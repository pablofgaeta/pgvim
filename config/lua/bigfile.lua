-- Reduced-feature mode for very large files.
--
-- Opening a huge file makes navigation sluggish because every per-buffer
-- feature (treesitter, LSP, syntax, completion, gutter decorators) re-scans the
-- whole buffer. When a buffer trips either threshold below we turn those off for
-- that buffer only. The buffer stays fully editable and, importantly,
-- telescope/fzf search keeps working -- nothing here touches the pickers.
--
-- Detection is two-phase: byte size is known at BufReadPre (before the file is
-- parsed, so we can stop treesitter/LSP/syntax before they ever start), and line
-- count is checked at BufReadPost for files that are long but not large on disk.

local MAX_BYTES = 1.5 * 1024 * 1024 -- 1.5 MB
local MAX_LINES = 5000

local group = vim.api.nvim_create_augroup('bigfile', { clear = true })

-- Only touch real, file-backed buffers. Skip help, terminals, telescope
-- prompt/preview buffers, etc. (they all set a non-empty 'buftype').
local function is_normal(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == ''
end

local function oversized_bytes(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return false
  end
  local ok, stat = pcall((vim.uv or vim.loop).fs_stat, name)
  return ok and stat ~= nil and stat.size > MAX_BYTES
end

-- Re-assert the disables that other events keep trying to undo: treesitter,
-- classic syntax, and any LSP client. Cheap and idempotent, so we call it from
-- several events (LSP servers attach asynchronously, and syntax can reload on
-- window entry) to make sure the buffer stays reduced.
local function enforce(buf)
  if not (vim.api.nvim_buf_is_valid(buf) and vim.b[buf].bigfile) then
    return
  end
  pcall(vim.treesitter.stop, buf)
  if vim.bo[buf].syntax ~= 'off' then
    vim.bo[buf].syntax = 'off'
  end
  for _, client in pairs(vim.lsp.get_clients { bufnr = buf }) do
    pcall(vim.lsp.buf_detach_client, buf, client.id)
  end
end

-- Apply the one-time buffer-local disables. Idempotent via b:bigfile_applied.
local function apply(buf)
  if vim.b[buf].bigfile_applied then
    return
  end
  vim.b[buf].bigfile_applied = true
  vim.b[buf].bigfile = true

  -- Drop the treesitter indentexpr set in plugins/treesitter.lua.
  vim.bo[buf].indentexpr = ''

  -- Completion off for this buffer (blink.cmp honours b:completion).
  vim.b[buf].completion = false

  -- Gutter/inline decorators that scan buffer contents.
  pcall(function()
    require('ibl').setup_buffer(buf, { enabled = false })
  end)
  pcall(function()
    require('gitsigns').detach(buf)
  end)

  -- Editor extras.
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false

  -- <leader>/ normally runs telescope's current_buffer_fuzzy_find, which loads
  -- every line as a picker entry and re-sorts them on each keystroke. On a file
  -- this size (and with multi-KB lines) that locks up nvim. Shadow it with a
  -- buffer-local mapping (buffer-local beats the global map) that greps the file
  -- on disk with ripgrep instead: it streams, so only matching lines become
  -- entries. Fuzzy-refine the matches with <C-Enter> (see telescope.lua).
  -- Note: this searches the saved file, so unsaved edits are not reflected.
  vim.keymap.set('n', '<leader>/', function()
    local name = vim.api.nvim_buf_get_name(buf)
    if name == '' then
      vim.notify('bigfile: no file on disk to search', vim.log.levels.WARN)
      return
    end
    require('telescope.builtin').live_grep {
      search_dirs = { name },
      prompt_title = 'Grep big file (fuzzy-refine: <C-Enter>)',
    }
  end, { buffer = buf, desc = '[/] Search big file (ripgrep, fzf-safe)' })

  -- Kill treesitter/syntax/LSP now and again after the read cascade settles
  -- (LSP servers finish attaching a beat later).
  enforce(buf)
  vim.schedule(function()
    enforce(buf)
  end)

  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.notify(
        ('bigfile: reduced mode (treesitter/LSP/syntax/completion off) for %s'):format(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t')),
        vim.log.levels.INFO
      )
    end
  end)
end

-- Window-local options are sticky to the *window*, not the buffer: overriding
-- them for a bigfile and then reusing that window for a normal file would leave
-- the overrides behind. So we snapshot the window's values on entry to a bigfile
-- buffer and put them back when a normal buffer next occupies the window.
-- number/relativenumber/wrap are included defensively -- bigfile does not change
-- them, but restoring them guarantees nothing user-visible can linger.
local WIN_OPTS = { 'foldmethod', 'foldexpr', 'cursorline', 'number', 'relativenumber', 'wrap' }
local saved_wo = {}

local function restore_win(win)
  local snap = saved_wo[win]
  if not snap then
    return
  end
  saved_wo[win] = nil
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  for _, opt in ipairs(WIN_OPTS) do
    pcall(function()
      vim.wo[win][opt] = snap[opt]
    end)
  end
end

-- Window-local settings for a bigfile buffer's window. Snapshots the window's
-- options once (so restore_win can undo them) before applying the reduced set.
local function apply_win(buf)
  local win = vim.api.nvim_get_current_win()
  if not vim.b[buf].bigfile then
    restore_win(win)
    return
  end
  if not saved_wo[win] then
    local snap = {}
    for _, opt in ipairs(WIN_OPTS) do
      snap[opt] = vim.wo[opt]
    end
    saved_wo[win] = snap
  end
  vim.wo.foldmethod = 'manual'
  vim.wo.foldexpr = '0'
  vim.wo.cursorline = false
end

-- Undo apply()/apply_win() for a buffer: clear the flags, restore the window,
-- drop the buffer-local shadow map, and re-run the per-filetype setup so
-- treesitter, LSP, syntax, indent, and the gutter decorators come back the same
-- way they would on a fresh read -- without reloading (edits are preserved).
local function unapply(buf)
  vim.b[buf].bigfile = nil
  vim.b[buf].bigfile_applied = nil
  vim.b[buf].completion = nil

  restore_win(vim.api.nvim_get_current_win())

  pcall(vim.keymap.del, 'n', '<leader>/', { buffer = buf })

  vim.bo[buf].swapfile = vim.go.swapfile
  vim.bo[buf].undofile = vim.go.undofile
  vim.bo[buf].syntax = 'on'

  pcall(function()
    require('ibl').setup_buffer(buf, { enabled = true })
  end)
  pcall(function()
    require('gitsigns').attach(buf)
  end)

  -- Re-firing FileType re-runs treesitter start, the ftplugin (indentexpr), and
  -- the lspconfig filetype autostart -- the machinery apply() had suppressed.
  pcall(vim.api.nvim_exec_autocmds, 'FileType', { buffer = buf })
end

-- matchparen and todo-comments have no per-buffer switch, so we flip the global
-- state to follow whichever *file* buffer is focused. Tracked so we only issue
-- the command on an actual transition -- important because :DoMatchParen runs a
-- :windo, which is disruptive if fired repeatedly or over special windows.
local features_enabled = true
local function set_global_features(enabled)
  if enabled == features_enabled then
    return
  end
  features_enabled = enabled
  if enabled then
    if vim.fn.exists ':DoMatchParen' == 2 then
      pcall(vim.cmd, 'DoMatchParen')
    end
    pcall(function()
      require('todo-comments').enable()
    end)
  else
    if vim.fn.exists ':NoMatchParen' == 2 then
      pcall(vim.cmd, 'NoMatchParen')
    end
    pcall(function()
      require('todo-comments').disable()
    end)
  end
end

-- Phase 1: byte size, before the file is parsed. Marking b:bigfile here lets the
-- treesitter FileType guard and the LspAttach guard bail out early.
vim.api.nvim_create_autocmd('BufReadPre', {
  group = group,
  callback = function(args)
    if is_normal(args.buf) and oversized_bytes(args.buf) then
      vim.b[args.buf].bigfile = true
    end
  end,
})

-- Phase 2: line count is only meaningful once loaded. Run the full apply here so
-- both byte- and line-detected files converge on the same disabled state.
vim.api.nvim_create_autocmd('BufReadPost', {
  group = group,
  callback = function(args)
    if not is_normal(args.buf) then
      return
    end
    if vim.b[args.buf].bigfile or vim.api.nvim_buf_line_count(args.buf) > MAX_LINES then
      apply(args.buf)
    end
  end,
})

-- Catch LSP clients that attach after our detection. Detaching inside LspAttach
-- itself is too early (the attach is still completing), so defer it.
vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(args)
    local buf = args.buf
    if vim.b[buf].bigfile then
      vim.schedule(function()
        enforce(buf)
      end)
    end
  end,
})

