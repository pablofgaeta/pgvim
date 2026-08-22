local M = {
  packages = { 'vim-tidal', 'scnvim' },
}

function M.setup()
  require('scnvim').setup {
    editor = {
      highlight = { color = 'IncSearch' },
    },
    postwin = {
      float = { enabled = true },
    },
  }
end

return M
