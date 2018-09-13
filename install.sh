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

	sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl /root/sql/*`
	sed -i "s/10.120.129.226/${MachineIp}/g" `grep 10.120.129.226 -rl /root/sql/*`
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

		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsconfig.sql
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsnotify.sql
		mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarspatch.sql
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
		mkdir -p /data/tars_patchs && cp -Rf /usr/local/app/patchs/* /data/tars_patchs/ && rm -rf /usr/local/app/patchs && ln -s /data/tars_patchs /usr/local/app/patchs
	fi

	# 安装 tarsnotify、tarsstat、tarsproperty、tarslog、tarsquerystat、tarsqueryproperty
	rm -rf /usr/local/app/tars/tarsnotify && mkdir -p /usr/local/app/tars/tarsnotify/bin && mkdir -p /usr/local/app/tars/tarsnotify/conf && mkdir -p /usr/local/app/tars/tarsnotify/data
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarsstat && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsstat/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsstat/data
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarsproperty && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsproperty/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsproperty/data
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarslog && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarslog/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarslog/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarslog/data
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarsquerystat && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/data
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/data

	cd /data/ && tar zxf tarsnotify.tgz && mv /data/tarsnotify/tarsnotify /usr/local/app/tars/tarsnotify/bin/ && rm -rf /data/tarsnotify
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnotify/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnotify/bin/tarsnotify --config=/usr/local/app/tars/tarsnotify/conf/tars.tarsnotify.config.conf  &' >> /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	cp /root/confs/tars.tarsnotify.config.conf /usr/local/app/tars/tarsnotify/conf/

	cd /data/ && tar zxf tarsstat.tgz && mv /data/tarsstat/tarsstat /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/ && rm -rf /data/tarsstat
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tarsstat --config=/usr/local/app/tars/tarsnode/data/tars.tarsstat/conf/tars.tarsstat.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tars_start.sh
	cp /root/confs/tars.tarsstat.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsstat/conf/

	cd /data/ && tar zxf tarsproperty.tgz && mv /data/tarsproperty/tarsproperty /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/ && rm -rf /data/tarsproperty
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tarsproperty --config=/usr/local/app/tars/tarsnode/data/tars.tarsproperty/conf/tars.tarsproperty.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tars_start.sh
	cp /root/confs/tars.tarsproperty.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsproperty/conf/

	cd /data/ && tar zxf tarslog.tgz && mv /data/tarslog/tarslog /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/ && rm -rf /data/tarslog
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarslog/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tarslog --config=/usr/local/app/tars/tarsnode/data/tars.tarslog/conf/tars.tarslog.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tars_start.sh
	cp /root/confs/tars.tarslog.config.conf /usr/local/app/tars/tarsnode/data/tars.tarslog/conf/

	cd /data/ && tar zxf tarsquerystat.tgz && mv /data/tarsquerystat/tarsquerystat /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/ && rm -rf /data/tarsquerystat
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tarsquerystat --config=/usr/local/app/tars/tarsnode/data/tars.tarsquerystat/conf/tars.tarsquerystat.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tars_start.sh
	cp /root/confs/tars.tarsquerystat.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/conf/

	cd /data/ && tar zxf tarsqueryproperty.tgz && mv /data/tarsqueryproperty/tarsqueryproperty /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/ && rm -rf /data/tarsqueryproperty
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

	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "USE db_tars; INSERT INTO t_adapter_conf (id, application, server_name, node_name, adapter_name, registry_timestamp, thread_num, endpoint, max_connections, allow_ip, servant, queuecap, queuetimeout, posttime, lastuser, protocol, handlegroup) VALUES (23, 'tars', 'tarsstat', '${MachineIp}', 'tars.tarsstat.StatObjAdapter', '2018-05-27 12:22:05', 5, 'tcp -h ${MachineIp} -t 60000 -p 10003 -e 0', 200000, '', 'tars.tarsstat.StatObj', 10000, 60000, '2018-05-27 20:22:05', NULL, 'tars', ''),(24, 'tars', 'tarsproperty', '${MachineIp}', 'tars.tarsproperty.PropertyObjAdapter', '2018-05-27 12:22:24', 5, 'tcp -h ${MachineIp} -t 60000 -p 10004 -e 0', 200000, '', 'tars.tarsproperty.PropertyObj', 10000, 60000, '2018-05-27 20:22:24', NULL, 'tars', ''),(25, 'tars', 'tarslog', '${MachineIp}', 'tars.tarslog.LogObjAdapter', '2018-05-27 12:22:43', 5, 'tcp -h ${MachineIp} -t 60000 -p 10005 -e 0', 200000, '', 'tars.tarslog.LogObj', 10000, 60000, '2018-05-27 20:22:43', NULL, 'tars', ''),(26, 'tars', 'tarsquerystat', '${MachineIp}', 'tars.tarsquerystat.NoTarsObjAdapter', '2018-05-27 12:23:08', 5, 'tcp -h ${MachineIp} -t 60000 -p 10006 -e 0', 200000, '', 'tars.tarsquerystat.NoTarsObj', 10000, 60000, '2018-05-27 20:23:08', NULL, 'not_tars', ''),(27, 'tars', 'tarsqueryproperty', '${MachineIp}', 'tars.tarsqueryproperty.NoTarsObjAdapter', '2018-05-27 12:23:22', 5, 'tcp -h ${MachineIp} -t 60000 -p 10007 -e 0', 200000, '', 'tars.tarsqueryproperty.NoTarsObj', 10000, 60000, '2018-05-27 20:23:22', NULL, 'not_tars', '');"

	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "USE db_tars; INSERT INTO t_server_conf (id, application, server_name, node_group, node_name, registry_timestamp, base_path, exe_path, template_name, bak_flag, setting_state, present_state, process_id, patch_version, patch_time, patch_user, tars_version, posttime, lastuser, server_type, start_script_path, stop_script_path, monitor_script_path, enable_group, enable_set, set_name, set_area, set_group, ip_group_name, profile, config_center_port, async_thread_num, server_important_type, remote_log_reserve_time, remote_log_compress_time, remote_log_type) VALUES (23, 'tars', 'tarsstat', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsstat', 0, 'active', 'inactive', 0, '59', '2018-05-29 12:28:37', '', '1.1.0', '2018-05-27 20:22:05', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(24, 'tars', 'tarsproperty', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsproperty', 0, 'active', 'inactive', 0, '60', '2018-05-29 12:29:32', '', '1.1.0', '2018-05-27 20:22:24', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(25, 'tars', 'tarslog', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarslog', 0, 'active', 'inactive', 0, '61', '2018-05-29 12:29:54', '', '1.1.0', '2018-05-27 20:22:43', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(26, 'tars', 'tarsquerystat', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsquerystat', 0, 'active', 'inactive', 0, '62', '2018-05-29 12:30:22', '', '1.1.0', '2018-05-27 20:23:08', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(27, 'tars', 'tarsqueryproperty', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsqueryproperty', 0, 'active', 'inactive', 0, '63', '2018-05-29 12:30:55', '', '1.1.0', '2018-05-27 20:23:22', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0); ALTER TABLE t_server_patchs AUTO_INCREMENT = 64;"


	chmod u+x tars_install.sh
	#./tars_install.sh

	chmod u+x tarspatch/util/init.sh
	./tarspatch/util/init.sh
}

build_web_mgr(){
	echo "web manager ...."
	
	cd /usr/local/tarsweb/
	sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry1.tars.com -rl ./config/*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./config/*`
	sed -i "s/3306/${DBPort}/g" `grep 3306 -rl ./config/*`
	sed -i "s/tars2015/${DBTarsPass}/g" `grep tars2015 -rl ./config/*`
	sed -i "s/DEBUG/INFO/g" `grep DEBUG -rl ./config/*`

	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "create database db_tars_web"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars_web < /usr/local/tarsweb/sql/db_tars_web.sql
	
	npm run prd
}

build_cpp_framework

install_base_services

build_web_mgr
