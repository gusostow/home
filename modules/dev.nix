{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Cloud/DevOps
    awscli2
    nodePackages.aws-cdk
    cargo-lambda
    docker
    flyctl
    s5cmd
    terraform

    # Build tools & compilers
    cmake
    gcc
    libllvm
    protobuf

    # Languages & runtimes
    go
    gopls
    nodejs
    rustup
    zig
    (python3.withPackages (
      p: with p; [
        ipdb
        ipython
        numpy
        pandas
        pip
        requests
        rich
      ]
    ))

    # Databases
    postgresql
    sqlite

    # Dev utilities
    nixfmt-rfc-style
    pandoc
    platformio
    pstree
    tldr
    uv
  ];
}
