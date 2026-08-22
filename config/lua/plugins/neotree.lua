local M = {
  packages = { 'plenary.nvim', 'nvim-web-devicons', 'nui.nvim', 'neo-tree.nvim' },
}

function M.setup()
  require('neo-tree').setup {
    filesystem = {
      filtered_items = { visible = true },
      window = { mappings = { ['\\'] = 'close_window' } },
    },
  }
  vim.keymap.set('n', '\\', '<cmd>Neotree reveal<cr>', {
    desc = 'NeoTree reveal',
    silent = true,
  })
end

return M
