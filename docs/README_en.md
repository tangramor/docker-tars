
![Docker Pulls](https://img.shields.io/docker/pulls/tangramor/docker-tars.svg) ![Docker Automated build](https://img.shields.io/docker/automated/tangramor/docker-tars.svg) ![Docker Build Status](https://img.shields.io/docker/build/tangramor/docker-tars.svg)


TOC
-----

* [Stipulation](#stipulation)
* [MySQL](#mysql)
* [Image](#image)
   * [Notice](#notice)
* [Environment Parameters](#environment-parameters)
   * [TZ](#tz)
   * [DBIP, DBPort, DBUser, DBPassword](#dbip-dbport-dbuser-dbpassword)
   * [MOUNT_DATA](#mount_data)
   * [INET_NAME](#inet_name)
   * [MASTER](#master)
   * [General basic service for framework](#general-basic-service-for-framework)
* [Build Images](#build-images)
* [Use The Image for Development](#use-the-image-for-development)
   * [For Example:](#for-example)
* [Thanks](#thanks)


Stipulation
------------
In this doc, we assume that you are working in **Windows**. Because the command line environment of docker in Windows will map disk driver C:, D: to `/c/` and `/d/`, just like under *nix, we will use `/c/Users/` to describe the User folder in driver C:.


MySQL
-----
This image does **NOT** have MySQL, you can use a docker official image(5.6):
```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:5.6 --innodb_use_native_aio=0
```

Please be aware of option `--innodb_use_native_aio=0` appended in the command above. Because MySQL aio does not support Windows file system.


If you use a **5.7** MySQL, you may need to add option `--sql_mode=NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION`. Because after 5.6 MySQL does not support zero date field ( https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_zero_date ).
```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:5.7 --sql_mode=NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION --innodb_use_native_aio=0
```


If use **8.0** MySQL, you need to set `--sql_mode=''`, that will disable the default strict mode ( https://dev.mysql.com/doc/refman/8.0/en/sql-mode.html )

```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:8 --sql_mode='' --innodb_use_native_aio=0
```


You can also use a customized my.cnf to add those options.


Image
------
The docker image is built automatically by docker hub: https://hub.docker.com/r/tarscloud/tars/ or https://hub.docker.com/r/tangramor/docker-tars/ . You can pull it by following command (please change `<tag>` accordingly):
```
docker pull tarscloud/tars:<tag>
```

* **latest** tag supports C++ server, includes standard C++ env of CentOS7;
* **php** tag supports PHP server, includes php 7.2 and swoole, phptars extensions;
* **java** tag supports Java server, includes JDK 10.0.2 and maven;
* **go** tag supports Go server, includes Golang 1.9.4;
* **nodejs** tag supports Nodejs server, includes nodejs 8.11.3;
* **dev** tag inludes C++, PHP, Java, Go and Nodejs server side development support. The above images **do not include** development tools like make to reduce image size.

|            |            |
| ---------- | ---------- |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars.svg)](https://microbadger.com/images/tarscloud/tars "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars.svg)](https://microbadger.com/images/tarscloud/tars "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars:php.svg)](https://microbadger.com/images/tarscloud/tars:php "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars:php.svg)](https://microbadger.com/images/tarscloud/tars:php "Get your own image badge on microbadger.com") |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars:nodejs.svg)](https://microbadger.com/images/tarscloud/tars:nodejs "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars:nodejs.svg)](https://microbadger.com/images/tarscloud/tars:nodejs "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars:java.svg)](https://microbadger.com/images/tarscloud/tars:java "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars:java.svg)](https://microbadger.com/images/tarscloud/tars:java "Get your own image badge on microbadger.com") |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars:go.svg)](https://microbadger.com/images/tarscloud/tars:go "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars:go.svg)](https://microbadger.com/images/tarscloud/tars:go "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars:dev.svg)](https://microbadger.com/images/tarscloud/tars:dev "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars:dev.svg)](https://microbadger.com/images/tarscloud/tars:dev "Get your own image badge on microbadger.com")


The image **tars-node** has only tarsnode service deployed, and does not have Tars source code either:
```
docker pull tarscloud/tars-node:<tag>
```
|            |            |
| ---------- | ---------- |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars-node.svg)](https://microbadger.com/images/tarscloud/tars-node "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node.svg)](https://microbadger.com/images/tarscloud/tars-node "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars-node:php.svg)](https://microbadger.com/images/tarscloud/tars-node:php "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node:php.svg)](https://microbadger.com/images/tarscloud/tars-node:php "Get your own image badge on microbadger.com") |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars-node:nodejs.svg)](https://microbadger.com/images/tarscloud/tars-node:nodejs "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node:nodejs.svg)](https://microbadger.com/images/tarscloud/tars-node:nodejs "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars-node:java.svg)](https://microbadger.com/images/tarscloud/tars-node:java "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node:java.svg)](https://microbadger.com/images/tarscloud/tars-node:java "Get your own image badge on microbadger.com") |
| [![](https://images.microbadger.com/badges/version/tarscloud/tars-node:go.svg)](https://microbadger.com/images/tarscloud/tars-node:go "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node:go.svg)](https://microbadger.com/images/tarscloud/tars-node:go "Get your own image badge on microbadger.com") | [![](https://images.microbadger.com/badges/version/tarscloud/tars-node:dev.svg)](https://microbadger.com/images/tarscloud/tars-node:dev "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/tarscloud/tars-node:dev.svg)](https://microbadger.com/images/tarscloud/tars-node:dev "Get your own image badge on microbadger.com") |


### Notice

The docker images are built based on Tars official source code, after the container started, it will launch an automatical installation process because the it need to modify the configurations in the official build according to the container's IP and environment parameters. That will need some minutes, and you may check the resin log `_log4j.log` under `/data/log/tars` to see if resin has started, or you can run `ps -ef` in container to check if all the processes have started.


Environment Parameters
----------------------
### TZ
The timezone definition, default: `Asia/Shanghai`.


### DBIP, DBPort, DBUser, DBPassword
When running the container, you need to set the environment parameters:
```
DBIP mysql
DBPort 3306
DBUser root
DBPassword password
```

### MOUNT_DATA
If you are runing container under **Linux** or **Mac**, you can set the **environment parameter** `MOUNT_DATA` to `true`. This option is used to link the data folders of Tars sub systems to the folers under /data, which we often mount to a external volumn. So even we removed old container and started a new one, with the old data in /data folder and mysql database, our deployments will not lose. That meets the principle "container should be stateless". **BUT** We **CANNOT** use this option under **Windows** because of the [problem of Windows file system and virtualbox](https://discuss.elastic.co/t/filebeat-docker-running-on-windows-not-allowing-application-to-rotate-the-log/89616/11).

### INET_NAME
If you want to expose all the Tars services to the host OS, you can use `--net=host` option when execute docker (the default mode that docker uses is bridge). Here we need to know the ethernet interface name, and if it is not `eth0`, we need to set the **environment parameter** `INET_NAME` to the one that host OS uses, such as `--env INET_NAME=ens160`. Once you started container with this network mode, you can execute `netstat -anop |grep '8080\|10000\|10001' |grep LISTEN` unser host OS to check if these ports are listened correctly.

### MASTER
The tar node server should register itself to the master node. This **environment parameter** `MASTER` is only for **tars-node** docker image, and you should set it to the IP or hostname of the master node.

The command in run_docker_tars.sh is like following, you should modify it accordingly:
```
docker run -d -it --name tars --link mysql --env DBIP=mysql --env DBPort=3306 --env DBUser=root --env DBPassword=PASS -p 8080:8080 -v /c/Users/<ACCOUNT>/tars_data:/data tangramor/docker-tars
```

### General basic service for framework
In the Dockerfile I put the successfully built service packages tarslog.tgz, tarsnotify.tgz, tarsproperty.tgz, tarsqueryproperty.tgz, tarsquerystat.tgz and tarsstat.tgz to /data, which should be mounted from the host machine like `/c/Users/<ACCOUNT>/tars_data/`. These services have been automatically installed in the docker image. You can refer to [Install general basic service for framework](https://github.com/TarsCloud/Tars/blob/master/Install.md#44-install-general-basic-service-for-framework) to understand those services.


Build Images
-------------
Build command: `docker build -t tars .`

Build command for tars-node: `docker build -t tars-node -f tars-node/Dockerfile .`


To build image of [tars-node](https://github.com/tangramor/tars-node) , you need to checkout tars-node and run docker build command:

```
git clone https://github.com/tangramor/tars-node.git
cd tars-node
docker build -t tars-node -f Dockerfile .
```


Use The Image for Development
------------------------------
It should be easyer to do Tars related development with the docker image. My way is put the project files under the local folder which will be mounted as /data in the container, such as `/c/Users/<ACCOUNT>/tars_data`. And once you did and works in the project, you can use command `docker exec -it tars bash` to enter Tars environment and execute the compiling or testing works.

### For Example:

**[TARS C++ Server & Client Development](https://github.com/tangramor/docker-tars/wiki/TARS-CPP-Server-&-Client-Development)**

**[TARS PHP TCP Server & Client Development](https://github.com/tangramor/docker-tars/wiki/TARS-PHP-TCP-Server-&-Client-Development)**

**[TARS PHP HTTP Server & Client Development](https://github.com/tangramor/docker-tars/wiki/TARS-PHP-HTTP-Server-&-Client-Development)**



Thanks
---------------

The scripts of this image are based on project https://github.com/panjen/docker-tars, which is from https://github.com/luocheng812/docker_tars.
