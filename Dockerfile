FROM centos/systemd

##镜像时区 
ENV TZ=Asia/Shanghai

# 中文字符集支持
ENV LC_ALL "zh_CN.UTF-8"

ENV DBIP 127.0.0.1
ENV DBPort 3306
ENV DBUser root
ENV DBPassword password

# Mysql里tars用户的密码，缺省为tars2015
ENV DBTarsPass tars2015

ENV JAVA_HOME /usr/java/jdk-10.0.2

ENV MAVEN_HOME /usr/local/apache-maven-3.5.4

COPY --from=tarscloud/tars:dev /usr/local/app /usr/local/app
COPY --from=tarscloud/tars:dev /usr/local/tarsweb /usr/local/tarsweb
COPY --from=tarscloud/tars:dev /usr/local/tars /usr/local/tars
COPY --from=tarscloud/tars:dev /home/tarsproto /home/tarsproto
COPY --from=tarscloud/tars:dev /root/t*.tgz /root/
COPY --from=tarscloud/tars:dev /root/Tars/framework/sql /root/sql
COPY --from=tarscloud/tars:dev /usr/local/mysql/lib /usr/local/mysql/lib
COPY --from=tarscloud/tars:dev $JAVA_HOME $JAVA_HOME
COPY --from=tarscloud/tars:dev $MAVEN_HOME $MAVEN_HOME
COPY --from=tarscloud/tars:dev /root/.m2 /root/.m2
COPY --from=tarscloud/tars:dev /etc/profile /etc/profile
COPY --from=tarscloud/tars:dev /root/.bashrc /root/.bashrc

RUN yum -y install https://repo.mysql.com/yum/mysql-8.0-community/el/7/x86_64/mysql80-community-release-el7-1.noarch.rpm \
	&& yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
	&& yum -y install wget mysql unzip iproute which flex bison protobuf zlib kde-l10n-Chinese glibc-common boost tzdata \
	&& ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
	&& localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 \
	&& echo "/usr/local/mysql/lib/" >> /etc/ld.so.conf && ldconfig \
	&& cd /usr/local/mysql/lib/ && rm -f libmysqlclient.a && ln -s libmysqlclient.so.*.*.* libmysqlclient.a \
	&& wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash \
	&& source ~/.bashrc && nvm install v8.11.3 \
	&& cd /usr/local/tarsweb/ && npm install -g pm2 --registry=https://registry.npm.taobao.org \
	&& yum clean all && rm -rf /var/cache/yum


# 是否将开启Tars的Web管理界面登录功能，预留，目前没用
ENV ENABLE_LOGIN false

# 是否将Tars系统进程的data目录挂载到外部存储，缺省为false以支持windows下使用
ENV MOUNT_DATA false

# 网络接口名称，如果运行时使用 --net=host，宿主机网卡接口可能不叫 eth0
ENV INET_NAME eth0

VOLUME ["/data"]
	
##拷贝资源
COPY install.sh /root/init/
COPY entrypoint.sh /sbin/

ADD confs /root/confs

RUN chmod 755 /sbin/entrypoint.sh
ENTRYPOINT [ "/sbin/entrypoint.sh", "start" ]

#Expose ports
EXPOSE 3000
