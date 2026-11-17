# Usage: vpn-toggle [wg0|proton|proton-gui|tailscale] — no argument opens a chooser.
choose() {
  local options=("wg0 (company)")
  if has_nm_connection proton || systemctl cat wg-quick-proton >/dev/null 2>&1; then
    options+=("proton (Proton VPN)")
  fi
  command -v protonvpn-app >/dev/null && options+=("proton-gui (Proton VPN app)")
  command -v tailscale >/dev/null && options+=("tailscale (mesh VPN)")
  printf '%s\n' "${options[@]}" | fuzzel --dmenu --prompt "VPN: " 2>/dev/null | cut -d' ' -f1
}

toggle_tailscale() {
  case "$(tailscale_state)" in
    Running)
      tailscale down 2>/dev/null || true
      notify "Tailscale disconnected"
      ;;
    Stopped)
      if tailscale up 2>/dev/null; then notify "Tailscale connected"; else notify "Tailscale failed — check: tailscale status"; fi
      ;;
    *) notify "Tailscale not logged in — run: sudo tailscale up" ;;
  esac
}

launch_proton_gui() {
  if pgrep -f protonvpn-app-wrapped >/dev/null; then
    notify "Proton VPN GUI already running"
  else
    protonvpn-app >/dev/null 2>&1 &
    disown
    notify "Proton VPN GUI launched"
  fi
}

toggle_tunnel() {
  local conn="$1" unit="wg-quick-$1"
  if has_nm_connection "$conn"; then
    if tunnel_state "$conn"; then
      nmcli connection down "$conn" || true
      notify "$conn disconnected"
    elif nmcli connection up "$conn"; then
      notify "$conn connected"
    else
      notify "$conn failed — check nmcli"
    fi
  elif tunnel_state "$conn"; then
    sudo systemctl stop "$unit" || true
    notify "$conn disconnected"
  elif sudo systemctl start "$unit" && sleep 0.5 && systemctl is-active --quiet "$unit"; then
    notify "$conn connected"
  else
    notify "$conn failed — check: journalctl -u $unit"
  fi
}

target="${1:-$(choose)}"
case "$target" in
  "") exit 0 ;;
  tailscale) toggle_tailscale ;;
  proton-gui) launch_proton_gui ;;
  proton) toggle_tunnel proton ;;
  *) toggle_tunnel wg0 ;;
esac
