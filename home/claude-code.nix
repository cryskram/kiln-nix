{ pkgs, ... }:
let
  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = with pkgs; [
      jq
      git
      gawk
      gnugrep
      coreutils
    ];
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
    '';
  };
}
