#!/bin/bash

MachineIp=$(ip addr | grep inet | grep ${INET_NAME} | awk '{print $2;}' | sed 's|/.*$||')
MachineName=$(cat /etc/hosts | grep ${MachineIp} | awk '{print $2}')

build_cpp_framework(){
	echo "build cpp framework ...."
	##Tars数据库环境初始化
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'%' identified by '${DBTarsPass}' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'localhost' identified by '${DBTarsPass}' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'${MachineName}' identified by '${DBTarsPass}' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'${MachineIp}' identified by '${DBTarsPass}' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "flush privileges;"

	sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl /root/Tars/cpp/framework/sql/*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl /root/Tars/cpp/framework/sql/*`

	cd /root/Tars/cpp/framework/sql/
	sed -i "s/proot@appinside/h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} /g" `grep proot@appinside -rl ./exec-sql.sh`
	
	chmod u+x /root/Tars/cpp/framework/sql/exec-sql.sh
	
	CHECK=$(mysqlshow --user=${DBUser} --password=${DBPassword} --host=${DBIP} --port=${DBPort} db_tars | grep -v Wildcard | grep -o db_tars)
	if [ "$CHECK" = "db_tars" -a ${MOUNT_DATA} = true ];
	then
		echo "DB db_tars already exists" > /root/DB_Exists.lock
	else
		/root/Tars/cpp/framework/sql/exec-sql.sh
	fi
}

install_base_services(){
	echo "base services ...."
	
	##框架基础服务包
	cd /root/
	mv t*.tgz /data

	if [ ${MOUNT_DATA} = true ];
	then
		mkdir -p /data/tarsconfig_data && ln -s /data/tarsconfig_data /usr/local/app/tars/tarsconfig/data
		mkdir -p /data/tarsnode_data && ln -s /data/tarsnode_data /usr/local/app/tars/tarsnode/data
		mkdir -p /data/tarspatch_data && ln -s /data/tarspatch_data /usr/local/app/tars/tarspatch/data
		mkdir -p /data/tarsregistry_data && ln -s /data/tarsregistry_data /usr/local/app/tars/tarsregistry/data
		mkdir -p /data/tars_patchs && rm -rf /usr/local/app/patchs && ln -s /data/tars_patchs /usr/local/app/patchs
	fi

	# 安装 tarsnotify、tarsstat、tarsproperty、tarslog、tarsquerystat、tarsqueryproperty
	mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsnotify/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsnotify/data
	mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsstat && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsstat/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsstat/data
	mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsproperty && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsproperty/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsproperty/data
	mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarslog && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarslog/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarslog/data
	mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsquerystat && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/data
	mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/data

	cp /data/tarsnotify.tgz /usr/local/app/tars/tarsnode/data/tars.tarsnotify/ && cd /usr/local/app/tars/tarsnode/data/tars.tarsnotify/ && tar zxf tarsnotify.tgz && mv tarsnotify/* ./bin/ && rm -rf tarsnotify
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/tarsnotify --config=/usr/local/app/tars/tarsnode/data/tars.tarsnotify/conf/tars.tarsnotify.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/tars_start.sh
	cp /root/confs/tars.tarsnotify.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsnotify/conf/

	cp /data/tarsstat.tgz /usr/local/app/tars/tarsnode/data/tars.tarsstat/ && cd /usr/local/app/tars/tarsnode/data/tars.tarsstat/ && tar zxf tarsstat.tgz && mv tarsstat/* ./bin/ && rm -rf tarsstat
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tarsstat --config=/usr/local/app/tars/tarsnode/data/tars.tarsstat/conf/tars.tarsstat.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tars_start.sh
	cp /root/confs/tars.tarsstat.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsstat/conf/

	cp /data/tarsproperty.tgz /usr/local/app/tars/tarsnode/data/tars.tarsproperty/ && cd /usr/local/app/tars/tarsnode/data/tars.tarsproperty/ && tar zxf tarsproperty.tgz && mv tarsproperty/* ./bin/ && rm -rf tarsproperty
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tarsproperty --config=/usr/local/app/tars/tarsnode/data/tars.tarsproperty/conf/tars.tarsproperty.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tars_start.sh
	cp /root/confs/tars.tarsproperty.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsproperty/conf/

	cp /data/tarslog.tgz /usr/local/app/tars/tarsnode/data/tars.tarslog/ && cd /usr/local/app/tars/tarsnode/data/tars.tarslog/ && tar zxf tarslog.tgz && mv tarslog/* ./bin/ && rm -rf tarslog
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarslog/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tarslog --config=/usr/local/app/tars/tarsnode/data/tars.tarslog/conf/tars.tarslog.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tars_start.sh
	cp /root/confs/tars.tarslog.config.conf /usr/local/app/tars/tarsnode/data/tars.tarslog/conf/

	cp /data/tarsquerystat.tgz /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/ && cd /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/ && tar zxf tarsquerystat.tgz && mv tarsquerystat/* ./bin/ && rm -rf tarsquerystat
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tarsquerystat --config=/usr/local/app/tars/tarsnode/data/tars.tarsquerystat/conf/tars.tarsquerystat.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tars_start.sh
	cp /root/confs/tars.tarsquerystat.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/conf/

	cp /data/tarsqueryproperty.tgz /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/ && cd /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/ && tar zxf tarsqueryproperty.tgz && mv tarsqueryproperty/* ./bin/ && rm -rf tarsqueryproperty
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/tarsqueryproperty --config=/usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/conf/tars.tarsqueryproperty.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/tars_start.sh
	cp /root/confs/tars.tarsqueryproperty.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/conf/

	##核心基础服务配置修改
	cd /usr/local/app/tars

	sed -i "s/dbhost.*=.*192.168.2.131/dbhost = ${DBIP}/g" `grep dbhost -rl ./*`
	sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./*`
	sed -i "s/dbport.*=.*3306/dbport = ${DBPort}/g" `grep dbport -rl /usr/local/app/tars/*`
	sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./*`
	sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./*`
	# 修改Mysql里tars用户密码
	sed -i "s/tars2015/${DBTarsPass}/g" `grep tars2015 -rl ./*`

	chmod u+x tars_install.sh
	#./tars_install.sh

	chmod u+x tarspatch/util/init.sh
	./tarspatch/util/init.sh
}

build_web_mgr(){
	echo "web manager ...."
	
	##web管理系统配置修改后重新打war包
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
