#!/bin/bash
# Load machine-specific values (gitignored). See local-config.example.sh
d="$(cd "$(dirname "$0")" && pwd)"; CONF=""
while [ "$d" != "/" ]; do [ -f "$d/local-config.sh" ] && { CONF="$d/local-config.sh"; break; }; d="$(dirname "$d")"; done
[ -n "$CONF" ] || { echo "No local-config.sh found - copy local-config.example.sh from the repo root and fill it in."; exit 1; }
. "$CONF"

SP="${TMPDIR:-/tmp}"   # scratch output; not the project folder
OUT="$SP/locale-verify.txt"
echo ">>> refreshing ARP (Mac password)"
sudo arp -d $PI_IP_ETH >/dev/null 2>&1
sudo arp -s $PI_IP_ETH $PI_MAC >/dev/null 2>&1
echo ">>> fresh login (Pi password)"
# -o SendEnv=  stops our Mac's own LANG/LC_* leaking in and muddying the test
ssh -i "$PI_KEY" -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -o SendEnv=none \
    pi@$PI_IP_ETH 'bash -lc "
echo === locale in a FRESH login ===
locale
echo
echo === any zh_CN left in system config? ===
grep -sn zh_CN /etc/environment /etc/default/locale /etc/locale.conf \
     ~/.bashrc ~/.profile ~/.bash_profile /etc/profile /etc/profile.d/* 2>/dev/null \
     || echo \"(none found - clean)\"
echo
echo === /etc/environment contents ===
cat /etc/environment 2>/dev/null || echo \"(absent)\"
"' 2>&1 | tee "$OUT"
echo ">>> done"
