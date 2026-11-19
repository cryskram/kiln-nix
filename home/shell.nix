{
  config,
  lib,
  pkgs,
  ...
}:
let
  tokens = import ../theme/tokens.nix;
  p = tokens.palette;
  p' = tokens.paletteNoHash;
  accent = tokens.colors.accent-primary;
  c = tokens.colors;

  btopTheme = with c; {
    main_bg = background;
    main_fg = foreground;
    title = foreground;
    hi_fg = accent-primary;
    selected_bg = surface;
    selected_fg = accent-primary;
    inactive_fg = foreground-dim;
    graph_text = foreground-muted;
    meter_bg = surface;
    proc_misc = accent-secondary;
    cpu_box = border;
    mem_box = border;
    net_box = border;
    proc_box = border;
    div_line = border;
    temp_start = p.green;
    temp_mid = p.yellow;
    temp_end = p.red;
    cpu_start = p.green;
    cpu_mid = p.yellow;
    cpu_end = p.red;
    free_start = p.aqua;
    free_mid = p.aqua;
    free_end = p.green;
    cached_start = p.blue;
    cached_mid = p.blue;
    cached_end = p.aqua;
    available_start = p.yellow;
    available_mid = p.yellow;
    available_end = p.orange;
    used_start = p.orange;
    used_mid = p.red;
    used_end = p.red;
    download_start = p.blue;
    download_mid = p.aqua;
    download_end = p.green;
    upload_start = p.purple;
    upload_mid = p.orange;
    upload_end = p.red;
    process_start = p.green;
    process_mid = p.yellow;
    process_end = p.red;
  };

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

  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;

  programs.fzf = {
    enable = true;
    colors = with c; {
      fg = foreground-muted;
      "fg+" = foreground;
      "bg+" = surface;
      hl = accent-primary;
      "hl+" = accent-primary;
      info = accent-secondary;
      prompt = accent-primary;
      pointer = p.orange;
      marker = p.yellow;
      spinner = accent-secondary;
      header = foreground-dim;
      border = border;
      gutter = "-1";
    };
  };
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

  xdg.configFile."btop/themes/kiln.theme".text = lib.concatLines (
    lib.mapAttrsToList (k: v: "theme[${k}]=\"${v}\"") btopTheme
  );
  home.activation.btopSeedConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    cfg="${config.xdg.configHome}/btop/btop.conf"
    [ -e "$cfg" ] || printf 'color_theme = "kiln"\ntheme_background = false\n' > "$cfg"
  '';

  home.packages = with pkgs; [
    yq-go
    btop
  ];
}
