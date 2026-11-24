# Dux Shell (formerly DankMaterialShell) rewrites its own settings.json, so the repo owns only the theme and plugin patches.
{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  tokens = import ../theme/tokens.nix;
  wallpapers = import ../theme/wallpapers.nix { inherit (pkgs) fetchurl; };
  c = tokens.colors;

  theme = {
    inherit (tokens) name;
    primary = c.accent-primary;
    primaryText = c.background-darkest;
    primaryContainer = c.accent-container;
    secondary = c.accent-secondary;
    surface = c.surface;
    surfaceText = c.foreground;
    surfaceVariant = c.surface-elevated;
    surfaceVariantText = c.foreground-muted;
    surfaceTint = c.accent-primary;
    surfaceContainerLowest = c.background-darkest;
    surfaceContainerLow = c.background;
    surfaceContainer = c.background-deep;
    surfaceContainerHigh = c.surface;
    surfaceContainerHighest = c.surface-elevated;
    background = c.background;
    backgroundText = c.foreground;
    outline = c.surface-hover;
    error = c.error;
    warning = c.warning;
    info = c.info;
    matugen_type = "scheme-content";
  };
in
{
  programs.dms-shell = {
    enable = true;
    package = pkgs.dux-shell;
    quickshell.package = pkgs.quickshell;
    enableSystemMonitoring = true;
    enableClipboardPaste = true;
    enableAudioWavelength = true;
    enableVPN = true;
    enableDynamicTheming = true;
  };

  systemd.user.services.dms.environment = {
    DMS_DISABLE_MATUGEN = "1";
    OPENCODE_USAGE_SOURCE = "api";
  };

  home-manager.users.${user} =
    { config, lib, ... }:
    let
      themeFile = "${config.xdg.configHome}/dms/themes/kiln.json";
    in
    {
      xdg.configFile."dms/themes/kiln.json".text = builtins.toJSON theme;

      home.file = lib.concatMapAttrs (
        set: walls:
        lib.listToAttrs (
          map (w: lib.nameValuePair "Pictures/Wallpapers/${set}/${w.name}" { source = w.path; }) walls
        )
      ) wallpapers;

      home.activation.dmsSeedSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        cfg="$HOME/.config/dms/settings.json"
        jq=${pkgs.jq}/bin/jq
        if [ ! -f "$cfg" ]; then
          mkdir -p "$(dirname "$cfg")"
          $jq -n --arg file "${themeFile}" --arg icons "${tokens.icons.name}" \
            '{ currentThemeName: "custom", customThemeFile: $file, iconThemeDark: $icons }' > "$cfg"
        elif [ "$($jq -r '.currentThemeName' "$cfg")" = custom ] \
          && [ ! -e "$($jq -r '.customThemeFile // ""' "$cfg")" ]; then
          $jq --arg file "${themeFile}" --arg icons "${tokens.icons.name}" \
            '.customThemeFile = $file | .iconThemeDark = $icons' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
        fi
      '';

      # AiOverviewControl still parses the pre-2026-10 Zen quota shape; re-applied because plugin updates replace the file.
      home.activation.patchAiOverviewControlOpencode = ''
        plugin="$HOME/.config/dms/plugins/aiOverviewControl"
        adapter="$plugin/providers/native/opencode.bash"
        if [ -f "$adapter" ] && ! grep -q 'current_shape' "$adapter"; then
          ${pkgs.patch}/bin/patch --forward --silent -p1 -d "$plugin" < ${../patches/aioc-opencode-usage-shape.patch} \
            || echo "AiOverviewControl: opencode adapter patch failed; upstream may have changed it" >&2
        fi
      '';

      # A truncated usage cache once made the Claude provider skip its API call forever; see docs/decisions/dank-material-shell.md.
      home.activation.patchAiOverviewControlClaude = ''
        plugin="$HOME/.config/dms/plugins/aiOverviewControl"
        script="$plugin/providers/get-claude-usage"
        if [ -f "$script" ] && ! grep -q 'cache_ts" in' "$script"; then
          ${pkgs.patch}/bin/patch --forward --silent -p1 -d "$plugin" < ${../patches/aioc-claude-cache-robust.patch} \
            || echo "AiOverviewControl: claude usage patch failed; upstream may have changed it" >&2
        fi
      '';
    };
}
