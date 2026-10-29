# FaceAISDK React Native 示例

[English](./README.md) | [中文](./README.zh-CN.md)

使用 [`@faceaisdk/react-native-face-sdk`](https://www.npmjs.com/package/@faceaisdk/react-native-face-sdk)
演示真机上的离线人脸录入、比对、活体检测和特征管理。

`main` 是 npm 插件消费示例；插件源码和完整 API 文档位于
[`dev`](https://github.com/FaceAISDK/FaceRecognition_ReactNative/tree/dev)。

## 环境要求

仅支持真机：iOS 15.5+ 或 Android API 24+。

已验证环境：

| 组件 | 版本 |
| --- | --- |
| Node.js / npm | 26.0.0 / 11.12.1（Node.js 最低 22.11）|
| React Native / CLI | 0.84.0 / 20.2.0 |
| 插件 / 原生 SDK | 1.8.0 / Android 2026.10.29.meiju / iOS Core 2026.10.29 |
| iOS | Xcode 26.6（17F113）、Swift 6.3.3、CocoaPods 1.16.2 |
| Android | JDK 17、SDK 34、Build Tools 35.0.0、NDK 28.1.13356709、CMake 3.22.1 |

Android 组件通过 SDK Manager 安装，配置 `ANDROID_HOME` 或
`android/local.properties`。项目自带 Gradle wrapper 8.14.3。

## 运行

```bash
npm ci
npm run doctor
```

插件已精确锁定版本。保留两个锁文件，升级时同步修改插件、iOS Core tag 和锁文件。
`doctor` 可加 `-- --android` 或 `-- --ios`，只检查单个平台。

### Android

连接并解锁手机，开启 USB 调试，允许此电脑调试：

```bash
npm start          # Metro 使用 8765 端口，保持运行
npm run android    # 在另一个终端执行
```

### iOS

```bash
cd ios && pod install --deployment && cd ..
```

用 Xcode 打开 `ios/FaceAISDK_RN.xcworkspace`，选择自己的 Development Team，
连接并解锁 iPhone：

```bash
npm run ios
```

共享 Scheme 默认运行 Release，内置 JavaScript。需要 Debug 时，先运行
`npm start`，再执行 `npm run ios -- --mode Debug`。

iOS 16 及更早版本使用 `npm run ios:legacy`，安装 Release 后点击手机图标启动。
构建日志位于 `ios/build/ios-legacy.log`。

## 演示功能

调用代码见 [App.tsx](./App.tsx)。先相机录入并确认保存，再查询或比对同一个
`demo-user`；独立活体检测无需录入。

| 功能 | API |
| --- | --- |
| 相机录入 | `addFaceBySDKCamera` |
| 人脸比对 + 活体 | `faceVerify` |
| 独立活体检测 | `livenessVerify` |
| 查询 / 写入 / 删除特征 | `getFaceFeature` / `insertFaceFeature` / `deleteFaceFeature` |
| Base64 图片录入 | `addFaceByImage` |

导入前在 `App.tsx` 配置 `DEMO_FACE_FEATURE` 或 `DEMO_BASE64_IMAGE`，写入会覆盖同一
faceID 的已有数据。检查返回的 `code` 和 `message` 判断业务结果，业务失败不一定抛异常。
示例仅展示特征和图片字符串的长度。

接入自己的项目请查看[插件接入文档](https://github.com/FaceAISDK/FaceRecognition_ReactNative/tree/dev)。
iOS 需配置相机用途说明，并将 App target 的 Debug、Release 中
`BUILD_LIBRARY_FOR_DISTRIBUTION` 设为 `NO`；SDK 1.8.0 自动配置 TensorFlowLite。
Android 需声明相机权限并在运行时申请。

## 常见问题

- **SDK 不可用：**安装依赖与 Pods 后重新构建原生应用。
- **版本冲突：**执行 `npm run doctor`，核对两个锁文件后重新安装。
- **提示未录入：**先完成相机录入并确认保存。
- **Debug 页面无法加载：**检查 Metro 及手机访问电脑 8765 端口的网络。
- **iOS 安装失败：**改用 Xcode 运行；iOS 16 及更早版本使用 `ios:legacy`。

[问题反馈](https://github.com/FaceAISDK/FaceRecognition_ReactNative/issues) · FaceAISDK.Service@gmail.com
