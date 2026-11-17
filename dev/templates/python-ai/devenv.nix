# Python 3.12 for AI SDKs with prebuilt wheels; LD_LIBRARY_PATH lets wheels like opencv find libstdc++/libGL.
{ pkgs, lib, ... }:
{
  languages.python = {
    enable = true;
    package = pkgs.python312;
    uv.enable = true;
  };

  env.LD_LIBRARY_PATH = lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.libglvnd
    pkgs.glib
    pkgs.zlib
    pkgs.libx11
    pkgs.libxcb
    pkgs.libxext
    pkgs.libsm
    pkgs.libice
    pkgs.libxrender
    pkgs.freetype
    pkgs.fontconfig
    pkgs.libxfixes
    pkgs.libxrandr
    pkgs.libxi
  ];

  packages = with pkgs; [
    ffmpeg
    ruff
    black
    mypy
    pyright
  ];

  enterShell = ''
    echo "python-ai env: $(python -V) — pip install into .venv, not the shell"
  '';
}
