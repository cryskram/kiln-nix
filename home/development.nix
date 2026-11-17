{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    herdr

    tree
    file
    which
    less
    unzip
    zip
    wget
    curl
    openssl
    httpie
    netcat
    dig
    traceroute
    iproute2
    tcpdump
    nmap

    go
    gopls
    delve
    golangci-lint
    gotools

    jdk
    maven
    gradle
    kotlin
    kotlin-language-server

    nodejs
    pnpm
    yarn
    typescript
    eslint
    prettier

    python3
    python3Packages.pip
    python3Packages.virtualenv
    uv
    ruff
    black
    mypy
    pyright

    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt

    flutter

    # gcc and clang both ship bin/c++; gcc wins.
    (lib.hiPrio gcc)
    (lib.lowPrio clang)
    gdb
    lldb
    cmake
    ninja
    pkg-config
    clang-tools
    gnumake

    postgresql
    redis
    sqlite
    mysql84
    mongosh
  ];
}
