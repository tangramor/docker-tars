FROM centos

WORKDIR /root/

##修改镜像时区 
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
	&& localedef -c -f UTF-8 -i zh_CN zh_CN.utf8

ENV LC_ALL zh_CN.utf8

ENV DBIP 127.0.0.1
ENV DBPort 3306
ENV DBUser root
ENV DBPassword password

##安装
RUN rpm -Uvh https://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm \
	&& yum --enablerepo=mysql80-community install -y git gcc gcc-c++ make wget cmake mysql mysql-devel unzip iproute which glibc-devel flex bison ncurses-devel zlib-devel kde-l10n-Chinese glibc-common \
	&& wget -c -t 0 https://github.com/Tencent/Tars/archive/master.zip -O master.zip \
	&& unzip -a master.zip && mv Tars-master Tars && rm -f /root/master.zip \
	&& mkdir -p /usr/local/mysql && ln -s /usr/lib64/mysql /usr/local/mysql/lib && ln -s /usr/include/mysql /usr/local/mysql/include && echo "/usr/local/mysql/lib/" >> /etc/ld.so.conf && ldconfig \
	&& cd /usr/local/mysql/lib/ && rm -f libmysqlclient.a && ln -s libmysqlclient.so.*.*.* libmysqlclient.a \
	&& cd /root/Tars/cpp/thirdparty && wget -c -t 0 https://github.com/Tencent/rapidjson/archive/master.zip -O master.zip \
	&& unzip -a master.zip && mv rapidjson-master rapidjson && rm -f master.zip \
	&& mkdir -p /data && chmod u+x /root/Tars/cpp/build/build.sh \
	# 以下对源码配置进行mysql8对应的修改
	&& sed -i '11s/rt/rt crypto ssl/' /root/Tars/cpp/framework/CMakeLists.txt && sed -i '20s/5.1.14/8.0.11/' /root/Tars/web/pom.xml \
	&& sed -i '25s/org.gjt.mm.mysql.Driver/com.mysql.cj.jdbc.Driver/' /root/Tars/web/src/main/resources/conf-spring/spring-context-datasource.xml \
	&& sed -i '26s/convertToNull/CONVERT_TO_NULL/' /root/Tars/web/src/main/resources/conf-spring/spring-context-datasource.xml \
	# 开始构建
	&& cd /root/Tars/cpp/build/ && ./build.sh all \
	&& ./build.sh install \
	&& cd /root/Tars/cpp/build/ && make framework-tar \
	&& make tarsstat-tar && make tarsnotify-tar && make tarsproperty-tar && make tarslog-tar && make tarsquerystat-tar && make tarsqueryproperty-tar \
	&& mkdir -p /usr/local/app/tars/ && cp /root/Tars/cpp/build/framework.tgz /usr/local/app/tars/  && cp /root/Tars/cpp/build/t*.tgz /root/ \
	&& cd /usr/local/app/tars/ && tar xzfv framework.tgz && rm -rf framework.tgz \
	&& mkdir -p /usr/local/app/patchs/tars.upload \
	&& mkdir -p /root/init && cd /root/init/ \
	&& wget -c -t 0 --header "Cookie: oraclelicense=accept" -c --no-check-certificate http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm \
	&& rpm -ivh /root/init/jdk-8u131-linux-x64.rpm && rm -rf /root/init/jdk-8u131-linux-x64.rpm \
	&& echo "export JAVA_HOME=/usr/java/jdk1.8.0_131" >> /etc/profile \
	&& echo "CLASSPATH=\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> /etc/profile \
	&& echo "PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile \
	&& echo "export PATH JAVA_HOME CLASSPATH" >> /etc/profile \
	&& cd /usr/local/ && wget -c -t 0 http://mirrors.gigenet.com/apache/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz \
	&& tar zxvf apache-maven-3.5.2-bin.tar.gz && echo "export MAVEN_HOME=/usr/local/apache-maven-3.5.2/" >> /etc/profile \
	&& echo "export PATH=\$PATH:\$MAVEN_HOME/bin" >> /etc/profile && source /etc/profile && mvn -v \
	&& rm -rf apache-maven-3.5.2-bin.tar.gz  \
	&& cd /usr/local/ && wget -c -t 0 http://caucho.com/download/resin-4.0.51.tar.gz && tar zxvf resin-4.0.51.tar.gz && mv resin-4.0.51 resin && rm -rf resin-4.0.51.tar.gz \
	&& source /etc/profile && cd /root/Tars/java && mvn clean install && mvn clean install -f core/client.pom.xml && mvn clean install -f core/server.pom.xml \
	&& cd /root/Tars/web/ && source /etc/profile && mvn clean package \
	&& cp /root/Tars/build/conf/resin.xml /usr/local/resin/conf/ \
	&& cp /root/Tars/web/target/tars.war /usr/local/resin/webapps/ \
	&& mkdir -p /root/sql && cp -rf /root/Tars/cpp/framework/sql/* /root/sql/ \
	&& rm -rf /root/Tars \
	&& yum -y remove git gcc gcc-c++ make cmake mysql-devel glibc-devel ncurses-devel zlib-devel glibc-headers kernel-headers keyutils-libs-devel krb5-devel libcom_err-devel libselinux-devel libsepol-devel libstdc++-devel libverto-devel openssl-devel pcre-devel autoconf automake \
	&& yum clean all && rm -rf /var/cache/yum
	
ENV JAVA_HOME /usr/java/jdk1.8.0_131

ENV MAVEN_HOME /usr/local/apache-maven-3.5.2

# 是否将Tars系统进程的data目录挂载到外部存储，缺省为false以支持windows下使用
ENV MOUNT_DATA false

# 网络接口名称，如果运行时使用 --net=host，宿主机网卡接口可能不叫 eth0
ENV INET_NAME eth0

VOLUME ["/data"]

##拷贝资源
COPY install.sh /root/init/
COPY entrypoint.sh /sbin/

ENTRYPOINT ["/bin/bash","/sbin/entrypoint.sh"]

CMD ["start"]

#Expose ports
EXPOSE 8080
