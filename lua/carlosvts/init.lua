local M = {}

function M.setup()
  require('carlosvts.project').setup()
  require('carlosvts.options').setup()
  require('carlosvts.keymaps').setup()
  require('carlosvts.autocmds').setup()
  require('carlosvts.commands').setup()
  require('carlosvts.plugins').setup()
end

M.setup()

return M
