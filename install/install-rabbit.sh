#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT2 "Begin Install Rabbit!"

myT3 "Install Rabbit"
sudo apt-get install rabbitmq-server -y

myT3 "Restart Rabbit"
sudo service rabbitmq-server restart
sleep 3

myT3 "Config Rabbit"
sudo rabbitmqctl add_user ${REMOTE_USER} ${REMOTE_PASSWD}
sudo rabbitmqctl set_permissions -p / ${REMOTE_USER} ".*" ".*" ".*"

myT2 "End Install Rabbit!"
