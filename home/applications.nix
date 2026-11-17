{ lib, pkgs, ... }:
let
  inherit (import ../theme/tokens.nix) colors palette fonts;

  rgb =
    hex:
    lib.concatMapStringsSep " "
      (
        offset:
        let
          milli = (lib.fromHexString (builtins.substring offset 2 hex) * 1000 + 127) / 255;
        in
        if milli >= 1000 then "1.000" else "0.${lib.fixedWidthNumber 3 milli}"
      )
      [
        1
        3
        5
      ];

  highlights = with palette; [
    orange
    blue-bright
    yellow-bright
    purple-bright
    aqua-bright
    green-bright
    red-bright
  ];
  letters = lib.stringToCharacters "abcdefghijklmnopqrstuvwxyz";

  sioyekPrefs = {
    background_color = rgb colors.background;
    dark_mode_background_color = rgb colors.background;
    dark_mode_contrast = "0.88";
    custom_background_color = rgb colors.background;
    custom_text_color = rgb colors.foreground;
    text_highlight_color = rgb colors.accent-primary;
    search_highlight_color = rgb colors.warning;
    link_highlight_color = rgb colors.info;
    synctex_highlight_color = rgb palette.purple-bright;
    visual_mark_color = "${rgb colors.accent-primary} 0.22 0.22";
    status_bar_color = rgb colors.background-darkest;
    status_bar_text_color = rgb colors.foreground;
    status_bar_font_size = "13";
    ui_font = fonts.ui;
    font_size = "14";
    page_separator_color = rgb colors.border;
    page_separator_width = "1";
    ruler_mode = "1";
    ruler_padding = "1.0";
    ruler_x_padding = "5.0";
    startup_commands = "toggle_dark_mode";
    zoom_inc_factor = "1.15";
    vertical_move_amount = "1.0";
    horizontal_move_amount = "1.0";
    move_screen_ratio = "0.55";
    fit_to_page_width_ratio = "0.92";
    create_table_of_contents_if_not_exists = "1";
    sort_bookmarks_by_location = "1";
    collapsed_toc = "0";
    flat_toc = "0";
    should_warn_about_user_key_override = "1";
  }
  // lib.listToAttrs (
    lib.imap0 (i: letter: {
      name = "highlight_color_${letter}";
      value = rgb (builtins.elemAt highlights (lib.mod i (builtins.length highlights)));
    }) letters
  );

  sioyekKeys = [
    "toggle_dark_mode <C-d>"
    "toggle_custom_color <C-S-d>"
    "toggle_highlight <C-h>"
    "fit_to_page_width w"
    "fit_to_page_width_smart W"
    "zoom_in ="
    "zoom_in +"
    "zoom_out -"
    "close_window q"
    "toggle_fullscreen <F11>"
    "goto_toc T"
    "search <C-k>"
  ];
in
{
  home.packages = with pkgs; [
    google-chrome
    obsidian
    slack
    discord
    figma-linux
    bruno
    postman
    jetbrains.goland
    jetbrains.idea
    jetbrains.datagrip
    vscode
    beekeeper-studio
    libreoffice
    hunspell
    hunspellDicts.en_US
    hunspellDicts.en_GB-large
    sioyek
    zathura
  ];

  xdg.mimeApps = {
    associations.added = {
      "x-scheme-handler/figma" = "figma-linux.desktop";
      "application/pdf" = [
        "sioyek.desktop"
        "org.pwmt.zathura-pdf-mupdf.desktop"
        "org.gnome.Evince.desktop"
      ];
    };
    defaultApplications = {
      "x-scheme-handler/figma" = "figma-linux.desktop";
      "x-scheme-handler/vscode" = "code-url-handler.desktop";
      "application/pdf" = "sioyek.desktop";
    };
  };

  # Upstream's desktop entry lacks the figma:// MimeType, which breaks the browser sign-in handoff.
  xdg.dataFile."applications/figma-linux.desktop".text = lib.generators.toINI { } {
    "Desktop Entry" = {
      Name = "Figma Linux";
      Comment = "Unofficial Figma desktop application for Linux";
      Exec = "figma-linux %U";
      Icon = "figma-linux";
      Terminal = false;
      Type = "Application";
      Categories = "Graphics;Design;";
      MimeType = "x-scheme-handler/figma;";
      StartupWMClass = "figma-linux";
    };
  };

  xdg.configFile = {
    "sioyek/prefs_user.config".text = lib.generators.toKeyValue {
      mkKeyValue = lib.generators.mkKeyValueDefault { } " ";
    } sioyekPrefs;
    "sioyek/keys_user.config".text = lib.concatLines sioyekKeys;
  };

  # A stale V8 code cache from a previous Electron paints a blank Obsidian window (nixpkgs #578970).
  home.activation.obsidianCacheGuard = ''
    stamp="$HOME/.config/obsidian/.nix-cache-key"
    want="${pkgs.obsidian.version}-${pkgs.electron.version}"
    if [ "$(cat "$stamp" 2>/dev/null)" != "$want" ]; then
      rm -rf "$HOME/.config/obsidian/Cache" "$HOME/.config/obsidian/Code Cache" "$HOME/.config/obsidian/GPUCache"
      mkdir -p "$HOME/.config/obsidian"
      printf '%s' "$want" > "$stamp"
    fi
  '';
}
