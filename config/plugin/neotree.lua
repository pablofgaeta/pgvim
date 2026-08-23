vim.pack.add {
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/nvim-neo-tree/neo-tree.nvim',
}

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
