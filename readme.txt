Steps:

Tip_0 Host Network
    Tip_0_1 Install Basic OS, refer to 1
    Tip_0_2 conf-vm.sh <vm_ipaddr> <vm_hostname>
    Tip_0_3 sudo usermod -a -G libvirtd <usrname>.  # Now we could connect to libvirt
    Tip_0_4 Network configuration: 
        Tip_0_4_1 sudo apt-get install bridge-utils
        Tip_0_4_2 trystack@OS-2:~$ cat /etc/network/interfaces 
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual

auto br-eth0
iface br-eth0 inet static
    address 192.168.1.20
    netmask 255.255.255.0
    gateway 192.168.1.1
    bridge_stp off
    bridge_ports eth0
    bridge_maxwait 5

auto eth1
iface eth1 inet manual

auto br-eth1
iface br-eth1 inet static
    address 172.16.2.1
    netmask 255.255.255.0
    bridge_stp off
    bridge_ports eth1
    bridge_maxwait 5

Tip_1 Install Basic OS
    Tip_1_1 Ensure su passwd has been set
    Tip_1_2 Ensure openssh server installed
	Tip_1_3 Maybe Need Modify user/password
		userdel pear && groupadd trystack && useradd -d /home/trystack -g trystack trystack -s "/bin/bash"  && passwd trystack && passwd
		mv /home/pear /home/trystack
		/etc/sudoers => pear / stack

Tip_2  Install Dep Packages & Config Remote VM
    Tip_2_1 Usage:
        ./conf-vm.sh <vm_ipaddr>
    Tip_2_2 Example:
        ./conf-vm.sh 192.168.122.231 

Tip_3  Install MySQL
    Tip_3_1 Install
        Edit /etc/network/interface, Reboot Network service
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.1.21
    netmask 255.255.255.0
    gateway 192.168.1.1

        ./conf-vm.sh 192.168.1.21 MySQL
        
        Tip_3_1_1 Auto Installation
            cd mysql server
            /home/pear/openstack/install/install-mysql.sh

    Tip_3_2 Test 
        mysql -h192.168.1.21 -uroot -p99cloud

Tip_4 Install RabbitMQ
    Tip_4_1 Install
        Edit /etc/network/interface, Reboot Network service
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.1.22
    netmask 255.255.255.0
    gateway 192.168.1.1

        ./conf-vm.sh 192.168.1.22 RabbitMQ
        Tip_3_1_1 Auto Installation
            cd rabbit server
            /home/pear/openstack/install/install-rabbit.sh
        
    Tip_4_2 Test
        Run python receive.py & python send.py, could see send msg & receive.

Tip_5 Install & Init Ctrl
    Tip5_1 Install
        Add a qcow2 disk to ctrl node
        Edit /etc/network/interface, Reboot Network service
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.1.23
    netmask 255.255.255.0
    gateway 192.168.1.1

        fdisk /dev/vdb, n, t/8e, w
        ./conf-vm.sh 192.168.1.23 Ctrl
		./conf-vm.sh 192.168.1.24 Keystone
		./conf-vm.sh 192.168.1.25 SwiftProxy
        
        ./install-ctrl.sh 
    Tip_5_2 Init
        ./init-ctrl.sh 
    Tip_5_3 Start & Stop
        ./start-ctrl.sh
        ./stop-all.sh

Tip_6 Install & Init Network
    Tip_6_1 Install
        Edit network configuration & Reset Network
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address 192.168.1.24
netmask 255.255.255.0
gateway 192.168.1.1

auto eth1
iface eth1 inet manual
up ifconfig $IFACE 0.0.0.0 up
up ip link set $IFACE promisc on
down ip link set $IFACE promisc off
down ifconfig $IFACE down

#auto br-ex
#iface br-ex inet static
#	address 172.16.2.100
#	netmask 255.255.255.0
            
        ./conf-vm.sh 192.168.1.22 Network
        ./install-network.sh 

        OpenVSwitch:
            sudo ovs-vsctl add-br br-int
            sudo ovs-vsctl add-br br-ex
            sudo ovs-vsctl add-port br-ex eth1

