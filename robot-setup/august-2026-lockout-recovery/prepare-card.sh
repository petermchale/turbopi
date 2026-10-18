#!/bin/bash
# Run on the Mac with the TurboPi SD card inserted.
# Arms a one-shot repair that runs as root on the Pi's next boot.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

BOOT=""
for cand in /Volumes/boot /Volumes/bootfs /Volumes/BOOT; do
    [ -f "$cand/cmdline.txt" ] && BOOT="$cand" && break
done
if [ -z "$BOOT" ]; then
    echo "Could not find the Pi boot partition." >&2
    echo "Volumes currently mounted:" >&2
    ls /Volumes >&2
    exit 1
fi
echo "Boot partition: $BOOT"

if [ ! -f "$BOOT/cmdline.txt.orig" ]; then
    cp "$BOOT/cmdline.txt" "$BOOT/cmdline.txt.orig"
    echo "Saved original cmdline.txt -> cmdline.txt.orig"
fi

cp "$HERE/pi-repair.sh" "$BOOT/pi-repair.sh"
chmod 755 "$BOOT/pi-repair.sh" 2>/dev/null || true

# Rebuild cmdline.txt from the pristine copy, as one single line.
ORIG="$(tr -d '\r\n' < "$BOOT/cmdline.txt.orig")"
printf '%s systemd.run=/boot/pi-repair.sh systemd.run_success_action=reboot systemd.run_failure_action=reboot systemd.unit=kernel-command-line.target\n' \
    "$ORIG" > "$BOOT/cmdline.txt"

rm -f "$BOOT/repair.log"
touch "$BOOT/ssh"
sync

echo
echo "New cmdline.txt:"
cat "$BOOT/cmdline.txt"
echo
echo "Done. Eject the card:  diskutil eject $BOOT"
echo "Then boot the robot, wait ~2 min (it reboots itself once), and look for"
echo "the HW-XXXXXXXX wifi network. Re-read the card later to see repair.log."
