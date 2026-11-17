notify() { notify-send "VPN" "$1" 2>/dev/null || true; }

has_nm_connection() { nmcli connection show "$1" >/dev/null 2>&1; }

tunnel_state() {
  if has_nm_connection "$1"; then
    nmcli -t -f NAME connection show --active 2>/dev/null | grep -qx "$1"
  else
    systemctl is-active --quiet "wg-quick-$1" 2>/dev/null
  fi
}

tailscale_state() {
  tailscale status --json 2>/dev/null | jq -r '.BackendState // "Unknown"' 2>/dev/null || echo Unknown
}
