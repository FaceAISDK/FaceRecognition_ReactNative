# FaceAISDK React Native 示例

[English](./README.md) | [中文](./README.zh-CN.md)

使用 [`@faceaisdk/react-native-face-sdk`](https://www.npmjs.com/package/@faceaisdk/react-native-face-sdk)
演示 iOS / Android 离线人脸录入、比对、活体检测和特征管理。

## 环境要求

- Node.js 22.11+、React Native 0.84.0、CLI 20.2.0、Face SDK 1.7.2（Android 2026.09.29、iOS Core 2026.09.22）。
- iOS 15.5+ 或 Android API 24+ 真机；不支持模拟器。
- iOS 需要 Xcode 和 CocoaPods；Android 需要 Android SDK（compile SDK 34）和 JDK 17。

## 运行

安装依赖并启动 Metro（端口 8765）：

```bash
npm install
npm start
```

保持 Metro 运行，在另一个终端执行以下命令。

### Android

连接已开启 USB 调试的真机：

```bash
npm run android
```

### iOS

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

Debug 调试时，iPhone 需要能访问电脑的 Metro 8765 端口。
若 CLI 的 `devicectl` 安装失败，请在 Xcode 选择已连接的真机，使用 **Product > Run**。

#### iOS 16 及更早版本

使用 `ios-deploy` 安装调试，不经过 `devicectl`。连接并解锁一台 iPhone，信任电脑，
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
- `App.tsx` 的 `DEMO_FACE_FEATURE` 和 `DEMO_BASE64_IMAGE` 默认为空；
  未配置时点击菜单只显示提示，不调用 SDK。使用前请填入真实 SDK 特征和有效
  Base64 图片。写入特征会覆盖同一人脸 ID 的已有数据。
- `motionTypes` 是逗号分隔的动作 ID；`timeout`、`steps`、`allowMultiFaces`
  分别控制超时、动作数量和多脸处理。`faceVerify` 还支持 `threshold`（默认 `0.83`），
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

```bash
npm install @faceaisdk/react-native-face-sdk@latest
```

### iOS

在 `ios/Podfile` 加载辅助脚本，并在 React Native 的 post-install 之后调用：

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

在 `Info.plist` 添加相机用途说明，再执行 `pod install`：

```xml
<key>NSCameraUsageDescription</key>
<string>人脸识别和活体检测需要使用相机。</string>
```

### Android

使用 `minSdkVersion >= 24` 和 `compileSdkVersion >= 34`，在
`android/app/src/main/AndroidManifest.xml` 声明相机权限：

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

运行时权限申请见 [App.tsx](./App.tsx) 的 `requestCameraPermission`；
iOS 权限弹窗由 SDK 处理。

## 常见问题

- **SDK 不可用：**确认依赖已安装；iOS 执行 `pod install`，打开 `.xcworkspace`。
  安装或升级 SDK 后重新构建原生应用。
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
