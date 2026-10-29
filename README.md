# FaceAISDK React Native Demo

[English](./README.md) | [中文](./README.zh-CN.md)

A physical-device demo of offline face enrollment, verification, liveness detection,
and feature management using [`@faceaisdk/react-native-face-sdk`](https://www.npmjs.com/package/@faceaisdk/react-native-face-sdk).

The `main` branch demonstrates the published SDK **1.8.0**.

## Requirements

Physical devices only: iOS 15.5+ or Android API 24+.

Verified environment:

| Component | Version |
| --- | --- |
| Node.js / npm | 26.0.0 / 11.12.1 (Node.js minimum: 22.11) |
| React Native / CLI | 0.84.0 / 20.2.0 |
| Plugin / native SDKs | 1.8.0 / Android 2026.10.29.meiju / iOS Core 2026.10.29 |
| iOS | Xcode 26.6 (17F113), Swift 6.3.3, CocoaPods 1.16.2 |
| Android | JDK 17, SDK 34, Build Tools 35.0.0, NDK 28.1.13356709, CMake 3.22.1 |

Install Android components in SDK Manager and configure `ANDROID_HOME` or
`android/local.properties`. The project includes Gradle wrapper 8.14.3.

## Run

```bash
npm ci
npm run doctor
```

The plugin version is pinned. Keep both lockfiles committed; upgrade the plugin,
iOS Core tag, and lockfiles together. `doctor` accepts `-- --android` or `-- --ios`.

### Android

Connect an unlocked device, enable USB debugging, and accept its authorization prompt.

```bash
npm start          # Metro on port 8765; keep this terminal open
npm run android    # Run in another terminal
```

### iOS

```bash
cd ios && pod install --deployment && cd ..
```

Open `ios/FaceAISDK_RN.xcworkspace`, select your Development Team, then connect and
unlock an iPhone:

```bash
npm run ios
```

The shared scheme runs Release, with JavaScript bundled. For Debug, start Metro
with `npm start` and use `npm run ios -- --mode Debug`.

For iOS 16 and earlier, use `npm run ios:legacy`; it installs Release, then tap
the app icon to launch. Its build log is `ios/build/ios-legacy.log`.

## Try the APIs

See [App.tsx](./App.tsx): enroll with the camera, then query or verify the same
`demo-user`. Standalone liveness does not require enrollment.

| Demo | API |
| --- | --- |
| Camera enrollment | `addFaceBySDKCamera` |
| Verification + liveness | `faceVerify` |
| Standalone liveness | `livenessVerify` |
| Read / insert / delete feature | `getFaceFeature` / `insertFaceFeature` / `deleteFaceFeature` |
| Base64 image enrollment | `addFaceByImage` |

Set `DEMO_FACE_FEATURE` or `DEMO_BASE64_IMAGE` in `App.tsx` before trying imports.
Imports overwrite the same face ID. Check result `code` and `message`; business
failures may resolve normally. Feature and image strings are displayed as lengths.

For your own project, follow the [SDK 1.8.0 integration guide](https://github.com/FaceAISDK/FaceRecognition_ReactNative/blob/v1.8.0/README.md#english).
See the [1.8.0 TypeScript definitions](https://github.com/FaceAISDK/FaceRecognition_ReactNative/blob/v1.8.0/src/types.ts) for options and return types.
iOS needs camera usage text and App target `BUILD_LIBRARY_FOR_DISTRIBUTION=NO`
in Debug and Release; SDK 1.8.0 configures TensorFlowLite automatically.
Android needs camera permission in the manifest and a runtime permission request.

## Troubleshooting

- **SDK unavailable:** install dependencies and Pods, then rebuild the native app.
- **Version conflict:** run `npm run doctor`; restore matching lockfiles before reinstalling.
- **No enrolled feature:** enroll and confirm saving before verification.
- **Debug page does not load:** check Metro and device access to port 8765.
- **iOS installation fails:** run from Xcode; use `ios:legacy` for iOS 16 and earlier.

[Report an issue](https://github.com/FaceAISDK/FaceRecognition_ReactNative/issues) · FaceAISDK.Service@gmail.com
