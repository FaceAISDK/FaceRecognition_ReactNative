# @faceaisdk/react-native-face-sdk
# new here https://github.com/FaceAISDK/FaceRecognition_ReaceNative
# new here https://github.com/FaceAISDK/FaceRecognition_ReaceNative



[English](#english) | [中文](#中文)

---

## English

React Native offline face enrollment, verification, and liveness detection SDK. Supports iOS and Android. All functions run offline without the need for backend API services.

> ⚠️ **Important**: This SDK involves low-level hardware and native algorithms. **It must be tested on a physical device**; it will not function on an emulator.

### Installation

```bash
npm install @faceaisdk/react-native-face-sdk
```

#### iOS Configuration
1. Update your `ios/Podfile` to include the SDK post-install hook:
   ```ruby
   require_relative '../node_modules/@faceaisdk/react-native-face-sdk/scripts/faceaisdk_post_install.rb'

   post_install do |installer|
     react_native_post_install(installer, config[:reactNativePath], :mac_catalyst_enabled => false)
     faceaisdk_post_install(installer)
   end
   ```
2. cd ios and run pod install (TensorFlowLiteSwift may take a while depending on the network)
   ```bash
   cd ios && pod install
   ```
3. Add the camera permission to your `Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need access to your camera for face recognition and liveness detection.</string>
   ```

#### Android Configuration
1. Ensure your project's `minSdkVersion` is at least **24**.
2. Add the camera permission to your `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   ```

### API Usage

```ts
import {
  addFaceBySDKCamera,
  faceVerify,
  livenessVerify,
  getFaceFeature,
  insertFaceFeature,
  addFaceByImage,
  deleteFaceFeature,
} from '@faceaisdk/react-native-face-sdk';
```

#### 1. Enroll Face by SDK Camera
```ts
addFaceBySDKCamera(faceID: string, options?: { mode?: number; showConfirm?: boolean }) => Promise<FaceResult>
```

#### 2. Face Verification (1:1 + Liveness)
```ts
faceVerify(faceID: string, options?: FaceVerifyOptions) => Promise<FaceResult>
```

#### 3. Liveness Detection
```ts
livenessVerify(options?: LivenessVerifyOptions) => Promise<FaceResult>
```

### Data Structures (`FaceResult`)

| Property      | Type | Description |
|:--------------| :--- | :--- |
| `code`        | `number` | Status code |
| `message`     | `string` | Message |
| `faceID`      | `string` | User identifier |
| `similarity`  | `number` | Similarity score |
| `liveness`    | `number` | Liveness score |
| `faceFeature` | `string` | 1024-bit face feature string |
| `faceBase64`  | `string` | Base64 face image |

---

## 中文
# new here https://github.com/FaceAISDK/FaceRecognition_ReaceNative
# new here https://github.com/FaceAISDK/FaceRecognition_ReaceNative


FaceAISDK 人脸识别、活体检测 React Native 原生插件，支持 iOS 和 Android 双端；所有功能无需后台 API 服务即可离线运行。

> ⚠️ **重要提示**：本 SDK 涉及底层硬件与原生算法，**必须使用真机测试**，模拟器无法运行。

### 安装

```bash
npm install @faceaisdk/react-native-face-sdk
```

#### iOS 配置
1. 在您的 `ios/Podfile` 中接入必要的脚本：
   ```ruby
   require_relative '../node_modules/@faceaisdk/react-native-face-sdk/scripts/faceaisdk_post_install.rb'

   post_install do |installer|
     react_native_post_install(installer, config[:reactNativePath], :mac_catalyst_enabled => false)
     faceaisdk_post_install(installer)
   end
   ```
2. 进入 `ios` 目录并安装 Pod 依赖(TensorFlowLiteSwift根据网络状态会需要比较长时间)
   ```bash
   cd ios && pod install
   ```
3. 在 `Info.plist` 中添加相机权限描述：
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>我们需要访问您的相机进行人脸识别与活体检测</string>
   ```

#### Android 配置
1. 确保项目的 `minSdkVersion` 至少为 **24**。
2. 在 `AndroidManifest.xml` 中声明相机权限：
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   ```

### 核心方法

#### 1. SDK 相机录入人脸
```ts
addFaceBySDKCamera(faceID: string, options?: { mode?: number; showConfirm?: boolean }) => Promise<FaceResult>
```

#### 2. 人脸比对 + 活体检测
```ts
faceVerify(faceID: string, options?: FaceVerifyOptions) => Promise<FaceResult>
```

#### 3. 纯活体检测
```ts
livenessVerify(options?: LivenessVerifyOptions) => Promise<FaceResult>
```

### 统一返回结构 (`FaceResult`)

| 属性            | 类型 | 说明 |
|:--------------| :--- | :--- |
| `code`        | `number` | 状态码 |
| `mseeage`     | `string` | 提示文本 |
| `faceID`      | `string` | 用户标识 |
| `similarity`  | `number` | 比对相似度 |
| `liveness`    | `number` | 活体检测分值 |
| `faceFeature` | `string` | 人脸特征值 (1024位) |
| `faceBase64`  | `string` | 人脸图片 Base64 字符串 |

---

## Support & Feedback
Issues: [GitHub Issues](https://github.com/FaceAISDK/FaceAISDK_RN/issues)  
Email: FaceAISDK.Service@gmail.com
