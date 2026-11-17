# Credentials come from gitignored files; upstream prefers xoxp > xoxb > xoxc/xoxd, so only the matching route is exported.
secrets_dir="${SLACK_MCP_SECRETS_DIR:-$HOME/niri-desktop/secrets}"

read_secret() {
  tr -d '\r\n' <"$secrets_dir/$1"
}

if [[ -n "${SLACK_MCP_XOXC_TOKEN:-}" && -n "${SLACK_MCP_XOXD_TOKEN:-}" ]]; then
  :
elif [[ -r "$secrets_dir/slack-xoxc-token" && -r "$secrets_dir/slack-xoxd-token" ]]; then
  SLACK_MCP_XOXC_TOKEN="$(read_secret slack-xoxc-token)"
  SLACK_MCP_XOXD_TOKEN="$(read_secret slack-xoxd-token)"
  export SLACK_MCP_XOXC_TOKEN SLACK_MCP_XOXD_TOKEN
else
  token="${SLACK_MCP_XOXP_TOKEN:-${SLACK_MCP_XOXB_TOKEN:-}}"
  if [[ -z "$token" && -r "$secrets_dir/slack-mcp-token" ]]; then
    token="$(read_secret slack-mcp-token)"
  fi
  if [[ -z "$token" ]]; then
    echo "slack-mcp-server: no Slack credentials in $secrets_dir (see docs/slack.md)" >&2
    exit 78
  fi
  case "$token" in
    xoxb-*) export SLACK_MCP_XOXB_TOKEN="$token" ;;
    *) export SLACK_MCP_XOXP_TOKEN="$token" ;;
  esac
fi

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/slack-mcp"
mkdir -p "$cache_dir"
export SLACK_MCP_USERS_CACHE="$cache_dir/users_cache.json"
export SLACK_MCP_CHANNELS_CACHE="$cache_dir/channels_cache_v2.json"

exec slack-mcp-server "$@"
