local M = {
  packages = {
    'mini.icons',
    'mini.nvim',
    'guess-indent.nvim',
    'grug-far.nvim',
    'todo-comments.nvim',
    'nvim-autopairs',
    'indent-blankline.nvim',
    'ecolog.nvim',
    'markview.nvim',
    'oil.nvim',
    'toggleterm.nvim',
    'undotree',
  },
}

function M.setup()
  require('guess-indent').setup {}
  require('todo-comments').setup { signs = false }
  require('nvim-autopairs').setup {}
  require('ibl').setup {}
  require('mini.icons').setup {}
  require('mini.ai').setup { n_lines = 500 }
  require('mini.surround').setup {}

  local statusline = require 'mini.statusline'
  statusline.setup { use_icons = vim.g.have_nerd_font }
  statusline.section_location = function()
    return '%2l:%-2v'
  end

  require('ecolog').setup {
    path = vim.fn.stdpath 'config',
    vim_env = true,
  }
  vim.keymap.set('n', '<leader>ee', '<cmd>EcologSelect<cr>', { desc = 'Select Env File' })

  require('markview').setup {
    preview = { enable = false },
  }

  require('oil').setup {
    keymaps = { q = 'actions.close' },
    view_options = { show_hidden = true },
  }

  require('toggleterm').setup {
    direction = 'float',
    start_in_insert = true,
    persist_mode = true,
    float_opts = {
      border = 'rounded',
      width = function()
        return math.floor(vim.o.columns * 0.9)
      end,
      height = function()
        return math.floor(vim.o.lines * 0.85)
      end,
    },
  }
  vim.keymap.set('n', '<M-f>', '<cmd>execute v:count . "ToggleTerm direction=float"<cr>', { desc = 'Toggle floating terminal' })
  vim.keymap.set('t', '<M-f>', '<cmd>execute b:toggle_number . "ToggleTerm direction=float"<cr>', { desc = 'Toggle floating terminal' })
end

return M
