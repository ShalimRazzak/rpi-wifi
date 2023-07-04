#!/bin/bash

# Install hostapd and dnsmasq
sudo apt install hostapd dnsmasq

# Enable and start hostapd
sudo systemctl unmask hostapd
sudo systemctl enable hostapd

# Configure dhcpcd
sudo nano /etc/dhcpcd.conf

# Set static IP address for wlan0
interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant

# Enable IPv4 routing
sudo nano /etc/sysctl.d/routed-ap.conf
net.ipv4.ip_forward=1

# Configure iptables
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo netfilter-persistent save

# Configure dnsmasq
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo nano /etc/dnsmasq.conf

# Set listening interface
interface=wlan0

# Set DHCP range
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h

# Set local wireless DNS domain
domain=wlan

# Set alias for this router
address=/gw.wlan/192.168.4.1

# Unblock wlan interface
sudo rfkill unblock wlan

# Configure hostapd
sudo nano /etc/hostapd/hostapd.conf

# Set country code
country_code=GB

# Set interface
interface=wlan0

# Set SSID
ssid=NameOfNetwork

# Set hw_mode
hw_mode=g

# Set channel
channel=7

# Set macaddr_acl
macaddr_acl=0

# Set auth_algs
auth_algs=1

# Set ignore_broadcast_ssid
ignore_broadcast_ssid=0

# Set wpa
wpa=2

# Set wpa_passphrase
wpa_passphrase=AardvarkBadgerHedgehog

# Set wpa_key_mgmt
wpa_key_mgmt=WPA-PSK

# Set wpa_pairwise
wpa_pairwise=TKIP

# Set rsn_pairwise
rsn_pairwise=CCMP

# Reboot
sudo systemctl reboot
