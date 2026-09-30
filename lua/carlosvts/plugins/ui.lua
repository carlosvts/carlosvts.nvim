local project = require 'carlosvts.project'

local function safe_delete(bufnr)
  if vim.bo[bufnr].modified and vim.fn.confirm('Discard unsaved changes?', '&No\n&Yes', 1) ~= 2 then return end
  require('mini.bufremove').delete(bufnr, vim.bo[bufnr].modified)
end

local function lsp_names()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients { bufnr = 0 }) do
    names[#names + 1] = client.name
  end
  return table.concat(names, ',')
end

return {
  {
    'folke/snacks.nvim',
    priority = 900,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true, size = 1024 * 1024, line_length = 10000 },
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = ' ', key = 'f', desc = 'Find File', action = function() require('fzf-lua').files { cwd = project.get() } end },
            { icon = ' ', key = 'g', desc = 'Find Text', action = function() require('fzf-lua').live_grep { cwd = project.get() } end },
            {
              icon = ' ',
              key = 'r',
              desc = 'Recent Files',
              action = function() require('fzf-lua').oldfiles { cwd = project.get(), cwd_only = true, stat_file = true } end,
            },
            { icon = ' ', key = 'p', desc = 'Switch Project', action = function() project.pick() end },
            {
              icon = ' ',
              key = 'e',
              desc = 'File Explorer',
              action = function() require('neo-tree.command').execute { toggle = true, dir = project.get(), reveal = true, position = 'left' } end,
            },
            {
              icon = ' ',
              key = 'R',
              desc = 'Search & Replace',
              action = function() require('grug-far').open { transient = true, prefills = { paths = project.get() } } end,
            },
            { icon = ' ', key = 'G', desc = 'LazyGit', action = function() Snacks.lazygit { cwd = project.get() } end },
            { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
            { icon = ' ', key = 'c', desc = 'Edit Config', action = ':ConfigOpen' },
            { icon = '󰒲 ', key = 'L', desc = 'Lazy', action = ':Lazy' },
            { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
          },
        },
        sections = {
          { section = 'header' },
          { section = 'keys', gap = 1, padding = 1 },
          { icon = ' ', title = 'Recent Files', section = 'recent_files', cwd = project.get(), limit = 6, indent = 2, padding = 1 },
          { section = 'startup' },
        },
      },
      notifier = { enabled = true, timeout = 2500, style = 'compact', top_down = false },
      quickfile = { enabled = true },
      explorer = { enabled = false },
      git = { enabled = false },
      gitbrowse = { enabled = false },
      image = { enabled = false },
      indent = { enabled = false },
      input = { enabled = false },
      picker = { enabled = false },
      profiler = { enabled = false },
      rename = { enabled = false },
      scope = { enabled = false },
      scratch = { enabled = false },
      scroll = { enabled = false },
      statuscolumn = { enabled = false },
      terminal = { enabled = false },
      toggle = { enabled = false },
      words = { enabled = false },
      zen = { enabled = false },
    },
    keys = { { '<leader>gg', function() Snacks.lazygit { cwd = project.get() } end, desc = 'LazyGit' } },
    config = function(_, opts)
      require('snacks').setup(opts)
      vim.notify = Snacks.notifier.notify
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    event = 'UIEnter',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = { theme = 'gruvbox', globalstatus = true, component_separators = '', section_separators = '' },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { { 'filename', path = 1, symbols = { modified = ' ●', readonly = ' ' } } },
        lualine_x = {
          { lsp_names, icon = ' ', cond = function() return #vim.lsp.get_clients { bufnr = 0 } > 0 end },
          'filetype',
          { 'encoding', cond = function() return vim.bo.fileencoding ~= '' and vim.bo.fileencoding ~= 'utf-8' end },
        },
        lualine_y = { 'location' },
        lualine_z = { 'progress' },
      },
      extensions = { 'lazy', 'neo-tree', 'quickfix' },
    },
  },
  {
    'akinsho/bufferline.nvim',
    version = '*',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons', 'echasnovski/mini.nvim' },
    opts = {
      options = {
        always_show_bufferline = false,
        diagnostics = 'nvim_lsp',
        separator_style = 'thin',
        show_close_icon = false,
        close_command = safe_delete,
        right_mouse_command = safe_delete,
        offsets = { { filetype = 'neo-tree', text = 'Workspace', separator = true } },
      },
    },
    keys = (function()
      local keys = { { '<leader>bp', function() require('bufferline').pick() end, desc = 'Pick buffer (letter overlay)' } }
      for i = 1, 9 do
        keys[#keys + 1] = { '<leader>b' .. i, function() require('bufferline').go_to(i, true) end, desc = 'Go to buffer ' .. i }
      end
      return keys
    end)(),
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      indent = { char = '│', highlight = 'IblIndent' },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = { filetypes = { 'dashboard', 'help', 'lazy', 'neo-tree', 'terminal' }, buftypes = { 'nofile', 'quickfix', 'terminal' } },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = { add = { text = '│' }, change = { text = '│' }, delete = { text = '_' }, topdelete = { text = '‾' }, changedelete = { text = '~' } },
      current_line_blame = false,
      on_attach = function(bufnr)
        local gs = require 'gitsigns'
        local function map(lhs, rhs, desc, mode) vim.keymap.set(mode or 'n', lhs, rhs, { buffer = bufnr, desc = desc }) end
        map(']g', function()
          if vim.wo.diff then return ']g' end
          vim.schedule(function() gs.nav_hunk 'next' end)
          return '<Ignore>'
        end, 'Next hunk', { 'n', 'x' })
        map('[g', function()
          if vim.wo.diff then return '[g' end
          vim.schedule(function() gs.nav_hunk 'prev' end)
          return '<Ignore>'
        end, 'Previous hunk', { 'n', 'x' })
        map('<leader>gp', gs.preview_hunk, 'Preview hunk')
        map('<leader>gs', gs.stage_hunk, 'Stage hunk', { 'n', 'x' })
        map('<leader>gr', gs.reset_hunk, 'Reset hunk', { 'n', 'x' })
        map('<leader>gd', gs.diffthis, 'Diff file')
        map('<leader>gb', gs.blame_line, 'Blame line')
      end,
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = { enabled = false, render_modes = { 'n', 'c' }, completions = { blink = { enabled = true } } },
    keys = { { '<leader>mr', '<cmd>RenderMarkdown toggle<cr>', desc = 'Toggle rendered Markdown', ft = 'markdown' } },
  },
  {
    'iamcco/markdown-preview.nvim',
    ft = 'markdown',
    build = 'npm install --prefix app',
    init = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_command_for_global = 0
      vim.g.mkdp_preview_options = { sync_scroll_type = 'middle', disable_sync_scroll = 0, disable_filename = 0 }
    end,
    keys = { { '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', desc = 'Toggle browser preview', ft = 'markdown' } },
  },
}
