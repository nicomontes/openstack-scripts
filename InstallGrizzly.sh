#COLORS
NORMAL="\\033[0;39m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[1;32m"

echo "________________           __________________"
echo "|$BLUE Conpute Node$NORMAL |           | $BLUE Network Node$NORMAL  |"
echo "| -nova compute|           |  -quantum all  |"
echo "| -kvm         |           |  -brint        |"
echo "| -quantum ovs |           |                |"
echo "| -brint       |           |                |"
echo "|$RED eth0    eth1$NORMAL |           |$RED eth1 eth0 eth2$NORMAL |"
echo "|__$RED|$NORMAL""_______$RED|$NORMAL""___|           |__$RED|$NORMAL""____$RED|$NORMAL""___$RED""brex$NORMAL""_|"
echo "$RED   |       |____VM_Network____|    |    |"
echo "   |          10.20.20.0/24        |    |"
echo "   |______Management_Network_______|    |"
echo "   |       10.10.10.0/24                |                         _  _"
echo '   |'"$NORMAL"'    ___________________             '"$RED"'|                        ( `   )_'
echo '   |    '"$NORMAL"'|'"$BLUE"' Controller Node'"$NORMAL"' |             '"$RED"'|__Internet_Network_____( Internet `)'
echo '   |    '"$NORMAL"'| -keystone       |             '"$RED"'|  192.168.100.0/2     (_   (_ .  _) _)'
echo "   |    $NORMAL| -glance         |             $RED|"
echo "   |    $NORMAL| -horizon        |             $RED|"
echo "   |    $NORMAL| -nova services  |             $RED|"
echo "   |    $NORMAL| -quantum server |             $RED|"
echo "   |    $NORMAL| $RED eth0     eth1$NORMAL  |             $RED|"
echo "   |    $NORMAL|___$RED|$NORMAL""________$RED|$NORMAL""____|             $RED|"
echo "   |________|        |__________________|$NORMAL"
echo ""
echo "$RED You must execute this Script in user home directory$NORMAL"
echo ""

function doCompute
{
  apt-get install -y ubuntu-cloud-keyring
  echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main >> /etc/apt/sources.list.d/grizzly.list
  apt-get update -y
  apt-get upgrade -y
  apt-get dist-upgrade -y
}

