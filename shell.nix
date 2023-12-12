{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      # https://search.nixos.org/packages
      ###########################################
      # Comment/Uncomment as needed.
      # docker-compose
      # nodejs_20
      ###########################################
      nodejs_18
      curl
      ezno
      go
      hyperledger-fabric
      jq
      nixos-shell
      quickjs
      swc
      tinygo
  ];
  # https://nixos.org/manual/nix/stable/command-ref/nix-shell#description
  shellHook = ''
    if [ -z "$monorepo" ]; then
      export monorepo="$(pwd)"
      alias fyp="cd $project_root"
      alias cdfe="cd $project_root/voterApp"
      alias cdbe="cd $project_root/fabricBlockchain"
    fi
    PS1="\[\033[1;32m\][nix-shell:\w]\$\[\033[0m\] "
  '';
}
