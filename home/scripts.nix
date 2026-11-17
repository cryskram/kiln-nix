{ pkgs, ... }:
let
  script =
    name: runtimeInputs: extraText:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = extraText + builtins.readFile ./scripts/${name}.sh;
    };

  vpnCommon = builtins.readFile ./scripts/vpn-common.sh;
in
{
  # systemctl and nmcli come from the system PATH so sudo matches the NOPASSWD rules in modules/vpn.nix.
  home.packages = with pkgs; [
    (script "figma-session-import" [
      python3
      openssl
      libsecret
      procps
      coreutils
    ] "")
    (script "get-sts" [
      awscli2
      jq
      libnotify
    ] "")
    (script "vpn-toggle" [
      jq
      fuzzel
      libnotify
      procps
    ] vpnCommon)
    (script "vpn-status" [ jq ] vpnCommon)
  ];
}
