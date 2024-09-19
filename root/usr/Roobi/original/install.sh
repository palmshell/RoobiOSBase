#!/bin/bash

set -e

current_script_path=$(dirname "$0")

cp /usr/Roobi/now/main.js /usr/Roobi/
cp /usr/Roobi/now/blank.html /usr/Roobi/
cp /usr/Roobi/now/xdotool /usr/Roobi/
cp /usr/Roobi/now/preload.js /usr/Roobi/

chmod 777 /usr/Roobi/xdotool

