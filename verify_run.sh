#!/bin/bash

# FaceAISDK 插件验证运行脚本
# 用于验证从 npm 安装的 @faceaisdk/react-native-face-sdk 是否能正常工作

set -e

echo "========================================"
echo "   FaceAISDK 插件安装与环境检查"
echo "========================================"

# 1. 检查依赖
if [ ! -d "node_modules/@faceaisdk/react-native-face-sdk" ]; then
    echo "📦 正在安装 SDK..."
    npm install @faceaisdk/react-native-face-sdk --save
fi

# 2. 检查 Autolinking
echo "🔍 检查 Autolinking 状态..."
npx react-native config | grep -A 5 "@faceaisdk/react-native-face-sdk"

# 3. 运行指导
echo ""
echo "✅ 环境准备就绪！"
echo "----------------------------------------"
echo "📱 请选择你要验证的平台并执行相应命令："
echo ""
echo "Android (真机):"
echo "  adb reverse tcp:8765 tcp:8765"
echo "  npx react-native run-android"
echo ""
echo "iOS (真机):"
echo "  cd ios && pod install && cd .."
echo "  npx react-native run-ios --device --port 8765"
echo "----------------------------------------"
echo "💡 提示：如果遇到 500 错误，请尝试执行：npx react-native start --reset-cache"
