#!/bin/bash

set -e


get_option() {
  while getopts "o:b:f:s:" flag; do
    case $flag in
      o)
        output="$OPTARG"
        ;;
      b)
        base="$OPTARG"
        ;;
      f)
        file="$OPTARG"
        ;;
      s)
        script="$OPTARG"
        ;;
    esac
  done
}

start(){
    echo "copy base"
    cp $base $output
    echo "mount device"
    loopdevice=$(losetup -f --show $output)
    mapdevice="/dev/mapper/$(kpartx -va $loopdevice | sed -E 's/.*(loop[0-9]+)p.*/\1/g' | head -1)"
    mount ${mapdevice}p2 /mnt

    echo copy file 
    cp $file /mnt/flash.img

    if [ "$script" != "" ]; then
      cp $script /mnt/usr/bin/flasher.sh
    fi


    umount /mnt

    kpartx -d "$output"


}

get_option $@
start