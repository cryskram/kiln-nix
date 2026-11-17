# Architecture

How the repository is put together, and the non-obvious reasons behind it. Code comments are kept to a minimum; the *why* lives here and in [`docs/decisions/`](docs/decisions/).

## Layout

```
flake.nix                 inputs, formatter (treefmt), niri config check, the `nixos` system
configuration.nix         host: boot, locale, audio, printing, the user account
hardware-configuration.nix  generated — do not edit
modules/                  NixOS modules (imported by modules/default.nix)
  nix.nix                 nix settings, GC, nixpkgs-unstable overlay
  core.nix                Home Manager wiring, session variables, desktop services
  pi/                     pi coding agent: default.nix (agent), guard.nix (permissions), mcp.nix (MCP servers)
  desktop.nix             `desktop.shell` option: caelestia | dms
  caelestia/              Caelestia shell: package overrides, generated Gruvbox scheme, wallpapers
  dms-shell.nix           Dux Shell (DMS), the alternative shell
  niri, sddm, theme, shell, docker, ollama, direnv, vpn, tailscale, ssh, android
home/                     Home Manager modules (imported by home/default.nix)
  scripts/*.sh            user scripts, built with writeShellApplication (shellcheck at build time)
theme/tokens.nix          the visual system: raw Gruvbox palette + semantic roles
pi/                       pi assets: extensions (TS), skills, brain, themes, pinned packages
pkgs/                     packages missing from nixpkgs
patches/                  patches applied to third-party code
dev/                      devenv fragments and project templates
```

`flake.nix` passes two special arguments to every module: `inputs` (all flake inputs) and `user` (the account name). Paths under the user's home are derived from `config.users.users.${user}.home`, never hard-coded.

## Nix

- **Unstable packages** come from one overlay in `modules/nix.nix`. It uses `import nixpkgs-unstable { config = prev.config; }` rather than `legacyPackages`, because `legacyPackages` carries nixpkgs' default config and refuses unfree packages such as `claude-code`.
- **`nix flake check`** runs `niri validate` on the generated `config.kdl`, since Home Manager 26.05 has no niri module to type-check it.
- **Formatting** is `nix fmt` (treefmt with nixfmt, Biome and shfmt).

## Visual system

`theme/tokens.nix` is the only place colours are defined. `palette` holds raw Gruvbox Dark values; `colors` maps them to roles (`background`, `accent-primary`, `error`, …). Everything themed derives from it: niri borders, Ghostty, fuzzel, swaylock, fish, starship, Spotify (spicetify), Sioyek, the SDDM cursor, the Caelestia scheme (`modules/caelestia/scheme.nix`) and the DMS theme JSON.

Blur is decorative. niri blurs every window and popup; Ghostty cannot request blur under niri, so its translucency (`background-opacity`) relies on niri's window rule. DMS requests blur for its own surfaces through `ext-background-effect`, so only the fuzzel fallback launcher has a layer rule; adding one for DMS double-applies and draws a tinted box around rounded popouts.

## Desktop shell

`desktop.shell` (`modules/desktop.nix`) selects the shell: `caelestia` (default) or `dms`. Each shell module is wrapped in `mkIf`, and `home/niri.nix` picks the matching keybinds, so exactly one shell, idle manager and bind set is active.

**Caelestia** (`modules/caelestia/`) comes from a niri-capable fork; why that fork, and the trade-offs, are in [`docs/decisions/caelestia.md`](docs/decisions/caelestia.md). Its bundled Gruvbox scheme is wrong, so `scheme.nix` generates one from the tokens and the CLI package is overridden to ship it. Caelestia owns its state under `~/.local/state/caelestia`; activation seeds the scheme and wallpaper only on first run. The CLI's theme appliers are disabled because they would rewrite files Home Manager owns. Wallpapers are fetched by hash from AngelJumbo/gruvbox-wallpapers and linked file-by-file, because the wallpaper scanner does not follow symlinked directories.

**Dux Shell** (formerly DankMaterialShell) rewrites its own `settings.json`, so the repo owns only its theme file. `DMS_DISABLE_MATUGEN=1` stops it regenerating colours from the wallpaper, and the AiOverviewControl plugin is patched on every activation.

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
