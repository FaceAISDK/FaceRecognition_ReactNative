#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHIM_DIR="$ROOT_DIR/ruby_shims"
IOS_DIR="$ROOT_DIR/ios"
ENSURE_DEPS_SCRIPT="$ROOT_DIR/ensure-js-deps.sh"

cd "$ROOT_DIR"

bash "$ENSURE_DEPS_SCRIPT"

if ! command -v bundle > /dev/null 2>&1; then
  echo "❌ 未找到 bundle，请先安装 Bundler。"
  exit 1
fi

bundle config set --local path vendor/bundle > /dev/null 2>&1 || true

if ! bundle check > /dev/null 2>&1; then
  echo "📦 安装 Ruby gems (bundle install)..."
  bundle install
fi

export RUBYLIB="$SHIM_DIR${RUBYLIB:+:$RUBYLIB}"
export COCOAPODS_DISABLE_STATS=1


echo "📦 安装 iOS Pods..."
bundle exec pod install --project-directory="$IOS_DIR" "$@"

