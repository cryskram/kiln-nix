# The official Caelestia dots are linked unchanged; personal settings go only through hypr-vars.lua and hypr-user.lua.
{
  config,
  inputs,
  lib,
  pkgs,
  user,
  ...
}:
let
  tokens = import ../../theme/tokens.nix;
  scheme = import ../caelestia/scheme.nix { inherit lib; };
  dots = "${inputs.caelestia-dots}/hypr";
  toLua = value: "return ${lib.generators.toLua { } value}\n";

  vars = {
    terminal = "ghostty";
    browser = "google-chrome-stable";
    editor = "code";
    fileExplorer = "nautilus";
    cursorTheme = tokens.cursor.name;
    cursorSize = tokens.cursor.size;
    sleepGestureCmd = "systemctl suspend";
  };
in
lib.mkIf (config.desktop.shell == "caelestia") {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  services.displayManager.defaultSession = "hyprland-uwsm";

  services.gnome.gnome-keyring.enable = true;
  services.geoclue2.enable = true;

  home-manager.users.${user} = {
    xdg.configFile = {
      "hypr/hyprland.lua".source = "${dots}/hyprland.lua";
      "hypr/variables.lua".source = "${dots}/variables.lua";
      "hypr/hyprland".source = "${dots}/hyprland";
      "hypr/utils".source = "${dots}/utils";
      "hypr/scheme/default.lua".text = toLua (scheme.state "medium" "dark").colours;
      "caelestia/hypr-vars.lua".text = toLua vars;
      "caelestia/hypr-user.lua".source = ./user.lua;
    };

    services.hyprpolkitagent.enable = true;

    home.packages = with pkgs; [
      cliphist
      wl-clipboard
      trash-cli
      hyprpicker
      gammastep
      glib
    ];
  };
}
