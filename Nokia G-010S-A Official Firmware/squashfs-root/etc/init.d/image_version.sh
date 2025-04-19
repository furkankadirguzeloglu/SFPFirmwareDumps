#!/bin/sh
get_new_image_version()
{
	ret=$(cat /usr/etc/buildinfo | grep IMAGEVERSION | awk -F "=" '{print $2}');
	echo $ret;	
}

get_old_image_version()
{
	if [ ! -f "/configs/image_version" ];then
		new_version=`get_new_image_version`
		echo "image0_version=$new_version" >> /configs/image_version		
		echo "image1_version=$new_version" >> /configs/image_version		
	fi
	
	if [ $1 == '0' ];then
		ret=$(cat /configs/image_version | grep image0)
	elif [ $1 == '1' ];then 
		ret=$(cat /configs/image_version | grep image1)
	fi
	
	if [ -z "$ret" ];then
		rm /configs/image_version
		new_version=`get_new_image_version`
		ret=$new_version
		echo "image0_version=$new_version" >> /configs/image_version		
		echo "image1_version=$new_version" >> /configs/image_version		
	fi

	echo $ret
}

update_image_version()
{
	ret=$(cat /proc/mtd | grep image | awk -F ':' '{print $2}' | awk -F " " '{print $3}');
	image_name=$(echo ${ret:6:1});
	 if [ $image_name == '1' ];then
		echo "we are now image0 !"
		if [ $2 ];then
			echo "upgrade : $2 "
			old_image_version=`get_old_image_version 1` ;
			echo "old : $old_image_version"
			if [ ! -z "$old_image_version" ];then
				ret=$(sed -i 's/'$old_image_version'/image1_version='$2'/' /configs/image_version );
			else
				echo "get 0 old image version error !"
			fi
		else
			echo "update image_version from bootup system"
			old_image_version=`get_old_image_version 0 ` ;
			ret=$(cat /configs/image_version | grep image0 | awk -F "=" '{print $2}');
			if [ -z "$ret" -a ! -z $old_image_version ] ; then
				ret=$(sed -i 's/'$old_image_version'/image0_version='$1'/' /configs/image_version );
			elif [ $new_image_version != $ret -a  ! -z $old_image_version ] ; then
				ret=$(sed -i 's/'$old_image_version'/image0_version='$1'/' /configs/image_version );	
			else
				echo "no need to update image0 version"
			fi
			
			ret=$(cat /configs/image_version | grep image1 | awk -F "=" '{print $2}')
			old_image_version=`get_old_image_version 1 ` ;
			if [ -z "$ret" -a ! -z $old_image_version ] ; then	
				ret=$(sed -i 's/'$old_image_version'/image1_version='$1'/' /configs/image_version );
			fi
		fi
	fi
	
	if [ $image_name == '0' ];then
		echo "we are now image1 !"
		if [ $2 ];then
			echo "upgrade : $2 "
			old_image_version=`get_old_image_version 0` ;
			if [ ! -z $old_image_version ] ;then
				ret=$(sed -i 's/'$old_image_version'/image0_version='$2'/' /configs/image_version );
			else
				echo "get 1 old_image_version error !"
			fi
		else
			echo "update image_version from bootup system"
			old_image_version=`get_old_image_version 1 ` ;
			ret=$(cat /configs/image_version | grep image1 | awk -F "=" '{print $2}')
			if [ -z "$ret" -a ! -z $old_image_version ] ; then
				ret=$(sed -i 's/'$old_image_version'/image1_version='$1'/' /configs/image_version );
			elif [ $new_image_version != $ret -a  ! -z $old_image_version ] ; then
				ret=$(sed -i 's/'$old_image_version'/image1_version='$1'/' /configs/image_version );	
			else
				echo "no need to update image1 version"
			fi
			
			ret=$(cat /configs/image_version | grep image0 | awk -F "=" '{print $2}')
			old_image_version=`get_old_image_version 0 ` ;
			if [ -z "$ret" -a ! -z $old_image_version ] ; then	
				ret=$(sed -i 's/'$old_image_version'/image0_version='$1'/' /configs/image_version );
			fi
		fi
	fi
}
#upgrade_image_version variables come form upgrade progammer parse 3FEimage 
upgrade_image_version=$1
new_image_version=`get_new_image_version`
echo "buildinfo : $new_image_version "
if [ ! -z "$new_image_version" ];then
	update_image_version $new_image_version $upgrade_image_version
else
	echo "get image version from /usr/etc/buidinfo error !"
fi

