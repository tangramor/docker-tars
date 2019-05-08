#!/bin/bash

MachineIp=$(ip addr | grep inet | grep ${INET_NAME} | awk '{print $2;}' | sed 's|/.*$||')

echo "init services ...."

##框架基础服务包
cd /root/
# 清除tars_install.sh 中多余的服务启动脚本
sed -i '/util/d' /usr/local/app/tars/tars_install.sh

mv t*.tgz /data

## 核心基础服务(必须手动部署:tarsAdminRegistry, tarsregistry, tarsnode, tarsconfig, tarspatch[和tars_web一起部署])
if [[ "${ServerName}" =~ "tarsAdminRegistry" ]]
then
	chmod +x /usr/local/app/tars/tarsAdminRegistry/util/*.sh
	echo 'tarsAdminRegistry/util/start.sh;' >> /usr/local/app/tars/tars_install.sh
fi

if [[ "${ServerName}" =~ "tarsregistry" ]]
then
	chmod +x /usr/local/app/tars/tarsregistry/util/*.sh
	echo 'tarsregistry/util/start.sh;' >> /usr/local/app/tars/tars_install.sh
fi

if [[ "${ServerName}" =~ "tarsnode" ]]
then
	chmod +x /usr/local/app/tars/tarsnode/util/*.sh
	echo 'tarsnode/util/start.sh;' >> /usr/local/app/tars/tars_install.sh
fi

if [[ "${ServerName}" =~ "tarsconfig" ]]
then
	chmod +x /usr/local/app/tars/tarsconfig/util/*.sh
	echo 'tarsconfig/util/start.sh;' >> /usr/local/app/tars/tars_install.sh
fi

## tars_web
if [[ "${ServerName}" =~ "tars_web" ]]
then
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
	
	npm run prd

	### tarspatch
	cd /usr/local/app/tars
	chmod u+x tarspatch/util/init.sh
	./tarspatch/util/init.sh
	chmod +x /usr/local/app/tars/tarspatch/util/*.sh
	echo 'tarspatch/util/start.sh;' >> /usr/local/app/tars/tars_install.sh

fi

## 普通基础服务(可通过管理平台部署的:tarsnotify、tarsstat、tarsproperty、tarslog、tarsquerystat、tarsqueryproperty)
if [[ "${ServerName}" =~ "tarsnotify" ]]
then
	rm -rf /usr/local/app/tars/tarsnotify && mkdir -p /usr/local/app/tars/tarsnotify/bin && mkdir -p /usr/local/app/tars/tarsnotify/conf && mkdir -p /usr/local/app/tars/tarsnotify/data
	cd /data/ && tar zxf tarsnotify.tgz && mv /data/tarsnotify/tarsnotify /usr/local/app/tars/tarsnotify/bin/ && rm -rf /data/tarsnotify
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnotify/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnotify/bin/tarsnotify --config=/usr/local/app/tars/tarsnotify/conf/tars.tarsnotify.config.conf  &' >> /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarsnotify/bin/tars_start.sh
	echo 'tarsnotify/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarsnotify.config.conf /usr/local/app/tars/tarsnotify/conf/
fi

if [[ "${ServerName}" =~ "tarsstat" ]]
then
	rm -rf /usr/local/app/tars/tarsstat && mkdir -p /usr/local/app/tars/tarsstat/bin && mkdir -p /usr/local/app/tars/tarsstat/conf && mkdir -p /usr/local/app/tars/tarsstat/data
	cd /data/ && tar zxf tarsstat.tgz && mv /data/tarsstat/tarsstat /usr/local/app/tars/tarsstat/bin/ && rm -rf /data/tarsstat
	echo '#!/bin/sh' > /usr/local/app/tars/tarsstat/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsstat/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsstat/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsstat/bin/tarsstat --config=/usr/local/app/tars/tarsstat/conf/tars.tarsstat.config.conf  &' >> /usr/local/app/tars/tarsstat/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarsstat/bin/tars_start.sh
	echo 'tarsstat/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarsstat.config.conf /usr/local/app/tars/tarsstat/conf/
fi

if [[ "${ServerName}" =~ "tarsproperty" ]]
then
	rm -rf /usr/local/app/tars/tarsproperty && mkdir -p /usr/local/app/tars/tarsproperty/bin && mkdir -p /usr/local/app/tars/tarsproperty/conf && mkdir -p /usr/local/app/tars/tarsproperty/data
	cd /data/ && tar zxf tarsproperty.tgz && mv /data/tarsproperty/tarsproperty /usr/local/app/tars/tarsproperty/bin/ && rm -rf /data/tarsproperty
	echo '#!/bin/sh' > /usr/local/app/tars/tarsproperty/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsproperty/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsproperty/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsproperty/bin/tarsproperty --config=/usr/local/app/tars/tarsproperty/conf/tars.tarsproperty.config.conf  &' >> /usr/local/app/tars/tarsproperty/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarsproperty/bin/tars_start.sh
	echo 'tarsproperty/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarsproperty.config.conf /usr/local/app/tars/tarsproperty/conf/
fi

if [[ "${ServerName}" =~ "tarslog" ]]
then
	rm -rf /usr/local/app/tars/tarslog && mkdir -p /usr/local/app/tars/tarslog/bin && mkdir -p /usr/local/app/tars/tarslog/conf && mkdir -p /usr/local/app/tars/tarslog/data
	cd /data/ && tar zxf tarslog.tgz && mv /data/tarslog/tarslog /usr/local/app/tars/tarslog/bin/ && rm -rf /data/tarslog
	echo '#!/bin/sh' > /usr/local/app/tars/tarslog/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarslog/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarslog/bin/tars_start.sh
	echo '/usr/local/app/tars/tarslog/bin/tarslog --config=/usr/local/app/tars/tarslog/conf/tars.tarslog.config.conf  &' >> /usr/local/app/tars/tarslog/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarslog/bin/tars_start.sh
	echo 'tarslog/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarslog.config.conf /usr/local/app/tars/tarslog/conf/
fi

if [[ "${ServerName}" =~ "tarsquerystat" ]]
then
	rm -rf /usr/local/app/tars/tarsquerystat && mkdir -p /usr/local/app/tars/tarsquerystat/bin && mkdir -p /usr/local/app/tars/tarsquerystat/conf && mkdir -p /usr/local/app/tars/tarsquerystat/data
	cd /data/ && tar zxf tarsquerystat.tgz && mv /data/tarsquerystat/tarsquerystat /usr/local/app/tars/tarsquerystat/bin/ && rm -rf /data/tarsquerystat
	echo '#!/bin/sh' > /usr/local/app/tars/tarsquerystat/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsquerystat/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsquerystat/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsquerystat/bin/tarsquerystat --config=/usr/local/app/tars/tarsquerystat/conf/tars.tarsquerystat.config.conf  &' >> /usr/local/app/tars/tarsquerystat/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarsquerystat/bin/tars_start.sh
	echo 'tarsquerystat/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarsquerystat.config.conf /usr/local/app/tars/tarsquerystat/conf/
fi

if [[ "${ServerName}" =~ "tarsqueryproperty" ]]
then
	rm -rf /usr/local/app/tars/tarsqueryproperty && mkdir -p /usr/local/app/tars/tarsqueryproperty/bin && mkdir -p /usr/local/app/tars/tarsqueryproperty/conf && mkdir -p /usr/local/app/tars/tarsqueryproperty/data
	cd /data/ && tar zxf tarsqueryproperty.tgz && mv /data/tarsqueryproperty/tarsqueryproperty /usr/local/app/tars/tarsqueryproperty/bin/ && rm -rf /data/tarsqueryproperty
	echo '#!/bin/sh' > /usr/local/app/tars/tarsqueryproperty/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsqueryproperty/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsqueryproperty/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsqueryproperty/bin/tarsqueryproperty --config=/usr/local/app/tars/tarsqueryproperty/conf/tars.tarsqueryproperty.config.conf  &' >> /usr/local/app/tars/tarsqueryproperty/bin/tars_start.sh
	chmod 755 /usr/local/app/tars/tarsqueryproperty/bin/tars_start.sh
	echo 'tarsqueryproperty/bin/tars_start.sh;' >> /usr/local/app/tars/tars_install.sh
	cp /root/confs/tars.tarsqueryproperty.config.conf /usr/local/app/tars/tarsqueryproperty/conf/
fi

##核心基础服务配置修改
cd /usr/local/app/tars

sed -i "s/dbhost.*=.*192.168.2.131/dbhost = ${DBIP}/g" `grep dbhost -rl ./*`
sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
sed -i "s/localip.tars.com/${MachineIp}/g" `grep localip.tars.com -rl ./*`
sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./*`
sed -i "s/dbport.*=.*3306/dbport = ${DBPort}/g" `grep dbport -rl /usr/local/app/tars/*`
sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./*`
sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./*`
# 修改Mysql里tars用户密码
sed -i "s/tars2015/${DBTarsPass}/g" `grep tars2015 -rl ./*`

# 启动服务
chmod u+x tars_install.sh
./tars_install.sh
