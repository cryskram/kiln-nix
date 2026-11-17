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

      formatter.${system} = pkgs.treefmt.withConfig {
        runtimeInputs = with pkgs; [
          nixfmt
          biome
          shfmt
        ];
        settings = {
          on-unmatched = "debug";
          excludes = [
            "flake.lock"
            "patches/*"
            "home/fish/completions/*"
          ];
          formatter = {
            nixfmt = {
              command = "nixfmt";
              includes = [ "*.nix" ];
            };
            biome = {
              command = "biome";
              options = [
                "format"
                "--write"
              ];
              includes = [
                "pi/extensions/*.ts"
                "pi/extensions/**/*.ts"
              ];
            };
            shfmt = {
              command = "shfmt";
              options = [
                "--write"
                "--indent=2"
                "--case-indent"
              ];
              includes = [ "*.sh" ];
            };
          };
        };
      };

      checks.${system}.hyprland-config =
        let
          nixos = self.nixosConfigurations.nixos.config;
          files = pkgs.lib.filterAttrs (
            name: _: pkgs.lib.hasPrefix "hypr/" name
          ) nixos.home-manager.users.${user}.xdg.configFile;
        in
        pkgs.runCommand "hyprland-config-validate"
          { nativeBuildInputs = [ nixos.programs.hyprland.package ]; }
          ''
            export HOME=$TMPDIR/home XDG_RUNTIME_DIR=$TMPDIR
            ${pkgs.lib.concatMapAttrsStringSep "\n" (name: file: ''
              mkdir -p "$HOME/.config/$(dirname ${name})"
              cp -rL --no-preserve=mode ${file.source} "$HOME/.config/${name}"
            '') files}
            cp -n $HOME/.config/hypr/dms-defaults/* $HOME/.config/hypr/dms/
            Hyprland --verify-config -c $HOME/.config/hypr/hyprland.lua > log 2>&1 || { cat log; exit 1; }
            grep -q "config ok" log
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
