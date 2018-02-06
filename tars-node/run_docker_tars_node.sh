#!/bin/bash
docker run -d -it --name tars-node --link mysql --env DBIP=mysql --env DBPort=3306 --env DBUser=root --env DBPassword=PASS -p 8080:8080 -v /c/Users/<ACCOUNT>/tars_node_data:/data tangramor/tars-node
