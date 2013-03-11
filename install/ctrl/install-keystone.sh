#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Begin Install Keystone!"

myT3 "Install Dep Pkgs"
sudo apt-get install python-dev libldap2-dev libsasl2-dev libssl-dev build-essential python-dev python-setuptools python-pip python-ldap curl libxml2-dev libxslt-dev mysql-client python-mysqldb python-mysqldb python-psycopg2 -y

myT3 "Install Keystone"
gitCloneModule keystone install

myT3 "Install Keystone Client"
gitCloneModule python-keystoneclient install
#gitCloneModule python-novaclient install
#gitCloneModule python-cinderclient install
#gitCloneModule python-glanceclient install
#gitCloneModule python-quantumclient install

myT3 "Config Keystone"
KEYSTONE_ETC_DIR=/etc/keystone
KEYSTONE_ETC_FILE_NAME=keystone.conf
KEYSTONE_ETC_FILE=${KEYSTONE_ETC_DIR}/${KEYSTONE_ETC_FILE_NAME}
KEYSTONE_LOG_DIR=/var/log/openstack/keystone
KEYSTONE_LOG_FILE_NAME=keystone.log
KEYSTONE_LOG_FILE=${KEYSTONE_LOG_DIR}/${KEYSTONE_LOG_FILE_NAME}
sudo mkdir -p ${KEYSTONE_ETC_DIR}
sudo cp ${REMOTE_SRC_DIR}/keystone/etc/* ${KEYSTONE_ETC_DIR}/
sudo cp ${REMOTE_SRC_DIR}/keystone/etc/logging.conf.sample ${REMOTE_SRC_DIR}/keystone/etc/logging.conf
sudo mkdir -p ${KEYSTONE_LOG_DIR}
sudo touch ${KEYSTONE_LOG_FILE}
sudo cp ${KEYSTONE_ETC_DIR}/keystone.conf.sample ${KEYSTONE_ETC_FILE}

sudo chmod a+w ${KEYSTONE_ETC_DIR}
sudo chmod a+w ${KEYSTONE_ETC_FILE}
iniset ${KEYSTONE_ETC_FILE} DEFAULT admin_token ${REMOTE_ADMIN_TOKEN}
iniset ${KEYSTONE_ETC_FILE} DEFAULT admin_port 35357
iniset ${KEYSTONE_ETC_FILE} DEFAULT bind_host 0.0.0.0
iniset ${KEYSTONE_ETC_FILE} DEFAULT compute_port 8774
iniset ${KEYSTONE_ETC_FILE} DEFAULT debug False
iniset ${KEYSTONE_ETC_FILE} DEFAULT policy_file policy.json
iniset ${KEYSTONE_ETC_FILE} DEFAULT public_port 5000
iniset ${KEYSTONE_ETC_FILE} DEFAULT use_syslog True
iniset ${KEYSTONE_ETC_FILE} DEFAULT verbose True
iniset ${KEYSTONE_ETC_FILE} DEFAULT log_dir ${KEYSTONE_LOG_DIR}
iniset ${KEYSTONE_ETC_FILE} DEFAULT log_file ${KEYSTONE_LOG_FILE_NAME}
iniset ${KEYSTONE_ETC_FILE} sql connection "$(getSqlConn ${REMOTE_DATABASE_USER} ${REMOTE_DATABASE_PASSWORD} ${DB_IP} keystone ${DB_PORT})"
iniset ${KEYSTONE_ETC_FILE} identity driver keystone.identity.backends.sql.Identity
#iniset ${KEYSTONE_ETC_FILE} token driver keystone.token.backends.sql.Token
iniset ${KEYSTONE_ETC_FILE} catalog driver keystone.catalog.backends.sql.Catalog
iniset ${KEYSTONE_ETC_FILE} signing token_format UUID
sudo chmod 644 ${KEYSTONE_ETC_FILE}
sudo chmod 755 ${KEYSTONE_ETC_FILE}

grep -v "^#" ${KEYSTONE_ETC_FILE} | grep -v "^$"

myT3 "Config SSL"
sudo mkdir -p ${KEYSTONE_ETC_DIR}/ssl
sudo cp -r ${REMOTE_SRC_DIR}/keystone/examples/pki/* ${KEYSTONE_ETC_DIR}/ssl/
cd ${KEYSTONE_ETC_DIR}/ssl
sudo ./gen_pki.sh
find .

myT3 "DB Sync"
sudo keystone-manage db_sync

myT2 "End Install Keystone!"
