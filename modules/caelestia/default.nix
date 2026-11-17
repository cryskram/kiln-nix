# Caelestia rewrites its state (scheme, wallpaper) from its own UI, so the repo seeds those once and owns only config.
{
  config,
  inputs,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  tokens = import ../../theme/tokens.nix;
  scheme = import ./scheme.nix { inherit lib; };
  wallpapers = pkgs.callPackage ./wallpapers.nix { };
  home = config.users.users.${user}.home;
  wallpaperDir = "${home}/Pictures/Wallpapers";
  defaultWallpaper = "${wallpaperDir}/gruvbox/pixel-watermill.png";

  cli = inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + "\n"
      + ''
        schemes=$(find "$out" -type d -path '*/caelestia/data/schemes/gruvbox' | head -n1)
        [ -n "$schemes" ] || { echo "caelestia-cli: gruvbox scheme directory not found" >&2; exit 1; }
        rm -rf "$schemes"
        ${lib.concatStrings (
          lib.mapAttrsToList (file: text: ''
            install -Dm644 ${pkgs.writeText "gruvbox-${builtins.replaceStrings [ "/" ] [ "-" ] file}" text} "$schemes/${file}"
          '') scheme.files
        )}
      '';
  });

  fontsConf = pkgs.makeFontsConf {
    fontDirectories = with pkgs; [
      material-symbols
      rubik
      inter
      nerd-fonts.caskaydia-cove
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ];
  };

  shell =
    (inputs.caelestia-shell.packages.${system}.caelestia-shell.override {
      withCli = true;
      caelestia-cli = cli;
    }).overrideAttrs
      (old: {
        # The wrapper pins fontconfig to the shell's own fonts; point it at a set that includes the UI fonts.
        postInstall =
          assert lib.hasInfix "--set FONTCONFIG_FILE \"" old.postInstall;
          builtins.replaceStrings
            [ "--set FONTCONFIG_FILE \"" ]
            [
              "--set FONTCONFIG_FILE \"${fontsConf}\" --set CAELESTIA_BUNDLED_FONTCONFIG \""
            ]
            old.postInstall;
      });

in
lib.mkIf (config.desktop.shell == "caelestia") {
  programs.gpu-screen-recorder.enable = true;
  hardware.i2c.enable = true;
  users.users.${user}.extraGroups = [ "i2c" ];

  home-manager.users.${user} =
    { lib, ... }:
    {
      imports = [ inputs.caelestia-shell.homeManagerModules.default ];

      programs.caelestia = {
        enable = true;
        package = shell;
        systemd.enable = false;

        settings = {
          general = {
            apps = {
              terminal = [ "ghostty" ];
              audio = [ "pwvucontrol" ];
              playback = [ "xdg-open" ];
              explorer = [ "nautilus" ];
            };
            idle = {
              lockBeforeSleep = true;
              inhibitWhenAudio = true;
              timeouts = [
                {
                  timeout = 300;
                  idleAction = "lock";
                }
                {
                  timeout = 330;
                  idleAction = "dpms off";
                  returnAction = "dpms on";
                }
              ];
            };
          };

          appearance = {
            anim.durations.scale = 0.85;
            font = {
              headline.family = tokens.fonts.display;
              title.family = tokens.fonts.ui;
              body.family = tokens.fonts.ui;
              label.family = tokens.fonts.ui;
              mono.family = "JetBrainsMono Nerd Font";
              clock = tokens.fonts.display;
              workspaces = tokens.fonts.display;
            };
          };

          bar = {
            clock.showDate = true;
            tray.recolour = true;
            workspaces = {
              shown = 5;
              occupiedBg = true;
              showWindows = true;
            };
          };

          launcher = {
            maxShown = 8;
            favouriteApps = [
              "com.mitchellh.ghostty"
              "google-chrome"
              "org.gnome.Nautilus"
              "code"
              "dev.zed.Zed"
              "obsidian"
              "slack"
              "spotify"
            ];
            hiddenApps = [
              "nautilus-autorun-software"
              "code-url-handler"
              "com.google.Chrome"
            ];
          };

          services = {
            clockFormat = "TwentyFourHour";
            sensorUnits = "Celsius";
            weatherUnits = "Celsius";
            smartScheme = false;
          };

          paths.wallpaperDir = wallpaperDir;
        };

        cli = {
          enable = true;
          package = cli;
          settings.theme = lib.genAttrs [
            "enableTerm"
            "enableHypr"
            "enableDiscord"
            "enableSpicetify"
            "enablePandora"
            "enableFuzzel"
            "enableBtop"
            "enableNvtop"
            "enableHtop"
            "enableGtk"
            "enableQt"
            "enableWarp"
            "enableChromium"
            "enableZed"
            "enableCava"
          ] (applier: applier == "enableHypr");
        };
      };

      home.packages = with pkgs; [
        pwvucontrol
        swappy
        material-symbols
        rubik
        nerd-fonts.caskaydia-cove
      ];

      home.file = lib.listToAttrs (
        map (w: lib.nameValuePair "Pictures/Wallpapers/gruvbox/${w.name}" { source = w.path; }) wallpapers
      );

      home.activation.caelestiaSeedState = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        state="''${XDG_STATE_HOME:-$HOME/.local/state}/caelestia"
        mkdir -p "$state/wallpaper"
        [ -f "$state/scheme.json" ] || printf '%s\n' ${lib.escapeShellArg (builtins.toJSON (scheme.state "medium" "dark"))} > "$state/scheme.json"
        [ -f "$state/wallpaper/path.txt" ] || printf '%s' ${lib.escapeShellArg defaultWallpaper} > "$state/wallpaper/path.txt"
      '';
    };
}
