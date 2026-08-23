vim.pack.add {
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
}

local parsers = {
  'bash',
  'c',
  'css',
  'diff',
  'git_config',
  'gitcommit',
  'gitignore',
  'go',
  'html',
  'hyprlang',
  'json',
  'lua',
  'luadoc',
  'make',
  'markdown',
  'markdown_inline',
  'nix',
  'python',
  'query',
  'rust',
  'supercollider',
  'toml',
  'vim',
  'vimdoc',
  'yaml',
}

local treesitter = require 'nvim-treesitter'
treesitter.setup {}
treesitter.install(parsers)

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
  callback = function(args)
    if vim.b[args.buf].bigfile then
      return
    end
    local language = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
    if language and pcall(vim.treesitter.language.add, language) then
      pcall(vim.treesitter.start, args.buf, language)
      if language ~= 'ruby' then
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end
  end,
})
