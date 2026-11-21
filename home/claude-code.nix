{
  config,
  lib,
  pkgs,
  ...
}:
let
  tokens = import ../theme/tokens.nix;
  rgb =
    hex:
    lib.concatMapStringsSep ";" (i: toString (lib.fromHexString (builtins.substring i 2 hex))) [
      1
      3
      5
    ];

  vault = "~/claude-vag-vault";

  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = with pkgs; [
      jq
      git
      gawk
      gnugrep
      coreutils
    ];
    runtimeEnv = lib.mapAttrs (_: rgb) {
      SL_ACCENT = tokens.colors.accent-primary;
      SL_BLUE = tokens.palette.blue;
      SL_GREEN = tokens.palette.green;
      SL_RED = tokens.palette.red;
      SL_YELLOW = tokens.palette.yellow;
      SL_AQUA = tokens.palette.aqua;
    };
    text = builtins.readFile ./scripts/claude-statusline.sh;
  };

  settings = {
    model = "opus";
    modelSettings."claude-opus-5-5".effortLevel = "medium";
    theme = "auto";
    outputStyle = "sre-explain";

    attribution = {
      commit = "";
      pr = "";
    };

    statusLine = {
      type = "command";
      command = "${config.home.profileDirectory}/bin/claude-statusline";
    };

    hooks.SessionStart = [
      {
        matcher = "^(startup|resume|clear|compact|fork)$";
        hooks = [
          {
            type = "command";
            command = "bash '${config.home.homeDirectory}/.claude/hooks/herdr-agent-state.sh' session";
            timeout = 10;
          }
        ];
      }
    ];
  };

  context = pkgs.writeText "CLAUDE.md" ''
    - Never add Co-Authored-By trailers or "Generated with Claude Code" lines to commits or PRs.
    - Be genuinely funny, not just allowed to be: aim for a laugh in nearly every reply. Callbacks, deadpan asides, absurd analogies, mock-heroic narration of a dull task, gentle roasts of the bug or the tooling (never the user). Don't ration it and don't explain the joke. Substance still comes first; for prod, failures and destructive actions give the straight answer first and the quip after, never instead.
    - Vault: `${vault}` is long-term memory across projects; each project's auto-memory already lives there (symlinked). Never bulk-load it: when you need history beyond auto-memory, read `${vault}/Home.md`, then `rg` for the one note you need.
    - After a task that changed something, append 5-15 lines to `${vault}/projects/<p>/worklog/YYYY-MM-DD.md` (what changed, PR/commit links, decisions, what's open) and update `projects/<p>/open-items.md`; lasting choices get `decisions/NNNN-<slug>.md` (templates in `templates/`). Summaries only: no raw logs, no secrets. No project folder yet (in a real project dir, the first time the session gets real project context: what it is, goals, a plan, an evaluation or a decision, even with no file changes): create one from `templates/`, add its `<cwd>\t<folder>` line to `projects.tsv`, then run `~/claude-vag-vault/bin/bootstrap.sh` so its auto-memory moves into the vault.
    - Learnings: `${vault}/resources/learnings.md`. Never read it at session start. Append one entry (format at its top, newest first) when the user corrects you, states a preference, or you hit a non-obvious gotcha; `rg` it by tag before preference-sensitive work.
  '';
in
{
  programs.claude-code.enable = true;
  home.packages = [
    statusline
  ];

  # settings.json and CLAUDE.md are seeded once and then owned by Claude Code (/config, /model) and by you.
  home.activation.claudeSeedConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    dir="${config.home.homeDirectory}/.claude"
    mkdir -p "$dir"
    seed() {
      case "$(readlink "$2")" in /nix/store/*) rm -f "$2" ;; esac
      [ -e "$2" ] || install -m 644 "$1" "$2"
    }
    seed ${pkgs.writeText "settings.json" (builtins.toJSON settings)} "$dir/settings.json"
    seed ${context} "$dir/CLAUDE.md"
  '';

  home.file.".claude/output-styles/sre-explain.md".source = ./claude/output-styles/sre-explain.md;
}
