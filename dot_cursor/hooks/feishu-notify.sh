#!/usr/bin/env bash
# Cursor Hooks：主 Agent 结束 (stop) 或会话结束 (sessionEnd) 时，用 lark-cli 发一条飞书群消息。
# 依赖：jq、lark-cli（本机已 lark-cli auth login）
# 配置：只改下面两行，不使用单独 env 文件。

set -euo pipefail

# ----- 在此填写 -----
LARK_NOTIFY_CHAT_ID="oc_xxx"
LARK_NOTIFY_AS="bot"
# --------------------

export PATH="${PATH}:/opt/homebrew/bin:/usr/local/bin:${HOME}/.local/bin"

payload="$(cat)"
if ! command -v jq >/dev/null 2>&1; then
  echo "[agent-notify] 未找到 jq，请安装: brew install jq" >&2
  # 仅 stop / subagentStop 需要向 stdout 输出 "{}"；无 jq 时用粗匹配避免卡住 Agent
  if echo "${payload}" | grep -E -q '"hook_event_name"[[:space:]]*:[[:space:]]*"(stop|subagentStop)"'; then
    printf '%s\n' '{}'
  fi
  exit 0
fi

hook="$(echo "$payload" | jq -r '.hook_event_name // empty')"
roots="$(echo "$payload" | jq -r '(.workspace_roots // []) | join(", ")')"

send() {
  local body="$1"
  [[ -z "${LARK_NOTIFY_CHAT_ID}" ]] && return 0
  command -v lark-cli >/dev/null 2>&1 || {
    echo "[agent-notify] lark-cli not found in PATH" >&2
    return 0
  }
  lark-cli im +messages-send \
    --chat-id "${LARK_NOTIFY_CHAT_ID}" \
    --as "${LARK_NOTIFY_AS}" \
    --text "${body}" >/dev/null 2>&1 || true
}

body=""
case "${hook}" in
  stop | subagentStop)
    status="$(echo "$payload" | jq -r '.status // empty')"
    loop="$(echo "$payload" | jq -r '.loop_count // empty')"
    body=$(
      printf '%s\n%s\n%s\n%s\n%s\n' \
        "[Cursor] ${hook}" \
        "工作区目录: ${roots:-（无）}" \
        "status: ${status}" \
        "loop_count: ${loop}" \
        "主 Agent 本轮已结束或已停止；如需继续请回到 Cursor。"
    )
    send "${body}"
    printf '%s\n' '{}'
    ;;
  sessionEnd)
    sid="$(echo "$payload" | jq -r '.session_id // .conversation_id // empty')"
    body=$(
      printf '%s\n%s\n%s\n%s\n' \
        "[Cursor] sessionEnd" \
        "工作区目录: ${roots:-（无）}" \
        "session: ${sid}" \
        "会话已结束。"
    )
    send "${body}"
    ;;
  *)
    ;;
esac

exit 0
