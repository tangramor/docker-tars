# Tencent Tars 的Docker镜像脚本与使用

## [Click to Read English Version](https://github.com/tangramor/docker-tars#english-vesion) or Scroll Down to Read it

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


另外安装脚本把构建成功的 tarslog.tgz、tarsnotify.tgz、tarsproperty.tgz、tarsqueryproperty.tgz、tarsquerystat.tgz 和 tarsstat.tgz 都放到了 `/c/Users/<ACCOUNT>/tars_data/` 目录之下，可以参考Tars官方文档的 [安装框架普通基础服务](https://github.com/Tencent/Tars/blob/master/Install.md#44-%E5%AE%89%E8%A3%85%E6%A1%86%E6%9E%B6%E6%99%AE%E9%80%9A%E5%9F%BA%E7%A1%80%E6%9C%8D%E5%8A%A1) 来安装这些服务。


MySQL
-----

本镜像是Tars的docker版本，未安装mysql，可以使用官方mysql镜像（5.6）：
```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:5.6 --innodb_use_native_aio=0
```

注意上面的运行命令添加了 `--innodb_use_native_aio=0` ，因为mysql的aio对windows文件系统不支持

如果要使用5.7以后版本的mysql，需要再添加 `--sql_mode=NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION` 参数，因为不支持全零的date字段值（ https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_zero_date ）

或者你也可以挂载使用一个自定义的 my.cnf 来添加上述参数。


构建镜像 
--------

镜像构建命令：`docker build -t tars .`

tars-master 镜像构建命令：`docker build -t tars-master -f tars-master/Dockerfile .`

tars-node 镜像构建命令：`docker build -t tars-node -f tars-node/Dockerfile .`


开发方式
--------
使用docker镜像进行Tars相关的开发就方便很多了，我的做法是把项目放置在被挂载到镜像 /data 目录的本地目录下，例如 `/c/Users/<ACCOUNT>/tars_data` 。在本地使用编辑器或IDE对项目文件进行开发，然后开启命令行：`docker exec -it tars bash` 进入Tars环境进行编译或测试。

### 举例说明：
	
1. **开发服务端**

    首先使用docker命令启动容器，这里我们可以用 `tangramor/tars-master`  或者 `tangramor/docker-tars`：
    
    ```
    docker run -d -it --name tars -p 8080:8080 -v /c/Users/tangramor/Workspace/tars_data:/data tangramor/tars-master
    ```
    
    这个命令启动了 `tangramor/tars-master` 容器 **tars** 并将本地的一个目录 `/c/Users/tangramor/Workspace/tars_data` 挂载为容器的 /data 目录，同时它还把 8080 端口暴露出来了。
    
    然后我们可以在宿主机的 `/c/Users/tangramor/Workspace/tars_data` 目录下看到有两个子目录被创建出来了：log、tars，前者是resin的日志目录，后者里面是Tars各系统进程的日志目录。同时 `/c/Users/tangramor/Workspace/tars_data` 目录下还有各个需要手动部署的 Tars 子系统的部署 tgz 包，我们参考 [安装框架普通基础服务](https://github.com/Tencent/Tars/blob/master/Install.md#44-%E5%AE%89%E8%A3%85%E6%A1%86%E6%9E%B6%E6%99%AE%E9%80%9A%E5%9F%BA%E7%A1%80%E6%9C%8D%E5%8A%A1) 来安装这些服务。
    
    运行 `docker exec -it tars bash` 进入容器 **tars**，`cd /data` 进入工作目录，参考官方的 [服务开发](https://github.com/Tencent/Tars/blob/master/docs/tars_cpp_quickstart.md#5-%E6%9C%8D%E5%8A%A1%E5%BC%80%E5%8F%91--) 文档，开发 TestApp.HelloServer，其中 testHello 方法修改如下：
    
    ```
    int HelloImp::testHello(const std::string &sReq, std::string &sRsp, tars::TarsCurrentPtr current)
    {
        TLOGDEBUG("HelloImp::testHellosReq:"<<sReq<<endl);
        sRsp = sReq + " World!";
        return 0;
    }
    
    ```
    
    然后将编译完成的 HelloServer.tgz 部署到 tars-master 容器或者 docker-tars 容器里

2. **开发PHP客户端**

    C++的客户端可以参考官方的 [客户端同步/异步调用服务](https://github.com/Tencent/Tars/blob/master/docs/tars_cpp_quickstart.md#54-%E5%AE%A2%E6%88%B7%E7%AB%AF%E5%90%8C%E6%AD%A5%E5%BC%82%E6%AD%A5%E8%B0%83%E7%94%A8%E6%9C%8D%E5%8A%A1)。注意如果要把C++的客户端部署到 tars-node 容器里，那么不要混用 minideb 标签和 latest、php7 标签的镜像，因为会有依赖问题。
    
    这里主要讲一下PHP的客户端开发与部署。
    
    首先使用docker命令启动**php7**标签的容器，这里我们可以用 `tangramor/tars-node:php7` ：
    
    ```
    docker run -d -it --name tars-node --link tars:tars -p 80:80 -v /c/Users/tangramor/Workspace/tars_node:/data tangramor/tars-node:php7
    ```
    
    这个命令启动了 `tangramor/tars-node:php7` 容器 **tars-node** 并将本地的一个目录 `/c/Users/tangramor/Workspace/tars_node` 挂载为容器的 /data 目录，同时它连接了命名为 **tars** 的服务端容器，还把 80 端口暴露出来了。
    
    我们可以在宿主机的 `/c/Users/tangramor/Workspace/tars_node` 目录下看到有三个子目录被创建出来了：log、tars 和 web。前两个都是日志目录，最后一个在容器中被链接为 `/var/www/html`，也就是Apache服务器的根目录。并且在 web 目录下可以看到 phpinfo.php 文件。我们使用浏览器访问 http://127.0.0.1/phpinfo.php （linux、mac）或 http://192.168.99.100/phpinfo.php （windows）就可以看到PHP的信息页面了。
    
    我们从宿主机的 `/c/Users/tangramor/Workspace/tars_data/TestApp/HelloServer` 目录里找到 `Hello.tars` 文件，将它拷贝到宿主机的 `/c/Users/tangramor/Workspace/tars_node/web` 目录下。
    
    运行 `docker exec -it tars-node bash` 进入容器 **tars-node**，`cd /data/web` 来到web目录，然后执行 `wget https://raw.githubusercontent.com/Tencent/Tars/master/php/tarsclient/tars2php.php` 把 `tars2php.php` 文件下载到本地。然后执行 `php tars2php.php Hello.tars "TestApp.HelloServer.HelloObj"` ，我们可以在 web 目录下看到 TestApp 目录被创建出来，`TestApp/HelloServer/HelloObj` 目录下是生成的PHP的客户端文件。
    
    在 web 目录下再创建一个 `composer.json` 文件，内容如下：
    
    ```
    {
      "name": "demo",
      "description": "demo",
      "authors": [
        {
          "name": "Tangramor",
          "email": "tangramor@qq.com"
        }
      ],
      "require": {
        "php": ">=5.3",
        "phptars/tars-assistant" : "0.2.1"
      },
      "autoload": {
        "psr-4": {
          "TestApp\\": "TestApp/"
        }
      }
    }
    ```
    
    然后运行 `composer install` 命令，`vendor` 目录被创建出来了。这表明我们可以在PHP文件里使用 autoload 来加载 phptars。在 web 目录下新建 `index.php` 文件，内容如下：
    
    ```
    <?php
    	require_once("./vendor/autoload.php");
    	// 指定主控
    	$host = "tars";
    	$port = 20001;
    
    	$start = microtime();
    
    	try {
    		$servant = new TestApp\HelloServer\HelloObj\Hello($host, $port);
    
    		$in1 = "Hello";
    
    		$intVal = $servant->testHello($in1,$out1);
    
    		echo "服务器返回：".$out1;
    
    	} catch(phptars\TarsException $e) {
    	    // 错误处理
    	    echo "Error: ".$e;
    	}
    
    	$end = microtime();
    
    	echo "<p>耗时：".($end - $start)." 秒</p>";
    ```
    
    在宿主机上使用浏览器访问 http://127.0.0.1/index.php （linux、mac）或 http://192.168.99.100/index.php （windows），如果没有意外，页面应该返回类似下面的内容：
    
    ```
    服务器返回：Hello World!
    
    耗时：0.051169 秒
    ```
    	

Trouble Shooting
----------------

在启动容器后，可以 `docker exec -it tars bash` 进入容器，查看当前运行状态；如果 `/c/Users/<ACCOUNT>/tars_data/log/tars` 下面出现了 _log4j.log 文件，说明安装已经完成，resin运行起来了。



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

In the Dockerfile I put the successfully built service packages tarslog.tgz, tarsnotify.tgz, tarsproperty.tgz, tarsqueryproperty.tgz, tarsquerystat.tgz and tarsstat.tgz to /data, which should be mounted from the host machine like `/c/Users/<ACCOUNT>/tars_data/`. You can refer to [Install general basic service for framework](https://github.com/Tencent/Tars/blob/master/Install.en.md#44-install-general-basic-service-for-framework) to install those services.


MySQL
-----
This image does not have MySQL, you can use a docker official image(5.6):
```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:5.6 --innodb_use_native_aio=0
```

Please be aware of option `--innodb_use_native_aio=0` appended in the command above. Because MySQL aio does not support Windows file system.

If you want a 5.7 or higher version MySQL, you may need to add option `--sql_mode=NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION`. Because after 5.6 MySQL does not support zero date field ( https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_zero_date ).

You can also use a customized my.cnf to add those options.


Build Images
-------------
Build command: `docker build -t tars .`

Build command for tars-master: `docker build -t tars-master -f tars-master/Dockerfile .`

Build command for tars-node: `docker build -t tars-node -f tars-node/Dockerfile .`


Use The Image for Development
------------------------------
It should be easyer to do Tars related development with the docker image. My way is put the project files under the local folder which will be mounted as /data in the container, such as `/c/Users/<ACCOUNT>/tars_data`. And once you did and works in the project, you can use command `docker exec -it tars bash` to enter Tars environment and execute the compiling or testing works.


Trouble Shooting
----------------
Once you started up the container, you can enter it by command `docker exec -it tars bash` and then you can execute linux commands to check the status. If you see _log4j.log file under `/c/Users/<ACCOUNT>/tars_data/log/tars`, that means resin is up to work and the installation is done.


