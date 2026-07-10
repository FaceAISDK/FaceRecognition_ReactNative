# Example App

`example/` 是仓库内的 React Native 示例工程，用于：

- 真机联调 FaceAISDK 能力
- 回归验证 JS API 与原生桥接是否可用
- 演示业务方实际接入方式
  
## 运行方式

首次运行无需手动处理依赖：`npm run start`、`npm run ios`、`npm run android`、`./auto_run.sh` 和 `./pod-install.sh` 都会先执行 `ensure-js-deps.sh`，自动确保仓库根目录依赖就绪、并在 `example/node_modules` 下建立指向仓库根目录的本地 SDK 软链，避免 Metro 出现 `Unable to resolve module`。

在仓库根目录执行：

```sh
npm run start
npm run android
npm run ios
```

或直接在 `example/` 目录执行：

```sh
cd example
node ../node_modules/react-native/cli.js start --config metro.config.js
```

## iOS 依赖安装

```sh
cd example
./pod-install.sh
```

该脚本会自动处理：

- `vendor/bundle` 本地 gem 安装路径
- Ruby 4 环境下 `kconv` 缺失的兼容层
- `bundle exec pod install --project-directory=ios`

## 自动运行脚本

```sh
./auto_run.sh
```

仓库根目录的 `./auto_run.sh` 也会转发到这里。

## 本地库接入方式

示例工程通过 `example/metro.config.js` 将 `@faceaisdk/react-native-face-sdk` 解析到仓库根目录，因此可以直接这样写：

```ts
import {faceVerify} from '@faceaisdk/react-native-face-sdk';
```

本地联调由两部分共同保证：

1. `example/node_modules/@faceaisdk/react-native-face-sdk` 是一个指向**仓库根目录**的软链（由 `example/ensure-js-deps.sh` 自动创建/修复），让 React Native CLI、CocoaPods / Gradle autolinking 和原生构建流程都能识别本地插件。
2. `example/metro.config.js` 通过 `watchFolders` + `nodeModulesPaths` 让 Metro 解析到仓库根目录源码与根目录依赖。

> 示例工程**不维护自己的完整 `node_modules`**，统一复用仓库根目录依赖。这样可避免 `metro`/`react-native` 双实例导致的
> `Unable to resolve module metro-runtime/...` 或 `Unable to resolve module @faceaisdk/react-native-face-sdk` 报错。
> 如果误在 `example/` 下执行了 `npm install`，下次运行 `./auto_run.sh` 或 `npm run start` 时会自动清理并恢复软链。

如果需要验证发布包内容（而不是本地源码），在仓库根目录执行：

```sh
npm run release:verify
```

该命令只会 `npm pack` 并校验压缩包内是否包含发布必需文件，**不会改动 `example/` 的本地联调环境**。

