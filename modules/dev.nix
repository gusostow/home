{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # cloud
    awscli2
    nodePackages.aws-cdk
    cargo-lambda
    docker
    flyctl
    s5cmd
    terraform

    # build tools & compilers
    cmake
    gcc
    hyperfine
    libllvm
    protobuf

    # languages & runtimes
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

    # databases
    postgresql
    sqlite

    # dev utilities
    nixfmt-rfc-style
    pandoc
    platformio
    pstree
    tldr
    uv
  ];

  # Laptop-specific zsh configuration
  programs.zsh = {
    initContent = ''
      export PATH=$PATH:~/.npm-global/bin
    '';
    sessionVariables = {
      PYTHONBREAKPOINT = "ipdb.set_trace";
      RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    };
  };
}
