vim.pack.add { 'https://github.com/stevearc/conform.nvim' }

require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    if ({ c = true, cpp = true })[vim.bo[bufnr].filetype] then
      return nil
    end
    return {
      timeout_ms = 500,
      lsp_format = 'fallback',
    }
  end,
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_fix', 'ruff_format' },
    css = { 'prettier' },
    html = { 'prettier' },
    javascript = { 'prettier' },
    rust = { 'rustfmt' },
    markdown = { 'rumdl' },
    nix = { 'alejandra' },
  },
}
vim.keymap.set({ 'n', 'x' }, '<leader>f', function()
  require('conform').format { lsp_fallback = true }
end, { desc = 'general format file' })