function doNetwork
{
# Ubuntu Preparation
  echo "$BLUE -- Preparing Ubuntu --$NORMAL"
  apt-get install -y ubuntu-cloud-keyring
  echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main >> /etc/apt/sources.list.d/grizzly.list
  apt-get update -y
  apt-get upgrade -y
  apt-get dist-upgrade -y
# Install and configure ntp
  apt-get install -y ntp
  sed -i 's/server 0.ubuntu.pool.ntp.org/#server 0.ubuntu.pool.ntp.org/g' /etc/ntp.conf
  sed -i 's/server 1.ubuntu.pool.ntp.org/#server 1.ubuntu.pool.ntp.org/g' /etc/ntp.conf
  sed -i 's/server 2.ubuntu.pool.ntp.org/#server 2.ubuntu.pool.ntp.org/g' /etc/ntp.conf
  sed -i 's/server 3.ubuntu.pool.ntp.org/#server 3.ubuntu.pool.ntp.org/g' /etc/ntp.conf
  sed -i 's/server ntp.ubuntu.com/server 10.10.10.51/g' /etc/ntp.conf
  service ntp restart
# Install vlan bridge
  apt-get install -y vlan bridge-utils
  sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  sysctl net.ipv4.ip_forward=1

# Networking
  echo "$BLUE -- Networking --$NORMAL"
# Internet Network Questions
  read -p 'What is Internet Interface (Exposing Interface API) ? ' internetInterface
  read -p 'Is she Static or Dynamique ? (static|dhcp) ' inetII
  if [ $inetII = "static" ]
  then
    read -p 'What is address of this Interface ? ' addressII
    read -p 'What is netmask of this Interface ? ' netmaskII
    read -p 'What is gateway of this Interface ? ' gatewayII
    read -p 'What is DNS of this Interface ? ' dnsII
  fi
# Openstack Management Network Questions
  read -p 'What is OpenStack Management Interface ? ' openstackInterface
  inetOI="static"
  read -p 'What is address of this Interface ? ' addressOI
  read -p 'What is netmask of this Interface ? ' netmaskOI
# Openstack Virtual Machine Network Questions
  read -p 'What is Virtual Machine Network Interface ? ' VMInterface
  inetVMI="static"
  read -p 'What is address of this Interface ? ' addressVMI
  read -p 'What is netmask of this Interface ? ' netmaskVMI
# Ask Confirmation For Change
  echo "$RED Your Network file /etc/network/interfaces will be change with these values :$NORMAL"
  echo "$GREEN #Internet Interface$NORMAL
  auto br-ex
  iface br-ex inet $inetII" >> /etc/network/interfaces
  if [ $inetII = "static" ]
  then
    echo "    address $addressII
    netmask $netmaskII
    gateway $gatewayII
    dns-nameservers $dnsII"
  fi
  echo "auto $internetInterface
  iface $internetInterface inet manual
  up ifconfig $IFACE 0.0.0.0 up
  up ip link set $IFACE promisc on
  down ip link set $IFACE promisc off
  down ifconfig $IFACE down"
  echo "$GREEN #Not internet connected(used for OpenStack management)$NORMAL
  auto $openstackInterface
  iface $openstackInterface inet $inetOI
  address $addressOI
    netmask $netmaskOI"
  echo "$GREEN #VM Configuration$NORMAL
  auto $VMInterface
  iface $VMInterface inet $inetVMI
    address $addressVMI
    netmask $netmaskVMI"
  echo "$RED Your Network file will are ERASE$NORMAL"
  read -p "Do you want to continue ? (Y/N) " continue
# Write File /etc/network/interfaces if continue=Y
  if [ continue = "Y" ]
  then
    echo "" > /etc/network/interfaces
    echo "# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback
" > /etc/network/interfaces
  echo "#Internet Interface
  auto br-ex
  iface br-ex inet $inetII" >> /etc/network/interfaces
  if [ $inetII = "static" ]
  then
    echo "    address $addressII
    netmask $netmaskII
    gateway $gatewayII
    dns-nameservers $dnsII
" >> /etc/network/interfaces
  fi
  echo "auto $internetInterface
  iface $internetInterface inet manual
  up ifconfig $IFACE 0.0.0.0 up
  up ip link set $IFACE promisc on
  down ip link set $IFACE promisc off
  down ifconfig $IFACE down
" >> /etc/network/interfaces
  echo "#Not internet connected(used for OpenStack management)
  auto $openstackInterface
  iface $openstackInterface inet $inetOI
    address $addressOI
    netmask $netmaskOI
" >> /etc/network/interfaces
echo "#VM Configuration
  auto $VMInterface
  iface $VMInterface inet $inetVMI
    address $addressVMI
    netmask $netmaskVMI" >> /etc/network/interfaces
  echo "Your file was writed with new values"
  fi
  service networking restart
  if [ $inetII = "static" ]
  then
    addressII=$(ifconfig $inetII | grep -o "inet addr:[0-9][\.0-9]*[0-9]" | grep -o "[0-9][\.0-9]*[0-9]")
    netmaskII=$(ifconfig $inetII | grep -o "Mask:[0-9][\.0-9]*[0-9]" | grep -o "[0-9][\.0-9]*[0-9]")
  fi

# OpenVSwitch
  echo "$BLUE -- OpenVSwitch --$NORMAL"
# Installation
  apt-get install -y openvswitch-switch openvswitch-datapath-dkms
# Create Bridge
  ovs-vsctl add-br br-int
  ovs-vsctl add-br br-ex
  ovs-vsctl add-port br-ex $internetInterface
  service networking restart

# Quantum
  echo "$BLUE -- Quantum --$NORMAL"
# Installation
  apt-get -y install quantum-plugin-openvswitch-agent quantum-dhcp-agent quantum-l3-agent quantum-metadata-agent
# Edit api-paste.ini
  sed -i 's/\(paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory\)/\1\nauth_host = '"$addressOI"'\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = quantum\nadmin_password = service_pass/g' /etc/quantum/api-paste.ini
# Edit ovs_quantum_plugin.ini
  sed -i 's/^\(sql_connection.*\)/#\1\nsql_connection = mysql://quantumUser:quantumPass@'"$addressOI"'\/quantum/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Example: tenant_network_type = gre\)/\1\ntenant_network_type = gre/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Example: tunnel_id_ranges = 1:1000\)/\1\ntunnel_id_ranges = 1:1000/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Default: integration_bridge = br-int\)/\1\nintegration_bridge = br-int/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Default: tunnel_bridge = br-tun\)/\1\ntunnel_bridge = br-tun/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Default: enable_tunneling = False\)/\1\nenable_tunneling = True/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
# Edit metadata_agent.ini
  sed -i 's/\(auth_url.*\)/#\1\nauth_url = http:\/\/'"$addressOI"':35357/v2.0/g' /etc/quantum/metadata_agent.ini
  sed -i 's/\(admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/quantum/metadata_agent.ini
  sed -i 's/\(admin_user.*\)/#\1\nadmin_user = quantum/g' /etc/quantum/metadata_agent.ini
  sed -i 's/\(admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/quantum/metadata_agent.ini
  sed -i 's/# \(nova_metadata_ip = \)127.0.0.1/\1'"$addressOI"'/g' /etc/quantum/metadata_agent.ini
  sed -i 's/# \(nova_metadata_port.*\)/\1/g' /etc/quantum/metadata_agent.ini
  sed -i 's/# \(metadata_proxy_shared_secret =\)/\1 helloOpenStack/g' /etc/quantum/metadata_agent.ini
# Edit quantum.conf
  sed -i 's/\(# rabbit_host = localhost\)/\1\nrabbit_host = '"$addressOI"'/g' /etc/quantum/quantum.conf
  sed -i 's/\(^auth_host.*\)/#\1\nauth_host = '"$addressOI"'/g' /etc/quantum/quantum.conf
  sed -i 's/\(^admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/quantum/quantum.conf
  sed -i 's/\(^admin_user.*\)/#\1\nadmin_user = quantum/g' /etc/quantum/quantum.conf
  sed -i 's/\(^admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/quantum/quantum.conf
# Path of home directory
  home=$(pwd)
  cd /etc/init.d/; for i in $( ls quantum-* ); do sudo service $i restart; done
  cd $home
}

