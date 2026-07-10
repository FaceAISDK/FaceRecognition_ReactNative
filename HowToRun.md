# How to Run / 如何运行

[English](#english) | [中文](#中文)

---

## English

### 1. Start Metro Bundler
Always start the Metro server first in a separate terminal window. Using `npm start` ensures the correct local version is used.
```bash
npm start -- --reset-cache
```

### 2. Run on Android Device
> ⚠️ **Note**: Must use a physical device. Emulators are not supported.

1. **Connect Device**: Ensure USB debugging is enabled and the device is connected.
2. **Port Reverse**: Map the device port to your computer's Metro port.
   ```bash
   adb reverse tcp:8765 tcp:8765
   ```
3. **Launch App**:
   ```bash
   npm run android
   ```

### 3. Run on iOS Device
> ⚠️ **Note**: Must use a physical device. Mac Catalyst and Simulators are not supported.

1. **Install Dependencies**:
   ```bash
   npm run pods:install
   ```
2. **Xcode Configuration**:
   - Open `example/ios/FaceRN.xcworkspace` in Xcode.
   - Go to **Signing & Capabilities** and select your Development Team.
3. **Launch App**:
   ```bash
   npm run ios
   ```

### 4. Deep Clean (Troubleshooting)
If you encounter build errors, run these commands:
```bash
# Clean Android
cd android && ./gradlew clean && cd ..

# Clean iOS
rm -rf example/ios/build example/.build/ios
rm -rf ~/Library/Developer/Xcode/DerivedData/FaceRN-*

# Restart everything
killall -9 node
npm start -- --reset-cache
```

---

## 中文

### 1. 启动 Metro 服务
请务必在独立的终端窗口中先启动 Metro 服务。使用 `npm start` 可以确保使用项目中安装的正确版本。
```bash
npm start -- --reset-cache
```

### 2. 运行到 Android 真机
> ⚠️ **注意**：必须使用真机，不支持模拟器。

1. **连接设备**：确保已开启 USB 调试并连接电脑。
2. **端口反向代理**：将手机端口映射到电脑的 Metro 端口。
   ```bash
   adb reverse tcp:8765 tcp:8765
   ```
3. **启动项目**：
   ```bash
   npm run android
   ```

### 3. 运行到 iOS 真机
> ⚠️ **注意**：必须使用真机，不支持 Mac Catalyst 或模拟器。

1. **安装依赖**：
   ```bash
   npm run pods:install
   ```
2. **Xcode 配置**：
   - 使用 Xcode 打开 `example/ios/FaceRN.xcworkspace`。
   - 在 **Signing & Capabilities** 选项卡中配置您的开发团队（Team）。
3. **启动项目**：
   ```bash
   npm run ios
   ```

### 4. 深度清理（故障排除）
如果遇到编译报错，请尝试以下清理命令：
```bash
# 清理 Android
cd android && ./gradlew clean && cd ..

# 清理 iOS
rm -rf example/ios/build example/.build/ios
rm -rf ~/Library/Developer/Xcode/DerivedData/FaceRN-*

# 重置所有环境
killall -9 node
npm start -- --reset-cache
```
