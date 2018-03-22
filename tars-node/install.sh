#!/bin/bash

MachineIp=$(ip addr | grep inet | grep ${INET_NAME} | awk '{print $2;}' | sed 's|/.*$||')
MachineName=$(cat /etc/hosts | grep ${MachineIp} | awk '{print $2}')

install_node_services(){
	echo "base services ...."
	
	#mkdir -p /data/tars/tarsnode_data && ln -s /data/tars/tarsnode_data /usr/local/app/tars/tarsnode/data

	##核心基础服务配置修改
	cd /usr/local/app/tars

	sed -i "s/dbhost.*=.*192.168.2.131/dbhost = ${DBIP}/g" `grep dbhost -rl ./*`
	sed -i "s/registry.tars.com/${MASTER}/g" `grep registry.tars.com -rl ./*`
	sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./*`
	sed -i "s/dbport.*=.*3306/dbport = ${DBPort}/g" `grep dbport -rl ./*`
	sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./*`

	if [ ${MOUNT_DATA} = true ];
	then
		mkdir -p /data/tarsnode_data && ln -s /data/tarsnode_data /usr/local/app/tars/tarsnode/data
	fi
	
	chmod u+x tarsnode_install.sh
	./tarsnode_install.sh
	
	echo "* * * * * /usr/local/app/tars/tarsnode/util/monitor.sh" >> /etc/crontab
}

install_node_services
