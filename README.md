本镜像脚本根据 https://github.com/panjen/docker-tars 修改，最初版本来自 https://github.com/luocheng812/docker_tars 。


镜像
----

docker镜像已经由docker hub自动构建：https://hub.docker.com/r/tangramor/docker-tars/ ，使用下面命令即可获取：
```
docker pull tangramor/docker-tars
```

tag 为 **php7** 的镜像包含了php7.2环境和phptars扩展，也添加了MySQL C++ connector以方便开发：
```
docker pull tangramor/docker-tars:php7
```

tag 为 **minideb** 的镜像是使用名为 minideb 的精简版 debian 作为基础镜像的版本：
```
docker pull tangramor/docker-tars:minideb
```

**tars-master** 之下是在镜像中删除了Tars源码的脚本，使用下面命令即可获取：
```
docker pull tangramor/tars-master
```

**tars-node** 之下是只部署 tarsnode 服务的节点镜像脚本，也删除了Tars源码，使用下面命令即可获取：
```
docker pull tangramor/tars-node
```

在运行容器时需要指定数据库的环境变量，例如：
```
DBIP mysql
DBPort 3306
DBUser root
DBPassword password
```

run_docker_tars.sh 里的命令如下，请自己修改：
```
docker run -d -it --name tars --link mysql --env DBIP=mysql --env DBPort=3306 --env DBUser=root --env DBPassword=PASS -p 8080:8080 -v /c/Users/<ACCOUNT>/tars_data:/data tangramor/docker-tars
```


另外安装脚本把构建成功的 tarslog.tgz、tarsnotify.tgz、tarsproperty.tgz、tarsqueryproperty.tgz、tarsquerystat.tgz 和 tarsstat.tgz 都放到了 /c/Users/\<ACCOUNT\>/tars_data/ 目录之下，可以参考Tars官方文档的 [安装框架普通基础服务](https://github.com/Tencent/Tars/blob/master/Install.md#44-%E5%AE%89%E8%A3%85%E6%A1%86%E6%9E%B6%E6%99%AE%E9%80%9A%E5%9F%BA%E7%A1%80%E6%9C%8D%E5%8A%A1) 来安装这些服务。


MySQL
-----

本镜像是Tars的docker版本，未安装mysql，可以使用官方mysql镜像（5.6）：
```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:5.6 --innodb_use_native_aio=0
```

注意上面的运行命令添加了 `--innodb_use_native_aio=0` ，因为mysql的aio对windows文件系统不支持

如果要使用5.7以后版本的mysql，需要再添加 `--sql_mode="NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"` 参数，因为不支持全零的date字段值（ https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_zero_date ）

或者你也可以挂载使用一个自定义的 my.cnf 来添加上述参数。


构建镜像 
--------

镜像构建命令：`docker build -t tars .`

tars-master 镜像构建命令：`docker build -t tars-master -f tars-master/Dockerfile .`

tars-node 镜像构建命令：`docker build -t tars-node -f tars-node/Dockerfile .`


开发方式
--------
使用docker镜像进行Tars相关的开发就方便很多了，我的做法是把项目放置在被挂载到镜像 /data 目录的本地目录下，例如 /c/Users/\<ACCOUNT\>/tars_data 。在本地使用编辑器或IDE对项目文件进行开发，然后开启命令行：`docker exec -it tars bash` 进入Tars环境进行编译或测试。


Trouble Shooting
----------------

在启动容器后，可以 `docker exec -it tars bash` 进入容器，查看当前运行状态；如果 /c/Users/\<ACCOUNT\>/tars_data/log/tars 下面出现了 _log4j.log 文件，说明安装已经完成，resin运行起来了。



English Vesion
===============

The scripts of this image are based on project https://github.com/panjen/docker-tars, which is from https://github.com/luocheng812/docker_tars.

Image
------
The docker image is built automatically by docker hub: https://hub.docker.com/r/tangramor/docker-tars/ . You can pull it by following command:
```
docker pull tangramor/docker-tars
```

The image with **php7** tag includes php7.2 and phptars extension, as well with MySQL C++ connector for development:
```
docker pull tangramor/docker-tars:php7
```

The image with **minideb** tag is based on minideb which is "a small image based on Debian designed for use in containers":
```
docker pull tangramor/docker-tars:minideb
```

The image **tars-master** removed Tars source code from the docker-tars image:
```
docker pull tangramor/tars-master
```

The image **tars-node** has only tarsnode service deployed, and does not have Tars source code either:
```
docker pull tangramor/tars-node
```

When running the container, you need to set the environment parameters:
```
DBIP mysql
DBPort 3306
DBUser root
DBPassword password
```

The command in run_docker_tars.sh is like following, you should modify it accordingly:
```
docker run -d -it --name tars --link mysql --env DBIP=mysql --env DBPort=3306 --env DBUser=root --env DBPassword=PASS -p 8080:8080 -v /c/Users/<ACCOUNT>/tars_data:/data tangramor/docker-tars
```

In the Dockerfile I put the successfully built service packages tarslog.tgz, tarsnotify.tgz, tarsproperty.tgz, tarsqueryproperty.tgz, tarsquerystat.tgz and tarsstat.tgz to /data, which should be mounted from the host machine like /c/Users/\<ACCOUNT\>/tars_data/. You can refer to [Install general basic service for framework](https://github.com/Tencent/Tars/blob/master/Install.en.md#44-install-general-basic-service-for-framework) to install those services.


MySQL
-----
This image does not have MySQL, you can use a docker official image(5.6):
```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:5.6 --innodb_use_native_aio=0
```

Please be aware of option `--innodb_use_native_aio=0` appended in the command above. Because MySQL aio does not support Windows file system.

If you want a 5.7 or higher version MySQL, you may need to add option `--sql_mode="NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"`. Because after 5.6 MySQL does not support zero date field ( https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_zero_date ).

You can also use a customized my.cnf to add those options.


Build Images
-------------
Build command: `docker build -t tars .`

Build command for tars-master: `docker build -t tars-master -f tars-master/Dockerfile .`

Build command for tars-node: `docker build -t tars-node -f tars-node/Dockerfile .`


Use The Image for Development
------------------------------
It should be easyer to do Tars related development with the docker image. My way is put the project files under the local folder which will be mounted as /data in the container, such as /c/Users/\<ACCOUNT\>/tars_data. And once you did and works in the project, you can use command `docker exec -it tars bash` to enter Tars environment and execute the compiling or testing works.


Trouble Shooting
----------------
Once you started up the container, you can enter it by command `docker exec -it tars bash` and then you can execute linux commands to check the status. If you see _log4j.log file under /c/Users/\<ACCOUNT\>/tars_data/log/tars, that means resin is up to work and the installation is done.


