local M = {}

---@class carlosvts.Term
---@field buf integer
---@field win? integer

---@type table<string|integer, carlosvts.Term>
local terms = {}

local function win_open(term) return term.win and vim.api.nvim_win_is_valid(term.win) end

local function hide(term)
  if win_open(term) then vim.api.nvim_win_hide(term.win) end
  term.win = nil
end

local function hide_all()
  for _, term in pairs(terms) do
    hide(term)
  end
end

---@param term carlosvts.Term
---@param title string
local function show(term, title)
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.8)
  term.win = vim.api.nvim_open_win(term.buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2) - 1,
    style = 'minimal',
    border = 'rounded',
    title = (' %s '):format(title),
    title_pos = 'center',
  })
end

local function new_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'hide'
  return buf
end

---Toggles the persistent floating shell number `id` (default 1).
---@param id? integer
function M.toggle(id)
  id = id or 1
  local term = terms[id]
  if term and win_open(term) then
    hide(term)
    return
  end
  hide_all()

  local created = not (term and vim.api.nvim_buf_is_valid(term.buf))
  if created then
    term = { buf = new_buf() }
    terms[id] = term
  end
  show(term, 'Terminal ' .. id)
  if created then vim.fn.jobstart(vim.o.shell, { term = true, cwd = require('carlosvts.project').get() }) end
  vim.cmd.startinsert()
end

---Runs `cmd` in a fresh floating terminal that stays open after the process exits.
---@param cmd string
---@param cwd string
function M.run(cmd, cwd)
  local previous = terms.run
  hide_all()
  if previous and vim.api.nvim_buf_is_valid(previous.buf) then pcall(vim.api.nvim_buf_delete, previous.buf, { force = true }) end

  local term = { buf = new_buf() }
  terms.run = term
  vim.b[term.buf].carlosvts_keep = true
  show(term, 'Run')
  vim.keymap.set('n', 'q', function() hide(term) end, { buffer = term.buf, silent = true, desc = 'Close run output' })
  vim.fn.jobstart({ vim.o.shell, '-c', cmd }, { term = true, cwd = cwd })
  vim.cmd.startinsert()
end

return M