-- Window entry can reload syntax; re-assert and set window-local options.
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = group,
  callback = function(args)
    apply_win(args.buf)
    enforce(args.buf)
  end,
})

-- Follow the focused file buffer for the global features. Skip special buffers
-- (telescope prompt/preview, help, terminals) entirely so we never run
-- matchparen's :windo while a picker is focused.
vim.api.nvim_create_autocmd('BufEnter', {
  group = group,
  callback = function(args)
    if not is_normal(args.buf) then
      return
    end
    set_global_features(not vim.b[args.buf].bigfile)
  end,
})

-- Drop a window's saved snapshot when it closes, so a reused window id can never
-- restore stale options onto an unrelated window.
vim.api.nvim_create_autocmd('WinClosed', {
  group = group,
  callback = function(args)
    saved_wo[tonumber(args.match)] = nil
  end,
})

-- Manual override. :BigfileToggle flips reduced mode for the current buffer
-- regardless of size -- force full features onto a big file, or reduce a
-- sluggish small one. This only affects the live buffer; detection still runs
-- normally on the next fresh read.
local function toggle(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not is_normal(buf) then
    vim.notify('bigfile: not a normal file buffer', vim.log.levels.WARN)
    return
  end
  if vim.b[buf].bigfile then
    unapply(buf)
    set_global_features(true)
    vim.notify(('bigfile: full mode restored for %s'):format(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t')), vim.log.levels.INFO)
  else
    apply(buf)
    apply_win(buf)
    set_global_features(false)
  end
end

vim.api.nvim_create_user_command('BigfileToggle', function()
  toggle()
end, { desc = 'Toggle bigfile reduced mode for the current buffer' })
