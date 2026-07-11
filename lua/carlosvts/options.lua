local M = {}

function M.setup()
  local opt = vim.opt
  opt.number = true
  opt.relativenumber = true
  opt.cursorcolumn = true
  opt.cursorline = false
  opt.signcolumn = 'yes'
  opt.termguicolors = true
  opt.background = 'dark'
  opt.mouse = 'a'
  opt.clipboard = 'unnamedplus'
  opt.confirm = true
  opt.splitright = true
  opt.splitbelow = true
  opt.scrolloff = 8
  opt.sidescrolloff = 8
  opt.updatetime = 200
  opt.timeoutlen = 400
  opt.undofile = true
  opt.swapfile = true
  opt.directory = vim.fn.stdpath 'state' .. '/swap//'
  opt.undodir = vim.fn.stdpath 'state' .. '/undo//'
  opt.backup = false
  opt.writebackup = true
  opt.ignorecase = true
  opt.smartcase = true
  opt.incsearch = true
  opt.hlsearch = true
  opt.inccommand = 'split'
  opt.wrap = false
  opt.breakindent = true
  opt.linebreak = true
  opt.expandtab = true
  opt.shiftwidth = 2
  opt.tabstop = 2
  opt.softtabstop = 2
  opt.smartindent = true
  opt.completeopt = { 'menu', 'menuone', 'noselect' }
  opt.shortmess:append 'I'
  opt.list = true
  opt.listchars = { tab = '  ', trail = '·', nbsp = '␣' }
  opt.fillchars:append { eob = ' ', fold = ' ' }
  opt.laststatus = 3
  opt.showmode = false
  opt.winborder = 'rounded'

  vim.fn.mkdir(vim.fn.stdpath 'state' .. '/swap', 'p')
  vim.fn.mkdir(vim.fn.stdpath 'state' .. '/undo', 'p')
end

return M
