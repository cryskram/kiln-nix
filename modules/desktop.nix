{ lib, ... }:
{
  options.desktop.shell = lib.mkOption {
    type = lib.types.enum [
      "caelestia"
      "dms"
    ];
    default = "caelestia";
    description = "Desktop session: caelestia runs on Hyprland, dms runs on niri.";
  };
}
