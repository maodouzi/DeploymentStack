#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Begin Install Keystone!"

myT3 "Install Dep Pkgs"
sudo apt-get install python-dev libldap2-dev libsasl2-dev libssl-dev build-essential python-dev python-setuptools python-pip python-ldap curl libxml2-dev libxslt-dev mysql-client python-mysqldb python-mysqldb python-psycopg2 -y

myT3 "Install Keystone Client"
gitCloneModule python-keystoneclient install

myT2 "End Install Keystone!"
