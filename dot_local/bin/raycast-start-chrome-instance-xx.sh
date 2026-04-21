#!/usr/bin/env bash
set -euo pipefail

# @raycast.schemaVersion 1
# @raycast.title Start Chrome (Instance XX, debug XXXX)
# @raycast.mode silent
# @raycast.packageName Chrome
# @raycast.description Launch Chrome with remote debugging on port XXXX.

exec "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=XXXX \
  --user-data-dir="~/.chrome/xx"

# 用回默认配置: 使用参数 --profile-directory="Default"
# default path: $HOME/Library/Application Support/Google/Chrome
# default port: 9222
