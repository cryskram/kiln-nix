{ user, ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    # --ssh makes tailscaled answer tailnet SSH itself, so tailnet logins follow tailnet ACLs rather than sshd keys.
    extraSetFlags = [
      "--operator=${user}"
      "--ssh"
    ];
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
