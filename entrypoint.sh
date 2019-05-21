#!/bin/bash

source /etc/profile
source ~/.bashrc

if [ "${ServerName}" == "init_db" ]
then
	echo "init db";
	/bin/bash /root/init/init_db.sh
else
	echo "init server";
	/bin/bash /root/init/init_server.sh
	tail -f /dev/null
fi

