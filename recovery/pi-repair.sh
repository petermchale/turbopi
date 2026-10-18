#!/bin/bash
# TurboPi network repair. Runs once at early boot via systemd.run= in cmdline.txt.
# Undoes the damage from the rartino/turbopi README networking steps.
# Logs to /boot/repair.log (readable from macOS) and /var/log/turbopi-repair.log.

RLOG=/var/log/turbopi-repair.log
exec >"$RLOG" 2>&1
set -x

echo "=== TurboPi repair, $(date) ==="

# /boot may not be mounted yet this early in boot. We need it writable, both to
# leave a log the user can read from macOS and - critically - to remove our own
# systemd.run= line. If we fail to restore cmdline.txt the Pi reboot-loops.
mount -o remount,rw / || true
if ! mountpoint -q /boot; then
    mount /boot || mount -t vfat /dev/mmcblk0p1 /boot || true
fi
mount -o remount,rw /boot || true
mountpoint -q /boot && BOOT_OK=1 || BOOT_OK=0
echo "BOOT_OK=$BOOT_OK"

# 1. Restore the kernel command line FIRST, so that even if a later step fails
#    we never boot-loop.
if [ "$BOOT_OK" = "1" ]; then
    if [ -f /boot/cmdline.txt.orig ]; then
        cp /boot/cmdline.txt.orig /boot/cmdline.txt
    else
        sed -i 's| systemd\.run[^ ]*||g; s| systemd\.unit=kernel-command-line\.target||g' /boot/cmdline.txt
    fi
    sync
    echo "--- cmdline.txt restored to: ---"
    cat /boot/cmdline.txt
fi

echo "--- BEFORE: /etc/dhcpcd.conf ---"
cat /etc/dhcpcd.conf 2>/dev/null
echo "--- BEFORE: /etc/network/interfaces.d/ ---"
for f in /etc/network/interfaces.d/*; do echo "== $f"; cat "$f"; done 2>/dev/null
echo "--- dhcp clients present ---"
ls -la /sbin/dhcpcd /usr/sbin/dhcpcd /sbin/dhclient /usr/sbin/dhclient 2>&1
echo "--- hw_wifi / ssh unit state ---"
systemctl is-enabled hw_wifi ssh 2>&1
echo "--- interfaces ---"
ip -o link 2>&1

STAMP=$(date +%Y%m%d%H%M%S)

# 2. Drop the denyinterfaces line that stopped dhcpcd managing eth0/wlan0.
if [ -f /etc/dhcpcd.conf ]; then
    cp -a /etc/dhcpcd.conf "/etc/dhcpcd.conf.bak.$STAMP"
    sed -i '/^[[:space:]]*denyinterfaces/d' /etc/dhcpcd.conf
fi

# 3. Put HiWonder's hotspot back: HW-XXXXXXXX / 192.168.149.1 / pw hiwonder.
systemctl unmask hw_wifi 2>&1
systemctl enable hw_wifi 2>&1

# 4. Guarantee a wired way in that needs no DHCP server. 192.168.2.50 matches
#    the subnet macOS Internet Sharing already hands out, so it is reachable
#    from the Mac with no further setup.
if [ -x /sbin/dhcpcd ] || [ -x /usr/sbin/dhcpcd ]; then
    if ! grep -q "profile turbopi_rescue" /etc/dhcpcd.conf; then
        cat >>/etc/dhcpcd.conf <<'EOF'

# Added by pi-repair.sh: wired rescue address if no DHCP server answers.
profile turbopi_rescue
static ip_address=192.168.2.50/24

interface eth0
fallback turbopi_rescue
EOF
    fi
    [ -f /etc/network/interfaces.d/eth0 ] && \
        mv /etc/network/interfaces.d/eth0 "/etc/network/interfaces.d/eth0.disabled.$STAMP"
else
    # No DHCP client at all: static eth0 via ifupdown.
    [ -f /etc/network/interfaces.d/eth0 ] && \
        cp -a /etc/network/interfaces.d/eth0 "/etc/network/interfaces.d/eth0.bak.$STAMP"
    cat >/etc/network/interfaces.d/eth0 <<'EOF'
auto eth0
allow-hotplug eth0
iface eth0 inet static
    address 192.168.2.50
    netmask 255.255.255.0
    gateway 192.168.2.1
EOF
fi

# 5. Make sure eth0 is actually up regardless of what the config managers do.
ip link set eth0 up 2>&1

# 6. Make sure ssh is running.
systemctl unmask ssh 2>&1
systemctl enable ssh 2>&1

echo "--- AFTER: /etc/dhcpcd.conf ---"
cat /etc/dhcpcd.conf
echo "--- AFTER: /etc/network/interfaces.d/ ---"
for f in /etc/network/interfaces.d/*; do echo "== $f"; cat "$f"; done 2>/dev/null
echo "=== repair finished ok ==="

# 7. Copy the log somewhere macOS can read it.
if [ "$BOOT_OK" = "1" ]; then
    cp "$RLOG" /boot/repair.log 2>/dev/null
    sync
fi

exit 0
