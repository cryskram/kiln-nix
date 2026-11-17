{ pkgs, ... }:
{
  programs.niri.enable = true;
  security.pam.services.swaylock = { };

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
  ];
}
