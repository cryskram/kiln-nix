{
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    loadModels = [ "qwen2.5:3b" ];
  };

  # Docker bridges change name when networks are recreated, so allow the whole Docker range (iptables backend).
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 172.16.0.0/12 --dport 11434 -j nixos-fw-accept
  '';
}
