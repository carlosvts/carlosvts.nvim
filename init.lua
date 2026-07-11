vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

if vim.fn.has 'nvim-0.12' ~= 1 then
  local version = vim.version()
  error(('carlosvts.nvim requires Neovim 0.12 or newer. Found: %d.%d.%d'):format(version.major, version.minor, version.patch))
end

require 'carlosvts'
