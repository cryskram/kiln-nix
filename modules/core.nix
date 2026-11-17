{
  inputs,
  pkgs,
  user,
  ...
}:
let
  tokens = import ../theme/tokens.nix;
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs user; };
    users.${user}.imports = [ ../home ];
  };

  environment.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    XCURSOR_THEME = tokens.cursor.name;
    XCURSOR_SIZE = toString tokens.cursor.size;
  };

  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # input group grants libinput/evtest access to every keyboard device; that is the intent.
  users.users.${user}.extraGroups = [ "input" ];

  environment.systemPackages = with pkgs; [
    nil
    nixd
    nixfmt
    awscli2
    google-cloud-sdk
    jq
    jdk17
    glow
    libinput
    evtest
    wev
  ];
}
