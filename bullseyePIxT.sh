#!/bin/bash
# The script configures simultaneous AP and Managed Mode Wifi on Raspberry Pi
# Distribution Raspbian Bullseye
# works on:
#           -Raspberry Pi Zero W
# Licence: GPLv3
# Repository: https://github.com/ShalimRazzak/rpi-wifi
# Special thanks to: https://github.com/MkLHX/AP_STA_RPI_SAME_WIFI_CHIP
# Special thanks to: https://github.com/lukicdarkoo/rpi-wifi

# set -exv

# Error management
set -o errexit
set -o pipefail
set -o nounset

DEFAULT='\033[0;39m'
WHITE='\033[0;02m'
RASPBERRY='\033[0;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'

_welcome() {
    VERSION="2.0.1"
    echo -e "${RASPBERRY}\n"
    echo -e "                                                                       "
    echo -e "  /888888  /8888888                         /888888  /88888888 /888888 "
    echo -e " /88__  88| 88__  88          /88          /88__  88|__  88__//88__  88"
    echo -e "| 88  \ 88| 88  \ 88         | 88         | 88  \__/   | 88  | 88  \ 88"
    echo -e "| 88888888| 8888888/       /88888888      |  888888    | 88  | 88888888"
    echo -e "| 88__  88| 88____/       |__  88__/       \____  88   | 88  | 88__  88"
    echo -e "| 88  | 88| 88               | 88          /88  \ 88   | 88  | 88  | 88"
    echo -e "| 88  | 88| 88               |__/         |  888888/   | 88  | 88  | 88"
    echo -e "|__/  |__/|__/                             \______/    |__/  |__/  |__/"
    echo -e "                                                                       "
    echo -e "                                                    version ${VERSION} "
    echo -e " By https://github.com/ShalimRazzak                                    "
    echo -e "${GREEN}                                                               "
    echo -e "Manage AP + STA modes on Raspberry Pi with the same wifi chip\n        "
    echo -e "${RASPBERRY}                                                           "
}

_logger() {
    echo -e "${GREEN}"
    echo "${1}"
    echo -e "${DEFAULT}"
}

_usage() {
    cat 1>&2 <<EOF
Configures simultaneous AP and Managed Mode Wifi on Raspberry Pi

USAGE:
    ap_sta_config.sh --ap <ap_ssid> [<ap_password>] --client <client_password> [<client_password>] --country <iso_3166_country_code>

    # configure AP + STA
    ap_sta_config.sh --ap ap_ssid ap_passphrases --client client_ssid client_passphrase --country US

    # configure AP + STA and change the wifi mode
    ap_sta_config.sh --ap ap_ssid ap_passphrases --client client_ssid client_passphrase --country US --hwmode g

    # update the AP configuration
    ap_sta_config.sh --ap ap_ssid ap_passphrases --ap-only

    # update the STA (client) configuration
    ap_sta_config.sh --client client_ssid client_passphrase --country US --sta-only

    # logs are written in /var/log/ap_sta_wifi folder

PARAMETERS:
    -a, --ap      	    AP SSID & password
    -c, --client	    Client SSID & password
    -i, --ip            AP IP (by default ip pattern 192.168.10.x)
    -cy, --country      ISO3166 Country Code (by default US)
    -hw, --hwmode       Mode Wi-Fi a = IEEE 802.11a, b = IEEE 802.11b, g = IEEE 802.11g (by default g)

FLAGS:
    -ao, --ap-only      Set only AP (Reboot required)
    -so, --sta-only     Set only STA
    -n, --no-internet   Disable IP forwarding
    -h, --help          Show this help
EOF
    exit 0
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -c | --client)
        CLIENT_SSID="$2"
        CLIENT_PASSPHRASE="$3"
        shift
        shift
        shift
        ;;
    -a | --ap)
        AP_SSID="$2"
        AP_PASSPHRASE="$3"
        shift
        shift
        shift
        ;;
    -i | --ip)
        ARG_AP_IP="$2"
        shift
        shift
        ;;
    -cy | --country)
        ARG_COUNTRY_CODE="$2"
        shift
        shift
        ;;
    -hw | --hwmode)
        ARG_WIFI_MODE="$2"
        shift
        shift
        ;;
    -n | --no-internet)
        NO_INTERNET="true"
        shift
        ;;
    -so | --sta-only)
        STA_ONLY="true"
        shift
        ;;
    -h | --help)
        _usage
        shift
        ;;
    *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done
