{ lib, pkgs, ... }:
let
  imageTypes = map (type: "image/${type}") [
    "png"
    "jpeg"
    "jpg"
    "webp"
    "gif"
    "bmp"
    "tiff"
    "svg+xml"
  ];
  imageViewer = lib.genAttrs imageTypes (_: "org.gnome.Loupe.desktop");
in
{
  programs.yazi = {
    enable = true;
    settings = {
      manager.show_hidden = true;
      preview.image_filter = "lanczos";
    };
  };

  home.packages = with pkgs; [
    nautilus
    file-roller
    loupe
  ];

  xdg.mimeApps = {
    enable = true;
    associations.added = imageViewer;
    defaultApplications = imageViewer;
  };
}