Config Network

auto br-ex
iface br-ex inet static
	address 172.16.2.100
	netmask 255.255.255.0
            
    Tip_6_2 Init
        ./init-network.sh
    
    Tip_6_3 Start & Stop
        ./start-network.sh
        ./stop-all.sh
        
Tip_7 Install & Init Compute
    Tip_7_1 Install
        Edit /etc/network/interface, Reboot Network service
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.1.51
    netmask 255.255.255.0
    gateway 192.168.1.1

        ./conf-vm.sh 192.168.1.51 Compute1
        ./install-compute.sh 192.168.1.51

		sudo ovs-vsctl add-br br-int
        
    Tip_7_2 Init
        ./init-compute.sh 192.168.1.51
    
    Tip_7_3 Start & Stop
        ./start-compute.sh
        ./stop-all.sh
        
Tip_8 Test
    Tip_8_1 Launch VM
        quantum net-create Ext-Net --provider:network_type local --router:external true
        quantum subnet-create Ext-Net 172.16.2.0/24
        quantum net-create TenantA-Net
        quantum subnet-create TenantA-Net 10.0.1.0/24
        quantum net-list # TenantA-Net ID
        nova boot --image tty-linux --flavor 1 --nic net-id=748ae7d2-4600-43b9-b15e-92aa888d52a4 TenantA_VM1
        
        # TenantA_VM1 could launch but dhcp failed. ps -ef | grep dns, no correct dnsmasq in processing, relaunch quantum in network node
        # stopQuantum
        # startQuantumNetwork
        # Reboot VM
            Sending select for 10.0.1.2...
            Lease of 10.0.1.2 obtained, lease time 120
            starting DHCP forEthernet interface eth0  [  [1;32mOK[0;39m  ]
            cloud-setup: checking http://169.254.169.254/2009-04-04/meta-data/instance-id
            wget: can't connect to remote host (169.254.169.254): No route to host
            cloud-setup: failed 1/30: up 6.53. request failed

        trystack@Network:~/openstack$ ip netns
        qrouter-b3fac298-6029-4e53-8562-586ca68820dd
        qdhcp-31d738ed-90a3-4bb5-b3e8-25ecb9ac953f
        qdhcp-748ae7d2-4600-43b9-b15e-92aa888d52a4

        sudo ip netns exec qrouter-b3fac298-6029-4e53-8562-586ca68820dd ping 10.0.1.2
        sudo ip netns exec qrouter-b3fac298-6029-4e53-8562-586ca68820dd ssh 10.0.1.2 -l root

    Tip_8_2 Router
        quantum router-create TenantA-R1
        quantum subnet-list
        +--------------------------------------+------+---------------+------------------------------------------------+
        | id                                   | name | cidr          | allocation_pools                               |
        +--------------------------------------+------+---------------+------------------------------------------------+
        | 49944e34-0412-4baa-92a5-28d350287261 |      | 172.16.2.0/24 | {"start": "172.16.2.2", "end": "172.16.2.254"} |
        | dcc0768a-1e4f-4797-9e18-7ed08bb23bee |      | 10.0.1.0/24   | {"start": "10.0.1.2", "end": "10.0.1.254"}     |
        +--------------------------------------+------+---------------+------------------------------------------------+
        quantum router-interface-add TenantA-R1 dcc0768a-1e4f-4797-9e18-7ed08bb23bee
        quantum router-gateway-set TenantA-R1 Ext-Net
        
        ping 172.16.2.1 OK
        # Couldn't ping 192.168.1.20, Don't know why

    Tip_8_3 Floating IP
        quantum floatingip-create Ext-Net
        nova list
        +--------------------------------------+-------+--------+----------------------+
        | ID                                   | Name  | Status | Networks             |
        +--------------------------------------+-------+--------+----------------------+
        | 820a47e2-c686-4a3a-b680-f60b642971f9 | test3 | ACTIVE | TenantA-Net=10.0.1.2 |
        +--------------------------------------+-------+--------+----------------------+
        quantum port-list -- --device_id 820a47e2-c686-4a3a-b680-f60b642971f9
        quantum floatingipassociate <floatingip id> <port id>
        
        
Tip_11  Install GitMirror
    Tip_11_1 Installation
        http://blog.chinaunix.net/uid-20940095-id-3340707.html
    Tip_11_2 Config 
        1. Run synchub.sh 
            1. Check Git Status
            2. Generate gitolite.conf
        2. Paste edit gitolite.conf, commit, push
        3. Run synchub.sh
            3.1 Sync Mirror

Tip_12   Install PostgreSQL
    Tip_12_1 Basic Install
        ./conf-vm.sh 192.168.1.41 PSQLM
        ./conf-vm.sh 192.168.1.41 PSQLS
    Tip_12_2 Apt-get
        sudo apt-get install postgresql python-mysqldb python-psycopg2 -y
        
Tip_13  Install Swift Node
    Tip_13_1 Install
        Edit /etc/network/interface, Reboot Network service
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.1.42
    netmask 255.255.255.0
    gateway 192.168.1.1

        ./conf-vm.sh 192.168.1.45 SwiftNode1
        ./conf-vm.sh 192.168.1.46 SwiftNode2
        ./conf-vm.sh 192.168.1.47 SwiftNode3
        
        Tip_13_1_2 Automatic Installation
            ./install-swift_node.sh 192.168.1.45
            ./install-swift_node.sh 192.168.1.46
            ./install-swift_node.sh 192.168.1.47
        
    Tip_13_2 Init
        ./init-swift_node.sh 192.168.1.45
    
    Tip_13_3 Start & Stop
        ./start-swiftnode.sh
        ./stop-all.sh

Tip_20 All_In_One
    Tip_20_1 Prepare
        Base Ubuntu 12.04, user/root/passwd + sshd
        Add /vdb for cinder, fdisk w/default*n/t/8e/w
        Net Set, reboot
        user&root/home dir/password/sudo
    
    Tip_20_2 Git Server
        

    Tip_20_3 Steps
        0. localrc => All In One
        1. ./conf-vm.sh 192.168.122.40 AllInOne
            Install mysql & rabbitmq
        2. ./install-ctrl.sh
            init-db in mysql server
            ./install keystone & init
            ./install glance & init
        3. ./install-network.sh
        4. ./install-compute.sh 192.168.122.40
        5. ./init-ctrl.sh
        6. ./init-network.sh
        7. ./init-compute.sh 192.168.122.40
        8. log in, stop all, start all


Tips:
-from nova.openstack.common import cfg
+from oslo.config import cfg


  110  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de ip route add 0.0.0.0/24 via 172.16.0.1
  111  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de ifconfig
  112  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de ip route add 0.0.0.0/24 dev qg-cfb4e432-c6
  113  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de route -n
  114  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de ip route chg 0.0.0.0/24 via 172.16.0.1
  115  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de ping 172.16.0.1
  116  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de brctl show
  117  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de ovs-vsctl show
  118  vim l3_agent.ini 
  119  sudo screen -x network
  120  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de ovs-vsctl show
  121  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de route -n
  122  sudo ip netns exec qrouter-04c9cb6f-23bf-4763-aa18-1e923f8f44de ip route add 172.16.0.0/24 dev qg-cfb4e432-c6
  
  
  wget http://169.254.169.254
  traceroute 8.8.8.8 
  
  Create Network, Subnet, ext & int
  Create router, add 2 gateway, from 

1. Create internal network/subnet, instance could get IP from dhcp, ping gateway failed.
2. Create a router, add interface to internal network, ping gateway OK. but couldn't get 169.254.169.254, 
    Because metadata agent in Network node couldn't reach, so couldn't trans 169.254.169.254:80 to 9697, see from iptables -t nat => redirect
3. Create external network/subnet, remember subnet should cover your network node, or you need to add route manually, no disable gw, no dhcp
4. set gateway in router, now we can ping external world
5. Add floating IP
6. Add rules in default secure group, TCP 22, ICMP -1 -1, CIRD.
