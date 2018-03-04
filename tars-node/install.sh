#!/bin/bash

ResourceDir=/root/res
MachineIp=$(ip addr | grep inet | grep eth0 | awk '{print $2;}' | sed 's|/.*$||')
MachineName=$(cat /etc/hosts | grep ${MachineIp} | awk '{print $2}')

install_node_services(){
	echo "base services ...."
	
	##核心基础服务配置修改
	source /etc/profile
	cd /usr/local/app/tars

	sed -i "s/dbhost.*=.*192.168.2.131/dbhost = ${DBIP}/g" `grep dbhost -rl ./*`
	sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./*`
	sed -i "s/dbport.*=.*3306/dbport = ${DBPort}/g" `grep dbport -rl ./*`
	sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./*`
	sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./*`

	chmod u+x tarsnode_install.sh
	./tarsnode_install.sh
	
	echo "* * * * * /usr/local/app/tars/tarsnode/util/monitor.sh" >> /etc/crontab
}

setup_apache() {
	mkdir /data/web
	echo "<?php phpinfo(); ?>" > /data/web/phpinfo.php
	rm -rf /var/www/html
	ln -s /data/web /var/www/html
}

install_node_services

setup_apache
