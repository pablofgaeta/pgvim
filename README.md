# pgvim

My personal Neovim distribution. Nix provides Neovim and external tools;
Neovim's native `vim.pack` manages plugins.

Neovim 0.12 or newer is required because `vim.pack` is still experimental.

## Run

```sh
nix run github:pablofgaeta/pgvim
```

The first launch installs plugins at the revisions in
`config/nvim-pack-lock.json`. After updating the flake input, run `:PackSync` to
move existing plugins to the new locked revisions.

## Home Manager

Add the flake input:

```nix
inputs.pgvim = {
  url = "github:pablofgaeta/pgvim";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Importing the module installs pgvim. There is no separate enable option.

```nix
imports = [inputs.pgvim.homeManagerModules.default];
```

## Modify

Clone the repository and use the local checkout:

```sh
git clone https://github.com/pablofgaeta/pgvim
cd pgvim
nix run .
```

Configuration changes are included when Nix rebuilds the package. The
repository lockfile is synchronized to
`~/.config/nvim/nvim-pack-lock.json` at startup. After accepting
`vim.pack.update()`, copy the writable lockfile back to
`config/nvim-pack-lock.json` before restarting Neovim.

## Verify

Run the package smoke tests for the current system:

```sh
nix flake check
```

The check exercises empty and file-backed sessions, first-use mappings, plugin
commands, lazy loading, and Home Manager extension composition in isolated XDG
directories.

## Extensions

The Home Manager module accepts Lua text and additional Neovim runtime trees:

```nix
programs.pgvim = {
  extraRuntimePaths = [./pgvim-extra];
  extraLuaConfig = builtins.readFile ./pgvim-extra/init.lua;
};
```

The Lua entry file may return hooks:

- `before` runs before public plugin configuration and returns optional overrides.
- `after` runs once the public configuration is ready.

```lua
return {
  before = function()
    return {
      avante = {},
      inline_completion = false,
    }
  end,
  after = function()
    -- Add private configuration here.
  end,
}
```

Plain Lua that returns nothing is also accepted.
