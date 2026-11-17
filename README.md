# niri-desktop

Reproducible NixOS desktop and developer workstation: [Hyprland](https://hypr.land) with the official [Caelestia](https://github.com/caelestia-dots/shell) shell and dotfiles, themed Gruvbox Dark, Wayland-only. [Niri](https://github.com/YaLTeR/niri) with Dux Shell remains one option away.

![NixOS](https://img.shields.io/badge/NixOS-26.05-blue?logo=nixos)
![Hyprland](https://img.shields.io/badge/compositor-Hyprland-d65d0e)
![Shell](https://img.shields.io/badge/shell-Caelestia-504945)

The Git repository is the single source of truth: clone it and rebuild on compatible hardware.

- **Compositor:** Hyprland 0.57 — dwindle, scrolling, master and monocle layouts, switchable live; official Caelestia Lua config
- **Shell:** Caelestia (official) — bar, launcher, dashboard, notifications, lock, wallpapers, theme picker
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

The official [Caelestia keybinds](https://github.com/caelestia-dots/caelestia/blob/main/hypr/variables.lua) apply unchanged; the essentials:

| Bind | Action |
|---|---|
| tap `Super` | launcher (`>scheme`, `>wallpaper`, `>variant` for theming) |
| `Super+T` / `Super+W` / `Super+E` / `Super+C` | Ghostty / Chrome / Nautilus / VS Code |
| `Super+Q` | close window |
| `Super+1..0`, `Super+Shift+1..0` | go to / move window to workspace |
| `Super+arrows`, `Super+Shift+arrows` | focus / move window |
| `Super+F`, `Super+Alt+Space` | fullscreen, toggle floating |
| `Super+N`, `Super+K` | notifications sidebar, all panels |
| `Super+L`, `Ctrl+Alt+Delete` | lock, session menu |
| `Super+V`, `Super+Period` | clipboard history, emoji picker |
| `Print`, `Super+Shift+S` | full screenshot, frozen region picker |
| `Super+S`, `Super+M`, `Super+D` | special workspaces: scratch, music, communication |

Added in `modules/hyprland/user.lua`:

| Bind | Action |
|---|---|
| `Super+Shift+Space` | cycle layout: dwindle → scrolling → master → monocle |
| `Super+[` / `Super+]` | scrolling: column width down / up through presets |
| `Super+Shift+[` / `Super+Shift+]` | scrolling: swap column left / right |
| `Super+Ctrl+[` / `Super+Ctrl+]` | scrolling: pull window into / push out of the neighbouring column |
| `Super+\` / `Super+Shift+\` | scrolling: fit visible columns / promote window to its own column |
| `Super+Shift+N` | VPN chooser |

To switch to niri with Dux Shell: `desktop.shell = "dms";` in `modules/desktop.nix`, then rebuild.

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
nix flake check                           # evaluation + validates the active compositor config
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
