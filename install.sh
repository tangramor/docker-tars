#!/bin/bash

MachineIp=$(ip addr | grep inet | grep ${INET_NAME} | awk '{print $2;}' | sed 's|/.*$||')
MachineName=$(cat /etc/hosts | grep ${MachineIp} | awk '{print $2}')

build_cpp_framework(){
	echo "build cpp framework ...."

	MYSQL_VER=$(mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "SELECT VERSION();" 2>/dev/null | grep -o '8.')

	##Tars数据库环境初始化
	if [ "$MYSQL_VER" = "8." ];
	then
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "CREATE USER 'tars'@'%' IDENTIFIED WITH mysql_native_password BY '${DBTarsPass}';"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "GRANT ALL ON *.* TO 'tars'@'%' WITH GRANT OPTION;"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "CREATE USER 'tars'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DBTarsPass}';"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "GRANT ALL ON *.* TO 'tars'@'localhost' WITH GRANT OPTION;"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "CREATE USER 'tars'@'${MachineName}' IDENTIFIED WITH mysql_native_password BY '${DBTarsPass}';"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "GRANT ALL ON *.* TO 'tars'@'${MachineName}' WITH GRANT OPTION;"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "CREATE USER 'tars'@'${MachineIp}' IDENTIFIED WITH mysql_native_password BY '${DBTarsPass}';"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "GRANT ALL ON *.* TO 'tars'@'${MachineIp}' WITH GRANT OPTION;"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "flush privileges;"
	else
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'%' identified by '${DBTarsPass}' with grant option;"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'localhost' identified by '${DBTarsPass}' with grant option;"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'${MachineName}' identified by '${DBTarsPass}' with grant option;"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'${MachineIp}' identified by '${DBTarsPass}' with grant option;"
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "flush privileges;"
	fi

	sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl /root/sql/*`
	sed -i "s/10.120.129.226/${MachineIp}/g" `grep 10.120.129.226 -rl /root/sql/*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl /root/sql/*`
	sed -i "s/'65','2',0)/'65','2',0,'NORMAL')/g" `grep "'65','2',0)" -rl /root/sql/*`
	sed -i "s/'65','2',0,'NORMAL');/'65','2',0,'NORMAL') ON DUPLICATE KEY UPDATE exe_path='\/usr\/local\/app\/tars\/tarsnotify\/bin\/tarsnotify';/g" /root/sql/tarsnotify.sql

	cd /root/sql/
	sed -i "s/proot@appinside/h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} /g" `grep proot@appinside -rl ./exec-sql.sh`
	
	chmod u+x /root/sql/exec-sql.sh
	
	CHECK=$(mysqlshow --user=${DBUser} --password=${DBPassword} --host=${DBIP} --port=${DBPort} db_tars | grep -v Wildcard | grep -o db_tars)
	if [[ "$CHECK" = "db_tars" && ${MOUNT_DATA} = true && ( ! -f /data/OldMachineIp || -f /data/OldMachineIp && $(cat /data/OldMachineIp) = ${MachineIp} ) ]];
	then

		echo "DB db_tars already exists" > /root/DB_Exists.lock

	elif [[ "$CHECK" = "db_tars" && ${MOUNT_DATA} = true && -f /data/OldMachineIp && $(cat /data/OldMachineIp) != ${MachineIp} ]]; then

		OLDIP=$(cat /data/OldMachineIp)
		echo "DB db_tars already exists" > /root/DB_Exists.lock

		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "USE db_tars; UPDATE t_adapter_conf SET node_name=REPLACE(node_name, '${OLDIP}', '${MachineIp}'), endpoint=REPLACE(endpoint,'${OLDIP}', '${MachineIp}'); UPDATE t_machine_tars_info SET node_name=REPLACE(node_name, '${OLDIP}', '${MachineIp}'); UPDATE t_server_conf SET node_name=REPLACE(node_name, '${OLDIP}', '${MachineIp}'); UPDATE t_server_notifys SET node_name=REPLACE(node_name, '${OLDIP}', '${MachineIp}'), server_id=REPLACE(server_id, '${OLDIP}', '${MachineIp}'); DELETE FROM t_node_info WHERE node_name='${OLDIP}'; DELETE FROM t_registry_info WHERE locator_id LIKE '${OLDIP}:%';"

		sed -i "s/${OLDIP}/${MachineIp}/g" `grep ${OLDIP} -rl /data/tarsnode_data/*`

	else

		/root/sql/exec-sql.sh

		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsconfig.sql
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsnotify.sql
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarspatch.sql
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarslog.sql
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsstat.sql
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsproperty.sql
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsquerystat.sql
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsqueryproperty.sql
	fi

	echo ${MachineIp} > /data/OldMachineIp
}

install_base_services(){
	echo "base services ...."
	
	##框架基础服务包
	cd /root/
	mv t*.tgz /data

	# 安装 tarsnotify、tarsstat、tarsproperty、tarslog、tarsquerystat、tarsqueryproperty
	rm -rf /usr/local/app/tars/tarsnotify && mkdir -p /usr/local/app/tars/tarsnotify/bin && mkdir -p /usr/local/app/tars/tarsnotify/conf && mkdir -p /usr/local/app/tars/tarsnotify/data
	rm -rf /usr/local/app/tars/tarsstat && mkdir -p /usr/local/app/tars/tarsstat/bin && mkdir -p /usr/local/app/tars/tarsstat/conf && mkdir -p /usr/local/app/tars/tarsstat/data
	rm -rf /usr/local/app/tars/tarsproperty && mkdir -p /usr/local/app/tars/tarsproperty/bin && mkdir -p /usr/local/app/tars/tarsproperty/conf && mkdir -p /usr/local/app/tars/tarsproperty/data
	rm -rf /usr/local/app/tars/tarslog && mkdir -p /usr/local/app/tars/tarslog/bin && mkdir -p /usr/local/app/tars/tarslog/conf && mkdir -p /usr/local/app/tars/tarslog/data
	rm -rf /usr/local/app/tars/tarsquerystat && mkdir -p /usr/local/app/tars/tarsquerystat/bin && mkdir -p /usr/local/app/tars/tarsquerystat/conf && mkdir -p /usr/local/app/tars/tarsquerystat/data
	rm -rf /usr/local/app/tars/tarsqueryproperty && mkdir -p /usr/local/app/tars/tarsqueryproperty/bin && mkdir -p /usr/local/app/tars/tarsqueryproperty/conf && mkdir -p /usr/local/app/tars/tarsqueryproperty/data

	if [ ${MOUNT_DATA} = true ];
	then
		mkdir -p /data/tarsconfig_data && rm -rf /usr/local/app/tars/tarsconfig/data && ln -s /data/tarsconfig_data /usr/local/app/tars/tarsconfig/data
		mkdir -p /data/tarsnode_data && rm -rf /usr/local/app/tars/tarsnode/data && ln -s /data/tarsnode_data /usr/local/app/tars/tarsnode/data
		mkdir -p /data/tarspatch_data && rm -rf /usr/local/app/tars/tarspatch/data && ln -s /data/tarspatch_data /usr/local/app/tars/tarspatch/data
		mkdir -p /data/tarsregistry_data && rm -rf /usr/local/app/tars/tarsregistry/data && ln -s /data/tarsregistry_data /usr/local/app/tars/tarsregistry/data
		mkdir -p /data/tars_patchs && cp -Rf /usr/local/app/patchs/* /data/tars_patchs/ && rm -rf /usr/local/app/patchs && ln -s /data/tars_patchs /usr/local/app/patchs
	fi

	cd /data/ && tar zxf tarsnotify.tgz && mv /data/tarsnotify/tarsnotify /usr/local/app/tars/tarsnotify/bin/ && rm -rf /data/tarsnotify
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnotify/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnotify/bin/tarsnotify --config=/usr/local/app/tars/tarsnotify/conf/tars.tarsnotify.config.conf  &' >> /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	echo 'tarsnotify/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarsnotify.config.conf /usr/local/app/tars/tarsnotify/conf/

	cd /data/ && tar zxf tarsstat.tgz && mv /data/tarsstat/tarsstat /usr/local/app/tars/tarsstat/bin/ && rm -rf /data/tarsstat
	echo '#!/bin/sh' > /usr/local/app/tars/tarsstat/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsstat/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsstat/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsstat/bin/tarsstat --config=/usr/local/app/tars/tarsstat/conf/tars.tarsstat.config.conf  &' >> /usr/local/app/tars/tarsstat/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarsstat/bin/tars_start.sh
	echo 'tarsstat/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarsstat.config.conf /usr/local/app/tars/tarsstat/conf/

	cd /data/ && tar zxf tarsproperty.tgz && mv /data/tarsproperty/tarsproperty /usr/local/app/tars/tarsproperty/bin/ && rm -rf /data/tarsproperty
	echo '#!/bin/sh' > /usr/local/app/tars/tarsproperty/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsproperty/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsproperty/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsproperty/bin/tarsproperty --config=/usr/local/app/tars/tarsproperty/conf/tars.tarsproperty.config.conf  &' >> /usr/local/app/tars/tarsproperty/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarsproperty/bin/tars_start.sh
	echo 'tarsproperty/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarsproperty.config.conf /usr/local/app/tars/tarsproperty/conf/

	cd /data/ && tar zxf tarslog.tgz && mv /data/tarslog/tarslog /usr/local/app/tars/tarslog/bin/ && rm -rf /data/tarslog
	echo '#!/bin/sh' > /usr/local/app/tars/tarslog/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarslog/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarslog/bin/tars_start.sh
	echo '/usr/local/app/tars/tarslog/bin/tarslog --config=/usr/local/app/tars/tarslog/conf/tars.tarslog.config.conf  &' >> /usr/local/app/tars/tarslog/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarslog/bin/tars_start.sh
	echo 'tarslog/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarslog.config.conf /usr/local/app/tars/tarslog/conf/

	cd /data/ && tar zxf tarsquerystat.tgz && mv /data/tarsquerystat/tarsquerystat /usr/local/app/tars/tarsquerystat/bin/ && rm -rf /data/tarsquerystat
	echo '#!/bin/sh' > /usr/local/app/tars/tarsquerystat/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsquerystat/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsquerystat/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsquerystat/bin/tarsquerystat --config=/usr/local/app/tars/tarsquerystat/conf/tars.tarsquerystat.config.conf  &' >> /usr/local/app/tars/tarsquerystat/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarsquerystat/bin/tars_start.sh
	echo 'tarsquerystat/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarsquerystat.config.conf /usr/local/app/tars/tarsquerystat/conf/

	cd /data/ && tar zxf tarsqueryproperty.tgz && mv /data/tarsqueryproperty/tarsqueryproperty /usr/local/app/tars/tarsqueryproperty/bin/ && rm -rf /data/tarsqueryproperty
	echo '#!/bin/sh' > /usr/local/app/tars/tarsqueryproperty/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsqueryproperty/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsqueryproperty/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsqueryproperty/bin/tarsqueryproperty --config=/usr/local/app/tars/tarsqueryproperty/conf/tars.tarsqueryproperty.config.conf  &' >> /usr/local/app/tars/tarsqueryproperty/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarsqueryproperty/bin/tars_start.sh
	echo 'tarsqueryproperty/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarsqueryproperty.config.conf /usr/local/app/tars/tarsqueryproperty/conf/

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

	#mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "USE db_tars; INSERT INTO t_adapter_conf (id, application, server_name, node_name, adapter_name, registry_timestamp, thread_num, endpoint, max_connections, allow_ip, servant, queuecap, queuetimeout, posttime, lastuser, protocol, handlegroup) VALUES (23, 'tars', 'tarsstat', '${MachineIp}', 'tars.tarsstat.StatObjAdapter', '2018-05-27 12:22:05', 5, 'tcp -h ${MachineIp} -t 60000 -p 10003 -e 0', 200000, '', 'tars.tarsstat.StatObj', 10000, 60000, '2018-05-27 20:22:05', NULL, 'tars', ''),(24, 'tars', 'tarsproperty', '${MachineIp}', 'tars.tarsproperty.PropertyObjAdapter', '2018-05-27 12:22:24', 5, 'tcp -h ${MachineIp} -t 60000 -p 10004 -e 0', 200000, '', 'tars.tarsproperty.PropertyObj', 10000, 60000, '2018-05-27 20:22:24', NULL, 'tars', ''),(25, 'tars', 'tarslog', '${MachineIp}', 'tars.tarslog.LogObjAdapter', '2018-05-27 12:22:43', 5, 'tcp -h ${MachineIp} -t 60000 -p 10005 -e 0', 200000, '', 'tars.tarslog.LogObj', 10000, 60000, '2018-05-27 20:22:43', NULL, 'tars', ''),(26, 'tars', 'tarsquerystat', '${MachineIp}', 'tars.tarsquerystat.NoTarsObjAdapter', '2018-05-27 12:23:08', 5, 'tcp -h ${MachineIp} -t 60000 -p 10006 -e 0', 200000, '', 'tars.tarsquerystat.NoTarsObj', 10000, 60000, '2018-05-27 20:23:08', NULL, 'not_tars', ''),(27, 'tars', 'tarsqueryproperty', '${MachineIp}', 'tars.tarsqueryproperty.NoTarsObjAdapter', '2018-05-27 12:23:22', 5, 'tcp -h ${MachineIp} -t 60000 -p 10007 -e 0', 200000, '', 'tars.tarsqueryproperty.NoTarsObj', 10000, 60000, '2018-05-27 20:23:22', NULL, 'not_tars', '');"

	#mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "USE db_tars; INSERT INTO t_server_conf (id, application, server_name, node_group, node_name, registry_timestamp, base_path, exe_path, template_name, bak_flag, setting_state, present_state, process_id, patch_version, patch_time, patch_user, tars_version, posttime, lastuser, server_type, start_script_path, stop_script_path, monitor_script_path, enable_group, enable_set, set_name, set_area, set_group, ip_group_name, profile, config_center_port, async_thread_num, server_important_type, remote_log_reserve_time, remote_log_compress_time, remote_log_type) VALUES (23, 'tars', 'tarsstat', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsstat', 0, 'active', 'inactive', 0, '59', '2018-05-29 12:28:37', '', '1.1.0', '2018-05-27 20:22:05', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(24, 'tars', 'tarsproperty', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsproperty', 0, 'active', 'inactive', 0, '60', '2018-05-29 12:29:32', '', '1.1.0', '2018-05-27 20:22:24', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(25, 'tars', 'tarslog', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarslog', 0, 'active', 'inactive', 0, '61', '2018-05-29 12:29:54', '', '1.1.0', '2018-05-27 20:22:43', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(26, 'tars', 'tarsquerystat', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsquerystat', 0, 'active', 'inactive', 0, '62', '2018-05-29 12:30:22', '', '1.1.0', '2018-05-27 20:23:08', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(27, 'tars', 'tarsqueryproperty', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsqueryproperty', 0, 'active', 'inactive', 0, '63', '2018-05-29 12:30:55', '', '1.1.0', '2018-05-27 20:23:22', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0); ALTER TABLE t_server_patchs AUTO_INCREMENT = 64;"

	chmod u+x tarspatch/util/init.sh
	./tarspatch/util/init.sh

	chmod u+x tars_install.sh
}

build_web_mgr(){
	echo "web manager ...."

	mkdir -p /data/logs
	rm -rf /root/.pm2
	mkdir -p /root/.pm2
	ln -s /data/logs /root/.pm2/logs
	
	cd /usr/local/tarsweb/
	sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./config/*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./config/*`
	sed -i "s/3306/${DBPort}/g" `grep 3306 -rl ./config/*`
	sed -i "s/tars2015/${DBTarsPass}/g" `grep tars2015 -rl ./config/*`
	sed -i "s/DEBUG/INFO/g" `grep DEBUG -rl ./config/*`

	if [ ${ENABLE_LOGIN} = true ];
	then
		echo "Enable Login"
		sed -i "s/enableLogin: false/enableLogin: true/g" ./config/loginConf.js
		sed -i "s/\/\/ let loginConf/let loginConf/g" ./app.js
		sed -i "s/\/\/ loginConf.ignore/loginConf.ignore/g" ./app.js
		sed -i "s/\/\/ app.use(loginMidware/app.use(loginMidware/g" ./app.js
	fi

	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "create database db_tars_web"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars_web < /usr/local/tarsweb/sql/db_tars_web.sql
}


build_cpp_framework

install_base_services

build_web_mgr
