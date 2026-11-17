# pi-guard takes the last matching rule and settings serialise sorted, so "*"/"**" act as catch-alls.
# Unlisted tools fall through to "ask", which blocks headless runs: every tool must be listed.
let
  rulesFor = value: names: builtins.listToAttrs (map (name: { inherit name value; }) names);
  allow = rulesFor "allow";
  deny = rulesFor "deny";
  ask = rulesFor "ask";

  protectedPaths = {
    "**" = "allow";
    "**/.ssh/**" = "deny";
    "**/.gnupg/**" = "deny";
    "**/.aws/**" = "deny";
    "**/secrets/**" = "deny";
    "**/.env" = "deny";
    "**/*.env" = "deny";
    "**/*.env.*" = "deny";
    "**/*.pem" = "deny";
    "**/*.key" = "deny";
    "**/id_*" = "deny";
    "**/.pi/agent/auth.json" = "deny";
  };
in
{
  enabled = true;
  rules = {
    bash = {
      "*" = "allow";
    }
    // deny [
      "dd"
      "mkfs"
      "mkfs.ext2"
      "mkfs.ext3"
      "mkfs.ext4"
      "mkfs.xfs"
      "mkfs.btrfs"
      "mkfs.fat"
      "mkfs.vfat"
      "dropdb"
      "dropuser"
      "psql *DROP*"
      "psql *TRUNCATE*"
      "mariadb *DROP*"
      "mysql *DROP*"
      "sqlite3 *DROP*"
      "redis-cli *FLUSH*"
    ]
    // ask [
      "rm -r*"
      "rm -R*"
      "rm -fr*"
      "rm -fR*"
      "rm --recursive*"
      "git reset --hard"
      "git clean -f*"
      "git push -f"
      "git push --force"
      "chmod 777*"
      "docker system prune*"
      "docker volume prune*"
      "docker volume rm*"
      "docker rm -f*"
      "kubectl delete*"
      "terraform destroy*"
      "terraform apply -auto-approve*"
      "reboot"
      "poweroff"
      "halt"
      "shutdown"
      "systemctl reboot"
      "systemctl poweroff"
      "systemctl halt"
    ];

    read = "allow";
    write = protectedPaths;
    edit = protectedPaths;

    slack_delete_message = "ask";
  }
  // allow [
    "ask_user_question"
    "bg_wait"
    "codemode"
    "contact_supervisor"
    "fetch_content"
    "find"
    "get_search_content"
    "grep"
    "ls"
    "powershell"
    "source_check"
    "subagent"
    "subagent_supervisor"
    "subagents_enable"
    "todo"
    "tool_search"
    "web_enable"
    "web_search"
    "mcp"

    "veridb_describe_table"
    "veridb_explain_query"
    "veridb_list_databases"
    "veridb_list_schemas"
    "veridb_list_tables"
    "veridb_query"
    "veridb_sample_rows"
    "veridb_search_columns"
    "veridb_status"

    "lens_diagnostics"
    "module_report"
    "project_report"
    "effective_config"
    "read_symbol"
    "read_enclosing"
    "symbol_search"
    "pi_lens_activate_tools"
    "ast_grep_search"
    "ast_grep_outline"
    "ast_grep_replace"
    "lsp_navigation"
    "lens_diagnostic_mark"

    "bruno_list_collections"
    "bruno_list_requests"
    "bruno_get_request"
    "bruno_execute_request"
    "bruno_run_collection"
    "bruno_list_environments"
    "bruno_get_environment"

    "slack_channels_list"
    "slack_conversations_history"
    "slack_conversations_replies"
    "slack_conversations_search_messages"
    "slack_users_search"
    "slack_conversations_add_message"
    "slack_edit_message"

    "google_accounts"
    "google_api"
    "google_docs_create"
    "google_docs_read"
    "google_docs_write"
    "google_drive_export"
    "google_drive_read"
    "google_drive_search"
    "google_drive_write"
    "google_sheets_batch"
    "google_sheets_create"
    "google_sheets_read"
    "google_sheets_write"
  ];
}
