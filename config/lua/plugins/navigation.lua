local M = {
  packages = {
    'telescope-fzf-native.nvim',
    'telescope-ui-select.nvim',
    'telescope.nvim',
  },
}

local registered = false

local function telescope_map(lhs, action, options, desc)
  vim.keymap.set('n', lhs, function()
    require('plugins').ensure 'workspace'
    local builtin = require 'telescope.builtin'
    local resolved = type(options) == 'function' and options() or options
    if resolved then
      builtin[action](resolved)
    else
      builtin[action]()
    end
  end, { desc = desc })
end

function M.register()
  if registered or vim.g.vscode then
    return
  end
  registered = true

  telescope_map('<leader>sh', 'help_tags', nil, '[S]earch [H]elp')
  telescope_map('<leader>sk', 'keymaps', nil, '[S]earch [K]eymaps')
  telescope_map('<leader>sf', 'find_files', { hidden = true }, '[S]earch [F]iles')
  telescope_map('<leader>ss', 'builtin', nil, '[S]earch [S]elect Telescope')
  telescope_map('<leader>sw', 'grep_string', nil, '[S]earch current [W]ord')
  telescope_map('<leader>sg', 'live_grep', {
    additional_args = function()
      return { '--hidden' }
    end,
  }, '[S]earch by [G]rep')
  telescope_map('<leader>sd', 'diagnostics', nil, '[S]earch [D]iagnostics')
  telescope_map('<leader>sr', 'resume', nil, '[S]earch [R]esume')
  telescope_map('<leader>s.', 'oldfiles', nil, '[S]earch recent files')
  telescope_map('<leader><leader>', 'buffers', nil, 'Find existing buffers')
  telescope_map('<leader>/', 'current_buffer_fuzzy_find', function()
    return require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    }
  end, 'Fuzzily search current buffer')
  telescope_map('<leader>s/', 'live_grep', {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }, 'Search in open files')
  telescope_map('<leader>sn', 'find_files', function()
    return { cwd = vim.g.pgvim_root }
  end, '[S]earch [N]eovim files')
  telescope_map('<leader>sng', 'live_grep', function()
    return { cwd = vim.g.pgvim_root }
  end, '[S]earch [N]eovim files by [G]rep')
end

function M.setup()
  if vim.g.vscode then
    return
  end

  local actions = require 'telescope.actions'
  require('telescope').setup {
    defaults = {
      mappings = {
        i = { ['<c-enter>'] = 'to_fuzzy_refine', ['<esc>'] = actions.close },
      },
    },
    extensions = {
      ['ui-select'] = require('telescope.themes').get_dropdown(),
    },
  }
  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')
end

return M
