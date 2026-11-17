# Spicetify — Spotify Gruvbox Dark (DEV, RICE §4)
# Uses spicetify-nix (follows nixpkgs) for declarative theming.
{ pkgs, spicetify-nix, ... }:
let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{

  programs.spicetify = {
    enable = true;
    # Theme: text + Gruvbox Dark palette
    theme = spicePkgs.themes.text;
    colorScheme = "custom";
    customColorScheme = {
      text = "ebdbb2";
      subtext = "d5c4a1";
      sidebarText = "ebdbb2";
      main = "282828";
      sidebar = "1d2021";
      player = "282828";
      card = "3c3836";
      shadow = "1d2021";
      selectedRow = "504945";
      button = "d65d0e";
      buttonActive = "d65d0e";
      buttonDisabled = "665c54";
      tabActive = "d65d0e";
      notification = "d65d0e";
      notificationError = "fb4934";
      misc = "665c54";
    };
    enabledExtensions = with spicePkgs.extensions; [
      shuffle
      # add more: adblock, hidePodcasts, etc. as needed
    ];
    # Keep Spotify features like local files disabled for simplicity
  };
}
