{ pkgs, ... }:
let
  tokens = import ../theme/tokens.nix;

  # Upstream has shipped dangling symlinks before, which the noBrokenSymlinks hook rejects.
  iconTheme =
    (pkgs.tela-circle-icon-theme.override { colorVariants = [ "orange" ]; }).overrideAttrs
      (old: {
        postInstall = (old.postInstall or "") + ''
          find "$out/share/icons" -xtype l -delete
        '';
      });
in
{
  gtk = {
    enable = true;
    theme = {
      package = pkgs.gruvbox-dark-gtk;
      name = "gruvbox-dark";
    };
    iconTheme = {
      package = iconTheme;
      inherit (tokens.icons) name;
    };
    font = {
      name = tokens.fonts.ui;
      size = tokens.fonts.size.sm;
    };
  };

  dconf.settings."org/gnome/desktop/interface".icon-theme = tokens.icons.name;

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    inherit (tokens.cursor) name size;
    x11.enable = true;
    gtk.enable = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "qt5ct";
  };
}
