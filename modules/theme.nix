{ pkgs, ... }:
let
  inherit (import ../theme/tokens.nix) fonts;
in
{
  fonts = {
    packages = with pkgs; [
      inter
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      font-awesome
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ fonts.ui ];
      monospace = [ fonts.mono ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
