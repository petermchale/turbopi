#!/bin/bash
# Read-only network diagnostic. Captures traffic to/from the Pi while probing it.
# Load machine-specific values (gitignored). See local-config.example.sh
CONF="$(cd "$(dirname "$0")/.." && pwd)/local-config.sh"
[ -f "$CONF" ] || { echo "Missing $CONF - copy local-config.example.sh to it and fill it in."; exit 1; }
. "$CONF"

SP="${TMPDIR:-/tmp}"   # scratch output; not the project folder
OUT="$SP/probe-out.txt"
: > "$OUT"

echo "### arp before" >>"$OUT"
arp -an | grep 192.168.2 >>"$OUT" 2>&1

echo "### flushing arp entry for $PI_IP_ETH" >>"$OUT"
arp -d $PI_IP_ETH >>"$OUT" 2>&1

echo "### starting capture on bridge100 (12s)" >>"$OUT"
tcpdump -i bridge100 -n -e -s 128 'host $PI_IP_ETH or arp or icmp' >"$SP/cap.txt" 2>"$SP/cap.err" &
TPID=$!
sleep 2

echo "### probing" >>"$OUT"
ping -c 3 -W 1000 $PI_IP_ETH >>"$OUT" 2>&1
nc -z -G 3 -w 3 $PI_IP_ETH 22 >>"$OUT" 2>&1 && echo "ssh open" >>"$OUT" || echo "ssh closed" >>"$OUT"
arping -c 3 $PI_IP_ETH >>"$OUT" 2>&1 || true
sleep 6

kill $TPID 2>/dev/null; wait $TPID 2>/dev/null

echo "### arp after" >>"$OUT"
arp -an | grep 192.168.2 >>"$OUT" 2>&1
echo "### capture line count: $(wc -l < "$SP/cap.txt")" >>"$OUT"
echo "DONE"
