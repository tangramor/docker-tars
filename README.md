# Tencent Tars 的Docker镜像脚本与使用

![Docker Pulls](https://img.shields.io/docker/pulls/tangramor/docker-tars.svg) ![Docker Automated build](https://img.shields.io/docker/automated/tangramor/docker-tars.svg) ![Docker Build Status](https://img.shields.io/docker/build/tangramor/docker-tars.svg)

## [Click to Read English Version](https://github.com/tangramor/docker-tars/blob/master/docs/README_en.md)

* [约定](#约定)
* [MySQL](#mysql)
* [镜像](#镜像)
  * [注意：](#注意)
* [环境变量](#环境变量)
  * [TZ](#tz)
  * [DBIP, DBPort, DBUser, DBPassword](#dbip-dbport-dbuser-dbpassword)
  * [DBTarsPass](#dbtarspass)
  * [MOUNT_DATA](#mount_data)
  * [INET_NAME](#inet_name)
  * [MASTER](#master)
  * [框架普通基础服务](#框架普通基础服务)
* [自己构建镜像](#自己构建镜像)
* [开发方式](#开发方式)
  * [举例说明：](#举例说明)
* [Trouble Shooting](#trouble-shooting)
* [感谢](#感谢)


约定
-----

本文档假定你的工作环境为**Windows**，因为Windows下的docker命令行环境会把C:盘、D:盘等盘符映射为 `/c/`、`/d/` 这样的目录形式，所以在文档中会直接使用 `/c/Users/` 这样的写法来描述C:盘的用户目录。


MySQL
-----

本镜像是Tars的docker版本，**未安装mysql**，可以使用官方mysql镜像（5.6）：
```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:5.6 --innodb_use_native_aio=0
```

注意上面的运行命令添加了 `--innodb_use_native_aio=0` ，因为mysql的aio对windows文件系统不支持


如果要使用 **5.7** 版本的mysql，需要再添加 `--sql_mode=NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION` 参数，因为不支持全零的date字段值（ https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_zero_date ）
```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:5.7 --sql_mode=NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION --innodb_use_native_aio=0
```


如果使用 **8.0** 版本的mysql，则直接设定 `--sql_mode=''`，即禁止掉缺省的严格模式，（参考 https://dev.mysql.com/doc/refman/8.0/en/sql-mode.html ）

```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:8 --sql_mode='' --innodb_use_native_aio=0
```

或者你也可以挂载使用一个自定义的 my.cnf 来添加上述参数。



镜像
----

docker镜像已经由docker hub自动构建：https://hub.docker.com/r/tangramor/docker-tars/ ，使用下面命令即可获取：
```
docker pull tangramor/docker-tars
```

tag 为 **php7** 的镜像支持PHP服务端开发，包含了php7.2环境和phptars扩展，也添加了MySQL C++ connector以方便开发：
```
docker pull tangramor/docker-tars:php7
```

tag 为 **php7mysql8** 的镜像支持PHP服务端开发，包含php7.2、JDK 10以及mysql8相关的支持修改（对TARS配置做了修改）：
```
docker pull tangramor/docker-tars:php7mysql8
```

tag 为 **minideb** 的镜像是使用名为 minideb 的精简版 debian 作为基础镜像的版本：
```
docker pull tangramor/docker-tars:minideb
```

tag 为 **php7deb** 的镜像是使用名为 minideb 的精简版 debian 作为基础镜像的版本，支持PHP服务端开发，包含了php7.2环境和phptars扩展：
```
docker pull tangramor/docker-tars:minideb
```

**tars-master** 之下是在镜像中删除了Tars源码的脚本，有跟 **docker-tars** 一致的tag，使用下面命令即可获取：
```
docker pull tangramor/tars-master
```

**tars-node** 之下是只部署 tarsnode 服务的节点镜像脚本，也删除了Tars源码，使用下面命令即可获取：
```
docker pull tangramor/tars-node
```

### 注意：

镜像使用的是官方Tars的源码编译构建的，容器启动后，还会有一个自动化的安装过程，因为原版的Tars代码里设置是需要修改的，容器必须根据启动后获得的IP、环境变量等信息修改设置文件，包括resin，需要重新对Tars管理应用打包，所以会花费一定的时间。可以通过监测 `/data/log/tars` 目录下的resin日志 `_log4j.log` 来查看resin是否完成了启动；还可以进入容器运行 `ps -ef` 命令查看进程信息来判断系统是否已经启动完成。


环境变量
--------
### TZ

时区设置，缺省为 `Asia/Shanghai` 。


### DBIP, DBPort, DBUser, DBPassword

在运行容器时需要指定数据库的**环境变量**，例如：
```
DBIP mysql
DBPort 3306
DBUser root
DBPassword password
```


### DBTarsPass

因为Tars的源码里面直接设置了mysql数据库里tars用户的密码，所以为了安全起见，可以通过设定此**环境变量** `DBTarsPass` 来让安装脚本替换掉缺省的tars数据库用户密码。


### MOUNT_DATA

如果是在**Linux**或者**Mac**上运行，可以设定**环境变量** `MOUNT_DATA` 为 `true` 。此选项用于将Tars的系统进程的数据目录挂载到 /data 目录之下（一般把外部存储卷挂载为 /data 目录），这样即使重新创建容器，只要环境变量一致（数据库也没变化），那么之前的部署就不会丢失。这符合容器是无状态的原则。可惜在**Windows**下由于[文件系统与虚拟机共享文件夹的权限问题](https://discuss.elastic.co/t/filebeat-docker-running-on-windows-not-allowing-application-to-rotate-the-log/89616/11)，我们**不能**使用这个选项。


### INET_NAME
如果想要把docker内部服务直接暴露到宿主机，可以在运行docker时使用 `--net=host` 选项（docker缺省使用的是bridge桥接模式），这时我们需要确定宿主机的网卡名称，如果不是 `eth0`，那么需要设定**环境变量** `INET_NAME` 的值为宿主机网卡名称，例如 `--env INET_NAME=ens160`。这种方式启动docker容器后，可以在宿主机使用 `netstat -anop |grep '8080\|10000\|10001' |grep LISTEN` 来查看端口是否被成功监听。


### MASTER
节点服务器需要把自己注册到主节点master，这时候需要将tarsnode的配置修改为指向master节点IP或者hostname，此**环境变量** `MASTER` 用于 **tars-node** 镜像，在运行此镜像容器前需要确定master节点IP或主机名hostname。


run_docker_tars.sh 里的命令如下，请自己修改：
```
docker run -d -it --name tars --link mysql --env MOUNT_DATA=false --env DBIP=mysql --env DBPort=3306 --env DBUser=root --env DBPassword=PASS -p 8080:8080 -v /c/Users/<ACCOUNT>/tars_data:/data tangramor/docker-tars
```

### 框架普通基础服务
另外安装脚本把构建成功的 tarslog.tgz、tarsnotify.tgz、tarsproperty.tgz、tarsqueryproperty.tgz、tarsquerystat.tgz 和 tarsstat.tgz 都放到了 `/c/Users/<ACCOUNT>/tars_data/` 目录之下，镜像本身已经自动安装了这些服务。你也可以参考Tars官方文档的 [安装框架普通基础服务](https://github.com/Tencent/Tars/blob/master/Install.md#44-%E5%AE%89%E8%A3%85%E6%A1%86%E6%9E%B6%E6%99%AE%E9%80%9A%E5%9F%BA%E7%A1%80%E6%9C%8D%E5%8A%A1) 来了解这些服务。



自己构建镜像 
-------------

镜像构建命令：`docker build -t tars .`


[tars-master](https://github.com/tangramor/tars-master) 镜像构建，请检出 tars-master 项目后执行命令：

```
git clone https://github.com/tangramor/tars-master.git
cd tars-master
docker build -t tars-master -f Dockerfile .
```


[tars-node](https://github.com/tangramor/tars-node) 镜像构建，请检出 tars-node 项目后执行命令：

```
git clone https://github.com/tangramor/tars-node.git
cd tars-node
docker build -t tars-node -f Dockerfile .
```


开发方式
--------
使用docker镜像进行Tars相关的开发就方便很多了，我的做法是把项目放置在被挂载到镜像 /data 目录的本地目录下，例如 `/c/Users/<ACCOUNT>/tars_data` 。在本地使用编辑器或IDE对项目文件进行开发，然后开启命令行：`docker exec -it tars bash` 进入Tars环境进行编译或测试。

### 举例说明：

**[TARS C++服务端与客户端开发](https://github.com/tangramor/docker-tars/wiki/TARS-CPP--%E6%9C%8D%E5%8A%A1%E7%AB%AF%E4%B8%8E%E5%AE%A2%E6%88%B7%E7%AB%AF%E5%BC%80%E5%8F%91)**

**[TARS PHP TCP服务端与客户端开发](https://github.com/tangramor/docker-tars/wiki/TARS-PHP-TCP%E6%9C%8D%E5%8A%A1%E7%AB%AF%E4%B8%8E%E5%AE%A2%E6%88%B7%E7%AB%AF%E5%BC%80%E5%8F%91)**

**[TARS PHP HTTP服务端与客户端开发](https://github.com/tangramor/docker-tars/wiki/TARS-PHP-HTTP%E6%9C%8D%E5%8A%A1%E7%AB%AF%E4%B8%8E%E5%AE%A2%E6%88%B7%E7%AB%AF%E5%BC%80%E5%8F%91)**


Trouble Shooting
----------------

在启动容器后，可以 `docker exec -it tars bash` 进入容器，查看当前运行状态；如果 `/c/Users/<ACCOUNT>/tars_data/log/tars` 下面出现了 _log4j.log 文件，说明安装已经完成，resin运行起来了。


感谢
------

本镜像脚本根据 https://github.com/panjen/docker-tars 修改，最初版本来自 https://github.com/luocheng812/docker_tars 。


