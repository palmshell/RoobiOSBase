cmd_/usr/factory/progress/script/linuxpg/pgdrv.mod := printf '%s\n'   pgdrv.o | awk '!x[$$0]++ { print("/usr/factory/progress/script/linuxpg/"$$0) }' > /usr/factory/progress/script/linuxpg/pgdrv.mod
