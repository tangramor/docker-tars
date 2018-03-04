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
		source /etc/profile
		/usr/local/app/tars/tars_install.sh
		/etc/init.d/redis-server start
		/etc/init.d/apache2 start
		exec /usr/local/resin/bin/resin.sh console
		;;
	*)
		exec "$@"
		;;
esac

