Resolved. Posting the root cause since it's a bug in the README rather than
anything I did differently, and the failure is silent, so others will hit it.

## The typo

```
echo "denyinterfaces eth0 wlan0 >> /etc/dhcpcd.conf"
```

The closing quote is in the wrong place. As written this echoes the string
`denyinterfaces eth0 wlan0 >> /etc/dhcpcd.conf` to stdout and changes nothing
— no redirection, no error, no permission problem (note it also has no `sudo`,
which it would need if it actually wrote to the file). It fails completely
silently.

So the line has almost certainly never been applied on your own robot, which is
why you've never seen this. I "fixed" the quoting to what it obviously meant,
and that is what broke networking.

## What applying it actually does

Combined with the surrounding steps it removes every route to configuring the
interfaces:

- `denyinterfaces eth0 wlan0` tells `dhcpcd` to ignore both interfaces.
- `/etc/network/interfaces.d/eth0` (created two steps earlier) says
  `iface eth0 inet dhcp`, which under `ifupdown` needs `dhclient` — purged by
  `apt-get purge isc-dhcp-client` in the very same block.
- `systemctl disable hw_wifi` removes the `HW-XXXXXXXX` hotspot, i.e. the only
  remaining way in.

The result after reboot is `eth0` and `wlan0` both administratively **DOWN**
with no address. From the other end of an ethernet cable the Pi is completely
silent at layer 2 — it doesn't even answer an ICMPv6 ping to `ff02::1`, and a
macOS bridge learns zero MAC addresses from it. That silence is diagnostic:
it's an interface that was never brought up, not one that failed DHCP.

Captured from the running system during recovery:

```
--- BEFORE: /etc/dhcpcd.conf ---
[...]
denyinterfaces eth0 wlan0

--- dhcp clients present ---
ls: cannot access '/sbin/dhclient': No such file or directory
-rwxr-xr-x 1 root root 317880 Oct 26 08:06 /sbin/dhcpcd

--- interfaces ---
2: eth0: <BROADCAST,MULTICAST> ... state DOWN
3: wlan0: <BROADCAST,MULTICAST> ... state DOWN
```

Worth noting `dhcpcd` *was* installed correctly — the purge/install pair
worked. `denyinterfaces` alone is sufficient to cause this.

## Recovering without console access

`/boot` is FAT32, so it's writable from any Mac or Windows machine. The
`systemd.run=` hook that Raspberry Pi Imager uses for its first-run
customisation lets you run a repair script as root before networking starts.
Append to `cmdline.txt` (keep it one line):

```
systemd.run=/boot/pi-repair.sh systemd.run_success_action=reboot systemd.run_failure_action=reboot systemd.unit=kernel-command-line.target
```

with a script that strips the `denyinterfaces` line and re-enables `hw_wifi`.
Restore `cmdline.txt` as the *first* action in the script, not the last —
otherwise a later failure leaves the Pi reboot-looping. Worth mentioning that
`/boot` may not be mounted that early, so mount it explicitly.

## Suggested README changes

1. **Fix the quoting**, or drop `denyinterfaces` for `eth0` entirely. Nothing
   in the setup needs it, and it's what removes your fallback route.
2. **`denyinterfaces wlan0` only.** This one is genuinely needed — otherwise
   `dhcpcd` fights `hw_wifi` for `wlan0` and lands a `169.254.x.x` address on
   top of the AP's `192.168.149.1`.
3. **`denyinterfaces` must appear before any `interface` stanza** in
   `dhcpcd.conf`. It's a global option; placed after an `interface` block it is
   parsed as part of that block and silently ignored. Appending it with `>>` to
   a file that already has interface stanzas will not work.
4. **Reverse the purge/install order**, and flag the connectivity trap: at that
   point in the guide the Pi is on its own AP with no upstream internet, so
   `apt-get install dhcpcd5` can fail right after you've removed the only DHCP
   client. Install first, verify, then purge.
5. **Keep `hw_wifi` enabled until the new wifi config is proven**, and disable
   it only after a successful reboot onto the target network. It's the escape
   hatch.
