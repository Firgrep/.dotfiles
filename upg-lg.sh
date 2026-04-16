LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') && \
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_$(uname -s)_$(uname -m).tar.gz" && \
tar xf lazygit.tar.gz lazygit && \
sudo install lazygit /usr/local/bin && \
rm lazygit lazygit.tar.gz