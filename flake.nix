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

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nixos-shell
            pkgs.overmind
            pkgs.tmux
            # frontend
            pkgs.nodejs_18
            # backend
            pkgs.go_1_21
            pkgs.go-tools # staticcheck
            pkgs.gotools  # godoc, etc.
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
              alias fe="cd $sv/frontend"
              alias be="cd $sv/backend"
              alias fabric="cd $sv/blockchain"
              alias up="cd $sv && overmind start"
              alias upsplit="cd $sv && tmux new-session -d -s mySession 'cd frontend && npm run dev' \; split-window -v 'cd backend && go run .' \; split-window -h 'cd blockchain && fablo recreate && htop -t' \; select-layout even-horizontal \; attach"
            fi
            export PS1="\[\033[1;32m\][\w]\$\[\033[0m\] "
          '';
        };
      }
    );
}
