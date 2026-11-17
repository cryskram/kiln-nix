# Theme: Catppuccin Mocha

Date: 2026-11-18. Supersedes Everforest Dark (`theme-everforest.md`) as the
global visual system (RICE §4, AGENTS §18).

## Why

Everforest was tried for a day and did not look right on this desktop.
Catppuccin was the theme before Gruvbox and is the one that felt best. Mocha
(darkest flavour) is the default; Macchiato is one word away.

## Chosen solution

`theme/palettes/catppuccin.nix` takes `{ flavour }` (`mocha` or `macchiato`)
and fills the same shape as the other palettes (see `theme-everforest.md`):

- Accent mauve, secondary blue, cursor rosewater, selection surface2.
- ANSI follows Catppuccin's official terminal ports (surface1/surface2 for
  black, pink for magenta, subtext for white).
- GTK `catppuccin-gtk` (flavour + mauve via `override`), Tela-circle purple
  icons, `catppuccin-cursors.<flavour>Mauve`, Neovim `catppuccin/nvim`
  (spec named `catppuccin` so it merges with LazyVim's own entry), pi
  `catppuccin-<flavour>`.
- 16 wallpapers from orangci/walls-catppuccin-mocha, all at least 1920×1080,
  chosen from a visual contact sheet. The first one is the SDDM background.

Palette `apps.gtk.override` and dotted `apps.cursor.package` paths were added
to the shared shape for this; other palettes ignore them.

## Unchanged

Zed, VS Code and other apps with their own picker are still only offered
themes, never switched. Zed's own Catppuccin extension was already installed.

## Switching

`theme/tokens.nix`: `import ./palettes/catppuccin.nix { flavour = "macchiato"; }`,
or point it at `everforest.nix` / `gruvbox.nix`.