set -- "${POSITIONAL[@]}"

if [ $(id -u) != 0 ]; then
    echo -e "${RED}"
    echo "You need to be root to run this script! Please run 'sudo bash $0'"
    echo -e "${DEFAULT}"
    exit 1
fi

[ $AP_SSID ] || usage

WIFI_MODE=${ARG_WIFI_MODE:-'g'}
COUNTRY_CODE=${ARG_COUNTRY_CODE:-'US'}
AP_IP=${ARG_AP_IP:-'192.168.10.1'}
AP_IP_BEGIN=$(echo "${AP_IP}" | sed -e 's/\.[0-9]\{1,3\}$//g')
MAC_ADDRESS="$(cat /sys/class/net/wlan0/address)"

# Install dependencies
sudo apt -y install dnsmasq dhcpcd hostapd
sudo apt -y update
sudo apt -y upgrade


    # Populate `/etc/dnsmasq.conf`
sudo bash -c 'cat > /etc/dnsmasq.conf' << EOF
interface=lo,ap@wlan0
no-dhcp-interface=lo,wlan0
bind-interfaces
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=${AP_IP_BEGIN}.50,${AP_IP_BEGIN}.150,12h
EOF

    # Populate `/etc/hostapd/hostapd.conf`
sudo bash -c 'cat > /etc/hostapd/hostapd.conf' << EOF
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
interface=ap@wlan0
driver=nl80211
ieee80211n=1
ssid=${AP_SSID}
hw_mode=${WIFI_MODE}
channel=11
wmm_enabled=0
macaddr_acl=0
auth_algs=1
wpa=2
$([ $AP_PASSPHRASE ] && echo "wpa_passphrase=${AP_PASSPHRASE}")
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP
EOF

# Populate `/etc/default/hostapd`
sudo bash -c 'cat > /etc/default/hostapd' << EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

# Populate `/etc/wpa_supplicant/wpa_supplicant.conf`
sudo bash -c 'cat > /etc/wpa_supplicant/wpa_supplicant.conf' << EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="${CLIENT_SSID}"
    $([ $CLIENT_PASSPHRASE ] && echo "psk=\"${CLIENT_PASSPHRASE}\"")
    id_str="AP1"
}
EOF

# Populate `/etc/network/interfaces`
sudo bash -c 'cat > /etc/network/interfaces' << EOF
source-directory /etc/network/interfaces.d

auto lo
auto ap0
auto wlan0
iface lo inet loopback

allow-hotplug ap0
iface ap0 inet static
    address ${AP_IP}
    netmask 255.255.255.0
    hostapd /etc/hostapd/hostapd.conf

allow-hotplug wlan0
iface wlan0 inet manual
    wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf
iface AP1 inet dhcp
EOF

    sudo chmod 600 /etc/hostapd/hostapd.conf
    sudo bash -c 'SYSTEMD_EDITOR=tee systemctl edit --force --full accesspoint@.service' << EOF
[Unit]
Description=IEEE 802.11 ap@%i AP on %i with hostapd
Wants=wpa_supplicant@%i.service
[Service]
Type=forking
PIDFile=/run/hostapd.pid
Restart=on-failure
RestartSec=2
Environment=DAEMON_CONF=/etc/hostapd/hostapd.conf
EnvironmentFile=-/etc/default/hostapd
ExecStartPre=/sbin/iw dev %i interface add ap@%i type __ap
ExecStart=/usr/sbin/hostapd -i ap@%i -P /run/hostapd.pid -B /etc/hostapd/hostapd.conf
ExecStopPost=-/sbin/iw dev ap@%i del
[Install]
WantedBy=sys-subsystem-net-devices-%i.device
EOF

    # not used, as the agent is hooked by dhcpcd
    sudo systemctl disable wpa_supplicant.service

    # We can then follow Raspberry’s documentation to enable routing and IP masquerading:
    sudo DEBIAN_FRONTEND=noninteractive apt install -y netfilter-persistent iptables-persistent

    sudo bash -c 'cat >/etc/sysctl.d/routed-ap.conf' << EOF
