{
  description = "github.com/SentinelVote/monorepo";
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "flake-utils";
  };
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        fablo = pkgs.stdenv.mkDerivation {
          name = "fablo";
          src = pkgs.fetchurl {
            url = "https://github.com/hyperledger-labs/fablo/releases/download/1.2.0/fablo.sh";
            sha256 = "edc2232b9d92d9739da0f25b48e8ce0023832fa2a5d7e638d04a1d40a894661f";
          };
          phases = ["installPhase" "patchPhase"];
          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/fablo
            chmod +x $out/bin/fablo
          '';
        };

        # We are emulating `go get github.com/zbohm/lirisi` here.
        lirical = pkgs.buildGoModule rec {
          pname = "lirical";
          version = "0.0.1";

          # How I got this value:
          # nix-shell -p nurl
          # nurl https://github.com/zbohm/lirisi/ 0963fdab3e353be12f42e923101d0d15ab54c058 2>/dev/null
#          src = pkgs.fetchFromGitHub {
#            owner = "zbohm";
#            repo = "lirisi";
#            rev = "0963fdab3e353be12f42e923101d0d15ab54c058";
#            sha256 = "sha256-OfCKqkeSNgdde/F7xM6tM+PxTR/KxyWrnhZc4gL+boI=";
#          };
#          vendorHash = "sha256-JXfTQb7JNIIODxEAWQiSoo56eUVnyhI+ZOYGgK1mxXg=";

          # How I got this value:
          # nix-shell -p nurl
          # nurl https://github.com/zbohm/lirisi/ 2>/dev/null
          src = pkgs.fetchFromGitHub {
            owner = "zbohm";
            repo = "lirisi";
            rev = "07d6e5fe96f8503b742a5a0a142cf31e701f4921";
            hash = "sha256-HhEJem+AdA/4FoeteVSGp+1RXwYsjsinS0BgfmV9u7k=";
          };
          vendorHash = "sha256-UEx/ZBKEex5gVX+jC5EQlgkASyqGrgSM2cju52b1oi0=";

          doCheck = false;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.go-tools # staticcheck
            pkgs.go_1_21
            pkgs.gotools  # godoc, etc.
            pkgs.nodejs_18
            pkgs.curl
            pkgs.jq
            pkgs.nixos-shell
            fablo
            lirical
          ];
          hardeningDisable = [ "fortify" ];
          shellHook = ''
            if [ -z "$monorepo" ]; then
              export monorepo="$(pwd)"
              alias monorepo="cd $monorepo"
              alias frontend="cd $monorepo/frontend"
              alias backend="cd $monorepo/backend"
              alias blockchain="cd $monorepo/blockchain"
              alias run="bash -c 'set -m ; cd frontend && npm run dev & cd ../backend && go run . & fg %1'"
            fi
            PS1="\[\033[1;32m\][nix-shell:\w]\$\[\033[0m\] "
          '';
        };
      }
    );
}