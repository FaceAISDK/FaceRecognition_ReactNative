#!/bin/bash

# npm run 会把 node_modules/.bin 放到 PATH 最前面。如果依赖目录里意外存在
# npm 包，裸 `npm` 会命中该局部版本，而不是当前 Node.js 配套的 npm。
set -euo pipefail

CLEAN_PATH=""
IFS=: read -r -a PATH_ENTRIES <<< "$PATH"
for entry in "${PATH_ENTRIES[@]}"; do
  case "$entry" in
    */node_modules/.bin) continue ;;
  esac
  CLEAN_PATH="${CLEAN_PATH:+$CLEAN_PATH:}$entry"
done

NPM_BIN="$(PATH="$CLEAN_PATH" command -v npm || true)"
if [ -z "$NPM_BIN" ]; then
  echo "❌ 未找到 Node.js 配套的 npm。"
  exit 1
fi

exec "$NPM_BIN" "$@"
