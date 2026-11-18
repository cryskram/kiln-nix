# Architecture

How the repository is put together, and the non-obvious reasons behind it. Code comments are kept to a minimum; the *why* lives here and in [`docs/decisions/`](docs/decisions/).

## Layout

```
flake.nix                 inputs, formatter (treefmt), Hyprland config check, the `nixos` system
configuration.nix         host: boot, locale, audio, printing, the user account
hardware-configuration.nix  generated — do not edit
modules/                  NixOS modules (imported by modules/default.nix)
  nix.nix                 nix settings, GC, nixpkgs-unstable overlay
  core.nix                Home Manager wiring, session variables, desktop services
  pi/                     pi coding agent: default.nix (agent), guard.nix (permissions), mcp.nix (MCP servers)
  hyprland/               Hyprland session: Dux Shell's stock Lua config, seeded dms/*.lua, user.lua
  dms-shell.nix           Dux Shell: theme, wallpapers, settings seed, plugin patch
  sddm, theme, shell, docker, ollama, direnv, vpn, tailscale, ssh, android
home/                     Home Manager modules (imported by home/default.nix)
  scripts/*.sh            user scripts, built with writeShellApplication (shellcheck at build time)
theme/                    tokens.nix (selects the active palette), palettes/ (catppuccin mocha/macchiato, everforest, gruvbox), wallpapers.nix (pinned collections)
pi/                       pi assets: extensions (TS), skills, brain, themes, pinned packages
pkgs/                     packages missing from nixpkgs
patches/                  patches applied to third-party code
dev/                      devenv fragments and project templates
```

`flake.nix` passes two special arguments to every module: `inputs` (all flake inputs) and `user` (the account name). Paths under the user's home are derived from `config.users.users.${user}.home`, never hard-coded.

## Nix

- **Unstable packages** come from one overlay in `modules/nix.nix`. It uses `import nixpkgs-unstable { config = prev.config; }` rather than `legacyPackages`, because `legacyPackages` carries nixpkgs' default config and refuses unfree packages such as `claude-code`.
- **`nix flake check`** runs `Hyprland --verify-config` on the installed Lua files plus the seeded `dms/*.lua` defaults.
- **Formatting** is `nix fmt` (treefmt with nixfmt, Biome and shfmt).
- **Rebuilds and GC** go through `nh` (`nh os switch`, flake path preset). Its weekly `nh clean` replaces `nix.gc`: it also removes stale `result`/direnv GC roots and always keeps the last 5 generations, so a quiet week never deletes every rollback.
- **Ad-hoc tools** come from `nix-index-database` (prebuilt weekly index, no local `nix-index` run): `, <cmd>` runs a command from whichever package provides it, and fish's command-not-found names that package. Nothing is installed, unlike `nix profile`.

## Visual system

`theme/palettes/*.nix` are the only places colours are defined, and `theme/tokens.nix` picks the active one. Each palette exports the same shape: `accents` (red…purple, exposed as `tokens.palette`), `colors` (roles such as `background`, `accent-primary`, `error`, plus the 16-slot ANSI list), and `apps` (GTK theme, icon colourway, cursor, Neovim colorscheme, pi theme, wallpaper set). Everything themed derives from it: Hyprland borders, Ghostty, fuzzel, swaylock, fish, starship, the Claude Code status line, Spotify (spicetify), Sioyek, GTK/icons/cursor, Neovim, pi, SDDM, and the Dux Shell theme JSON. bat and delta use the `base16` theme, so they follow the terminal palette instead of naming a theme.

Apps whose theme is a user choice (Zed, VS Code, browsers) only get the theme made available, never selected btop is the middle case: it rewrites `btop.conf` from its own menu, so the repo owns only `btop/themes/kiln.theme` (generated from the palette) and seeds `btop.conf` once with `color_theme = "kiln"`. Picking another theme in btop sticks; staying on `kiln` follows palette switches. zathura and fzf have no theme picker, so their colours are owned outright.

Blur is decorative: Hyprland's default decoration blur shows through Ghostty's `background-opacity`, and Dux Shell manages blur for its own surfaces.

## Desktop session

Hyprland with Dux Shell; why, and what came before, is in [`docs/decisions/hyprland-dms.md`](docs/decisions/hyprland-dms.md).

