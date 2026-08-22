local M = {
  packages = { 'friendly-snippets', 'LuaSnip', 'lazydev.nvim', 'blink.cmp' },
}

function M.setup()
  if vim.g.vscode then
    return
  end

  require('lazydev').setup {
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
    },
  }
  require('luasnip').setup {}
  require('luasnip.loaders.from_vscode').lazy_load()

  require('blink.cmp').setup {
    keymap = { preset = 'default' },
    appearance = { nerd_font_variant = 'mono' },
    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
      trigger = { prefetch_on_insert = false },
    },
    sources = {
      default = { 'lsp', 'path', 'buffer', 'snippets', 'lazydev' },
      providers = {
        lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
      },
    },
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    signature = { enabled = true },
  }
end

return M
