#!/bin/sh
# check config link

# stage 1: for etc
for cafe in $(ls /configs/etc)
do
	wine=/etc/${cafe}
	beer=/configs/etc/${cafe}
	if [ ! -e ${wine} ]; then
		ln -sf ${beer} ${wine}
		continue
	fi
done

#stage 2: for user
for cafe in $(ls /configs/home)
do
	wine=/etc/home/${cafe}
	beer=/configs/home/${cafe}
	if [ ${cafe} = "ONTUSER" ]; then
		continue
	fi
	if [ ! -e ${wine} ]; then
		ln -sf ${beer} ${wine}
		continue
	fi
done

