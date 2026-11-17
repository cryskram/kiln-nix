# Dux Shell (formerly DankMaterialShell) rewrites its own settings.json, so the repo owns only the theme and plugin patches.
{ pkgs, user, ... }:
let
  tokens = import ../theme/tokens.nix;
  c = tokens.colors;
  p = tokens.palette;

  theme = {
    name = "Gruvbox Dark";
    primary = c.accent-primary;
    primaryText = c.background-darkest;
    primaryContainer = p.aqua-faded;
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
    { config, ... }:
    let
      themeFile = "${config.xdg.configHome}/dms/themes/gruvbox-dark.json";
    in
    {
      xdg.configFile."dms/themes/gruvbox-dark.json".text = builtins.toJSON theme;

      home.activation.dmsSeedSettings = ''
        cfg="$HOME/.config/dms/settings.json"
        if [ ! -f "$cfg" ]; then
          mkdir -p "$(dirname "$cfg")"
          ${pkgs.jq}/bin/jq -n --arg file "${themeFile}" --arg icons "${tokens.icons.name}" \
            '{ currentThemeName: "custom", customThemeFile: $file, iconThemeDark: $icons }' > "$cfg"
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
    };
}
