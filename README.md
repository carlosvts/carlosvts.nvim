# carlosvts.nvim

Uma IDE discreta, escalável e _batteries included_, construída diretamente com Neovim, Lua e plugins individuais. A configuração não deriva de nenhuma distribuição e não restaura sessões, não salva ou formata automaticamente, não abre terminais e não altera o diretório por causa de Git ou LSP.

## Requisitos

- Neovim 0.12 ou mais recente.
- Git, uma Nerd Font (recomendado: JetBrainsMono Nerd Font), `rg`, `fd` e `fzf`.
- Node.js/npm para ferramentas de linguagem e para o preview Markdown.
- Python 3 para Python, debugpy e pytest.
- `bat`, `delta` e LazyGit são recomendados.
- O Treesitter atual requer `tree-sitter-cli` 0.26.1+, `curl`, `tar` e um compilador C.

A configuração interrompe cedo com uma mensagem clara em versões antigas. Execute `:ConfigHealth` para ver ferramentas ausentes.

## Instalação Fedora

Clone este repositório em um diretório permanente e execute:

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

O script detecta Fedora/dnf, instala somente binários ausentes, verifica Neovim 0.12, cria um backup `~/.config/nvim.backup-AAAA-MM-DD-HHMMSS`, cria um symlink e sincroniza Lazy, Treesitter e Mason. Se o repositório já for a configuração ativa, ele não move nem recria o link.

## Instalação Windows

