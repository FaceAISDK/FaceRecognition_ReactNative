#!/bin/bash

set -euo pipefail

EXAMPLE_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$EXAMPLE_DIR/.." && pwd)"
IOS_DIR="$EXAMPLE_DIR/ios"
DERIVED_DATA="$EXAMPLE_DIR/.build/ios"
PLATFORM="${1:-auto}"
BUNDLE_ID="com.facern"

cd "$EXAMPLE_DIR"

usage() {
  echo "用法: ./auto_run.sh [auto|ios|android]"
}

find_ios_device() {
  python3 <<'PY'
import json
import subprocess
import sys

try:
    items = json.loads(subprocess.check_output(
        ["xcrun", "xcdevice", "list"], stderr=subprocess.DEVNULL
    ))
except Exception:
    sys.exit(1)

for item in items:
    if (not item.get("simulator") and item.get("available")
            and item.get("platform") == "com.apple.platform.iphoneos"):
        print(item["name"])
        print(item["identifier"])
        print(item.get("operatingSystemVersion", ""))
        sys.exit(0)

sys.exit(1)
PY
}

find_android_device() {
  command -v adb > /dev/null 2>&1 || return 1
  adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }'
}

ensure_metro() {
  if lsof -iTCP:8081 -sTCP:LISTEN > /dev/null 2>&1; then
    echo "✅ 复用已运行的 Metro"
    return
  fi

  echo "▶️  启动 Metro..."
  nohup node "$REPO_DIR/node_modules/react-native/cli.js" start \
    --config "$EXAMPLE_DIR/metro.config.js" \
    > /tmp/facern-metro.log 2>&1 &

  for _ in {1..10}; do
    lsof -iTCP:8081 -sTCP:LISTEN > /dev/null 2>&1 && return
    sleep 1
  done

  echo "❌ Metro 启动失败，请查看 /tmp/facern-metro.log"
  return 1
}

ensure_pods() {
  local manifest="$IOS_DIR/Pods/Manifest.lock"
  local helper="$REPO_DIR/scripts/faceaisdk_post_install.rb"
  local pods_project="$IOS_DIR/Pods/Pods.xcodeproj/project.pbxproj"

  if [ ! -d "$IOS_DIR/FaceRN.xcworkspace" ] || [ ! -f "$pods_project" ] \
      || ! cmp -s "$IOS_DIR/Podfile.lock" "$manifest" \
      || [ "$IOS_DIR/Podfile" -nt "$pods_project" ] || [ "$helper" -nt "$pods_project" ]; then
    "$EXAMPLE_DIR/pod-install.sh"
  fi
}

install_with_ios_deploy() {
  local udid="$1"
  local app="$2"
  local tool="$REPO_DIR/node_modules/.bin/ios-deploy"
  local log="/tmp/facern-ios-deploy.log"

  if [ ! -x "$tool" ]; then
    tool="$(command -v ios-deploy || true)"
  fi
  if [ -z "$tool" ]; then
    echo "❌ 未找到 ios-deploy，请先运行 npm install。"
    return 1
  fi

  if "$tool" --id "$udid" --bundle "$app" --justlaunch --unbuffered 2>&1 | tee "$log"; then
    return
  fi

  # 部分旧版 iOS 的 LLDB safequit 会返回 1，即使应用已经成功安装并启动。
  grep -q '^success$' "$log"
}

run_ios() {
  local info="$1"
  local name
  local udid
  local ios_version
  local ios_major
  local app="$DERIVED_DATA/Build/Products/Debug-iphoneos/FaceRN.app"

  name="$(printf '%s\n' "$info" | sed -n '1p')"
  udid="$(printf '%s\n' "$info" | sed -n '2p')"
  ios_version="$(printf '%s\n' "$info" | sed -n '3p')"
  ios_major="${ios_version%%.*}"
  export NODE_BINARY
  NODE_BINARY="$(command -v node)"

  echo "🍎 构建并安装到 ${name}（iOS ${ios_version}）"
  ensure_pods
  xcodebuild \
    -workspace "$IOS_DIR/FaceRN.xcworkspace" \
    -scheme FaceRN \
    -configuration Debug \
    -destination "id=$udid" \
    -derivedDataPath "$DERIVED_DATA" \
    -allowProvisioningUpdates \
    build

  if [[ "$ios_major" =~ ^[0-9]+$ ]] && [ "$ios_major" -lt 17 ]; then
    install_with_ios_deploy "$udid" "$app"
    return
  fi

  if xcrun devicectl device install app --device "$udid" "$app" \
      && xcrun devicectl device process launch --device "$udid" "$BUNDLE_ID"; then
    return
  fi

  echo "⚠️  devicectl 安装失败，改用 ios-deploy..."
  install_with_ios_deploy "$udid" "$app"
}

run_android() {
  local device="$1"
  echo "🤖 构建并安装到 Android 设备 $device"
  adb reverse tcp:8081 tcp:8081
  node "$REPO_DIR/node_modules/react-native/cli.js" run-android \
    --deviceId "$device" --no-packager
}

case "$PLATFORM" in
  auto|ios|android) ;;
  -h|--help) usage; exit 0 ;;
  *) usage; exit 2 ;;
esac

bash "$EXAMPLE_DIR/ensure-js-deps.sh"

IOS_DEVICE="$(find_ios_device || true)"
ANDROID_DEVICE="$(find_android_device || true)"

if [ "$PLATFORM" = ios ] && [ -z "$IOS_DEVICE" ]; then
  echo "❌ 未发现可用的 iOS 真机，请连接、解锁并信任此电脑。"
  exit 1
fi
if [ "$PLATFORM" = android ] && [ -z "$ANDROID_DEVICE" ]; then
  echo "❌ 未发现 Android 真机，请检查 adb 和 USB 调试。"
  exit 1
fi
if [ "$PLATFORM" = auto ] && [ -z "$IOS_DEVICE" ] && [ -z "$ANDROID_DEVICE" ]; then
  echo "❌ 未发现可用真机。"
  exit 1
fi

ensure_metro

if [ "$PLATFORM" != android ] && [ -n "$IOS_DEVICE" ]; then
  run_ios "$IOS_DEVICE"
fi
if [ "$PLATFORM" != ios ] && [ -n "$ANDROID_DEVICE" ]; then
  run_android "$ANDROID_DEVICE"
fi

echo "✅ 安装并启动完成"
