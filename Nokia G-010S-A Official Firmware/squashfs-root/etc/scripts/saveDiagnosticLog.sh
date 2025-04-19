#!/bin/sh

#check save to log partition or configure partition
df | grep -q '/logs'
if [ $? -eq 0 ]; then
  file_prefix=/logs/diagnostic.
#  gtop_log=/logs/gtop
else
  file_prefix=/configs/diagnostic.
#  gtop_log=/configs/gtop
fi

#tar_name=.tar.gz

# Save the diagnostic log to specified path
diagnostic_log_desc_path=/logs
diagnostic_log_fileId_name=diagnostic_log_fileid
diagnostic_log_file_MaxNum=5

#get current file id

if [ -e $diagnostic_log_desc_path/$diagnostic_log_fileId_name ]
then
    file_id=`head -1 $diagnostic_log_desc_path/$diagnostic_log_fileId_name`
else
    file_id=0
fi

if [ $file_id -ge $diagnostic_log_file_MaxNum ]
then
    echo "file_id($file_id) >= log_file_max_num($diagnostic_log_file_MaxNum), reset file_id to 0"
    file_id=0
fi

log_file=${file_prefix}${file_id}
echo $log_file
#gtop_file=${gtop_log}${file_id}${tar_name}
#echo $gtop_file

rm $log_file
#rm $gtop_file
rm -rf /tmp/gtop.txt
/opt/lantiq/bin/gtop -b > /dev/null 2>&1
sync

if [ -e /logs/gtop.txt ]; then
    rm /logs/gtop.txt
fi

let diagnostic_log_size=`du /tmp/gtop.txt | awk '{print $1}'`+5
let logs_avaliable_size=`df | grep "$diagnostic_log_desc_path" | awk '{print $4}'`
echo "logs_avaliable_size is $logs_avaliable_size, diagnostic_log_size is $diagnostic_log_size"

if [ $diagnostic_log_size -le $logs_avaliable_size ]
then
    echo "ifconfig information collected:" >> $log_file
    ifconfig -a >> $log_file
    echo "arp information collected:" >> $log_file
    arp >> $log_file
    echo "other information collected:" >> $log_file
    route -e >> $log_file
    date >> $log_file
    uptime >> $log_file
    free >> $log_file
    top -b -n 1 >> $log_file
    ritool dump >> $log_file
    cat /usr/etc/buildinfo >> $log_file
    echo "End of information collected." >> $log_file

    if [ -e /tmp/gtop.txt ]; then
#        tar -zcvf $gtop_file /tmp/gtop.txt
        mv /tmp/gtop.txt /logs/gtop.txt
    fi

    if [ -e /logs/clog.sh ]; then
      . /logs/clog.sh
    fi

    let file_id_tmp=$file_id+1
    echo $file_id_tmp > $diagnostic_log_desc_path/$diagnostic_log_fileId_name
    sync

else
    echo "path: $diagnostic_log_desc_path avaliable size($logs_avaliable_size) is not enough"
fi
