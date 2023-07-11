# Simultaneous AP and Managed Mode Wifi on Raspberry Pi

###### Special thanks to: https://albeec13.github.io/2017/09/26/raspberry-pi-zero-w-simultaneous-ap-and-managed-mode-wifi/

###### Special thanks to: https://github.com/lukicdarkoo/rpi-wifi

###### Special thanks to: https://https://github.com/MkLHX/AP_STA_RPI_SAME_WIFI_CHIP

###### This repo was forked from https://github.com/lukicdarkoo/rpi-wifi

<h2>Video Demonstration</h2>

- ### [YouTube: Raspberry Pi zero w Wifi extender on the same chip How to!!](https://youtu.be/9yh4li--poI)
  

<h2>Environments and Technologies Used</h2>
- This works on Raspberry Pi OS Lite (Legacy): https://www.raspberrypi.com/software/operating-systems/

Release date: May 3rd 2023
System: 32-bit
Kernel version: 5.10
Debian version: 10 (buster)

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
  for i in {1..2}; do curl https://raw.githubusercontent.com/ShalimRazzak/rpi-wifi/master/PIxT_Config | sudo bash -s -- -a MyAP myappass -c WifiSSID wifipass; done
```
- Replace `MyAP` and `myappass` with ssid and password of the network you want to create and replace `WifiSSID` `wifipass` with ssid and password of your existing wifi network. Note: Make sure that the length of the password you set is greater than 7 characters, otherwise this fails.
- Reboot Pi Zero W
- Profit
