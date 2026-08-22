local function check_version()
  local version = tostring(vim.version())
  if vim.version.ge(vim.version(), '0.12') then
    vim.health.ok(('Neovim version: %s'):format(version))
  else
    vim.health.error(('Neovim 0.12 or newer is required; found %s'):format(version))
  end
end

local function check_executables()
  local executables = {
    'alejandra',
    'dlv',
    'fd',
    'git',
    'gopls',
    'jj',
    'lua-language-server',
    'make',
    'nil',
    'prettier',
    'pyrefly',
    'rg',
    'ruff',
    'rumdl',
    'rust-analyzer',
    'stylua',
    'terraform-ls',
    'tree-sitter',
    'unzip',
  }

  for _, executable in ipairs(executables) do
    if vim.fn.executable(executable) == 1 then
      vim.health.ok(('Found executable: %s'):format(executable))
    else
      vim.health.error(('Missing executable: %s'):format(executable))
    end
  end
end

return {
  check = function()
    vim.health.start 'pgvim'
    vim.health.info('System information: ' .. vim.inspect((vim.uv or vim.loop).os_uname()))
    check_version()
    check_executables()
  end,
}
