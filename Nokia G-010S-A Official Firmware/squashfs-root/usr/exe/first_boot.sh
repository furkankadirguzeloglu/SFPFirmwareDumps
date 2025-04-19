#!/bin/sh

####################################################################
#
# Alcatel-Lucent ONT first boot Init script
#
# Descrtion: will execute this script when boot after SW upgrading.
#	     function module can add into own sub-script.
#
# Note: this script will be deleted at the end of startup.
#
# <Fuguo.Xu@alcatel-sbell.com.cn>, 14/12/2012
####################################################################

FIRST_BOOT_DIR=/tmp/first_boot

mkdir -p $FIRST_BOOT_DIR

#set first boot flag for TR069
touch $FIRST_BOOT_DIR/first_boot_flag_tr069

#set first boot flag for cfgmgr
touch $FIRST_BOOT_DIR/first_boot_flag_cfgmgr

#set first boot flag for /etc/ process
touch $FIRST_BOOT_DIR/first_boot_flag_etc_process

#set first boot flag for cfgmgr
touch $FIRST_BOOT_DIR/first_boot_flag_voice

#set first boot flag for cleaner, remove junk files.
touch $FIRST_BOOT_DIR/first_boot_flag_cleaner

