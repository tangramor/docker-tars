TOC
-----

* [Stipulation](#stipulation)
* [MySQL](#mysql)
* [Image](#image)
   * [Notice](#notice)
* [Environment Parameters](#environment-parameters)
   * [DBIP, DBPort, DBUser, DBPassword](#dbip-dbport-dbuser-dbpassword)
   * [MOUNT_DATA](#mount_data)
   * [INET_NAME](#inet_name)
   * [MASTER](#master)
   * [General basic service for framework](#general-basic-service-for-framework)
* [Build Images](#build-images)
* [Use The Image for Development](#use-the-image-for-development)
   * [For Example:](#for-example)
* [Trouble Shooting](#trouble-shooting)
* [Thanks](#thanks)


Stipulation
------------
In this doc, we assume that you are working in **Windows**. Because the command line environment of docker in Windows will map disk driver C:, D: to `/c/` and `/d/`, just like under *nix, we will use `/c/Users/` to describe the User folder in driver C:.


MySQL
-----
This image does not have MySQL, you can use a docker official image(5.6):
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
The docker image is built automatically by docker hub: https://hub.docker.com/r/tangramor/docker-tars/ . You can pull it by following command:
```
docker pull tangramor/docker-tars
```

The image with **php7** tag uses source code of TARS **[phptars](https://github.com/Tencent/Tars/tree/phptars)** branch, which support PHP server development, and it includes php7.2 and phptars extension, as well with MySQL C++ connector for development:
```
docker pull tangramor/docker-tars:php7
```

The image with **minideb** tag is based on minideb which is "a small image based on Debian designed for use in containers":
```
docker pull tangramor/docker-tars:minideb
```

The image with **php7mysql8** tag uses source code of TARS **[phptars](https://github.com/Tencent/Tars/tree/phptars)** branch, which support PHP server development, and it includes php7.2, JDK 10 and mysql8 related support:
```
docker pull tangramor/docker-tars:php7mysql8
```

The image **tars-master** removed Tars source code from the docker-tars image:
```
docker pull tangramor/tars-master
```

The image **tars-node** has only tarsnode service deployed, and does not have Tars source code either:
```
docker pull tangramor/tars-node
```

### Notice

The docker images are built based on Tars official source code, after the container started, it will launch an automatical installation process because the it need to modify the configurations in the official build according to the container's IP and environment parameters. That will need some minutes, and you may check the resin log `_log4j.log` under `/data/log/tars` to see if resin has started, or you can run `ps -ef` in container to check if all the processes have started.


Environment Parameters
----------------------
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
In the Dockerfile I put the successfully built service packages tarslog.tgz, tarsnotify.tgz, tarsproperty.tgz, tarsqueryproperty.tgz, tarsquerystat.tgz and tarsstat.tgz to /data, which should be mounted from the host machine like `/c/Users/<ACCOUNT>/tars_data/`. These services have been automatically installed in the docker image. You can refer to [Install general basic service for framework](https://github.com/Tencent/Tars/blob/master/Install.en.md#44-install-general-basic-service-for-framework) to understand those services.


Build Images
-------------
Build command: `docker build -t tars .`

Build command for tars-master: `docker build -t tars-master -f tars-master/Dockerfile .`

Build command for tars-node: `docker build -t tars-node -f tars-node/Dockerfile .`

To build image of [tars-master](https://github.com/tangramor/tars-master) , you need to checkout tars-master and run docker build command:

```
git clone https://github.com/tangramor/tars-master.git
cd tars-master
docker build -t tars-master -f Dockerfile .
```


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
    
1. **C++ Server Side Development**

    Start docker container with following command. Here we can use image `tangramor/tars-master` or `tangramor/docker-tars`.
    
    ```
    docker run -d -it --name tars -p 8080:8080 -v /c/Users/tangramor/Workspace/tars_data:/data tangramor/tars-master
    ```
    
    This command starts `tangramor/tars-master` to container **tars** and mount local folder `/c/Users/tangramor/Workspace/tars_data` as /data folder in the container. It also exposes port 8080.
    
    We can see that there are 2 new folders, log and tars, created under `/c/Users/tangramor/Workspace/tars_data` in our host OS. Folder log is to store resin log and folder tars contains the log folders of Tars sub systems. In the mean time we can find tgz packages under `/c/Users/tangramor/Workspace/tars_data` which have already been installed in the container.
    
    Execute `docker exec -it tars bash` to enter container **tars**, `cd /data` to the work directory, and we can refer to [Service Development](https://github.com/Tencent/Tars/blob/master/docs/tars_cpp_quickstart.md#5-%E6%9C%8D%E5%8A%A1%E5%BC%80%E5%8F%91--) to develop TestApp.HelloServer. We need to modify method testHello to following:
    
    ```
    int HelloImp::testHello(const std::string &sReq, std::string &sRsp, tars::TarsCurrentPtr current)
    {
        TLOGDEBUG("HelloImp::testHellosReq:"<<sReq<<endl);
        sRsp = sReq + " World!";
        return 0;
    }
    
    ```
    
    Then we deploy the compiled HelloServer.tgz to our **tars** container.

2. **PHP Client of C++ Server Development**

    C++ client can be done by referring to [Sync/Async calling to Service from Client](https://github.com/Tencent/Tars/blob/master/docs/tars_cpp_quickstart.md#54-%E5%AE%A2%E6%88%B7%E7%AB%AF%E5%90%8C%E6%AD%A5%E5%BC%82%E6%AD%A5%E8%B0%83%E7%94%A8%E6%9C%8D%E5%8A%A1). Be aware that if you want to deploy C++ client to tars-node container, you should not mix `minideb` tag with `latest` and `php7` tags, because there will be dependency problem for different OSs.
    
    Here I will introduce how to develop PHP client and deploy it.
    
    Start a **php7** tag container, such as `tangramor/tars-node:php7`:
    
    ```
    docker run -d -it --name tars-node --link tars:tars -e MASTER=tars -p 80:80 -v /c/Users/tangramor/Workspace/tars_node:/data tangramor/tars-node:php7
    ```
    
    This command starts `tangramor/tars-node:php7` to container **tars-node** and mount local folder `/c/Users/tangramor/Workspace/tars_node` as /data folder in the container. It also exposes port 80.
    
    We can see that where are 3 new folders, log, tars and web, created under `/c/Users/tangramor/Workspace/tars_node`. Folder log and tars are used to store logs, folder web is linked as `/var/www/html` in the container. We can find file phpinfo.php under web folder, and if you visit http://127.0.0.1/phpinfo.php (in Linux or Mac) or http://192.168.99.100/phpinfo.php (in Windows), you can see the PHP information page.
    
    Find `Hello.tars` from `/c/Users/tangramor/Workspace/tars_data/TestApp/HelloServer` in host OS, and copy it to `/c/Users/tangramor/Workspace/tars_node/web`.
    
    Execute `docker exec -it tars-node bash` to enter container **tars-node**, `cd /data/web` to web folder, and create a file with name `tarsclient.proto.php`:

    ```
    <?php

      return array(
          'appName' => 'TestApp',
          'serverName' => 'HelloServer',
          'objName' => 'HelloObj',
          'withServant' => false,  //true to generate server side code, false for client side code
          'tarsFiles' => array(
              './Hello.tars'
          ),
          'dstPath' => './',
          'namespacePrefix' => '',
      );
    ```

    Then run `php /root/phptars/tars2php.php ./tarsclient.proto.php`, we can see that TestApp folder is created, and under `TestApp/HelloServer/HelloObj` we can find the generated client files.
    
    Create `composer.json` file under web folder:
    
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
          "phptars/tars-client" : "0.1.1"
        },
        "autoload": {
          "psr-4": {
            "TestApp\\": "TestApp/"
          }
        },
        "repositories": {
          "tars": {
            "type": "composer",
            "url": "https://raw.githubusercontent.com/Tencent/Tars/phptars/php/dist/tarsphp.json"
          }
        }
    }
    ```
    
    Execute `composer install`, we can see `vendor` folder is created. That means we can use autoload in PHP files to load phptars. Create a file named `index.php` under web folder:
    
    ```
    <?php
        require_once("./vendor/autoload.php");
    
        $config = new \Tars\client\CommunicatorConfig();
        $config->setLocator("tars.tarsregistry.QueryObj@tcp -h 172.17.0.3 -p 17890");
        $config->setModuleName("TestApp.HelloServer");
        $config->setCharsetName("UTF-8");
        $servant = new \TestApp\HelloServer\HelloObj\HelloServant($config);
    
        $start = microtime();
    
        try {    
            $in1 = "Hello";
    
            $intVal = $servant->testHello($in1,$out1);
    
            echo "Server returns: ".$out1;
    
        } catch(phptars\TarsException $e) {
            echo "Error: ".$e;
        }
    
        $end = microtime();
    
        echo "<p>Elapsed time: ".($end - $start)." seconds</p>";
    ```
    
    Use a browser in host OS to visit http://127.0.0.1/index.php (in Linux or Mac) or http://192.168.99.100/index.php (in Windows), you should see result like following:
    
    ```
    Server returns: Hello World!
    
    Elapsed time: 0.051169 seconds
    ```

3. **PHP Server Side Development**
    
    Here we need to use tag `php7mysql8` of image `tangramor/docker-tars` to develop PHP server. Here we assume that you are using Windows:
    
    ```
    docker run --name mysql8 -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/tangramor/mysql8_data:/var/lib/mysql mysql:8 --sql_mode="" --innodb_use_native_aio=0
    
    docker run -d -it --name tars_mysql8 --link mysql8 --env DBIP=mysql8 --env DBPort=3306 --env DBUser=root --env DBPassword=password -p 8080:8080 -p 80:80 -v /c/Users/tangramor/tars_mysql8_data:/data tangramor/docker-tars:php7mysql8
    ```
    
    The above 2 commands start 2 containers: a v8.0 mysql and `tangramor/docker-tars:php7mysql8` container with name **tars_mysql8**, and we mount the folder of host machine `/c/Users/tangramor/Workspace/tars_mysql8_data` as /data folder of container **tars_mysql8**. It also exposes port 8080 and 80.
    
    Enter `/c/Users/tangramor/Workspace/tars_mysql8_data/web` and create folders: `scripts`、`src` and `tars`:
    
    ![DevPHPTest1](https://raw.githubusercontent.com/tangramor/docker-tars/master/docs/images/DevPHPTest1.png)
    
    Run `docker exec -it tars_mysql8 bash` to enter container **tars_mysql8** and `cd /data/web`.
    
    Create file `test.tars` under `tars` folder ( Refer: [phptars example](https://github.com/Tencent/Tars/blob/phptars/php/examples/tars-tcp-server/tars/example.tars) ):
    
    ```
    module testtafserviceservant
    {
        struct SimpleStruct {
            0 require long id=0;
            1 require int count=0;
            2 require short page=0;
        };
    
        struct OutStruct {
            0 require long id=0;
            1 require int count=0;
            2 require short page=0;
            3 optional string str;
        };
    
        struct ComplicatedStruct {
            0 require vector<SimpleStruct> ss;
            1 require SimpleStruct rs;
            2 require map<string, SimpleStruct> mss;
            3 optional string str;
        }
    
        struct LotofTags {
            0 require long id=0;
            1 require int count=0;
            2 require short page=0;
            3 optional string str;
            4 require vector<SimpleStruct> ss;
            5 require SimpleStruct rs;
            6 require map<string, SimpleStruct> mss;
        }
    
        interface TestTafService
        {
    
            void testTafServer();
    
            int testLofofTags(LotofTags tags, out LotofTags outtags);
    
            void sayHelloWorld(string name, out string outGreetings);
    
            int testBasic(bool a, int b, string c, out bool d, out int e, out string f);
    
            string testStruct(long a, SimpleStruct b, out OutStruct d);
    
            string testMap(short a, SimpleStruct b, map<string, string> m1, out OutStruct d, out map<int, SimpleStruct> m2);
    
            string testVector(int a, vector<string> v1, vector<SimpleStruct> v2, out vector<int> v3, out vector<OutStruct> v4);
    
            SimpleStruct testReturn();
    
            map<string,string> testReturn2();
    
            vector<SimpleStruct> testComplicatedStruct(ComplicatedStruct cs,vector<ComplicatedStruct> vcs, out ComplicatedStruct ocs,out vector<ComplicatedStruct> ovcs);
    
            map<string,ComplicatedStruct> testComplicatedMap(map<string,ComplicatedStruct> mcs, out map<string,ComplicatedStruct> omcs);
    
            int testEmpty(short a,out bool b1, out int in2, out OutStruct d, out vector<OutStruct> v3,out vector<int> v4);
    
            int testSelf();
    
            int testProperty();
    
        };
    
    }
    ```
    
    Create file `tars.proto.php` under `tars`:
    
    ```
    <?php
    
      return array(
          'appName' => 'PHPTest',
          'serverName' => 'PHPServer',
          'objName' => 'obj',
          'withServant' => true, //true to generate server side code, false for client side code
          'tarsFiles' => array(
              './test.tars'
          ),
          'dstPath' => '../src/servant',
          'namespacePrefix' => 'Server\servant',
      );
    ```
    
    Create `tars2php.sh` under `scripts` and give execution permission `chmod u+x tars2php.sh`:
    ```
    cd ../tars/
    
    php /root/phptars/tars2php.php ./tars.proto.php
    ```
    
    Create folder `src/servant`, then run `./scripts/tars2php.sh`, you will see there are 3 layers folders generated under `src/servant`: `PHPTest/PHPServer/obj`, it includes:
    
    * classes folder - To store the generated tars structs
    * tars folder - To store the original tars file
    * TestTafServiceServant.php - interface
    
    ![DevPHPTest2](https://raw.githubusercontent.com/tangramor/docker-tars/master/docs/images/DevPHPTest2.png)
    
    Enter `src` folder, we begin to implemente the server side logic. Because we are using the official example, here we copy the source code directly from example project:
    
    ```
    wget https://github.com/Tencent/Tars/raw/phptars/php/examples/tars-tcp-server/src/composer.json
    wget https://github.com/Tencent/Tars/raw/phptars/php/examples/tars-tcp-server/src/index.php
    wget https://github.com/Tencent/Tars/raw/phptars/php/examples/tars-tcp-server/src/services.php
    mkdir impl && cd impl && wget https://github.com/Tencent/Tars/raw/phptars/php/examples/tars-tcp-server/src/impl/PHPServerServantImpl.php && cd ..
    mkdir conf && cd conf && wget https://github.com/Tencent/Tars/raw/phptars/php/examples/tars-tcp-server/src/conf/ENVConf.php && cd ..
    ```
    
    - conf: configurations for implementation, here we just give a demo. If you push config from Tars platform, the file will be written into this folder.
    - impl: implementation code for interface. And the address of the implementation will be written in servcies.php.
    - composer.json: dependencies of the project.
    - index.php: entrance file of the service. You can use another name, and you need to change the deployment template on Tars platform, by adding `entrance` field under `server`.
    - services.php: diclare the addresses of interface and implementation, and they will be used for instantiate and annotation parsing.
    
    Change the configuration in `conf/ENVConf.php` . And execute `composer install` under `src` to load required dependencies, then run `composer run-script deploy` to build the package, and a package name like `PHPServer_20180523105340.tar.gz` will be generated.
    
    ![DevPHPTest3](https://raw.githubusercontent.com/tangramor/docker-tars/master/docs/images/DevPHPTest3.png)
    
    Create a `logs` folder under `/data`, because this example will write file under it.
    
    Deploy the generated package to Tars platform. Remember to use tars-php type and use `tars.tarsphp.default` template (or create a template by yourself):
    
    ![DeployPHPTest1](https://raw.githubusercontent.com/tangramor/docker-tars/master/docs/images/DeployPHPTest1.png)
    
    ![DeployPHPTest2](https://raw.githubusercontent.com/tangramor/docker-tars/master/docs/images/DeployPHPTest2.png)
    
    Once the deployment is successfully completed, you will see related processes when run `ps -ef`.
    
    ![DeployPHPTest3](https://raw.githubusercontent.com/tangramor/docker-tars/master/docs/images/DeployPHPTest3.png)

4. **PHP Client Side Development**

    We will develop the client side code in the same container.
    
    Enter `/c/Users/tangramor/Workspace/tars_mysql8_data/web` and create `client` folder under it.
    
    Run `docker exec -it tars_mysql8 bash` to enter container **tars_mysql8**, and `cd /data/web/client`.
    
    Copy the `test.tars` file created in 3. **PHP Server Side Development** to current folder, and create file `tarsclient.proto.php`:
    
    ```
    <?php
    
      return array(
          'appName' => 'PHPTest',
          'serverName' => 'PHPServer',
          'objName' => 'obj',
          'withServant' => false, //true to generate server side code, false for client side code
          'tarsFiles' => array(
              './test.tars'
          ),
          'dstPath' => './',
          'namespacePrefix' => 'Client\servant',
      );
    ```
    
    Run `php /root/phptars/tars2php.php ./tarsclient.proto.php`, and you will see there are 3 layers folders generated: `PHPTest/PHPServer/obj`, it includes:
    
    * classes folder - To store the generated tars structs
    * tars folder - To store the original tars file
    * TestTafServiceServant.php - client class TestTafServiceServant
    
    Create file `composer.json`:
    
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
        "phptars/tars-client" : "0.1.1"
      },
      "autoload": {
        "psr-4": {
          "Client\\servant\\": "./"
        }
      },
      "repositories": {
        "tars": {
          "type": "composer",
          "url": "https://raw.githubusercontent.com/Tencent/Tars/phptars/php/dist/tarsphp.json"
        }
      }
    }
    
    ```
    
    And create `index.php` file:
    ```
    <?php
      require_once("./vendor/autoload.php");
    
      // ip、port
      $config = new \Tars\client\CommunicatorConfig();
      $config->setLocator('tars.tarsregistry.QueryObj@tcp -h 172.17.0.3 -p 17890');
      $config->setModuleName('PHPTest.PHPServer');
      $config->setCharsetName('UTF-8');
    
      $servant = new Client\servant\PHPTest\PHPServer\obj\TestTafServiceServant($config);
    
      $name = 'ted';
      $intVal = $servant->sayHelloWorld($name, $greetings);
    
      echo '<p>'.$greetings.'</p>';
    ```
    
    Run `composer install` to load required dependencies, then execute `php index.php` to test our client. If everything good, it should output: `<p>hello world!</p>`. We use a web browser to visit http://192.168.99.100/client/index.php and should see page:
    
    ![DevPHPTest4](https://raw.githubusercontent.com/tangramor/docker-tars/master/docs/images/DevPHPTest4.png)
        
    Check  `ted.log` under `/data/logs`, there should be content written: `sayHelloWorld name:ted`.


Trouble Shooting
----------------
Once you started up the container, you can enter it by command `docker exec -it tars bash` and then you can execute linux commands to check the status. If you see _log4j.log file under `/c/Users/<ACCOUNT>/tars_data/log/tars`, that means resin is up to work and the installation is done.



Thanks
---------------

The scripts of this image are based on project https://github.com/panjen/docker-tars, which is from https://github.com/luocheng812/docker_tars.
