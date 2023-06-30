{
  description = "R playground";

  nixConfig = {
    extra-substituters = [ "https://tweag-jupyter.cachix.org" ];
    extra-trusted-public-keys = [ "tweag-jupyter.cachix.org-1:UtNH4Zs6hVUFpFBTLaA4ejYavPo5EFFqgd7G7FxGW9g=" ];
  };

  inputs = {
    parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/release-23.05";
    jupyenv.url = "github:fortuneteller2k/jupyenv";
  };

  outputs = { self, parts, nixpkgs, jupyenv, ... }@inputs: parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "x86_64-darwin" ];

    perSystem = { self', pkgs, system, ... }:
      let
        inherit (jupyenv.lib.${system}) mkJupyterlabNew;

        minimalMkShell = pkgs.mkShell.override {
          stdenv = pkgs.stdenvNoCC.override {
            cc = null;
            preHook = "";
            allowedRequisites = null;
            initialPath = [ pkgs.toybox ];
            shell = "${pkgs.bash}/bin/bash";
            extraNativeBuildInputs = [ ];
          };
        };

        rPackagesFrom = rp: __attrValues {
          inherit (rp)
            tidyverse
            easystats
            littler
            languageserver
            ggdark
            ggthemes
            svglite;
        };

        jupyterlab = mkJupyterlabNew ({ ... }: {
          inherit nixpkgs;

          imports = [{
            kernel.r.playground = {
              enable = true;
              extraRPackages = rPackagesFrom;
            };
          }];
        });
      in
      {
        packages = {
          inherit jupyterlab;
          default = jupyterlab;
        };

        apps.default = {
          program = "${jupyterlab}/bin/jupyter-lab";
          type = "app";
        };

        devShells.default = minimalMkShell {
          packages = [
            (pkgs.rWrapper.override { packages = rPackagesFrom pkgs.rPackages; })
          ];
        };
      };
  };
}
