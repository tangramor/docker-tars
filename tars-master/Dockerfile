FROM bitnami/minideb

WORKDIR /root/

##修改镜像时区 
ENV TZ=Asia/Shanghai
ENV LC_ALL zh_CN.UTF-8
ENV DBIP 127.0.0.1
ENV DBPort 3306
ENV DBUser root
ENV DBPassword password

##安装
RUN install_packages build-essential cmake wget mariadb-client libmariadbclient-dev libmariadbclient18 unzip iproute flex bison libncurses5-dev zlib1g-dev ca-certificates locales \
	&& echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
	&& echo 'LC_ALL=zh_CN.UTF-8' >> /etc/environment && localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8 \
	&& wget https://github.com/Tencent/Tars/archive/master.zip \
	&& unzip -a master.zip && mv Tars-master Tars && rm -f /root/master.zip \
	&& mkdir -p /usr/local/mysql/lib && ln -s /usr/include/mysql /usr/local/mysql/include \
	&& ln -s /usr/lib/x86_64-linux-gnu/libmariadbclient.so.*.*.* /usr/local/mysql/lib/libmysqlclient.a \
	&& cd /root/Tars/cpp/thirdparty && wget https://github.com/Tencent/rapidjson/archive/master.zip \
	&& unzip -a master.zip && mv rapidjson-master rapidjson && rm -f master.zip \
	&& mkdir -p /data && chmod u+x /root/Tars/cpp/build/build.sh \
	&& cd /root/Tars/cpp/build/ && ./build.sh all \
	&& ./build.sh install \
	&& cd /root/Tars/cpp/build/ && make framework-tar \
	&& make tarsstat-tar && make tarsnotify-tar && make tarsproperty-tar && make tarslog-tar && make tarsquerystat-tar && make tarsqueryproperty-tar \
	&& mkdir -p /usr/local/app/tars/ && cp /root/Tars/cpp/build/framework.tgz /usr/local/app/tars/ && cp /root/Tars/cpp/build/t*.tgz /root/ \
	&& cd /usr/local/app/tars/ && tar xzfv framework.tgz && rm -rf framework.tgz \
	&& mkdir -p /usr/local/app/patchs/tars.upload \
	&& mkdir -p /root/init && cd /root/init/ \
	&& wget --header "Cookie: oraclelicense=accept" -c --no-check-certificate http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz \
	&& tar zxf /root/init/jdk-8u131-linux-x64.tar.gz && rm -rf /root/init/jdk-8u131-linux-x64.tar.gz \
	&& mkdir /usr/java && mv /root/init/jdk1.8.0_131 /usr/java \
	&& echo "export JAVA_HOME=/usr/java/jdk1.8.0_131" >> /etc/profile \
	&& echo "CLASSPATH=\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> /etc/profile \
	&& echo "PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile \
	&& echo "export PATH JAVA_HOME CLASSPATH" >> /etc/profile \
	&& cd /usr/local/ && wget http://mirrors.gigenet.com/apache/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz \
	&& tar zxvf apache-maven-3.5.2-bin.tar.gz && echo "export MAVEN_HOME=/usr/local/apache-maven-3.5.2/" >> /etc/profile \
	&& echo "export PATH=\$PATH:\$MAVEN_HOME/bin" >> /etc/profile && . /etc/profile && mvn -v \
	&& rm -rf apache-maven-3.5.2-bin.tar.gz  \
	&& cd /usr/local/ && wget http://caucho.com/download/resin-4.0.51.tar.gz && tar zxvf resin-4.0.51.tar.gz && mv resin-4.0.51 resin && rm -rf resin-4.0.51.tar.gz \
	&& cd /root/Tars/java && mvn clean install && mvn clean install -f core/client.pom.xml && mvn clean install -f core/server.pom.xml \
	&& cd /root/Tars/web/ && mvn clean package \
	&& cp /root/Tars/build/conf/resin.xml /usr/local/resin/conf/ \
	&& cp /root/Tars/web/target/tars.war /usr/local/resin/webapps/ \
	&& mkdir -p /root/sql && cp -rf /root/Tars/cpp/framework/sql/* /root/sql/ \
	&& rm -rf /root/Tars \
	&& apt-get -y purge build-essential cmake cmake-data cpp cpp-6 dpkg-dev g++ g++-6 gcc gcc-6 libc-dev-bin libc6-dev libgcc-6-dev libmariadbclient-dev libstdc++-6-dev libtinfo-dev linux-libc-dev make zlib1g-dev \
	&& apt-get -y autoremove

ENV JAVA_HOME /usr/java/jdk1.8.0_131

ENV MAVEN_HOME /usr/local/apache-maven-3.5.2

VOLUME ["/data"]
	
##拷贝资源
COPY install.sh /root/init/
COPY entrypoint.sh /sbin/

ENTRYPOINT ["/bin/bash","/sbin/entrypoint.sh"]

CMD ["start"]

#Expose ports
EXPOSE 8080
