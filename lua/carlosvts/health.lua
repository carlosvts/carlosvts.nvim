local M = {}

local executables = {
  required = { 'git', 'rg', 'fd', 'fzf' },
  optional = { 'bat', 'delta', 'lazygit', 'node', 'npm', 'python3', 'python', 'cmake', 'make' },
  lsp = {
    'basedpyright-langserver',
    'lua-language-server',
    'cmake-language-server',
    'vscode-json-language-server',
    'yaml-language-server',
    'taplo',
    'marksman',
    'bash-language-server',
    'docker-langserver',
    'docker-compose-langserver',
    'terraform-ls',
  },
  formatters = { 'ruff', 'stylua', 'prettier', 'taplo', 'shfmt' },
  linters = { 'ruff', 'markdownlint-cli2', 'shellcheck' },
  debug = { 'debugpy-adapter' },
}

local function check_bin(name, required)
  if vim.fn.executable(name) == 1 then
    vim.health.ok(('%s: %s'):format(name, vim.fn.exepath(name)))
  elseif required then
    vim.health.error(name .. ' is missing')
  else
    vim.health.warn(name .. ' is missing')
  end
end

function M.check()
  vim.health.start 'carlosvts.nvim'
  if vim.fn.has 'nvim-0.12' == 1 then
    vim.health.ok 'Neovim >= 0.12'
  else
    vim.health.error 'Neovim 0.12 or newer is required'
  end
  for _, name in ipairs(executables.required) do
    check_bin(name, true)
  end
  for _, name in ipairs(executables.optional) do
    check_bin(name, false)
  end

  vim.health.start 'Clipboard'
  if vim.fn.has 'clipboard' == 1 then
    vim.health.ok 'Clipboard provider available'
  else
    vim.health.warn 'No clipboard provider detected; run :checkhealth vim.provider'
  end

  vim.health.start 'Plugins'
  for _, module in ipairs { 'lazy', 'snacks', 'fzf-lua', 'neo-tree', 'nvim-treesitter', 'mason', 'blink.cmp' } do
    if pcall(require, module) then
      vim.health.ok(module)
    else
      vim.health.error(module .. ' is unavailable')
    end
  end

  for section, names in pairs { LSP = executables.lsp, Formatters = executables.formatters, Linters = executables.linters, Debug = executables.debug } do
    vim.health.start(section)
    for _, name in ipairs(names) do
      check_bin(name, false)
    end
  end

  if vim.fn.has 'win32' ~= 1 then
    vim.health.start 'Fedora C/C++'
    for _, name in ipairs { 'gcc', 'g++', 'clangd', 'clang-format', 'cmake', 'make', 'codelldb' } do
      check_bin(name, false)
    end
  else
    vim.health.start 'Windows'
    vim.health.ok 'clangd and codelldb are intentionally optional and are not installed automatically'
  end
end

return M
