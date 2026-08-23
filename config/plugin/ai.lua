vim.pack.add {
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/nvim-mini/mini.icons',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/yetone/avante.nvim',
  'https://github.com/supermaven-inc/supermaven-nvim',
}

local overrides = package.loaded['pgvim.overrides'] or {}

local avante = overrides.avante
  or {
    provider = 'opencode',
    acp_providers = {
      opencode = {
        command = 'opencode',
        args = { 'acp' },
      },
    },
    behaviour = { auto_suggestions = false },
  }
require('avante').setup(avante)

if overrides.inline_completion ~= false then
  require('supermaven-nvim').setup {}
end
