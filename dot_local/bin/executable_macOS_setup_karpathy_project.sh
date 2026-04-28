#!/usr/bin/env bash
set -euo pipefail

SOURCE_URL="https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md"

curl -o AGENTS.md https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md

sed -i.bak 's/CLAUDE.md/AGENTS.md/g' AGENTS.md
rm -f AGENTS.md.bak

if [ ! -f ".gitignore" ]; then
  echo "未找到 .gitignore，正在创建新的 .gitignore 文件"
  touch .gitignore
fi

if ! grep -qxF "AGENTS.md" .gitignore; then
  echo >> .gitignore
  echo "AGENTS.md" >> .gitignore
  echo "已将 AGENTS.md 加入 .gitignore"
else
  echo "AGENTS.md 已存在于 .gitignore 中，无需重复添加"
fi

