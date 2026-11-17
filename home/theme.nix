{ pkgs, ... }:
let
  tokens = import ../theme/tokens.nix;

  # Upstream has shipped dangling symlinks before, which the noBrokenSymlinks hook rejects.
  iconTheme =
    (pkgs.tela-circle-icon-theme.override { colorVariants = [ tokens.icons.variant ]; }).overrideAttrs
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
      package = pkgs.${tokens.gtk.package};
      inherit (tokens.gtk) name;
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
    package = pkgs.${tokens.cursor.package};
    inherit (tokens.cursor) name size;
    x11.enable = true;
    gtk.enable = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "qt5ct";
  };
}
