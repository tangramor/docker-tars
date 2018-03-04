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
RUN install_packages build-essential cmake wget mariadb-client libmariadbclient-dev libmariadbclient18 unzip iproute flex bison libncurses5-dev zlib1g-dev ca-certificates vim rsync locales apache2 composer php7.0 php7.0-cli php7.0-dev php7.0-mcrypt php7.0-gd php7.0-curl php7.0-mysql php7.0-zip php7.0-fileinfo php7.0-mbstring php-redis redis-server \
	&& echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
	&& echo 'LC_ALL=zh_CN.UTF-8' >> /etc/environment && localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8 \
	&& wget -c -t 0 https://github.com/Tencent/Tars/archive/master.zip -O master.zip \
	&& unzip -a master.zip && mv Tars-master Tars && rm -f /root/master.zip \
	&& mkdir -p /usr/local/mysql/lib && ln -s /usr/include/mysql /usr/local/mysql/include \
	&& ln -s /usr/lib/x86_64-linux-gnu/libmariadbclient.so.*.*.* /usr/local/mysql/lib/libmysqlclient.a \
	&& cd /root/Tars/cpp/thirdparty && wget -c -t 0 https://github.com/Tencent/rapidjson/archive/master.zip -O master.zip \
	&& unzip -a master.zip && mv rapidjson-master rapidjson && rm -f master.zip \
	&& mkdir -p /data && chmod u+x /root/Tars/cpp/build/build.sh \
	&& cd /root/Tars/cpp/build/ && ./build.sh all \
	&& ./build.sh install \
	&& cd /root/Tars/cpp/build/ && make framework-tar \
	&& mkdir -p /usr/local/app/tars/ && cp /root/Tars/cpp/build/framework.tgz /usr/local/app/tars/ \
	&& cd /usr/local/app/tars/ && tar xzfv framework.tgz && rm -rf framework.tgz \
	&& mkdir -p /usr/local/app/patchs/tars.upload \
	&& cd /root/Tars/php/tarsclient/ext/ && phpize --clean && phpize \
	&& ./configure --enable-phptars --with-php-config=/usr/bin/php-config && make && make install && phpize --clean \
	&& echo "extension=phptars.so" > /etc/php/7.0/mods-available/phptars.ini \
	&& ln -s /etc/php/7.0/mods-available/phptars.ini /etc/php/7.0/apache2/conf.d/20-phptars.ini \
	&& ln -s /etc/php/7.0/mods-available/phptars.ini /etc/php/7.0/cli/conf.d/20-phptars.ini \
	&& mkdir -p /root/init && cd /root/init/ \
	&& wget -c -t 0 --header "Cookie: oraclelicense=accept" --no-check-certificate http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz \
	&& tar zxf /root/init/jdk-8u131-linux-x64.tar.gz && rm -rf /root/init/jdk-8u131-linux-x64.tar.gz \
	&& mkdir /usr/java && mv /root/init/jdk1.8.0_131 /usr/java \
	&& echo "export JAVA_HOME=/usr/java/jdk1.8.0_131" >> /etc/profile \
	&& echo "CLASSPATH=\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> /etc/profile \
	&& echo "PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile \
	&& echo "export PATH JAVA_HOME CLASSPATH" >> /etc/profile \
	&& cd /usr/local/ && wget -c -t 0 http://mirrors.gigenet.com/apache/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz \
	&& tar zxvf apache-maven-3.5.2-bin.tar.gz && echo "export MAVEN_HOME=/usr/local/apache-maven-3.5.2/" >> /etc/profile \
	&& echo "export PATH=\$PATH:\$MAVEN_HOME/bin" >> /etc/profile && . /etc/profile && mvn -v \
	&& rm -rf apache-maven-3.5.2-bin.tar.gz  \
	&& . /etc/profile && cd /root/Tars/java && mvn clean install && mvn clean install -f core/client.pom.xml && mvn clean install -f core/server.pom.xml \
	&& rm -rf /root/Tars \
	&& apt-get -y autoremove

ENV JAVA_HOME /usr/java/jdk1.8.0_131

ENV MAVEN_HOME /usr/local/apache-maven-3.5.2

VOLUME ["/data"]

##拷贝资源
COPY tars-node/install.sh /root/init/
COPY tars-node/entrypoint.sh /sbin/

ENTRYPOINT ["/bin/bash","/sbin/entrypoint.sh"]

CMD ["start"]

#Expose ports
EXPOSE 80
