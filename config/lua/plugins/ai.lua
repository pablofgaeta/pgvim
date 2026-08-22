local M = {
  packages = { 'avante.nvim', 'supermaven-nvim' },
  requires = { 'workspace' },
}

function M.setup(overrides)
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
end

return M
