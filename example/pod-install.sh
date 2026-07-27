#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHIM_DIR="$ROOT_DIR/ruby_shims"
IOS_DIR="$ROOT_DIR/ios"
ENSURE_DEPS_SCRIPT="$ROOT_DIR/ensure-js-deps.sh"
BUNDLE_CMD=()

cd "$ROOT_DIR"

bash "$ENSURE_DEPS_SCRIPT"

if command -v rbenv > /dev/null 2>&1 \
    && rbenv exec bundle --version > /dev/null 2>&1; then
  BUNDLE_CMD=(rbenv exec bundle)
elif bundle --version > /dev/null 2>&1; then
  BUNDLE_CMD=(bundle)
else
  echo "❌ 未找到 bundle，请先安装 Bundler。"
  exit 1
fi

"${BUNDLE_CMD[@]}" config set --local path vendor/bundle > /dev/null 2>&1 || true

if ! "${BUNDLE_CMD[@]}" check > /dev/null 2>&1; then
  echo "📦 安装 Ruby gems (bundle install)..."
  "${BUNDLE_CMD[@]}" install
fi

export RUBYLIB="$SHIM_DIR${RUBYLIB:+:$RUBYLIB}"
export COCOAPODS_DISABLE_STATS=1


echo "📦 安装 iOS Pods..."
"${BUNDLE_CMD[@]}" exec pod install --project-directory="$IOS_DIR" "$@"
