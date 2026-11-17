# Decision: Caelestia shell on niri

Date: 2026-11-17. Supersedes DMS as the default shell; DMS stays available (`desktop.shell = "dms"`).

## Problem

Upstream [Caelestia](https://github.com/caelestia-dots/shell) is Hyprland-only: workspaces, the active window, fullscreen detection and its keybinds all go through Hyprland IPC and Hyprland global shortcuts. It has no niri code path.

## Alternatives

| Option | State (Nov 2026) | Verdict |
|---|---|---|
| Upstream caelestia-dots/shell | active, no niri support | broken workspaces/active window under niri |
| jutraim/niri-caelestia-shell | self-declared abandoned | no |
| AyushKr2003/niri-caelestia-shell | archived 2026-06 | no |
| luqmanishere/caelestia-niri | fork, 48 commits behind upstream | stale |
| tadeasf/caelestia-niri | overlay + regex patches over upstream, imperative `build.py`, tied to their niri-gnome setup | not declarative |
| **CrankyTitanO7/caelestia-shell-WM** | fork 1 commit behind upstream; generic `Wm` service with Hyprland/niri/Umbriel backends; ships upstream's Nix flake and Home Manager module | **chosen** |

## Chosen

The CrankyTitanO7 fork, consumed as a flake input (`inputs.caelestia`) that follows `nixpkgs-unstable`, with `general.windowManager = "Niri"`. Configuration lives in `modules/caelestia/`.

- **Theme.** caelestia-cli's bundled `gruvbox` scheme is not Gruvbox (it is a teal Material palette). `modules/caelestia/scheme.nix` regenerates all three flavours, dark and light, from `theme/tokens.nix`, and the CLI package is overridden to ship them, so the theme picker offers a real Gruvbox.
- **State.** Caelestia writes `~/.local/state/caelestia/{scheme.json,wallpaper/path.txt}` from its UI. Activation seeds them only when absent (Gruvbox medium dark, `pixel-watermill`), so picker choices survive rebuilds.
- **CLI theme appliers are off** (`cli.json`): they rewrite GTK, Qt, fuzzel, terminal and other configs that Home Manager owns. Scheme changes recolour the shell only.
- **Fonts.** The package pins fontconfig to its bundled fonts; the wrapper is patched to `--set-default` so the service can add Inter and JetBrains Mono from the tokens.
- **Keybinds** are niri binds calling `caelestia-shell ipc call …` (see `home/niri.nix`); each has a fallback where one exists.
- **Idle** is Caelestia's own monitor (lock at 5 min, DPMS off at 5.5 min); swayidle runs only under DMS.

## Trade-offs

- Single-maintainer fork, written with AI assistance, 0 stars. If it stalls, the `Wm` layer is the part to port; DMS is one option away.
- quickshell (git) and the QML plugin build from source on input updates.
- niri exposes no fullscreen state over IPC, so "hide over fullscreen" behaviours are limited (documented upstream in the fork).
