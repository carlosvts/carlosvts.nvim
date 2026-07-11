local M = {}

local is_windows = vim.fn.has 'win32' == 1

M.treesitter_parsers = {
  'bash',
  'c',
  'cmake',
  'comment',
  'cpp',
  'css',
  'diff',
  'dockerfile',
  'git_config',
  'git_rebase',
  'gitattributes',
  'gitcommit',
  'gitignore',
  'html',
  'json',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'python',
  'query',
  'regex',
  'toml',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
  'terraform',
  'hcl',
}

---@param root? string
---@return string
function M.python(root)
  root = root or require('carlosvts.project').get()
  local candidates = {}
  if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= '' then
    candidates[#candidates + 1] = vim.fs.joinpath(vim.env.VIRTUAL_ENV, is_windows and 'Scripts/python.exe' or 'bin/python')
  end
  for _, name in ipairs { '.venv', 'venv' } do
    candidates[#candidates + 1] = vim.fs.joinpath(root, name, is_windows and 'Scripts/python.exe' or 'bin/python')
  end
  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then return candidate end
  end
  for _, executable in ipairs(is_windows and { 'python', 'python3' } or { 'python3', 'python' }) do
    if vim.fn.executable(executable) == 1 then return vim.fn.exepath(executable) end
  end
  return is_windows and 'python' or 'python3'
end

function M.configure_make()
  local root = require('carlosvts.project').get()
  local makeprg = 'make'
  if vim.fn.filereadable(vim.fs.joinpath(root, 'Makefile')) == 1 then
    makeprg = 'make'
  elseif vim.fn.filereadable(vim.fs.joinpath(root, 'CMakeLists.txt')) == 1 then
    local build = vim.fs.joinpath(root, 'build')
    makeprg = vim.fn.isdirectory(build) == 1 and ('cmake --build %s'):format(vim.fn.shellescape(build)) or 'cmake --build build'
  elseif
    vim.fn.filereadable(vim.fs.joinpath(root, 'pyproject.toml')) == 1
    or vim.fn.filereadable(vim.fs.joinpath(root, 'pytest.ini')) == 1
    or vim.fn.isdirectory(vim.fs.joinpath(root, 'tests')) == 1
  then
    makeprg = vim.fn.shellescape(M.python(root)) .. ' -m pytest --tb=short -q'
  end
  vim.opt.makeprg = makeprg
  vim.opt.errorformat = table.concat({
    '%f:%l:%c: %trror: %m',
    '%f:%l:%c: %tarning: %m',
    '%f:%l: %trror: %m',
    '%f:%l: %tarning: %m',
    '%E%f:%l: in %m',
    '%E%f:%l: %m',
    [[%C%\s%#%m]],
    '%-G%.%#',
  }, ',')
end

return M
