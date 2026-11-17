# Single source of truth for the visual system: raw Gruvbox Dark palette, then semantic roles.
rec {
  palette = {
    bg0_h = "#1d2021";
    bg0 = "#282828";
    bg0_s = "#32302f";
    bg1 = "#3c3836";
    bg2 = "#504945";
    bg3 = "#665c54";
    bg4 = "#7c6f64";
    fg0 = "#fbf1c7";
    fg1 = "#ebdbb2";
    fg2 = "#d5c4a1";
    fg3 = "#bdae93";
    fg4 = "#a89984";
    gray = "#928374";

    red = "#cc241d";
    green = "#98971a";
    yellow = "#d79921";
    blue = "#458588";
    purple = "#b16286";
    aqua = "#689d6a";
    orange = "#d65d0e";

    red-bright = "#fb4934";
    green-bright = "#b8bb26";
    yellow-bright = "#fabd2f";
    blue-bright = "#83a598";
    purple-bright = "#d3869b";
    aqua-bright = "#8ec07c";
    orange-bright = "#fe8019";

    red-faded = "#9d0006";
    green-faded = "#79740e";
    yellow-faded = "#b57614";
    blue-faded = "#076678";
    purple-faded = "#8f3f71";
    aqua-faded = "#427b58";
    orange-faded = "#af3a03";
  };

  paletteLight = {
    bg0_h = "#f9f5d7";
    bg0 = "#fbf1c7";
    bg0_s = "#f2e5bc";
    bg1 = "#ebdbb2";
    bg2 = "#d5c4a1";
    bg3 = "#bdae93";
    bg4 = "#a89984";
    fg0 = "#282828";
    fg1 = "#3c3836";
    fg2 = "#504945";
    fg3 = "#665c54";
    fg4 = "#7c6f64";
  };

  colors = with palette; {
    background = bg0;
    background-deep = bg0_s;
    background-darkest = bg0_h;
    surface = bg1;
    surface-elevated = bg2;
    surface-hover = bg3;
    surface-active = bg4;

    foreground = fg1;
    foreground-muted = fg2;
    foreground-dim = fg3;

    accent-primary = orange;
    accent-secondary = blue-bright;

    border = bg2;
    border-subtle = bg1;

    success = green-bright;
    warning = yellow-bright;
    error = red-bright;
    info = blue-bright;

    shadow = bg0_h;
    cursor = fg1;
    selectionBg = bg2;
    selectionFg = fg1;

    ansi = [
      bg0
      red
      green
      yellow
      blue
      purple
      aqua
      fg4
      gray
      red-bright
      green-bright
      yellow-bright
      blue-bright
      purple-bright
      aqua-bright
      fg1
    ];
  };

  icons.name = "Tela-circle-orange-dark";

  cursor = {
    name = "Bibata-Modern-Amber";
    size = 24;
  };

  fonts = {
    ui = "Inter";
    display = "Rubik";
    icons = "Material Symbols Rounded";
    mono = "JetBrains Mono";
    size = {
      xs = 9;
      sm = 10;
      md = 11;
      lg = 13;
    };
  };

  hexNoHash = hex: builtins.substring 1 (builtins.stringLength hex - 1) hex;
  colorsNoHash = builtins.mapAttrs (_: hexNoHash) (removeAttrs colors [ "ansi" ]);
  paletteNoHash = builtins.mapAttrs (_: hexNoHash) palette;
}
