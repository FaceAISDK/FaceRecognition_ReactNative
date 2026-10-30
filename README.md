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

## Integration & API

[SDK integration, parameters, return values, and examples](./docs/API.md) · [Demo source](./App.tsx)

## Troubleshooting

- **SDK unavailable:** install dependencies and Pods, then rebuild the native app.
- **Version conflict:** run `npm run doctor`; restore matching lockfiles before reinstalling.
- **No enrolled feature:** enroll and confirm saving before verification.
- **Debug page does not load:** check Metro and device access to port 8765.
- **iOS installation fails:** run from Xcode; use `ios:legacy` for iOS 16 and earlier.

[Report an issue](https://github.com/FaceAISDK/FaceRecognition_ReactNative/issues) · FaceAISDK.Service@gmail.com
