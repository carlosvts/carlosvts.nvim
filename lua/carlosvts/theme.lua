local M = {}

---@class carlosvts.ThemeVariant
---@field colorscheme string
---@field background 'dark'|'light'

---@class carlosvts.ThemeFamily
---@field name string Lazy plugin name
---@field repository string
---@field variants carlosvts.ThemeVariant[]
---@field setup? fun()

local function dark(colorscheme) return { colorscheme = colorscheme, background = 'dark' } end
local function light(colorscheme) return { colorscheme = colorscheme, background = 'light' } end

M.default = 'gruvbox'

---@type carlosvts.ThemeFamily[]
M.families = {
  {
    name = 'gruvbox.nvim',
    repository = 'ellisonleao/gruvbox.nvim',
    variants = { dark 'gruvbox' },
    setup = function()
      require('gruvbox').setup {
        contrast = 'hard',
        transparent_mode = false,
        terminal_colors = true,
        dim_inactive = false,
        overrides = {},
      }
    end,
  },
  {
    name = 'catppuccin',
    repository = 'catppuccin/nvim',
    variants = { dark 'catppuccin-mocha', dark 'catppuccin-macchiato', dark 'catppuccin-frappe', light 'catppuccin-latte' },
    setup = function() require('catppuccin').setup { transparent_background = false } end,
  },
  {
    name = 'tokyonight.nvim',
    repository = 'folke/tokyonight.nvim',
    variants = { dark 'tokyonight-night', dark 'tokyonight-storm', dark 'tokyonight-moon', light 'tokyonight-day' },
    setup = function() require('tokyonight').setup { transparent = false } end,
  },
  {
    name = 'rose-pine',
    repository = 'rose-pine/neovim',
    variants = { dark 'rose-pine-main', dark 'rose-pine-moon', light 'rose-pine-dawn' },
    setup = function() require('rose-pine').setup { styles = { transparency = false } } end,
  },
  {
    name = 'kanagawa.nvim',
    repository = 'rebelot/kanagawa.nvim',
    variants = { dark 'kanagawa-wave', dark 'kanagawa-dragon', light 'kanagawa-lotus' },
    setup = function() require('kanagawa').setup { transparent = false } end,
  },
  {
    name = 'nightfox.nvim',
    repository = 'EdenEast/nightfox.nvim',
    variants = { dark 'nightfox', dark 'carbonfox', dark 'duskfox', dark 'terafox', light 'dayfox' },
    setup = function() require('nightfox').setup { options = { transparent = false } } end,
  },
}

local state_file = vim.fs.joinpath(vim.fn.stdpath 'state', 'carlosvts-theme.json')

---@param colorscheme string
---@return carlosvts.ThemeFamily?, carlosvts.ThemeVariant?
local function find(colorscheme)
  for _, family in ipairs(M.families) do
    for _, variant in ipairs(family.variants) do
      if variant.colorscheme == colorscheme then return family, variant end
    end
  end
end

---@return string
local function load_saved()
  local fd = io.open(state_file, 'r')
  if not fd then return M.default end
  local content = fd:read '*a'
  fd:close()
  local ok, data = pcall(vim.json.decode, content)
  if ok and type(data) == 'table' and type(data.colorscheme) == 'string' and find(data.colorscheme) then return data.colorscheme end
  return M.default
end

---@param colorscheme string
local function save(colorscheme)
  vim.fn.mkdir(vim.fs.dirname(state_file), 'p')
  local fd = io.open(state_file, 'w')
  if not fd then return end
  fd:write(vim.json.encode { colorscheme = colorscheme })
  fd:close()
end

M.colorscheme = load_saved()

---Applies a colorscheme (loading its plugin on demand) without persisting it.
---@param colorscheme string
---@return boolean
function M.apply(colorscheme)
  local family, variant = find(colorscheme)
  if not family or not variant then return false end
  pcall(function() require('lazy').load { plugins = { family.name } } end)
  vim.o.background = variant.background
  local ok, err = pcall(vim.cmd.colorscheme, colorscheme)
  if not ok then
    vim.notify(('Unable to apply %s: %s'):format(colorscheme, err), vim.log.levels.ERROR)
    return false
  end
  return true
end

---Applies and persists a colorscheme.
---@param colorscheme string
function M.set(colorscheme)
  if M.apply(colorscheme) then
    M.colorscheme = colorscheme
    save(colorscheme)
  end
end

function M.pick()
  local fzf = require 'fzf-lua'
  local shell = require 'fzf-lua.shell'
  local original, original_bg = M.colorscheme, vim.o.background

  local entries = {}
  for _, family in ipairs(M.families) do
    for _, variant in ipairs(family.variants) do
      if variant.colorscheme ~= M.colorscheme then table.insert(entries, variant.colorscheme) end
    end
  end
  table.insert(entries, 1, M.colorscheme)

  local previewed
  local opts = {
    prompt = 'Theme> ',
    winopts = {
      height = 0.45,
      width = 0.35,
      row = 0.4,
      preview = { hidden = false },
      on_close = function()
        if previewed and previewed ~= original then
          M.apply(original)
          vim.o.background = original_bg
        end
      end,
    },
    fzf_opts = { ['--preview-window'] = 'nohidden:right:0' },
    actions = {
      ['default'] = function(selected)
        if selected and selected[1] then
          previewed = nil
          M.set(selected[1])
        end
      end,
    },
  }
  opts.preview = shell.stringify_data(function(selected)
    if selected and selected[1] then
      previewed = selected[1]
      M.apply(selected[1])
    end
  end, opts, '{}')

  fzf.fzf_exec(entries, opts)
end

---@return LazySpec[]
function M.specs()
  local active = find(M.colorscheme)
  local specs = {}
  for _, family in ipairs(M.families) do
    local is_active = family == active
    table.insert(specs, {
      family.repository,
      name = family.name,
      lazy = not is_active,
      priority = is_active and 1000 or nil,
      config = function()
        if family.setup then family.setup() end
        if is_active and vim.g.colors_name == nil then M.apply(M.colorscheme) end
      end,
    })
  end
  return specs
end

return M
