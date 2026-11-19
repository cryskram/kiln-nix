# Single source of truth for the visual system; switching themes means changing `active` and rebuilding.
let
  active = import ./palettes/catppuccin.nix { flavour = "mocha"; };
in
rec {
  inherit (active) name slug colors;
  inherit (active.apps)
    gtk
    nvim
    pi
    wallpapers
    loginWallpaper
    ;

  palette = active.accents;

  icons = active.apps.icons;

  cursor = active.apps.cursor // {
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
