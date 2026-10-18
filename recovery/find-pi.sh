#!/bin/bash
# Run on the Mac with the USB ethernet adapter cabled to the robot.
# Waits for link, then tries every way of finding the Pi.
IF=en7

echo "Waiting for link on $IF (turn the robot on now)..."
for i in $(seq 1 180); do
    st=$(ifconfig $IF 2>/dev/null | awk '/status:/{print $2}')
    [ "$st" = "active" ] && break
    printf '\r  %ss  status=%s ' "$i" "${st:-none}"
    sleep 1
done
echo
if [ "$(ifconfig $IF | awk '/status:/{print $2}')" != "active" ]; then
    echo "No link. Check the cable is in the Pi's ethernet port and the robot is on."
    exit 1
fi
echo "Link is up."

echo; echo "--- our addresses on $IF ---"
ifconfig $IF | grep inet

echo; echo "--- mDNS (.local) ---"
for host in raspberrypi.local turbopi.local hiwonder.local; do
    printf '%-20s ' "$host"
    ping -c1 -W 2000 -b $IF "$host" >/dev/null 2>&1 && echo "REACHABLE" || echo "-"
done
echo "browsing for ssh services:"
timeout 8 dns-sd -B _ssh._tcp local 2>/dev/null || true

echo; echo "--- IPv6 link-local neighbours ---"
ping6 -c 3 -I $IF ff02::1 >/dev/null 2>&1
ndp -an 2>/dev/null | grep -i "$IF" || echo "(none)"

echo; echo "--- IPv4 link-local / shared-network sweep ---"
ping -c 2 -b $IF 255.255.255.255 >/dev/null 2>&1
for net in 169.254 192.168.2 192.168.150; do
    for n in $(seq 1 20); do (ping -c1 -W 300 $net.$n >/dev/null 2>&1 &) ; done
done
sleep 3
arp -an | grep -v en0 | grep -v incomplete || echo "(nothing answered)"

echo; echo "If a candidate IP or hostname showed up:  ssh pi@<that>"
