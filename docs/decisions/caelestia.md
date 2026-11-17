# Decision: official Caelestia on Hyprland

Date: 2026-11-17. Replaces niri + Dux Shell as the default session; that pairing remains selectable with `desktop.shell = "dms"`.

## Problem

[Caelestia](https://github.com/caelestia-dots/shell) is built for Hyprland: workspaces, the active window, fullscreen detection and every keybind go through Hyprland IPC and Hyprland global shortcuts.

## Alternatives

| Option | Verdict |
|---|---|
| Caelestia on niri via a community fork (CrankyTitanO7/caelestia-shell-WM; tried first, see Git history) | works, but a single-maintainer, AI-written fork; Hyprland-only features hidden |
| Other niri ports (jutraim, AyushKr2003, luqmanishere, tadeasf) | abandoned, archived, stale or imperative |
| **Official shell + official dots on Hyprland** | **chosen**: the configuration Caelestia is developed and tested against |

## Chosen

- **Inputs.** `caelestia-shell` (the official flake, following `nixpkgs-unstable`) and `caelestia-dots` (the official dotfiles, `flake = false`). Hyprland 0.57 comes from `nixpkgs-unstable` through the overlay, matching what the dots target.
- **Hyprland config is the official Lua config, unchanged.** `modules/hyprland/` links `hyprland.lua`, `variables.lua`, `hyprland/` and `utils/` from the dots. Personal settings use the hooks the dots provide: `~/.config/caelestia/hypr-vars.lua` (apps, cursor; generated from Nix) and `hypr-user.lua` (`modules/hyprland/user.lua`: monitors, layout switching, scrolling binds).
- **Validation.** `nix flake check` runs `Hyprland --verify-config` against exactly those files.
- **Session.** UWSM (`hyprland-uwsm`) is the SDDM default. The dots start the shell, cliphist, gammastep and the keyring themselves.
- **Theme.** caelestia-cli's bundled `gruvbox` scheme is a teal Material palette. `modules/caelestia/scheme.nix` generates real Gruvbox (hard/medium/soft, dark/light) from `theme/tokens.nix`. The CLI package ships it, and it seeds both the shell state and `hypr/scheme/default.lua`, so borders and shell start in Gruvbox. Only the CLI's `enableHypr` applier is on, so the theme picker recolours the shell and Hyprland borders, never files Home Manager owns.
- **Fonts.** The shell's wrapper pins fontconfig to its bundled fonts; the package is patched to use a font set that includes Inter and JetBrains Mono from the tokens.

## Trade-offs

- The repository is still named `niri-desktop`; niri is now the alternative session.
- quickshell (git) and the Caelestia QML plugin build from source on every input update.
- The dots' `execs.lua` assumes Arch paths for polkit-gnome and the geoclue demo agent; those calls fail harmlessly, and the NixOS modules provide hyprpolkitagent and the geoclue agent instead.
- `niri-display-toggle` is niri-specific; under Hyprland, monitors are configured in `user.lua`.
