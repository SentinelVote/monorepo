let
  # https://github.com/emscripten-core/emscripten/issues/18013#issuecomment-1275222500
  v1-38-28-asm-js-support = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/df2176f7f3f748974f24916df29bb70763d89734.tar.gz") {};
  # https://github.com/emscripten-core/emscripten/blob/bd050e64bb0d9952df1344b8ea9356252328ad83/ChangeLog.markdown#v1381-05172018
  v1-37-36-asm-js-support = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/25b53f32236b308172673c958f570b5b488c7b73.tar.gz") {};
in
{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      # https://search.nixos.org/packages
      ###########################################
      # Comment/Uncomment as needed.
      # emscripten
      # nodejs_20
      # nodejs_18
      ###########################################
      clang
      curl
      direnv
      emacs
      ezno
      gcc
      gdb
      go
      hyperledger-fabric
      jq
      nixos-shell
      quickjs
      swc
      tinygo
      wasmer
      wasmtime
      zig
  ] ++ [
  # v1-38-28-asm-js-support.emscripten
  # v1-37-36-asm-js-support.emscripten
  ];
  # https://nixos.org/manual/nix/stable/command-ref/nix-shell#description
  shellHook = ''
    if [ -z "$monorepo" ]; then
      export monorepo="$(pwd)"
      alias fyp="cd $project_root"
      alias cdfe="cd $project_root/voterApp"
      alias cdbe="cd $project_root/fabricBlockchain"
      PS1="\[\033[1;32m\][nix-shell:\w]\$\[\033[0m\] "
    fi
    PS1="\[\033[1;32m\][nix-shell:\w]\$\[\033[0m\] "
  '';
}
