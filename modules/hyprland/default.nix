# Dux Shell's stock Hyprland config is used as shipped; dms/*.lua fragments track the repo default until its Settings UI edits them.
{ pkgs, user, ... }:
let
  tokens = import ../../theme/tokens.nix;
  c = tokens.colorsNoHash;
  stock = "${pkgs.dux-shell.src}/core/internal/config/embedded";

  hyprland = pkgs.runCommand "hyprland.lua" { } ''
    cat ${stock}/hyprland.lua > $out
    printf '\nrequire("user")\n' >> $out
  '';

  binds = pkgs.runCommand "binds.lua" { } ''
    substitute ${stock}/hypr-binds.lua $out --replace-fail '{{TERMINAL_COMMAND}}' ghostty
  '';

  borders = active: inactive: locked: ''
    hl.config({
    	general = {
    		col = {
    			active_border = "rgb(${active})",
    			inactive_border = "rgb(${inactive})",
    		},
    	},
    	group = {
    		col = {
    			border_active = "rgb(${active})",
    			border_inactive = "rgb(${inactive})",
    			border_locked_active = "rgb(${locked})",
    			border_locked_inactive = "rgb(${inactive})",
    		},
    		groupbar = {
    			col = {
    				active = "rgb(${active})",
    				inactive = "rgb(${inactive})",
    				locked_active = "rgb(${locked})",
    				locked_inactive = "rgb(${inactive})",
    			},
    		},
    	},
    })
  '';

  defaults = {
    "colors.lua" = pkgs.writeText "colors.lua" (
      borders c.accent-primary c.surface-elevated c.accent-secondary
    );
    "outputs.lua" = pkgs.writeText "outputs.lua" ''
      hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
      hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@59.95", position = "auto-right", scale = 1 })
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
    '';
    "cursor.lua" = pkgs.writeText "cursor.lua" ''
      hl.env("XCURSOR_THEME", "${tokens.cursor.name}")
      hl.env("XCURSOR_SIZE", "${toString tokens.cursor.size}")
    '';
    "layout.lua" = "${stock}/hypr-layout.lua";
    "input.lua" = "${stock}/hypr-input.lua";
    "windowrules.lua" = "${stock}/hypr-windowrules.lua";
    "binds-user.lua" = "${stock}/hypr-binds-user.lua";
  };
in
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  services.displayManager.defaultSession = "hyprland-uwsm";
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.swaylock = { };

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
  ];

  home-manager.users.${user} =
    { lib, ... }:
    {
      xdg.configFile = {
        "hypr/hyprland.lua".source = hyprland;
        "hypr/user.lua".source = ./user.lua;
        "hypr/dms/binds.lua".source = binds;
        "uwsm/env-hyprland".text = "export HYPRLAND_NO_SD_TARGET=1\n";
      }
      // lib.mapAttrs' (
        name: source: lib.nameValuePair "hypr/dms-defaults/${name}" { inherit source; }
      ) defaults;

      home.activation.hyprlandSeedDms = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        dms="''${XDG_CONFIG_HOME:-$HOME/.config}/hypr/dms"
        mkdir -p "$dms"
        for default in "$dms-defaults"/*; do
          name=$(basename "$default")
          target="$dms/$name" seeded="$dms/.seeded/$name"
          if [ ! -e "$target" ] || { [ -e "$seeded" ] && cmp -s "$target" "$seeded"; }; then
            install -m 644 "$default" "$target"
            install -D -m 644 "$default" "$seeded"
          fi
        done
      '';
    };
}
