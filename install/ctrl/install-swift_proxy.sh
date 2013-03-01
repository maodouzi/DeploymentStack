#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Begin Install Swift-Proxy!"

myT3 "Install Dep Pkgs"
sudo apt-get install python-dev libldap2-dev libsasl2-dev libssl-dev build-essential git python-dev python-setuptools python-pip libxml2-dev libxslt-dev openssl memcached xfsprogs -y

myT3 "Install Swift"
gitCloneModule keystone install
gitCloneModule swift install
gitCloneModule python-swiftclient install

myT3 "Config Swift"
sudo mkdir -p /etc/swift
sudo chmod 777 /etc/swift/
sudo touch /etc/swift/swift.conf
sudo chmod a+w /etc/swift/swift.conf
sudo echo "
[swift-hash]
swift_hash_path_suffix = ${SWIFT_HASH}
" > /etc/swift/swift.conf
sudo chmod 644 /etc/swift/swift.conf
sudo mkdir -p /var/cache/swift
sudo chown -R ${REMOTE_USER}:${REMOTE_USER} /var/cache/swift
sudo chmod 755 /etc/swift/

myT3 "Config Swift-Proxy"
cat << CONF_SWIFT_PROXY > /tmp/proxy-server.conf
[DEFAULT]
bind_ip = 0.0.0.0
bind_port = 8080
swift_dir = /etc/swift
workers = 1
user = ${REMOTE_USER}
log_level = DEBUG
[pipeline:main]
pipeline = catch_errors healthcheck cache ratelimit  authtoken keystoneauth proxy-logging proxy-server
[app:proxy-server]
account_autocreate = true
use = egg:swift#proxy
[filter:tempauth]
use = egg:swift#tempauth
user_admin_admin = admin .admin .reseller_admin
user_test_tester = testing .admin
user_test2_tester2 = testing2 .admin
user_test_tester3 = testing3
[filter:authtoken]
signing_dir = /var/cache/swift
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
auth_host = ${KEYSTONE_IP}
auth_port = 35357
auth_protocol = http
auth_uri = http://${KEYSTONE_IP}:5000/
admin_tenant_name = admin
admin_user = admin
admin_password = ${REMOTE_PASSWD}
delay_auth_decision = 1
[filter:keystoneauth]
use = egg:swift#keystoneauth
operator_roles = Member, admin
[filter:healthcheck]
use = egg:swift#healthcheck
[filter:cache]
use = egg:swift#memcache
[filter:ratelimit]
use = egg:swift#ratelimit
[filter:domain_remap]
use = egg:swift#domain_remap
[filter:catch_errors]
use = egg:swift#catch_errors
[filter:cname_lookup]
use = egg:swift#cname_lookup
[filter:staticweb]
use = egg:swift#staticweb
[filter:tempurl]
use = egg:swift#tempurl
[filter:formpost]
use = egg:swift#formpost
[filter:name_check]
use = egg:swift#name_check
[filter:proxy-logging]
use = egg:swift#proxy_logging
[filter:bulk]
use = egg:swift#bulk
[filter:container-quotas]
use = egg:swift#container_quotas
CONF_SWIFT_PROXY

sudo cp /tmp/proxy-server.conf /etc/swift/proxy-server.conf

myT3 "Config Memcached"
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/memcached.conf
sudo service memcached restart

myT3 "Ring Builder"
cd /etc/swift
sudo rm -rf *.builder *.ring.gz
sudo swift-ring-builder account.builder create 18 ${SWIFT_NODE_NUM} 1
sudo swift-ring-builder container.builder create 18 ${SWIFT_NODE_NUM} 1
sudo swift-ring-builder object.builder create 18 ${SWIFT_NODE_NUM} 1
            
idx=0
for nodeIp in ${SWIFT_NODE_LIST};do
    idx=$(expr $idx + 1)
    sudo swift-ring-builder account.builder add z${idx}-${nodeIp}:6012/${SWIFT_VD} 100
    sudo swift-ring-builder container.builder add z${idx}-${nodeIp}:6011/${SWIFT_VD} 100
    sudo swift-ring-builder object.builder add z${idx}-${nodeIp}:6010/${SWIFT_VD} 100
done

swift-ring-builder account.builder
swift-ring-builder container.builder
swift-ring-builder object.builder
            
sudo swift-ring-builder account.builder rebalance
sudo swift-ring-builder container.builder rebalance
sudo swift-ring-builder object.builder rebalance

myT2 "End Install Swift-Proxy!"
