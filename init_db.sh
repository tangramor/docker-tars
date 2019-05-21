#!/bin/bash

MachineIp=$(ip addr | grep inet | grep ${INET_NAME} | awk '{print $2;}' | sed 's|/.*$||')
MachineName=$(cat /etc/hosts | grep ${MachineIp} | awk '{print $2}')

echo "build cpp framework ...."
	
MYSQL_VER=$(mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "SELECT VERSION();" 2>/dev/null | grep -o '8.')

echo "MYSQL_VER:" $MYSQL_VER

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
echo "CHECK:" $CHECK
if [[ "$CHECK" = "db_tars" && ${MOUNT_DATA} = true && ( ! -f /data/OldMachineIp || -f /data/OldMachineIp && $(cat /data/OldMachineIp) = ${MachineIp} ) ]];
then
	echo "DB db_tars already exists"
	echo "DB db_tars already exists" > /root/DB_Exists.lock

elif [[ "$CHECK" = "db_tars" && ${MOUNT_DATA} = true && -f /data/OldMachineIp && $(cat /data/OldMachineIp) != ${MachineIp} ]]; then
	
	echo "DB db_tars already exists but need change OldMachineIp"
	OLDIP=$(cat /data/OldMachineIp)
	echo "DB db_tars already exists" > /root/DB_Exists.lock

	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "USE db_tars; UPDATE t_adapter_conf SET node_name=REPLACE(node_name, '${OLDIP}', '${MachineIp}'), endpoint=REPLACE(endpoint,'${OLDIP}', '${MachineIp}'); UPDATE t_machine_tars_info SET node_name=REPLACE(node_name, '${OLDIP}', '${MachineIp}'); UPDATE t_server_conf SET node_name=REPLACE(node_name, '${OLDIP}', '${MachineIp}'); UPDATE t_server_notifys SET node_name=REPLACE(node_name, '${OLDIP}', '${MachineIp}'), server_id=REPLACE(server_id, '${OLDIP}', '${MachineIp}'); DELETE FROM t_node_info WHERE node_name='${OLDIP}'; DELETE FROM t_registry_info WHERE locator_id LIKE '${OLDIP}:%';"

	sed -i "s/${OLDIP}/${MachineIp}/g" `grep ${OLDIP} -rl /data/tarsnode_data/*`

else
	echo "first init db"
	/root/sql/exec-sql.sh

	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsconfig.sql
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsnotify.sql
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarspatch.sql
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarslog.sql
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsstat.sql
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsproperty.sql
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsquerystat.sql
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars < /root/sql/tarsqueryproperty.sql

	cd /usr/local/tarsweb/
	sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./config/*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./config/*`
	sed -i "s/3306/${DBPort}/g" `grep 3306 -rl ./config/*`
	sed -i "s/tars2015/${DBTarsPass}/g" `grep tars2015 -rl ./config/*`
	sed -i "s/DEBUG/INFO/g" `grep DEBUG -rl ./config/*`
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "create database db_tars_web"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} db_tars_web < /usr/local/tarsweb/sql/db_tars_web.sql
fi

echo ${MachineIp} > /data/OldMachineIp