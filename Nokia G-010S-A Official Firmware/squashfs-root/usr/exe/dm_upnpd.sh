#! /bin/sh
filename="/tmp/upnpd"
if [ -f $filename ];then
    proc_info=$(cat $filename)
    echo $proc_info
    var=`echo $proc_info | awk -F ', ' '{print $0}' | sed "s/,//g"`
    #echo $var
    procname=$(echo $var | awk '{print $1}')
    extitf=$(echo $var | awk '{print $2}')
    intitf=$(echo $var | awk '{print $3}')
    killall $procname
    echo "restart upnpd process by daemon"
    $procname $extitf $intitf &
else
    echo "/tmp/upnpd is not existed"
fi
