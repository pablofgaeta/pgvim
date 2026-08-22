local M = {
  packages = { 'fidget.nvim', 'nvim-lspconfig', 'rustaceanvim' },
  requires = { 'workspace', 'completion' },
}

local function client_supports_method(client, method, bufnr)
  return client:supports_method(method, bufnr)
end

local function on_attach(event)
  local map = function(keys, func, desc, mode)
    vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
  end

  map('grn', vim.lsp.buf.rename, 'Rename')
  map('gra', vim.lsp.buf.code_action, 'Code Action', { 'n', 'x' })
  map('grr', require('telescope.builtin').lsp_references, 'References')
  map('gri', require('telescope.builtin').lsp_implementations, 'Implementation')
  map('grd', require('telescope.builtin').lsp_definitions, 'Definition')
  map('grD', vim.lsp.buf.declaration, 'Declaration')
  map('gO', require('telescope.builtin').lsp_document_symbols, 'Document Symbols')
  map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace Symbols')
  map('grt', require('telescope.builtin').lsp_type_definitions, 'Type Definition')

  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
    local group = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      buffer = event.buf,
      group = group,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = event.buf,
      group = group,
      callback = vim.lsp.buf.clear_references,
    })
    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
      callback = function(detach_event)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = detach_event.buf }
      end,
    })
  end

  if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
    map('<leader>th', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
    end, 'Toggle Inlay Hints')
  end
end

function M.setup()
  if vim.g.vscode then
    return
  end

  require('fidget').setup {}
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
    callback = on_attach,
  })

  vim.diagnostic.config {
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = vim.diagnostic.severity.ERROR },
    signs = vim.g.have_nerd_font and {
      text = {
        [vim.diagnostic.severity.ERROR] = '󰅚 ',
        [vim.diagnostic.severity.WARN] = '󰀪 ',
        [vim.diagnostic.severity.INFO] = '󰋽 ',
        [vim.diagnostic.severity.HINT] = '󰌶 ',
      },
    } or {},
    virtual_text = { source = 'if_many', spacing = 2 },
  }

  local capabilities = require('blink.cmp').get_lsp_capabilities()
  local servers = {
    gopls = {},
    pyrefly = {},
    html = {},
    cssls = {},
    yamlls = {},
    dockerls = {},
    terraformls = {},
    nil_ls = {
      settings = {
        ['nil'] = {
          formatting = { command = { 'alejandra' } },
        },
      },
    },
    lua_ls = {
      settings = {
        Lua = {
          completion = { callSnippet = 'Replace' },
          diagnostics = { disable = { 'missing-fields' } },
        },
      },
    },
  }

  for name, server in pairs(servers) do
    vim.lsp.config(
      name,
      vim.tbl_deep_extend('force', {
        capabilities = capabilities,
      }, server)
    )
    vim.lsp.enable(name)
  end
end

return M
