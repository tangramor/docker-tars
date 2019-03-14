FROM centos/systemd

WORKDIR /root/

##镜像时区 
ENV TZ=Asia/Shanghai

ENV DBIP 127.0.0.1
ENV DBPort 3306
ENV DBUser root
ENV DBPassword password

# Mysql里tars用户的密码，缺省为tars2015
ENV DBTarsPass tars2015

ENV JAVA_HOME /usr/java/jdk-11.0.2

ENV MAVEN_HOME /usr/local/apache-maven-3.6.0

ENV GOPATH=/usr/local/go

# 中文字符集支持
ENV LC_ALL "zh_CN.UTF-8"

COPY --from=tarscloud/tars:dev /usr/local/mysql/lib /usr/local/mysql/lib
COPY --from=tarscloud/tars:dev /usr/include/mysql /usr/include/mysql
COPY --from=tarscloud/tars:dev $GOPATH $GOPATH
COPY --from=tarscloud/tars:dev $JAVA_HOME $JAVA_HOME
COPY --from=tarscloud/tars:dev $MAVEN_HOME $MAVEN_HOME
COPY --from=tarscloud/tars:dev /root/.m2 /root/.m2
COPY --from=tarscloud/tars:dev /etc/profile /etc/profile
COPY --from=tarscloud/tars:dev /root/.bashrc /root/.bashrc
COPY --from=tarscloud/tars:dev /root/phptars /root/phptars
COPY --from=tarscloud/tars:dev /usr/lib64/php/modules/phptars.so /usr/lib64/php/modules/phptars.so
COPY --from=tarscloud/tars:dev /usr/lib64/php/modules/swoole.so /usr/lib64/php/modules/swoole.so
COPY --from=tarscloud/tars:dev /etc/php.d/phptars.ini /etc/php.d/phptars.ini
COPY --from=tarscloud/tars:dev /etc/php.d/swoole.ini /etc/php.d/swoole.ini
COPY --from=tarscloud/tars:dev /usr/local/bin/composer /usr/local/bin/composer

##安装
RUN yum -y install https://repo.mysql.com/yum/mysql-8.0-community/el/7/x86_64/mysql80-community-release-el7-1.noarch.rpm \
    && yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum -y install yum-utils && yum-config-manager --enable remi-php73 \
    && yum -y install git gcc gcc-c++ go make wget cmake mysql mysql-devel unzip iproute which glibc-devel flex bison ncurses-devel protobuf-devel zlib-devel kde-l10n-Chinese glibc-common hiredis-devel rapidjson-devel boost boost-devel php php-cli php-devel php-mbstring php-pecl-mcrypt php-json php-gd php-curl php-mysqlnd php-pecl-zip php-fileinfo php-phpiredis php-pecl-redis4 php-seld-phar-utils pcre-devel tzdata rsync \
    # 设置时区与编码
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 \
    && ln -s /usr/include/mysql /usr/local/mysql/include && echo "/usr/local/mysql/lib/" >> /etc/ld.so.conf && ldconfig \
    && cd /usr/local/mysql/lib/ && rm -f libmysqlclient.a && ln -s libmysqlclient.so.*.*.* libmysqlclient.a \
    # 获取最新TARS源码
    && cd /root/ && git clone https://github.com/TarsCloud/Tars \
    && cd /root/Tars/ && git submodule update --init --recursive framework \
    && git submodule update --init --recursive web && cd web && git checkout master && git pull && cd .. \
    && git submodule update --init --recursive php && cd php && git checkout master && git pull && cd ..  \
    && git submodule update --init --recursive go && cd go && git checkout master && git pull && cd ..  \
    && git submodule update --init --recursive java && cd java && git checkout master && git pull && cd ..  \
    && mkdir -p /data && chmod u+x /root/Tars/framework/build/build.sh \
    # 以下对源码配置进行mysql8对应的修改
    && sed -i '32s/rt/rt crypto ssl/' /root/Tars/framework/CMakeLists.txt \
    # 开始构建
    && cd /root/Tars/framework/build/ && ./build.sh all \
    && ./build.sh install \
    && cd /root/Tars/framework/build/ && make framework-tar \
    && make tarsstat-tar && make tarsnotify-tar && make tarsproperty-tar && make tarslog-tar && make tarsquerystat-tar && make tarsqueryproperty-tar \
    && mkdir -p /usr/local/app/tars/ && cp /root/Tars/framework/build/framework.tgz /usr/local/app/tars/ && cp /root/Tars/framework/build/t*.tgz /root/ \
    && cd /usr/local/app/tars/ && tar xzfv framework.tgz && rm -rf framework.tgz \
    && mkdir -p /usr/local/app/patchs/tars.upload \
    && wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash \
    && source ~/.bashrc && nvm install v8.15.1 \
    && cp -Rf /root/Tars/web /usr/local/tarsweb && cd /usr/local/tarsweb/ && npm install \
    && npm install -g pm2 @tars/deploy @tars/stream @tars/rpc @tars/logs @tars/config @tars/monitor @tars/notify @tars/utils @tars/dyeing @tars/registry \
    && mkdir -p /root/sql && cp -rf /root/Tars/framework/sql/* /root/sql/ \
    && cd /root/Tars/framework/build/ && ./build.sh cleanall \
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
EXPOSE 80
