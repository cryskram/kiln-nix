# Decision: Hyprland with Dux Shell

Date: 2026-11-17. Supersedes [`caelestia.md`](caelestia.md). Hyprland is now the only compositor; niri and Caelestia were removed. The last Caelestia state is tagged `caelestia-hyprland`.

## Context

The desktop drifted GNOME → Hyprland → niri (with Noctalia, then Dux Shell) → Hyprland with Caelestia. Caelestia was polished, but its Hyprland config and shell came as one opinionated unit. Dux Shell (formerly DankMaterialShell) was already configured here, is packaged in nixpkgs, and supports Hyprland directly.

## Chosen

- **Compositor:** Hyprland 0.57 from `nixpkgs-unstable`, under UWSM (`hyprland-uwsm`, the SDDM default).
- **Shell:** Dux Shell from nixpkgs (`programs.dms-shell` with `pkgs.dux-shell`), started by `dms.service` on `graphical-session.target`.
- **Hyprland config is Dux's own stock config,** taken from the source of the packaged release (`pkgs.dux-shell.src`, `core/internal/config/embedded`), so it always matches the installed shell:
  - `hyprland.lua` is the stock file with one appended line, `require("user")`;
  - `dms/binds.lua` is the stock binds file with the terminal set to Ghostty;
  - `dms/{colors,outputs,cursor,layout,input,windowrules,binds-user}.lua` are rewritten by Dux's Settings UI, so they are seeded once from `hypr/dms-defaults/` and then left to the UI. Colours, monitors and cursor come from `theme/tokens.nix`.
- **`modules/hyprland/user.lua`** is the repo-owned personal layer: live layout cycling, per-layout `Super+[`/`Super+]`, scrolling-layout binds, and the VPN chooser. It lives outside `binds-user.lua` because the Dux keybind editor drops anything but `hl.bind`/`hl.unbind` lines from that file.
- `HYPRLAND_NO_SD_TARGET=1` (UWSM env): UWSM already runs the graphical session, so the stock config's `hyprland-session.target` start, which only Dux's own installer creates, is skipped.
- **Idle:** swayidle (lock via Dux, swaylock fallback; DPMS through `hyprctl`), since Dux's own idle settings are unset.
- **Validation:** `nix flake check` runs `Hyprland --verify-config` on the installed files plus the seeded defaults.

## Trade-offs

- Seeded fragments do not update when the tokens change on an existing install; delete a fragment to have it reseeded.
- Fragment names follow the packaged Dux version. 2.1.2 keeps animations inside `hyprland.lua`; newer releases split them out, so the seed list must follow a Dux upgrade (the flake check fails if a referenced file is missing).
