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

  learnings = "${config.home.homeDirectory}/kiln-nix/pi/skills/learnings";

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
    - Journal: use the `learnings` skill (${learnings}/LEARNINGS.md). Read it at session start; append one entry per its SKILL.md whenever the user corrects you, states a preference, or you hit a non-obvious gotcha.
    - Have a sense of humor: dry, quick, well-timed. A good line beats a forced one, and jokes never replace substance or bury bad news.
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

  # Live link, not a store copy: LEARNINGS.md is append-only and shared with pi.
  home.file.".claude/skills/learnings".source = config.lib.file.mkOutOfStoreSymlink learnings;

  home.file.".claude/output-styles/sre-explain.md".source = ./claude/output-styles/sre-explain.md;
}
