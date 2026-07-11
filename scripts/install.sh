#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /etc/fedora-release ]] || ! command -v dnf >/dev/null 2>&1; then
  printf 'This installer supports Fedora with dnf only.\n' >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
timestamp="$(date +%Y-%m-%d-%H%M%S)"

declare -A packages=(
  [git]=git [nvim]=neovim [rg]=ripgrep [fd]=fd-find [fzf]=fzf [bat]=bat
  [delta]=git-delta [lazygit]=lazygit [node]=nodejs [npm]=npm [python3]=python3
  [cmake]=cmake [make]=make [gcc]=gcc [g++]=gcc-c++ [clangd]=clang-tools-extra
  [clang-format]=clang-tools-extra [tree-sitter]=tree-sitter-cli
)

missing_packages=()
for command in "${!packages[@]}"; do
  command -v "$command" >/dev/null 2>&1 || missing_packages+=("${packages[$command]}")
done

if ((${#missing_packages[@]})); then
  mapfile -t missing_packages < <(printf '%s\n' "${missing_packages[@]}" | sort -u)
  available_packages=()
  for package in "${missing_packages[@]}"; do
    if dnf -q repoquery "$package" >/dev/null 2>&1; then
      available_packages+=("$package")
    else
      printf 'Package unavailable in enabled repositories, skipping: %s\n' "$package" >&2
    fi
  done
  if ((${#available_packages[@]})); then
    printf 'Installing missing Fedora packages: %s\n' "${available_packages[*]}"
    sudo dnf install -y "${available_packages[@]}"
  fi
fi

for required in git nvim rg fd fzf node npm python3 cmake make gcc g++ clangd clang-format tree-sitter; do
  command -v "$required" >/dev/null 2>&1 || { printf 'Required command is still missing: %s\n' "$required" >&2; exit 1; }
done

version="$(nvim --version | sed -n '1s/^NVIM v//p')"
if [[ "$(printf '%s\n' '0.12.0' "$version" | sort -V | head -n1)" != '0.12.0' ]]; then
  printf 'Neovim 0.12+ is required; Fedora provided %s. Install a current official Neovim build and rerun.\n' "$version" >&2
  exit 1
fi

mkdir -p "$(dirname "$config_dir")"
if [[ -e "$config_dir" || -L "$config_dir" ]]; then
  current="$(readlink -f "$config_dir")"
  if [[ "$current" != "$repo_dir" ]]; then
    backup="${config_dir}.backup-${timestamp}"
    mv "$config_dir" "$backup"
    printf 'Previous configuration backed up at %s\n' "$backup"
    ln -s "$repo_dir" "$config_dir"
  fi
else
  ln -s "$repo_dir" "$config_dir"
fi

printf 'Synchronizing plugins...\n'
nvim --headless '+Lazy! sync' +qa
printf 'Installing Treesitter parsers...\n'
nvim --headless "+lua require('nvim-treesitter').install(require('carlosvts.tools').treesitter_parsers):wait(300000)" +qa
printf 'Installing Mason tools...\n'
CARLOSVTS_HEADLESS_INSTALL=1 nvim --headless '+MasonToolsInstallSync' +qa
nvim --headless '+checkhealth carlosvts' '+qa' || true

printf '\ncarlosvts.nvim installed at %s\nRun: nvim .\n' "$config_dir"
