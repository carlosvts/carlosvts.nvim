local M = {}

local esc = vim.fn.shellescape

---@param name string
---@return boolean
local function has(name) return vim.fn.executable(name) == 1 end

---@param ctx { file: string, dir: string, stem: string, out: string, args: string, root?: string }
---@return string? command, string? cwd, string? missing
local runners = {
  c = function(c)
    local cc = has 'gcc' and 'gcc' or has 'clang' and 'clang' or nil
    if not cc then return nil, nil, 'gcc or clang' end
    return ('%s -Wall -Wextra -g %s -o %s && %s'):format(cc, esc(c.file), esc(c.out), esc(c.out) .. c.args), c.dir
  end,
  cpp = function(c)
    local cxx = has 'g++' and 'g++' or has 'clang++' and 'clang++' or nil
    if not cxx then return nil, nil, 'g++ or clang++' end
    return ('%s -std=c++23 -Wall -Wextra -g %s -o %s && %s'):format(cxx, esc(c.file), esc(c.out), esc(c.out) .. c.args), c.dir
  end,
  python = function(c)
    local py = has 'python3' and 'python3' or has 'python' and 'python' or nil
    if not py then return nil, nil, 'python3' end
    return ('%s %s%s'):format(py, esc(c.file), c.args), c.dir
  end,
  lua = function(c) return ('nvim -l %s%s'):format(esc(c.file), c.args), c.dir end,
  go = function(c)
    if not has 'go' then return nil, nil, 'go' end
    return ('go run %s%s'):format(esc(c.file), c.args), c.dir
  end,
  javascript = function(c)
    if not has 'node' then return nil, nil, 'node' end
    return ('node %s%s'):format(esc(c.file), c.args), c.dir
  end,
  java = function(c)
    if not has 'java' then return nil, nil, 'java' end
    return ('java %s%s'):format(esc(c.file), c.args), c.dir
  end,
  sh = function(c) return ('bash %s%s'):format(esc(c.file), c.args), c.dir end,
  rust = function(c)
    if c.root and has 'cargo' then return 'cargo run' .. (c.args ~= '' and ' --' .. c.args or ''), c.root end
    if not has 'rustc' then return nil, nil, 'rustc/cargo' end
    return ('rustc -g %s -o %s && %s'):format(esc(c.file), esc(c.out), esc(c.out) .. c.args), c.dir
  end,
}

local last_args = {}

---@param args string
local function execute(args)
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local runner = runners[vim.bo[buf].filetype]
  if file == '' or vim.bo[buf].buftype ~= '' then
    vim.notify('Run: save the file first.', vim.log.levels.WARN)
    return
  end
  if not runner then
    vim.notify(('Run: no runner for filetype "%s".'):format(vim.bo[buf].filetype), vim.log.levels.WARN)
    return
  end
  if vim.bo[buf].modified then vim.cmd 'silent update' end

  local out_dir = vim.fs.joinpath(vim.fn.stdpath 'cache', 'run')
  vim.fn.mkdir(out_dir, 'p')
  local stem = vim.fn.fnamemodify(file, ':t:r')
  local command, cwd, missing = runner {
    file = file,
    dir = vim.fs.dirname(file),
    stem = stem,
    out = vim.fs.joinpath(out_dir, stem),
    args = args ~= '' and ' ' .. args or '',
    root = vim.fs.root(buf, 'Cargo.toml'),
  }
  if not command then
    vim.notify(('Run: %s not found in PATH.'):format(missing), vim.log.levels.ERROR)
    return
  end
  require('carlosvts.terminal').run(command, cwd)
end

---Runs the current file with no arguments.
function M.run() execute '' end

---Prompts for arguments (raw shell text, so `< input.txt` works as stdin) and runs the current file.
function M.run_with_args()
  local file = vim.api.nvim_buf_get_name(0)
  vim.ui.input({ prompt = 'Run args: ', default = last_args[file] or '' }, function(input)
    if input == nil then return end
    last_args[file] = input
    execute(vim.trim(input))
  end)
end

return M
