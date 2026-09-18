sudo apt update && sudo apt install xclip

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
