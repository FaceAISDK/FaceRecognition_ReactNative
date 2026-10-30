# SDK 1.8.0 Integration & API

[English](./API.md) | [中文](./API.zh-CN.md) · [Demo README](../README.md)

This guide describes the published `@faceaisdk/react-native-face-sdk@1.8.0`:
Android SDK `2026.10.29.meiju`, iOS Core `2026.10.29`. Use physical devices.
The package declares React >=18 and React Native >=0.71 peer dependencies;
this demo has been verified with React 19.2.3 and React Native 0.84.0.

## API index

- [isFaceAIModuleAvailable](#isfaceaimoduleavailable): check native linking.
- [addFaceBySDKCamera](#addfacebysdkcamera): enroll with the camera.
- [faceVerify](#faceverify): verify a face with liveness.
- [livenessVerify](#livenessverify): run standalone liveness.
- [getFaceFeature](#getfacefeature): read a local feature.
- [insertFaceFeature](#insertfacefeature): store a supplied feature.
- [addFaceByImage](#addfacebyimage): enroll from an image.
- [deleteFaceFeature](#deletefacefeature): delete a local feature.

## Install in your React Native project

```bash
npm install --save-exact @faceaisdk/react-native-face-sdk@1.8.0
```

### iOS

1. Set the App deployment target and Podfile `platform :ios` to **15.5** or later.
2. Set **App target → Build Settings → Build Libraries for Distribution**
   (`BUILD_LIBRARY_FOR_DISTRIBUTION`) to **No** in both Debug and Release.
3. Add camera usage text to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for face recognition and liveness detection.</string>
```

4. Run `cd ios && pod install`, then rebuild the native app. Open `.xcworkspace`
   and select your own Development Team for a signed device build.

Autolinking loads the SDK podspec. Version 1.8.0 automatically configures the
TensorFlowLite modulemap and TensorFlowLiteSwift ABI. Keep the existing
`react_native_post_install`; no SDK-specific post-install call is required.
The temporary TensorFlowLiteSwift workaround used with 1.7.4 can be removed.
The SDK handles the iOS camera permission prompt.

The demo additionally pins Core's Git tag in its Podfile. When upgrading it,
update the npm version, Core tag, and both lockfiles together. To reproduce the
**demo**, follow its README (`npm ci`, `pod install --deployment`); the installation
command above is for adding the SDK to another project.

### Android

Use `minSdkVersion >= 24` and `compileSdkVersion >= 34`. In the app manifest:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

Request camera permission at runtime before opening SDK camera pages, then
rebuild the native app after installing the plugin. Autolinking handles the bridge;
the plugin supplies its native Maven dependency. See the helper below for permission handling.

## Calling conventions

Use named imports from `@faceaisdk/react-native-face-sdk`. All seven business
APIs return `Promise<FaceResult>`; `isFaceAIModuleAvailable` synchronously returns
`boolean`. Call camera APIs while the app is in the foreground and await one
operation before starting another. Android 1.8.0 stores one pending camera callback.

Use a stable, nonempty `faceID` such as `user-001`. It identifies a local record
and is also used in image filenames: avoid path separators. Enrollment or insertion
under an existing ID overwrites that record. Use the same ID for enrollment,
lookup, verification, and deletion. A face feature is an opaque SDK string,
not an image Base64 string; preserve it unchanged.

### Shared camera helper

Save this application helper as `face-sdk-helpers.ts` to use the camera examples
below. It handles Android permission denial and prevents overlapping calls.
On permanent denial, offer a settings action in your UI (`Linking.openSettings()`).

```ts
import {PermissionsAndroid, Platform} from 'react-native';
import {isFaceAIModuleAvailable} from '@faceaisdk/react-native-face-sdk';

let cameraBusy = false;

// Application helper; this is not an SDK export.
export async function withSdkCamera<T>(call: () => Promise<T>): Promise<T> {
  if (cameraBusy) throw new Error('A camera operation is already running');
  cameraBusy = true;
  try {
    if (!isFaceAIModuleAvailable())
      throw new Error('Rebuild the native app first');
    if (Platform.OS === 'android') {
      const permission = PermissionsAndroid.PERMISSIONS.CAMERA;
      if (!(await PermissionsAndroid.check(permission))) {
        const status = await PermissionsAndroid.request(permission);
        if (status !== PermissionsAndroid.RESULTS.GRANTED) {
          throw new Error(
            status === PermissionsAndroid.RESULTS.NEVER_ASK_AGAIN
              ? 'Enable camera permission in system settings'
              : 'Camera permission denied',
          );
        }
      }
    }
    return await call();
  } finally {
    cameraBusy = false;
  }
}
```

The helper waits for the native callback before releasing the lock. A JavaScript
`Promise.race` timeout does not cancel a native page; do not open another camera
page until the existing operation has ended. SDK 1.8.0 exposes no cancellation API.

## FaceResult

```ts
interface FaceResult {
  code: number;
  message: string;
  faceID: string;
  similarity: number;
  liveness: number;
  faceFeature: string;
  faceBase64: string;
}
```

| Field         | Meaning                                                                                                                                        |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `code`        | Native business result. Interpret it for the called API; see below.                                                                            |
| `message`     | Native message, possibly localized. Use it for feedback, not as a stable enum.                                                                 |
| `faceID`      | The requested local ID; standalone liveness uses an empty string.                                                                              |
| `similarity`  | Face similarity from `faceVerify`; unused APIs return `0`.                                                                                     |
| `liveness`    | Liveness score from verification/liveness; unused APIs return `0`.                                                                             |
| `faceFeature` | SDK feature from enrollment, image enrollment, or lookup; otherwise usually `''`. A usable feature for lookup/verification is 1024 characters. |
| `faceBase64`  | Face image when provided by a camera operation; otherwise `''`. A successful operation may still provide no image.                             |

The JavaScript layer normalizes missing numeric fields to `0` and string fields
to `''`. Therefore a zero score or empty field can mean “not supplied.”
Avoid logging entire feature/image strings; the demo displays their lengths.

### Result codes

| API / situation                                                 | Result                                                                                                                                           |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Camera enrollment, image enrollment, feature insertion/deletion | `code === 1` indicates success.                                                                                                                  |
| `getFaceFeature`                                                | `code === 1` indicates an existing feature of the expected length. `0` can mean missing or invalid-length data.                                  |
| `faceVerify`                                                    | `code === 1` indicates verification passed. On iOS, missing/invalid stored feature returns `6`.                                                  |
| `livenessVerify`                                                | `code === 10` indicates all requested liveness checks passed.                                                                                    |
| `code === 0`                                                    | May indicate cancellation, failure, or missing feature, depending on the API. It is not a universal cancellation code.                           |
| Android native camera permission rejection                      | The native bridge can return `-1`. The helper above rejects before opening the native page.                                                      |
| Other codes                                                     | Native verification/liveness results are passed through; retain `code` and `message` for diagnosis. Do not treat every positive code as success. |

SDK business failures normally resolve the Promise. A missing native module or
JavaScript invocation error can reject it: handle **both** the result code and `catch`.

## Camera options

`FaceVerifyOptions` and `LivenessVerifyOptions` contain the following optional fields:

| Field             | Type               | `faceVerify` default | `livenessVerify` default | Meaning                                                                               |
| ----------------- | ------------------ | -------------------- | ------------------------ | ------------------------------------------------------------------------------------- |
| `threshold`       | `number`           | `0.83`               | Not accepted             | Face similarity threshold; not a liveness score threshold.                            |
| `livenessType`    | `1 \| 2 \| 3 \| 4` | `1`                  | `2`                      | Liveness mode; see below.                                                             |
| `motionTypes`     | `string`           | `'1,2,3,4,5'`        | `'1,2,3,4,5'`            | Comma-separated motion IDs.                                                           |
| `timeout`         | `number`           | `7`                  | `7`                      | Motion timeout in seconds; use a positive integer.                                    |
| `steps`           | `number`           | `2`                  | `2`                      | Motion step count; use a positive integer appropriate for the selected motions.       |
| `allowMultiFaces` | `boolean`          | `true`               | `true`                   | Android forwards it to the native SDK. **iOS 1.8.0 accepts but does not forward it.** |

Liveness modes: `1` = motion, `2` = motion + color flash, `3` = color flash,
`4` = silent only. The iOS camera implementation notes that modes 1–3 also
include silent liveness. TypeScript exposes 1–4; do not pass `0` to disable liveness.
Motion IDs: `1` open mouth, `2` smile, `3` blink, `4` shake head, `5` nod.
Motion fields apply to modes using motion checks. The JavaScript wrapper does
not validate numeric ranges or malformed motion strings.

The demo explicitly passes `livenessType: 1` to both camera checks. That does
not change the SDK's standalone liveness default of `2`.

## isFaceAIModuleAvailable

`isFaceAIModuleAvailable(): boolean`

Parameters: none. Returns whether the `FaceRNModule` native bridge is linked.
It does not check camera permission, model initialization, or recognition success.

```ts
import {isFaceAIModuleAvailable} from '@faceaisdk/react-native-face-sdk';

export function checkSdkLinking() {
  const available = isFaceAIModuleAvailable();
  if (!available)
    console.warn('Install Pods if needed and rebuild the native app');
  return available;
}
```

## addFaceBySDKCamera

`addFaceBySDKCamera(faceID: string, options?: AddFaceBySDKCameraOptions): Promise<FaceResult>`

| Parameter             | Type                        | Required / default | Meaning                                                                                        |
| --------------------- | --------------------------- | ------------------ | ---------------------------------------------------------------------------------------------- |
| `faceID`              | `string`                    | Required           | Local ID to save; an existing record is overwritten on successful save.                        |
| `options`             | `AddFaceBySDKCameraOptions` | Optional, `{}`     | Camera enrollment settings.                                                                    |
| `options.mode`        | `1 \| 2`                    | `1`                | Native enrollment mode on Android. On iOS 1.8.0 it is reserved and does not change processing. |
| `options.showConfirm` | `boolean`                   | `true`             | Show confirmation before saving the accepted face.                                             |

Opens SDK camera enrollment. On `code === 1`, the feature has been saved locally;
`faceFeature` contains the feature and `faceBase64` may contain the face image.
`similarity` and `liveness` are `0`. On iOS, a cancelled enrollment may still
return a previously stored feature: a nonempty feature alone is not proof of success.

```ts
import {addFaceBySDKCamera} from '@faceaisdk/react-native-face-sdk';
import {withSdkCamera} from './face-sdk-helpers';

export async function enrollFace(faceID: string) {
  const result = await withSdkCamera(() =>
    addFaceBySDKCamera(faceID, {mode: 1, showConfirm: true}),
  );
  if (result.code !== 1) {
    console.warn('Enrollment not saved:', result.code, result.message);
  }
  return result;
}
```

## faceVerify

`faceVerify(faceID: string, options?: FaceVerifyOptions): Promise<FaceResult>`

| Parameter | Type                | Required / default | Meaning                                                           |
| --------- | ------------------- | ------------------ | ----------------------------------------------------------------- |
| `faceID`  | `string`            | Required           | ID with a previously enrolled or inserted valid feature.          |
| `options` | `FaceVerifyOptions` | Optional, `{}`     | All fields and defaults are in [Camera options](#camera-options). |

Opens 1:1 verification with liveness. Returns `code`, `message`, `faceID`,
`similarity`, and `liveness`; `faceFeature` is empty and `faceBase64` is optional.
Pass only on `code === 1`, rather than comparing the returned similarity alone.
Lookup failures should keep their original `code`/`message instead of all being labelled “not enrolled.”

```ts
import {faceVerify, getFaceFeature} from '@faceaisdk/react-native-face-sdk';
import {withSdkCamera} from './face-sdk-helpers';

export async function verifyFace(faceID: string) {
  return withSdkCamera(async () => {
    const stored = await getFaceFeature(faceID);
    if (stored.code !== 1) {
      throw new Error(
        `Feature lookup failed (${stored.code}): ${stored.message}`,
      );
    }
    const result = await faceVerify(faceID, {
      threshold: 0.83,
      livenessType: 1,
      motionTypes: '1,2,3,4,5',
      timeout: 7,
      steps: 2,
      allowMultiFaces: false,
    });
    if (result.code !== 1) {
      console.warn('Verification not passed:', result.code, result.message);
    }
    return result;
  });
}
```

## livenessVerify

`livenessVerify(options?: LivenessVerifyOptions): Promise<FaceResult>`

| Parameter | Type                    | Required / default | Meaning                                                                        |
| --------- | ----------------------- | ------------------ | ------------------------------------------------------------------------------ |
| `options` | `LivenessVerifyOptions` | Optional, `{}`     | [Camera options](#camera-options), excluding `threshold`; default mode is `2`. |

Opens standalone liveness; no face ID or enrollment is needed. On
`code === 10`, all requested liveness checks have passed. `liveness` carries
the score; `faceID` and `faceFeature` are empty, `similarity` is `0`, and
`faceBase64` may contain the captured image.

```ts
import {livenessVerify} from '@faceaisdk/react-native-face-sdk';
import {withSdkCamera} from './face-sdk-helpers';

export async function checkLiveness() {
  const result = await withSdkCamera(() =>
    livenessVerify({livenessType: 2, timeout: 7, steps: 2}),
  );
  if (result.code !== 10) {
    console.warn('Liveness not passed:', result.code, result.message);
  }
  return result;
}
```

## getFaceFeature

`getFaceFeature(faceID: string): Promise<FaceResult>`

| Parameter | Type     | Required | Meaning            |
| --------- | -------- | -------- | ------------------ |
| `faceID`  | `string` | Yes      | Local ID to query. |

Reads the local feature without opening a camera. `code === 1` and a
1024-character `faceFeature` indicate a usable stored feature. A `0` result can
mean missing data or an unexpected length; inspect `message`. `faceID` is echoed,
`similarity`/`liveness` are `0`, and `faceBase64` is empty.

```ts
import {getFaceFeature} from '@faceaisdk/react-native-face-sdk';

export async function readFeature(faceID: string) {
  const result = await getFaceFeature(faceID);
  console.log({
    code: result.code,
    message: result.message,
    length: result.faceFeature.length,
  });
  return result;
}
```

## insertFaceFeature

`insertFaceFeature(faceID: string, faceFeature: string): Promise<FaceResult>`

| Parameter     | Type     | Required | Meaning                                                                              |
| ------------- | -------- | -------- | ------------------------------------------------------------------------------------ |
| `faceID`      | `string` | Yes      | Target local ID; existing data is overwritten.                                       |
| `faceFeature` | `string` | Yes      | A valid 1024-character feature generated by the compatible SDK, preserved unchanged. |

Writes the supplied feature without opening a camera. `code === 1` reports
successful storage, not a fresh face/liveness verification. `faceID` is echoed;
feature/image fields are empty and scores are `0`.
Android requires exactly 1024 characters. iOS insertion only rejects lengths below
1024, but its lookup and verification still require exactly 1024. Do not pad,
truncate, or manufacture a feature to satisfy the length check. The bridge does
not guarantee cross-platform or cross-version feature compatibility.

```ts
import {
  getFaceFeature,
  insertFaceFeature,
} from '@faceaisdk/react-native-face-sdk';

// The caller must choose a target ID whose data may be overwritten.
export async function copyFeature(sourceID: string, targetID: string) {
  if (sourceID === targetID) throw new Error('Choose a different target ID');
  const source = await getFaceFeature(sourceID);
  if (source.code !== 1 || source.faceFeature.length !== 1024) {
    throw new Error(
      `No usable SDK feature (${source.code}): ${source.message}`,
    );
  }
  const result = await insertFaceFeature(targetID, source.faceFeature);
  if (result.code !== 1)
    throw new Error(`Insert failed (${result.code}): ${result.message}`);
  return result;
}
```

## addFaceByImage

`addFaceByImage(faceID: string, base64Image: string): Promise<FaceResult>`

| Parameter     | Type     | Required | Meaning                                                                            |
| ------------- | -------- | -------- | ---------------------------------------------------------------------------------- |
| `faceID`      | `string` | Yes      | Local ID for the extracted feature; existing data is overwritten on success.       |
| `base64Image` | `string` | Yes      | Base64 data of a real, decodable face image; not a URL, file path, or SDK feature. |

Extracts and saves a feature from the supplied image, without opening the SDK
camera or proving liveness. For cross-platform input, use the plain image Base64
payload. iOS also strips a data-URI prefix containing `base64,`; do not assume that
convenience is supported on Android.
Android needs a current Activity for this API, so invoke it while the app is in the foreground.
On `code === 1`, `faceFeature` contains the saved feature; scores are `0` and
`faceBase64` is empty. Image parsing/extraction failures resolve with a failure code.
The JavaScript API is named `addFaceByImage`; `addFaceBySDKImage` is the underlying
native bridge method and is not a public named JavaScript export.

```ts
import {addFaceByImage} from '@faceaisdk/react-native-face-sdk';

// Pass an actual encoded face image supplied by your application's image input.
export async function enrollFromImage(faceID: string, base64Image: string) {
  if (!base64Image.trim()) throw new Error('An image is required');
  const result = await addFaceByImage(faceID, base64Image);
  if (result.code !== 1) {
    console.warn('Image enrollment failed:', result.code, result.message);
  }
  return result;
}
```

## deleteFaceFeature

`deleteFaceFeature(faceID: string): Promise<FaceResult>`

| Parameter | Type     | Required | Meaning             |
| --------- | -------- | -------- | ------------------- |
| `faceID`  | `string` | Yes      | Local ID to delete. |

Deletes the local feature. The current bridge reports `code === 1` even when
the ID did not exist; this is not an existence check. `faceID` is echoed,
feature/image fields are empty, and scores are `0`.
Android also attempts to delete that ID's enrollment cache image. iOS 1.8.0 removes
the feature and `<faceID>_base64` UserDefaults entries, but does not delete the
FaceImageManager image file here. Neither API promises to clear every verification
or liveness image. Query again if your UI needs the post-deletion state.

```ts
import {
  deleteFaceFeature,
  getFaceFeature,
} from '@faceaisdk/react-native-face-sdk';

// Invoke only after the user has confirmed which ID should be deleted.
export async function removeFeature(faceID: string) {
  const result = await deleteFaceFeature(faceID);
  if (result.code !== 1)
    throw new Error(`Delete failed (${result.code}): ${result.message}`);
  const afterDelete = await getFaceFeature(faceID);
  return {result, afterDelete};
}
```

## Handling errors at the call site

The examples export async functions; call them from UI event handlers and catch
rejections there. A `try/catch` alone does not handle SDK business failures:

```ts
import {faceVerify} from '@faceaisdk/react-native-face-sdk';
import {withSdkCamera} from './face-sdk-helpers';

export async function handleVerification(faceID: string) {
  try {
    const result = await withSdkCamera(() => faceVerify(faceID));
    if (result.code !== 1) {
      console.warn('SDK business result:', result.code, result.message);
    }
    return result;
  } catch (error) {
    console.warn(
      'Invocation failed:',
      error instanceof Error ? error.message : String(error),
    );
    return null;
  }
}
```

## Integration checklist

- Rebuild after installing/upgrading the SDK; a Metro reload cannot link a native module.
- Await the native result before opening another camera page; do not auto-retry cancelled or denied operations.
- Verify with an enrolled ID; standalone liveness and image feature extraction are different operations.
- On this demo, configure `DEMO_FACE_FEATURE` / `DEMO_BASE64_IMAGE` in [App.tsx](../App.tsx) before trying imports.
- Validate real enrollment, verification, cancellation, permission rejection, and deletion on the target devices. Examples passing TypeScript checks do not exercise native algorithms.

This guide is maintained in `main/docs` for SDK 1.8.0. Update it alongside the
plugin version and native dependency versions when upgrading.
