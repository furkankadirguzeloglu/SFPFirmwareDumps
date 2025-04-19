#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2011, 2016 lantiq.com

. $IPKG_INSTROOT/lib/falcon.sh

START=64

BOARD_NAME=$(falcon_board_name)

log() {
	logger -s -p daemon.err -t "[onu]" "$*" 2> /dev/console
}

debug=${V:-0}

onu() {
	local dbg
	dbg="true" #will ignore options and don't print
	[ $debug -eq 1 ] && dbg="echo"
	if [ "$1" = "-v" ]; then
		dbg="echo"
		shift
	fi
	$dbg "onu $*"
	result=`/opt/lantiq/bin/onu $*`
	$dbg "result $result"
	status=${result%% *}
	if [ "$status" != "errorcode=0" ]; then
		log "onu $* failed: $result"
	fi
}

get_default_settings() {
	gphy_fw_mode="2" # 11G as default
	mdio_speed="2" # 2.5MHz, as defined by standard

	for i in 0 1 2 3; do
		eval "port_mux_$i=\"\""
		eval "port_mode_$i=\"\""
		eval "port_capability_$i=\"\""
		# default: assume no phys
		eval "phy_addr_$i=\"-1\""
	done

	clk_delay="0 0"
	max_frame_size=1518

	autoneg_mode="0" # SGMII_NO_ANEG
	invrx="0"
	invtx="0"

	loop_ports=""
}

gpon_lan_netdev_cfg() {
	[ -n "$2" ] && onu lannics $1 $2
}

gpon_lan_port_set() {
	local pport=$1
	local phy_addr=$2
	local port_mux=$3
	local port_mode=$4
	local port_capability=$5
	[ -z "$port_mux" ] && return
	onu lanpcs $pport $lanpe $phy_addr $port_mux $port_mode $clk_delay $max_frame_size 1 $autoneg_mode $invtx $invrx
	# only set if phy_addr is not -1 and capabilities are defined
	[ "$phy_addr" != "-1" -a "$port_capability" ] && onu lanpccs $pport $port_capability
}

gpon_lan_port_disable() {
	[ -n "$2" ] && onu lanpd $1
}


# "constants" for gpon_lan_mux
MUX_RGMII0="5 5"
MUX_RGMII1="6 5"
MUX_GMII_MAC="5 8"
MUX_MII_MAC="5 10"
MUX_RMII0="5 6"
MUX_RMII1="6 6"
MUX_GMII_PHY="5 9"
MUX_MII_PHY="5 11"
MUX_TMII_PHY="5 13"
MUX_SGMII_TBI_AUTODETECT="4 15"
MUX_SGMII_TBI_SERDES="4 14"

gpon_lan_mux() {
	local mux="$2 $3"
	eval "port_mux_$1=\"$mux\""
	eval "phy_addr_$1=\"-1\""
	eval "port_capability_$1=\"\""
}

gpon_lan_phy_auto() {
	eval "phy_addr_$1=\"$2\""
	eval "port_capability_$1=\"1 1 1 1 1 1 1 1\""
	eval "port_mode_$1=\"0 0 0\""
	mdio_speed="0" # default for GPHY/EEE
}

gpon_lan_phy_fixed() {
	eval "phy_addr_$1=\"$2\""
	eval "port_capability_$1=\"1 1 1 1 1 1 1 1\""
	eval "port_mode_$1=\"$3\""
	mdio_speed="0" # default for GPHY/EEE
}

gpon_lan_gphy() {
	local pport=$1
	local gphynr=$2
	local mux=$(expr $gphynr \* 2)
	gpon_lan_mux $pport $mux 1
	gpon_lan_phy_auto $pport $gphynr
}

gpon_lan_ephy() {
	local pport=$1
	local ephynr=$2
	gpon_lan_mux $pport $ephynr 2
	gpon_lan_phy_auto $pport $ephynr
	eval "port_capability_$pport=\"1 1 1 1 0 1 1 1\""
}

