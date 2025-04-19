#!/bin/sh

me171=`/opt/lantiq/bin/omci_pipe.sh md | grep "Extended VLAN conf data" | sed -n 's/\(0x\)/\1/p' | cut -f 3 -d '|' | cut -f 1 -d '(' | head -n 1 | sed s/[[:space:]]//g`

echo > /tmp/other_debug
/opt/lantiq/bin/omci_pipe.sh md >> /tmp/other_debug
echo "################################################################################################################################################################" >> /tmp/other_debug
/opt/lantiq/bin/omci_pipe.sh meg 171 $me171 >> /tmp/other_debug
echo "################################################################################################################################################################" >> /tmp/other_debug
/opt/lantiq/bin/omci_pipe.sh mda >> /tmp/other_debug
echo "################################################################################################################################################################" >> /tmp/other_debug


