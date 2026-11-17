{ pkgs, ... }:
let
  tokens = import ../theme/tokens.nix;
  p = tokens.palette;
  p' = tokens.paletteNoHash;
  accent = tokens.colors.accent-primary;

  bold = color: "bold ${color}";
  segment = color: {
    style = bold color;
    format = "[\\($symbol$version\\)](${bold color}) ";
  };
in
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      g = "git";
      gs = "git status -sb";
      gc = "git commit";
      gp = "git push";
      lg = "lazygit";
      y = "yazi";
      cat = "bat";
      ls = "eza -la --icons --git";
      grep = "rg";
      find = "fd";
      zed = "zeditor";
    };
    # glow wraps at a fixed width; follow the live terminal width unless one is given.
    functions.glow = ''
      if test (count $argv) -eq 0; or contains -- -w $argv; or string match -qr '^--width|^-t$|^--tui$' -- $argv
          command glow $argv
          return
      end
      set -l cols (tput cols 2>/dev/null)
      if test -z "$cols"
          command glow $argv
      else
          command glow -w $cols $argv
      end
    '';
    interactiveShellInit = ''
      set -g fish_greeting ""
      set -g fish_color_command ${tokens.hexNoHash accent}
      set -g fish_color_param ${tokens.colorsNoHash.foreground}
      set -g fish_color_quote ${p'.yellow}
      set -g fish_color_error ${p'.red}
      set -g fish_history_max 10000
    '';
  };

  xdg.configFile."fish/completions/phoenix.fish".source = ./fish/completions/phoenix.fish;

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$directory$git_branch$git_status$git_metrics$nix_shell$direnv$container$golang$nodejs$python$rust$java$line_break$character";
      character = {
        success_symbol = "[>](${bold accent})";
        error_symbol = "[>](${bold p.red})";
        vicmd_symbol = "[>](${bold p.blue})";
      };
      directory = {
        style = bold accent;
        truncation_length = 3;
        truncate_to_repo = true;
      };
      git_branch = {
        style = bold p.blue;
        format = "[\\($branch\\)](${bold p.blue}) ";
      };
      git_status = {
        style = bold p.yellow;
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
        stashed = "\\$";
        ahead = "⇡$count ";
        behind = "⇣$count ";
        diverged = "⇕⇡$ahead_count⇣$behind_count ";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
        untracked = "?";
      };
      git_metrics = {
        disabled = false;
        added_style = bold p.green;
        deleted_style = bold p.red;
        format = "([+$added]($added_style) )([-$deleted]($deleted_style) )";
      };
      nix_shell = {
        symbol = " ";
        style = bold p.aqua;
        format = "[\\($symbol$state\\)](${bold p.aqua}) ";
        impure_msg = "impure";
        pure_msg = "pure";
      };
      direnv = {
        disabled = false;
        symbol = " ";
        style = bold p.purple;
        format = "[\\($symbol$loaded/$allowed\\)](${bold p.purple}) ";
        loaded_msg = "loaded";
        unloaded_msg = "not loaded";
        allowed_msg = "allowed";
        not_allowed_msg = "not allowed";
      };
      container = {
        symbol = " ";
        style = bold p.green;
        format = "[\\($symbol $name\\)](${bold p.green}) ";
      };
      cmd_duration = {
        min_time = 2000;
        format = "[took $duration](${bold p.red}) ";
      };
      golang = segment p.aqua // {
        symbol = " ";
      };
      nodejs = segment p.green // {
        symbol = " ";
      };
      python = segment p.yellow // {
        symbol = " ";
      };
      rust = segment p.red // {
        symbol = " ";
      };
      java = segment p.purple // {
        symbol = " ";
      };
    };
  };

  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.eza.enable = true;
  programs.bat = {
    enable = true;
    config.theme = "base16";
  };
  programs.fd.enable = true;
  programs.ripgrep.enable = true;
  programs.jq.enable = true;
  programs.lazygit.enable = true;

  home.sessionPath = [ "$HOME/.local/bin" ];

  # Width is deliberately unset: the glow function above passes the live terminal width.
  xdg.configFile."glow/glow.yml".text = ''
    style: "auto"
    mouse: false
    pager: false
    all: false
  '';

  home.packages = [ pkgs.yq-go ];
}