# options for sgmii mode:
SGMII=3
TBI_SERDES=14
TBI_AUTODETECT=15
gpon_lan_phy_sgmii() {
	local pport=$1
	local mode=$2
	local speedmode=${3:-"0 0 0"}
	gpon_lan_mux $pport 4 $mode
	eval "port_mode_$1=\"$speedmode\""
}

gpon_lan_fixed_rgmii() {
	local mux
	local pport
	loop_ports="$*"
	for i in 0 1; do
		[ $1 ] && {
			pport=$1
			shift
			case "$i" in
				0) mux="$MUX_RGMII0" ;;
				1) mux="$MUX_RGMII1" ;;
				*) return ;;
			esac
			gpon_lan_mux $pport $mux
			# Full Duplex, Flow Control RXTX, 1G
			eval "port_mode_$pport=\"1 3 4\""
		}
	done
	clk_delay="1 1"
}

gpon_mac_loop_enable() {
	for i in $*; do
		onu lanlcs $i 1 0 0 0 0 0 0
	done
}

decode_sgmii_mode() {
	local SGMII_PORT=$1

	case $(falcon_sgmii_mode) in
	1)
		# SGMII, LAN_MODE_SPEED_AUTO
		gpon_lan_phy_sgmii ${SGMII_PORT} $SGMII
		autoneg_mode="1" # SGMII_MAC_ANEG
		;;
	2)
		# SGMII, LAN_MODE_SPEED_2500
		gpon_lan_phy_sgmii ${SGMII_PORT} $SGMII "1 0 5"
		autoneg_mode="0" # SGMII_NO_ANEG
		;;
	3)
		# TBI_SERDES, LAN_MODE_SPEED_1000
		gpon_lan_phy_sgmii ${SGMII_PORT} $TBI_SERDES "1 0 4"
		autoneg_mode="3" # SGMII_SERDES_ANEG
		;;
	4)
		# TBI_SERDES, LAN_MODE_SPEED_1000
		gpon_lan_phy_sgmii ${SGMII_PORT} $TBI_SERDES "1 0 4"
		autoneg_mode="0" # SGMII_NO_ANEG
		;;
	5)
		# TBI_AUTODETECT, LAN_MODE_SPEED_2500
		gpon_lan_phy_sgmii ${SGMII_PORT} $TBI_AUTODETECT "1 0 5"
		autoneg_mode="3" # SGMII_SERDES_ANEG
		;;
	*) # default mode, auto
		# TBI_AUTODETECT
		gpon_lan_phy_sgmii ${SGMII_PORT} $TBI_AUTODETECT
		autoneg_mode="3" # SGMII_SERDES_ANEG
		;;
	esac
}

