local M = {
  packages = { 'conform.nvim' },
}

function M.setup()
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
end

return M
