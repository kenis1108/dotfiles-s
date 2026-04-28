#!/usr/bin/env bash
set -euo pipefail

UPDATE=false
if [[ "${1:-}" == "--update" ]]; then
  UPDATE=true
fi

SOURCE_URL="https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md"
CURSOR_URL="https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/.cursor/rules/karpathy-guidelines.mdc"
TRAE_URL="https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/.cursor/rules/karpathy-guidelines.mdc"

INSTALL_PATHS=(
  "$HOME/.claude/CLAUDE.md"
  "$HOME/.codex/AGENTS.md"
  "$HOME/.config/opencode/AGENTS.md"
)
CURSOR_INSTALL_PATH="$HOME/.cursor/rules/karpathy-guidelines.mdc"
TRAE_INSTALL_PATH="$HOME/.trae/user_rules/karpathy-guidelines.md"

download_file() {
  local url="$1"
  local target_path="$2"
  local description="${3:-文件}"

  local target_dir=$(dirname "${target_path}")

  if [ -f "${target_path}" ]; then
    if [ "${UPDATE}" == "true" ]; then
      echo "🗑️  删除旧文件: ${target_path}"
      rm -f "${target_path}"
    else
      echo "✅ ${description}已存在，跳过: ${target_path}"
      return
    fi
  fi

  if [ ! -d "${target_dir}" ]; then
    echo "📁 创建目录: ${target_dir}"
    mkdir -p "${target_dir}"
  fi

  echo "⬇️  正在下载${description}到: ${target_path}"
  curl -sSL --fail "${url}" -o "${target_path}"
  echo "✅ 完成: ${target_path}"
}

for target_path in "${INSTALL_PATHS[@]}"; do
  target_file=$(basename "${target_path}")

  download_file "${SOURCE_URL}" "${target_path}" "文件"

  if [ "${target_file}" != "CLAUDE.md" ]; then
    echo "🔄 执行内容替换: CLAUDE.md -> AGENTS.md"
    sed -i.bak 's/CLAUDE.md/AGENTS.md/g' "${target_path}"
    rm -f "${target_path}.bak"
  fi

  echo "----------------------------------------"
done

echo "🎯 开始处理 Cursor 配置..."
download_file "${CURSOR_URL}" "${CURSOR_INSTALL_PATH}" "Cursor规则"

echo "----------------------------------------"
echo "🎯 开始处理 TARE 配置..."
download_file "${TRAE_URL}" "${TRAE_INSTALL_PATH}" "TRAE规则"

echo "----------------------------------------"
echo "🎉 所有文件处理完成！"
echo ""
echo "用法: $0 [--update]"
