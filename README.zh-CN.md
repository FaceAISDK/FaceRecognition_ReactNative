<p align="center">
  <img src="./ios/FaceAISDK_RN/Images.xcassets/AppIcon.appiconset/icon-1024x1024@1x.png" width="96" height="96" alt="FaceAISDK" />
</p>

<h1 align="center">FaceAISDK · React Native</h1>

<p align="center">
  离线人脸录入 · 1:1 比对 · 活体检测 · 特征管理
</p>

<p align="center">
  <a href="./README.md">English</a> · <strong>简体中文</strong>
</p>

<p align="center">
  <a href="#快速开始">快速开始</a> ·
  <a href="./docs/API.zh-CN.md">接入与 API 文档</a> ·
  <a href="./App.tsx">Demo 源码</a>
</p>

<p align="center">
  <code>SDK 1.8.0</code> &nbsp; <code>React Native 0.84.0</code>
</p>

`main` 是已发布 npm 插件
[`@faceaisdk/react-native-face-sdk`](https://www.npmjs.com/package/@faceaisdk/react-native-face-sdk) 的演示工程。

> **请使用真机：** iOS **15.5+** 或 Android **API 24+**，不支持模拟器。

## 快速开始

### 安装依赖

```bash
npm ci
npm run doctor
```

`doctor` 检查依赖版本与本机工具链。只检查单个平台时，可使用
`npm run doctor -- --android` 或 `npm run doctor -- --ios`。

### Android

连接并解锁手机，开启 **USB 调试**，在手机上允许此电脑调试。

```bash
# 终端 1：保持 Metro 在 8765 端口运行
npm start
```

```bash
# 终端 2：安装并运行到真机
npm run android
```

### iOS

```bash
cd ios && pod install --deployment && cd ..
```

用 Xcode 打开 **`ios/FaceAISDK_RN.xcworkspace`**，选择自己的 **Development Team**，
连接并解锁 iPhone。

```bash
npm run ios
```

共享 Scheme 默认运行 **Release**，已内置 JavaScript。
需要 **Debug** 时，先执行 `npm start`，再执行 `npm run ios -- --mode Debug`。

<details>
<summary><strong>iOS 16 及更早版本</strong></summary>

使用旧版设备安装命令：

```bash
npm run ios:legacy
```

安装 Release 后，点击手机上的应用图标启动。构建日志保存在
`ios/build/ios-legacy.log`。

</details>

## 环境与版本

Node.js 需 **22.11+**。Android 组件通过 **SDK Manager** 安装，并配置
`ANDROID_HOME` 或 `android/local.properties`。

<details>
<summary><strong>展开已验证的工具链</strong></summary>

| 组件                      | 已验证版本                           |
| :------------------------ | :----------------------------------- |
| Node.js / npm             | `26.0.0` / `11.12.1`                 |
| React Native / CLI        | `0.84.0` / `20.2.0`                  |
| Xcode / Swift / CocoaPods | `26.6 (17F113)` / `6.3.3` / `1.16.2` |
| JDK                       | `17`                                 |
| Android SDK / Build Tools | `34` / `35.0.0`                      |
| Android NDK / CMake       | `28.1.13356709` / `3.22.1`           |
| Gradle wrapper            | `8.14.3`（项目已自带）               |
| Android 原生 SDK          | `2026.10.29.meiju`                   |
| iOS Core                  | `2026.10.29`                         |

</details>

插件已精确锁定版本。保留并提交 `package-lock.json`、`ios/Podfile.lock`；
升级时同步调整插件、iOS Core tag 和两个锁文件。

## 常见问题

| 现象               | 处理方式                                              |
| :----------------- | :---------------------------------------------------- |
| SDK 不可用         | 安装依赖与 Pods 后，重新构建原生应用。                |
| 版本冲突           | 执行 `npm run doctor`，核对两个锁文件后重新安装。     |
| 提示未录入         | 先完成相机录入并确认保存，再进行比对。                |
| Debug 页面无法加载 | 检查 Metro 及手机访问电脑 `8765` 端口的网络。         |
| iOS 安装失败       | 改用 Xcode 运行；iOS 16 及更早版本使用 `ios:legacy`。 |

---

<p align="center">
  <a href="https://github.com/FaceAISDK/FaceRecognition_ReactNative/issues">问题反馈</a> ·
  <a href="mailto:FaceAISDK.Service@gmail.com">FaceAISDK.Service@gmail.com</a>
</p>
