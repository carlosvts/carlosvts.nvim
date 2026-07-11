local M = {}

function M.setup()
  vim.api.nvim_create_user_command('ProjectSwitch', function(opts)
    local path = opts.args ~= '' and opts.args or vim.fn.getcwd()
    local ok, err = require('carlosvts.project').switch(path)
    if not ok then vim.notify(err, vim.log.levels.ERROR) end
  end, { nargs = '?', complete = 'dir', desc = 'Switch editor workspace' })

  vim.api.nvim_create_user_command(
    'ProjectFind',
    function(opts) require('carlosvts.project').pick(opts.args ~= '' and opts.args or nil) end,
    { nargs = '?', complete = 'dir', desc = 'Find a project under a directory' }
  )

  vim.api.nvim_create_user_command(
    'ConfigOpen',
    function() vim.cmd.tabedit(vim.fn.fnameescape(vim.fs.joinpath(vim.fn.stdpath 'config', 'init.lua'))) end,
    { desc = 'Open carlosvts.nvim in a new tab' }
  )

  vim.api.nvim_create_user_command('ConfigReload', function()
    require('carlosvts.options').setup()
    require('carlosvts.keymaps').setup()
    require('carlosvts.autocmds').setup()
    pcall(vim.cmd.colorscheme, require('carlosvts.theme').colorscheme)
    vim.notify('Core options and mappings reloaded. Restart Neovim for plugin specification changes.', vim.log.levels.INFO)
  end, { desc = 'Safely reload core configuration' })

  vim.api.nvim_create_user_command('ConfigHealth', function() vim.cmd.checkhealth 'carlosvts' end, { desc = 'Check carlosvts.nvim dependencies' })

  vim.api.nvim_create_user_command('ConfigUpdate', function()
    vim.notify('Updating plugins, parsers and Mason tools...', vim.log.levels.INFO)
    require('lazy').sync { wait = true, show = false }
    local ok_ts, task = pcall(function() return require('nvim-treesitter').update(require('carlosvts.tools').treesitter_parsers, { summary = true }) end)
    if ok_ts and task then task:wait(300000) end
    require('mason-registry').refresh(function()
      pcall(vim.cmd, 'MasonToolsUpdateSync')
      vim.schedule(function() vim.notify('Update complete. Review lazy-lock.json and restart Neovim.', vim.log.levels.INFO) end)
    end)
  end, { desc = 'Update plugins, parsers and editorial tools' })

  local function cmake(args, label)
    vim.system(args, { cwd = require('carlosvts.project').get(), text = true }, function(result)
      vim.schedule(function()
        local lines = vim.split((result.stdout or '') .. (result.stderr or ''), '\n', { trimempty = true })
        vim.fn.setqflist({}, 'r', { title = label, lines = lines, efm = vim.o.errorformat })
        if result.code == 0 then
          vim.notify(label .. ' completed.', vim.log.levels.INFO)
        else
          vim.cmd.copen()
        end
      end)
    end)
  end

  vim.api.nvim_create_user_command('CMakeConfigure', function()
    local root = require('carlosvts.project').get()
    cmake({ 'cmake', '-S', root, '-B', vim.fs.joinpath(root, 'build') }, 'CMake configure')
  end, { desc = 'Configure the workspace CMake build directory' })

  vim.api.nvim_create_user_command('CMakeBuild', function()
    local root = require('carlosvts.project').get()
    cmake({ 'cmake', '--build', vim.fs.joinpath(root, 'build') }, 'CMake build')
  end, { desc = 'Build the workspace CMake build directory' })
end

return M
