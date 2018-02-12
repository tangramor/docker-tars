本镜像脚本根据 https://github.com/panjen/docker-tars 修改，最初版本来自 https://github.com/luocheng812/docker_tars 。


镜像
-----

docker镜像已经由docker hub自动构建：https://hub.docker.com/r/tangramor/docker-tars/ ，使用下面命令即可获取：

```
docker pull tangramor/docker-tars
```

tag 为 php7 的镜像包含了php7.2环境和phptars扩展，也添加了MySQL C++ connector以方便开发：

```
docker pull tangramor/docker-tars:php7
```

tag 为 minideb 的镜像是使用名为 minideb 的精简版 debian 作为基础镜像的版本：

```
docker pull tangramor/docker-tars:minideb
```


tars-master 之下是在镜像中删除了Tars源码的脚本，使用下面命令即可获取：

```
docker pull tangramor/docker-tars-master
```


tars-node 之下是只部署 tarsnode 服务的节点镜像脚本，也删除了Tars源码，使用下面命令即可获取：

```
docker pull tangramor/docker-tars-node

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
-------

镜像构建命令：`docker build -t tars .`

tars-master 镜像构建命令：`docker build -t tars-master -f tars-master/Dockerfile .`

tars-node 镜像构建命令：`docker build -t tars-node -f tars-node/Dockerfile .`


开发方式
--------
使用docker镜像进行Tars相关的开发就方便很多了，我的做法是把项目放置在被挂载到镜像 /data 目录的本地目录下，例如 /c/Users/<ACCOUNT>/tars_data 。在本地使用编辑器或IDE对项目文件进行开发，然后开启命令行：`docker exec -it tars bash` 进入Tars环境进行编译或测试。


Trouble Shooting
----------------

在启动容器后，可以 `docker exec -it tars bash` 进入容器，查看当前运行状态；如果 /c/Users/\<ACCOUNT\>/tars_data/log/tars 下面出现了 _log4j.log 文件，说明安装已经完成，resin运行起来了。

，resin运行起来了。

