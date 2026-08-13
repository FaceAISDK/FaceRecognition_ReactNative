# React Native Face SDK 发布指南

本文档总结了发布 `@faceaisdk/react-native-face-sdk` 插件新版本的标准流程。

## 1. 发布前准备 (SDK 同步)

由于本插件是对原生人脸识别 SDK 的封装，发布前需确认原生依赖版本是否为最新：

- **Android**: 检查 [android/build.gradle](file:///Users/anylife/StudioProjects/FaceRecognition_ReactNative/android/build.gradle) 中的 `implementation 'io.github.faceaisdk:Android:YYYY.MM.DD'`。
- **iOS**: 检查 [react-native-face-sdk.podspec](file:///Users/anylife/StudioProjects/FaceRecognition_ReactNative/react-native-face-sdk.podspec) 中的 `s.dependency 'FaceAISDK_Core', 'YYYY.MM.DD'`。

## 2. 更新插件版本号

修改根目录下的 [package.json](file:///Users/anylife/StudioProjects/FaceRecognition_ReactNative/package.json)：

```json
{
  "name": "@faceaisdk/react-native-face-sdk",
  "version": "1.7.0",  // 更新此处版本号
  ...
}
```

> [!TIP]
> iOS 的 podspec 会自动读取此版本号，无需手动修改 podspec 文件。

## 3. 本地构建与自动化校验

在发布之前，必须运行项目自带的校验脚本，确保编译无误且压缩包内容完整。

```bash
npm run release:verify
```

此脚本会自动执行以下任务：
- `typecheck`: TypeScript 语法检查。
- `build`: 编译 TS 到 `lib` 目录。
- `test`: 运行 Jest 单元测试。
- `verify-example-package`: 模拟 npm pack 并校验 tarball 内容。

## 4. 预览发布 (Dry Run)

进一步确认发布包的体积和文件列表：

```bash
npm run publish:dry-run
```

## 5. 提交 Git 变更并打标签

```bash
git add .
git commit -m "chore: release v1.7.0"
git push origin main

# 必须打 tag，因为 iOS podspec 依赖 tag 进行源码定位
git tag v1.7.0
git push origin v1.7.0
```

## 6. 正式发布到 npm

确保你已登录 npm (`npm whoami`)：

```bash
npm publish --access public
```

---

## 常见问题处理

> [!CAUTION]
> **npm ERR! eisdir EISDIR**
> 如果运行 `release:verify` 报错，通常是 `node_modules` 中混入了旧版 npm。
> **解决方法**: 运行 `rm -rf node_modules/npm node_modules/.bin/npm node_modules/latest` 后重装依赖。
