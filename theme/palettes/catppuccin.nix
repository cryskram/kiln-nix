# Catppuccin (catppuccin.com/palette), mauve accent; the flavour is chosen in theme/tokens.nix.
{ flavour }:
let
  flavours = {
    mocha = {
      rosewater = "#f5e0dc";
      pink = "#f5c2e7";
      mauve = "#cba6f7";
      red = "#f38ba8";
      peach = "#fab387";
      yellow = "#f9e2af";
      green = "#a6e3a1";
      teal = "#94e2d5";
      blue = "#89b4fa";
      text = "#cdd6f4";
      subtext1 = "#bac2de";
      subtext0 = "#a6adc8";
      overlay0 = "#6c7086";
      surface2 = "#585b70";
      surface1 = "#45475a";
      surface0 = "#313244";
      base = "#1e1e2e";
      mantle = "#181825";
      crust = "#11111b";
    };
    macchiato = {
      rosewater = "#f4dbd6";
      pink = "#f5bde6";
      mauve = "#c6a0f6";
      red = "#ed8796";
      peach = "#f5a97f";
      yellow = "#eed49f";
      green = "#a6da95";
      teal = "#8bd5ca";
      blue = "#8aadf4";
      text = "#cad3f5";
      subtext1 = "#b8c0e0";
      subtext0 = "#a5adcb";
      overlay0 = "#6e738d";
      surface2 = "#5b6078";
      surface1 = "#494d64";
      surface0 = "#363a4f";
      base = "#24273a";
      mantle = "#1e2030";
      crust = "#181926";
    };
  };

  c = flavours.${flavour};
  title = {
    mocha = "Mocha";
    macchiato = "Macchiato";
  };
in
rec {
  name = "Catppuccin ${title.${flavour}}";
  slug = "catppuccin-${flavour}";

  accents = {
    inherit (c)
      red
      yellow
      green
      blue
      ;
    orange = c.peach;
    aqua = c.teal;
    purple = c.mauve;
  };

  colors = with c; {
    background = base;
    background-deep = mantle;
    background-darkest = crust;
    surface = surface0;
    surface-elevated = surface1;
    surface-hover = surface2;
    surface-active = overlay0;

    foreground = text;
    foreground-muted = subtext1;
    foreground-dim = subtext0;

    accent-primary = mauve;
    accent-secondary = blue;
    accent-container = surface1;

    border = surface1;
    border-subtle = surface0;

    success = green;
    warning = yellow;
    error = red;
    info = blue;

    shadow = crust;
    cursor = rosewater;
    selectionBg = surface2;
    selectionFg = text;

    ansi = [
      surface1
      red
      green
      yellow
      blue
      pink
      teal
      subtext1
      surface2
      red
      green
      yellow
      blue
      pink
      teal
      subtext0
    ];
  };

  apps = {
    gtk = {
      package = "catppuccin-gtk";
      override = {
        variant = flavour;
        accents = [ "mauve" ];
      };
      name = "catppuccin-${flavour}-mauve-standard";
    };
    icons = {
      variant = "purple";
      name = "Tela-circle-purple-dark";
    };
    cursor = {
      package = "catppuccin-cursors.${flavour}Mauve";
      name = "catppuccin-${flavour}-mauve-cursors";
    };
    nvim = {
      repo = "catppuccin/nvim";
      name = "catppuccin";
      colorscheme = "catppuccin-${flavour}";
      setup = ''require("catppuccin").setup({ flavour = "${flavour}" })'';
    };
    pi = "catppuccin-${flavour}";
    wallpapers = "catppuccin";
    loginWallpaper = "space-piano.png";
  };
}
