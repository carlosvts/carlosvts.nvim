local M = {}

function M.setup()
  local lazypath = vim.fs.joinpath(vim.fn.stdpath 'data', 'lazy', 'lazy.nvim')
  if not vim.uv.fs_stat(lazypath) then
    vim.notify('Installing lazy.nvim...', vim.log.levels.INFO)
    local result = vim
      .system({
        'git',
        'clone',
        '--filter=blob:none',
        '--branch=stable',
        'https://github.com/folke/lazy.nvim.git',
        lazypath,
      }, { text = true })
      :wait()
    if result.code ~= 0 then error('Unable to install lazy.nvim:\n' .. (result.stderr or 'unknown error')) end
  end
  vim.opt.runtimepath:prepend(lazypath)

  local specs = { require('carlosvts.theme').spec() }
  for _, module in ipairs { 'editor', 'coding', 'ui', 'debug' } do
    vim.list_extend(specs, require('carlosvts.plugins.' .. module))
  end

  require('lazy').setup(specs, {
    defaults = { lazy = true, version = false },
    install = { missing = true, colorscheme = { 'gruvbox', 'habamax' } },
    checker = { enabled = true, notify = true, frequency = 86400 },
    change_detection = { enabled = true, notify = false },
    lockfile = vim.fs.joinpath(vim.fn.stdpath 'config', 'lazy-lock.json'),
    performance = {
      rtp = { disabled_plugins = { 'gzip', 'netrwPlugin', 'tarPlugin', 'tohtml', 'tutor', 'zipPlugin' } },
    },
    ui = { border = 'rounded' },
  })
end

return M
