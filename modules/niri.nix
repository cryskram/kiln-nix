{
  config,
  pkgs,
  ...
}:
{
  programs.niri.enable = config.desktop.shell == "dms";

  # swaylock stays installed in every session as the fallback lock, so it always needs PAM.
  security.pam.services.swaylock = { };

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
  ];
}
