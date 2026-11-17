{ inputs, pkgs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  c = (import ../theme/tokens.nix).colorsNoHash;
in
{
  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.text;
    colorScheme = "custom";
    customColorScheme = {
      text = c.foreground;
      subtext = c.foreground-muted;
      sidebarText = c.foreground;
      main = c.background;
      sidebar = c.background-darkest;
      player = c.background;
      card = c.surface;
      shadow = c.shadow;
      selectedRow = c.surface-elevated;
      button = c.accent-primary;
      buttonActive = c.accent-primary;
      buttonDisabled = c.surface-hover;
      tabActive = c.accent-primary;
      notification = c.accent-primary;
      notificationError = c.error;
      misc = c.surface-hover;
    };
    enabledExtensions = [ spicePkgs.extensions.shuffle ];
  };
}
