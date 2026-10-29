# @faceaisdk/react-native-face-sdk

[English](#english) | [中文](#中文)

---

## English

React Native offline face enrollment, verification, and liveness detection SDK. Supports iOS and Android. All functions run offline without the need for backend API services.

Version 1.8.0 updates the Android SDK to `2026.10.29.meiju` and iOS Core to
`2026.10.29`. Android exposes the native SDK dependency through `api`. On iOS,
the automatic hook supplies the TensorFlowLite modulemap and preserves the
TensorFlowLiteSwift ABI required by Core, including variant targets and separate
Pod projects. No manual SDK post-install call is needed.

> ⚠️ **Important**: This SDK involves low-level hardware and native algorithms. **It must be tested on a physical device**; it will not function on an emulator.

### Installation

```bash
npm install @faceaisdk/react-native-face-sdk
```

#### iOS Configuration

1. Set the app's iOS deployment target and the `platform :ios` in `ios/Podfile` to **15.5** or later.
2. Explicitly set **App target → Build Settings → Build Libraries for Distribution**
   (`BUILD_LIBRARY_FOR_DISTRIBUTION`) to **No** in Debug and Release. Core 2026.10.29
   exports `YES` to the host xcconfig; overriding it on the App prevents CocoaPods
   from enabling distribution mode for unrelated Swift Pods.
3. Install the Pod dependencies (TensorFlowLiteSwift may take a while depending on the network):
   ```bash
   cd ios && pod install
   ```
   React Native autolinking loads the SDK's podspec, which automatically supplies
   the TensorFlowLite modulemap and ABI settings needed for static library integration.
   Keep your existing `react_native_post_install` callback.
   No SDK-specific `require_relative` or `faceaisdk_post_install` call is needed.
4. Add the camera permission to your `Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need access to your camera for face recognition and liveness detection.</string>
   ```

When upgrading from the manual setup, remove the `require_relative '.../faceaisdk_post_install.rb'` line and the `faceaisdk_post_install(installer)` call from your Podfile, then run `pod install` again. Existing manual calls remain compatible.

When upgrading from 1.7.4, the temporary TensorFlowLiteSwift workaround copied
from the demo's Podfile can also be removed; 1.8.0 applies those settings automatically.

Core was compiled against TensorFlowLiteSwift's library evolution ABI. Disabling
it changes how `Interpreter.Options` is passed and causes `EXC_BREAKPOINT` / `SIGTRAP`
in `Interpreter.init`. The fix sets `BUILD_LIBRARY_FOR_DISTRIBUTION=YES` and adds
`-no-verify-emitted-module-interface` only to TensorFlowLiteSwift. The automatic
hook leaves the App and unrelated Pods unchanged; keep the App set to No.

#### Android Configuration

1. Ensure your project's `minSdkVersion` is at least **24**.
2. Ensure your project's `compileSdkVersion` is at least **34**.
3. Add the camera permission to your `AndroidManifest.xml`:
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

| Property      | Type     | Description                                   |
| :------------ | :------- | :-------------------------------------------- |
| `code`        | `number` | Status code                                   |
| `message`     | `string` | Message                                       |
| `faceID`      | `string` | User identifier                               |
| `similarity`  | `number` | Similarity score                              |
| `liveness`    | `number` | Liveness score                                |
| `faceFeature` | `string` | Base64-encoded face feature (1024 characters) |
| `faceBase64`  | `string` | Base64 face image                             |

Check `code` for the business result and use `message` for user-facing text.
An SDK business failure does not necessarily reject the promise. Enroll and save
the face before calling `faceVerify`; standalone `livenessVerify` needs no enrollment.

---

## 中文

FaceAISDK 人脸识别、活体检测 React Native 原生插件，支持 iOS 和 Android 双端；所有功能无需后台 API 服务即可离线运行。

1.8.0 将 Android SDK 升级为 `2026.10.29.meiju`，iOS Core 升级为 `2026.10.29`。
Android 通过 `api` 导出原生 SDK 依赖；iOS 自动回调会补齐 TensorFlowLite modulemap，
并为 TensorFlowLiteSwift 保持 Core 所需的 ABI，覆盖变体 target 和独立 Pod project。
无需手动调用 SDK 的 post-install 脚本。

> ⚠️ **重要提示**：本 SDK 涉及底层硬件与原生算法，**必须使用真机测试**，模拟器无法运行。

### 安装

```bash
npm install @faceaisdk/react-native-face-sdk
```

#### iOS 配置

1. 将 App 的 iOS 部署版本及 `ios/Podfile` 中的 `platform :ios` 设为 **15.5** 或更高。
2. 在 **App target → Build Settings → Build Libraries for Distribution**
   （`BUILD_LIBRARY_FOR_DISTRIBUTION`）中将 Debug、Release 显式设为 **No**。
   Core 2026.10.29 会向宿主 xcconfig 导出 `YES`；App 显式覆盖后，可避免 CocoaPods
   为其他 Swift Pods 开启发行模式。
3. 进入 `ios` 目录并安装 Pod 依赖（TensorFlowLiteSwift 根据网络状态可能耗时较长）：
   ```bash
   cd ios && pod install
   ```
   React Native autolinking 会加载 SDK 的 podspec，自动补齐静态库集成所需的
   TensorFlowLite modulemap 和 ABI 配置。保留项目原有的 `react_native_post_install`，
   无需手动引入脚本或调用 `faceaisdk_post_install`。
4. 在 `Info.plist` 中添加相机权限描述：
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>我们需要访问您的相机进行人脸识别与活体检测</string>
   ```

从旧版手动配置升级时，可删除 Podfile 中的 `require_relative '.../faceaisdk_post_install.rb'` 和 `faceaisdk_post_install(installer)`，再执行一次 `pod install`。保留旧调用也兼容。

从 1.7.4 升级时，也可移除此前从示例 Podfile 复制的 TensorFlowLiteSwift 临时配置；
1.8.0 已自动执行这些设置。

Core 预编译时使用了 TensorFlowLiteSwift 的 library evolution ABI；关闭它会使
`Interpreter.Options` 传参方式不匹配，在 `Interpreter.init` 触发
`EXC_BREAKPOINT` / `SIGTRAP`。修复仅为 TensorFlowLiteSwift 设置
`BUILD_LIBRARY_FOR_DISTRIBUTION=YES` 并添加 `-no-verify-emitted-module-interface`。
自动回调不会修改 App 和其他 Pods，App 的发行模式保持 No。

#### Android 配置

1. 确保项目的 `minSdkVersion` 至少为 **24**。
2. 确保项目的 `compileSdkVersion` 至少为 **34**。
3. 在 `AndroidManifest.xml` 中声明相机权限：
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

| 属性          | 类型     | 说明                                 |
| :------------ | :------- | :----------------------------------- |
| `code`        | `number` | 状态码                               |
| `message`     | `string` | 提示文本                             |
| `faceID`      | `string` | 用户标识                             |
| `similarity`  | `number` | 比对相似度                           |
| `liveness`    | `number` | 活体检测分值                         |
| `faceFeature` | `string` | Base64 编码的人脸特征（1024 个字符） |
| `faceBase64`  | `string` | 人脸图片 Base64 字符串               |

根据 `code` 判断业务结果，使用 `message` 展示提示；SDK 业务失败不一定抛出异常。
调用 `faceVerify` 前需录入并保存人脸，独立 `livenessVerify` 无需录入。

---

## Support & Feedback

Issues: [GitHub Issues](https://github.com/FaceAISDK/FaceRecognition_ReactNative/issues)  
Email: FaceAISDK.Service@gmail.com
