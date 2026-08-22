{configRoot}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.pgvim;
  package = import ./package.nix {
    inherit pkgs configRoot;
    inherit (cfg) extraLuaConfig extraRuntimePaths;
  };
in {
  options.programs.pgvim = {
    extraRuntimePaths = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "Neovim runtime trees loaded before the distribution.";
    };

    extraLuaConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Lua evaluated before the distribution; it may return extension hooks.";
    };
  };

  config = {
    home.packages = [package];
    home.sessionVariables = {
      EDITOR = lib.mkDefault "nvim";
      VISUAL = lib.mkDefault "nvim";
    };
  };
}
