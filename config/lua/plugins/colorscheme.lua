local M = {
  packages = { 'catppuccin' },
}

function M.setup()
  require('catppuccin').setup {
    flavour = 'mocha',
    background = {
      light = 'latte',
      dark = 'mocha',
    },
    transparent_background = true,
    auto_integrations = true,
  }
  vim.cmd.colorscheme 'catppuccin'
end

return M
