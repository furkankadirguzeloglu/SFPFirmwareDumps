#!/bin/sh
image=`cat /proc/mtd | grep image | cut -c 31`
cimage=`expr 1 - $image`
echo image$cimage
