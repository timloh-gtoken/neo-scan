#!/bin/bash

export DOCKER_HOST_IP=`netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}'`

/opt/app/bin/neoscan migrate
/opt/app/bin/neoscan foreground
