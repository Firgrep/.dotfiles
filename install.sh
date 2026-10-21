sudo apt update && sudo apt install xclip

# Neovim, pinned to a known-good version rather than whatever the distro's
# apt repo happens to carry (older Ubuntu releases ship Neovim versions far
# too old for AstroNvim). Installs to /opt/nvim-linux64 (matches the PATH
# entry already in .bashrc) and symlinks into /usr/local/bin, which comes
# before /usr/bin on PATH, so this wins even if a distro neovim package is
# also present.
NVIM_VERSION="v0.11.6"
curl -Lo /tmp/nvim-linux-x86_64.tar.gz "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
sudo rm -rf /opt/nvim-linux64
sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz
sudo mv /opt/nvim-linux-x86_64 /opt/nvim-linux64
sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
rm /tmp/nvim-linux-x86_64.tar.gz
nvim --version | head -1

# AstroNvim requirements
sudo apt install -y \
  build-essential \
  unzip \
  ripgrep \
  fd-find \
  python3-pip \
  python3-venv \
  libicu78
# build-essential: compiles treesitter parsers
# unzip: several Mason-installed tools (stylua, selene, terraform-ls, tflint, ...) ship as .zip
# ripgrep, fd-find: used by pickers/live-grep
# python3-pip, python3-venv: Mason installs Python-based tools (e.g. nginx-config-formatter) into their own venv
# libicu78: marksman (Markdown LSP) is a .NET binary that aborts (SIGABRT) on
# startup without an ICU package installed on the system

# Debian/Ubuntu installs fd-find's binary as `fdfind`, not `fd` (the name `fd`
# was already taken in their archive), so symlink it to the name most tools expect
sudo ln -sf "$(which fdfind)" /usr/local/bin/fd

# lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/
rm lazygit.tar.gz lazygit

# fzf, from GitHub releases: the apt package is too old for `fzf --bash`
# (added in 0.48), which .bashrc uses. Installs to ~/.local/bin, which comes
# before /usr/bin on PATH, so this wins over any apt fzf.
FZF_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
tar xf fzf.tar.gz fzf
install -D -t ~/.local/bin fzf
rm fzf.tar.gz fzf

# Rust toolchain via rustup: creates ~/.cargo/env, which .bashrc sources
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
# rustup-init only installs when missing, so also update an existing toolchain to the newest stable
. "$HOME/.cargo/env"
rustup update stable

# atuin: the installer creates ~/.atuin/bin/env, which .bashrc sources.
# Local-only history afterwards: `atuin import auto` (no cloud sync).
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive

# zoxide: official installer puts the binary in ~/.local/bin
curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Go, from the official tarball into /usr/local/go (the PATH entry already in .bashrc).
# Mason builds gopls, delve, goimports etc. with `go install`.
GO_VERSION=$(curl -s "https://go.dev/VERSION?m=text" | head -1)
curl -Lo /tmp/go.tar.gz "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz
/usr/local/go/bin/go version

# Node via nvm (sourced by .bashrc): Mason installs biome, yaml-language-server,
# json-lsp and mdx-analyzer with npm.
NVM_VERSION=$(curl -s "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | grep -Po '"tag_name": *"\K[^"]*')
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | PROFILE=/dev/null bash
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm install 26
nvm alias default 26

# pnpm, standalone installer (needs no Node, but sits with the other JS tooling)
curl -fsSL https://get.pnpm.io/install.sh | sh -

# uv + Python 3.13: the distro's python3 can be newer than Mason's Python tools support
# (nginx-language-server needs <3.14). uv puts python3.13 in ~/.local/bin, which Mason
# finds as a versioned candidate without replacing the system python3.
curl -LsSf https://astral.sh/uv/install.sh | sh
~/.local/bin/uv python install 3.13

# kubectl, latest stable release, installed to /usr/local/bin
KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
curl -Lo kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Inconsolata Nerd Font, per-user install to ~/.local/share/fonts
NERD_FONT_VERSION="v3.5.1"
FONT_TMP=$(mktemp -d)
curl -Lo "$FONT_TMP/Inconsolata.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/Inconsolata.zip"
mkdir -p ~/.local/share/fonts/InconsolataNerdFont
unzip -o -q "$FONT_TMP/Inconsolata.zip" '*.ttf' -d ~/.local/share/fonts/InconsolataNerdFont
rm -rf "$FONT_TMP"
fc-cache -f ~/.local/share/fonts
