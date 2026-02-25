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

        als = hpkgs.overrideCabal
          (hpkgs.callCabal2nix "agda-language-server" ./. { })
          (drv: {
            buildInputs = (drv.buildInputs or [ ]) ++ [
              pkgs.gmp
              pkgs.ncurses
              pkgs.zlib
            ];
          });

        alsChecks = hpkgs.overrideCabal als (drv: {
          doCheck = true;
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
