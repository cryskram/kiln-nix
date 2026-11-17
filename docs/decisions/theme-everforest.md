# Theme: Everforest Dark (and swappable palettes)

Date: 2026-11-17. Superseded 2026-11-18 by Catppuccin Mocha (`theme-catppuccin.md`). Supersedes Gruvbox Dark (`theme-gruvbox.md`) as the global
visual system (RICE §4, AGENTS §18).

## Why

The theme has rotated Tokyo Night → Catppuccin → Gruvbox → Everforest. Each
switch so far meant editing palette names across a dozen modules. This time the
switch was made a one-line change, and Everforest is the first palette on it.

## Chosen solution

- `theme/palettes/<name>.nix` each export one shape: `accents` (red, orange,
  yellow, green, aqua, blue, purple), `colors` (semantic roles + 16 ANSI slots)
  and `apps` (GTK theme, Tela icon colourway, cursor, Neovim colorscheme, pi
  theme, wallpaper set).
- `theme/tokens.nix` imports exactly one of them (`active`). Consumers only use
  role names (`accent-primary`, `surface`, …) or accent names (`palette.blue`),
  never palette-specific names such as `bg0_h` or `orange-bright`.
- Everforest uses the **hard** background variant. The Gruvbox record flagged
  Everforest as possibly washed out at 1080p; hard contrast is the fix.
  Accent is green, secondary blue, cursor orange, selection `bg_visual`.

| Surface | Everforest |
|---|---|
| GTK | `everforest-gtk-theme` → `Everforest-Green-Dark` |
| Icons | `Tela-circle-green-dark` |
| Cursor | `everforest-cursors` |
| Neovim | `sainnhe/everforest`, `everforest_background = "hard"` |
| bat / delta | `base16`, which follows the terminal's ANSI palette |
| pi | `everforest-dark` |
| SDDM | astronaut theme recoloured from tokens + Everforest wallpaper |
| Zed | pinned `albertsko/zed-everforest` theme file, **not selected** |
| Wallpapers | 12 from Apeiros-46B/everforest-walls (Gruvbox set kept) |

## Owned vs. offered

The repo **owns** surfaces with no in-app theme picker (terminal, prompt,
borders, GTK, login). It only **offers** themes where the app has its own picker:
Zed gets the theme file in `~/.config/zed/themes/`, but the choice stays in Zed's
user-owned `settings.json`. pi's `/theme` and Dux Shell's theme picker still work
at runtime.

## Stale-state handling

Two pieces of app-owned state used to pin the old palette after a rebuild:

- **Dux Shell** pointed `customThemeFile` at `gruvbox-dark.json`. The repo now
  writes a palette-neutral `dms/themes/kiln.json`, and activation repoints
  `customThemeFile` to it when the configured file no longer exists.
- **Hyprland `dms/*.lua`** were seeded once and never updated. They now follow
  the repo default until the Dux UI edits them (see ARCHITECTURE.md).

## Tradeoffs

- `base16` syntax highlighting in bat/delta is less detailed than a dedicated
  tmTheme, but it never drifts from the terminal palette. bat ships no
  Everforest theme.
- Everforest has one accent set, so ANSI bright slots repeat the normal ones.
- Electron apps (Slack, Discord, Obsidian, VS Code, Chrome) are not themed. They
  have their own pickers.

## Switching

Point `active` in `theme/tokens.nix` at another palette file, then rebuild and
switch. To add a theme, copy a palette file and fill in the same keys.
