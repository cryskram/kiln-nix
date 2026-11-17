# Usage: vpn-status [wg0|proton|tailscale] — no argument lists every tunnel.
up_down() { if "$@"; then echo up; else echo down; fi; }

case "${1:-}" in
  tailscale) up_down test "$(tailscale_state)" = Running ;;
  "")
    for conn in wg0 proton; do
      echo "$conn: $(up_down tunnel_state "$conn")"
    done
    if command -v tailscale >/dev/null; then
      echo "tailscale: $(up_down test "$(tailscale_state)" = Running)"
    fi
    ;;
  *) up_down tunnel_state "$1" ;;
esac
