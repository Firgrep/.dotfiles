### Arch

- `yay -Sy visual-studio-code-bin` to update VS Code
- `git pull` `makepkg -is` to update Chrome from the AUR in src

### Ubuntu

- `apt-get install --only-upgrade <package-name>` to _only_ upgrade a single pkg.

### GNOME

Title bar (applications)

- https://askubuntu.com/questions/821813/how-to-slim-down-ubuntu-gnome-title-bar-fatness

Timeout for blanking the screen (seconds, 0 is false)

- `gsettings set org.gnome.desktop.session idle-delay 3600`

Cursor

- `gsettings list-recursively | grep blink` find the actual variable concerning blinking cursor
- `gsettings set org.gnome.desktop.interface cursor-blink false` Turn off blinking cursor in terminal

### Network

Block IPv6 on machine

- `sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1` set to 0 to re-enable
- to permanently edit, go to `/etc/sysctl.conf`

### Base64

- `base64 -w 0 key.json > encoded_key.txt `

### Fonts

- `sudo mkdir /usr/local/share/fonts/NEW_FONT`
- `sudo mv ~/Downloads/NEW_FONT/*.ttf /usr/local/share/fonts/NEW_FONT`
