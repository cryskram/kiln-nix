# kiln-nix

Reproducible NixOS desktop and developer workstation: [Hyprland](https://hypr.land) with [Dux Shell](https://github.com/duxlabs-dev/dux-shell) (formerly DankMaterialShell), themed Catppuccin Mocha, Wayland-only.

![NixOS](https://img.shields.io/badge/NixOS-26.05-blue?logo=nixos)
![Hyprland](https://img.shields.io/badge/compositor-Hyprland-d65d0e)
![Shell](https://img.shields.io/badge/shell-Dux%20Shell-504945)

The Git repository is the single source of truth: clone it and rebuild on compatible hardware.

- **Compositor:** Hyprland 0.57 — dwindle, scrolling, master and monocle layouts, switchable live; Dux Shell's stock Lua config
- **Shell:** Dux Shell — bar, launcher, control centre, notifications, lock, wallpapers, overview, display profiles
- **Wallpapers:** curated Catppuccin, Everforest and Gruvbox collections, pinned by hash, in `~/Pictures/Wallpapers/<set>`
- **Theme:** Catppuccin Mocha from one set of tokens ([`theme/tokens.nix`](theme/tokens.nix)); palettes are swappable
- **Login:** SDDM with the Astronaut theme
- **Workstation:** devenv + direnv, Docker, language toolchains, pi and OpenCode coding agents

Docs: [`ARCHITECTURE.md`](ARCHITECTURE.md) (how and why) · [`AGENTS.md`](AGENTS.md) (working rules) · [`RICE.md`](RICE.md) (visual spec) · [`DEV_ENVIRONMENT.md`](DEV_ENVIRONMENT.md) · [`docs/decisions/`](docs/decisions/)

## Quick start

```bash
git clone https://github.com/cryskram/kiln-nix.git ~/kiln-nix
cd ~/kiln-nix
nix flake check
sudo nixos-rebuild switch --flake .#nixos --accept-flake-config
```

Requires NixOS 26.05 on x86_64 with flakes enabled. Built on Intel graphics at 1920×1080; outputs are configured per connector, so additional monitors work.

## Layout

```
flake.nix            inputs, formatter, checks, the `nixos` system
configuration.nix    host basics (boot, locale, audio, user)
modules/             NixOS modules — nix, core, pi/, hyprland/, dms-shell, sddm, vpn, …
home/                Home Manager modules and scripts/
theme/tokens.nix     colours, fonts, cursor, icons
pi/                  pi extensions, skills, brain, themes, pinned packages
pkgs/                packages not in nixpkgs
dev/                 devenv fragments and project templates
```

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for details.

## Keybindings

Dux Shell's [stock Hyprland binds](https://github.com/duxlabs-dev/dux-shell/blob/master/core/internal/config/embedded/hypr-binds.lua) apply unchanged (`Super+Shift+/` shows them all); the essentials:

| Bind | Action |
|---|---|
| `Super+Space` / `Alt+Space` | launcher / launcher bar |
| `Super+T` / `Super+Return` | Ghostty |
| `Super+Q`, `Super+F`, `Super+Shift+T` | close, maximise, toggle floating |
| `Super+arrows` or `Super+HJKL` | focus; add `Shift` to move the window |
| `Super+1..9`, `Super+Shift+1..9` | go to / move window to workspace |
| `Super+Tab` / `Super+O` | overview |
| `Super+A`, `Super+D`, `Super+M` | control centre, dashboard, media |
| `Super+V`, `Super+Ctrl+N` | clipboard history, notifications |
| `Super+Alt+L`, `Super+X` | lock, power menu |
| `Print`, `Ctrl+Print`, `Alt+Print` | region, full, window screenshot |
| `Super+P` | cycle display profiles |
| `Super+S` | scratchpad workspace |

Added in [`modules/hyprland/user.lua`](modules/hyprland/user.lua):

| Bind | Action |
|---|---|
| `Super+Shift+Space` | cycle layout: dwindle → scrolling → master → monocle |
| `Super+[` / `Super+]` | scrolling: column width down / up through presets (dwindle: Dux's split preselect) |
| `Super+Shift+[` / `Super+Shift+]` | scrolling: swap column left / right |
| `Super+Ctrl+[` / `Super+Ctrl+]` | scrolling: pull window into / push out of the neighbouring column |
| `Super+\` / `Super+Shift+\` | scrolling: fit visible columns / promote window to its own column |
| `Super+Alt+V` | VPN chooser |

## Development environments

```bash
mkdir ~/my-app && cd ~/my-app
cp -r ~/kiln-nix/dev/templates/go/. .   # or node, java, python, python-ai, rust
direnv allow
```

Templates are standalone, so a copied project does not depend on this repository. Company projects use a personal env from `dev/company/` without adding Nix files to the company repo (see [`dev/company/README.md`](dev/company/README.md)).

## VPN and secrets

Secrets never enter Git: `secrets/*` is ignored except its README. Tunnels are used through NetworkManager:

```bash
nmcli connection import type wireguard file ~/kiln-nix/secrets/wg0.conf
vpn-toggle    # or Super+Alt+V — also handles Proton VPN and Tailscale
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
