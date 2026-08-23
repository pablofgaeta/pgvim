vim.pack.add {
  'https://github.com/tidalcycles/vim-tidal',
  'https://github.com/davidgranstrom/scnvim',
}

require('scnvim').setup {
  editor = {
    highlight = { color = 'IncSearch' },
  },
  postwin = {
    float = { enabled = true },
  },
}
vim.keymap.set('n', '<leader>sdb', function()
  vim.cmd.SCNvimStart()
end, { desc = 'Start SuperCollider' })
vim.keymap.set('n', '<leader>sde', function()
  vim.cmd.SCNvimStop()
end, { desc = 'Stop SuperCollider' })
