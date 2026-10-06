local M = {}

local function map(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc }) end

function M.setup()
  map({ 'n', 'i', 'v' }, '<C-s>', '<cmd>silent update<cr>', 'Save file')
  map('i', '<C-v>', '<C-r>+', 'Paste clipboard')
  map('x', '<C-c>', '"+y', 'Copy selection')
  map('n', 'x', '"_x', 'Delete character')
  map('n', 'X', '"_X', 'Delete previous character')
  map('x', 'p', 'P', 'Paste without replacing clipboard')
  map('n', '<Esc>', '<cmd>nohlsearch<cr><Esc>', 'Clear search highlight')
  map('n', '<M-j>', '<cmd>move .+1<cr>==', 'Move line down')
  map('n', '<M-k>', '<cmd>move .-2<cr>==', 'Move line up')
  map('x', '<M-j>', ":move '>+1<cr>gv=gv", 'Move selection down')
  map('x', '<M-k>', ":move '<-2<cr>gv=gv", 'Move selection up')

  for key, command in pairs { h = 'h', j = 'j', k = 'k', l = 'l' } do
    map('n', '<leader>' .. key, '<C-w>' .. command, 'Focus ' .. key)
  end
  map('n', '<leader>H', '<cmd>vertical resize -3<cr>', 'Decrease width')
  map('n', '<leader>L', '<cmd>vertical resize +3<cr>', 'Increase width')
  map('n', '<leader>J', '<cmd>resize +2<cr>', 'Increase height')
  map('n', '<leader>K', '<cmd>resize -2<cr>', 'Decrease height')
  map('n', '<leader>wv', '<cmd>vsplit<cr>', 'Vertical split')
  map('n', '<leader>ws', '<cmd>split<cr>', 'Horizontal split')
  for key, command in pairs { h = 'h', j = 'j', k = 'k', l = 'l' } do
    map('n', '<C-' .. key .. '>', '<C-w>' .. command, 'Focus ' .. key)
  end
  map('n', 'H', '<cmd>bprevious<cr>', 'Previous buffer')
  map('n', 'L', '<cmd>bnext<cr>', 'Next buffer')
  map('n', '[b', '<cmd>bprevious<cr>', 'Previous buffer')
  map('n', ']b', '<cmd>bnext<cr>', 'Next buffer')

  map('n', ']d', function() vim.diagnostic.jump { count = 1, float = true } end, 'Next diagnostic')
  map('n', '[d', function() vim.diagnostic.jump { count = -1, float = true } end, 'Previous diagnostic')

  map('t', '<Esc><Esc>', [[<C-\><C-n>]], 'Exit terminal mode')
  map('t', '<C-q>', [[<C-\><C-n><cmd>bdelete!<cr>]], 'Close terminal')
  for key, command in pairs { h = 'h', j = 'j', k = 'k', l = 'l' } do
    map('t', '<C-' .. key .. '>', '<C-\\><C-n><C-w>' .. command, 'Focus ' .. key)
  end
  for _, lhs in ipairs { '<C-/>', '<C-_>' } do
    map({ 'n', 't' }, lhs, function() require('carlosvts.terminal').toggle() end, 'Toggle floating terminal')
  end
  map('n', '<leader>tf', function() require('carlosvts.terminal').toggle(1) end, 'Floating terminal 1')
  for id = 1, 3 do
    map('n', '<leader>t' .. id, function() require('carlosvts.terminal').toggle(id) end, 'Floating terminal ' .. id)
  end
  map('n', '<leader>r', function() require('carlosvts.run').run() end, 'Run current file')
  map('n', '<leader>tt', '<cmd>botright 15split | terminal<cr>', 'Terminal (bottom split)')

  map('n', ']x', [[/^<<<<<<<\|^=======\|^>>>>>>><cr>]], 'Next conflict marker')
  map('n', '[x', [[?^<<<<<<<\|^=======\|^>>>>>>><cr>]], 'Previous conflict marker')
end

return M
