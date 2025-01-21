# .DOTFILES for Firgrep

The start of a dotty journey.

Feel welcome to copy!

`stow .` to populate symlinks.

### `stow` defaults

Without a `.stow-local-ignore` file, `stow` will use [defaults](https://www.gnu.org/software/stow/manual/stow.html#Ignore-Lists), but if this file exists then the defaults will be ignored.

### `tmux` plugins setup

- install TPM `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
- install plugins `prefix + I` [see](https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installing-plugins)
- install xsel `$ sudo apt-get install xsel`
- reload terminals

### `atuin` better history search

- run `bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)`
- restart terminals
- run `atuin import auto` (local syncing only, no cloud)

### `neovim` requirements

- `sudo apt install ripgrep`
- `sudo apt install fd-find`
- Lazygit
  ```
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit -D -t /usr/local/bin/
  ```
