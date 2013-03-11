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
GLANCE_ETC_SCRUBBER_NAME=glance-scrubber.conf
GLANCE_ETC_CACHE_NAME=glance-cache.conf
GLANCE_ETC_API=${GLANCE_ETC_DIR}/${GLANCE_ETC_API_NAME}
GLANCE_ETC_REG=${GLANCE_ETC_DIR}/${GLANCE_ETC_REG_NAME}
GLANCE_ETC_SCRUBBER=${GLANCE_ETC_DIR}/${GLANCE_ETC_SCRUBBER_NAME}
GLANCE_ETC_CACHE=${GLANCE_ETC_DIR}/${GLANCE_ETC_CACHE_NAME}
GLANCE_LOG_DIR=/var/log/glance
GLANCE_LOG_FILE_NAME=glance.log
GLANCE_LOG_FILE=${GLANCE_LOG_DIR}/${GLANCE_LOG_FILE_NAME}
GLANCE_IMAGE_DIR=/opt/openstack/glance/images
GLANCE_SCRUBBER_DIR=/opt/openstack/glance/scrubber
GLANCE_CACHE_DIR=/opt/openstack/glance/cache
sudo mkdir -p ${GLANCE_IMAGE_DIR}
sudo mkdir -p ${GLANCE_SCRUBBER_DIR}
sudo mkdir -p ${GLANCE_CACHE_DIR}

sudo mkdir -p ${GLANCE_ETC_DIR}
sudo cp ${REMOTE_SRC_DIR}/glance/etc/* ${GLANCE_ETC_DIR}/
sudo mkdir -p ${GLANCE_LOG_DIR}
sudo touch ${GLANCE_LOG_FILE}

sudo chmod a+w ${GLANCE_ETC_DIR} ${GLANCE_ETC_API} ${GLANCE_ETC_REG} ${GLANCE_ETC_SCRUBBER} ${GLANCE_ETC_CACHE}
iniset ${GLANCE_ETC_API} keystone_authtoken admin_tenant_name admin
iniset ${GLANCE_ETC_API} keystone_authtoken auth_host ${KEYSTONE_IP}
iniset ${GLANCE_ETC_API} keystone_authtoken admin_user admin
iniset ${GLANCE_ETC_API} keystone_authtoken admin_password ${REMOTE_PASSWD}
iniset ${GLANCE_ETC_API} DEFAULT sql_connection $(getSqlConn ${REMOTE_DATABASE_USER} ${REMOTE_DATABASE_PASSWORD} ${DB_IP} glance ${DB_PORT})
iniset ${GLANCE_ETC_API} DEFAULT workers 6
iniset ${GLANCE_ETC_API} DEFAULT use_syslog True
iniset ${GLANCE_ETC_API} DEFAULT registry_client_timeout 600
iniset ${GLANCE_ETC_API} DEFAULT notifier_strategy rabbit
iniset ${GLANCE_ETC_API} DEFAULT rabbit_host ${RABBITMQ_IP}
iniset ${GLANCE_ETC_API} DEFAULT rabbit_userid ${REMOTE_RABBITMQ_USER} 
iniset ${GLANCE_ETC_API} DEFAULT rabbit_password ${REMOTE_RABBITMQ_PASSWD}
iniset ${GLANCE_ETC_API} DEFAULT rabbit_vhost /openstack/glance
iniset ${GLANCE_ETC_API} DEFAULT filesystem_store_datadir ${GLANCE_IMAGE_DIR}
iniset ${GLANCE_ETC_API} DEFAULT scrubber_datadir ${GLANCE_SCRUBBER_DIR} 
iniset ${GLANCE_ETC_API} DEFAULT image_cache_dir ${GLANCE_CACHE_DIR}
sed -i "/qpid/d" ${GLANCE_ETC_API}

iniset ${GLANCE_ETC_REG} DEFAULT sql_connection $(getSqlConn ${REMOTE_DATABASE_USER} ${REMOTE_DATABASE_PASSWORD} ${DB_IP} glance ${DB_PORT})
iniset ${GLANCE_ETC_REG} DEFAULT use_syslog True
iniset ${GLANCE_ETC_REG} keystone_authtoken auth_host ${KEYSTONE_IP}
iniset ${GLANCE_ETC_REG} keystone_authtoken admin_tenant_name admin
iniset ${GLANCE_ETC_REG} keystone_authtoken admin_user admin
iniset ${GLANCE_ETC_REG} keystone_authtoken admin_password ${REMOTE_PASSWD}

iniset ${GLANCE_ETC_SCRUBBER} DEFAULT scrubber_datadir ${GLANCE_SCRUBBER_DIR}
iniset ${GLANCE_ETC_SCRUBBER} DEFAULT filesystem_store_datadir ${GLANCE_IMAGE_DIR}

iniset ${GLANCE_ETC_CACHE} DEFAULT filesystem_store_datadir ${GLANCE_IMAGE_DIR}
iniset ${GLANCE_ETC_CACHE} DEFAULT auth_url http://${KEYSTONE_IP}:5000/v2.0/
iniset ${GLANCE_ETC_CACHE} DEFAULT admin_tenant_name admin
iniset ${GLANCE_ETC_CACHE} DEFAULT admin_user admin
iniset ${GLANCE_ETC_CACHE} DEFAULT admin_password ${REMOTE_PASSWD}

sudo chmod 644 ${GLANCE_ETC_API} ${GLANCE_ETC_REG} ${GLANCE_ETC_SCRUBBER} ${GLANCE_ETC_CACHE}
sudo chmod 755 ${GLANCE_ETC_DIR}

for x in ${GLANCE_ETC_API} ${GLANCE_ETC_REG} ${GLANCE_ETC_SCRUBBER} ${GLANCE_ETC_CACHE};do
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
