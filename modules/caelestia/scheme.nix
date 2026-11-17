# Caelestia's bundled "gruvbox" scheme is a teal Material palette; this rebuilds it from theme/tokens.nix.
{ lib }:
let
  tokens = import ../../theme/tokens.nix;
  inherit (tokens) hexNoHash;
  p = tokens.palette;
  l = tokens.paletteLight;

  dark =
    surfaces: with p; {
      mode = "dark";
      inherit surfaces;
      text = {
        on = fg1;
        onVariant = fg3;
        outline = gray;
        outlineVariant = bg3;
        inverse = fg1;
        onInverse = bg1;
        onAccent = bg0_h;
        onContainer = fg0;
      };
      accents = {
        primary = orange-bright;
        primaryContainer = orange;
        secondary = blue-bright;
        secondaryContainer = blue;
        tertiary = aqua-bright;
        tertiaryContainer = aqua-faded;
        error = red-bright;
        errorContainer = red-faded;
        success = green-bright;
        successContainer = green-faded;
        inversePrimary = orange-faded;
        keys = {
          primary = orange;
          secondary = blue;
          tertiary = aqua;
          neutral = gray;
          neutral_variant = fg4;
        };
      };
      named = {
        rosewater = fg0;
        flamingo = purple-bright;
        pink = purple-bright;
        mauve = purple-bright;
        red = red-bright;
        maroon = red;
        peach = orange-bright;
        yellow = yellow-bright;
        green = green-bright;
        teal = aqua-bright;
        sky = blue-bright;
        sapphire = blue-bright;
        blue = blue-bright;
        lavender = purple-bright;
        link = blue-bright;
        visited = purple-bright;
        positive = green-bright;
        neutral = yellow-bright;
        negative = red-bright;
      };
      ansi = tokens.colors.ansi;
      text-scale = [
        fg1
        fg2
        fg3
        fg4
        gray
        bg4
        bg3
        bg2
        bg1
      ];
    };

  light =
    surfaces: with l; {
      mode = "light";
      inherit surfaces;
      text = {
        on = fg1;
        onVariant = fg3;
        outline = p.gray;
        outlineVariant = bg3;
        inverse = fg1;
        onInverse = bg1;
        onAccent = bg0_h;
        onContainer = fg0;
      };
      accents = with p; {
        primary = orange-faded;
        primaryContainer = orange-bright;
        secondary = blue-faded;
        secondaryContainer = blue-bright;
        tertiary = aqua-faded;
        tertiaryContainer = aqua-bright;
        error = red-faded;
        errorContainer = red-bright;
        success = green-faded;
        successContainer = green-bright;
        inversePrimary = orange-bright;
        keys = {
          primary = orange;
          secondary = blue;
          tertiary = aqua;
          neutral = gray;
          neutral_variant = l.fg4;
        };
      };
      named = with p; {
        rosewater = l.fg0;
        flamingo = purple-faded;
        pink = purple-faded;
        mauve = purple-faded;
        red = red-faded;
        maroon = red;
        peach = orange-faded;
        yellow = yellow-faded;
        green = green-faded;
        teal = aqua-faded;
        sky = blue-faded;
        sapphire = blue-faded;
        blue = blue-faded;
        lavender = purple-faded;
        link = blue-faded;
        visited = purple-faded;
        positive = green-faded;
        neutral = yellow-faded;
        negative = red-faded;
      };
      ansi = with p; [
        bg0
        red
        green
        yellow
        blue
        purple
        aqua
        l.fg4
        gray
        red-faded
        green-faded
        yellow-faded
        blue-faded
        purple-faded
        aqua-faded
        l.fg1
      ];
      text-scale = [
        fg1
        fg2
        fg3
        fg4
        p.gray
        bg4
        bg3
        bg2
        bg1
      ];
    };

  surfaceSet = lowest: low: surface: container: high: highest: bright: {
    inherit
      lowest
      low
      surface
      container
      high
      highest
      bright
      ;
  };

  variants = {
    hard = {
      dark = dark (surfaceSet "#141617" p.bg0_h p.bg0_h p.bg0 p.bg1 p.bg2 p.bg3);
      light = light (surfaceSet "#ffffff" l.bg0_h l.bg0_h l.bg0 l.bg0_s l.bg1 l.bg2);
    };
    medium = {
      dark = dark (surfaceSet p.bg0_h p.bg0_s p.bg0 p.bg1 p.bg2 p.bg3 p.bg3);
      light = light (surfaceSet l.bg0_h l.bg0_s l.bg0 l.bg1 l.bg2 l.bg3 l.bg2);
    };
    soft = {
      dark = dark (surfaceSet p.bg0 p.bg1 p.bg0_s p.bg1 p.bg2 p.bg3 p.bg4);
      light = light (surfaceSet l.bg0 l.bg0_s l.bg0_s l.bg1 l.bg2 l.bg3 l.bg3);
    };
  };

  colours =
    v:
    let
      s = v.surfaces;
      t = v.text;
      a = v.accents;
      n = v.named;
      scale = v.text-scale;
      at = builtins.elemAt scale;
    in
    lib.mapAttrs (_: hexNoHash) (
      {
        primary_paletteKeyColor = a.keys.primary;
        secondary_paletteKeyColor = a.keys.secondary;
        tertiary_paletteKeyColor = a.keys.tertiary;
        neutral_paletteKeyColor = a.keys.neutral;
        neutral_variant_paletteKeyColor = a.keys.neutral_variant;

        background = s.surface;
        onBackground = t.on;
        surface = s.surface;
        surfaceDim = s.lowest;
        surfaceBright = s.bright;
        surfaceContainerLowest = s.lowest;
        surfaceContainerLow = s.low;
        surfaceContainer = s.container;
        surfaceContainerHigh = s.high;
        surfaceContainerHighest = s.highest;
        onSurface = t.on;
        surfaceVariant = s.high;
        onSurfaceVariant = t.onVariant;
        inverseSurface = t.inverse;
        inverseOnSurface = t.onInverse;
        outline = t.outline;
        outlineVariant = t.outlineVariant;
        shadow = "#000000";
        scrim = "#000000";

        surfaceTint = a.primary;
        primary = a.primary;
        onPrimary = t.onAccent;
        primaryContainer = a.primaryContainer;
        onPrimaryContainer = t.onContainer;
        inversePrimary = a.inversePrimary;
        secondary = a.secondary;
        onSecondary = t.onAccent;
        secondaryContainer = a.secondaryContainer;
        onSecondaryContainer = t.onContainer;
        tertiary = a.tertiary;
        onTertiary = t.onAccent;
        tertiaryContainer = a.tertiaryContainer;
        onTertiaryContainer = t.onContainer;
        error = a.error;
        onError = t.onAccent;
        errorContainer = a.errorContainer;
        onErrorContainer = t.onContainer;
        success = a.success;
        onSuccess = t.onAccent;
        successContainer = a.successContainer;
        onSuccessContainer = t.onContainer;

        primaryFixed = a.primary;
        primaryFixedDim = a.primaryContainer;
        onPrimaryFixed = t.onAccent;
        onPrimaryFixedVariant = s.high;
        secondaryFixed = a.secondary;
        secondaryFixedDim = a.secondaryContainer;
        onSecondaryFixed = t.onAccent;
        onSecondaryFixedVariant = s.high;
        tertiaryFixed = a.tertiary;
        tertiaryFixedDim = a.tertiaryContainer;
        onTertiaryFixed = t.onAccent;
        onTertiaryFixedVariant = s.high;

        klink = n.link;
        klinkSelection = n.link;
        kvisited = n.visited;
        kvisitedSelection = n.visited;
        knegative = n.negative;
        knegativeSelection = n.negative;
        kneutral = n.neutral;
        kneutralSelection = n.neutral;
        kpositive = n.positive;
        kpositiveSelection = n.positive;

        text = at 0;
        subtext1 = at 1;
        subtext0 = at 2;
        overlay2 = at 3;
        overlay1 = at 4;
        overlay0 = at 5;
        surface2 = at 6;
        surface1 = at 7;
        surface0 = at 8;
        base = s.surface;
        mantle = s.lowest;
        crust = s.lowest;
      }
      // removeAttrs n [
        "link"
        "visited"
        "positive"
        "neutral"
        "negative"
      ]
      // lib.listToAttrs (lib.imap0 (i: c: lib.nameValuePair "term${toString i}" c) v.ansi)
    );

  render = v: lib.concatLines (lib.mapAttrsToList (k: c: "${k} ${c}") (colours v));
in
{
  files = lib.concatMapAttrs (
    flavour: modes: lib.mapAttrs' (mode: v: lib.nameValuePair "${flavour}/${mode}.txt" (render v)) modes
  ) variants;

  state = flavour: mode: {
    name = "gruvbox";
    inherit flavour mode;
    variant = "tonalspot";
    colours = colours variants.${flavour}.${mode};
  };
}
