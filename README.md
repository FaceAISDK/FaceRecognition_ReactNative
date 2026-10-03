# FaceAISDK React Native Demo

[English](./README.md) | [中文](./README.zh-CN.md)

Offline face enrollment, verification, and liveness detection on iOS and Android
with [`@faceaisdk/react-native-face-sdk`](https://www.npmjs.com/package/@faceaisdk/react-native-face-sdk).

The `main` branch contains this npm consumer demo; the plugin source and release
tools are maintained on the [`dev` branch](https://github.com/FaceAISDK/FaceRecognition_ReactNative/tree/dev).

## Requirements

- Node.js 22.11+, React Native 0.84.0, CLI 20.2.0, Face SDK 1.7.4 (Android 2026.09.29, iOS Core 2026.09.22).
- A physical device: iOS 15.5+ or Android API 24+. Simulators are not supported.
- Xcode and CocoaPods for iOS; Android SDK (compile SDK 34) and JDK 17 for Android.

## Run

Install dependencies:

```bash
npm install
```

For Android and iOS Debug, run `npm start` to keep Metro running on port 8765,
then use another terminal for the commands below. iOS Release builds bundle the
JavaScript and do not need Metro.

### Android

Connect a device with USB debugging enabled:

```bash
npm run android
```

### iOS

The demo already configures iOS 15.5+ and explicitly sets **Build Libraries for
Distribution** to **No** for the App target in Debug and Release. SDK 1.7.4
automatically supplies the TensorFlowLite modulemap. Version 1.7.4 omits a
TensorFlowLiteSwift ABI setting required by the prebuilt Core, causing model
initialization to crash. This demo's [Podfile](./ios/Podfile) includes the scoped
workaround: enable distribution mode and skip emitted-interface verification
for TensorFlowLiteSwift in Debug and Release. Keep the App target set to No.
The `dev` branch contains the automatic ABI fix, pending a new npm release.

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

The shared scheme currently uses Release for Run. For Debug on a physical
device, use `npm run ios -- --mode Debug` and keep `npm start` running.

For Debug builds, the iPhone must be able to reach Metro on your computer's port 8765.
If CLI installation fails with `devicectl`, select the connected device in Xcode
and use **Product > Run** instead.

#### iOS 16 and Earlier

Use `ios-deploy` instead of `devicectl`. Connect and unlock one iPhone, trust the
computer, then run from the project root:

```bash
npm run ios:legacy
```

This builds a Release app and installs it; tap the app icon to launch. Metro is
not needed. Build files are cached in `ios/build`; existing Pods and build caches
are not deleted. The CLI version and `npm run ios` remain unchanged.
Output is brief; the full log is saved to `ios/build/ios-legacy.log` (replaced
each run) and printed automatically if building or installation fails.

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
- Before using "Face verification + liveness" for the first time, tap "Enroll face
  with camera" and confirm saving. The demo checks the `demo-user` feature before
  verification and shows enrollment instructions when it is missing. On iOS,
  calling the plugin's `faceVerify` without an enrolled feature returns `code: 6`,
  regardless of Debug or Release mode.
- `DEMO_FACE_FEATURE` and `DEMO_BASE64_IMAGE` in `App.tsx` are empty by default.
  Until configured, these menu items show a reminder without calling the SDK.
  Use a real SDK feature and a valid Base64 image; inserting a feature overwrites
  data for the same face ID.
- `motionTypes` contains comma-separated motion IDs; `timeout` and `steps` control
  the timeout and action count. In SDK 1.7.4, `allowMultiFaces` is forwarded to
  the Android SDK; the iOS bridge accepts it but does not forward it to Core.
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

For another React Native project, use the following platform setup with SDK 1.7.4.

### iOS

Before installing Pods:

1. Set the App deployment target and `platform :ios` in `ios/Podfile` to **15.5** or later.
2. In Xcode, select the **App target → Build Settings → Build Libraries for
   Distribution** (`BUILD_LIBRARY_FOR_DISTRIBUTION`) and explicitly set **No**
   for both Debug and Release. This demo already includes that setting. Core
   2026.09.22 exports `YES` into the host xcconfig; inheriting it can make CocoaPods
   enable distribution mode for unrelated Pods and fail Swift interface verification.
   [Library evolution](https://www.swift.org/blog/library-evolution/) is intended
   for frameworks distributed separately from their clients.
3. Add camera usage text to the App's `Info.plist`:

   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Camera access is required for face recognition and liveness detection.</string>
   ```

With npm version 1.7.4, add the following after `react_native_post_install` in
your existing `post_install` callback:

```ruby
flag = '-no-verify-emitted-module-interface'
installer.pods_project.targets.each do |target|
  next unless target.name == 'TensorFlowLiteSwift'

  target.build_configurations.each do |configuration|
    configuration.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    flags = Array(configuration.build_settings['OTHER_SWIFT_FLAGS'] || '$(inherited)').join(' ')
    next if flags.split.include?(flag)

    configuration.build_settings['OTHER_SWIFT_FLAGS'] = "#{flags} #{flag}"
  end
end
```

Core was built against TensorFlowLiteSwift's library evolution ABI. Compiling
that dependency without library evolution changes how `Interpreter.Options` is
passed and causes `EXC_BREAKPOINT` / `SIGTRAP` in `Interpreter.init`. This
workaround affects TensorFlowLiteSwift only; keep the App target set to No.

From the project root, install the plugin and Pods:

```bash
npm install @faceaisdk/react-native-face-sdk@1.7.4
cd ios && pod install
```

React Native autolinking loads the SDK podspec, which registers the modulemap
repair automatically. No SDK-specific `require_relative` or
`faceaisdk_post_install(installer)` call is needed; keep your existing
`react_native_post_install` callback and the scoped 1.7.4 workaround above.
When upgrading from the old setup, remove
the SDK's `require_relative '.../faceaisdk_post_install.rb'` line and the
`faceaisdk_post_install(installer)` call, then run `pod install` again and rebuild.

### Android

Install the plugin from the project root:

```bash
npm install @faceaisdk/react-native-face-sdk@1.7.4
```

Use `minSdkVersion >= 24` and `compileSdkVersion >= 34`. Add camera permission
to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

Request camera permission at runtime; see `requestCameraPermission` in [App.tsx](./App.tsx).
The SDK handles the iOS permission prompt.

## Troubleshooting

- **A camera operation crashes in `TensorFlowLite.Interpreter.init`:** npm 1.7.4
  requires the TensorFlowLiteSwift workaround above. Run `pod install` and rebuild
  after applying it. Changing the App's distribution setting alone does not fix
  this runtime ABI mismatch.
- **SDK unavailable:** confirm the dependency is installed, run `pod install` on
  iOS, and rebuild the native app. Open `.xcworkspace`, not `.xcodeproj`.
- **TensorFlowLite Swift interface verification fails:** if the build reports
  `underlying Objective-C module 'TensorFlowLite' not found` during
  `SwiftVerifyEmittedModuleInterface`, explicitly set the App target's
  `BUILD_LIBRARY_FOR_DISTRIBUTION` to `NO` in Debug and Release, and apply the
  TensorFlowLiteSwift workaround above, then run `pod install` again. That
  target needs distribution mode enabled with emitted-interface verification
  skipped. Changing settings only on the build command line does not update
  the Pods configurations generated by CocoaPods.
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
