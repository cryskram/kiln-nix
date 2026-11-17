# Home-level theming — Gruvbox Dark
# Imports centralized tokens; no hard-coded palette elsewhere per RICE §4.
{ pkgs, ... }:
let
  tokens = import ../theme/tokens.nix;
  cn = tokens.colorsNoHash;
in
{
  # GTK — Gruvbox Dark
  gtk = {
    enable = true;
    theme = {
      package = pkgs.gruvbox-dark-gtk;
      name = "gruvbox-dark";
    };
    # Tela-circle, orange colourway (name from theme/tokens.nix).
    # Upstream has shipped dangling symlinks (xsi-addon-symbolic,
    # application-x-addon-symbolic, org.xfce.appfinder) which nixpkgs'
    # noBrokenSymlinks fixup hook rejects; they are pruned before fixup. The
    # orange variant currently has none, so this is insurance, not a workaround.
    iconTheme = {
      package =
        (pkgs.tela-circle-icon-theme.override { colorVariants = [ "orange" ]; }).overrideAttrs
          (old: {
            postInstall = (old.postInstall or "") + ''
              find "$out/share/icons" -xtype l -delete
            '';
          });
      name = tokens.icons.name;
    };
    font = {
      name = tokens.fonts.ui;
      size = tokens.fonts.size.sm;
    };
  };

  # GTK4 / libadwaita apps read the icon theme from dconf (the gtk module only
  # writes gtk-2.0 and gtk-3.0 settings.ini), so the value is set here too.
  dconf.settings."org/gnome/desktop/interface"."icon-theme" = tokens.icons.name;

  # Cursor — Bibata Modern Amber (gruvbox orange) at 24px. nixpkgs carries no
  # gruvbox cursor port, so the accent colour comes from Bibata's amber variant.
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Amber";
    size = 24;
    x11.enable = true;
    gtk.enable = true;
  };

  home.sessionVariables = {
    XCURSOR_SIZE = "24";
    XCURSOR_THEME = "Bibata-Modern-Amber";
  };

  # Qt — use qt5ct on Wayland (gtk2 platform theme requires X DISPLAY and breaks Quickshell on pure Wayland)
  qt = {
    enable = true;
    platformTheme.name = "qt5ct";
  };

  # Terminal — ghostty Gruvbox glass (more blur)
  # The full palette is declared here from the central tokens (RICE §4) rather
  # than left to a bundled theme file, so terminal colours track the repo's
  # single source of truth.
  programs.ghostty.settings = {
    font-family = tokens.fonts.mono;
    font-size = 11;
    # Sink the terminal below the rest of the desktop: bg0_h instead of bg0.
    background = tokens.colors.background-darkest;
    foreground = tokens.colors.foreground;
    cursor-color = tokens.colors.cursor;
    cursor-text = tokens.colors.background-darkest;
    selection-background = tokens.colors.selectionBg;
    selection-foreground = tokens.colors.selectionFg;
    palette = builtins.genList (i: "${toString i}=${builtins.elemAt tokens.colors.ansi i}") 16;
    background-opacity = 0.82;
    # Canonical ghostty name for the blur intensity. Ghostty itself can only
    # apply this on macOS and KDE Plasma, so under niri it is inert: the blur
    # comes from niri's window-rule (home/niri.nix).
    background-blur = 32;
    # Focus is already communicated by niri's 2px orange active border, so do not
    # also fade unfocused splits. Ghostty defaults unfocused-split-opacity to
    # 0.7, which paints a background-coloured rectangle over every split that
    # does not have focus (1 disables the effect entirely).
    unfocused-split-opacity = 1;
    window-decoration = false;
    window-padding-x = 12;
    window-padding-y = 12;
    copy-on-select = "clipboard";
  };

  # Launcher — fuzzel glass (transparent + blur via layer)
  programs.fuzzel.settings = {
    main = {
      font = "${tokens.fonts.ui}:size=10";
      line-height = 18;
      horizontal-pad = 12;
      vertical-pad = 8;
      inner-pad = 8;
      layer = "overlay";
    };
    colors = {
      background = "${cn.background}d9"; # d9 ~85% (glass)
      text = "${cn.foreground}ff";
      match = "${cn.accent-primary}ff";
      selection = "${cn.surface-elevated}cc"; # cc ~80%
      selection-text = "${cn.foreground}ff";
      border = "${cn.border}99"; # 60%
    };
    border = {
      width = 1;
      radius = 12;
    };
  };
}
