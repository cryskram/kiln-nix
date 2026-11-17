{
  config,
  pkgs,
  user,
  ...
}:
let
  home = config.users.users.${user}.home;
  brunoMcp = pkgs.callPackage ../../pkgs/bruno-mcp.nix { };

  slackMcp = pkgs.writeShellApplication {
    name = "slack-mcp";
    runtimeInputs = [
      pkgs.coreutils
      (pkgs.callPackage ../../pkgs/slack-mcp-server.nix { })
    ];
    text = builtins.readFile ./slack-mcp.sh;
  };
in
{
  home-manager.users.${user}.home.file.".pi/agent/mcp.json".text = builtins.toJSON {
    mcpServers = {
      veridb = {
        command = "${home}/Projects/veridb/bin/veridb";
        args = [
          "-config"
          "${home}/Projects/veridb/configs/veridb.local.yaml"
          "-env-file"
          "${home}/Projects/veridb/.env"
        ];
      };

      bruno = {
        command = "${pkgs.nodejs}/bin/node";
        args = [
          "${brunoMcp}/lib/node_modules/@usebruno/mcp/dist/index.js"
          "--workspace"
          "${home}/Documents/bruno/TAP"
          "--workspace"
          "${home}/Documents/bruno/PERSONAL"
        ];
      };

      # Write tools stay unregistered unless named here and enabled via SLACK_MCP_ADD_MESSAGE_TOOL.
      slack = {
        command = "${slackMcp}/bin/slack-mcp";
        args = [
          "--transport"
          "stdio"
          "--enabled-tools"
          (builtins.concatStringsSep "," [
            "channels_list"
            "conversations_history"
            "conversations_replies"
            "conversations_search_messages"
            "users_search"
            "conversations_add_message"
          ])
        ];
        env.SLACK_MCP_ADD_MESSAGE_TOOL = "true";
      };
    };
  };
}
