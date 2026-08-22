{
  pkgs,
  configRoot,
  extraLuaConfig ? "",
  extraRuntimePaths ? [],
}: let
  supercolliderPackage =
    if pkgs.stdenv.hostPlatform.isDarwin
    then pkgs.callPackage ./supercollider-darwin.nix {}
    else pkgs.supercollider;

  runtimePathConfig = pkgs.lib.concatMapStringsSep "\n" (path: ''
    vim.opt.runtimepath:prepend([[${path}]])
  '') (pkgs.lib.reverseList extraRuntimePaths);

  bootstrap = pkgs.writeText "pgvim-init.lua" ''
    ${runtimePathConfig}
    _G.pgvim_extension = (function()
      ${extraLuaConfig}
    end)()
    dofile([[${configRoot}/init.lua]])
  '';

  runtimeLibraries = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [pkgs.libiconv];

  dependencies =
    (with pkgs; [
      alejandra
      cargo
      curl
      delve
      docker-language-server
      dockerfile-language-server
      fd
      git
      gnumake
      gopls
      (haskellPackages.ghcWithPackages (packages: [packages.tidal]))
      jujutsu
      lua-language-server
      nil
      nodejs
      opencode
      pkg-config
      prettier
      pyrefly
      python3Packages.debugpy
      ripgrep
      ruff
      rumdl
      rust-analyzer
      rustc
      rustfmt
      stdenv.cc
      stylua
      terraform-ls
      tree-sitter
      unzip
      uv
      vscode-langservers-extracted
      yaml-language-server
    ])
    ++ [supercolliderPackage];
in
  pkgs.symlinkJoin {
    name = "pgvim";
    paths = [pkgs.neovim];
    nativeBuildInputs = [pkgs.makeWrapper];

    postBuild = ''
      wrapProgram "$out/bin/nvim" \
        --prefix PATH : "${pkgs.lib.makeBinPath dependencies}" \
        ${pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''--prefix LIBRARY_PATH : "${pkgs.lib.makeLibraryPath runtimeLibraries}" \''}
        --add-flags "-u ${bootstrap}"
      ln -s nvim "$out/bin/vi"
      ln -s nvim "$out/bin/vim"
    '';

    meta =
      pkgs.neovim.meta
      // {
        description = "Pablo's portable Neovim distribution";
        mainProgram = "nvim";
      };
  }
