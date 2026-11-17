{
  description = "Reproducible NixOS desktop built around Niri";

  nixConfig = {
    extra-substituters = [
      "https://pi.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi.url = "github:lukasl-dev/pi.nix";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      user = "vageesh";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = import ./pi/packages.nix { inherit pkgs; };

      formatter.${system} = pkgs.nixfmt-tree;

      checks.${system}.niri-config =
        let
          niriConfig =
            self.nixosConfigurations.nixos.config.home-manager.users.${user}.xdg.configFile."niri/config.kdl";
        in
        pkgs.runCommand "niri-config-validate" { nativeBuildInputs = [ pkgs.niri ]; } ''
          niri validate --config ${niriConfig.source}
          touch $out
        '';

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs user; };
        modules = [
          ./configuration.nix
          ./modules
          inputs.pi.nixosModules.default
          inputs.home-manager.nixosModules.home-manager
        ];
      };
    };
}
