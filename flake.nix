{
  description = "Pablo's portable Neovim distribution.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    systems = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = import ./nix/package.nix {
        inherit pkgs;
        configRoot = ./config;
      };
    });

    checks = forAllSystems (system:
      import ./nix/checks.nix {
        pkgs = nixpkgs.legacyPackages.${system};
        configRoot = ./config;
      });

    homeManagerModules.default = import ./nix/home-manager.nix {
      configRoot = ./config;
    };
  };
}