# https://www.raspberrypi.org/documentation/configuration/wireless/access-point-routed.md
# Enable IPv4 routing
net.ipv4.ip_forward=1
EOF


    # Populate `/etc/wpa_supplicant/wpa_supplicant.conf`
sudo bash -c 'cat > /etc/wpa_supplicant/wpa_supplicant.conf' << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=${COUNTRY_CODE}
network={
    ssid="${CLIENT_SSID}"
    $([ $CLIENT_PASSPHRASE ] && echo "psk=\"${CLIENT_PASSPHRASE}\"")
    scan_ssid=1
}
EOF


    systemctl unmask dnsmasq.service
    systemctl enable dnsmasq.service
    sudo systemctl stop hostapd # if the default hostapd service was active before
    sudo systemctl disable hostapd # if the default hostapd service was enabled before
    sudo systemctl enable accesspoint@wlan0.service
    sudo rfkill unblock wlan
    systemctl daemon-reload


# persist powermanagement off for wlan0
grep 'iw dev wlan0 set power_save off' /etc/rc.local || sudo sed -i 's:^exit 0:iw dev wlan0 set power_save off\n\nexit 0:' /etc/rc.local

# Populate `/bin/start_wifi.sh`
sudo bash -c 'cat > /bin/rpi-wifi.sh' << EOF
echo 'Starting Wifi AP and client...'
sleep 30
sudo ifdown --force wlan0
sudo ifdown --force ap0
sudo ifup ap0
sudo ifup wlan0
$([ "${NO_INTERNET-}" != "true" ] && echo "sudo sysctl -w net.ipv4.ip_forward=1")
$([ "${NO_INTERNET-}" != "true" ] && echo "sudo iptables -t nat -A POSTROUTING -s ${AP_IP_BEGIN}.0/24 ! -d ${AP_IP_BEGIN}.0/24 -j MASQUERADE")
$([ "${NO_INTERNET-}" != "true" ] && echo "sudo systemctl restart dnsmasq")
EOF
sudo chmod +x /bin/rpi-wifi.sh

    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
    sudo iptables -A FORWARD -i wlan0 -o ap@wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i ap@wlan0 -o wlan0 -j ACCEPT
    sudo netfilter-persistent save


# persist powermanagement off for wlan0
grep 'iw dev wlan0 set power_save off' /etc/rc.local || sudo sed -i 's:^exit 0:iw dev wlan0 set power_save off\n\nexit 0:' /etc/rc.local

# Finish
if test true == "${STA_ONLY}"; then
    _logger "Reconfiguring wlan for new WiFi connection: ${CLIENT_SSID}"
    _logger " --> please wait (usually 20-30 seconds total)."
    sleep 1
    wpa_cli -i wlan0 reconfigure
    sleep 10
    ifconfig wlan0 down # better way for docker
    sleep 2
    ifconfig wlan0 up # better way for docker
    _logger "STA configuration is finished!"
elif test true == "${AP_ONLY}"; then
    _logger "AP configuration is finished!"
    _logger " --> You MUST REBOOT for the new AP changes to take effect."
elif test true != "${STA_ONLY}" && test true != "${AP_ONLY}"; then
    _logger "AP + STA configurations are finished!"
    _logger " --> You MUST REBOOT for the new AP changes to take effect."
fi

if test true != "${STA_ONLY}"; then
    _logger "Wait during wlan0 reconnecting to internet..."
    sleep 5

    # Finish
echo "Wifi configuration is finished! Please reboot your Raspberry Pi to apply changes..."
