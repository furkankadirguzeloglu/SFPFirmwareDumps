#!/bin/sh
## check the system account
PASSWD="/configs/etc/passwd"
SHADOW="/configs/etc/shadow"
UGROUP="/configs/etc/group"

## discard the residual account while image switch
COMMIT=`fw_printenv commit | awk -F "=" '{print $2}'`
ret=`cat /proc/mtd | grep image | awk -F ':' '{print $2}' | awk -F " " '{print $3}')`
value=`echo ${ret:6:1}`

if [ $value = '0' ];then
    ACTIVE=1;
else
    ACTIVE=0;
fi

if [ $ACTIVE -ne $COMMIT ];then
    echo "rm $PASSWD $SHADOW $UGROUP in image switch"
    rm -rf $PASSWD $SHADOW $UGROUP
fi

## check the default system account
home_dir=/etc/home
if [ -e $PASSWD ]; then
  if [ -s $PASSWD ]; then  
    if ! grep -q "^ONTUSER:" $PASSWD; then
       sed -i '/^ONTUSER:.*$/d' $PASSWD
       sed -i '$a\ONTUSER:x:0:0:Linux:/etc/home/ONTUSER:/bin/sh' $PASSWD
       sed -i '/^ONTUSER:.*$/d' $SHADOW
       sed -i '$a\ONTUSER:$1$ojmCYQtx$ktc5DH0Kvu/jCpuUSAQB0.:0:0:99999:7:::' $SHADOW
       [ -d ${home_dir} ] || mkdir -p ${home_dir}
       if [ ! -d ${home_dir}/ONTUSER ]; then
         mkdir -p ${home_dir}/ONTUSER
         echo "export PS1=\"[\\u@\\h: \\W]\\\\\$ \"" >> ${home_dir}/ONTUSER/.bashrc
         chown ONTUSER ${home_dir}/ONTUSER/.bashrc
       fi
    elif grep "^ONTUSER:" $PASSWD |grep -q -v "/bin/sh"; then
        sed -i 's#^ONTUSER:.*$#ONTUSER:x:0:0:Linux:/etc/home/ONTUSER:/bin/sh#g' $PASSWD
    fi
    
    if ! grep -q "^root:" $PASSWD; then
       ## Add the default account root in the first line, which is used for factory cmd prompt
       sed -i  '1i\root:x:0:0:root:/root:/bin/false' "$PASSWD"
    else
       sed -i 's#^root:.*$#root:x:0:0:root:/root:/bin/false#g' $PASSWD
    fi

    ## no ONTUSER account for SIGH
    ## move the logic to cfgmgr because ritool is not ready here
    
  else
    ## passwd file is empty, then rm these empty files, which will be restored by etc configuration file mechanism
    ## Therefore, cfgetc.sh must be run after this script to restore the passwd files
    rm -rf $PASSWD $SHADOW $UGROUP
  fi
fi

## trigger system sync
sync