get_easy98000_addon_ports() {
	local module
	module=`cat /proc/cpld/xmii`
	[ "$MODULE" ] && module=$MODULE
	case "$module" in
	"RGMII module"*) # GPHY RGMII addon board
		gpon_lan_mux 2 $MUX_RGMII0
		gpon_lan_phy_auto 2 4
		gpon_lan_mux 3 $MUX_RGMII1
		gpon_lan_phy_auto 3 5
		clk_delay="1 1"
		netdev_cfg_2="4 -1"
		netdev_cfg_3="5 -1"
		;;
	"GMII PHY"*) # GPHY GMII addon board
		gpon_lan_mux 2 $MUX_GMII_MAC
		gpon_lan_phy_fixed 2 4 "1 0 4"
		;;
	"MII PHY"*) # GPHY MII addon board
		gpon_lan_mux 2 $MUX_MII_MAC
		gpon_lan_phy_fixed 2 4 "1 0 2"
		;;
	"RMII PHY"*) # GPHY RMII addon board
		gpon_lan_mux 2 $MUX_RMII0
		gpon_lan_phy_auto 2 4
		gpon_lan_mux 3 $MUX_RMII1
		gpon_lan_phy_auto 3 5
		;;
	"GMII MAC"*) # Tantos GMII addon board
		gpon_lan_mux 2 $MUX_GMII_PHY
		port_mode_2="1 0 4"
		;;
	"MII MAC"*) # Tantos MII addon board
		gpon_lan_mux 2 $MUX_MII_PHY
		port_mode_2="1 0 2"
		;;
	"TMII MAC"*) # Tantos TMII addon board
		gpon_lan_mux 2 $MUX_TMII_PHY
		port_mode_2="1 0 3"
		;;
	*) # none/unknown
		;;
	esac
	if [ -e "/proc/cpld/sgmii" ]; then
		module=`cat /proc/cpld/sgmii`
		case "$module" in
		"SGMII"*) # SGMII addon board
			# use SGMII port instead of GPHY0 (0) or RGMII1 (3)
			SGMII_PORT=0
			# assume PHY with MDIO (1) or no MDIO (0)
			MDIO=0
			if [ $MDIO == 1 ]; then
				gpon_lan_phy_sgmii ${SGMII_PORT} $TBI_AUTODETECT
				gpon_lan_phy_auto ${SGMII_PORT} 6
				autoneg_mode="1" # SGMII_MAC_ANEG
			else
				decode_sgmii_mode ${SGMII_PORT}
			fi
			invrx="0"
			invtx="1"

			# for debugging: set lower debug level
			#onu onudls 1
			;;
		*) # none/unknown
			;;
		esac
	fi
}

