#!/bin/bash

if [ -d /root/init ];then

	for x in $(ls /root/init)
	do
		if [ -f /root/init/$x ];then
			chmod u+x /root/init/$x
			/bin/bash /root/init/$x
			rm -rf /root/init/$x
		fi
	done
fi


case ${1} in
	init)
		;;
	start)
		/usr/sbin/init
		source /etc/profile
		cd /usr/local/app/tars && ./tars_install.sh
		redis-server /etc/redis.conf
		httpd
		exec /usr/local/resin/bin/resin.sh console
		;;
	*)
		exec "$@"
		;;
esac

