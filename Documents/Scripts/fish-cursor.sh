#!/opt/homebrew/bin/fish

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Cursor (fish)
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🐟
# @raycast.description Launch Cursor using fish shell environment

# 确保 fish 是 login shell，加载完整环境
exec fish -l -c "cursor $argv"