get_gpon_lan_ports() {
	get_default_settings
	case $BOARD_NAME in
	easy98000)
		gpon_lan_gphy 0 0
		gpon_lan_gphy 1 1
		get_easy98000_addon_ports
		;;
	easy98000_4fe) # four times FE
		gphy_fw_mode="1" # 11F firmware
		gpon_lan_ephy 0 0
		gpon_lan_ephy 1 1
		gpon_lan_ephy 2 2
		gpon_lan_ephy 3 3
		#phy_addr_0="0"
		#phy_addr_1="1"
		#phy_addr_2="2"
		#phy_addr_3="3"
		#port_mux_0="0 2" # FEPHY0, EPHY
		#port_mux_1="1 2" # FEPHY1, EPHY
		#port_mux_2="2 2" # FEPHY2, EPHY
		#port_mux_3="3 2" # FEPHY3, EPHY
		#port_capability_0="1 1 1 1 0 1 1 1"
		#port_capability_1="1 1 1 1 0 1 1 1"
		#port_capability_2="1 1 1 1 0 1 1 1"
		#port_capability_3="1 1 1 1 0 1 1 1"
		clk_delay="1 1"
		;;
	easy98000_serdes) # SERDES Test-config
		gpon_lan_gphy 0 0
		gpon_lan_gphy 1 1
		decode_sgmii_mode 3
		invrx="0"
		invtx="1"
		# for debugging: set lower debug level
		onu onudls 1
		;;
	easy98021)
		gpon_lan_gphy 0 0
		gpon_lan_gphy 1 1
		;;
	easy98020)
		gpon_lan_gphy 0 0
		gpon_lan_gphy 1 1
		gpon_lan_mux 2 $MUX_RGMII0
		gpon_lan_phy_auto 2 5
		gpon_lan_mux 3 $MUX_RGMII1
		gpon_lan_phy_auto 3 6
		;;
	easy98010)
		gpon_lan_gphy 0 0
		;;
	MDU*)
		gpon_lan_mux 0 $MUX_GMII_MAC
		port_mode_0="1 4 4"
		gpon_lan_gphy 1 0
		clk_delay="2 2"
		;;
	easy98035synce1588) # SFP module with F24S
		# use RGMIIB
		gpon_lan_mux 0 $MUX_RGMII1
		port_mode_0="1 3 4"
		clk_delay="0 0"
		# F24S is at MDIO 31, IRQ is connected to GPIO110 (42)
		netdev_cfg_0="0x1f 42"
		# for debugging: set lower debug level
		#onu onudls 1
		;;
	SFP|easy98035*) # SFP module
		# enable SGMII on boot directly
		lanpe="1"
		decode_sgmii_mode 0
		# for debugging: set lower debug level
		#onu onudls 1
		# "disable" the MDIO pins, switch to "gpio, input"
		echo 7 > /sys/class/gpio/export
		echo 8 > /sys/class/gpio/export
		;;
	CTTDP*)
		gmii_port=0
		sgmii_port=2

		# SGMII to PUMA
		gpon_lan_mux $sgmii_port $MUX_SGMII_TBI_AUTODETECT
		# LAN_MODE_SPEED_AUTO, flow control disabled
		eval "port_mode_$sgmii_port=\"0 4 0\""
		autoneg_mode="3" # SGMII_SERDES_ANEG

		# GMII to VINAX
		gpon_lan_mux $gmii_port $MUX_GMII_MAC
		eval "port_mode_$gmii_port=\"1 4 4\""

		# loop on "GPHY1"
		gpon_lan_mux 3 "2 1"
		port_mode_3="1 3 4"
		loop_ports="3"
		;;
	GFAST*)
		# enable SGMII on boot directly
		lanpe="1"
		decode_sgmii_mode 0
		# for debugging: set lower debug level
		#onu onudls 1
		# "disable" the MDIO pins, switch to "gpio, input"
		echo 7 > /sys/class/gpio/export
		echo 8 > /sys/class/gpio/export

		# loop on "GPHY1"
		gpon_lan_mux 3 "2 1"
		port_mode_3="1 3 4"
		loop_ports="3"
		;;
	easy88381|easy88384|easy88388|FTTDP8*) # Generic FTTdp8 DPU module
		gmii_port=1
		sgmii_port=0
		case "$(uci get fttdp.internal_interface.interface_mode 2> /dev/null)" in
		gmii*)
			gmii_port=0
			sgmii_port=1
			;;
		esac
		
		# SGMII to VINAX
		gpon_lan_mux $sgmii_port $MUX_SGMII_TBI_SERDES
		# LAN_MODE_SPEED_1000, FULL DUPLEX, flow control disabled
		eval "port_mode_$sgmii_port=\"1 0 4\""
		autoneg_mode="0" # SGMII_NO_ANEG
		
		# GMII to VINAX
		gpon_lan_mux $gmii_port $MUX_GMII_MAC
		eval "port_mode_$gmii_port=\"1 4 4\""

		gpon_lan_gphy 2 0
		#gpon_lan_gphy 2 1 # alternative: GPHY1
		# loop on "GPHY1"
		gpon_lan_mux 3 "2 1"
		port_mode_3="1 3 4"
		loop_ports="3"
		;;
	easy98000_FTTDP8) # FTTDP8 simulation on easy98000
		gpon_lan_gphy 0 1
		get_easy98000_addon_ports
		# override port 2 as LCT on GPHY1
		gpon_lan_gphy 2 0

		# loop on "port 3", here use RGMII0
		gpon_lan_fixed_rgmii 3
		;;
	easy98020_CTTDP8) # CTTDP8 simulation on easy98020
		gpon_lan_gphy 0 0

		gpon_lan_mux 2 $MUX_RGMII0
		gpon_lan_phy_auto 2 5

		# loop on "GPHY1"
		gpon_lan_mux 3 "2 1"
		port_mode_3="1 3 4"
		loop_ports="3"
		;;
	esac
}

