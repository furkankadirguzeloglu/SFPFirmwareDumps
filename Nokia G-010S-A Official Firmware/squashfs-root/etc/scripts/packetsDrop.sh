#!/bin/sh
#set -x

# Retrieve packet numbers at lan port
# Command "onu lan_total_counter_get 0" like this. rx_frames is US packet numer, tx_frames is DS.
# ONTUSER@SFP:/tmp# onu lan_total_counter_get 0
#   errorcode=0 lport=0 rx_frames=2977699 rx_bytes=381145472 tx_frames=5007794 tx_bytes=600935218 ...
read_lan_packet_number()
{
  LAN_PKT_NUM=$(onu lan_total_counter_get 0)
  LAN_PKT_NUM_US=$(echo ${LAN_PKT_NUM#*rx_frames=} | cut -f1 -d" ")
  LAN_PKT_NUM_DS=$(echo ${LAN_PKT_NUM#*tx_frames=} | cut -f1 -d" ")
}

# Retrieve packet numbers at bridge port
# Command "onu gpe_bridge_port_total_counter_get" like this. ibp_good is US packet numer, ebp_good is DS.
#   errorcode=0 index=0 learning_discard=0 ibp_good=2977699 ibp_discard=0 ebp_good=5007791 ebp_discard=0 
read_bp_packet_number()
{
  BP_PKT_NUM=$(onu gpe_bridge_port_total_counter_get 0)
  BP_PKT_NUM_US=$(echo ${BP_PKT_NUM#*ibp_good=} | cut -f1 -d" ")
  BP_PKT_NUM_DS=$(echo ${BP_PKT_NUM#*ebp_good=} | cut -f1 -d" ")
}

# Retrieve packet numbers at GEM port
# PQ mapper table ID is 66
# Command "onu gpe_bridge_port_total_counter_get" like this. ibp_good is US packet numer, ebp_good is DS.
#   errorcode=0 index=0 learning_discard=0 ibp_good=2977699 ibp_discard=0 ebp_good=5007791 ebp_discard=0 
read_gem_packet_number()
{
  let GEM_PKT_US=0
  let GEM_PKT_DS=0
  # Looks while block after a pipeline is executed in a seperate sub shell so 
  # varialbe values are not available out of while loop. Change to use for
  #   echo ${GEM_PORTS} | cut -f1- -d" " | tr ' ' '\n' | while read GEM_PORT_TMP
  for GEM_PORT_TMP in $(echo ${GEM_PORTS})
  do
    GEM_PKT_TMP=$(onu gpe_gem_total_counter_get $((0x${GEM_PORT_TMP})))
    if [ $? != 0 ]; then
      echo -e "WARNING: Failed to read packet counter for GEM port $((0x${GEM_PORT_TMP}))"
      continue
    fi
    let GEM_PKT_TMP_US=$(echo ${GEM_PKT_TMP} | cut -f5 -d" " | cut -f2 -d"=")
    let GEM_PKT_TMP_DS=$(echo ${GEM_PKT_TMP} | cut -f3 -d" " | cut -f2 -d"=")
    #echo -e "Upstream packet on GEM port ${GEM_PORT_TMP}: ${GEM_PKT_TMP_US}"
    #echo -e "Downstream Packet on GEM port ${GEM_PORT_TMP}: ${GEM_PKT_TMP_DS}"
    let GEM_PKT_US=${GEM_PKT_US}+${GEM_PKT_TMP_US}
    let GEM_PKT_DS=${GEM_PKT_DS}+${GEM_PKT_TMP_DS}
    #echo -e "GEM_PKT_US:${GEM_PKT_US}\n"
    #echo -e "GEM_PKT_DS:${GEM_PKT_DS}\n"
  done
  MC_GEM_PORT_IDX=$(onu gpe_gem_port_get 2047 | cut -f3 -d" " | cut -f2 -d"=")
  MC_GEM_PKT=$(onu gpe_gem_total_counter_get ${MC_GEM_PORT_IDX})
  MC_GEM_PKT_DS=$(echo ${MC_GEM_PKT} | cut -f3 -d" " | cut -f2 -d"=")
  BC_GEM_PORT_IDX=$(onu gpe_gem_port_get 2046 | cut -f3 -d" " | cut -f2 -d"=")
  BC_GEM_PKT=$(onu gpe_gem_total_counter_get ${BC_GEM_PORT_IDX})
  BC_GEM_PKT_DS=$(echo ${BC_GEM_PKT} | cut -f3 -d" " | cut -f2 -d"=")
  let GEM_PKT_DS_ALL=${GEM_PKT_DS}+${MC_GEM_PKT_DS}+${BC_GEM_PKT_DS}
}

# Output packet numbers for upstream and downstream
print_packet_numer()
{
  # Output statistics for upstream and downstream
  echo -e "\n"
#  echo -e "#########################################################"
#  echo -e "### Packet statistics at $(date) ###"
#  echo -e "#########################################################"
  echo -e "#########################################"
  echo -e "##### Packet numbers before traffic #####"
  echo -e "#########################################"
  echo -e "##### Upstream packet statistics #####"
  echo -e "LAN port       : ${LAN_PKT_NUM_US_OLD}"
  echo -e "UNI bridge port: ${BP_PKT_NUM_US_OLD}"
  echo -e "GEM port       : ${GEM_PKT_US_OLD}"
  echo -e "\n"
  echo -e "##### Downstream packet statistics #####"
  echo -e "GEM port all   : ${GEM_PKT_DS_ALL_OLD}"
  echo -e " GEM port flow : ${GEM_PKT_DS_OLD}"
  echo -e " GEM port MC   : ${MC_GEM_PKT_DS_OLD}"
  echo -e " GEM port BC   : ${BC_GEM_PKT_DS_OLD}"
  echo -e "UNI bridge port: ${BP_PKT_NUM_DS_OLD}"
  echo -e "LAN port       : ${LAN_PKT_NUM_DS_OLD}"
  echo -e "\n"
  echo -e "########################################"
  echo -e "##### Packet numbers after traffic #####"
  echo -e "########################################"
  echo -e "##### Upstream packet statistics #####"
  echo -e "LAN port       : ${LAN_PKT_NUM_US}"
  echo -e "UNI bridge port: ${BP_PKT_NUM_US}"
  echo -e "GEM port       : ${GEM_PKT_US}"
  echo -e "\n"
  echo -e "##### Downstream packet statistics #####"
  echo -e "GEM port all   : ${GEM_PKT_DS_ALL}"
  echo -e " GEM port flow : ${GEM_PKT_DS}"
  echo -e " GEM port MC   : ${MC_GEM_PKT_DS}"
  echo -e " GEM port BC   : ${BC_GEM_PKT_DS}"
  echo -e "UNI bridge port: ${BP_PKT_NUM_DS}"
  echo -e "LAN port       : ${LAN_PKT_NUM_DS}"
  echo -e "\n"
}

usage_exit()
{
  echo -e "\nUsage: packetsDrop.sh [-l]\n"
  echo -e "         -l: save gtop and omci log\n"
  exit 1
}

#
# Main function starts here
#

# Redirect console to current tty
omcli omciMgr redirect `tty`

SAVE_LOG=false
if [ $# != 0 ]; then
  if [ $# == 1 -a "$1" == "-l" ]; then
    echo -e "\n"
    echo -e "You are running this tool with -l opton,"
    echo -e "it means gtop log before and after traffic will be saved."
    echo -e "Please make sure putty/SecureCRT is configured to save log."
    echo -e "This might take around one minute."
    echo -e "\n"
    read -p "Are you sure(y/n)? " -n 1 -r USER_CHOICE
    if [ "${USER_CHOICE}" == "y" -o "${USER_CHOICE}" == "Y" ]; then
      SAVE_LOG=true
    else
      echo -e "\n"
      exit 0
    fi
  else
    usage_exit
  fi
fi

# Retrieve GEM ports
GEM_PORTS=""
let i=0
while [ $i -lt 16 ]; do
  PQ_MAPPER=$(onu gpetr 66 $i | grep "errorcode=0 data=8")
  if [ $? != 0 ]; then
    let i=$i+1
    continue
  fi
  PQ_GEM_PORTS=$(echo ${PQ_MAPPER} | cut -f3-4 -d" " | sed -e 's/ //g')
  PQ_GEM_PORTS_IDX=""
  let j=0
  while [ $j -lt 16 ]; do
    GEM_PORT_TMP=${PQ_GEM_PORTS:$j:2}
    if [ "${GEM_PORT_TMP}" == "ff" ]; then
      let j=$j+2
      continue
    fi
    echo ${GEM_PORTS} | grep ${GEM_PORT_TMP} 2>&1 >/dev/null
    if [ $? == 0 ]; then
      let j=$j+2
      continue
    fi
    echo ${PQ_GEM_PORTS_IDX} | grep ${GEM_PORT_TMP} 2>&1 > /dev/null
    if [ $? != 0 ]; then
      PQ_GEM_PORTS_IDX="${PQ_GEM_PORTS_IDX} ${GEM_PORT_TMP}"
    fi
    GEM_PORTS="${GEM_PORTS} ${GEM_PORT_TMP}"
    let j=$j+2
  done # end of while of j
  #echo -e "GEM_PORTS on pmapper ${i}:${PQ_GEM_PORTS_IDX}"
  let i=$i+1
done # end of whiel of i

#echo -e "GEM ports on all pmapper:${GEM_PORTS}"

if [ "${SAVE_LOG}" == "true" ]; then
  echo -e "\n"
  echo -e "#########################################################"
  echo -e "### gtop log before traffic at $(date) ###"
  echo -e "#########################################################"
  echo -e "\n"
  rm -rf /tmp/gtop.txt
  gtop -b 
  if [ -f /tmp/gtop.txt ]; then
    cat /tmp/gtop.txt
    rm -rf /tmp/gtop.txt
  fi
fi

# Read packet counters before sending data flow
read_lan_packet_number
read_bp_packet_number
read_gem_packet_number
#print_packet_numer

LAN_PKT_NUM_US_OLD=${LAN_PKT_NUM_US}
BP_PKT_NUM_US_OLD=${BP_PKT_NUM_US}
GEM_PKT_US_OLD=${GEM_PKT_US}
GEM_PKT_DS_OLD=${GEM_PKT_DS}
MC_GEM_PKT_DS_OLD=${MC_GEM_PKT_DS}
BC_GEM_PKT_DS_OLD=${BC_GEM_PKT_DS}
GEM_PKT_DS_ALL_OLD=${GEM_PKT_DS_ALL}
BP_PKT_NUM_DS_OLD=${BP_PKT_NUM_DS}
LAN_PKT_NUM_DS_OLD=${LAN_PKT_NUM_DS}

echo -e "\n"
echo -e "!!!!! Please send traffic, then stop traffic.!!!!!"
read -p "When traffic is done press any key to display report: " -n 1 -r 
echo -e "\n"

# Read packet counters after data flow is sent
read_lan_packet_number
read_bp_packet_number
read_gem_packet_number

if [ "${SAVE_LOG}" == "true" ]; then
  echo -e "\n"
  echo -e "#########################################################"
  echo -e "### gtop log after traffic at $(date) ###"
  echo -e "#########################################################"
  echo -e "\n"
  rm -rf /tmp/gtop.txt
  gtop -b 
  if [ -f /tmp/gtop.txt ]; then
    cat /tmp/gtop.txt
    rm -rf /tmp/gtop.txt
  fi
  echo -e "\n"
fi

print_packet_numer

# Calculate packet numbers sent in the flow
let LAN_PKT_NUM_US_INC=${LAN_PKT_NUM_US}-${LAN_PKT_NUM_US_OLD}
let BP_PKT_NUM_US_INC=${BP_PKT_NUM_US}-${BP_PKT_NUM_US_OLD}
let GEM_PKT_US_INC=${GEM_PKT_US}-${GEM_PKT_US_OLD}
let GEM_PKT_DS_INC=${GEM_PKT_DS}-${GEM_PKT_DS_OLD}
let MC_GEM_PKT_DS_INC=${MC_GEM_PKT_DS}-${MC_GEM_PKT_DS_OLD}
let BC_GEM_PKT_DS_INC=${BC_GEM_PKT_DS}-${BC_GEM_PKT_DS_OLD}
let GEM_PKT_DS_ALL_INC=${GEM_PKT_DS_ALL}-${GEM_PKT_DS_ALL_OLD}
let BP_PKT_NUM_DS_INC=${BP_PKT_NUM_DS}-${BP_PKT_NUM_DS_OLD}
let LAN_PKT_NUM_DS_INC=${LAN_PKT_NUM_DS}-${LAN_PKT_NUM_DS_OLD}

echo -e "*********************************************************"
echo -e "****** Packet increasd  between the two statistics ******"
echo -e "*********************************************************"
echo -e "##### Upstream packet increased #####"
echo -e "LAN port       : ${LAN_PKT_NUM_US_INC}" 
echo -e "UNI bridge port: ${BP_PKT_NUM_US_INC}" 
echo -e "GEM port       : ${GEM_PKT_US_INC}" 

echo -e "\n"
echo -e "##### Downstream packet increased #####" 
echo -e "GEM port all   : ${GEM_PKT_DS_ALL_INC}"
echo -e " GEM port flow : ${GEM_PKT_DS_INC}"
echo -e " GEM port MC   : ${MC_GEM_PKT_DS_INC}"
echo -e " GEM port BC   : ${BC_GEM_PKT_DS_INC}"
echo -e "UNI bridge port: ${BP_PKT_NUM_DS_INC}"
echo -e "LAN port       : ${LAN_PKT_NUM_DS_INC}"
echo -e "\n\n"

exit 0
