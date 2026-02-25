{
  description = "Agda Language Server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        hpkgs = pkgs.haskellPackages;
        hlib = pkgs.haskell.lib;

        als =
          hlib.overrideCabal
            (hlib.addExtraLibraries
              (hlib.doJailbreak (hpkgs.callCabal2nix "agda-language-server" ./. { }))
              [ pkgs.gmp pkgs.ncurses pkgs.zlib ])
            (_: {
              doCheck = false;
            });

        alsChecks = hlib.overrideCabal als (drv: {
          doCheck = true;
          preCheck = (drv.preCheck or "") + ''
            als_bin="$(find dist -type f -name als -perm -0100 | head -n1)"
            if [ -z "$als_bin" ]; then
              echo "Could not find built als executable under dist/" >&2
              exit 1
            fi
            export PATH="$(dirname "$als_bin"):$PATH"
          '';
        });
      in
      {
        packages = {
          als = als;
          default = als;
        };

        apps = {
          als = flake-utils.lib.mkApp { drv = als; exePath = "/bin/als"; };
          default = flake-utils.lib.mkApp { drv = als; exePath = "/bin/als"; };
        };

        checks = {
          als-tests = alsChecks;
          default = alsChecks;
        };

        devShells = {
          default = hpkgs.shellFor {
            packages = p: [ als ];
            buildInputs = [
              pkgs.cabal-install
              pkgs.ghcid
              pkgs.haskell-language-server
              pkgs.pkg-config
              pkgs.gmp
              pkgs.ncurses
              pkgs.zlib
            ];
          };
        };
      });
}
