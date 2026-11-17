# Tunnel configs are optional gitignored files in secrets/; each one present becomes a manual-start unit.
{
  lib,
  pkgs,
  user,
  ...
}:
let
  firstExisting =
    names: lib.findFirst builtins.pathExists null (map (name: ../secrets + "/${name}") names);

  wireguard = lib.filterAttrs (_: file: file != null) {
    wg0 = firstExisting [
      "wg0.conf"
      "company-wg.conf"
    ];
    proton = firstExisting [
      "proton.conf"
      "proton-wg.conf"
    ];
  };

  openvpnConfig = firstExisting [
    "vpn.ovpn"
    "company.ovpn"
  ];

  passwordless =
    command:
    map (args: {
      command = "/run/current-system/sw/bin/${command} ${args}";
      options = [ "NOPASSWD" ];
    });
in
{
  networking.wg-quick.interfaces = lib.mapAttrs (_: configFile: {
    inherit configFile;
    autostart = false;
  }) wireguard;

  services.openvpn.servers = lib.optionalAttrs (openvpnConfig != null) {
    company = {
      config = "config ${openvpnConfig}";
      autoStart = false;
    };
  };

  # vpn-toggle drives wg-quick through sudo without a password prompt.
  security.sudo.extraRules = [
    {
      users = [ user ];
      commands =
        lib.concatMap
          (
            iface:
            passwordless "systemctl" [
              "start wg-quick-${iface}"
              "stop wg-quick-${iface}"
              "restart wg-quick-${iface}"
            ]
            ++ passwordless "wg-quick" [
              "up ${iface}"
              "down ${iface}"
            ]
          )
          [
            "wg0"
            "proton"
          ];
    }
  ];

  environment.systemPackages = with pkgs; [
    wireguard-tools
    openvpn
    networkmanager-openvpn
    proton-vpn
  ];
}
