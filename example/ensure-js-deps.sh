#!/bin/bash

# 确保 example 示例工程的 JS 依赖就绪。
#
# 设计原则（关键，避免 Metro 双实例冲突）：
#   - 示例工程不维护自己的完整 node_modules，统一复用仓库根目录的 node_modules
#     （react / react-native / metro / jest 等都在根目录 devDependencies 中）。
#   - example/node_modules 里只放一个指向仓库根目录的本地 SDK 软链，
#     用于解析 `@faceaisdk/react-native-face-sdk`。
#   - 若 example 下出现了重复安装的 react-native / metro，会主动清理，
#     否则会出现 "Unable to resolve module metro-runtime/..." 等报错。

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"          # example 目录
REPO_DIR="$(cd "$ROOT_DIR/.." && pwd)"             # 仓库根目录
EXAMPLE_NM="$ROOT_DIR/node_modules"
SDK_SCOPE_DIR="$EXAMPLE_NM/@faceaisdk"
SDK_LINK="$SDK_SCOPE_DIR/react-native-face-sdk"
LAYOUT_CHANGED=0

ensure_repo_dependencies() {
  if [ -e "$REPO_DIR/node_modules/react-native/package.json" ] \
     && [ -e "$REPO_DIR/node_modules/metro/package.json" ] \
     && [ -e "$REPO_DIR/node_modules/react/package.json" ]; then
    return 0
  fi

  echo "📦 仓库根目录依赖缺失，正在执行 npm install（含 react-native / metro 等）..."
  npm install --prefix "$REPO_DIR" --no-fund --no-audit
  echo "✅ 仓库根目录依赖已就绪。"
}

remove_conflicting_full_install() {
  # 如果 example/node_modules 里出现了 react-native / metro 等真实依赖目录，
  # 说明之前误执行过完整 npm install，会与根目录形成双实例，必须清理。
  if [ -d "$EXAMPLE_NM/react-native" ] || [ -d "$EXAMPLE_NM/metro" ]; then
    echo "🧹 检测到 example/node_modules 存在重复安装，正在清理以避免 Metro 双实例冲突..."
    rm -rf "$EXAMPLE_NM"
    LAYOUT_CHANGED=1
  fi
}

ensure_sdk_symlink() {
  local current_target=""

  if [ -L "$SDK_LINK" ]; then
    current_target="$(cd -P "$SDK_LINK" 2>/dev/null && pwd -P || true)"
    if [ "$current_target" = "$REPO_DIR" ]; then
      return 0
    fi
  fi

  echo "🔗 正在创建本地 SDK 软链: @faceaisdk/react-native-face-sdk -> 仓库根目录"
  rm -rf "$SDK_LINK"
  mkdir -p "$SDK_SCOPE_DIR"
  ln -s "../../.." "$SDK_LINK"
  LAYOUT_CHANGED=1
}

# 当 example/node_modules 布局发生变化时，清理 Android 侧缓存的 autolinking 结果，
# 否则 Gradle 会沿用旧的依赖目录（例如已删除的 example/node_modules/react-native-safe-area-context），
# 报 "Configuring project ':react-native-safe-area-context' without an existing directory" 之类错误。
clean_stale_android_autolinking() {
  if [ "$LAYOUT_CHANGED" -ne 1 ]; then
    return 0
  fi

  rm -rf "$ROOT_DIR/android/build/generated/autolinking" \
         "$ROOT_DIR/android/app/build/generated/autolinking" 2>/dev/null || true
  echo "🧹 已清理 Android 旧的 autolinking 缓存（布局已变化）。"
}

verify_sdk_resolves() {
  if [ ! -e "$SDK_LINK/package.json" ]; then
    echo "❌ 本地 SDK 软链无法解析到 package.json，请检查仓库结构。"
    exit 1
  fi
}

print_sdk_source() {
  local linked_target=""
  linked_target="$(cd -P "$SDK_LINK" 2>/dev/null && pwd -P || true)"
  echo "🔗 当前 Example 使用本地 SDK 源码目录: ${linked_target:-未知}"
}

ensure_repo_dependencies
remove_conflicting_full_install
ensure_sdk_symlink
clean_stale_android_autolinking
verify_sdk_resolves
print_sdk_source

echo "✅ Example JavaScript 依赖已就绪（复用仓库根目录 node_modules + 本地 SDK 软链）。"


