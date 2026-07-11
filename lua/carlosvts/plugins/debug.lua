local tools = require 'carlosvts.tools'
local project = require 'carlosvts.project'
local is_windows = vim.fn.has 'win32' == 1

return {
  {
    'mfussenegger/nvim-dap',
    keys = {
      { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Toggle breakpoint' },
      { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Condition: ') end, desc = 'Conditional breakpoint' },
      { '<leader>dc', function() require('dap').continue() end, desc = 'Continue or start' },
      { '<leader>dn', function() require('dap').step_over() end, desc = 'Step over' },
      { '<leader>di', function() require('dap').step_into() end, desc = 'Step into' },
      { '<leader>do', function() require('dap').step_out() end, desc = 'Step out' },
      { '<leader>dr', function() require('dap').repl.open() end, desc = 'Open REPL' },
      { '<leader>du', function() require('dapui').toggle() end, desc = 'Toggle DAP UI' },
      { '<leader>dt', function() require('dap').terminate() end, desc = 'Terminate session' },
    },
    dependencies = {
      'nvim-neotest/nvim-nio',
      {
        'rcarriga/nvim-dap-ui',
        config = function()
          local dap, dapui = require 'dap', require 'dapui'
          dapui.setup {}
          dap.listeners.before.attach.carlosvts = function() dapui.open() end
          dap.listeners.before.launch.carlosvts = function() dapui.open() end
          dap.listeners.before.event_terminated.carlosvts = function() dapui.close() end
          dap.listeners.before.event_exited.carlosvts = function() dapui.close() end
        end,
      },
      { 'mfussenegger/nvim-dap-python', ft = 'python', config = function() require('dap-python').setup(tools.python()) end },
    },
    config = function()
      if is_windows then return end
      local dap = require 'dap'
      local adapter = vim.fn.exepath 'codelldb'
      if adapter == '' then adapter = vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'bin', 'codelldb') end
      dap.adapters.codelldb = { type = 'server', port = '${port}', executable = { command = adapter, args = { '--port', '${port}' } } }
      dap.configurations.c = {
        {
          name = 'Launch executable',
          type = 'codelldb',
          request = 'launch',
          program = function() return vim.fn.input('Executable: ', project.get() .. '/', 'file') end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
      }
      dap.configurations.cpp = dap.configurations.c
    end,
  },
}
