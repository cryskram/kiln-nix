# niri-desktop

Reproducible NixOS desktop and developer workstation built around [Niri](https://github.com/YaLTeR/niri) and the [Caelestia](https://github.com/caelestia-dots/shell) shell, themed Gruvbox Dark, Wayland-only.

![NixOS](https://img.shields.io/badge/NixOS-26.05-blue?logo=nixos)
![Niri](https://img.shields.io/badge/compositor-Niri-d65d0e)
![Shell](https://img.shields.io/badge/shell-Caelestia-504945)

The Git repository is the single source of truth: clone it and rebuild on compatible hardware.

- **Compositor:** Niri — scrollable tiling, 12px corners, 8px gaps, 2px focus border, glass blur
- **Shell:** Caelestia (Quickshell, niri fork) — bar, launcher, dashboard, notifications, lock, wallpapers; Dux Shell selectable via `desktop.shell`
- **Wallpapers:** 17 curated Gruvbox wallpapers, pinned by hash, in `~/Pictures/Wallpapers/gruvbox`
- **Theme:** Gruvbox Dark from one set of tokens ([`theme/tokens.nix`](theme/tokens.nix))
- **Login:** SDDM with the Astronaut theme
- **Workstation:** devenv + direnv, Docker, language toolchains, pi and OpenCode coding agents

Docs: [`ARCHITECTURE.md`](ARCHITECTURE.md) (how and why) · [`AGENTS.md`](AGENTS.md) (working rules) · [`RICE.md`](RICE.md) (visual spec) · [`DEV_ENVIRONMENT.md`](DEV_ENVIRONMENT.md) · [`docs/decisions/`](docs/decisions/)

## Quick start

```bash
git clone https://github.com/cryskram/niri-desktop.git ~/niri-desktop
cd ~/niri-desktop
nix flake check
sudo nixos-rebuild switch --flake .#nixos --accept-flake-config
```

Requires NixOS 26.05 on x86_64 with flakes enabled. Built on Intel graphics at 1920×1080; outputs are configured per connector, so additional monitors work.

## Layout

```
flake.nix            inputs, formatter, checks, the `nixos` system
configuration.nix    host basics (boot, locale, audio, user)
modules/             NixOS modules — nix, core, pi/, dms-shell, niri, sddm, vpn, …
home/                Home Manager modules and scripts/
theme/tokens.nix     colours, fonts, cursor, icons
pi/                  pi extensions, skills, brain, themes, pinned packages
pkgs/                packages not in nixpkgs
dev/                 devenv fragments and project templates
```

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for details.

## Keybindings

Niri's default bindings are included first; these are added or overridden.

| Bind | Action |
|---|---|
| `Mod+T` / `Mod+Return` | Ghostty |
| `Mod+D` / `Mod+Slash` | launcher (`>` for actions: `>wallpaper`, `>scheme`, `>variant`) |
| `Mod+A` | dashboard (media, weather, performance) |
| `Mod+N` | notifications sidebar |
| `Mod+Ctrl+C` | utilities (quick toggles) |
| `Mod+P` / `Mod+Shift+E` | session menu |
| `Super+Alt+L` | lock |
| `Mod+Ctrl+V` | clipboard history |
| `Mod+Semicolon` | emoji picker |
| `Mod+Shift+S` / `Print` | region (annotate in swappy) / full screenshot |
| `Mod+Shift+R` | record a region (press again to stop) |
| `Mod+M` | toggle mirroring onto HDMI-A-1 |
| `Mod+Shift+1` / `Mod+Shift+2` | extend with HDMI left / right |
| `Mod+Shift+N` | VPN chooser (`vpn-toggle`) |

Theme and wallpaper are picked from the launcher (`>scheme`, `>wallpaper`). Switching back to Dux Shell is one line: `desktop.shell = "dms";`.

## Development environments

```bash
mkdir ~/my-app && cd ~/my-app
cp -r ~/niri-desktop/dev/templates/go/. .   # or node, java, python, python-ai, rust
direnv allow
```

Templates are standalone, so a copied project does not depend on this repository. Company projects use a personal env from `dev/company/` without adding Nix files to the company repo (see [`dev/company/README.md`](dev/company/README.md)).

## VPN and secrets

Secrets never enter Git: `secrets/*` is ignored except its README. Tunnels are used through NetworkManager:

```bash
nmcli connection import type wireguard file ~/niri-desktop/secrets/wg0.conf
vpn-toggle    # or Mod+Shift+N — also handles Proton VPN and Tailscale
vpn-status
```

See [`secrets/README.md`](secrets/README.md) and [`docs/tailscale.md`](docs/tailscale.md).

## Validate and rebuild

```bash
nix fmt                                   # nixfmt, biome, shfmt
nix flake check                           # evaluation + `niri validate` on the generated config
nixos-rebuild dry-build --flake .#nixos
sudo nixos-rebuild switch --flake .#nixos --accept-flake-config
```

## Updating

Update one flake input at a time and check what will compile before switching:

```bash
git tag pre-update-$(date +%Y%m%d)
nix flake update nixpkgs
nix build --dry-run --no-link .#nixosConfigurations.nixos.config.system.build.toplevel
nix flake check
```

| Input | Cost |
|---|---|
| `nixpkgs` | kernel modules (~10 min) when the kernel moves |
| `nixpkgs-unstable` | usually cached (also provides the shell and coding agents) |
| `pi` | cached via `pi.cachix.org` |
| `home-manager`, `spicetify-nix` | seconds |

Third-party pi extensions are pinned in [`pi/packages.nix`](pi/packages.nix), not as flake inputs:

```bash
scripts/update-pi-extensions.py                # report outdated pins
scripts/update-pi-extensions.py --update NAME  # bump one (or --update-all)
scripts/update-pi-extensions.py --rehash       # re-capture npm hashes after a nodejs bump
```

A `hash mismatch in fixed-output derivation … node-modules` error after a nixpkgs bump is expected: the build is reporting the new npm hash. `--rehash` captures it.

## Rollback

```bash
sudo nixos-rebuild switch --rollback
git log --oneline --tags
```
