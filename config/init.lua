local source = debug.getinfo(1, 'S').source
local config_root = vim.fs.dirname(source:sub(1, 1) == '@' and source:sub(2) or source)
vim.g.pgvim_root = config_root
vim.opt.runtimepath:prepend(config_root)

require 'settings'
require 'bigfile'

local canonical_lock = config_root .. '/nvim-pack-lock.json'
local user_lock = vim.fn.stdpath 'config' .. '/nvim-pack-lock.json'
if canonical_lock ~= user_lock then
  vim.fn.mkdir(vim.fs.dirname(user_lock), 'p')
  local uv = vim.uv or vim.loop
  if uv.fs_stat(user_lock) then
    local unlocked, unlock_error = uv.fs_chmod(user_lock, 420)
    if not unlocked then
      error(('Could not unlock vim.pack lockfile: %s'):format(unlock_error))
    end
  end
  local copied, copy_error = uv.fs_copyfile(canonical_lock, user_lock)
  if not copied then
    error(('Could not synchronize vim.pack lockfile: %s'):format(copy_error))
  end
  local writable, chmod_error = uv.fs_chmod(user_lock, 420)
  if not writable then
    error(('Could not make vim.pack lockfile writable: %s'):format(chmod_error))
  end
end

local extension = rawget(_G, 'pgvim_extension')
if extension ~= nil and type(extension) ~= 'table' then
  error 'extraLuaConfig must return a table of extension hooks or nil'
end

local overrides = extension and extension.before and extension.before() or {}
require('plugins').setup(overrides)
if extension and extension.after then
  extension.after()
end

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

require 'mappings'

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
