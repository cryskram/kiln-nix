rec {
  name = "Gruvbox Dark";
  slug = "gruvbox-dark";

  base = {
    bg0_h = "#1d2021";
    bg0 = "#282828";
    bg0_s = "#32302f";
    bg1 = "#3c3836";
    bg2 = "#504945";
    bg3 = "#665c54";
    bg4 = "#7c6f64";
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
    aqua-faded = "#427b58";
  };

  accents = {
    red = "#fb4934";
    orange = "#fe8019";
    yellow = "#fabd2f";
    green = "#b8bb26";
    aqua = "#8ec07c";
    blue = "#83a598";
    purple = "#d3869b";
  };

  colors = with base; {
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
    accent-secondary = accents.blue;
    accent-container = aqua-faded;

    border = bg2;
    border-subtle = bg1;

    success = accents.green;
    warning = accents.yellow;
    error = accents.red;
    info = accents.blue;

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
    ]
    ++ (with accents; [
      red
      green
      yellow
      blue
      purple
      aqua
    ])
    ++ [ fg1 ];
  };

  apps = {
    gtk = {
      package = "gruvbox-dark-gtk";
      name = "gruvbox-dark";
    };
    icons = {
      variant = "orange";
      name = "Tela-circle-orange-dark";
    };
    cursor = {
      package = "bibata-cursors";
      name = "Bibata-Modern-Amber";
    };
    nvim = {
      repo = "ellisonleao/gruvbox.nvim";
      name = "gruvbox";
      colorscheme = "gruvbox";
      setup = ''require("gruvbox").setup({ contrast = "hard" })'';
    };
    pi = "gruvbox-dark";
    wallpapers = "gruvbox";
    loginWallpaper = "pixel-watermill.png";
  };
}
