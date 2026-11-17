{ lib, ... }:
{
  options.desktop.shell = lib.mkOption {
    type = lib.types.enum [
      "caelestia"
      "dms"
    ];
    default = "caelestia";
    description = "Desktop shell drawn on top of niri: bar, launcher, notifications, lock and wallpaper.";
  };
}
