local project = require 'carlosvts.project'

return {
  { 'nvim-lua/plenary.nvim', lazy = true },
  { 'nvim-tree/nvim-web-devicons', lazy = true },
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = { preset = 'helix', delay = 350, icons = { mappings = true } },
    config = function(_, opts)
      local wk = require 'which-key'
      wk.setup(opts)
      wk.add {
        { '<leader>b', group = 'Buffers' },
        { '<leader>c', group = 'Code' },
        { '<leader>d', group = 'Debug' },
        { '<leader>f', group = 'Find' },
        { '<leader>g', group = 'Git' },
        { '<leader>m', group = 'Markdown' },
        { '<leader>w', group = 'Windows' },
        { '<leader>x', group = 'Diagnostics' },
      }
    end,
  },
  {
    'ibhagwan/fzf-lua',
    cmd = 'FzfLua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = { 'fzf-native', winopts = { border = 'rounded', preview = { border = 'border' } } },
    keys = {
      { '<leader>ff', function() require('fzf-lua').files { cwd = project.get() } end, desc = 'Workspace files' },
      { '<leader>fg', function() require('fzf-lua').live_grep { cwd = project.get() } end, desc = 'Workspace grep' },
      { '<leader>fb', function() require('fzf-lua').buffers() end, desc = 'Buffers' },
      { '<leader>bb', function() require('fzf-lua').buffers() end, desc = 'Buffers' },
      {
        '<leader>fr',
        function() require('fzf-lua').oldfiles { cwd = project.get(), cwd_only = true, stat_file = true } end,
        desc = 'Recent workspace files',
      },
      { '<leader>fs', function() require('fzf-lua').lsp_document_symbols() end, desc = 'Document symbols' },
      { '<leader>fS', function() require('fzf-lua').lsp_live_workspace_symbols() end, desc = 'Workspace symbols' },
      { '<leader>fc', function() require('fzf-lua').commands() end, desc = 'Commands' },
      { '<leader>fh', function() require('fzf-lua').helptags() end, desc = 'Help tags' },
      { '<leader>fd', function() require('fzf-lua').diagnostics_document() end, desc = 'Diagnostics' },
      { '<leader>fD', function() require('fzf-lua').diagnostics_workspace() end, desc = 'Workspace diagnostics' },
      { '<leader>fp', function() project.pick() end, desc = 'Switch project' },
    },
  },
  {
    'MagicDuck/grug-far.nvim',
    cmd = 'GrugFar',
    opts = {},
    keys = {
      {
        '<leader>fR',
        function() require('grug-far').open { transient = true, prefills = { paths = project.get() } } end,
        desc = 'Search and replace in workspace',
      },
      {
        '<leader>fR',
        function() require('grug-far').with_visual_selection { transient = true, prefills = { paths = project.get() } } end,
        mode = 'x',
        desc = 'Search and replace selection',
      },
    },
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    cmd = 'Neotree',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons', 'MunifTanjim/nui.nvim' },
    keys = {
      {
        '<leader>e',
        function() require('neo-tree.command').execute { toggle = true, dir = project.get(), reveal = true, position = 'left' } end,
        desc = 'Workspace explorer',
      },
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = 'rounded',
      filesystem = {
        bind_to_cwd = false,
        cwd_target = { sidebar = 'none', current = 'none' },
        follow_current_file = { enabled = true, leave_dirs_open = false },
        filtered_items = {
          visible = false,
          hide_dotfiles = true,
          hide_gitignored = true,
          hide_by_name = { '.git', '__pycache__', '.pytest_cache', '.mypy_cache', '.ruff_cache', '.venv', 'venv', 'node_modules', 'build', 'dist', '.cache' },
          never_show = { '.DS_Store' },
        },
        window = {
          mappings = {
            ['H'] = 'toggle_hidden',
            ['I'] = 'toggle_gitignore',
          },
        },
      },
      default_component_configs = { indent = { with_expanders = true }, git_status = { symbols = { unstaged = 'M', staged = 'S' } } },
      window = { position = 'left', width = 34 },
    },
  },
  {
    'echasnovski/mini.nvim',
    version = false,
    event = 'VeryLazy',
    config = function()
      require('mini.ai').setup { n_lines = 300 }
      require('mini.surround').setup()
      require('mini.pairs').setup()
      require('mini.bufremove').setup()
      vim.keymap.set('n', '<leader>bd', function()
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.bo[bufnr].modified then
          local answer = vim.fn.confirm('Buffer has unsaved changes. Discard them?', '&No\n&Yes', 1)
          if answer ~= 2 then return end
        end
        require('mini.bufremove').delete(bufnr, vim.bo[bufnr].modified)
      end, { desc = 'Delete buffer safely' })
    end,
  },
}