enable_gpon_lan_ports() {
	case $BOARD_NAME in
	MDU*)
		# enable data port towards the Vinax
		# ensure that CLKOC_OEN is enabled
		onu lanpe 0
		# enable the tagging towards the Vinax
		# please refer to the gpe_sce_constants_get command / vinax_tag element
		# by default the tag is configured to 0x8100000A (VLAN ID 10)
		onu gpevtcs 0 1
		;;
	esac
	
	case $BOARD_NAME in		
		CTTDP1|FTTDP1|easy88381*)
			onu onu_portmap_set 3 0 2 3 0 0 0 0 0 0 0 0
			;;
		CTTDP4|FTTDP4|easy88384*)
			onu onu_portmap_set 6 0 0 0 0 2 3 0 0 0 0 0
			;;
		CTTDP8|FTTDP8|easy98000_FTTDP8|easy88388*)
			config_load fttdp
			config_get interface_mode internal_interface interface_mode none

			case "$interface_mode" in
				sgmii|gmii)
					# in case of using 2nd LCT below is a FTTDP8_2LCT configuration to use
					onu onu_portmap_set 10 0 0 0 0 0 0 0 0 2 3 0
					;;
				sgmii_gmii)
					onu onu_portmap_set 10 0 0 0 0 1 1 1 1 2 3 0
					;;
				*)
					log "Invalid FTTDP setting - interface_mode not configured!"
					onu onu_portmap_set 4 0 1 2 3 0 0 0 0 0 0 0
					return -1
					;;
			esac
			;;
		# 2nd LCT FTTDP8 scenario
		FTTDP8_2LCT)
			config_load fttdp
			config_get interface_mode internal_interface interface_mode none
		
			case "$interface_mode" in
				sgmii|gmii)
					onu onu_portmap_set 11 0 0 0 0 0 0 0 0 2 3 1
					;;
				*)
					log "Invalid FTTDP setting - interface_mode not configured!"
					onu onu_portmap_set 4 0 1 2 3 0 0 0 0 0 0 0
					return -1
					;;
			esac
			;;

		*)
			if [ -f "/etc/config/.fttdp" ]; then
				config_load fttdp
				config_get interface_mode internal_interface interface_mode none

				case "$interface_mode" in
					sgmii|gmii)
						onu onu_portmap_set 10 0 0 0 0 0 0 0 0 2 3 0
						;;
					sgmii_gmii)
						onu onu_portmap_set 10 0 0 0 0 1 1 1 1 2 3 0
						;;
					*)
						log "Invalid FTTDP setting - interface_mode not configured!"
						onu onu_portmap_set 4 0 1 2 3 0 0 0 0 0 0 0
						return -1
						;;
				esac
			else
				onu onu_portmap_set 4 0 1 2 3 0 0 0 0 0 0 0
			fi
			
			;;
	esac
}

