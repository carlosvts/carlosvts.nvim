local tools = require 'carlosvts.tools'
local is_windows = vim.fn.has 'win32' == 1

local parsers = tools.treesitter_parsers

local servers = {
  'basedpyright',
  'lua_ls',
  'cmake',
  'jsonls',
  'yamlls',
  'taplo',
  'marksman',
  'bashls',
  'dockerls',
  'docker_compose_language_service',
  'terraformls',
}
if not is_windows or vim.fn.executable 'clangd' == 1 then servers[#servers + 1] = 'clangd' end

local mason_tools = {
  'basedpyright',
  'bash-language-server',
  'cmake-language-server',
  'docker-compose-language-service',
  'dockerfile-language-server',
  'json-lsp',
  'lua-language-server',
  'marksman',
  'taplo',
  'terraform-ls',
  'yaml-language-server',
  'ruff',
  'debugpy',
  'stylua',
  'prettier',
  'shfmt',
  'shellcheck',
  'markdownlint-cli2',
}
if not is_windows then vim.list_extend(mason_tools, { 'clang-format', 'codelldb' }) end

local function setup_lsp()
  local capabilities = require('blink.cmp').get_lsp_capabilities()
  vim.lsp.config('*', { capabilities = capabilities })

  ---@type vim.lsp.Config
  local basedpyright = {
    before_init = function(_, config)
      local root = config.root_dir or require('carlosvts.project').get()
      local python = tools.python(root)
      config.settings = vim.tbl_deep_extend('force', config.settings or {}, {
        python = { pythonPath = python },
        basedpyright = { analysis = { typeCheckingMode = 'standard', diagnosticMode = 'openFilesOnly' } },
      })
    end,
  }
  vim.lsp.config('basedpyright', basedpyright)

  ---@type vim.lsp.Config
  local lua_ls = {
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file('', true) },
        diagnostics = { globals = { 'vim' } },
        telemetry = { enable = false },
      },
    },
  }
  vim.lsp.config('lua_ls', lua_ls)
  vim.lsp.enable(servers)
