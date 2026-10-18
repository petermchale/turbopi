# shellcheck disable=SC2148
# Copy to local-config.sh and fill in your own robot's values.
#
# PI_MAC    : the Pi's ethernet MAC. Find it with `arp -an` while connected,
#             or on the robot with `ip link show eth0`.
# AP_SSID   : the HiWonder hotspot, named HW-<last 8 of the Pi's wlan0 MAC>.
#             Factory password is `hiwonder`.
# shellcheck disable=SC2034
PI_MAC="xx:xx:xx:xx:xx:xx"
PI_IP_ETH="192.168.2.2"
PI_IP_WIFI="192.168.149.1"
AP_SSID="HW-XXXXXXXX"
PI_KEY="$HOME/.ssh/turbopi_ed25519"
