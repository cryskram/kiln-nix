# Theme: Gruvbox Dark

Date: 2026-11-17. Superseded the same day by Everforest Dark (`theme-everforest.md`); it supersedes Catppuccin Macchiato as the global visual system
(RICE §4, AGENTS §18).

## Alternatives considered

| Theme | Why it was considered | Why it lost |
|---|---|---|
| **Gruvbox Dark** | warm sepia base, orange accent, reads well on a 1080p panel at a distance | — chosen |
| Tokyo Night Storm | highest polish, very high contrast | cool blue/violet; the desktop already leans cold between niri borders and the lock screen |
| Everforest Dark | calmest of the set, pairs well with glass/blur | can look washed out on a 24" 1080p panel at arm's length |
| Kanagawa Wave | distinctive ink-wash indigo + gold | busiest accent set to keep coherent across six surfaces |
| Catppuccin Mocha | zero-effort (input already present) | same family, no real visual change |

Selection criterion was coherence across surfaces rather than individual novelty:
one palette has to work in the compositor borders, the shell, the terminal,
diffs, PDFs, Spotify and the editor at once.

## What changed

- `theme/tokens.nix` — full Gruvbox Dark palette (bg0–bg4, fg/fg2/fg3, orange +
  blue accents, canonical 16-slot ANSI mapping). Still the single source of truth.
- `theme/dms-gruvbox.json` — DMS theme (replaces `dms-macchiato.json`).
- `modules/catppuccin.nix` **deleted**; the `catppuccin` flake input, its NixOS
  module and its HM module are all removed. Catppuccin's auto-theming is what
  made this a cross-cutting change rather than a token swap.
- GTK `gruvbox-dark`, icons `Tela-circle-orange-dark`, cursor
  `Bibata-Modern-Amber`, ghostty palette straight from tokens.
- Per-app: fish colours, delta `gruvbox-dark` (bat ships it), Neovim
  `ellisonleone/gruvbox.nvim`, sioyek floats, spicetify custom scheme,
  pi default theme `gruvbox-dark`.

## Tradeoffs and known gaps

- **No Gruvbox cursor port in nixpkgs.** Bibata Modern Amber stands in; it is
  dark-neutral with an amber accent, so it reads as part of the palette without
  pretending to be a gruvbox asset.
- **Zed ships no Gruvbox theme.** Its theme is user-owned in
  `~/.config/zed/settings.json`, so it stays on Catppuccin Macchiato until a
  Gruvbox theme is installed from the extension registry. Vendoring a theme JSON
  would be the declarative route if that matters later.
- **DMS themes are app-owned theme packages.** The running shell pointed at
  `~/.config/dms/themes/catppuccin/theme.json` (a multi-variant package), not at
  the Home-Manager file, so the palette only repaints once `customThemeFile` is
  repointed. `modules/dms-shell.nix` seeds it on a fresh profile; an existing
  profile needs the one-time edit described in `docs/`.
- Catppuccin themes remain in `pi/themes/` and stay selectable via `/theme` —
  the desktop palette changed, the editor's available themes did not.

## Reversal

Restore `modules/catppuccin.nix` and the input, point `theme/tokens.nix` at the
Macchiato values (git history has them), then rebuild. Half-reverted states are
what break: the GTK theme name, icon package and cursor package must all agree
with the tokens.