function doController
{
# Ubuntu Preparation
  echo "$BLUE -- Preparing Ubuntu --$NORMAL"
  apt-get install -y ubuntu-cloud-keyring
  echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main >> /etc/apt/sources.list.d/grizzly.list
  apt-get update -y
  apt-get upgrade -y
  apt-get dist-upgrade -y

# Networking
  echo "$BLUE -- Networking --$NORMAL"
# Internet Network Questions
  read -p 'What is Internet Interface (Exposing Interface API) ? ' internetInterface
  read -p 'Is she Static or Dynamique ? (static|dhcp) ' inetII
  if [ $inetII = "static" ]
  then
    read -p 'What is address of this Interface ? ' addressII
    read -p 'What is netmask of this Interface ? ' netmaskII
    read -p 'What is gateway of this Interface ? ' gatewayII
    read -p 'What is DNS of this Interface ? ' dnsII
  fi
# Openstack Management Network Questions
  read -p 'What is OpenStack Management Interface ? ' openstackInterface
  inetOI="static"
  read -p 'What is address of this Interface ? ' addressOI
  read -p 'What is netmask of this Interface ? ' netmaskOI
# Ask Confirmation For Change
  echo "$RED Your Network file /etc/network/interfaces will be change with these values :$NORMAL"
  echo "$GREEN #For Exposing OpenStack API over the internet$NORMAL
  auto $internetInterface
  iface $internetInterface inet $inetII"
  if [ $inetII = "static" ]
  then
    echo "    address $addressII
    netmask $netmaskII
    gateway $gatewayII
    dns-nameservers $dnsII"
  fi
  echo "$GREEN #Not internet connected(used for OpenStack management)$NORMAL
  auto $openstackInterface
  iface $openstackInterface inet $inetOI
  address $addressOI
    netmask $netmaskOI"
  echo "$RED Your Network file will are ERASE$NORMAL"
  read -p "Do you want to continue ? (Y/N) " continue
# Write File /etc/network/interfaces if continue=Y
  if [ continue = "Y" ]
  then
    echo "" > /etc/network/interfaces
    echo "# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback
" > /etc/network/interfaces
  echo "#For Exposing OpenStack API over the internet
  auto $internetInterface
  iface $internetInterface inet $inetII" >> /etc/network/interfaces
  if [ $inetII = "static" ]
  then
    echo "    address $addressII
    netmask $netmaskII
    gateway $gatewayII
    dns-nameservers $dnsII
" >> /etc/network/interfaces
  fi
  echo "#Not internet connected(used for OpenStack management)
  auto $openstackInterface
  iface $openstackInterface inet $inetOI
    address $addressOI
    netmask $netmaskOI" >> /etc/network/interfaces
  echo "Your file was writed with new values"
  fi
  service networking restart
  if [ $inetII = "static" ]
  then
    addressII=$(ifconfig $inetII | grep -o "inet addr:[0-9][\.0-9]*[0-9]" | grep -o "[0-9][\.0-9]*[0-9]")
    netmaskII=$(ifconfig $inetII | grep -o "Mask:[0-9][\.0-9]*[0-9]" | grep -o "[0-9][\.0-9]*[0-9]")
  fi

# MySQL + RabbitMQ
  echo "$BLUE -- MySQL & RabbitMQ --$NORMAL"
# Installation
  apt-get install -y mysql-server python-mysqldb
# Listen on all address
  sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
  service mysql restart
# Installation
  apt-get install -y rabbitmq-server
  apt-get install -y ntp
# Create Databases with Permissions
  echo "CREATE DATABASE keystone;\
GRANT ALL ON keystone.* TO 'keystoneUser'@'%' IDENTIFIED BY 'keystonePass';\
CREATE DATABASE glance;\
GRANT ALL ON glance.* TO 'glanceUser'@'%' IDENTIFIED BY 'glancePass';\
CREATE DATABASE quantum;\
GRANT ALL ON quantum.* TO 'quantumUser'@'%' IDENTIFIED BY 'quantumPass';\
CREATE DATABASE nova;\
GRANT ALL ON nova.* TO 'novaUser'@'%' IDENTIFIED BY 'novaPass';\
CREATE DATABASE cinder;\
GRANT ALL ON cinder.* TO 'cinderUser'@'%' IDENTIFIED BY 'cinderPass';\
quit;" > mysql -u root -p

# Other (vlan-bridge)
  echo "$BLUE -- Other --$NORMAL"
  apt-get install -y vlan bridge-utils
  sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  sysctl net.ipv4.ip_forward=1

# Keystone
  echo "$BLUE -- Keystone --$NORMAL"
  apt-get install -y keystone
# Change sql connection keystone.conf
  sed -i 's/^\(connection.*\)/#\1\nconnection = mysql:\/\/keystoneUser:keystonePass@'"$addressOI"'\/keystone/g' /etc/keystone/keystone.conf
  service keystone restart
  keystone-manage db_sync
# Download 2 scripts
  wget https://raw.github.com/mseknibilel/OpenStack-Grizzly-Install-Guide/OVS_MultiNode/KeystoneScripts/keystone_basic.sh
  wget https://raw.github.com/mseknibilel/OpenStack-Grizzly-Install-Guide/OVS_MultiNode/KeystoneScripts/keystone_endpoints_basic.sh
# Change IP in scripts
  sed -i 's/^\(HOST_IP.*\)/#\1\nHOST_IP='"$addressOI"'/g' keystone_basic.sh
  sed -i 's/^\(HOST_IP.*\)/#\1\nHOST_IP='"$addressOI"'/g' keystone_endpoints_basic.sh
  sed -i 's/^\(EXT_HOST_IP.*\)/#\1\nEXT_HOST_IP='"$addressII"'/g' keystone_endpoints_basic.sh
  chmod +x keystone_basic.sh
  chmod +x keystone_endpoints_basic.sh
  ./keystone_basic.sh
  ./keystone_endpoints_basic.sh
# Create soource files for services connection
  touch sources
  echo "#Paste the following:
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=admin_pass
export OS_AUTH_URL=\"http://"$addressII":5000/v2.0/\"
export OS_SERVICE_ENDPOINT=http://"$addressOI":35357/v2.0
export OS_SERVICE_TOKEN=ADMIN" > sources
  source sources
  echo "$GREEN Comande keystone user-list$NORMAL"
  keystone user-list

# Glance
  echo "$BLUE -- GLANCE --$NORMAL"
  apt-get install -y glance
# Edit glance-api-paste.ini
  echo "auth_host = $addressOI
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = service_pass" >> /etc/glance/glance-api-paste.ini
# Edit glance-registry-paste.ini
  echo "auth_host = $addressOI
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = service_pass" >> /etc/glance/glance-registry-paste.ini
# Edit glance-api.conf
  sed -i 's/^\(sql_connection.*\)/#\1\nsql_connection = mysql:\/\/glanceUser:glancePass@'"$addressOI"'\/glance/g' /etc/glance/glance-api.conf
  echo "flavor = keystone" >> /etc/glance/glance-api.conf
# Edit glance-registry.conf
  sed -i 's/^\(sql_connection.*\)/#\1\nsql_connection = mysql:\/\/glanceUser:glancePass@'"$addressOI"'\/glance/g' /etc/glance/glance-registry.conf
  echo "flavor = keystone" >> /etc/glance/glance-registry.conf
  service glance-api restart; service glance-registry restart
# Sync Database
  glance-manage db_sync
# Download Image and Add
  glance image-create --name myFirstImage --is-public true --container-format bare --disk-format qcow2 --location https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
  echo "$GREEN Commande glance image-list$NORMAL"
  glance image-list

# Quantum
  echo "$BLUE -- Quantum --$NORMAL"
# Installation
  apt-get install -y quantum-server
# Edit ovs_quantum_plugin.ini
  sed -i 's/^\(sql_connection.*\)/#\1\nsql_connection = mysql://quantumUser:quantumPass@'"$addressOI"'\/quantum/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Example: tenant_network_type = gre\)/\1\ntenant_network_type = gre/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Example: tunnel_id_ranges = 1:1000\)/\1\ntunnel_id_ranges = 1:1000/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Default: enable_tunneling = False\)/\1\nenable_tunneling = True/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
# Edit api-paste.ini
  sed -i 's/\(paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory\)/\1\nauth_host = '"$addressOI"'\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = quantum\nadmin_password = service_pass/g' /etc/quantum/api-paste.ini
# Edit quantum.conf
  sed -i 's/\(^auth_host.*\)/#\1\nauth_host = '"$addressOI"'/g' /etc/quantum/quantum.conf
  sed -i 's/\(^admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/quantum/quantum.conf
  sed -i 's/\(^admin_user.*\)/#\1\nadmin_user = quantum/g' /etc/quantum/quantum.conf
  sed -i 's/\(^admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/quantum/quantum.conf
  service quantum-server restart

# Nova
  echo "$BLUE -- Nova --$NORMAL"
# Installation
  apt-get install -y nova-api nova-cert novnc nova-consoleauth nova-scheduler nova-novncproxy nova-doc nova-conductor
# Edit api-paste.ini
  sed -i 's/\(^auth_host.*\)/#\1\nauth_host = '"$addressOI"'/g' /etc/nova/api-paste.ini
  sed -i 's/\(^admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/nova/api-paste.ini
  sed -i 's/\(^admin_user.*\)/#\1\nadmin_user = quantum/g' /etc/nova/api-paste.ini
  sed -i 's/\(^admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/nova/api-paste.ini
# Edit nova.conf
  sed -i 's/\(^[a-z].*\)/#\1/g' /etc/nova/nova.conf
  echo "" >> /etc/nova/nova.conf
  echo "logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/run/lock/nova
verbose=True
api_paste_config=/etc/nova/api-paste.ini
compute_scheduler_driver=nova.scheduler.simple.SimpleScheduler
rabbit_host="$addressOI"
nova_url=http://"$addressOI":8774/v1.1/
sql_connection=mysql://novaUser:novaPass@"$addressOI"nova
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf

# Auth
use_deprecated_auth=false
auth_strategy=keystone

# Imaging service
glance_api_servers="$addressOI":9292
image_service=nova.image.glance.GlanceImageService

# Vnc configuration
novnc_enabled=true
novncproxy_base_url=http://"$addressII":6080/vnc_auto.html
novncproxy_port=6080
vncserver_proxyclient_address="$addressOI"
vncserver_listen=0.0.0.0

# Network settings
network_api_class=nova.network.quantumv2.api.API
quantum_url=http://"$addressOI":9696
quantum_auth_strategy=keystone
quantum_admin_tenant_name=service
quantum_admin_username=quantum
quantum_admin_password=service_pass
quantum_admin_auth_url=http://"$addressOI":35357/v2.0
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver

#Metadata
service_quantum_metadata_proxy = True
quantum_metadata_proxy_shared_secret = helloOpenStack

# Compute #
compute_driver=libvirt.LibvirtDriver

# Cinder #
volume_api_class=nova.volume.cinder.API
osapi_volume_listen_port=5900" >> /etc/nova/nova.conf
# Sync Database
  nova-manage db sync
# Path of home directory
  home=$(pwd)
  cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done
  cd $home
  echo "$GREEN Commende nova-manage service list$NORMAL"
  nova-manage service list

# Cinder
  echo "$BLUE -- Cinder --$NORMAL"
# Installation
  apt-get install -y cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms
  sed -i 's/false/true/g' /etc/default/iscsitarget
  service iscsitarget start
  service open-iscsi start
# Edit api-paste.ini
  sed -i 's/\(^service_host.*\)/#\1\nservice_host = '"$addressII"'/g' /etc/cinder/api-paste.ini
  sed -i 's/\(^auth_host.*\)/#\1\nauth_host = '"$addressOI"'/g' /etc/cinder/api-paste.ini
  sed -i 's/\(^admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/cinder/api-paste.ini
  sed -i 's/\(^admin_user.*\)/#\1\nadmin_user = cinder/g' /etc/cinder/api-paste.ini
  sed -i 's/\(^admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/cinder/api-paste.ini
# Edit cinder.conf
  echo "sql_connection = mysql://cinderUser:cinderPass@"$addressOI"/cinder" >> /etc/cinder/cinder.conf
  echo "iscsi_ip_address=$addressOI" >> /etc/cinder/cinder.conf
# Sync Database
  cinder-manage db sync
  read -p "What is the disk for your Volume Group ? " diskVG
# Create PV and VG
  pvcreate $diskVG
  vgcreate cinder-volumes $diskVG
  cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i restart; done
  echo "$GREEN Commande to vrify all cinder services$NORMAL"
  cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i status; done
  cd $home

# Horizon
  echo "$BLUE -- HORIZON --$NORMAL"
  apt-get install -y openstack-dashboard memcached
# Remove Ubuntu Theme
  dpkg --purge openstack-dashboard-ubuntu-theme
  service apache2 restart; service memcached restart
}

# Ask what node he want install
node=""
while [ -z $node ]
do
  read -p 'What do you want install ? (compute/network/controller) ' node
  case $node in
    "compute")
      doCompute
    ;;
    "network")
      doNetwork
    ;;
    "controller")
      doController
    ;;
    *)
      node=""
    ;;
  esac
done