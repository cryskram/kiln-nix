{ pkgs, ... }:
let
  tokens = import ../theme/tokens.nix;
  inherit (tokens) colors fonts;
  cn = tokens.colorsNoHash;

  lock = "${pkgs.dux-shell}/bin/dms ipc call lock lock || ${pkgs.swaylock}/bin/swaylock -f";
  dpms = state: "${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = \"${state}\" })'";
in
{
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = fonts.mono;
      font-size = fonts.size.md;
      background = colors.background-darkest;
      foreground = colors.foreground;
      cursor-color = colors.cursor;
      cursor-text = colors.background-darkest;
      selection-background = colors.selectionBg;
      selection-foreground = colors.selectionFg;
      palette = builtins.genList (i: "${toString i}=${builtins.elemAt colors.ansi i}") 16;
      # Ghostty cannot request blur itself; Hyprland's decoration blur shows through this opacity.
      background-opacity = 0.82;
      background-blur = 32;
      unfocused-split-opacity = 1;
      window-decoration = false;
      window-padding-x = 12;
      window-padding-y = 12;
      copy-on-select = "clipboard";
    };
  };

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "${fonts.ui}:size=${toString fonts.size.sm}";
        line-height = 18;
        horizontal-pad = 12;
        vertical-pad = 8;
        inner-pad = 8;
        layer = "overlay";
      };
      colors = {
        background = "${cn.background}d9";
        text = "${cn.foreground}ff";
        match = "${cn.accent-primary}ff";
        selection = "${cn.surface-elevated}cc";
        selection-text = "${cn.foreground}ff";
        border = "${cn.border}99";
      };
      border = {
        width = 1;
        radius = 12;
      };
    };
  };

  programs.swaylock = {
    enable = true;
    settings = {
      color = cn.background;
      inside-color = cn.surface;
      ring-color = cn.border;
      inside-clear-color = cn.surface;
      ring-clear-color = cn.info;
      inside-ver-color = cn.surface;
      ring-ver-color = cn.warning;
      inside-wrong-color = cn.surface;
      ring-wrong-color = cn.error;
      key-hl-color = cn.accent-primary;
      bs-hl-color = cn.error;
      text-color = cn.foreground;
      layout-bg-color = cn.background-deep;
      separator-color = "00000000";
    };
  };

  services.swayidle = {
    enable = true;
    events.before-sleep = "sh -c '${lock}'";
    timeouts = [
      {
        timeout = 300;
        command = "sh -c '${lock}'";
      }
      {
        timeout = 305;
        command = dpms "off";
        resumeCommand = dpms "on";
      }
    ];
  };

  home.packages = with pkgs; [
    networkmanagerapplet
    wl-clipboard
    grim
    slurp
    satty
    wf-recorder
    wlogout
    wl-mirror
  ];
}
