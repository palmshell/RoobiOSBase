#!/bin/bash

cd /usr/Roobi

if [ -d "new" ];then
    echo "Roobi update"

    if [ -d "backup" ];then
        rm -rf backup
    fi
    mv now backup
    mv new now
    /bin/bash now/install.sh
fi


cd now

chmod +x run
./run