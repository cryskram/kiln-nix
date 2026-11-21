{
  config,
  lib,
  pkgs,
  ...
}:
let
  vault = "${config.home.homeDirectory}/claude-vag-vault";
  tools = with pkgs; [
    bash
    git
    gitleaks
    gh
    coreutils
    gnused
  ];

  sync = pkgs.writeShellApplication {
    name = "vault-sync";
    runtimeInputs = tools;
    text = ''exec ${vault}/bin/sync.sh "$@"'';
  };
in
{
  home.packages = [
    pkgs.gitleaks
    sync
  ];

  # The vault owns the project→memory map (projects.tsv) so non-nix devices run the same script.
  home.activation.vaultBootstrap = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -x "${vault}/bin/bootstrap.sh" ]; then
      PATH="${lib.makeBinPath tools}:$PATH" run "${vault}/bin/bootstrap.sh"
    fi
  '';

  systemd.user.services.vault-sync = {
    Unit.Description = "Commit, pull and push ~/claude-vag-vault";
    Service = {
      Type = "oneshot";
      ExecStart = "${sync}/bin/vault-sync";
    };
  };

  systemd.user.timers.vault-sync = {
    Unit.Description = "Sync ~/claude-vag-vault every 15 minutes";
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "15m";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
