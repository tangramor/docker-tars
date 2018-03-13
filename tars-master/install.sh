#!/bin/bash

MachineIp=$(ip addr | grep inet | grep ${INET_NAME} | awk '{print $2;}' | sed 's|/.*$||')
MachineName=$(cat /etc/hosts | grep ${MachineIp} | awk '{print $2}')

build_cpp_framework(){
	echo "build cpp framework ...."
	##Tars数据库环境初始化
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'%' identified by 'tars2015' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'localhost' identified by 'tars2015' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'${MachineName}' identified by 'tars2015' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "flush privileges;"

	sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl /root/sql/*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl /root/sql/*`

	cd /root/sql/
	sed -i "s/proot@appinside/h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} /g" `grep proot@appinside -rl ./exec-sql.sh`
	
	chmod u+x /root/sql/exec-sql.sh
	
	CHECK=$(mysqlshow --user=${DBUser} --password=${DBPassword} --host=${DBIP} --port=${DBPort} db_tars | grep -v Wildcard | grep -o db_tars)
	if [ "$CHECK" = "db_tars" -a ${MOUNT_DATA} = true ];
	then
		echo "DB db_tars already exists" > /root/DB_Exists.lock
	else
		/root/sql/exec-sql.sh
	fi

}

install_base_services(){
	echo "base services ...."
	
	cd /root
	mv t*.tgz /data

	##核心基础服务配置修改
	cd /usr/local/app/tars

	sed -i "s/dbhost.*=.*192.168.2.131/dbhost = ${DBIP}/g" `grep dbhost -rl ./*`
	sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./*`
	sed -i "s/dbport.*=.*3306/dbport = ${DBPort}/g" `grep dbport -rl /usr/local/app/tars/*`
	sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./*`
	sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./*`

	chmod u+x tars_install.sh
	#./tars_install.sh

	if [ ${MOUNT_DATA} = true ];
	then
		mkdir -p /data/tarsconfig_data && ln -s /data/tarsconfig_data /usr/local/app/tars/tarsconfig/data
		mkdir -p /data/tarsnode_data && ln -s /data/tarsnode_data /usr/local/app/tars/tarsnode/data
		mkdir -p /data/tarspatch_data && ln -s /data/tarspatch_data /usr/local/app/tars/tarspatch/data
		mkdir -p /data/tarsregistry_data && ln -s /data/tarsregistry_data /usr/local/app/tars/tarsregistry/data
	fi

	chmod u+x tarspatch/util/init.sh
	./tarspatch/util/init.sh
}

build_web_mgr(){
	echo "web manager ...."
	
	##web管理系统配置修改后重新打war包
	source /etc/profile
	cd /usr/local/resin/webapps/
	mkdir tars
	cd tars
	jar -xvf ../tars.war
	
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./WEB-INF/classes/app.config.properties`
	sed -i "s/3306/${DBPort}/g" `grep 3306 -rl ./WEB-INF/classes/app.config.properties`
	sed -i "s/registry1.tars.com/${MachineIp}/g" `grep registry1.tars.com -rl ./WEB-INF/classes/tars.conf`
	sed -i "s/registry2.tars.com/${MachineIp}/g" `grep registry2.tars.com -rl ./WEB-INF/classes/tars.conf`
	sed -i "s/DEBUG/INFO/g" `grep DEBUG -rl ./WEB-INF/classes/log4j.properties`
	
	jar -uvf ../tars.war .
	cd ..
	rm -rf tars
}


build_cpp_framework

install_base_services

build_web_mgr
