# Console recovery with NO laptop nearby (wifi only)

Your home network's subnet and router address are whatever your own router
uses (check with `ipconfig getsummary en0` on the Mac). There is no DHCP
client on the Pi, so assign a static address by hand — pick one high in the
range that your router is unlikely to hand out.

Replace SSID and PASSWORD below with your own.

## 1. Write a wpa_supplicant config

    sudo tee /etc/wpa_supplicant/wpa_supplicant.conf >/dev/null <<'END'
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    update_config=1
    country=US
    END

    wpa_passphrase "SSID" "PASSWORD" | grep -v '#psk' \
        | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf

## 2. Bring wlan0 up and associate

    sudo ip link set wlan0 up
    sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
    sleep 5
    iwconfig wlan0            # should show your SSID, not "unassociated"

## 3. Give it an address and a route

    sudo ip addr add 192.168.X.50/24 dev wlan0
    sudo ip route add default via 192.168.X.1
    echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf

    ping -c3 192.168.X.1     # router
    ping -c3 1.1.1.1          # internet
    ping -c3 deb.debian.org   # DNS working

## 4. You can now ssh in from the Mac and stop typing at the TV

    ssh pi@192.168.X.50

## 5. Then continue from step 3 of console-fix.md

Install the DHCP client FIRST, before removing anything:

    sudo apt-get update
    sudo apt-get install -y dhcpcd5
    sudo sed -i '/^[[:space:]]*denyinterfaces/d' /etc/dhcpcd.conf
    sudo systemctl enable --now dhcpcd
    sudo systemctl unmask hw_wifi
    sudo systemctl enable hw_wifi

Reboot and confirm it comes back on its own before you put the robot away.