end

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = '*',
        callback = function(args)
          if vim.b[args.buf].carlosvts_bigfile then return end
          local language = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype) or vim.bo[args.buf].filetype
          if vim.list_contains(parsers, language) then pcall(vim.treesitter.start, args.buf, language) end
        end,
      })
      vim.schedule(function()
        if #vim.api.nvim_list_uis() == 0 then return end
        local treesitter = require 'nvim-treesitter'
        local installed = treesitter.get_installed 'parsers'
        local missing = vim.tbl_filter(function(language) return not vim.list_contains(installed, language) end, parsers)
        if #missing > 0 then
          vim.notify(('Installing %d missing Treesitter parsers...'):format(#missing), vim.log.levels.INFO)
          treesitter.install(missing)
        end
      end)
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    lazy = false,
    config = function()
      require('nvim-treesitter-textobjects').setup { select = { lookahead = true } }
      local select = require('nvim-treesitter-textobjects.select').select_textobject
      local move = require 'nvim-treesitter-textobjects.move'
      local selections = {
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
        ['aa'] = '@parameter.outer',
        ['ia'] = '@parameter.inner',
        ['ab'] = '@block.outer',
        ['ib'] = '@block.inner',
      }
      for lhs, capture in pairs(selections) do
        vim.keymap.set({ 'x', 'o' }, lhs, function() select(capture, 'textobjects') end, { desc = 'Select ' .. capture })
      end
      local moves = {
        [']f'] = { move.goto_next_start, '@function.outer' },
        ['[f'] = { move.goto_previous_start, '@function.outer' },
        [']c'] = { move.goto_next_start, '@class.outer' },
        ['[c'] = { move.goto_previous_start, '@class.outer' },
        [']a'] = { move.goto_next_start, '@parameter.inner' },
        ['[a'] = { move.goto_previous_start, '@parameter.inner' },
      }
      for lhs, item in pairs(moves) do
        vim.keymap.set({ 'n', 'x', 'o' }, lhs, function() item[1](item[2], 'textobjects') end, { desc = 'Move to ' .. item[2] })
      end
    end,
  },
  {
    'saghen/blink.cmp',
    version = '1.*',
    event = 'InsertEnter',
    opts = {
      enabled = function() return not vim.b.carlosvts_bigfile end,
      keymap = {
        preset = 'none',
        ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide', 'fallback' },
      },
      completion = {
        keyword = { range = 'full' },
        list = { selection = { preselect = false, auto_insert = false } },
        documentation = { auto_show = false },
        menu = { auto_show = true },
      },
      signature = { enabled = false },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
          lsp = { min_keyword_length = 2 },
          buffer = { min_keyword_length = 2 },
          path = { min_keyword_length = 2 },
        },
      },
      snippets = { preset = 'default' },
    },
  },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = { library = { { path = '${3rd}/luv/library', words = { 'vim%.uv' } } } },
  },
  {
    'mason-org/mason.nvim',
    lazy = false,
    opts = { ui = { border = 'rounded' }, max_concurrent_installers = 3 },
  },
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    dependencies = {
      'mason-org/mason.nvim',
      'saghen/blink.cmp',
    },
    config = setup_lsp,
  },
  {
    'mason-org/mason-lspconfig.nvim',
    cond = function() return #vim.api.nvim_list_uis() > 0 or vim.env.CARLOSVTS_HEADLESS_INSTALL == '1' end,
    event = 'BufReadPre',
    cmd = { 'LspInstall', 'LspUninstall' },
    dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig' },
    opts = { ensure_installed = {}, automatic_enable = false },
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    lazy = false,
    cond = function() return #vim.api.nvim_list_uis() > 0 or vim.env.CARLOSVTS_HEADLESS_INSTALL == '1' end,
    dependencies = { 'mason-org/mason.nvim' },
    init = function()
      vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
          vim.defer_fn(function()
            if #vim.api.nvim_list_uis() > 0 then pcall(require('mason-tool-installer').check_install) end
          end, 3000)
        end,
      })
    end,
    opts = { ensure_installed = mason_tools, run_on_start = false, debounce_hours = 24 },
  },
  {
    'stevearc/conform.nvim',
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>cf',
        function()
          if vim.b.carlosvts_bigfile then
            vim.notify('Formatting is disabled for large files.', vim.log.levels.WARN)
            return
          end
          require('conform').format { async = true, timeout_ms = 5000, lsp_format = 'never' }
        end,
        mode = { 'n', 'x' },
        desc = 'Format explicitly',
      },
    },
    opts = {
      notify_on_error = true,
      notify_no_formatters = true,
      formatters_by_ft = {
        python = { 'ruff_organize_imports', 'ruff_format' },
        c = { 'clang_format' },
        cpp = { 'clang_format' },
        lua = { 'stylua' },
        json = { 'prettier' },
        jsonc = { 'prettier' },
        yaml = { 'prettier' },
        markdown = { 'prettier' },
        toml = { 'taplo' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
      },
    },
  },
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufWritePost', 'InsertLeave' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = { python = { 'ruff' }, markdown = { 'markdownlint-cli2' }, sh = { 'shellcheck' }, bash = { 'shellcheck' } }
      local timer = vim.uv.new_timer()
      local function run(buf)
        if not vim.api.nvim_buf_is_valid(buf) or vim.b[buf].carlosvts_bigfile then return end
        timer:stop()
        timer:start(
          250,
          0,
          vim.schedule_wrap(function()
            if vim.api.nvim_buf_is_valid(buf) then lint.try_lint(nil, { cwd = require('carlosvts.project').get() }) end
          end)
        )
      end
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
        group = vim.api.nvim_create_augroup('CarlosvtsLint', { clear = true }),
        callback = function(args) run(args.buf) end,
      })
      vim.api.nvim_create_user_command('Lint', function() run(vim.api.nvim_get_current_buf()) end, { desc = 'Lint current buffer' })
    end,
  },
}
