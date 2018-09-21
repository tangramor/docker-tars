#!/bin/bash
docker run -d -it --name tars --link mysql8 --env DBIP=mysql8 --env DBPort=3306 --env DBUser=root --env DBPassword=PASS -p 3000:3000 -v /c/Users/<ACCOUNT>/tars_data:/data tarscloud/tars:php7mysql8
