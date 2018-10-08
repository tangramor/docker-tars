FROM centos as builder

WORKDIR /root/

##镜像时区 
ENV TZ=Asia/Shanghai

##安装
RUN yum -y install https://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm \
	&& yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
	&& yum -y install git gcc gcc-c++ make wget cmake mysql mysql-devel unzip iproute which glibc-devel flex bison ncurses-devel protobuf-devel zlib-devel kde-l10n-Chinese glibc-common hiredis-devel rapidjson-devel boost boost-devel tzdata \
	# 设置时区与编码
	&& ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
	&& localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 \
	&& mkdir -p /usr/local/mysql && ln -s /usr/lib64/mysql /usr/local/mysql/lib && ln -s /usr/include/mysql /usr/local/mysql/include && echo "/usr/local/mysql/lib/" >> /etc/ld.so.conf && ldconfig \
	&& cd /usr/local/mysql/lib/ && rm -f libmysqlclient.a && ln -s libmysqlclient.so.*.*.* libmysqlclient.a \
	# 获取最新TARS源码
	&& cd /root/ && git clone https://github.com/TarsCloud/Tars \
	&& cd /root/Tars/ && git submodule update --init --recursive framework \
	&& git submodule update --init --recursive web \
	&& git submodule update --init --recursive java \
	&& mkdir -p /data && chmod u+x /root/Tars/framework/build/build.sh \
	# 开始构建
	&& cd /root/Tars/framework/build/ && ./build.sh all \
	&& ./build.sh install \
	&& cd /root/Tars/framework/build/ && make framework-tar \
	&& make tarsstat-tar && make tarsnotify-tar && make tarsproperty-tar && make tarslog-tar && make tarsquerystat-tar && make tarsqueryproperty-tar \
	&& mkdir -p /usr/local/app/tars/ && cp /root/Tars/framework/build/framework.tgz /usr/local/app/tars/ && cp /root/Tars/framework/build/t*.tgz /root/ \
	&& cd /usr/local/app/tars/ && tar xzfv framework.tgz && rm -rf framework.tgz \
	&& mkdir -p /usr/local/app/patchs/tars.upload \
	# 获取并安装nodejs
	&& wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash \
	&& source ~/.bashrc && nvm install v8.11.3 \
	&& cp -Rf /root/Tars/web /usr/local/tarsweb && npm install -g pm2 --registry=https://registry.npm.taobao.org \
	&& cd /usr/local/tarsweb/ && npm install --registry=https://registry.npm.taobao.org \
	&& mkdir -p /root/sql && cp -rf /root/Tars/framework/sql/* /root/sql/ \
	# 获取并安装JDK
	&& mkdir -p /root/init && cd /root/init/ \
	&& wget -c -t 0 --header "Cookie: oraclelicense=accept" -c --no-check-certificate http://download.oracle.com/otn-pub/java/jdk/10.0.2+13/19aef61b38124481863b1413dce1855f/jdk-10.0.2_linux-x64_bin.rpm \
	&& rpm -ivh /root/init/jdk-10.0.2_linux-x64_bin.rpm && rm -rf /root/init/jdk-10.0.2_linux-x64_bin.rpm \
	&& echo "export JAVA_HOME=/usr/java/jdk-10.0.2" >> /etc/profile \
	&& echo "CLASSPATH=\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> /etc/profile \
	&& echo "PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile \
	&& echo "export PATH JAVA_HOME CLASSPATH" >> /etc/profile \
	&& echo "export JAVA_HOME=/usr/java/jdk-10.0.2" >> /root/.bashrc \
	&& echo "CLASSPATH=\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> /root/.bashrc \
	&& echo "PATH=\$JAVA_HOME/bin:\$PATH" >> /root/.bashrc \
	&& echo "export PATH JAVA_HOME CLASSPATH" >> /root/.bashrc \
	&& cd /usr/local/ && wget -c -t 0 https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz \
	&& tar zxvf apache-maven-3.5.4-bin.tar.gz && echo "export MAVEN_HOME=/usr/local/apache-maven-3.5.4/" >> /etc/profile \
	# 设置阿里云maven镜像
	# && sed -i '/<mirrors>/a\\t<mirror>\n\t\t<id>nexus-aliyun<\/id>\n\t\t<mirrorOf>*<\/mirrorOf>\n\t\t<name>Nexus aliyun<\/name>\n\t\t<url>http:\/\/maven.aliyun.com\/nexus\/content\/groups\/public<\/url>\n\t<\/mirror>' /usr/local/apache-maven-3.5.4/conf/settings.xml \
	&& echo "export PATH=\$PATH:\$MAVEN_HOME/bin" >> /etc/profile \
	&& echo "export PATH=\$PATH:\$MAVEN_HOME/bin" >> /root/.bashrc \
	&& source /etc/profile && mvn -v \
	&& rm -rf apache-maven-3.5.4-bin.tar.gz \
	&& cd /root/Tars/java && source /etc/profile && mvn clean install && mvn clean install -f core/client.pom.xml \
	&& mvn clean install -f core/server.pom.xml \
	&& cd /root/init && mvn archetype:generate -DgroupId=com.tangramor -DartifactId=TestJava -DarchetypeArtifactId=maven-archetype-webapp -DinteractiveMode=false \
	&& cd /root/Tars/java/examples/quickstart-server/ && mvn tars:tars2java && mvn package


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

COPY --from=builder /usr/local/app /usr/local/app
COPY --from=builder /usr/local/tarsweb /usr/local/tarsweb
COPY --from=builder /usr/local/tars /usr/local/tars
COPY --from=builder /home/tarsproto /home/tarsproto
COPY --from=builder /root/t*.tgz /root/
COPY --from=builder /root/Tars/framework/sql /root/sql
COPY --from=builder /usr/local/mysql/lib /usr/local/mysql/lib
COPY --from=builder $JAVA_HOME $JAVA_HOME
COPY --from=builder $MAVEN_HOME $MAVEN_HOME
COPY --from=builder /root/.m2 /root/.m2
COPY --from=builder /etc/profile /etc/profile
COPY --from=builder /root/.bashrc /root/.bashrc

RUN yum -y install https://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm \
	&& yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
	&& yum -y install wget mysql unzip iproute which flex bison protobuf zlib kde-l10n-Chinese glibc-common boost tzdata \
	&& ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
	&& localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 \
	&& mkdir -p /usr/local/mysql && ln -s /usr/lib64/mysql /usr/local/mysql/lib && echo "/usr/local/mysql/lib/" >> /etc/ld.so.conf && ldconfig \
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
