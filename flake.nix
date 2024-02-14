# `nix develop github:sentinelvote/monorepo/main#default`

{
  description = "github.com/SentinelVote/monorepo";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { config, self', pkgs, lib, system, ... }:
        let
          fablo = pkgs.stdenv.mkDerivation {
            name = "fablo";
            src = pkgs.fetchurl {
              url =
                "https://github.com/hyperledger-labs/fablo/releases/download/1.2.0/fablo.sh";
              sha256 =
                "edc2232b9d92d9739da0f25b48e8ce0023832fa2a5d7e638d04a1d40a894661f";
            };
            phases = [ "installPhase" "patchPhase" ];
            installPhase = ''
              mkdir -p $out/bin
              cp $src $out/bin/fablo
              chmod +x $out/bin/fablo
            '';
          };

          # We are emulating `go get github.com/zbohm/lirisi`.
          lirisi = pkgs.buildGoModule rec {
            pname = "lirisi";
            version = "0.0.1";
            doCheck = false;

            # nix-shell -p nurl --command 'nurl https://github.com/zbohm/lirisi/ 2>/dev/null'
            src = pkgs.fetchFromGitHub {
              owner = "zbohm";
              repo = "lirisi";
              rev = "07d6e5fe96f8503b742a5a0a142cf31e701f4921";
              sha256 = "sha256-HhEJem+AdA/4FoeteVSGp+1RXwYsjsinS0BgfmV9u7k=";
            };

            vendorHash = "sha256-UEx/ZBKEex5gVX+jC5EQlgkASyqGrgSM2cju52b1oi0=";
            # `|| true` skips further checks because `go mod tidy` is enough to produce vendorHash.
            # Ideally, lirisi repository should include go.sum to mitigate this issue, then we can remove preBuild.
            preBuild = ''
              go mod tidy || true
            '';
          };

        in {
          _module.args.pkgs = import inputs.nixpkgs { inherit system; };
          devShells.default = pkgs.mkShell {
            name = "sentinelvote";
            packages = [
              pkgs.git
              pkgs.tmux
              # frontend
              pkgs.nodejs_18
              # backend
              pkgs.go_1_21
              pkgs.go-tools # staticcheck
              pkgs.gotools # godoc, etc.
              # blockchain
              pkgs.curl
              pkgs.jq
              fablo
              lirisi
            ];
            hardeningDisable = [ "fortify" ];
            shellHook = ''
              if [ -z "$sv" ]; then
                export sv="$(pwd)"
                alias sv="cd $sv"
              fi
              source ${pkgs.git}/share/git/contrib/completion/git-prompt.sh
              export PS1='\w\[\033[0;36m\]$(__git_ps1 " %s")\[\033[0m\] % '
            '';
          };
        };
    };
}
