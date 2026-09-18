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
  python3-venv
# build-essential: compiles treesitter parsers
# unzip: several Mason-installed tools (stylua, selene, terraform-ls, tflint, ...) ship as .zip
# ripgrep, fd-find: used by pickers/live-grep
# python3-pip, python3-venv: Mason installs Python-based tools (e.g. nginx-config-formatter) into their own venv

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
