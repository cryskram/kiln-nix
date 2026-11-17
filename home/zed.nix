# Themes are only made available here; the active one is chosen in Zed's own settings.json, which stays user-owned.
{ pkgs, ... }:
{
  home.packages = [ pkgs.zed-editor ];

  xdg.configFile."zed/themes/everforest.json".source = pkgs.fetchurl {
    name = "zed-everforest.json";
    url = "https://raw.githubusercontent.com/albertsko/zed-everforest/7d313cfe719a7b39e7cd273d5d92dd7f4f1cbb97/themes/everforest-regular.json";
    hash = "sha256-1eNsUsarBGMZ8RIcyowOqPfaMQJ/4AZ9vAciQfXsnbU=";
  };
}
