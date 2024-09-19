#!/bin/sh

MODEL="Intel(R) N100"

echo "########################### Flasher Running ###########################"

restart (){
    echo "Press [Enter] to restart."
    read n
    reboot
    echo "rebooting...."
    exit 0         
}


failed (){
    echo "########################### Flasher failed ###########################"
    restart
}

success (){
    echo "########################### Flasher success ###########################"
    restart
}

check_emmc(){
    dd if=/dev/mmcblk0 of=/tmp/tmp.out bs=100 count=1 2> /dev/null
    if [ "$?" != "0" ] ||  [ `ls -al /tmp/tmp.out | awk '{print $5}'` !=  "100" ]; then
        echo "eMMC is not activated or dose not exist."
        failed
    fi

}

model=`cat /proc/cpuinfo | grep "model name" | awk 'END {print}' | awk -F ':' '{print $2}' | awk '{$1=$1;print}'`

if [ "$MODEL" != "$model" ]; then
    echo "Inappropriate device, please check your device or flasher!"
    failed
fi

check_emmc

echo "wait 5 ...."
sleep 1
echo "wait 4 ...."
sleep 1
echo "wait 3 ...."
sleep 1
echo "wait 2 ...."
sleep 1
echo "wait 1 ...."
sleep 1

echo "Flashing ...."
dd if=/flash.img of=/dev/mmcblk0 bs=4M

if [ "$?" -eq 0 ];then
    success
else
    failed
fi
