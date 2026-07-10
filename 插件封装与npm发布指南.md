# 插件开发与 npm 发布指南

本指南面向插件的开发人员，介绍如何维护、联调测试以及向 npm 组织发布 `@faceaisdk/react-native-face-sdk`。

## 1. 目录结构

```text
FaceAISDK_RN/
├── src/                             # TypeScript 对外 API 源码
├── lib/                             # 编译后的 JS/d.ts 产物 (发布核心)
├── android/                         # 原生 Android SDK Library 源码与资源
├── ios/                             # 原生 iOS SDK 源码与资源
│   ├── FaceAISDK/Localizable.xcstrings # iOS 多语言编辑源
│   └── Resources/*.lproj/Localizable.strings # iOS 运行时多语言资源
├── __tests__/                       # 单元测试
├── example/                         # 联调验证示例 App (不发布)
├── react-native-face-sdk.podspec     # CocoaPods 发布配置
└── package/                          # npm 包解压/打包临时产物，已忽略，禁止提交
```

## 2. 本地开发与联调 (`example/`)

示例工程已经通过 `metro.config.js` 的 `extraNodeModules` 将包名直接解析到仓库根目录，实现免安装直接实时调试源码。

同时，`example/package.json` 中的 `"@faceaisdk/react-native-face-sdk": "file:.."` 会在 `example/node_modules` 下创建指向仓库根目录的本地链接。这是给 React Native CLI、CocoaPods autolinking 和原生构建流程识别本地插件用的。

`example/ios` 和 `example/android` 只保留宿主 App 工程文件；SDK 原生实现统一维护在根目录 `ios/`、`android/` 中，并通过本地包 autolinking 接入 Example。Android 示例工程当前使用 `minSdkVersion 24`、`compileSdkVersion 34`、`targetSdkVersion 34`。

> 注意：安装日志中出现 npm registry 访问，通常只是下载 `react-native`、Babel、Jest 等第三方依赖；并不代表 Example 切到了远程发布版 SDK。`example/ensure-js-deps.sh` 会打印当前实际使用的 SDK 路径。

### 快捷真机运行
在根目录下可直接执行：
```sh
./auto_run.sh
```

首次联调或依赖被清理后，也可以先执行：

```sh
npm run dev:bootstrap
```

### 手动分步运行
1. **启动 Metro 服务**：
   ```sh
   npm run start
   ```
2. **运行 Android**：
   ```sh
   npm run android
   ```
3. **运行 iOS (真机)**：
   ```sh
   npm run pods:install   # 自动处理 Ruby 4 兼容与 Xcode 15 接口校验参数
   npm run ios
   ```

---

## 3. 构建与发布流程

### 1. 代码检查与编译
发布前需要确保 TS 编译无误、单元测试及 Lint 全部通过：
```sh
npm run typecheck    # TS 类型检查
npm run build        # 编译生成 lib 产物
npm test             # 运行单元测试
```

### 2. 本地打包验证
使用 `npm pack` 在本地生成 `.tgz` 压缩包（例如 `react-native-face-ai-sdk-0.1.0.tgz`）。该文件用于检查压缩包内是否包含必须的原生目录、打包产物（`lib/`）和配置：
```sh
npm pack
```
**注意**：生成的 `.tgz` 文件和解压后的 `package/` 目录仅供本地检查，**严禁提交到 Git 仓库**。项目中已通过 `.gitignore` 配置忽略 `*.tgz` 和 `package/`。

推荐使用统一验证命令：

```sh
npm run release:verify
```

该命令会自动执行：

1. TypeScript 类型检查
2. 构建 `lib/` 发布产物
3. 单元测试
4. `npm pack --json`
5. 校验 tarball 内必须包含 `package.json`、`lib/`、`src/`、Android 原生配置、iOS 原生源码、`ios/FaceAISDK/Localizable.xcstrings`、`ios/Resources/*.lproj/Localizable.strings`、podspec 和 post-install 脚本

该命令刻意不把 `.tgz` 安装到 `example/`，避免在 Example 下生成独立依赖树，导致 Metro / React Native 双实例问题。Example 始终保持 `file:..` 本地联调模式。

### 3. 正式发布
确保在官网已创建 `faceaisdk` 组织，且 `package.json` 中的版本号已递增，然后执行发布：
```sh
npm publish --access public
```
*注：由于强制 2FA 安全策略，发布时请根据终端提示或使用 `--otp=xxxxxx` 参数输入手机验证码。*

正式发布前建议先执行：

```sh
npm run publish:dry-run
```

确认发布清单、入口文件、原生目录和 npm 元数据均符合预期后，再执行正式发布。

---

## 4. 开发注意事项

1. **版本规范 (SemVer)**：严格按照 `主版本号.次版本号.修订号` 进行递增（如 Bug 修复递增最后一位，新功能递增第二位）。
2. **依赖隔离**：核心库如 `react` 和 `react-native` 必须放在 `peerDependencies` 中，严禁放入 `dependencies`。
3. **原生代码变更**：修改 `ios/` 或 `android/` 原生桥接层代码后，必须引导使用者重新执行 `pod install` 并重新跑原生全量编译。
4. **Xcode 15+ 编译兼容**：对于 Swift interface 校验错误，请查阅 `example/ios/Podfile` 中对 `TensorFlowLiteSwift` 及 `RCTSwiftUI` 注入 `-no-verify-emitted-module-interface` 的处理钩子。
5. **iOS 多语言资源**：`ios/FaceAISDK/Localizable.xcstrings` 是编辑源；`ios/Resources/en.lproj/Localizable.strings` 和 `ios/Resources/zh-Hans.lproj/Localizable.strings` 是运行时资源。当前 Swift 代码使用 `NSLocalizedString`，因此 CocoaPods 必须打包 `.lproj/Localizable.strings`，否则运行到 iOS 后会只返回 key。
6. **发布资源配置**：新增必须随包发布的原生资源后，需要同步检查 `package.json` 的 `files`、`react-native-face-sdk.podspec` 的 `s.resources`，以及 `scripts/verify-example-package.sh` 的必需文件列表。
