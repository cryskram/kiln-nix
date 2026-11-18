{
  config,
  inputs,
  user,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      accept-flake-config = true;
      auto-optimise-store = true;
      trusted-users = [
        "root"
        user
      ];
      extra-substituters = [
        "https://pi.cachix.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  programs.nh = {
    enable = true;
    flake = "${config.users.users.${user}.home}/kiln-nix";
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 7d --keep 5";
    };
  };

  nixpkgs.overlays = [
    (
      final: prev:
      let
        # `import` rather than legacyPackages so unstable inherits allowUnfree (claude-code is unfree).
        unstable = import inputs.nixpkgs-unstable {
          inherit (prev.stdenv.hostPlatform) system;
          inherit (prev) config;
        };
      in
      {
        inherit (unstable)
          pi-coding-agent
          herdr
          claude-code
          dux-shell
          quickshell
          hyprland
          hyprshell
          xdg-desktop-portal-hyprland
          ;

        opencode = final.callPackage ../pkgs/opencode2.nix { };

        # VSCode moved its bundled ripgrep; drop this once nixpkgs handles both layouts.
        vscode = prev.vscode.overrideAttrs (old: {
          prePatch = (old.prePatch or "") + ''
            mkdir -p resources/app/node_modules/@vscode/ripgrep/bin
            touch resources/app/node_modules/@vscode/ripgrep/bin/rg
          '';
          postPatch = (old.postPatch or "") + ''
            newRg=resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal/bin/linux-x64/rg
            if [ -e "$newRg" ] && [ ! -L "$newRg" ]; then
              rm "$newRg"
              ln -s ${final.ripgrep}/bin/rg "$newRg"
            fi
          '';
        });
      }
    )
  ];
}
