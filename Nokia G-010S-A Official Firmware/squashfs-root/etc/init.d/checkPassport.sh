#!/bin/sh
mkdir -p /home/ONTUSER

get_ONTUSER_user()
{
	ret=$(awk -F ':' 'BEGIN {count=0; flag=0;};{user[count]=$1;count++;};END{for(i=0;i<count;i++){if("ONTUSER"==user[i]){flag=1;}};print flag}' /etc/passwd);
	return ${ret};
}

get_ONTUSER_passwd()
{
	ret=$(awk -F ':' 'BEGIN {count=0;flag=0};{user[count]=$1;passwd[count]=$2,count++;};END{for(i=0;i<count;i++){if("ONTUSER"==user[i] && passwd[i]!=""){flag=1;}};print flag}' /etc/shadow);
  return ${ret};
}

get_ONTUSER_user
ONTUSER_user_flag=$?
get_ONTUSER_passwd
ONTUSER_passwd_flag=$?

if [ $ONTUSER_user_flag = 1 -a $ONTUSER_passwd_flag = 1 ]; then
echo "ONTUSER user/passwd is ok !"
elif [ $ONTUSER_user_flag = 1 -a $ONTUSER_passwd_flag = 0 ]; then
echo "ONTUSER user exist , but password not exist"
echo "now need to add password"
echo -e "SUGAR2A041\nSUGAR2A041" | passwd ONTUSER
elif [ $ONTUSER_user_flag = 0 -a $ONTUSER_passwd_flag = 1 ]; then
echo "no ONTUSER not exist ,but password exist!"
echo "ONTUSER:x:0:0:ONTUSER:/home/ONTUSER:/bin/ash" >> /etc/passwd
echo -e "SUGAR2A041\nSUGAR2A041" | passwd ONTUSER
elif [ $ONTUSER_user_flag = 0 -a $ONTUSER_passwd_flag = 0 ]; then
echo "maybe a init status there is no ONTUSER and password !"
echo "ONTUSER:x:0:0:SUGAR2A041:/home/ONTUSER:/bin/ash" >> /etc/passwd
echo -e "SUGAR2A041\nSUGAR2A041" | passwd ONTUSER
fi
