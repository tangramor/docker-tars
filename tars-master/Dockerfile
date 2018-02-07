FROM centos

##安装glibc-devel flex、bison mysql 支持库 中文乱码
RUN yum install -y git gcc gcc-c++ make wget cmake mysql mysql-devel unzip iproute which glibc-devel flex bison ncurses-devel zlib-devel kde-l10n-Chinese glibc-common && yum clean all

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

##安装JDK
RUN mkdir -p /root/init && cd /root/init/ \
	&& wget --header "Cookie: oraclelicense=accept" -c --no-check-certificate http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm \
	&& rpm -ivh /root/init/jdk-8u131-linux-x64.rpm && rm -rf /root/init/jdk-8u131-linux-x64.rpm \
	&& echo "export JAVA_HOME=/usr/java/jdk1.8.0_131" >> /etc/profile \
	&& echo "CLASSPATH=\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> /etc/profile \
	&& echo "PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile \
	&& echo "export PATH JAVA_HOME CLASSPATH" >> /etc/profile
	
ENV JAVA_HOME /usr/java/jdk1.8.0_131

##安装Maven
RUN cd /usr/local/ && wget http://mirrors.gigenet.com/apache/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz \
	&& tar zxvf apache-maven-3.5.2-bin.tar.gz && echo "export MAVEN_HOME=/usr/local/apache-maven-3.5.2/" >> /etc/profile \
	&& echo "export PATH=\$PATH:\$MAVEN_HOME/bin" >> /etc/profile && source /etc/profile && mvn -v \
	&& rm -rf apache-maven-3.5.2-bin.tar.gz 

ENV MAVEN_HOME /usr/local/apache-maven-3.5.2

##安装resin
RUN cd /usr/local/ && wget http://caucho.com/download/resin-4.0.51.tar.gz && tar zxvf resin-4.0.51.tar.gz && mv resin-4.0.51 resin && rm -rf resin-4.0.51.tar.gz \
	&& mkdir -p /usr/local/mysql && ln -s /usr/lib64/mysql /usr/local/mysql/lib && ln -s /usr/include/mysql /usr/local/mysql/include && echo "/usr/local/mysql/lib/" >> /etc/ld.so.conf && ldconfig \
	&& cd /usr/local/mysql/lib/ && ln -s libmysqlclient.so.*.*.* libmysqlclient.a

##获取Tars源码
RUN wget https://github.com/Tencent/Tars/archive/master.zip \
	&& unzip -a master.zip \
	&& mv Tars-master Tars

##安装java语言框架
RUN source /etc/profile && cd /root/Tars/java && mvn clean install && mvn clean install -f core/client.pom.xml && mvn clean install -f core/server.pom.xml

##安装c++语言框架
RUN cd /root/Tars/cpp/thirdparty && sh thirdparty.sh 
RUN chmod u+x /root/Tars/cpp/build/build.sh
RUN cd /root/Tars/cpp/build/ && ./build.sh all 
RUN cd /root/Tars/cpp/build/ && ./build.sh install

##打包框架基础服务
RUN cd /root/Tars/cpp/build/ && make framework-tar \
	&& make tarsstat-tar && make tarsnotify-tar && make tarsproperty-tar && make tarslog-tar && make tarsquerystat-tar && make tarsqueryproperty-tar

##安装核心基础服务
RUN mkdir -p /usr/local/app/tars/ && cp /root/Tars/cpp/build/framework.tgz /usr/local/app/tars/ \
	&& cd /usr/local/app/tars/ && tar xzfv framework.tgz && rm -rf framework.tgz \
	&& mkdir -p /usr/local/app/patchs/tars.upload

##安装web管理系统
RUN cd /root/Tars/web/ && source /etc/profile && mvn clean package \
	&& cp /root/Tars/build/conf/resin.xml /usr/local/resin/conf/ \
	&& cp /root/Tars/web/target/tars.war /usr/local/resin/webapps/

##拷贝SQL文件
RUN mkdir -p /root/sql && cp -rf /root/Tars/cpp/framework/sql/* /root/sql/

##删除Tars源码
RUN rm -rf /root/Tars && rm -f /root/master.zip

##拷贝资源
COPY init/master-install.sh /root/init/
COPY entrypoint.sh /sbin/

ENTRYPOINT ["/bin/bash","/sbin/entrypoint.sh"]

CMD ["start"]

#Expose ports
EXPOSE 8080