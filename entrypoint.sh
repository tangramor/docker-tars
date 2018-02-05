
#!/bin/bash

if [ -d /root/init ];then

        for x in $(ls /root/init)
        do
                if [ -f /root/init/$x ];then
                        chmod u+x /root/init/$x
                        /bin/bash /root/init/$x
                        rm -rf /root/init/$x
                fi
        done
fi


case ${1} in
        init)
                ;;
        start)

                #时间戳
            # cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone

                 source /etc/profile
            #    /usr/local/app/tars/tars_install.sh
            #    /usr/local/app/tars/tarspatch/util/init.sh
                exec /usr/local/resin/bin/resin.sh console
                ;;
        *)
                exec "$@"
                ;;
esac

