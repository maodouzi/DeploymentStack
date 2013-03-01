#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Begin Install Glance!"

myT3 "Install Dep Pkgs"
sudo apt-get install libxml2 libxml2-dev libxslt1-dev build-essential git python-dev python-setuptools python-pip python-mysqldb python-psycopg2 -y

myT3 "Install Glance"
gitCloneModule glance install

myT3 "Install Glance Client"
gitCloneModule python-glanceclient install

myT3 "Config Glance"
GLANCE_ETC_DIR=/etc/glance
GLANCE_ETC_API_NAME=glance-api.conf
GLANCE_ETC_REG_NAME=glance-registry.conf
GLANCE_INI_API_NAME=glance-api-paste.ini
GLANCE_INI_REG_NAME=glance-registry-paste.ini
GLANCE_ETC_API=${GLANCE_ETC_DIR}/${GLANCE_ETC_API_NAME}
GLANCE_ETC_REG=${GLANCE_ETC_DIR}/${GLANCE_ETC_REG_NAME}
GLANCE_INI_API=${GLANCE_ETC_DIR}/${GLANCE_INI_API_NAME}
GLANCE_INI_REG=${GLANCE_ETC_DIR}/${GLANCE_INI_REG_NAME}
GLANCE_LOG_DIR=/var/log/glance
GLANCE_LOG_FILE_NAME=glance.log
GLANCE_LOG_FILE=${GLANCE_LOG_DIR}/${GLANCE_LOG_FILE_NAME}
sudo mkdir -p ${GLANCE_ETC_DIR}
sudo cp ${REMOTE_SRC_DIR}/glance/etc/* ${GLANCE_ETC_DIR}/
sudo mkdir -p ${GLANCE_LOG_DIR}
sudo touch ${GLANCE_LOG_FILE}
sudo chmod a+w ${GLANCE_ETC_DIR} ${GLANCE_ETC_API} ${GLANCE_ETC_REG} ${GLANCE_INI_API} ${GLANCE_INI_REG}
iniset ${GLANCE_ETC_API} paste_deploy flavor keystone
iniset ${GLANCE_ETC_API} keystone_authtoken admin_tenant_name admin
iniset ${GLANCE_ETC_API} keystone_authtoken auth_host ${KEYSTONE_IP}
iniset ${GLANCE_ETC_API} keystone_authtoken admin_user admin
iniset ${GLANCE_ETC_API} keystone_authtoken admin_password ${REMOTE_PASSWD}
iniset ${GLANCE_ETC_API} DEFAULT sql_connection $(getSqlConn ${REMOTE_DATABASE_USER} ${REMOTE_DATABASE_PASSWORD} ${DB_IP} glance ${DB_PORT})

iniset ${GLANCE_ETC_REG} paste_deploy flavor keystone
iniset ${GLANCE_ETC_REG} DEFAULT sql_connection $(getSqlConn ${REMOTE_DATABASE_USER} ${REMOTE_DATABASE_PASSWORD} ${DB_IP} glance ${DB_PORT})
iniset ${GLANCE_ETC_REG} keystone_authtoken auth_host ${KEYSTONE_IP}
iniset ${GLANCE_ETC_REG} keystone_authtoken admin_tenant_name admin
iniset ${GLANCE_ETC_REG} keystone_authtoken admin_user admin
iniset ${GLANCE_ETC_REG} keystone_authtoken admin_password ${REMOTE_PASSWD}

iniset ${GLANCE_INI_API} filter:authtoken paste.filter_factory keystone.middleware.auth_token:filter_factory
iniset ${GLANCE_INI_API} filter:authtoken service_protocol http
iniset ${GLANCE_INI_API} filter:authtoken service_host localhost
iniset ${GLANCE_INI_API} filter:authtoken service_port 5000
iniset ${GLANCE_INI_API} filter:authtoken auth_host ${KEYSTONE_IP}
iniset ${GLANCE_INI_API} filter:authtoken auth_port 35357
iniset ${GLANCE_INI_API} filter:authtoken auth_protocol http
iniset ${GLANCE_INI_API} filter:authtoken auth_uri http://${KEYSTONE_IP}:5000/
iniset ${GLANCE_INI_API} filter:authtoken admin_tenant_name admin
iniset ${GLANCE_INI_API} filter:authtoken admin_user admin
iniset ${GLANCE_INI_API} filter:authtoken admin_password ${REMOTE_PASSWD}
iniset ${GLANCE_INI_API} filter:authtoken admin_token ${REMOTE_ADMIN_TOKEN}

iniset ${GLANCE_INI_REG} filter:authtoken paste.filter_factory keystone.middleware.auth_token:filter_factory
iniset ${GLANCE_INI_REG} filter:authtoken service_protocol http
iniset ${GLANCE_INI_REG} filter:authtoken service_host localhost
iniset ${GLANCE_INI_REG} filter:authtoken service_port 5000
iniset ${GLANCE_INI_REG} filter:authtoken auth_host ${KEYSTONE_IP}
iniset ${GLANCE_INI_REG} filter:authtoken auth_port 35357
iniset ${GLANCE_INI_REG} filter:authtoken auth_protocol http
iniset ${GLANCE_INI_REG} filter:authtoken auth_uri http://${KEYSTONE_IP}:5000/
iniset ${GLANCE_INI_REG} filter:authtoken admin_tenant_name admin
iniset ${GLANCE_INI_REG} filter:authtoken admin_user admin
iniset ${GLANCE_INI_REG} filter:authtoken admin_password ${REMOTE_PASSWD}
iniset ${GLANCE_INI_REG} filter:authtoken admin_token ${REMOTE_ADMIN_TOKEN}

sudo chmod 644 ${GLANCE_ETC_API} ${GLANCE_ETC_REG} ${GLANCE_INI_API} ${GLANCE_INI_REG}
sudo chmod 755 ${GLANCE_ETC_DIR}

for x in ${GLANCE_ETC_API} ${GLANCE_ETC_REG} ${GLANCE_INI_API} ${GLANCE_INI_REG};do
	echo $x
	grep -v "^#" $x | grep -v "^$"
	echo ""
done

myT3 "DB Sync"
sudo glance-manage db_sync

myT3 "Down Image"
if [ ! -f ~/images/ttylinux-uec-${ARCH_TYPE}-12.1_2.6.35-22_1.tar.gz ];then
	mkdir -p ~/images
	cd ~/images && wget http://smoser.brickies.net/ubuntu/ttylinux-uec/ttylinux-uec-${ARCH_TYPE}-12.1_2.6.35-22_1.tar.gz
	tar zxvf ttylinux-uec-${ARCH_TYPE}-12.1_2.6.35-22_1.tar.gz
fi

myT2 "End Install Glance!"
