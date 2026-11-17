{ pkgs, ... }:
let
  inherit (import ../theme/tokens.nix) cursor;
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
      bibata-cursors
      kdePackages.qtmultimedia
      kdePackages.qtsvg
      kdePackages.qtvirtualkeyboard
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
    ];
  };

  environment.systemPackages = [ pkgs.sddm-astronaut ];
}