configure_fttdp_interface() {
	case $BOARD_NAME in
	GFAST)
		# SINGLE interface, 8 LPORTs, without Eth uplink, with Management channel, without 2nd LCT 
		onu gpe_fttdp_if_cfg_set 1 8 0 1 0
		# cir/pir to 630Mbit - 2% = 618 Mbit
		onu gpe_fttdp_ds_flow_shaper_rate_set 77250000 77250000
		
		# pause frame masks: 76 54 32 10, set bit = Xoff
		onu gpe_fttdp_ds_flow_pause_mask_set 0 0x01000000
		onu gpe_fttdp_ds_flow_pause_mask_set 1 0x02000000
		onu gpe_fttdp_ds_flow_pause_mask_set 2 0x04000000
		onu gpe_fttdp_ds_flow_pause_mask_set 3 0x08000000
		onu gpe_fttdp_ds_flow_pause_mask_set 4 0x10000000
		onu gpe_fttdp_ds_flow_pause_mask_set 5 0x20000000
		onu gpe_fttdp_ds_flow_pause_mask_set 6 0x40000000
		onu gpe_fttdp_ds_flow_pause_mask_set 7 0x80000000
		;;
	CTTDP1|CTTDP4|CTTDP8|FTTDP1|FTTDP4|FTTDP8*|easy88381*|easy88384*|easy88388*|easy98000_FTTDP8)
		case $BOARD_NAME in
		CTTDP1)
			# SINGLE interface, 1 LPORT, with Eth uplink, without Management channel, without 2nd LCT 
			onu gpe_fttdp_if_cfg_set 1 1 1 0 0
			;;
		CTTDP4)
			# SINGLE interface, 4 LPORTs, with Eth uplink, without Management channel, without 2nd LCT 
			onu gpe_fttdp_if_cfg_set 1 4 1 0 0
			;;
		CTTDP8)
			# SINGLE interface, 8 LPORTs, with Eth uplink, without Management channel, without 2nd LCT 
			onu gpe_fttdp_if_cfg_set 1 8 1 0 0
			;;
		FTTDP1|easy88381*)
			# SINGLE interface, 1 LPORT, without Eth uplink, without Management channel, without 2nd LCT 
			onu gpe_fttdp_if_cfg_set 1 1 0 0 0
			;;
		FTTDP4|easy88384*)
			# SINGLE interface, 4 LPORTs, without Eth uplink, without Management channel, without 2nd LCT 
			onu gpe_fttdp_if_cfg_set 1 4 0 0 0
			;;
		FTTDP8|easy98000_FTTDP8|easy88388*)
			config_load fttdp
			config_get interface_mode internal_interface interface_mode none

			case "$interface_mode" in
			sgmii|gmii)
				# SINGLE interface, 8 LPORTs, without Eth uplink, without Management channel, without 2nd LCT 
				# in case of using 2nd LCT below is a FTTDP8_2LCT configuration to use
				onu gpe_fttdp_if_cfg_set 1 8 0 0 0
				;;
			sgmii_gmii)
				# DUAL interface, 8 LPORTs (4+4), without Eth uplink, without Management channel, without 2nd LCT 
				onu gpe_fttdp_if_cfg_set 2 8 0 0 0
				;;
			*)
				log "Invalid FTTDP setting - interface_mode not configured!"
				return -1
				;;
			esac
			;;
		# 2nd LCT FTTDP8 scenario
		FTTDP8_2LCT)
			config_load fttdp
			config_get interface_mode internal_interface interface_mode none
		
			case "$interface_mode" in
			sgmii|gmii)
				# SINGLE interface, 8 LPORTs, without Eth uplink, without Management channel, with 2nd LCT 
				onu gpe_fttdp_if_cfg_set 1 8 0 0 1
				;;
			*)
				log "Invalid FTTDP setting - interface_mode not configured!"
				return -1
				;;
			esac
			;;
		esac

		# cir/pir to 200Mbit - 2% = 196 Mbit
		onu gpe_fttdp_ds_flow_shaper_rate_set 24500000 24500000
		
		# pause frame masks: 10 32 54 76, set bit = Xoff
		onu gpe_fttdp_ds_flow_pause_mask_set 0 0x0F000000
		onu gpe_fttdp_ds_flow_pause_mask_set 1 0xF0000000
		onu gpe_fttdp_ds_flow_pause_mask_set 2 0x000F0000
		onu gpe_fttdp_ds_flow_pause_mask_set 3 0x00F00000
		onu gpe_fttdp_ds_flow_pause_mask_set 4 0x00000F00
		onu gpe_fttdp_ds_flow_pause_mask_set 5 0x0000F000
		onu gpe_fttdp_ds_flow_pause_mask_set 6 0x0000000F
		onu gpe_fttdp_ds_flow_pause_mask_set 7 0x000000F0
		;;
	esac
}

load_synce_pins() {

	config_get name $1 name
	config_get pin $1 pin
	config_get restriction $1 restriction

	[ -z "$restriction" ] || {
		for r in $restriction_list; do
			if [ "$r" == "$restriction" ]; then
				return
			fi
		done
	}
	eval "${name}=$pin"
}

