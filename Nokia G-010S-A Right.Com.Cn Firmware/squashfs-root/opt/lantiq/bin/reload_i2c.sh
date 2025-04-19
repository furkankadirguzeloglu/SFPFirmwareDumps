#!/bin/sh

DEBUG_LEVEL=${1:-"3"}

[ -e /etc/init.d/sfp_eeprom.sh ] && /etc/init.d/sfp_eeprom.sh stop
rmmod mod_sfp_i2c
insmod mod_sfp_i2c debug=${DEBUG_LEVEL}
[ -e /etc/init.d/sfp_eeprom.sh ] && /etc/init.d/sfp_eeprom.sh boot
