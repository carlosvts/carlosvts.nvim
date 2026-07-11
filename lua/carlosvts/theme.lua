local M = {
  repository = 'ellisonleao/gruvbox.nvim',
  colorscheme = 'gruvbox',
  variant = 'dark',
  options = {
    contrast = 'hard',
    transparent_mode = false,
    terminal_colors = true,
    dim_inactive = false,
  },
  overrides = {},
}

---@return LazySpec
function M.spec()
  return {
    M.repository,
    lazy = false,
    priority = 1000,
    config = function()
      vim.opt.background = M.variant
      local module = M.repository:match '/([^/]+)%.nvim$' or M.colorscheme
      local ok, theme = pcall(require, module)
      if ok and type(theme.setup) == 'function' then
        local opts = vim.tbl_deep_extend('force', vim.deepcopy(M.options), { overrides = M.overrides })
        theme.setup(opts)
      end
      vim.cmd.colorscheme(M.colorscheme)
    end,
  }
end

return M
