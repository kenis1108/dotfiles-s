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
