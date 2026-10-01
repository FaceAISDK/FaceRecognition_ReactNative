# FaceAISDK React Native Demo

[English](./README.md) | [中文](./README.zh-CN.md)

Offline face enrollment, verification, and liveness detection on iOS and Android
with [`@faceaisdk/react-native-face-sdk`](https://www.npmjs.com/package/@faceaisdk/react-native-face-sdk).

## Requirements

- Node.js 22.11+, React Native 0.84.0, CLI 20.2.0, Face SDK 1.7.1 (iOS Core 2026.09.22).
- A physical device: iOS 15.5+ or Android API 24+. Simulators are not supported.
- Xcode and CocoaPods for iOS; Android SDK (compile SDK 34) and JDK 17 for Android.

## Run

Install dependencies and start Metro on port 8765:

```bash
npm install
npm start
```

Keep Metro running; use another terminal for the commands below.

### Android

Connect a device with USB debugging enabled:

```bash
npm run android
```

### iOS

Install Pods:

```bash
cd ios
pod install
cd ..
```

Open `ios/FaceAISDK_RN.xcworkspace` in Xcode and select your Development Team
under **Signing & Capabilities**. Connect an iPhone, then run:

```bash
npm run ios
```

For Debug builds, the iPhone must be able to reach Metro on your computer's port 8765.
If CLI installation fails with `devicectl`, select the connected device in Xcode
and use **Product > Run** instead.

## Demo APIs

See [App.tsx](./App.tsx) for the complete example. Import APIs from
`@faceaisdk/react-native-face-sdk`; each call below returns `Promise<FaceResult>`.

```ts
const faceID = 'demo-user';
const options = {
  livenessType: 1 as const,
  motionTypes: '1,2,3,4,5',
  timeout: 7,
  steps: 2,
  allowMultiFaces: true,
};
```

| Menu                          | API call                                                   |
| ----------------------------- | ---------------------------------------------------------- |
| Enroll face with camera       | `addFaceBySDKCamera(faceID, {mode: 1, showConfirm: true})` |
| Face verification + liveness  | `faceVerify(faceID, options)`                              |
| Liveness detection            | `livenessVerify(options)`                                  |
| Query face feature            | `getFaceFeature(faceID)`                                   |
| Insert custom face feature    | `insertFaceFeature(faceID, feature)`                       |
| Enroll face from Base64 image | `addFaceByImage(faceID, base64Image)`                      |
| Delete face feature           | `deleteFaceFeature(faceID)`                                |

- Enroll a face before verification or lookup. Standalone liveness needs no enrollment.
- `DEMO_FACE_FEATURE` and `DEMO_BASE64_IMAGE` in `App.tsx` are empty by default.
  Until configured, these menu items show a reminder without calling the SDK.
  Use a real SDK feature and a valid Base64 image; inserting a feature overwrites
  data for the same face ID.
- `motionTypes` contains comma-separated motion IDs; `timeout`, `steps`, and
  `allowMultiFaces` control the timeout, action count, and multi-face handling.
  `faceVerify` also accepts `threshold` (default `0.83`), a similarity threshold,
  not a liveness threshold.

## Results

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

Check `code` and `message`: an SDK business failure does not necessarily reject
the promise. The demo displays feature/image lengths instead of large raw values.

## SDK Integration

For another React Native project:

```bash
npm install @faceaisdk/react-native-face-sdk@latest
```

### iOS

Add the helper to `ios/Podfile` and call it after React Native's post-install step:

```ruby
require_relative '../node_modules/@faceaisdk/react-native-face-sdk/scripts/faceaisdk_post_install.rb'

post_install do |installer|
  react_native_post_install(
    installer,
    config[:reactNativePath],
    :mac_catalyst_enabled => false
  )
  faceaisdk_post_install(installer)
end
```

Add camera usage text to `Info.plist`, then run `pod install`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for face recognition and liveness detection.</string>
```

### Android

Use `minSdkVersion >= 24` and `compileSdkVersion >= 34`. Add camera permission
to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

Request camera permission at runtime; see `requestCameraPermission` in [App.tsx](./App.tsx).
The SDK handles the iOS permission prompt.

## Troubleshooting

- **SDK unavailable:** confirm the dependency is installed, run `pod install` on
  iOS, and rebuild the native app. Open `.xcworkspace`, not `.xcodeproj`.
- **Debug bundle not loading:** confirm Metro is running on port 8765; check the
  phone's access to the computer, the Metro host address, and local network permission.
- **Feature/image import fails:** configure the demo constants with real data.
  If a feature was overwritten, enroll the face again.

## Related Demos & Support

[iOS](https://github.com/FaceAISDK/FaceAISDK_iOS) ·
[Android](https://github.com/FaceAISDK/FaceAISDK_Android) ·
[uniApp](https://github.com/FaceAISDK/FaceAISDK_uniapp_UTS) ·
[Flutter](https://github.com/FaceAISDK/FaceRecognition_Flutter)

[GitHub Issues](https://github.com/FaceAISDK/FaceRecognition_ReactNative/issues) ·
FaceAISDK.Service@gmail.com
