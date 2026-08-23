{
  pkgs,
  configRoot,
}: let
  lib = pkgs.lib;
  vimPlugins = pkgs.vimPlugins;
  packLock = builtins.fromJSON (builtins.readFile ../config/nvim-pack-lock.json);
  neojjSpec = packLock.plugins.neojj;

  neojj = pkgs.vimUtils.buildVimPlugin {
    pname = "neojj";
    version = neojjSpec.rev;
    src = pkgs.fetchzip {
      url = "${neojjSpec.src}/archive/${neojjSpec.rev}.tar.gz";
      hash = "sha256-tGAZsTkLb7ubrVuQqw1suRd6t3zSdGREaVMivUaAYYs=";
    };
    doCheck = false;
  };

  supermaven = pkgs.writeTextDir "lua/supermaven-nvim.lua" ''
    return {
      setup = function()
        vim.g.pgvim_smoke_supermaven_setup = true
      end,
    }
  '';

  vimTidal = pkgs.runCommand "vim-tidal-smoke-stub" {} ''
    mkdir -p "$out"
  '';

  pluginSources = {
    LuaSnip = vimPlugins.luasnip;
    "avante.nvim" = vimPlugins."avante-nvim";
    "baleia.nvim" = vimPlugins."baleia-nvim";
    "blink.cmp" = vimPlugins."blink-cmp";
    catppuccin = vimPlugins."catppuccin-nvim";
    "conform.nvim" = vimPlugins."conform-nvim";
    "diffview.nvim" = vimPlugins."diffview-nvim";
    "ecolog.nvim" = vimPlugins."ecolog-nvim";
    "fidget.nvim" = vimPlugins."fidget-nvim";
    "friendly-snippets" = vimPlugins."friendly-snippets";
    "gitsigns.nvim" = vimPlugins."gitsigns-nvim";
    "grug-far.nvim" = vimPlugins."grug-far-nvim";
    "guess-indent.nvim" = vimPlugins."guess-indent-nvim";
    "indent-blankline.nvim" = vimPlugins."indent-blankline-nvim";
    "lazydev.nvim" = vimPlugins."lazydev-nvim";
    "markview.nvim" = vimPlugins."markview-nvim";
    "mini.icons" = vimPlugins."mini-icons";
    "mini.nvim" = vimPlugins."mini-nvim";
    "neo-tree.nvim" = vimPlugins."neo-tree-nvim";
    neogit = vimPlugins.neogit;
    inherit neojj;
    "nui.nvim" = vimPlugins."nui-nvim";
    "nvim-dap" = vimPlugins."nvim-dap";
    "nvim-dap-go" = vimPlugins."nvim-dap-go";
    "nvim-dap-python" = vimPlugins."nvim-dap-python";
    "nvim-dap-ui" = vimPlugins."nvim-dap-ui";
    "nvim-nio" = vimPlugins."nvim-nio";
    "nvim-autopairs" = vimPlugins."nvim-autopairs";
    "nvim-lspconfig" = vimPlugins."nvim-lspconfig";
    "nvim-treesitter" = vimPlugins."nvim-treesitter";
    "nvim-web-devicons" = vimPlugins."nvim-web-devicons";
    "oil.nvim" = vimPlugins."oil-nvim";
    "plenary.nvim" = vimPlugins."plenary-nvim";
    rustaceanvim = vimPlugins.rustaceanvim;
    scnvim = vimPlugins.scnvim;
    "supermaven-nvim" = supermaven;
    "telescope-fzf-native.nvim" = vimPlugins."telescope-fzf-native-nvim";
    "telescope-ui-select.nvim" = vimPlugins."telescope-ui-select-nvim";
    "telescope.nvim" = vimPlugins."telescope-nvim";
    "todo-comments.nvim" = vimPlugins."todo-comments-nvim";
    "toggleterm.nvim" = vimPlugins."toggleterm-nvim";
    undotree = vimPlugins.undotree;
    "vim-tidal" = vimTidal;
    "which-key.nvim" = vimPlugins."which-key-nvim";
  };

  pluginPack = pkgs.runCommand "pgvim-smoke-plugins" {} ''
    mkdir -p "$out/pack/core/opt"
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: source: ''
        ln -s "${source}" "$out/pack/core/opt/${name}"
      '')
      pluginSources)}
  '';

  extensionRuntime = pkgs.writeTextDir "lua/pgvim_smoke_extra.lua" ''
    return { value = 'runtime-loaded' }
  '';

  smokeModule = (import ./home-manager.nix {inherit configRoot;}) {
    inherit lib pkgs;
    config.programs.pgvim = {
      extraRuntimePaths = [extensionRuntime];
      extraLuaConfig = ''
        vim.opt.packpath:prepend([[${pluginPack}]])
        local smoke_lock = vim.fn.stdpath('config') .. '/nvim-pack-lock.json'
        local original_copyfile = vim.uv.fs_copyfile
        vim.uv.fs_copyfile = function(source, target, ...)
          if target == smoke_lock then
            return true
          end
          return original_copyfile(source, target, ...)
        end
        local smoke_pack = require('vim.pack')
        local function plugin_name(spec)
          if type(spec) == 'table' and spec.name then
            return spec.name
          end
          local source = type(spec) == 'table' and spec.src or spec
          local name = source:match('/([^/]+)$'):gsub("%.git$", "")
          return name
        end
        local active_plugins = {}
        smoke_pack.add = function(specs)
          vim.g.pgvim_smoke_pack_stub_called = true
          for _, spec in ipairs(specs) do
            local name = plugin_name(spec)
            if not active_plugins[name] then
              vim.cmd.packadd({ args = { name }, bang = vim.v.vim_did_init == 0 })
              active_plugins[name] = true
            end
          end
        end
        rawset(vim, 'pack', smoke_pack)
        vim.cmd.packadd('nvim-treesitter')
        require('nvim-treesitter').install = function() end
        return {
          before = function()
            vim.g.pgvim_smoke_before = require('pgvim_smoke_extra').value
            return {}
          end,
          after = function()
            vim.uv.fs_copyfile = original_copyfile
            vim.g.pgvim_smoke_after = 'configured'
          end,
        }
      '';
    };
  };

  smokePackage = builtins.head smokeModule.config.home.packages;
in {
  smoke = pkgs.runCommand "pgvim-smoke" {} ''
    run_smoke() {
      scenario="$1"
      shift
      root="$TMPDIR/$scenario"
      mkdir -p "$root/config/nvim" "$root/data" "$root/state" "$root/cache"
      printf '{"plugins":{}}' > "$root/config/nvim/nvim-pack-lock.json"
      HOME="$root/home" \
      XDG_CONFIG_HOME="$root/config" \
      XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" \
      XDG_CACHE_HOME="$root/cache" \
      PGVIM_SMOKE_EXTENSION=1 \
      PGVIM_SMOKE_SCENARIO="$scenario" \
        "${smokePackage}/bin/nvim" --headless "$@" \
          --cmd "luafile ${../tests/smoke.lua}"
    }

    run_smoke empty
    touch "$TMPDIR/smoke-file.lua"
    run_smoke file "$TMPDIR/smoke-file.lua"
    touch "$out"
  '';
}
