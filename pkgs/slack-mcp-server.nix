{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
let
  version = "1.3.0";
in
buildGoModule {
  pname = "slack-mcp-server";
  inherit version;

  src = fetchFromGitHub {
    owner = "korotovsky";
    repo = "slack-mcp-server";
    tag = "v${version}";
    hash = "sha256-I4f6yKV0BXtaxnqi/XNID+Pwl2mWjSqxIHhb07U7sc4=";
  };

  vendorHash = "sha256-+uQRODO9oL8mGKBmdghTxE6R9Fz+3GJFVTi17306gT8=";

  subPackages = [ "cmd/slack-mcp-server" ];

  ldflags = [
    "-s"
    "-w"
    "-X"
    "github.com/korotovsky/slack-mcp-server/pkg/version.Version=v${version}"
    "-X"
    "github.com/korotovsky/slack-mcp-server/pkg/version.BinaryName=slack-mcp-server"
  ];

  # Upstream tests need a live Slack workspace.
  doCheck = false;

  meta = {
    description = "Slack MCP server — search, read and post Slack messages via an xoxp/xoxb token";
    homepage = "https://github.com/korotovsky/slack-mcp-server";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "slack-mcp-server";
  };
}
