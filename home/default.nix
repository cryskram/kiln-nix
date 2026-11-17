{ inputs, ... }:
{
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
    ./niri.nix
    ./desktop.nix
    ./theme.nix
    ./shell.nix
    ./files.nix
    ./scripts.nix
    ./git.nix
    ./development.nix
    ./applications.nix
    ./spicetify.nix
    ./neovim.nix
    ./zed.nix
  ];

  home.stateVersion = "26.05";

  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";
}
