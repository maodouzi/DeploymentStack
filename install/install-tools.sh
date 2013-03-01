#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT2 "Begin Install Tools!"

myT3 "Create ssh key"
if [ ! -f ~/.ssh/id_dsa.pub ];then
    ssh-keygen -t dsa
fi

myT3 "Config DNS"
sudo chmod 777 /etc/resolvconf/resolv.conf.d
sudo chmod o+w /etc/resolvconf/resolv.conf.d/head
sed -i "/${NEVER_MATCH}/d" /etc/resolvconf/resolv.conf.d/head
echo "nameserver ${DNS_IP} #${NEVER_MATCH}" >>  /etc/resolvconf/resolv.conf.d/head 
sudo chmod o-w /etc/resolvconf/resolv.conf.d/head
sudo chmod 755 /etc/resolvconf/resolv.conf.d
confDNS

myT3 "Config Hosts"
confHosts

myT3 "Init OpenStack Environment"
initOsEnv

myT3 "Update Source"
sudo cp /etc/apt/sources.list /etc/apt/sources.list.us 
sudo sed -i "s/us/cn/" /etc/apt/sources.list
sudo apt-get update && sudo apt-get dist-upgrade -y

myT2 "Install basic tools"
#sudo apt-get install screen -y
sudo apt-get install screen kvm libvirt-bin xfsprogs openvswitch-switch -y

myT3 "Install vim"
sudo apt-get install vim -y
cat > ~/.vimrc << EOF
"set smarttab
"set smartindent
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
EOF
cat ~/.vimrc

myT3 "Config Git"
sudo apt-get install git-core git-doc git python-pip -y
sudo pip install --index-url=${PIP_MIRROR} git-review
#git config --global user.name "Wu Wenxiang"    
#git config --global user.email "wu.wenxiang@99cloud.net"
#git config --global color.ui "always"  #Windows
git config --global color.ui "auto" #Linux
git config --global alias.ci "commit"
git config --global alias.co "checkout"
git config --global alias.st "status"
git config --global alias.br "branch"
git config --global core.editor "vim"
#git config --global gitreview.username "wu-wenxiang"
git config --list

myT3 "Config Alias"
sed -i "/${NEVER_MATCH}/d" ~/.bashrc
mkdir -p ${REMOTE_SRC_DIR}
echo "alias gitpull=\"s=${REMOTE_SRC_DIR};x=\`pwd\`;y=\`ls \${s}\`;for z in \${y};do cd \${s}/\${z};pwd;git pull;done;cd \${x}\" # ${NEVER_MATCH}" >> ~/.bashrc
grep gitpull ~/.bashrc

myT3 "GC"
sudo apt-get autoremove -y
sudo apt-get clean

myT2 "End Install Tools!"
