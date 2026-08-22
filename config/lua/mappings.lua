-- Keep selection alive when indenting in visual/visual-block mode
vim.keymap.set('x', '<', '<gv', { desc = 'Indent left and keep selection' })
vim.keymap.set('x', '>', '>gv', { desc = 'Indent right and keep selection' })

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- vscode-like comment toggling
vim.keymap.set('i', '<D-/>', '<Esc>:normal gcc<CR>i', { desc = '[/] Toggle comment line' })
vim.keymap.set('n', '<D-/>', ':normal gcc<CR>', { desc = '[/] Toggle comment line' })
vim.keymap.set('v', '<D-/>', '<Esc>:normal gvgc<CR>', { desc = '[/] Toggle comment block' })

-- go to normal mode
vim.keymap.set('n', ';', ':', { desc = 'CMD enter command mode' })
vim.keymap.set('i', 'jk', '<ESC>')

-- swap lines up and down in normal mode
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { desc = 'Move line down' })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { desc = 'Move line up' })

-- swap lines up and down in insert mode
vim.keymap.set('i', '<A-j>', '<Esc>:m .+1<CR>==gi', { desc = 'Move line down' })
vim.keymap.set('i', '<A-k>', '<Esc>:m .-2<CR>==gi', { desc = 'Move line up' })

-- swap selected lines up and down in visual mode
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- whole file ops
vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', { desc = 'general save file' })
vim.keymap.set('n', '<C-c>', '<cmd>%y+<CR>', { desc = 'general copy whole file' })

-- line no toggles
vim.keymap.set('n', '<leader>n', '<cmd>set nu!<CR>', { desc = 'toggle line number' })
vim.keymap.set('n', '<leader>rn', '<cmd>set rnu!<CR>', { desc = 'toggle relative number' })

-- formatting
vim.keymap.set({ 'n', 'x' }, '<leader>f', function()
  require('plugins').ensure 'development'
  require('conform').format { lsp_fallback = true }
end, { desc = 'general format file' })

-- diagnostics
vim.keymap.set('n', '<leader>ds', vim.diagnostic.setloclist, { desc = 'LSP diagnostic loclist' })

vim.keymap.set('n', '<leader>uv', '<cmd>!uv run %<CR>', { desc = 'Run current file with uv', noremap = false, silent = true })

vim.keymap.set('n', '<leader><F5>', function()
  require('plugins').ensure 'workspace'
  vim.cmd.UndotreeToggle()
end)

vim.keymap.set('n', '<leader>sdb', function()
  require('plugins').ensure 'tidal'
  vim.cmd.SCNvimStart()
end)
vim.keymap.set('n', '<leader>sde', function()
  require('plugins').ensure 'tidal'
  vim.cmd.SCNvimStop()
end)

vim.keymap.set('n', '<D-p>', function()
  require('plugins').ensure 'workspace'
  require('telescope.builtin').find_files()
end, { desc = 'Search Files' })

vim.keymap.set('n', '-', function()
  require('plugins').ensure 'workspace'
  vim.cmd.Oil()
end, { desc = 'Open parent directory' })
