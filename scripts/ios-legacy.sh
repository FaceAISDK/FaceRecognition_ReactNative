#!/bin/sh
set -eu

mkdir -p ios/build
log_file=ios/build/ios-legacy.log
: > "$log_file"

# Keep successful output short; show the full log and preserve the exit code on failure.
run_step() {
  printf '%s\n' "$1"
  shift
  if "$@" >> "$log_file" 2>&1; then
    return 0
  else
    status=$?
    printf 'Failed (exit %s). Full log: %s\n' "$status" "$log_file" >&2
    cat "$log_file" >&2
    exit "$status"
  fi
}

run_step 'Building iOS Release...' xcodebuild \
  -workspace ios/FaceAISDK_RN.xcworkspace -scheme FaceAISDK_RN \
  -configuration Release -sdk iphoneos -destination generic/platform=iOS \
  -derivedDataPath ios/build build -quiet
run_step 'Build succeeded. Installing...' ios-deploy \
  --bundle ios/build/Build/Products/Release-iphoneos/FaceAISDK_RN.app
printf 'Installed. Tap the app icon to launch. Full log: %s\n' "$log_file"
