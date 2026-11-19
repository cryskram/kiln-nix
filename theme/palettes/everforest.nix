# Everforest Dark, hard contrast (sainnhe/everforest); hard keeps the panel from reading washed out at 1080p.
rec {
  name = "Everforest Dark";
  slug = "everforest-dark";

  base = {
    bg_dim = "#1e2326";
    bg0 = "#272e33";
    bg1 = "#2e383c";
    bg2 = "#374145";
    bg3 = "#414b50";
    bg4 = "#495156";
    bg5 = "#4f5b58";
    bg_visual = "#4c3743";
    bg_green = "#3c4841";
    fg = "#d3c6aa";
    grey0 = "#7a8478";
    grey1 = "#859289";
    grey2 = "#9da9a0";
  };

  accents = {
    red = "#e67e80";
    orange = "#e69875";
    yellow = "#dbbc7f";
    green = "#a7c080";
    aqua = "#83c092";
    blue = "#7fbbb3";
    purple = "#d699b6";
  };

  colors = with base; {
    background = bg0;
    background-deep = bg1;
    background-darkest = bg_dim;
    surface = bg2;
    surface-elevated = bg3;
    surface-hover = bg4;
    surface-active = bg5;

    foreground = fg;
    foreground-muted = grey2;
    foreground-dim = grey1;

    accent-primary = accents.green;
    accent-secondary = accents.blue;
    accent-container = bg_green;

    border = bg3;
    border-subtle = bg2;

    success = accents.green;
    warning = accents.yellow;
    error = accents.red;
    info = accents.blue;

    shadow = bg_dim;
    cursor = accents.orange;
    selectionBg = bg_visual;
    selectionFg = fg;

    ansi = with accents; [
      bg3
      red
      green
      yellow
      blue
      purple
      aqua
      fg
      grey0
      red
      green
      yellow
      blue
      purple
      aqua
      fg
    ];
  };

  apps = {
    gtk = {
      package = "everforest-gtk-theme";
      name = "Everforest-Green-Dark";
    };
    icons = {
      variant = "green";
      name = "Tela-circle-green-dark";
    };
    cursor = {
      package = "everforest-cursors";
      name = "everforest-cursors";
    };
    nvim = {
      repo = "sainnhe/everforest";
      name = "everforest";
      colorscheme = "everforest";
      setup = ''
        vim.g.everforest_background = "hard"
        vim.g.everforest_better_performance = 1
      '';
    };
    pi = "everforest-dark";
    wallpapers = "everforest";
    loginWallpaper = "fog-forest.png";
  };
}
