# Centralized design tokens — Gruvbox Dark (medium contrast)
# Single source of truth per RICE §4. Values from the canonical gruvbox palette;
# warm sepia base with orange as the accent.
rec {
  colors = {
    # Base — gruvbox bg0/bg0_h/bg1/bg2/bg3/bg4
    background = "#282828"; # bg0
    background-deep = "#32302f"; # bg0_s (soft)
    background-darkest = "#1d2021"; # bg0_h (hard)
    surface = "#3c3836"; # bg1
    surface-elevated = "#504945"; # bg2
    surface-hover = "#665c54"; # bg3
    surface-active = "#7c6f64"; # bg4

    # Foreground — gruvbox fg/fg2/fg3
    foreground = "#ebdbb2"; # fg
    foreground-muted = "#d5c4a1"; # fg2
    foreground-dim = "#bdae93"; # fg3

    # Accent — gruvbox orange + blue
    accent-primary = "#d65d0e"; # orange (dark)
    accent-secondary = "#83a598"; # blue (bright)

    # Borders
    border = "#504945"; # bg2
    border-subtle = "#3c3836"; # bg1

    # Semantic
    success = "#b8bb26"; # bright green
    warning = "#fabd2f"; # bright yellow
    error = "#fb4934"; # bright red
    info = "#83a598"; # bright blue

    # Effects
    shadow = "#1d2021"; # bg0_h

    # Cursor + selection — gruvbox terminal port: fg cursor on bg2 selection.
    cursor = "#ebdbb2"; # fg
    selectionBg = "#504945"; # bg2
    selectionFg = "#ebdbb2"; # fg

    # Full 16-slot ANSI terminal palette — canonical gruvbox dark mapping:
    # 0-7 normal, 8 = gray (bg4), 9-15 bright.
    ansi = [
      "#282828" # 0  black    (bg0)
      "#cc241d" # 1  red
      "#98971a" # 2  green
      "#d79921" # 3  yellow
      "#458588" # 4  blue
      "#b16286" # 5  purple
      "#689d6a" # 6  aqua
      "#a89984" # 7  white    (fg4)
      "#928374" # 8  br-black (gray)
      "#fb4934" # 9  br-red
      "#b8bb26" # 10 br-green
      "#fabd2f" # 11 br-yellow
      "#83a598" # 12 br-blue
      "#d3869b" # 13 br-purple
      "#8ec07c" # 14 br-aqua
      "#ebdbb2" # 15 br-white (fg)
    ];
  };

  icons = {
    # Name only — the package (Tela-circle orange, plus the prune of upstream's
    # dangling symlinks) is built in home/theme.nix because it needs pkgs.
    name = "Tela-circle-orange-dark";
  };

  fonts = {
    ui = "Inter";
    mono = "JetBrains Mono";
    size = {
      xs = 9;
      sm = 10;
      md = 11;
      lg = 13;
    };
  };

  hexNoHash = hex: builtins.substring 1 (builtins.stringLength hex - 1) hex;
  colorsNoHash = builtins.mapAttrs (_: v: hexNoHash v) colors;
}
