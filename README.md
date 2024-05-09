# House Server Docker Setup

This is a unified docker-compose setup to run the following things in our life:

## Smart Home Stuff
* A [Zigbee](https://www.zigbee2mqtt.io) bridge to control lights and such
* A [Homebridge](https://homebridge.io) server to expose Zigbee stuff to HomeKit
* A [HAP](https://github.com/mtrudel/hap) instance to control our skylight blinds
* A [Zigbee2soco](https://github.com/kristianwiklund/zigbee2soco) instance to control Sonos speakers via IKEA Symfonisk remotes

## Network Stuff
* A [UniFi](https://ui.com) controller
* A Grafana & Prometheus stack to graph all sorts of things
* A tailscale node
* A number of exporters that Prometheus uses as data sources

## Various Stuff
* An RTL-SDR powered ADSB stack that publishes to flightradar24
* A dockerized version of the [PiDP-11](https://obsolescence.wixsite.com/obsolescence/pidp-11) emulator
* An AirPrint bridge for our ancient laser printer
* A simple Alpine-based sandbox for futzing around in
* Backups and proxy server for all of the above

All of this runs on a single RPi 4 (8GB) in our house, with quite a bit of extra room.

## Setting up the Pi

Raw notes from the last time I set the box up. This is more of a 'note to self'
section than anything prescriptive. YMMV etc.

* Set the RPi to boot from USB (instructions [here](https://www.tomshardware.com/how-to/boot-raspberry-pi-4-usb))
* Install 64 bit raspbian on an sdcard
* Enable ssh on sdcard (touch ssh)
* Boot up from sdcard
* sudo apt-get install git
* move to USB
  * git clone https://github.com/billw2/rpi-clone.git
  * ./rpi-clone sda -f2
  * reboot
* Vaidate that we rebooted from USB
* Run passwd, change to something hard (save in 1Password)
* run raspi-config
  * Set up i2c
  * Lower GPU memory to 16
  * Set hostname
  * Ensure the following is in /boot/config.txt
      ```
      [all]
      gpu_mem=16

      # turn off LEDs
      dtoverlay=act-led

      ##disable ACT LED
      dtparam=act_led_trigger=none
      dtparam=act_led_activelow=off

      ##disable PWR LED
      dtparam=pwr_led_trigger=none
      dtparam=pwr_led_activelow=off

      ##turn off ethernet port LEDs
      dtparam=eth_led0=4
      dtparam=eth_led1=4

      ##turn on/ off bluetooth
      dtoverlay=disable-bt

      ##turn on/off wifi
      dtoverlay=disable-wifi
      ```
  * reboot
* touch .hushlogin
* append bind ‘set enable-bracketed-paste off’ to .bashrc
* Install docker
  * curl -fsSL https://get.docker.com -o get-docker.sh
  * sudo sh get-docker.sh
  * rm get-docker.sh
  * sudo usermod -aG docker $USER
  * reboot
* install external hub with [ZigBee](https://sonoff.tech/product/gateway-and-sensors/sonoff-zigbee-3-0-usb-dongle-plus-p/) dongle (it MUST be in a USB2 port)
* git clone git@github.com:mtrudel/pibox.git
  * Ensure that all hostnames in Caddyfile are set up on router, pointing to the same IP as pibox
  * Set up a docker macvlan network:
    ```
    > docker network create -d macvlan --gateway 192.168.10.1 --ip-range 192.168.10.33/27 --subnet 192.168.10.0/24 -o parent=eth0 dockervlan
    ```
  * docker compose up -d
  * Shell into the zigbee2mqtt controller (`docker compose run -it zigbee2mqtt
  /bin/sh`) and set up data/configuration.conf
  enough to get the container started (you can configure the rest from the GUI)
  * go to homebridge
    * install homebridge-z2m
