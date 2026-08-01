# FaceAISDK人脸识别活体检测React Native 示例

[English](./README.md) | [中文](./README.zh-CN.md)

本仓库是
[`@faceaisdk/react-native-face-sdk`](https://www.npmjs.com/package/@faceaisdk/react-native-face-sdk)
的 React Native API示例，演示 iOS 和 Android 端的离线人脸录入、1:1 比对、
活体检测和人脸特征管理。

> SDK 依赖设备相机和原生人脸算法，必须使用真机；不支持模拟器。

## 功能

- 使用 SDK 相机离线录入人脸
- 人脸 1:1 比对与活体检测
- 独立活体检测
- 查询、写入和删除人脸特征
- 传入自定义 Base64 图片录入人脸

## 环境要求

| 项目         | 要求                                                       |
| ------------ | ---------------------------------------------------------- |
| Node.js      | 22.11 或更高版本                                           |
| React Native | 本示例使用 0.84.0                                          |
| Face SDK     | 本示例使用 `^1.1.0`                                        |
| iOS          | 15.0 或更高版本，必须使用真机                              |
| Android      | `minSdkVersion` 24+、`compileSdkVersion` 34+，必须使用真机 |

## 运行本示例

安装 JavaScript 依赖：

```bash
npm install
```

### Android

在一个终端中启动 Metro：

```bash
npm start
```

连接已开启 USB 调试的 Android 真机，然后在另一个终端运行：

```bash
npm run android
```

### iOS

安装 CocoaPods 依赖：

```bash
cd ios
pod install
cd ..
```

使用 Xcode 打开 `ios/FaceAISDK_RN.xcworkspace`，然后在
**Signing & Capabilities** 中选择 Development Team。

分别在两个终端中启动 Metro 和应用：

```bash
npm start
npm run ios
```

## 在其他项目中安装 SDK

```bash
npm install @faceaisdk/react-native-face-sdk latest
```

### iOS 配置

在 `ios/Podfile` 顶部附近加载 SDK 的 post-install 脚本：

```ruby
require_relative '../node_modules/@faceaisdk/react-native-face-sdk/scripts/faceaisdk_post_install.rb'
```

在 React Native 的 post-install 步骤之后调用该脚本：

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

安装 Pods：

```bash
cd ios && pod install
```

在 `Info.plist` 中添加相机权限说明：

```xml
<key>NSCameraUsageDescription</key>
<string>人脸识别和活体检测需要使用相机。</string>
```

### Android 配置

确保 Android 工程至少使用：

```gradle
minSdkVersion = 24
compileSdkVersion = 34
```

在 `android/app/src/main/AndroidManifest.xml` 中声明相机权限：

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

Android 还必须在运行时请求相机权限。完整的 `PermissionsAndroid` 示例请参考
[`App.tsx`](./App.tsx)。

## 导入

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

## API 示例

### 检查原生模块是否可用

```ts
const available = isFaceAIModuleAvailable();
```

调用其他 API 前，可以使用此方法发现原生安装或链接是否完整。

### 使用 SDK 相机录入人脸

```ts
const result = await addFaceBySDKCamera('demo-user', {
  mode: 1,
  showConfirm: true,
});
```

| 参数          | 类型      | 说明             |
| ------------- | --------- | ---------------- |
| `mode`        | `1 \| 2`  | 相机录入模式     |
| `showConfirm` | `boolean` | 是否显示确认步骤 |

### 人脸比对与活体检测

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

### 独立活体检测

```ts
const result = await livenessVerify({
  livenessType: 1,
  motionTypes: '1,2,3,4,5',
  timeout: 7,
  steps: 2,
  allowMultiFaces: true,
});
```

`faceVerify` 和 `livenessVerify` 共用以下活体参数：

| 参数              | 类型               | 说明                       |
| ----------------- | ------------------ | -------------------------- |
| `livenessType`    | `1 \| 2 \| 3 \| 4` | 活体检测模式               |
| `motionTypes`     | `string`           | 使用逗号分隔的动作类型 ID  |
| `timeout`         | `number`           | 活体检测超时参数           |
| `steps`           | `number`           | 活体检测步骤数量           |
| `allowMultiFaces` | `boolean`          | 是否允许画面中出现多张人脸 |

`faceVerify` 还支持 `threshold`，用于设置人脸相似度阈值。

### 查询人脸特征

```ts
const result = await getFaceFeature('demo-user');
```

### 写入自定义人脸特征

```ts
const customFeature = '0'.repeat(1024);
const result = await insertFaceFeature('demo-user', customFeature);
```

这里的占位值用于演示如何传入自定义特征。需要成功执行时，请替换为有效的人脸特征。

### 使用自定义 Base64 图片录入

```ts
const customBase64Image = 'demo_base64_image_string';
const result = await addFaceByImage('demo-user', customBase64Image);
```

请将占位值替换为有效的 Base64 图片。

### 删除人脸特征

```ts
const result = await deleteFaceFeature('demo-user');
```

## 返回结果

所有异步 API 都返回 `FaceResult`：

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

| 属性          | 类型     | 说明            |
| ------------- | -------- | --------------- |
| `code`        | `number` | SDK 返回码      |
| `message`     | `string` | SDK 返回信息    |
| `faceID`      | `string` | 人脸标识        |
| `similarity`  | `number` | 人脸相似度      |
| `liveness`    | `number` | 活体检测分值    |
| `faceFeature` | `string` | 人脸特征数据    |
| `faceBase64`  | `string` | Base64 人脸图片 |

SDK 提示文本可以直接使用 `message`。为了避免弹窗中出现过长内容，示例只展示
人脸特征和 Base64 图片的长度。

## 常见问题

### 页面显示“SDK 未连接”

- 确认 `dependencies` 中已经安装 SDK。
- iOS 执行 `pod install` 后，应打开 `.xcworkspace`，不要打开 `.xcodeproj`。
- 安装或升级 SDK 后需要重新构建原生应用。

### 自定义特征或 Base64 录入失败

`App.tsx` 中的常量是故意保留的假数据，只用于演示自定义参数传递。需要成功执行时，
请替换为有效的人脸特征或 Base64 图片。

## 其他 SDK 示例

- [iOS SDK](https://github.com/FaceAISDK/FaceAISDK_iOS)
- [Android SDK](https://github.com/FaceAISDK/FaceAISDK_Android)
- [uniApp UTS](https://github.com/FaceAISDK/FaceAISDK_uniapp_UTS)
- [Flutter](https://github.com/FaceAISDK/FaceRecognition_Flutter)
- [React Native](https://github.com/FaceAISDK/FaceRecognition_ReactNative)

## 支持与反馈

- [GitHub Issues](https://github.com/FaceAISDK/FaceRecognition_ReactNative/issues)
- Email: FaceAISDK.Service@gmail.com
