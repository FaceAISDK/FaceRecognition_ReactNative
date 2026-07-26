# Face Recognition-FaceAISDK React Native Demo

[English](./README.md) | [中文](./README.zh-CN.md)

This repository is API demo for
[`@faceaisdk/react-native-face-sdk`](https://www.npmjs.com/package/@faceaisdk/react-native-face-sdk).
It shows offline face enrollment, 1:1 verification, liveness detection, and
face-feature management on iOS and Android.

> The SDK depends on the device camera and native face algorithms. A physical
> device is required; simulators are not supported.

## Features

- Offline face enrollment with the SDK camera
- 1:1 face verification with liveness detection
- Standalone liveness detection
- Query, insert, and delete face features
- Face enrollment from a custom Base64 image

## Requirements

| Item         | Requirement                                                   |
| ------------ | ------------------------------------------------------------- |
| Node.js      | 22.11 or later                                                |
| React Native | This demo uses 0.84.0                                         |
| Face SDK     | This demo uses `^1.1.0`                                       |
| iOS          | 15.0 or later, physical device                                |
| Android      | `minSdkVersion` 24+, `compileSdkVersion` 34+, physical device |

## Run This Demo

Install JavaScript dependencies:

```bash
npm install
```

### Android

Start Metro in one terminal:

```bash
npm start
```

Connect a device with USB debugging enabled, then run in another terminal:

```bash
npm run android
```

### iOS

Install CocoaPods dependencies:

```bash
cd ios
pod install
cd ..
```

Open `ios/FaceAISDK_RN.xcworkspace` in Xcode and select a Development Team
under **Signing & Capabilities**.

Start Metro and run the app in separate terminals:

```bash
npm start
npm run ios
```

## Install the SDK in Another Project

```bash
npm install @faceaisdk/react-native-face-sdk
```

### iOS Configuration

Add the SDK post-install helper near the top of `ios/Podfile`:

```ruby
require_relative '../node_modules/@faceaisdk/react-native-face-sdk/scripts/faceaisdk_post_install.rb'
```

Call it after React Native's post-install step:

```ruby
post_install do |installer|
  react_native_post_install(
    installer,
    config[:reactNativePath],
    :mac_catalyst_enabled => false
  )
  faceaisdk_post_install(installer)
end
```

Install Pods:

```bash
cd ios && pod install
```

Add camera permission to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for face recognition and liveness detection.</string>
```

### Android Configuration

Make sure the Android project uses at least:

```gradle
minSdkVersion = 24
compileSdkVersion = 34
```

Add camera permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

Camera permission must also be requested at runtime on Android. See
[`App.tsx`](./App.tsx) for a working example using `PermissionsAndroid`.

## Import

```ts
import {
  addFaceByImage,
  addFaceBySDKCamera,
  deleteFaceFeature,
  faceVerify,
  getFaceFeature,
  insertFaceFeature,
  isFaceAIModuleAvailable,
  livenessVerify,
  type FaceResult,
} from '@faceaisdk/react-native-face-sdk';
```

## API Examples

### Check Native Module Availability

```ts
const available = isFaceAIModuleAvailable();
```

Use this to detect an incomplete native installation before invoking an API.

### Enroll a Face with the SDK Camera

```ts
const result = await addFaceBySDKCamera('demo-user', {
  mode: 1,
  showConfirm: true,
});
```

| Option        | Type      | Description                           |
| ------------- | --------- | ------------------------------------- |
| `mode`        | `1 \| 2`  | Camera enrollment mode                |
| `showConfirm` | `boolean` | Whether to show the confirmation step |

### Face Verification with Liveness

```ts
const result = await faceVerify('demo-user', {
  threshold: 0.83,
  livenessType: 1,
  motionTypes: '1,2,3,4,5',
  timeout: 7,
  steps: 2,
  allowMultiFaces: true,
});
```

### Standalone Liveness Detection

```ts
const result = await livenessVerify({
  livenessType: 1,
  motionTypes: '1,2,3,4,5',
  timeout: 7,
  steps: 2,
  allowMultiFaces: true,
});
```

`faceVerify` and `livenessVerify` share these liveness options:

| Option            | Type               | Description                        |
| ----------------- | ------------------ | ---------------------------------- |
| `livenessType`    | `1 \| 2 \| 3 \| 4` | Liveness detection mode            |
| `motionTypes`     | `string`           | Comma-separated motion type IDs    |
| `timeout`         | `number`           | Liveness timeout value             |
| `steps`           | `number`           | Number of liveness steps           |
| `allowMultiFaces` | `boolean`          | Whether multiple faces are allowed |

`faceVerify` additionally accepts `threshold`, the face similarity threshold.

### Query a Face Feature

```ts
const result = await getFaceFeature('demo-user');
```

### Insert a Custom Face Feature

```ts
const customFeature = '0'.repeat(1024);
const result = await insertFaceFeature('demo-user', customFeature);
```

The placeholder demonstrates how to pass a custom feature. Replace it with a
valid feature before expecting a successful SDK result.

### Enroll from a Custom Base64 Image

```ts
const customBase64Image = 'demo_base64_image_string';
const result = await addFaceByImage('demo-user', customBase64Image);
```

Replace the placeholder with a valid Base64-encoded image.

### Delete a Face Feature

```ts
const result = await deleteFaceFeature('demo-user');
```

## Result

All asynchronous APIs resolve to `FaceResult`:

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

| Property      | Type     | Description           |
| ------------- | -------- | --------------------- |
| `code`        | `number` | SDK result code       |
| `message`     | `string` | SDK result message    |
| `faceID`      | `string` | Face identifier       |
| `similarity`  | `number` | Face similarity score |
| `liveness`    | `number` | Liveness score        |
| `faceFeature` | `string` | Face feature data     |
| `faceBase64`  | `string` | Base64 face image     |

Use `message` directly for the SDK-provided result text. The demo shows feature
and Base64 lengths instead of placing potentially large values in an alert.

## Troubleshooting

### The Demo Shows “SDK Not Connected”

- Confirm that the package is present in `dependencies`.
- On iOS, run `pod install` and open the `.xcworkspace`, not the `.xcodeproj`.
- Rebuild the native app after installing or upgrading the package.

### Custom Feature or Base64 Enrollment Fails

The constants in `App.tsx` are intentionally fake values used to demonstrate
custom argument passing. Replace them with a valid face feature or Base64 image.

## Related SDK Demos

- [iOS SDK](https://github.com/FaceAISDK/FaceAISDK_iOS)
- [Android SDK](https://github.com/FaceAISDK/FaceAISDK_Android)
- [uniApp UTS](https://github.com/FaceAISDK/FaceAISDK_uniapp_UTS)
- [Flutter](https://github.com/FaceAISDK/FaceRecognition_Flutter)
- [React Native](https://github.com/FaceAISDK/FaceRecognition_ReactNative)

## Support & Feedback

- [GitHub Issues](https://github.com/FaceAISDK/FaceRecognition_ReactNative/issues)
- Email: FaceAISDK.Service@gmail.com
