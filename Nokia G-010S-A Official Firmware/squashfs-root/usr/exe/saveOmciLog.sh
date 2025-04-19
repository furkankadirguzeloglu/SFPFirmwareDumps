#!/bin/sh

#check save to log partition or configure partition
df | grep -q '/logs'
if [ $? -eq 0 ]; then
  file_prefix=/logs/omciMsg.
else
  file_prefix=/configs/omciMsg.
fi

#get current file id
if [ -e /configs/omciMsgFileID.txt ]; then
  file_id=`head -1 /configs/omciMsgFileID.txt`
else
  file_id=0
fi

log_file=${file_prefix}${file_id}
echo $log_file

if [ -e /tmp/omcimsg.txt ]; then
  line=`cat /tmp/omcimsg.txt | wc -l`
  echo $line

  if [ $line -ge 20 ]; then
    rm -f $log_file
    tail -20 /tmp/omcimsg.txt > $log_file
  else
    cat /tmp/omcimsg.txt >> $log_file
  fi
fi
sync
echo "saveOmciLog.sh has been finished"

# Copy the omci log to specified path, modify by Anna
omci_log_path=/tmp/omci.log
omci_bak_path=/tmp/omci.log.bak
omci_log_desc_path=/logs
omci_log_backup_file_path=/logs
omci_log_backup_file=$omci_log_backup_file_path/omci_backup_path
omci_log_fileId_name=omci_log_fileid
omci_log_file_MaxNum=5

if [ -e $omci_log_backup_file ]
then
    omci_file_path=`head -1 $omci_log_backup_file`
    echo "omci_file_path = $omci_file_path"

    if [ -e $omci_file_path ]
    then
        if [ -e $omci_file_path/$omci_log_fileId_name ]
        then
            file_id=`head -1 $omci_log_fileId_name`
        else
            file_id=0
        fi

        if [ $file_id -ge $omci_log_file_MaxNum ]
        then
            echo "file_id($file_id) >= log_file_max_num($omci_log_file_MaxNum), reset file_id to 0"
            file_id=0
        fi

        let omci_log_size=`du /tmp/omci.log | awk '{print $1}'`/1024+1
        let logs_avaliable_size=`df -m | grep "$omci_file_path" | awk '{print $4}'`-1
        echo "logs_avaliable_size is $logs_avaliable_size, omci_log_size is $omci_log_size"
        if [ $omci_log_size -le $logs_avaliable_size ]
        then
            cp $omci_log_path $omci_file_path/omci.log.$file_id

            if [ -e $omci_bak_path ]
            then
                let omci_bak_size=`du /tmp/omci.log.bak | awk '{print $1}'`/1024+1
                let logs_avaliable_size=`df -m | grep "$omci_file_path" | awk '{print $4}'`-1
                if [ $omci_bak_size -le $logs_avaliable_size ]
                then
                    cp $omci_bak_path $omci_file_path/omci.log.bak.$file_id
                else
                    echo "path: $omci_file_path avaliable size($logs_avaliable_size) is not enough, do not copy omci.log.bak"
                fi
            fi

            let file_id_tmp=$file_id+1
            echo $file_id_tmp > $omci_file_path/$omci_log_fileId_name

            sync
        else
            echo "path: $omci_file_path avaliable size($logs_avaliable_size) is not enough, do not copy omci.log"
        fi
    fi
fi
