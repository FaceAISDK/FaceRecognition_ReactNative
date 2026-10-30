# SDK 1.8.0 接入与 API 文档

[English](./API.md) | [中文](./API.zh-CN.md) · [Demo README](../README.zh-CN.md)

本文对应已发布的 `@faceaisdk/react-native-face-sdk@1.8.0`，原生依赖为 Android
`2026.10.29.meiju`、iOS Core `2026.10.29`，需使用真机。
包声明的 peer dependency 范围为 React >=18、React Native >=0.71；
本示例已验证 React 19.2.3、React Native 0.84.0。

## 接口目录

- [isFaceAIModuleAvailable](#isfaceaimoduleavailable)：检查原生桥接。
- [addFaceBySDKCamera](#addfacebysdkcamera)：相机录入。
- [faceVerify](#faceverify)：人脸比对与活体检测。
- [livenessVerify](#livenessverify)：独立活体检测。
- [getFaceFeature](#getfacefeature)：查询本地特征。
- [insertFaceFeature](#insertfacefeature)：写入已有特征。
- [addFaceByImage](#addfacebyimage)：图片录入。
- [deleteFaceFeature](#deletefacefeature)：删除本地特征。

## 接入现有 React Native 工程

```bash
npm install --save-exact @faceaisdk/react-native-face-sdk@1.8.0
```

### iOS

1. 将 App 最低部署版本及 Podfile 的 `platform :ios` 设为 **15.5** 或更高。
2. 在 **App target → Build Settings → Build Libraries for Distribution** 中，
   将 Debug、Release 的 `BUILD_LIBRARY_FOR_DISTRIBUTION` 都显式设为 **No**。
3. 在 `Info.plist` 配置相机用途说明：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机进行人脸识别和活体检测。</string>
```

4. 执行 `cd ios && pod install`，重新构建原生应用。打开 `.xcworkspace`，
   真机签名时选择自己的 Development Team。

Autolinking 会加载插件 podspec。1.8.0 自动补齐 TensorFlowLite modulemap 和
TensorFlowLiteSwift ABI 配置，保留原有 `react_native_post_install` 即可，
无需额外调用 SDK post-install 脚本。此前针对 1.7.4 添加的 TensorFlowLiteSwift
临时配置可以移除。iOS 相机权限弹窗由 SDK 处理。

本 Demo 的 Podfile 额外固定了 Core Git tag，升级时须同步修改 npm 版本、Core tag
及两个锁文件。**运行本 Demo** 按 README 使用 `npm ci` 和 `pod install --deployment`；
上面的安装命令用于在其他工程中接入 SDK。

### Android

使用 `minSdkVersion >= 24`、`compileSdkVersion >= 34`，在 App manifest 中声明：

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

打开 SDK 相机页面前申请运行时权限，安装插件后重新构建原生应用。
桥接由 Autolinking 处理，原生 Maven 依赖由插件提供；权限处理示例见下文。

## 调用约定

从 `@faceaisdk/react-native-face-sdk` 具名导入接口。七个业务接口均返回
`Promise<FaceResult>`；`isFaceAIModuleAvailable` 同步返回 `boolean`。
相机接口须在 App 前台调用，并等待当前操作结束后再发起下一个。
Android 1.8.0 的原生桥接只保存一个待处理的相机回调。

`faceID` 使用非空、稳定的字符串，例如 `user-001`。它既是本地记录键，也会用于图片
文件名，避免使用路径分隔符。录入或写入同一 ID 会覆盖已有记录；录入、查询、比对、删除
使用同一 ID。`faceFeature` 是 SDK 生成的特征字符串，不是图片 Base64，应原样保存和传递。

### 共用相机调用辅助函数

将以下**应用侧示例函数**保存为 `face-sdk-helpers.ts`，供后续相机示例复用。
它处理 Android 权限拒绝，并防止相机调用重叠；该函数不是插件导出接口。
永久拒绝权限时，界面可提供“打开设置”操作，调用 `Linking.openSettings()`。

```ts
import {PermissionsAndroid, Platform} from 'react-native';
import {isFaceAIModuleAvailable} from '@faceaisdk/react-native-face-sdk';

let cameraBusy = false;

// Application helper; this is not an SDK export.
export async function withSdkCamera<T>(call: () => Promise<T>): Promise<T> {
  if (cameraBusy) throw new Error('A camera operation is already running');
  cameraBusy = true;
  try {
    if (!isFaceAIModuleAvailable())
      throw new Error('Rebuild the native app first');
    if (Platform.OS === 'android') {
      const permission = PermissionsAndroid.PERMISSIONS.CAMERA;
      if (!(await PermissionsAndroid.check(permission))) {
        const status = await PermissionsAndroid.request(permission);
        if (status !== PermissionsAndroid.RESULTS.GRANTED) {
          throw new Error(
            status === PermissionsAndroid.RESULTS.NEVER_ASK_AGAIN
              ? 'Enable camera permission in system settings'
              : 'Camera permission denied',
          );
        }
      }
    }
    return await call();
  } finally {
    cameraBusy = false;
  }
}
```

辅助函数等原生回调后才释放调用锁。JavaScript 的 `Promise.race` 超时不等于关闭原生
相机页面；前一次原生操作结束前不要再次打开相机。SDK 1.8.0 未提供取消接口。

## FaceResult

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

| 字段          | 含义                                                                                         |
| ------------- | -------------------------------------------------------------------------------------------- |
| `code`        | 原生业务结果码，必须结合所调用的接口判断，见下表。                                           |
| `message`     | 原生提示，可能已本地化；用于展示与排错，不作为稳定枚举。                                     |
| `faceID`      | 本次请求的本地 ID；独立活体检测为空字符串。                                                  |
| `similarity`  | `faceVerify` 的人脸相似度；其他接口不使用时为 `0`。                                          |
| `liveness`    | 比对/活体检测返回的活体分数；不使用时为 `0`。                                                |
| `faceFeature` | 录入、图片录入或查询返回的特征，其余接口通常为空。可查询、比对的有效特征长度为 1024 个字符。 |
| `faceBase64`  | 相机操作提供的人脸图片 Base64，未提供时为空；操作成功也不保证一定有图片。                    |

JavaScript 层将缺失的数值字段补为 `0`、字符串字段补为 `''`，因此零分或空字符串也可能
表示“未提供”。避免打印完整特征和图片字符串，Demo 仅展示长度。

### 结果码判定

| 接口 / 情况                       | 判定                                                                         |
| --------------------------------- | ---------------------------------------------------------------------------- |
| 相机录入、图片录入、特征写入/删除 | `code === 1` 表示成功。                                                      |
| `getFaceFeature`                  | `code === 1` 表示存在符合长度要求的特征；`0` 可能表示未找到或长度不合法。    |
| `faceVerify`                      | `code === 1` 表示比对通过；iOS 缺少有效本地特征时返回 `6`。                  |
| `livenessVerify`                  | `code === 10` 表示所需活体检测全部通过。                                     |
| `code === 0`                      | 可能是取消、失败或特征不存在，不能统一当作“用户取消”。                       |
| Android 原生相机权限拒绝          | 桥接可能返回 `-1`；使用上面的辅助函数时，会在打开原生页面前抛出异常。        |
| 其他结果码                        | 透传原生比对/活体结果，保留 `code`、`message` 排错，不要把所有正数都当成功。 |

SDK 业务失败通常正常 resolve Promise；原生模块未链接或 JavaScript 调用异常可能
导致 reject，需同时检查业务结果和处理 `catch`。

## 相机参数

`FaceVerifyOptions` 和 `LivenessVerifyOptions` 的可选字段如下：

| 字段              | 类型               | `faceVerify` 默认值 | `livenessVerify` 默认值 | 说明                                                         |
| ----------------- | ------------------ | ------------------- | ----------------------- | ------------------------------------------------------------ |
| `threshold`       | `number`           | `0.83`              | 不接收此字段            | 人脸相似度阈值，不是活体分数阈值。                           |
| `livenessType`    | `1 \| 2 \| 3 \| 4` | `1`                 | `2`                     | 活体类型，见下文。                                           |
| `motionTypes`     | `string`           | `'1,2,3,4,5'`       | `'1,2,3,4,5'`           | 逗号分隔的动作 ID。                                          |
| `timeout`         | `number`           | `7`                 | `7`                     | 动作超时，单位秒，使用正整数。                               |
| `steps`           | `number`           | `2`                 | `2`                     | 动作步骤数，使用与动作配置相适应的正整数。                   |
| `allowMultiFaces` | `boolean`          | `true`              | `true`                  | Android 透传至原生 SDK；**iOS 1.8.0 接收但未向 Core 传递**。 |

活体类型：`1` 动作，`2` 动作+炫彩，`3` 炫彩，`4` 仅静默。
iOS 相机实现注明 1–3 也包含静默检测。TypeScript 仅公开 1–4，不要传 `0` 来关闭活体。
动作 ID：`1` 张嘴、`2` 微笑、`3` 眨眼、`4` 摇头、`5` 点头。
动作参数用于包含动作检测的模式；JavaScript 包装层不校验数值范围或动作字符串格式。

Demo 对两个相机检测接口都显式传入 `livenessType: 1`；独立活体接口自身的默认值仍为 `2`。

## isFaceAIModuleAvailable

`isFaceAIModuleAvailable(): boolean`

无参数。返回 `FaceRNModule` 原生桥接是否已链接；不代表已获得相机权限、模型已初始化
或识别一定成功。

```ts
import {isFaceAIModuleAvailable} from '@faceaisdk/react-native-face-sdk';

export function checkSdkLinking() {
  const available = isFaceAIModuleAvailable();
  if (!available)
    console.warn('Install Pods if needed and rebuild the native app');
  return available;
}
```

## addFaceBySDKCamera

`addFaceBySDKCamera(faceID: string, options?: AddFaceBySDKCameraOptions): Promise<FaceResult>`

| 参数                  | 类型                        | 必填 / 默认值 | 说明                                                         |
| --------------------- | --------------------------- | ------------- | ------------------------------------------------------------ |
| `faceID`              | `string`                    | 必填          | 保存特征的本地 ID，成功保存时覆盖同 ID 的已有记录。          |
| `options`             | `AddFaceBySDKCameraOptions` | 可选，`{}`    | 相机录入配置。                                               |
| `options.mode`        | `1 \| 2`                    | `1`           | Android 原生录入模式；iOS 1.8.0 为预留参数，不改变处理流程。 |
| `options.showConfirm` | `boolean`                   | `true`        | 是否在保存采集到的人脸前显示确认操作。                       |

打开 SDK 相机录入页面。`code === 1` 时特征已保存到本地，`faceFeature` 返回特征，
`faceBase64` 可能返回人脸图片；`similarity`、`liveness` 为 `0`。
iOS 取消录入时也可能返回此前保存的特征，不能仅凭 `faceFeature` 非空判断录入成功。

```ts
import {addFaceBySDKCamera} from '@faceaisdk/react-native-face-sdk';
import {withSdkCamera} from './face-sdk-helpers';

export async function enrollFace(faceID: string) {
  const result = await withSdkCamera(() =>
    addFaceBySDKCamera(faceID, {mode: 1, showConfirm: true}),
  );
  if (result.code !== 1) {
    console.warn('Enrollment not saved:', result.code, result.message);
  }
  return result;
}
```

## faceVerify

`faceVerify(faceID: string, options?: FaceVerifyOptions): Promise<FaceResult>`

| 参数      | 类型                | 必填 / 默认值 | 说明                                  |
| --------- | ------------------- | ------------- | ------------------------------------- |
| `faceID`  | `string`            | 必填          | 已录入或写入有效特征的本地 ID。       |
| `options` | `FaceVerifyOptions` | 可选，`{}`    | 字段与默认值见[相机参数](#相机参数)。 |

打开 1:1 人脸比对与活体页面。返回 `code`、`message`、`faceID`、`similarity`、
`liveness`；`faceFeature` 为空，`faceBase64` 可为空。
以 `code === 1` 判定比对通过，不要只根据相似度自行当作验证成功。
查询失败时保留原始 `code`、`message`，不要一律提示“未录入”。

```ts
import {faceVerify, getFaceFeature} from '@faceaisdk/react-native-face-sdk';
import {withSdkCamera} from './face-sdk-helpers';

export async function verifyFace(faceID: string) {
  return withSdkCamera(async () => {
    const stored = await getFaceFeature(faceID);
    if (stored.code !== 1) {
      throw new Error(
        `Feature lookup failed (${stored.code}): ${stored.message}`,
      );
    }
    const result = await faceVerify(faceID, {
      threshold: 0.83,
      livenessType: 1,
      motionTypes: '1,2,3,4,5',
      timeout: 7,
      steps: 2,
      allowMultiFaces: false,
    });
    if (result.code !== 1) {
      console.warn('Verification not passed:', result.code, result.message);
    }
    return result;
  });
}
```

## livenessVerify

`livenessVerify(options?: LivenessVerifyOptions): Promise<FaceResult>`

| 参数      | 类型                    | 必填 / 默认值 | 说明                                                                 |
| --------- | ----------------------- | ------------- | -------------------------------------------------------------------- |
| `options` | `LivenessVerifyOptions` | 可选，`{}`    | [相机参数](#相机参数)中除 `threshold` 外的字段，默认活体类型为 `2`。 |

打开独立活体页面，无需 faceID，也无需提前录入。`code === 10` 表示所需活体检测全部
通过，`liveness` 为活体分数；`faceID`、`faceFeature` 为空，`similarity` 为 `0`，
`faceBase64` 可能返回采集的图片。

```ts
import {livenessVerify} from '@faceaisdk/react-native-face-sdk';
import {withSdkCamera} from './face-sdk-helpers';

export async function checkLiveness() {
  const result = await withSdkCamera(() =>
    livenessVerify({livenessType: 2, timeout: 7, steps: 2}),
  );
  if (result.code !== 10) {
    console.warn('Liveness not passed:', result.code, result.message);
  }
  return result;
}
```

## getFaceFeature

`getFaceFeature(faceID: string): Promise<FaceResult>`

| 参数     | 类型     | 必填 | 说明                |
| -------- | -------- | ---- | ------------------- |
| `faceID` | `string` | 是   | 需要查询的本地 ID。 |

读取本地特征，不打开相机。`code === 1` 且 `faceFeature` 长度为 1024 表示有可用
特征。返回 `0` 可能是不存在或长度异常，结合 `message` 排错。`faceID` 回显请求 ID，
`similarity`、`liveness` 为 `0`，`faceBase64` 为空。

```ts
import {getFaceFeature} from '@faceaisdk/react-native-face-sdk';

export async function readFeature(faceID: string) {
  const result = await getFaceFeature(faceID);
  console.log({
    code: result.code,
    message: result.message,
    length: result.faceFeature.length,
  });
  return result;
}
```

## insertFaceFeature

`insertFaceFeature(faceID: string, faceFeature: string): Promise<FaceResult>`

| 参数          | 类型     | 必填 | 说明                                                      |
| ------------- | -------- | ---- | --------------------------------------------------------- |
| `faceID`      | `string` | 是   | 目标本地 ID，覆盖同 ID 的已有特征。                       |
| `faceFeature` | `string` | 是   | 由兼容 SDK 生成、原样传递的有效特征，长度为 1024 个字符。 |

不打开相机，直接写入特征。`code === 1` 只说明保存成功，不代表本次执行了人脸或活体
验证。`faceID` 回显，特征/图片字段为空，分数字段为 `0`。
Android 要求长度恰好为 1024；iOS 写入只拒绝小于 1024 的数据，但后续查询、比对仍要求
恰好 1024。不要靠截断、补齐或伪造字符串满足长度检查。桥接层不保证跨平台、跨版本特征兼容。

```ts
import {
  getFaceFeature,
  insertFaceFeature,
} from '@faceaisdk/react-native-face-sdk';

// The caller must choose a target ID whose data may be overwritten.
export async function copyFeature(sourceID: string, targetID: string) {
  if (sourceID === targetID) throw new Error('Choose a different target ID');
  const source = await getFaceFeature(sourceID);
  if (source.code !== 1 || source.faceFeature.length !== 1024) {
    throw new Error(
      `No usable SDK feature (${source.code}): ${source.message}`,
    );
  }
  const result = await insertFaceFeature(targetID, source.faceFeature);
  if (result.code !== 1)
    throw new Error(`Insert failed (${result.code}): ${result.message}`);
  return result;
}
```

## addFaceByImage

`addFaceByImage(faceID: string, base64Image: string): Promise<FaceResult>`

| 参数          | 类型     | 必填 | 说明                                                            |
| ------------- | -------- | ---- | --------------------------------------------------------------- |
| `faceID`      | `string` | 是   | 提取特征后保存的本地 ID，成功后覆盖同 ID 的已有记录。           |
| `base64Image` | `string` | 是   | 真实、可解码人脸图片的 Base64，不是 URL、文件路径或特征字符串。 |

从传入图片提取并保存特征，不打开 SDK 相机，不证明活体。跨端传入纯图片 Base64 数据；
iOS 额外支持剥离包含 `base64,` 的 data URI 前缀，不应假设 Android 具有相同兼容处理。
Android 此接口需要可用的当前 Activity，应在 App 前台调用。
`code === 1` 时 `faceFeature` 返回已保存特征，分数字段为 `0`、`faceBase64` 为空。
图片解析或提取失败会以业务失败码 resolve。
公开 JavaScript 接口名是 `addFaceByImage`；`addFaceBySDKImage` 是底层桥接名，
不是可具名导入的 JavaScript 接口。

```ts
import {addFaceByImage} from '@faceaisdk/react-native-face-sdk';

// Pass an actual encoded face image supplied by your application's image input.
export async function enrollFromImage(faceID: string, base64Image: string) {
  if (!base64Image.trim()) throw new Error('An image is required');
  const result = await addFaceByImage(faceID, base64Image);
  if (result.code !== 1) {
    console.warn('Image enrollment failed:', result.code, result.message);
  }
  return result;
}
```

## deleteFaceFeature

`deleteFaceFeature(faceID: string): Promise<FaceResult>`

| 参数     | 类型     | 必填 | 说明                |
| -------- | -------- | ---- | ------------------- |
| `faceID` | `string` | 是   | 需要删除的本地 ID。 |

删除本地特征。当前桥接在 ID 原本不存在时也返回 `code === 1`，不能用该结果判断此前
是否有记录。`faceID` 回显，特征/图片字段为空，分数字段为 `0`。
Android 还会尝试删除该 ID 的录入缓存图；iOS 1.8.0 删除特征及 `<faceID>_base64`
UserDefaults 项，此处不删除 FaceImageManager 保存的图片文件。两端均不承诺清理全部
比对或活体图片。界面需要删除后的状态时，再次查询。

```ts
import {
  deleteFaceFeature,
  getFaceFeature,
} from '@faceaisdk/react-native-face-sdk';

// Invoke only after the user has confirmed which ID should be deleted.
export async function removeFeature(faceID: string) {
  const result = await deleteFaceFeature(faceID);
  if (result.code !== 1)
    throw new Error(`Delete failed (${result.code}): ${result.message}`);
  const afterDelete = await getFaceFeature(faceID);
  return {result, afterDelete};
}
```

## 调用处的错误处理

示例导出的是异步函数，在界面事件中调用时应处理 reject。仅使用 `try/catch`
不足以处理 SDK 业务失败，还需检查结果码：

```ts
import {faceVerify} from '@faceaisdk/react-native-face-sdk';
import {withSdkCamera} from './face-sdk-helpers';

export async function handleVerification(faceID: string) {
  try {
    const result = await withSdkCamera(() => faceVerify(faceID));
    if (result.code !== 1) {
      console.warn('SDK business result:', result.code, result.message);
    }
    return result;
  } catch (error) {
    console.warn(
      'Invocation failed:',
      error instanceof Error ? error.message : String(error),
    );
    return null;
  }
}
```

## 集成核对

- 安装或升级插件后重新构建原生应用，Metro 刷新不能完成原生模块链接。
- 等待原生操作结束后再打开下一个相机页面，不要对取消或拒绝权限自动重试。
- 比对前先录入；独立活体与图片提取特征是不同操作。
- 本 Demo 的导入菜单需先在 [App.tsx](../App.tsx) 配置 `DEMO_FACE_FEATURE` / `DEMO_BASE64_IMAGE`。
- 在目标真机覆盖录入、比对、取消、权限拒绝、删除；示例通过 TypeScript 检查不代表运行了原生算法。

本文在 `main/docs` 独立维护，适用于 SDK 1.8.0；升级插件和原生依赖时同步更新。
