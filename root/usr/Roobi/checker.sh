#!/bin/bash

function check_item() {
    time=$1
    sleep $time
    if [ "`systemctl is-active roobi`" != "active" ];then
        return 1
    fi
    if [ "`curl -sL http://127.0.0.1/ping`" == "pong" ];then
        exit 0
    fi
    if [ "`curl -sL http://127.0.0.1:739/ping`" == "pong" ];then
        exit 0
    fi
    return 0
}

function check() {
    time_list=(0 1 0.5 0.5 1 2 3 10 10 10 10 10 10 10 10)
    for _time in ${time_list[@]}; do
        echo "checker $_time"
        check_item $_time
        if [ $? -eq 1 ]; then
            return 1
        fi
    done
}

check

cd /usr/Roobi

if [ -d "backup" ];then
    echo "test failed change to backup"
    systemctl kill roobi
    rm -rf now
    mv backup now
    /bin/bash now/install.sh
    systemctl start roobi
    check
fi

if [ -d "original" ];then
    echo "test failed change to original"
    systemctl kill roobi
    rm -rf now
    cp -r original now
    /bin/bash now/install.sh
    systemctl start roobi
    check
fi


echo "Roobi running failed !!!!!!!!"
exit 1
