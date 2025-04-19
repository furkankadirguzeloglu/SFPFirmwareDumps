#!bin/sh
# For factory aging test
OPID=$(ritool get OperatorID | cut -d: -f2)
if [ "$OPID" == "9999" ] || [ "$OPID" == "0000" ]; then
        sh /usr/exe/oflt_reboot_monitor.sh &
fi

# called by /etc/init.d/rcS. used to clean boot fail counter.
echo "INFO: boot fail count: $count"
fw_printenv | grep boot_fail=
sleep 70  # wait for service recovery
fw_setenv boot_fail 0
echo "INFO: clean boot fail counter done"