synce_config() {
	local cfg="ethernet"
	local nSyncE_Mode
	local bSyncE_SGMII_Squelch
	nGPIO_ExtPLL_LD="-1"
	nGPIO_ExtPLL_CF="-1"

	if [ -f "/etc/config/synce" ]; then
		config_load synce_pins
		config_foreach load_synce_pins pin
		onu lan_synce_pin_cfg_set $nGPIO_ExtPLL_LD  $nGPIO_ExtPLL_CF

		if [ -f "/opt/lantiq/bin/squelchd" ]; then
			/opt/lantiq/bin/squelchd -d -s -w /sys/devices/virtual/gpondev/onu0/falcon_mdio:1f/squelch &
		fi

		config_load synce
		config_get nSyncE_Mode          ${cfg} nSyncE_Mode 255
		config_get bSyncE_SGMII_Squelch ${cfg} bSyncE_SGMII_Squelch
		onu lan_synce_cfg_set $nSyncE_Mode $bSyncE_SGMII_Squelch
	fi
}

################################################################################
# default functions for init scripts

boot() {
	get_gpon_lan_ports
	onu lani

	onu lancs $gphy_fw_mode $mdio_speed 0 1

	gpon_lan_netdev_cfg 0 "$netdev_cfg_0"
	gpon_lan_netdev_cfg 1 "$netdev_cfg_1"
	gpon_lan_netdev_cfg 2 "$netdev_cfg_2"
	gpon_lan_netdev_cfg 3 "$netdev_cfg_3"
	onu lannoi

	# configure Synchronous Ethernet
	synce_config

	lanpe="0"
	start
}

start() {
	if [ "$lanpe" == "" ]; then
		get_gpon_lan_ports
		lanpe="1"
	fi

	gpon_lan_port_set 0 "$phy_addr_0" "$port_mux_0" "$port_mode_0" "$port_capability_0"
	gpon_lan_port_set 1 "$phy_addr_1" "$port_mux_1" "$port_mode_1" "$port_capability_1"
	gpon_lan_port_set 2 "$phy_addr_2" "$port_mux_2" "$port_mode_2" "$port_capability_2"
	gpon_lan_port_set 3 "$phy_addr_3" "$port_mux_3" "$port_mode_3" "$port_capability_3"

	gpon_mac_loop_enable $loop_ports

	# Set default Lantiq Pause Frames MAC Source Address configuration
	onu lan_pause_mac_cfg_set 0 0xAC 0x9A 0x96 0x00 0x01 0x00

	enable_gpon_lan_ports
	
	configure_fttdp_interface
}

stop() {
	get_gpon_lan_ports
	gpon_lan_port_disable 0 "$port_mux_0"
	gpon_lan_port_disable 1 "$port_mux_1"
	gpon_lan_port_disable 2 "$port_mux_2"
	gpon_lan_port_disable 3 "$port_mux_3"
}

EXTRA_COMMANDS="dump"
EXTRA_HELP="	dump	dump settings for all boards"

BOARDS="easy98000 easy98000_4fe easy98000_serdes easy98021 easy98020 easy98010 MDU SFP FTTDP8 FTTDP8_2LCT"
MODULES="RGMII module;GMII PHY;MII PHY;RMII PHY;GMII MAC;MII MAC;TMII MAC"
do_dump() {
	get_gpon_lan_ports
	echo 0 "*" "$phy_addr_0" "*" "$port_mux_0" "$port_mode_0" "*" "$port_capability_0"
	echo 1 "*" "$phy_addr_1" "*" "$port_mux_1" "$port_mode_1" "*" "$port_capability_1"
	echo 2 "*" "$phy_addr_2" "*" "$port_mux_2" "$port_mode_2" "*" "$port_capability_2"
	echo 3 "*" "$phy_addr_3" "*" "$port_mux_3" "$port_mode_3" "*" "$port_capability_3"
}
dump() {
	MODULE="no"
	echo "dump start"
	for BOARD_NAME in $BOARDS; do
		echo DUMP for board $BOARD_NAME
		do_dump
	done
	BOARD_NAME=easy98000
	IFS=";"
	for MODULE in $MODULES; do
		echo DUMP for module $MODULE
		do_dump
	done

	echo "dump end"
}
