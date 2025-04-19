#!/bin/sh
# For factory aging test

count=0

echo "" >> /logs/factory_reboot_monitor.log
while true
do
  echo "UP-COUNTER: $count" >> /logs/factory_reboot_monitor.log
  let count++
  sleep 10
done
