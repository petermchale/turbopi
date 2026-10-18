# Fixing it from a keyboard + monitor on the Pi

Needs: micro-HDMI -> HDMI cable, a monitor, a USB keyboard.
The Pi's USB ports and micro-HDMI are reachable without disassembly.

Log in as `pi` (password: whatever you changed it to, else `raspberry`).

## 1. Confirm the diagnosis

    ip link show eth0          # expect: state DOWN
    which dhcpcd dhclient      # expect: no output  <- the smoking gun

## 2. Get networking back immediately (no reboot)

    sudo ip link set eth0 up
    sudo ip addr add 192.168.2.50/24 dev eth0
    sudo ip route add default via 192.168.2.1

With the ethernet cable to the Mac and Internet Sharing on, you now have
internet. Verify:

    ping -c3 192.168.2.1
    ping -c3 1.1.1.1

From the Mac: `ssh pi@192.168.2.50`

## 3. Make the repair permanent

    sudo sed -i '/^[[:space:]]*denyinterfaces/d' /etc/dhcpcd.conf
    sudo apt-get update
    sudo apt-get install -y dhcpcd5        # must succeed before anything else
    sudo systemctl enable --now dhcpcd

## 4. Put the hotspot back as a permanent escape hatch

    sudo systemctl unmask hw_wifi
    sudo systemctl enable hw_wifi

## 5. Only now set up your own wifi

    sudo nano /etc/network/interfaces.d/wlan0

Contents:

    auto wlan0
    iface wlan0 inet dhcp
        wpa-ssid "YOUR_SSID"
        wpa-psk "YOUR_PASSWORD"

Then `sudo reboot`, and check your router for the new IP.

## Do NOT

Never add `denyinterfaces eth0 wlan0` to /etc/dhcpcd.conf. It is not needed,
and combined with purging the DHCP client it is what bricked the robot.
