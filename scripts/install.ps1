$ErrorActionPreference = 'Stop'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw 'winget is required. Install or update Microsoft App Installer first.'
}

$RepoDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ConfigDir = Join-Path $env:LOCALAPPDATA 'nvim'
$Timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'

$Packages = [ordered]@{
  git      = 'Git.Git'
  nvim     = 'Neovim.Neovim'
  rg       = 'BurntSushi.ripgrep.MSVC'
  fd       = 'sharkdp.fd'
  fzf      = 'junegunn.fzf'
  bat      = 'sharkdp.bat'
  delta    = 'dandavison.delta'
  lazygit  = 'JesseDuffield.lazygit'
  node     = 'OpenJS.NodeJS.LTS'
  python   = 'Python.Python.3.13'
}

foreach ($Entry in $Packages.GetEnumerator()) {
  $Present = Get-Command $Entry.Key -ErrorAction SilentlyContinue
  if ($Entry.Key -eq 'python') { $Present = $Present -or (Get-Command python3 -ErrorAction SilentlyContinue) }
  if (-not $Present) {
    winget show --id $Entry.Value --exact --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "winget package ID is unavailable: $($Entry.Value)"
      continue
    }
    Write-Host "Installing $($Entry.Key) ($($Entry.Value))..."
    winget install --id $Entry.Value --exact --accept-package-agreements --accept-source-agreements --silent
    if ($LASTEXITCODE -ne 0) { Write-Warning "Could not install optional package $($Entry.Value)" }
  }
}

$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

$Nvim = Get-Command nvim -ErrorAction Stop
$VersionLine = & $Nvim.Source --version | Select-Object -First 1
$Version = [version]($VersionLine -replace '^NVIM v', '')
if ($Version -lt [version]'0.12.0') { throw "Neovim 0.12+ is required; found $Version" }

if (Test-Path $ConfigDir) {
  $ConfigItem = Get-Item $ConfigDir
  $Existing = if ($ConfigItem.Target) { [IO.Path]::GetFullPath($ConfigItem.Target) } else { [IO.Path]::GetFullPath($ConfigItem.FullName) }
  if ($Existing -ne [IO.Path]::GetFullPath($RepoDir)) {
    $Backup = "$ConfigDir.backup-$Timestamp"
    Move-Item $ConfigDir $Backup
    Write-Host "Previous configuration backed up at $Backup"
    New-Item -ItemType Junction -Path $ConfigDir -Target $RepoDir | Out-Null
  }
} else {
  New-Item -ItemType Junction -Path $ConfigDir -Target $RepoDir | Out-Null
}

Write-Host 'Synchronizing plugins...'
& nvim --headless '+Lazy! sync' '+qa'
Write-Host 'Installing Treesitter parsers (requires a compiler already present on Windows)...'
& nvim --headless "+lua require('nvim-treesitter').install(require('carlosvts.tools').treesitter_parsers):wait(300000)" '+qa'
if ($LASTEXITCODE -ne 0) { Write-Warning 'Some Treesitter parsers could not be compiled. No compiler is installed automatically on Windows.' }
Write-Host 'Installing Mason tools...'
$env:CARLOSVTS_HEADLESS_INSTALL = '1'
& nvim --headless '+MasonToolsInstallSync' '+qa'
& nvim --headless '+checkhealth carlosvts' '+qa'

Write-Host "`ncarlosvts.nvim installed at $ConfigDir"
Write-Host 'Run: nvim .'
