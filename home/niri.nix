{
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (import ../theme/tokens.nix) colors;

in
lib.mkIf (osConfig.desktop.shell == "dms") {
  xdg.configFile."niri/config.kdl".text = ''
    include "${pkgs.niri.src}/resources/default-config.kdl"

    prefer-no-csd
    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    hotkey-overlay {
        skip-at-startup
    }

    output "eDP-1" {
        scale 1.15
    }

    output "HDMI-A-1" {
        mode "2560x1440@59.951"
        scale 1.0
    }

    layout {
        gaps 8
        focus-ring {
            off
        }
        border {
            width 2
            active-color "${colors.accent-primary}"
            inactive-color "${colors.border}"
            urgent-color "${colors.error}"
        }
    }

    // Without draw-border-with-background false, the border fill tints translucent windows.
    window-rule {
        geometry-corner-radius 12
        clip-to-geometry true
        draw-border-with-background false
        opacity 0.95

        background-effect {
            blur true
        }

        popups {
            background-effect {
                blur true
            }
        }
    }

    window-rule {
        match app-id=r#"^com\.mitchellh\.ghostty$"#
        opacity 1.0
    }

    // DMS requests blur itself via ext-background-effect; only fuzzel needs a layer rule.
    layer-rule {
        match namespace=r#"^launcher$"#

        background-effect {
            blur true
        }
    }

    binds {
        "Mod+D" { spawn-sh "dms ipc call spotlight toggle || fuzzel"; }
        "Mod+Slash" { spawn-sh "dms ipc call spotlight toggle || fuzzel"; }
        "Mod+Ctrl+V" { spawn "dms" "ipc" "call" "clipboard" "toggle"; }
        "Mod+Ctrl+C" { spawn "dms" "ipc" "call" "control-center" "toggle"; }
        "Mod+P" { spawn-sh "dms ipc call powermenu toggle || wlogout"; }
        "Mod+Shift+E" { spawn "wlogout"; }
        "Super+Alt+L" { spawn-sh "dms ipc call lock lock || swaylock"; }
        "Mod+Shift+S" { spawn "dms" "screenshot"; }
        "Print" { spawn "dms" "screenshot" "full"; }
        "Mod+Shift+R" { spawn-sh "wf-recorder -g \"$(slurp -o)\" -f ~/Videos/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"; }
        "Mod+T" { spawn "ghostty"; }
        "Mod+Return" { spawn "ghostty"; }
        "Mod+M" { spawn "niri-display-toggle"; }
        "Mod+Shift+M" { spawn "niri-display-toggle"; }
        "Mod+Shift+1" { spawn "niri-display-toggle" "1"; }
        "Mod+Shift+2" { spawn "niri-display-toggle" "2"; }
        "Mod+Shift+N" { spawn "vpn-toggle"; }
    }
  '';
}
