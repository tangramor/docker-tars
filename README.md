本镜像脚本根据 https://github.com/panjen/docker-tars 修改。

本镜像是Tars的docker版本，未安装mysql，可以使用官方mysql镜像（5.6）：
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d -p 3306:3306 -v /c/Users/<ACCOUNT>/mysql_data:/var/lib/mysql mysql:5.6 --innodb_use_native_aio=0

注意上面的运行命令添加了 --innodb_use_native_aio=0 ，因为mysql的aio对windows文件系统不支持

如果要使用5.7以后版本的mysql，需要再添加 --sql_mode="NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION" 参数，因为不支持全零的date字段值（ https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_zero_date ）

或者你也可以挂载使用一个自定义的 my.cnf 来添加上述参数。


镜像构建命令：docker build -t tars .


在运行容器时需要指定数据库的环境变量，例如：

DBIP mysql

DBPort 3306

DBUser root

DBPassword password

run_docker_tars.sh 里的命令如下，请自己修改：

docker run -d -it --name tars --link mysql --env DBIP=mysql --env DBPort=3306 --env DBUser=root --env DBPassword=PASS -p 8080:8080 -v /c/Users/<ACCOUNT>/tars_data:/data tars

