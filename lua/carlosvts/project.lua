local M = {}

local workspace = vim.fs.normalize(vim.uv.cwd() or vim.fn.getcwd())
local noisy = { '.git', '.venv', 'venv', 'node_modules', '__pycache__', '.cache', 'build', 'dist' }

function M.get() return workspace end

function M.setup() vim.g.carlosvts_workspace = workspace end

function M.noisy_dirs() return vim.deepcopy(noisy) end

---@param path string
---@return boolean, string?
function M.switch(path)
  path = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(path), ':p'))
  if vim.fn.isdirectory(path) ~= 1 then return false, ('Not a directory: %s'):format(path) end

  workspace = path
  vim.g.carlosvts_workspace = workspace
  vim.cmd.cd(vim.fn.fnameescape(path))
  vim.api.nvim_exec_autocmds('User', { pattern = 'CarlosvtsWorkspaceChanged', data = { path = path } })
  pcall(function()
    local state = require('neo-tree.sources.manager').get_state 'filesystem'
    if state and state.winid and vim.api.nvim_win_is_valid(state.winid) then
      require('neo-tree.command').execute { action = 'show', dir = path, reveal = true }
    end
  end)
  require('carlosvts.tools').configure_make()
  pcall(function() require('dap-python').setup(require('carlosvts.tools').python(path)) end)
  vim.notify(('Workspace: %s'):format(path), vim.log.levels.INFO)
  return true
end

local function fd_command(root)
  local excludes = {}
  for _, dir in ipairs(noisy) do
    vim.list_extend(excludes, { '--exclude', dir })
  end
  return vim.list_extend({ 'fd', '--type', 'd', '--hidden', '--absolute-path', '.', root }, excludes)
end

---@param root? string
function M.pick(root)
  local function open_picker(search_root)
    search_root = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(search_root), ':p'))
    if vim.fn.executable 'fd' ~= 1 then
      vim.notify('Project picker requires fd. Install it or use :ProjectSwitch.', vim.log.levels.WARN)
      return
    end
    vim.system(fd_command(search_root), { text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          vim.notify(result.stderr, vim.log.levels.ERROR)
          return
        end
        local dirs = vim.split(vim.trim(result.stdout), '\n', { trimempty = true })
        require('fzf-lua').fzf_exec(dirs, {
          prompt = 'Projects> ',
          actions = {
            ['default'] = function(selected)
              if selected and selected[1] then M.switch(selected[1]) end
            end,
          },
        })
      end)
    end)
  end

  if root then
    open_picker(root)
    return
  end
  vim.ui.input({ prompt = 'Project search root: ', default = vim.uv.os_homedir() }, function(input)
    if input and input ~= '' then open_picker(input) end
  end)
end

return M
