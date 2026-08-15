local M = {}

-- Merges line diagnostics above LSP hover in a single float, since IDEs
-- typically surface both together instead of requiring separate keys.
local function hover_with_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local lnum = vim.api.nvim_win_get_cursor(win)[1] - 1
  local lines = {}

  for _, diagnostic in ipairs(vim.diagnostic.get(bufnr, { lnum = lnum })) do
    table.insert(lines, ('**%s**: %s'):format(vim.diagnostic.severity[diagnostic.severity], diagnostic.message))
  end
  if #lines > 0 then table.insert(lines, '---') end

  local client = vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/hover' })[1]
  if not client then
    if #lines > 0 then vim.lsp.util.open_floating_preview(lines, 'markdown', { border = 'rounded', focus = false }) end
    return
  end

  local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
  client:request('textDocument/hover', params, function(_, result)
    if result and result.contents then vim.list_extend(lines, vim.lsp.util.convert_input_to_markdown_lines(result.contents)) end
    lines = vim.lsp.util.trim_empty_lines(lines)
    if #lines == 0 then
      vim.notify('No information available', vim.log.levels.INFO)
      return
    end
    vim.lsp.util.open_floating_preview(lines, 'markdown', { border = 'rounded', focus = false })
  end, bufnr)
end

function M.setup()
  local group = vim.api.nvim_create_augroup('CarlosvtsCore', { clear = true })
  vim.api.nvim_create_autocmd('InsertEnter', {
    group = group,
    callback = function() vim.wo.relativenumber = false end,
  })
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = group,
    callback = function() vim.wo.relativenumber = true end,
  })
  vim.api.nvim_create_autocmd('TextYankPost', {
    group = group,
    callback = function() vim.hl.on_yank { timeout = 150 } end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = { 'markdown', 'text', 'gitcommit' },
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true
      vim.opt_local.spell = false
    end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'lua',
    callback = function()
      vim.opt_local.shiftwidth = 2
      vim.opt_local.tabstop = 2
      vim.opt_local.softtabstop = 2
    end,
  })

  vim.diagnostic.config {
    severity_sort = true,
    underline = true,
    virtual_text = false,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = '',
        [vim.diagnostic.severity.WARN] = '',
        [vim.diagnostic.severity.INFO] = '',
        [vim.diagnostic.severity.HINT] = '󰌵',
      },
    },
    float = { border = 'rounded', source = 'if_many' },
    update_in_insert = false,
  }

  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args)
      local opts = { buffer = args.buf, silent = true }
      local function map(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, vim.tbl_extend('force', opts, { desc = desc })) end
      map('gd', vim.lsp.buf.definition, 'Definition')
      map('gD', vim.lsp.buf.declaration, 'Declaration')
      map('gr', function() require('fzf-lua').lsp_references() end, 'References')
      map('gi', vim.lsp.buf.implementation, 'Implementation')
      map('K', hover_with_diagnostics, 'Hover documentation and diagnostics')
      map('<F2>', vim.lsp.buf.rename, 'Rename symbol')
      map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
      map('<leader>cd', vim.diagnostic.open_float, 'Line diagnostics')
      map('<leader>cr', function() require('fzf-lua').lsp_references() end, 'References')
      map('<leader>cs', function() require('fzf-lua').lsp_document_symbols() end, 'Document symbols')
      map('<leader>cS', function() require('fzf-lua').lsp_live_workspace_symbols() end, 'Workspace symbols')

      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client:supports_method 'textDocument/inlayHint' then
        map('<leader>ch', function()
          local bufnr = args.buf
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }, { bufnr = bufnr })
        end, 'Toggle inlay hints')
      end
    end,
  })

  local function large_file(buf)
    if vim.b[buf].carlosvts_bigfile then return end
    vim.b[buf].carlosvts_bigfile = true
    pcall(vim.treesitter.stop, buf)
    for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
      pcall(vim.lsp.buf_detach_client, buf, client.id)
    end
    pcall(function() require('ibl').setup_buffer(buf, { enabled = false }) end)
    vim.bo[buf].syntax = vim.bo[buf].filetype
    if not vim.b[buf].carlosvts_bigfile_notified then
      vim.b[buf].carlosvts_bigfile_notified = true
      vim.schedule(function() vim.notify('Large-file mode: LSP, completion, Treesitter, lint and indent guides disabled.', vim.log.levels.INFO) end)
    end
  end

  vim.api.nvim_create_autocmd('BufReadPre', {
    group = group,
    callback = function(args)
      local stat = vim.uv.fs_stat(args.file)
      if stat and stat.size > 1024 * 1024 then large_file(args.buf) end
    end,
  })
  vim.api.nvim_create_autocmd('BufReadPost', {
    group = group,
    callback = function(args)
      if vim.b[args.buf].carlosvts_bigfile then return end
      for _, line in ipairs(vim.api.nvim_buf_get_lines(args.buf, 0, math.min(200, vim.api.nvim_buf_line_count(args.buf)), false)) do
        if #line > 10000 then
          large_file(args.buf)
          break
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd('QuickFixCmdPost', {
    group = group,
    pattern = 'make',
    callback = function()
      for _, item in ipairs(vim.fn.getqflist()) do
        if item.valid == 1 and item.type == 'E' then
          vim.cmd.copen()
          return
        end
      end
      vim.cmd.cclose()
      vim.notify('Build finished without errors.', vim.log.levels.INFO)
    end,
  })

  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    once = true,
    callback = function()
      if vim.fn.argc() ~= 1 or vim.fn.isdirectory(vim.fn.argv(0)) ~= 1 then return end
      vim.schedule(function()
        local directory_buf = vim.api.nvim_get_current_buf()
        vim.cmd.enew()
        pcall(vim.api.nvim_buf_delete, directory_buf, { force = true })
      end)
    end,
  })

  -- Keep search matches after Enter; clear only after an actual cursor move.
  local searched = false
  vim.on_key(function(key)
    if vim.fn.getcmdtype() == '/' or vim.fn.getcmdtype() == '?' then
      searched = true
      return
    end
    if searched and vim.v.hlsearch == 1 and vim.tbl_contains({ 'h', 'j', 'k', 'l', 'w', 'b', 'e', '0', '$', 'G' }, key) then
      vim.schedule(function() vim.cmd.nohlsearch() end)
      searched = false
    end
  end, vim.api.nvim_create_namespace 'carlosvts-search')

  require('carlosvts.tools').configure_make()
end

return M
