#!/bin/sh
#### /etc configuration deal with for the target system

SYS_ETC_CFG="/usr/cfg/etc.cfg"
SYS_ETC_EXT="/usr/cfg/etc.ext"

#### deal with the etc.cfg with general strategy
for item in $(cat ${SYS_ETC_CFG} |sed "s/[ \t]//g" |sed "s/^#.*$//g")
do
	LINK_TARGET=$(echo ${item} |cut -d: -f1)
	LINK_SOURCE=$(echo ${item} |cut -d: -f2)
	#judge LINK_TARGET is url or file
	if [ -d ${LINK_TARGET} ];then
		if [ ! -d ${LINK_SOURCE} ];then
			mkdir -p ${LINK_SOURCE}
		fi
		files=`ls -al ${LINK_TARGET} | awk -F " " '{print $9}'`
		for file in $files	
		do
			if [ $file != . -a $file != ..  ];then
				if [ ! -f ${LINK_SOURCE}/$file ];then
					mv ${LINK_TARGET}/${file} ${LINK_SOURCE}/${file}
				fi	
			fi
		done
		rm -rf ${LINK_TARGET}
	elif [ -e ${LINK_SOURCE} ]; then
		if [ -L ${LINK_TARGET} ]; then
			rm -f ${LINK_TARGET}
		else
			rm -rf ${LINK_TARGET}
		fi
	elif [ -e ${LINK_TARGET} ]; then
		mv ${LINK_TARGET} ${LINK_SOURCE}
	else
		echo MSG: No ${LINK_SOURCE}
	fi
	ln -sf ${LINK_SOURCE} ${LINK_TARGET}
done
sync

#### deal with the etc.ext with specail strategy
for item in $(cat ${SYS_ETC_EXT} |sed "s/[ \t]//g" |sed "s/^#.*$//g")
do
	LINK_TARGET=$(echo ${item} |cut -d: -f1)
	LINK_SOURCE=$(echo ${item} |cut -d: -f2)
	ln -sf ${LINK_SOURCE} ${LINK_TARGET}
done

