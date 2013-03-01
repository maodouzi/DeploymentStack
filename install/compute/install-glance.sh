#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Begin Install Glance!"

myT3 "Install Dep Pkgs"
sudo apt-get install libxml2 libxml2-dev libxslt1-dev build-essential git python-dev python-setuptools python-pip python-mysqldb python-psycopg2 -y

myT3 "Install Glance Client"
gitCloneModule python-glanceclient install

myT2 "End Install Glance!"
