local M = {}

local configured = {}
local overrides = {}

local function build_plugin(event)
  if event.data.kind ~= 'install' and event.data.kind ~= 'update' then
    return
  end

  local commands = {
    ['LuaSnip'] = { 'make', 'install_jsregexp' },
    ['avante.nvim'] = { 'make' },
    ['telescope-fzf-native.nvim'] = { 'make' },
  }
  local command = commands[event.data.spec.name]
  if command then
    local result = vim.system(command, { cwd = event.data.path }):wait()
    if result.code ~= 0 then
      error(('Failed to build %s:\n%s'):format(event.data.spec.name, result.stderr or ''))
    end
  end
end

local collections = {
  workspace = { 'editor', 'navigation' },
  development = { 'lsp', 'formatting', 'git', 'treesitter' },
}

local function ensure_module(name)
  if configured[name] then
    return
  end

  local module = require('plugins.' .. name)
  for _, required in ipairs(module.requires or {}) do
    M.ensure(required)
  end
  for _, plugin in ipairs(module.packages or {}) do
    vim.cmd.packadd(plugin)
  end
  module.setup(overrides)
  configured[name] = true
end

function M.ensure(name)
  local collection = collections[name]
  if not collection then
    ensure_module(name)
    return
  end

  for _, module in ipairs(collection) do
    ensure_module(module)
  end
end

function M.setup(config_overrides)
  overrides = config_overrides or {}

  vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('plugin-builds', { clear = true }),
    callback = build_plugin,
  })

  vim.pack.add(require 'specs', {
    confirm = false,
    load = function() end,
  })
  vim.api.nvim_create_user_command('PackSync', function()
    vim.pack.update(nil, { target = 'lockfile' })
  end, { desc = 'Synchronize installed plugins to the repository lockfile' })

  M.ensure 'colorscheme'
  M.ensure 'neotree'
  M.ensure 'whichkey'
  require('plugins.navigation').register()

  vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
    group = vim.api.nvim_create_augroup('development-plugins', { clear = true }),
    once = true,
    callback = function()
      M.ensure 'development'
    end,
  })
  local ai_autocmd
  ai_autocmd = vim.api.nvim_create_autocmd('InsertEnter', {
    group = vim.api.nvim_create_augroup('ai-plugins', { clear = true }),
    callback = function()
      if vim.bo.buftype ~= '' then
        return
      end
      vim.api.nvim_del_autocmd(ai_autocmd)
      M.ensure 'ai'
    end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('tidal-plugins', { clear = true }),
    pattern = { 'supercollider', 'tidal' },
    once = true,
    callback = function()
      M.ensure 'tidal'
    end,
  })

  local function dap_action(action)
    return function()
      M.ensure 'dap'
      require('dap')[action]()
    end
  end
  vim.keymap.set('n', '<F5>', dap_action 'continue', { desc = 'Debug: Start/Continue' })
  vim.keymap.set('n', '<F1>', dap_action 'step_into', { desc = 'Debug: Step Into' })
  vim.keymap.set('n', '<F2>', dap_action 'step_over', { desc = 'Debug: Step Over' })
  vim.keymap.set('n', '<F3>', dap_action 'step_out', { desc = 'Debug: Step Out' })
end

return M
