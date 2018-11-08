# Tencent Tars 的Docker镜像脚本与使用

![Docker Pulls](https://img.shields.io/docker/pulls/tarscloud/tars.svg) ![Docker Automated build](https://img.shields.io/docker/automated/tarscloud/tars.svg) ![Docker Build Status](https://img.shields.io/docker/build/tarscloud/tars.svg)

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
* [感谢](#感谢)


约定
-----

本文档假定你的工作环境为 **Windows**，因为Windows下的docker命令行环境会把C:盘、D:盘等盘符映射为 `/c/`、`/d/` 这样的目录形式，所以在文档中会直接使用 `/c/Users/` 这样的写法来描述C:盘的用户目录。


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

docker镜像已经由docker hub自动构建：https://hub.docker.com/r/tarscloud/tars/ 或 https://hub.docker.com/r/tangramor/docker-tars/ ，使用下面命令即可获取（注意替换 `<tag>` ）：
```
docker pull tarscloud/tars:<tag>
```

* tag 为 **latest** 的镜像支持C++服务端，包含 CentOS7 的标准C++运行环境；
* tag 为 **php** 的镜像支持PHP服务端，包含了 php 7.2 环境和 swoole、phptars 扩展；
* tag 为 **java** 的镜像支持Java服务端，包含 JDK 10.0.2 以及 maven 等支持；
* tag 为 **go** 的镜像支持Go语言服务端，包含 Golang 1.9.4；
* tag 为 **nodejs** 的镜像支持Nodejs服务端，包含 nodejs 8.11.3；
* tag 为 **dev** 的镜像包含了C++、PHP、Java、Go和Nodejs的服务端开发支持，用于开发，上述其它镜像则 **不包含** make等开发工具以减小镜像体积。

|            |            |
| ---------- | ---------- |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars.svg)](https://microbadger.com/images/tarscloud/tars "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars.svg)](https://microbadger.com/images/tarscloud/tars "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars:php.svg)](https://microbadger.com/images/tarscloud/tars:php "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars:php.svg)](https://microbadger.com/images/tarscloud/tars:php "Get your own image badge on microbadger.com") |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars:nodejs.svg)](https://microbadger.com/images/tarscloud/tars:nodejs "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars:nodejs.svg)](https://microbadger.com/images/tarscloud/tars:nodejs "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars:java.svg)](https://microbadger.com/images/tarscloud/tars:java "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars:java.svg)](https://microbadger.com/images/tarscloud/tars:java "Get your own image badge on microbadger.com") |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars:go.svg)](https://microbadger.com/images/tarscloud/tars:go "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars:go.svg)](https://microbadger.com/images/tarscloud/tars:go "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars:dev.svg)](https://microbadger.com/images/tarscloud/tars:dev "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars:dev.svg)](https://microbadger.com/images/tarscloud/tars:dev "Get your own image badge on microbadger.com")


**tars-node** 之下是只部署 tarsnode 服务的节点镜像脚本，使用下面命令即可获取：
```
docker pull tarscloud/tars-node:<tag>
```

|            |            |
| ---------- | ---------- |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars-node.svg)](https://microbadger.com/images/tarscloud/tars-node "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node.svg)](https://microbadger.com/images/tarscloud/tars-node "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars-node:php.svg)](https://microbadger.com/images/tarscloud/tars-node:php "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node:php.svg)](https://microbadger.com/images/tarscloud/tars-node:php "Get your own image badge on microbadger.com") |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars-node:nodejs.svg)](https://microbadger.com/images/tarscloud/tars-node:nodejs "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node:nodejs.svg)](https://microbadger.com/images/tarscloud/tars-node:nodejs "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars-node:java.svg)](https://microbadger.com/images/tarscloud/tars-node:java "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node:java.svg)](https://microbadger.com/images/tarscloud/tars-node:java "Get your own image badge on microbadger.com") |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars-node:go.svg)](https://microbadger.com/images/tarscloud/tars-node:go "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node:go.svg)](https://microbadger.com/images/tarscloud/tars-node:go "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars-node:dev.svg)](https://microbadger.com/images/tarscloud/tars-node:dev "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node:dev.svg)](https://microbadger.com/images/tarscloud/tars-node:dev "Get your own image badge on microbadger.com") |

### 注意：

镜像使用的是官方Tars的源码编译构建的，容器启动后，还会有一个自动化的安装过程，因为原版的Tars代码里设置是需要修改的，容器必须根据启动后获得的IP、环境变量等信息修改设置文件，所以会花费一定的时间。可以进入容器运行 `ps -ef` 命令查看进程信息来判断系统是否已经启动完成。


环境变量
--------
### TZ

时区设置，缺省为 `Asia/Shanghai` 。


### DBIP, DBPort, DBUser, DBPassword

在运行容器时需要指定数据库的 **环境变量**，例如：
```
DBIP mysql
DBPort 3306
DBUser root
DBPassword password
```


### DBTarsPass

因为Tars的源码里面直接设置了mysql数据库里tars用户的密码，所以为了安全起见，可以通过设定此 **环境变量** `DBTarsPass` 来让安装脚本替换掉缺省的tars数据库用户密码。


### MOUNT_DATA

如果是在 **Linux** 或者 **Mac** 上运行，可以设定 **环境变量** `MOUNT_DATA` 为 `true` 。此选项用于将Tars的系统进程的数据目录挂载到 /data 目录之下（一般把外部存储卷挂载为 /data 目录），这样即使重新创建容器，只要环境变量一致（数据库也没变化），那么之前的部署就不会丢失。这符合容器是无状态的原则。可惜在 **Windows** 下由于[文件系统与虚拟机共享文件夹的权限问题](https://discuss.elastic.co/t/filebeat-docker-running-on-windows-not-allowing-application-to-rotate-the-log/89616/11)，我们 **不能** 使用这个选项。


### INET_NAME
如果想要把docker内部服务直接暴露到宿主机，可以在运行docker时使用 `--net=host` 选项（docker缺省使用的是bridge桥接模式），这时我们需要确定宿主机的网卡名称，如果不是 `eth0`，那么需要设定 **环境变量** `INET_NAME` 的值为宿主机网卡名称，例如 `--env INET_NAME=ens160`。这种方式启动docker容器后，可以在宿主机使用 `netstat -anop |grep '8080\|10000\|10001' |grep LISTEN` 来查看端口是否被成功监听。


### MASTER
节点服务器需要把自己注册到主节点master，这时候需要将tarsnode的配置修改为指向master节点IP或者hostname，此 **环境变量** `MASTER` 用于 **tars-node** 镜像，在运行此镜像容器前需要确定master节点IP或主机名hostname。


run_docker_tars.sh 里的命令如下，请自己修改：
```
docker run -d -it --name tars --link mysql --env MOUNT_DATA=false --env DBIP=mysql --env DBPort=3306 --env DBUser=root --env DBPassword=PASS -p 8080:8080 -v /c/Users/<ACCOUNT>/tars_data:/data tarscloud/tars
```

### 框架普通基础服务
另外安装脚本把构建成功的 tarslog.tgz、tarsnotify.tgz、tarsproperty.tgz、tarsqueryproperty.tgz、tarsquerystat.tgz 和 tarsstat.tgz 都放到了 `/c/Users/<ACCOUNT>/tars_data/` 目录之下，镜像本身已经自动安装了这些服务。你也可以参考Tars官方文档的 [安装框架普通基础服务](https://github.com/TarsCloud/Tars/blob/master/Install.zh.md#44-%E5%AE%89%E8%A3%85%E6%A1%86%E6%9E%B6%E6%99%AE%E9%80%9A%E5%9F%BA%E7%A1%80%E6%9C%8D%E5%8A%A1) 来了解这些服务。



自己构建镜像 
-------------

镜像构建命令：`docker build -t tars .`


[tars-node](https://github.com/TarsDocker/tars-node) 镜像构建，请检出 tars-node 项目后执行命令：

```
git clone https://github.com/TarsDocker/tars-node.git
cd tars-node
docker build -t tars-node -f Dockerfile .
```


开发方式
--------
使用docker镜像进行Tars相关的开发就方便很多了，我的做法是把项目放置在被挂载到镜像 /data 目录的本地目录下，例如 `/c/Users/<ACCOUNT>/tars_data` 。在本地使用编辑器或IDE对项目文件进行开发，然后开启命令行：`docker exec -it tars bash` 进入Tars环境进行编译或测试。

### 举例说明（含PDF下载）：

**[TARS C++服务端与客户端开发](https://tangramor.gitlab.io/tars-docker-guide/1.TARS-CPP-%E6%9C%8D%E5%8A%A1%E7%AB%AF%E4%B8%8E%E5%AE%A2%E6%88%B7%E7%AB%AF%E5%BC%80%E5%8F%91/)**

**[TARS PHP TCP服务端与客户端开发](https://tangramor.gitlab.io/tars-docker-guide/2.TARS-PHP-TCP%E6%9C%8D%E5%8A%A1%E7%AB%AF%E4%B8%8E%E5%AE%A2%E6%88%B7%E7%AB%AF%E5%BC%80%E5%8F%91/)**

**[TARS PHP HTTP服务端与客户端开发](https://tangramor.gitlab.io/tars-docker-guide/3.TARS-PHP-HTTP%E6%9C%8D%E5%8A%A1%E7%AB%AF%E4%B8%8E%E5%AE%A2%E6%88%B7%E7%AB%AF%E5%BC%80%E5%8F%91/)**

**[TARS JAVA服务端与客户端开发](https://tangramor.gitlab.io/tars-docker-guide/4.TARS-JAVA-%E6%9C%8D%E5%8A%A1%E7%AB%AF%E4%B8%8E%E5%AE%A2%E6%88%B7%E7%AB%AF%E5%BC%80%E5%8F%91/)**

**[TARS Kubernetes部署](https://tangramor.gitlab.io/tars-docker-guide/9.TARS-Kubernetes-%E9%83%A8%E7%BD%B2/)**

以上文档网站基于 https://github.com/tangramor/mkdocs 生成，支持 Gitlab Pages 和 PDF 导出（含中文）。


感谢
------

本镜像脚本根据 https://github.com/panjen/docker-tars 修改，最初版本来自 https://github.com/luocheng812/docker_tars 。


