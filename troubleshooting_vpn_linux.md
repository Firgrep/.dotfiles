# VPN Linux Troubleshooting

VPN working slow or partially or not at all? Here is a list of possible solutions to try.

## Tools and Techniques

A helpful tool to check DNS is `dig`. Install with `pacman -S bind`. E.g. use `dig gmail.com`.

Use `tracepath 172.217.16.133` to check responses. Without VPN you should get multiple responses in rapid succession. Test with VPN before and after trying solutions to verify if it worked.

### ❌ System uses IPv6 instead of IPv4

**Fix**

- Run `sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1`
- Run `ip addr` or `curl ifconfig.me` to verify IPv4 is being used.
- _Note_ This is not a persistent change: Go to config in `/etc/sysctl.conf` to make a persistent change.

### ❌ Resolver Symlink broken

**Error**

- Running `resolvectl status` returns the following message:

```sh
Failed to get global data: Unit dbus-org.freedesktop.resolve1.service not found.
```

**Fix**

- Repair symlink: `sudo ln -sf /lib/systemd/system/systemd-resolved.service /etc/systemd/system/dbus-org.freedesktop.resolve1.service`
- Restart resolver: `systemctl restart systemd-resolved`
- Verify with `resolvectl status`

**See also**

- https://bbs.archlinux.org/viewtopic.php?id=268275

### ❌ Missing Network Rules (not verified)

**Error**

- No file found at `cat /etc/udev/rules.d/10-network.rules`

**Fix**

- Run `sudo nano /etc/udev/rules.d/10-network.rules`
- Input `ACTION=="add", SUBSYSTEM=="net",  ATTR{mtu}="1490"`
- Save and close.
- Restart?

### ❌ Incorrect mtu / pmtu

**Error**

- When running `tracepath 172.217.16.133` it should display which `pmtu` number is active.

**Fix**

- Run `ip a` to locate the ID of the VPN. For me it was `ppp0` (the name after the number and column). You will see the `mtu` number here.
- Try adjusting `mtu` to `1350` with `sudo ip link set ppp0 mtu 1350`.
- The change should have immediate effect. Verify with `tracepath 172.217.16.133`.

**See also**

- https://bbs.archlinux.org/viewtopic.php?id=268813
