# Simultaneous AP and Managed Mode Wifi on Raspberry Pi

###### Special thanks to: https://albeec13.github.io/2017/09/26/raspberry-pi-zero-w-simultaneous-ap-and-managed-mode-wifi/

###### This repo was forked from https://github.com/lukicdarkoo/rpi-wifi

## About
This repo was forked from https://github.com/lukicdarkoo/rpi-wifi. This fork logs the settings and steps that worked for a Raspberry Pi Zero W.

- This works on Raspbian Lite 2019-07-12 (buster): https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-07-12/
- After etching buster into a sd card and setting up ssh and wpa_supplicant.conf for remote access, ssh into the PI. In the pi terminal run `sudo apt update`, accept the prompts.
  - Your `wpa_supplicant.conf` file should look like the following:
  
    ```
    country=US
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    update_config=1
    
    network={
        ssid="YOUR_WIFI_SSID"
        psk="YOUR_WIFI_PASSWORD"
    }
    ```
  - To create an empty ssh file inside the Boot: folder of the sd card do:
    `type NUL >> ssh` on Windows (command prompt) and `touch ssh` on Unix (Terminal)
- Once this is done, run:
```
curl https://raw.githubusercontent.com/ShalimRazzak/rpi-wifi/master/configure | bash -s -- -a MyAP myappass -c WifiSSID wifipass
```
- Replace `MyAP` and `myappass` with ssid and password of the network you want to create and replace `WifiSSID` `wifipass` with ssid and password of your existing wifi network. Note: Make sure that the length of the password you set is greater than 7 characters, otherwise this fails.
- Reboot Pi Zero W
- Profit

## Usage for bullseye
```
To run this script, save it as a file with the .sh extension and then run it with the following command:

bash script.sh


curl https://raw.githubusercontent.com/ShalimRazzak/rpi-wifi/master/wipitest.sh | bash script.sh -s -- -a MyAP myappass -c WifiSSID wifipass
```