Em PowerShell nativo, dentro do clone:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\install.ps1
```

O script confirma cada ID com `winget show`, instala somente o que não está no `PATH`, cria backup em `%LOCALAPPDATA%\nvim.backup-AAAA-MM-DD-HHMMSS` e usa uma junction. Não instala MSYS2, MinGW, Clang, MSVC, CMake ou codelldb.

O `nvim-treesitter` atual exige compilador. Como esta configuração deliberadamente não instala toolchain C/C++ no Windows, a instalação de parsers pode avisar e continuar. Parsers já presentes continuam utilizáveis; para o conjunto completo, o usuário precisa fornecer voluntariamente um compilador compatível. Essa é a principal diferença inevitável entre as plataformas.

## Estrutura

```text
init.lua                         barreira de versão e entrada
lua/carlosvts/options.lua        opções globais
lua/carlosvts/keymaps.lua        atalhos independentes de plugins
lua/carlosvts/autocmds.lua       modo, LSP, arquivos grandes e quickfix
lua/carlosvts/commands.lua       comandos públicos
lua/carlosvts/project.lua        workspace editorial e troca de projeto
lua/carlosvts/tools.lua          Python, parsers e :make
lua/carlosvts/theme.lua          identidade visual completa
lua/carlosvts/health.lua         :ConfigHealth
lua/carlosvts/plugins/*.lua      specs por domínio
scripts/                         instalação idempotente
lazy-lock.json                   revisões reproduzíveis
```

## Workspace

O diretório capturado por `vim.uv.cwd()` no início é o **workspace editorial**. Neo-tree, arquivos, grep, recentes e `:make` usam sempre esse valor. `nvim .` inicia em um buffer genérico vazio, sem dashboard ou menu sobreposto. Nenhum marcador Git, Python ou CMake o substitui silenciosamente.

Cada servidor LSP continua usando a configuração e os `root_markers` fornecidos pelo `nvim-lspconfig`. Portanto:

```text
workspace do editor = diretório de onde o Neovim foi iniciado
root do LSP         = raiz detectada por cada servidor
```

Use `<leader>fp`, `:ProjectFind [raiz-de-busca]` ou `:ProjectSwitch [path]`. A troca executa `:cd`, atualiza Neo-tree, pickers, Python e `:make`, mas não fecha buffers, abre arquivos ou restaura sessão.

## Atalhos principais

| Atalho | Ação |
|---|---|
| `<leader>e` | alternar Neo-tree no workspace |
| `<leader>ff` / `<leader>fg` | arquivos / grep no workspace |
| `<leader>fb`, `<leader>bb` | buffers |
| `<leader>fr` | recentes do workspace |
| `<leader>fs` / `<leader>fS` | símbolos do documento / workspace |
| `<leader>fc`, `<leader>fh`, `<leader>fd` | comandos, ajuda, diagnósticos |
| `<leader>fp` | trocar projeto |
| `<leader>h/j/k/l` | focar split |
| `<leader>H/L/J/K` | redimensionar split |
| `<leader>wv` / `<leader>ws` | split vertical / horizontal |
| `[b` / `]b` | buffer anterior / seguinte |
| `<leader>bd` | remover buffer com confirmação |
| `<C-s>` | salvar explicitamente |
| `Alt+j` / `Alt+k` | mover linha ou seleção mantendo indentação |
| `gd`, `gD`, `gr`, `gi` | definição, declaração, referências, implementação |
| `K`, `F2` | hover, renomear símbolo |
| `<leader>ca`, `<leader>cd` | code action, diagnóstico da linha |
| `<leader>cf` | formatar arquivo ou seleção explicitamente |
| `<leader>gg` | abrir LazyGit |
| `]g` / `[g` | navegar hunks Git |
| `<leader>gp/gs/gr/gd/gb` | preview, stage, reset, diff, blame |
| `<leader>db/dB/dc/dn/di/do` | breakpoints e controle do debugger |
| `<leader>dr/du/dt` | REPL, UI, encerrar debug |
| `<leader>mr` / `<leader>mp` | render interno / preview no navegador |
| `]x` / `[x` | navegar marcadores de conflito |

`y`, `d` e `p` usam o clipboard do sistema. `x`/`X` usam o black-hole register, e `p` visual preserva o clipboard. `<C-v>` permanece Visual Block no modo normal; em insert cola o clipboard. `gc`/`gcc` são os comentários nativos do Neovim 0.12.

## Plugins e motivo

| Plugin | Função clara |
|---|---|
| lazy.nvim | instalação, lockfile e verificação de updates |
| gruvbox.nvim | tema dark hard sólido |
| lualine / bufferline | estado e buffers sem ruído |
| snacks.nvim | notifier, bigfile, quickfile e LazyGit somente; dashboard desativado |
| neo-tree.nvim | único explorer |
| fzf-lua | único fuzzy finder |
| which-key.nvim | descoberta dos grupos semânticos |
| mini.ai/surround/pairs/bufremove | edição estrutural e buffers seguros |
| nvim-treesitter + textobjects | parsing, highlight e movimentos estruturais |
| blink.cmp | completion LSP/snippets, sem signature automática |
| Mason + lspconfig | instalação e configurações LSP modernas |
| conform.nvim / nvim-lint | formatação explícita e lint com debounce |
| gitsigns.nvim | hunks no buffer |
| nvim-dap, dap-ui, dap-python | debugging sob demanda |
| render-markdown / markdown-preview | leitura opcional e preview fiel no navegador |

Não há coleção externa de snippets; snippets vêm dos servidores LSP.

## Linguagens e ferramentas

| Linguagem | LSP | Lint | Formatação |
|---|---|---|---|
| Python | basedpyright | ruff | ruff imports + format |
| Lua | lua_ls + lazydev | LSP | stylua |
| C/C++ | clangd | LSP | clang-format |
| CMake | cmake | LSP | - |
| JSON/JSONC | jsonls | LSP | prettier |
| YAML | yamlls | LSP | prettier |
| TOML | taplo | LSP | taplo |
| Markdown | marksman | markdownlint-cli2 | prettier |
| Bash | bashls | shellcheck | shfmt |
| Docker/Compose | dockerls / docker_compose_language_service | LSP | - |
| Terraform/HCL | terraformls | LSP | - |

No Windows, clangd é habilitado somente se já existir no `PATH`; sua ausência não é erro. codelldb nunca é instalado ou configurado automaticamente ali.

### Python

O resolvedor único em `tools.lua` procura `VIRTUAL_ENV`, `.venv`, `venv`, o `PATH`, `python3` e `python`, usando `Scripts/python.exe` no Windows e `bin/python` no Linux. basedpyright, Ruff/Conform, lint e debugpy partem dessa mesma decisão. Em uma troca de projeto, o adaptador Python é atualizado.

### Completion

Blink só propõe candidatos após dois caracteres para LSP, buffer e paths. `Tab` avança no menu/snippet ou indenta; `Shift-Tab` volta ou reduz indentação. `Enter` aceita apenas uma entrada selecionada explicitamente, pois preselect e auto-insert estão desligados. Não há inlay hints, signature help automática ou documentação automática.

## Build e quickfix

Ao iniciar ou trocar workspace, `makeprg` segue esta ordem: `Makefile`, `CMakeLists.txt` com `cmake --build build`, projeto pytest com o Python resolvido, e `make` como fallback. Execute `:make` explicitamente. Quickfix abre apenas se houver item de erro e fecha em sucesso.

`:CMakeConfigure` executa `cmake -S <workspace> -B <workspace>/build`; `:CMakeBuild` compila esse diretório. Nenhum deles roda automaticamente, apaga ou reconfigura builds existentes sem comando.

## Debugging

O DAP carrega quando um atalho `<leader>d` é usado. A UI abre ao iniciar/anexar uma sessão e fecha ao terminar. Python usa debugpy; Fedora usa codelldb para C/C++. Nenhum debugger ou terminal é aberto na inicialização.

## Markdown e LaTeX

`<leader>mr` liga o render interno somente nos modos configurados; a sintaxe não fica permanentemente escondida durante edição. `<leader>mp` alterna o preview assíncrono no navegador, com KaTeX, Mermaid, tabelas, tarefas e imagens locais fornecidos pelo markdown-preview. O navegador é a referência para frações, matrizes e layout LaTeX complexo; o terminal não oferece a mesma fidelidade.

## Tema

Edite somente `lua/carlosvts/theme.lua`. `repository`, `colorscheme`, `variant`, `options` e `overrides` ficam centralizados; a spec retornada por `spec()` faz o Lazy instalar o repositório escolhido. Mantenha o fundo sólido ao trocar de tema.

## Expandindo

### Adicionar um plugin

Inclua uma spec no arquivo de domínio apropriado em `lua/carlosvts/plugins/`. Defina evento, comando, key ou filetype apenas se o plugin suportar lazy loading. Não duplique uma responsabilidade existente.

### Adicionar uma linguagem ou parser

Adicione o parser em `tools.treesitter_parsers`, o filetype no autocmd Treesitter e a ferramenta no quadro correto. Execute `:ConfigUpdate`.

### Adicionar um LSP

Adicione o nome reconhecido pelo `nvim-lspconfig` à lista `servers` em `plugins/coding.lua`. Para overrides, crie uma tabela `---@type vim.lsp.Config`, chame `vim.lsp.config('nome', config)` e mantenha `vim.lsp.enable()` como ativação. Nunca use `require('lspconfig').server.setup()`.

### Adicionar formatter ou linter

Para formatter, atualize `formatters_by_ft` do Conform e `mason_tools`. Para linter, atualize `linters_by_ft` do nvim-lint somente quando o LSP não duplicar bons diagnósticos. Nenhum formatter deve ganhar autocmd de save.

## Comandos da configuração

- `:ConfigOpen`: abre `init.lua` em nova tab.
- `:ConfigReload`: reaplica somente opções, maps, autocmds e colorscheme; specs exigem restart.
- `:ConfigHealth`: verifica versão, executáveis, clipboard, plugins, LSPs, formatters, linters e adapters.
- `:ConfigUpdate`: sincroniza Lazy/lockfile, parsers e registry/ferramentas Mason; depois pede restart.
- `:Lint`: lint manual.

O checker do Lazy roda em background e apenas notifica updates; ele nunca atualiza sozinho. Depois de `:ConfigUpdate`, revise e versione `lazy-lock.json`.

## Diagnóstico

Use `:ConfigHealth`, `:checkhealth`, `:Lazy`, `:Mason`, `:ConformInfo`, `:LspInfo` e `:messages`. Para startup, use:

```bash
nvim --startuptime /tmp/carlosvts-startup.log +qa
```

Arquivos acima de 1 MiB ou com linhas acima de 10.000 bytes entram em modo leve: Treesitter, LSP, completion, lint, indent guides e coluna do cursor são desligados, com uma única notificação. Busca, edição, números e syntax básica permanecem.

## Diferenças entre sistemas

- Separadores são construídos com `vim.fs.joinpath`; não há paths fixos de home.
- Fedora instala C/C++, CMake, clangd, clang-format e codelldb.
- Windows não instala essas ferramentas e usa junction em vez de symlink.
- Providers de clipboard e o programa que abre o navegador pertencem ao sistema/terminal.
- O requisito de compilador do Treesitter conflita deliberadamente com a política de não instalar toolchain C no Windows; veja a nota da instalação Windows.
