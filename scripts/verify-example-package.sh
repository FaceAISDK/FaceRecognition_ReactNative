#!/bin/bash

# 发布前校验：打出 npm 压缩包，并检查其中是否包含发布所必需的产物。
#
# 注意：此脚本刻意「不」往 example/ 安装依赖。
# 因为 example 采用「复用仓库根目录 node_modules + 本地 SDK 软链」的模式，
# 一旦在 example 下执行完整 npm install，就会与根目录形成 metro/react 双实例，
# 触发 "Unable to resolve module metro-runtime/..." 等问题。
# 所以这里只校验 tarball 内容，绝不污染本地联调环境。

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PACK_DIR="$ROOT_DIR/.build/npm-pack"

cd "$ROOT_DIR"

echo "📦 生成 npm 压缩包..."
rm -rf "$PACK_DIR"
mkdir -p "$PACK_DIR"
PACK_JSON="$(npm pack --json --pack-destination "$PACK_DIR")"
TGZ_FILE="$(printf '%s' "$PACK_JSON" | node -e 'const fs = require("fs"); const data = JSON.parse(fs.readFileSync(0, "utf8")); process.stdout.write(data[0].filename);')"
TGZ_PATH="$PACK_DIR/$TGZ_FILE"
echo "✅ 已生成: $TGZ_PATH"

echo "🔍 校验压缩包内容是否包含发布必需文件..."
FILE_LIST="$(tar -tzf "$TGZ_PATH")"

REQUIRED=(
  "package/package.json"
  "package/lib/index.js"
  "package/lib/index.d.ts"
  "package/react-native-face-sdk.podspec"
  "package/android/build.gradle"
  "package/src/index.ts"
  "package/ios/FaceAISDK/Localizable.xcstrings"
  "package/ios/Resources/en.lproj/Localizable.strings"
  "package/ios/Resources/zh-Hans.lproj/Localizable.strings"
  "package/scripts/faceaisdk_post_install.rb"
)

MISSING=0
for entry in "${REQUIRED[@]}"; do
  if printf '%s\n' "$FILE_LIST" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -qx "$entry"; then
    echo "  ✓ $entry"
  else
    echo "  ✗ 缺失: $entry"
    MISSING=1
  fi
done

# iOS 原生源码（至少包含一个桥接文件）
if printf '%s\n' "$FILE_LIST" | grep -q "^package/ios/.*\.\(m\|mm\|swift\|h\)$"; then
  echo "  ✓ package/ios/* 原生源码"
else
  echo "  ✗ 缺失: package/ios/* 原生源码"
  MISSING=1
fi

if [ "$MISSING" -ne 0 ]; then
  echo "❌ 发布包校验失败：缺少必需文件，请检查 package.json 的 files 配置与构建产物。"
  exit 1
fi

echo "✅ 发布包校验通过：tarball 内容完整，可用于 npm publish。"
