<p align="center">
  <img src="./ios/FaceAISDK_RN/Images.xcassets/AppIcon.appiconset/icon-1024x1024@1x.png" width="96" height="96" alt="FaceAISDK" />
</p>

<h1 align="center">FaceAISDK · React Native</h1>

<p align="center">
  Offline enrollment · 1:1 verification · Liveness detection · Feature management
</p>

<p align="center">
  <strong>English</strong> · <a href="./README.zh-CN.md">简体中文</a>
</p>

<p align="center">
  <a href="#quick-start">Quick start</a> ·
  <a href="./docs/API.md">Integration & API</a> ·
  <a href="./App.tsx">Demo source</a>
</p>

<p align="center">
  <code>SDK 1.8.0</code> &nbsp; <code>React Native 0.84.0</code>
</p>

The `main` branch demonstrates the published
[`@faceaisdk/react-native-face-sdk`](https://www.npmjs.com/package/@faceaisdk/react-native-face-sdk) package.

> **Physical devices required:** iOS **15.5+** or Android **API 24+**. Simulators are not supported.

## Quick start

### Install dependencies

```bash
npm ci
npm run doctor
```

`doctor` checks dependency versions and the local toolchain. To check one platform,
use `npm run doctor -- --android` or `npm run doctor -- --ios`.

### Android

Connect and unlock the phone, enable **USB debugging**, and accept the computer's authorization prompt.

```bash
# Terminal 1 — keep Metro running on port 8765
npm start
```

```bash
# Terminal 2 — install and run on the device
npm run android
```

### iOS

```bash
cd ios && pod install --deployment && cd ..
```

Open **`ios/FaceAISDK_RN.xcworkspace`**, select your own **Development Team**,
and connect an unlocked iPhone.

```bash
npm run ios
```

The shared scheme runs **Release** by default, with JavaScript bundled.
For **Debug**, start Metro with `npm start`, then use `npm run ios -- --mode Debug`.

<details>
<summary><strong>iOS 16 and earlier</strong></summary>

Use the legacy installer:

```bash
npm run ios:legacy
```

It installs Release; tap the app icon to launch. The build log is saved to
`ios/build/ios-legacy.log`.

</details>

## Environment & versions

Node.js **22.11+** is required. Install Android components in **SDK Manager** and
configure `ANDROID_HOME` or `android/local.properties`.

<details>
<summary><strong>View the verified toolchain</strong></summary>

| Component                 | Verified version                     |
| :------------------------ | :----------------------------------- |
| Node.js / npm             | `26.0.0` / `11.12.1`                 |
| React Native / CLI        | `0.84.0` / `20.2.0`                  |
| Xcode / Swift / CocoaPods | `26.6 (17F113)` / `6.3.3` / `1.16.2` |
| JDK                       | `17`                                 |
| Android SDK / Build Tools | `34` / `35.0.0`                      |
| Android NDK / CMake       | `28.1.13356709` / `3.22.1`           |
| Gradle wrapper            | `8.14.3` (included in the project)   |
| Native SDK — Android      | `2026.10.29.meiju`                   |
| Native SDK — iOS Core     | `2026.10.29`                         |

</details>

The plugin version is pinned. Keep `package-lock.json` and `ios/Podfile.lock`
committed; upgrade the plugin, iOS Core tag, and both lockfiles together.

## Troubleshooting

| Symptom                  | What to check                                                         |
| :----------------------- | :-------------------------------------------------------------------- |
| SDK unavailable          | Install dependencies and Pods, then rebuild the native app.           |
| Version conflict         | Run `npm run doctor`; restore matching lockfiles before reinstalling. |
| No enrolled feature      | Enroll a face and confirm saving before verification.                 |
| Debug page does not load | Check Metro and device access to port `8765`.                         |
| iOS installation fails   | Run from Xcode; use `ios:legacy` for iOS 16 and earlier.              |

---

<p align="center">
  <a href="https://github.com/FaceAISDK/FaceRecognition_ReactNative/issues">Report an issue</a> ·
  <a href="mailto:FaceAISDK.Service@gmail.com">FaceAISDK.Service@gmail.com</a>
</p>
