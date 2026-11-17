# SSH client config.
#
# The herdr agent holds ~7 identities. sshd allows MaxAuthTries (6) public-key
# attempts, so an unqualified `ssh` offers keys until the server hangs up with
# "Too many authentication failures" — before it ever reaches the one that
# works. Per-host `IdentitiesOnly` pins both the key and the attempt count.
{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      # Phoenix dev VMs — identity is the VM login from ~/.config/phoenix/config.yaml.
      "*.phoenix.sustvest.in" = {
        User = "vageesh";
        IdentityFile = "~/.ssh/id_rsa_vageesh";
        IdentitiesOnly = true;
      };
    };
  };
}
