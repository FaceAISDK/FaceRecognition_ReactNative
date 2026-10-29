# FaceAISDK React Native 示例

[English](./README.md) | [中文](./README.zh-CN.md)

使用 [`@faceaisdk/react-native-face-sdk`](https://www.npmjs.com/package/@faceaisdk/react-native-face-sdk)
演示 iOS / Android 离线人脸录入、比对、活体检测和特征管理。

`main` 分支是使用 npm 插件的示例工程；插件源码及发布工具位于
[`dev` 分支](https://github.com/FaceAISDK/FaceRecognition_ReactNative/tree/dev)。

## 环境要求

- Node.js 22.11+、React Native 0.84.0、CLI 20.2.0、Face SDK 1.8.0（Android 2026.10.29.meiju、iOS Core 2026.10.29）。
- iOS 15.5+ 或 Android API 24+ 真机；不支持模拟器。
- iOS 需要 Xcode 和 CocoaPods；Android 需要 Android SDK（compile SDK 34）和 JDK 17。

## 运行

安装依赖：

```bash
npm install
```

Android 和 iOS Debug 需要执行 `npm start`，保持 Metro 在 8765 端口运行，
再用另一个终端执行以下命令。iOS Release 会打包 JavaScript，无需 Metro。

### Android

连接已开启 USB 调试的真机：

```bash
npm run android
```

### iOS

示例已设置 iOS 15.5+，并将 App target 的 Debug、Release 两种配置中的
**Build Libraries for Distribution** 显式设为 **No**。SDK 1.8.0 会自动补齐
TensorFlowLite modulemap 和 Core 所需的 TensorFlowLiteSwift ABI 配置。
本示例的 [Podfile](./ios/Podfile) 将 Core 固定到 `2026.10.29` Git tag，
并保留标准 React Native post-install 回调，无需额外添加 SDK 临时修复。
App target 仍为 No。

安装 Pods：

```bash
cd ios
pod install
cd ..
```

用 Xcode 打开 `ios/FaceAISDK_RN.xcworkspace`，在 **Signing & Capabilities**
中选择自己的 Development Team。连接 iPhone 后运行：

```bash
npm run ios
```

当前共享 Scheme 的 Run 配置为 Release。需要真机 Debug 调试时，执行
`npm run ios -- --mode Debug`，并保持 `npm start` 运行。

Debug 调试时，iPhone 需要能访问电脑的 Metro 8765 端口。
若 CLI 的 `devicectl` 安装失败，请在 Xcode 选择已连接的真机，使用 **Product > Run**。

#### iOS 16 及更早版本

使用 `ios-deploy` 安装应用。连接并解锁一台 iPhone，信任电脑，
然后在项目根目录运行：

```bash
npm run ios:legacy
```

命令构建并安装 Release 包，完成后点击手机上的应用图标启动，无需 Metro。
构建文件缓存在 `ios/build`，不会删除已有 Pods 或构建缓存。
CLI 版本和原来的 `npm run ios` 保持不变。
默认精简输出；完整日志保存在 `ios/build/ios-legacy.log`（每次运行覆盖），
构建或安装失败时自动显示完整日志。

## 演示 API

完整调用见 [App.tsx](./App.tsx)。从 `@faceaisdk/react-native-face-sdk` 导入 API；
下表中的调用均返回 `Promise<FaceResult>`。

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

| 菜单                | API 调用                                                   |
| ------------------- | ---------------------------------------------------------- |
| 相机录入人脸        | `addFaceBySDKCamera(faceID, {mode: 1, showConfirm: true})` |
| 人脸比对 + 活体检测 | `faceVerify(faceID, options)`                              |
| 活体检测            | `livenessVerify(options)`                                  |
| 查询人脸特征        | `getFaceFeature(faceID)`                                   |
| 传入自定义人脸特征  | `insertFaceFeature(faceID, feature)`                       |
| Base64 图片录入人脸 | `addFaceByImage(faceID, base64Image)`                      |
| 删除人脸特征        | `deleteFaceFeature(faceID)`                                |

- 先录入，再比对或查询；独立活体检测无需录入。
- 首次使用“人脸比对 + 活体检测”时，先点击“相机录入人脸”并确认保存。
  Demo 会在比对前检查 `demo-user` 的特征；尚未录入时显示操作提示。
  iOS 直接调用插件的 `faceVerify` 时，缺少对应特征会返回 `code: 6`，
  这与 Debug / Release 模式无关。
- `App.tsx` 的 `DEMO_FACE_FEATURE` 和 `DEMO_BASE64_IMAGE` 默认为空；
  未配置时点击菜单只显示提示，不调用 SDK。使用前请填入真实 SDK 特征和有效
  Base64 图片。写入特征会覆盖同一人脸 ID 的已有数据。
- `motionTypes` 是逗号分隔的动作 ID；`timeout`、`steps` 分别控制超时和动作数量。
  SDK 1.8.0 的 `allowMultiFaces` 会传给 Android SDK；iOS 桥接层接受此参数，但未传给 Core。
  `faceVerify` 还支持 `threshold`（默认 `0.83`），
  这是人脸相似度阈值，不是活体阈值。

## 返回结果

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

检查 `code` 和 `message` 判断业务结果；SDK 业务失败不一定抛出异常。
为避免弹窗内容过长，示例只展示特征和图片字符串的长度。

## 接入其他项目

其他 React Native 工程可按下面的平台配置接入 SDK 1.8.0。

### iOS

安装 Pods 前：

1. 将 App 的最低部署版本及 `ios/Podfile` 中的 `platform :ios` 设为 **15.5** 或更高。
2. 在 Xcode 中选择 **App target → Build Settings → Build Libraries for
   Distribution**（`BUILD_LIBRARY_FOR_DISTRIBUTION`），将 Debug、Release 都显式设为
   **No**。本示例已包含此设置。Core 2026.10.29 会在宿主 xcconfig 中导出 `YES`；
   如果 App 继承它，CocoaPods 可能为所有 Swift Pods 开启发行模式，触发接口校验问题。
   [Library evolution](https://www.swift.org/blog/library-evolution/) 用于向调用方单独分发的二进制框架。
3. 在 App 的 `Info.plist` 添加相机用途说明：

   ```xml
   <key>NSCameraUsageDescription</key>
   <string>人脸识别和活体检测需要使用相机。</string>
   ```

SDK 1.8.0 会自动为 TensorFlowLiteSwift 开启 library evolution 并跳过 Swift
接口校验，以匹配预编译 Core 的 ABI。保留原有的 `react_native_post_install` 回调，
App target 的发行模式保持 No。

在项目根目录安装插件和 Pods：

```bash
npm install @faceaisdk/react-native-face-sdk@1.8.0
cd ios && pod install
```

React Native autolinking 会加载 SDK podspec，自动注册 modulemap 和 ABI 配置，无需手动添加
SDK 的 `require_relative` 或调用 `faceaisdk_post_install(installer)`，保留项目原有的
`react_native_post_install`。升级时，可移除 1.7.4 的 TensorFlowLiteSwift 临时配置，
以及旧版 SDK 的 `require_relative '.../faceaisdk_post_install.rb'` 和 `faceaisdk_post_install(installer)`（如有），
重新执行 `pod install` 并构建原生应用。

### Android

在项目根目录安装插件：

```bash
npm install @faceaisdk/react-native-face-sdk@1.8.0
```

使用 `minSdkVersion >= 24` 和 `compileSdkVersion >= 34`，在
`android/app/src/main/AndroidManifest.xml` 声明相机权限：

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

运行时权限申请见 [App.tsx](./App.tsx) 的 `requestCameraPermission`；
iOS 权限弹窗由 SDK 处理。

## 常见问题

- **进入相机录入或比对后闪退：**若在 `TensorFlowLite.Interpreter.init`
  触发 `EXC_BREAKPOINT` / `SIGTRAP`，确认已安装 npm SDK 1.8.0，再执行 `pod install`
  并重建应用，使自动 TensorFlowLiteSwift ABI 配置生效。App target 的发行模式保持 No。
- **SDK 不可用：**确认依赖已安装；iOS 执行 `pod install`，打开 `.xcworkspace`。
  安装或升级 SDK 后重新构建原生应用。
- **TensorFlowLite Swift 接口校验失败：**若 `SwiftVerifyEmittedModuleInterface` 报错
  `underlying Objective-C module 'TensorFlowLite' not found`，将 App target 的
  Debug、Release 配置中的 `BUILD_LIBRARY_FOR_DISTRIBUTION` 显式设为 `NO`，确认已安装
  npm SDK 1.8.0 后重新执行 `pod install`。SDK 会自动为 TensorFlowLiteSwift 开启发行
  模式并跳过接口校验；仅在构建命令行设置，不会更新 CocoaPods 生成的 Pods 配置。
- **Debug 页面无法加载：**确认 Metro 在 8765 端口运行，检查手机到电脑的网络、
  Metro 主机地址和本地网络权限。
- **特征或图片录入失败：**为演示常量配置真实数据；已有特征被覆盖后，需要重新录入人脸。

## 相关示例与反馈

[iOS](https://github.com/FaceAISDK/FaceAISDK_iOS) ·
[Android](https://github.com/FaceAISDK/FaceAISDK_Android) ·
[uniApp](https://github.com/FaceAISDK/FaceAISDK_uniapp_UTS) ·
[Flutter](https://github.com/FaceAISDK/FaceRecognition_Flutter)

[GitHub Issues](https://github.com/FaceAISDK/FaceRecognition_ReactNative/issues) ·
FaceAISDK.Service@gmail.com
