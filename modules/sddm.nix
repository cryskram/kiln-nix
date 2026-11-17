{ pkgs, ... }:
let
  tokens = import ../theme/tokens.nix;
  inherit (tokens) colors cursor fonts;
  wallpapers = import ../theme/wallpapers.nix { inherit (pkgs) fetchurl; };

  astronaut = pkgs.sddm-astronaut.override {
    themeConfig = {
      Font = fonts.ui;
      Background = "${(builtins.head wallpapers.${tokens.wallpapers}).path}";
      DimBackground = "0.2";
      HeaderTextColor = colors.foreground;
      DateTextColor = colors.foreground;
      TimeTextColor = colors.foreground;
      FormBackgroundColor = colors.background;
      BackgroundColor = colors.background;
      DimBackgroundColor = colors.background-darkest;
      LoginFieldBackgroundColor = colors.surface;
      PasswordFieldBackgroundColor = colors.surface;
      LoginFieldTextColor = colors.foreground;
      PasswordFieldTextColor = colors.foreground;
      UserIconColor = colors.accent-primary;
      PasswordIconColor = colors.accent-primary;
      PlaceholderTextColor = colors.foreground-dim;
      WarningColor = colors.error;
      LoginButtonTextColor = colors.background-darkest;
      LoginButtonBackgroundColor = colors.accent-primary;
      SystemButtonsIconsColor = colors.foreground;
      SessionButtonTextColor = colors.foreground;
      VirtualKeyboardButtonTextColor = colors.foreground;
      DropdownTextColor = colors.foreground;
      DropdownSelectedBackgroundColor = colors.surface-elevated;
      DropdownBackgroundColor = colors.background;
      HighlightTextColor = colors.background-darkest;
      HighlightBackgroundColor = colors.accent-primary;
      HighlightBorderColor = colors.accent-primary;
      HoverUserIconColor = colors.accent-secondary;
      HoverPasswordIconColor = colors.accent-secondary;
      HoverSystemButtonsIconsColor = colors.accent-secondary;
      HoverSessionButtonTextColor = colors.accent-secondary;
      HoverVirtualKeyboardButtonTextColor = colors.accent-secondary;
    };
  };
in
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    settings.Theme = {
      CursorTheme = cursor.name;
      CursorSize = cursor.size;
    };
    extraPackages = with pkgs; [
      pkgs.${cursor.package}
      kdePackages.qtmultimedia
      kdePackages.qtsvg
      kdePackages.qtvirtualkeyboard
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
    ];
  };

  environment.systemPackages = [ astronaut ];
}