- **Hyprland config** (`modules/hyprland/`) is Dux's stock Lua config from the packaged release, so it always matches the installed shell. `hyprland.lua` gets one appended `require("user")`, and `dms/binds.lua` gets Ghostty as the terminal. Everything personal is in `user.lua` (layout cycling, scrolling-column keys). Alt+Tab belongs to hyprshell (`home/desktop.nix`), run with only its switcher enabled because Dux Shell already provides the overview, launcher and clipboard.
- **Seeded fragments.** Dux's Settings UI rewrites `dms/{colors,outputs,cursor,layout,input,windowrules,binds-user}.lua`, so activation copies them from `hypr/dms-defaults/` and keeps a copy in `dms/.seeded/`. A fragment that still matches its seeded copy follows the repo default (so a palette change repaints the borders); one edited in the UI is left alone. Delete it to reseed.
- **Dux Shell** (`modules/dms-shell.nix`) rewrites its own `settings.json`, so the repo owns only the theme file (`dms/themes/kiln.json`) and seeds settings on a fresh install; if the selected custom theme file no longer exists, activation repoints it to `kiln.json`. `DMS_DISABLE_MATUGEN=1` stops it re-colouring from the wallpaper, and the AiOverviewControl plugin is patched on every activation.
- **Wallpapers** (`theme/wallpapers.nix`) are named collections fetched by hash (orangci/walls-catppuccin-mocha, Apeiros-46B/everforest-walls, AngelJumbo/gruvbox-wallpapers) into `~/Pictures/Wallpapers/<set>`. The wallpaper itself is picked in the Dux Shell UI.

## Pi

The agent is configured in `modules/pi/default.nix` through pi.nix's `programs.pi.coding-agent`.

- **Virtual `auto` model.** `pi/extensions/jev-router.ts` registers `opencode-go/auto`. It sits under the `opencode-go` provider because pi resolves credentials by provider. Anything that builds its own resource loader must load the router explicitly:
  - subagents run without ambient extensions, so `subagents.defaultSubagentOnlyExtensions` lists the router and `pi-web-access`;
  - pi-btw reads `~/.pi/agent/btw.json`, which lists the router;
  - pi-web-access cannot stream a virtual model, so `web-search.json` pins a concrete one.
- **Subagents** inherit project context, global context and skills explicitly (pi-subagents omits them by default). `deepseek-*` models are avoided for tool-driven roles because they emit tool calls as text.
- **pi-lens** would otherwise install language servers imperatively; `PI_LENS_DISABLE_*_INSTALL` stops that, and servers come from devenv shells.
- **Company skills** stay outside the repo and are passed with `--skill` paths.

### Permissions (`modules/pi/guard.nix`)

pi-guard matches tool names exactly and takes the **last** matching rule; settings are serialised sorted, so `*` (bash) and `**` (paths) act as catch-alls. A tool with no rule falls through to `ask`, which **blocks** headless runs (subagents, `pi -p`). The rule set is therefore complete: every tool any extension or MCP server registers is listed. When adding an extension or MCP server, add its tools (`/guard list` shows the effective policy; MCP direct tools are named `<server>_<tool>`).

- Bash rules match the command name exactly and glob the remaining tokens, so database clients are listed by name (`psql *DROP*`). `dd` is denied outright because no glob reliably matches its `of=` path.
- Path rules use `**`, not `*`: a single `*` does not cross `/`.
- Reads are deliberately unrestricted; writes and edits are blocked for keys, `.env` files and `secrets/`.
- `ast_grep_replace` writes through an array parameter that path rules cannot see.
- Slack posting is allowed without a prompt; deleting a Slack message asks.

### MCP (`modules/pi/mcp.nix`)

pi-mcp-adapter replaces pi's built-in MCP (`-builtin:mcp`) and reads `~/.pi/agent/mcp.json`. Disable a server globally with `enabled = false;` in its entry, or per project with `/mcp-adapter disable <name>`.

- **Slack** uses korotovsky/slack-mcp-server with a user session (xoxc/xoxd) or app token, read at start-up from gitignored files in `secrets/` by `modules/pi/slack-mcp.sh`, so no credential reaches the Nix store. Caches are pinned to `~/.cache/slack-mcp`; they are what resolve `#channel` and `@user_dm`, so never run with `-no-cache`. Write tools are registered only when named in `--enabled-tools`, and posting additionally needs `SLACK_MCP_ADD_MESSAGE_TOOL`. See [`docs/slack.md`](docs/slack.md).
- **Bruno** runs real requests from the pinned workspaces; treat its output as live traffic.
- **VeriDB** is built in `~/Projects/veridb`; its credentials stay in that project's `.env`.

## Scripts

`home/scripts/*.sh` become commands via `writeShellApplication`. `vpn-toggle` deliberately leaves `systemctl` to the system `PATH`: the passwordless sudo rules in `modules/vpn.nix` match `/run/current-system/sw/bin/systemctl` exactly.

- `get-sts` keeps the source profile (long-term IAM key) and the target profile (session credentials) separate; writing session credentials into the source profile destroys its key.
- `figma-session-import` copies Chrome's Figma cookies into figma-linux, whose own browser login stores an incomplete set. See [`docs/figma.md`](docs/figma.md).

## Known caveats

- `modules/vpn.nix` checks for tunnel configs in `secrets/` with `builtins.pathExists`. Flakes only see Git-tracked files, and `secrets/` is gitignored, so those units are never generated from a Git checkout. NetworkManager imports (which `vpn-toggle` prefers) are unaffected. A working declarative route needs a secret manager such as sops-nix or agenix, which would also keep the config out of the world-readable store.
- The gh credential helper is configured as `!gh auth git-credential` (resolved from `PATH`) rather than through Home Manager's option, which pins a store path that breaks once that gh is garbage-collected.
