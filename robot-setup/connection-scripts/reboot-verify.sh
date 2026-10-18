#!/bin/bash
# Reboots the Pi and verifies the filesystem expansion. Mac password only.
# Load machine-specific values (gitignored). See local-config.example.sh
d="$(cd "$(dirname "$0")" && pwd)"; CONF=""
while [ "$d" != "/" ]; do [ -f "$d/local-config.sh" ] && { CONF="$d/local-config.sh"; break; }; d="$(dirname "$d")"; done
[ -n "$CONF" ] || { echo "No local-config.sh found - copy local-config.example.sh from the repo root and fill it in."; exit 1; }
. "$CONF"

SP="${TMPDIR:-/tmp}"   # scratch output; not the project folder
KEY="$PI_KEY"
SSHO=(-i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)
flush() { sudo arp -d $PI_IP_ETH >/dev/null 2>&1; sudo arp -s $PI_IP_ETH $PI_MAC >/dev/null 2>&1; }

echo ">>> Mac password for the ARP flush"
sudo -v || exit 1

echo ">>> rebooting the Pi"
flush
ssh "${SSHO[@]}" pi@$PI_IP_ETH 'sudo reboot' 2>&1 | grep -v "^$" || true

echo ">>> waiting for it to come back (up to ~3 min)"
for n in $(seq 1 30); do
  sleep 6
  flush
  if ssh "${SSHO[@]}" -o BatchMode=yes pi@$PI_IP_ETH 'true' 2>/dev/null; then
    echo "    back up after ~$((n*6))s"
    break
  fi
  printf '    %ss...\n' "$((n*6))"
done

echo ">>> verifying"
flush
ssh "${SSHO[@]}" pi@$PI_IP_ETH 'bash -lc "
echo === DISK ===
df -h /
echo
echo === LOCALE ===
locale | head -3
echo
echo === TIME ===
timedatectl | head -3
echo
echo === UPTIME ===
uptime
"' 2>&1 | tee "$SP/final-check.txt"
echo ">>> done"
