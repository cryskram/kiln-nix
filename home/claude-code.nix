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
in
{
  # settings.json and CLAUDE.md become read-only store links; change them here, not via /config.
  programs.claude-code = {
    enable = true;

    settings = {
      model = "opus";
      modelSettings."claude-opus-5-5".effortLevel = "medium";
      theme = "auto";

      attribution = {
        commit = "";
        pr = "";
      };

      statusLine = {
        type = "command";
        command = "${statusline}/bin/claude-statusline";
      };

      # herdr owns the script (it rewrites it on update); only the registration lives here.
      hooks.SessionStart = [
        {
          matcher = "^(startup|resume|clear|compact|fork)$";
          hooks = [
            {
              type = "command";
              command = "bash '/home/vageesh/.claude/hooks/herdr-agent-state.sh' session";
              timeout = 10;
            }
          ];
        }
      ];
    };

    context = ''
      - Never add Co-Authored-By trailers or "Generated with Claude Code" lines to commits or PRs.
      - Journal: use the `learnings` skill (${learnings}/LEARNINGS.md). Read it at session start; append one entry per its SKILL.md whenever the user corrects you, states a preference, or you hit a non-obvious gotcha.
      - Have a sense of humor: dry, quick, well-timed. A good line beats a forced one, and jokes never replace substance or bury bad news.
    '';
  };

  # Live link, not a store copy: LEARNINGS.md is append-only and shared with pi.
  home.file.".claude/skills/learnings".source = config.lib.file.mkOutOfStoreSymlink learnings;
}
