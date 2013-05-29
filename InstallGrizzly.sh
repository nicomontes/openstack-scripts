#!/bin/bash
#COLORS
eval "`dircolors -b`"
NORMAL="\\033[0;39m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[1;32m"
YELLOW="\\033[1;33m"
NORMALUNDERLINED="033[4;39m"

echo "________________           __________________"
echo -e "|$BLUE Compute Node$NORMAL |           | $BLUE Network Node$NORMAL  |"
echo -e "| -nova compute|           |  -quantum all  |"
echo -e "| -kvm         |           |  -brint        |"
echo -e "| -quantum ovs |           |                |"
echo -e "| -brint       |           |                |"
echo -e "|$RED eth0   $GREEN eth1$NORMAL |           |$GREEN eth1$RED eth0$YELLOW eth2$NORMAL |"
echo -e "|__$RED|$NORMAL""_______$GREEN|$NORMAL""___|           |__$GREEN|$NORMAL""____$RED|$NORMAL""___$YELLOW""brex$NORMAL""_|"
echo -e "$RED   |       $GREEN|____VM_Network____|$RED    |    $YELLOW|"
echo -e "$RED   |         $GREEN 10.20.20.0/24      $RED  |    $YELLOW|"
echo -e "$RED   |______Management_Network_______|    $YELLOW|"
echo -e "$RED   |       10.10.10.0/24                $YELLOW|                         _  _"
echo -e $RED'   |'"$NORMAL"'    ___________________             '"$YELLOW"'|                        ( `   )_'
echo -e $RED'   |    '"$NORMAL"'|'"$BLUE"' Controller Node'"$NORMAL"' |             '"$YELLOW"'|__Internet_Network_____( Internet `)'
echo -e $RED'   |    '"$NORMAL"'| -keystone       |             '"$YELLOW"'|  192.168.100.0/2     (_   (_ .  _) _)'
echo -e "$RED   |    $NORMAL| -glance         |             $YELLOW|"
echo -e "$RED   |    $NORMAL| -horizon        |             $YELLOW|"
echo -e "$RED   |    $NORMAL| -nova services  |             $YELLOW|"
echo -e "$RED   |    $NORMAL| -quantum server |             $YELLOW|"
echo -e "$RED   |    $NORMAL| $RED eth0  $YELLOW   eth1$NORMAL  |             $YELLOW|"
echo -e "$RED   |    $NORMAL|___$RED|$NORMAL""________$YELLOW|$NORMAL""____|             $YELLOW|"
echo -e "$RED   |________|      $YELLOW  |__________________|$NORMAL"
echo ""
echo -e "$RED You must execute this Script in user home directory$NORMAL"
echo "If you install more one Node on this Server you must install Network Node in last time for better results"
echo ""

# Network functions
# Check if Interface is configured, return true or false
function checkInterface
{
  while read line
  do
    interfaceName=$(echo $line | grep -o "^auto.*" | grep -o "[a-zA-Z0-9]*$")
    if [ "$interfaceName" == "$1" ]
    then
      echo "true"
      checkOK="true"
    fi
  done < /etc/network/interfaces
  if [ -z "$checkOK" ]
  then
    checkOK="false"
    echo "false"
  fi
}

# Check the configuration, return the interface configuration
function checkConfigInterface
{
  while read line
  do
    interfaceName=$(echo $line | grep -o "^auto.*" | grep -o "[a-zA-Z0-9]*$")
    if [ "$interfaceName" == "$1" ]
    then
      checkOK="true"
    fi
    if [ "$(echo $line | grep -o "^auto")" == "auto" ] && [ "$checkOK" == "true" ]
    then
      auto="true"
      interfaceConf=$line
    elif [ "$auto" == "true" ] && [ -n "$(echo $line | grep -o ".*")" ] && [ "$checkOK" == "true" ]
    then
      interfaceConf=$(echo "$interfaceConf\n$line")
    elif [ "$auto" == "true" ] && [ "$(echo $line | grep "^[\ ]*#" | grep -o "#")" == "#" ]
    then
      auto="false"
      checkOK="false"
      echo -e "$interfaceConf"
    elif [ "$auto" == "true" ] && [ -z "$(echo $line | grep -o ".*")" ] && [ "$checkOK" == "true" ]
    then
      auto="false"
      checkOK="false"
      echo -e "$interfaceConf"
    fi
  done < /etc/network/interfaces
  if [ "$checkOK" == "true" ]
  then
    auto="false"
    checkOK="false"
    echo -e "$interfaceConf"
  fi
}

# return interface configuration for ask of user if he want change
function askConfirmInterface
{
  if [ "$(checkInterface $1)" == "true" ]
  then
    interfaceConf=$(checkConfigInterface $1)
    echo -e $RED"--- OLD Config Interface ---$NORMAL"
    echo -e "$interfaceConf"
  else
    echo -e "$RED This Interface is not configured in your network file$NORMAL"
  fi
  echo -e $RED"--- NEW Config Interface ---$NORMAL"
  echo -e "auto $1
iface $1 inet $2"
  newInterfaceConf=$(echo "auto $1
iface $1 inet $2")
  if [ -n "$4" ] && [ -z "$6" ]
  then
    echo -e "address $3
netmask $4"
    newInterfaceConf=$(echo "auto $1
iface $1 inet $2
address $3
netmask $4")
  elif [ -n "$6" ]
  then
    echo -e "address $3
netmask $4
gateway $5
dns-nameservers $6"
    newInterfaceConf=$(echo "auto $1
iface $1 inet $2
address $3
netmask $4
gateway $5
dns-nameservers $6")
  fi
}

# Write new interface configuration
function writeInterface
{
  numLineStart=$(grep -n "^auto $1" /etc/network/interfaces | cut -d":" -f1 | head -n 1)
  nbLine=$(echo "$(checkConfigInterface $1)" | wc -l)
  i="1"
  while [ "$i" -le "$nbLine" ] && [ -n "$numLineStart" ]
  do
    sed -i "$numLineStart"'d' /etc/network/interfaces
    i=$(($i+1))
  done
  if [ -n "$5" ] && [ -z "$7" ]
  then
    echo -e "
# $5
auto $1
iface $1 inet $2
address $3
netmask $4" >> /etc/network/interfaces
  elif [ -n "$7" ]
  then
    echo -e "
# $7
auto $1
iface $1 inet $2
address $3
netmask $4
gateway $5
dns-nameservers $6" >> /etc/network/interfaces
  else
    echo -e "
# $3
auto $1
iface $1 inet $2" >> /etc/network/interfaces
  fi
}

# Erase Interface
function removeInterface
{
  numLineStart=$(grep -n "^auto $1" /etc/network/interfaces | cut -d":" -f1 | head -n 1)
  nbLine=$(echo "$(checkConfigInterface $1)" | wc -l)
  i="1"
  while [ "$i" -le "$nbLine" ] && [ -n "$numLineStart" ]
  do
    sed -i "$numLineStart"'d' /etc/network/interfaces
    i=$(($i+1))
  done
}

function doController
{
# Ubuntu Preparation
  echo -e "$BLUE -- Preparing Ubuntu --$NORMAL"
  apt-get install -y ubuntu-cloud-keyring
  echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main >> /etc/apt/sources.list.d/grizzly.list
  apt-get update -y
  apt-get upgrade -y
  apt-get dist-upgrade -y

# Networking
  echo -e "$BLUE -- Networking --$NORMAL"
# Internet Network Questions
  read -p 'What is Internet Interface (Exposing Interface API) ? ' controllerInternetInterface
  read -p 'Is it Static or Dynamic ? (static|dhcp) ' controllerInetII
  if [ "$controllerInetII" = "static" ]
  then
    read -p 'What is the address of this Interface ? ' controllerAddressII
    read -p 'What is the netmask of this Interface ? ' controllerNetmaskII
    read -p 'What is the gateway of this Interface ? ' controllerGatewayII
    echo "controllerGatewayII=$controllerGatewayII" >> openstack.conf
    read -p 'What is the DNS of this Interface ? ' controllerDnsII
    echo "controllerDnsII=$controllerDnsII" >> openstack.conf
  fi
# Openstack Management Network Questions
  read -p 'What is the OpenStack Management Interface ? ' controllerOpenstackInterface
  controllerInetOI="static"
  read -p 'What is the address of this Interface ? ' controllerAddressOI
  read -p 'What is the netmask of this Interface ? ' controllerNetmaskOI
# Ask Confirmation For Change
echo -e "$RED Your Network file /etc/network/interfaces will be change with these values :$NORMAL"
  askConfirmInterface $controllerInternetInterface $controllerInetII $controllerAddressII $controllerNetmaskII $controllerGatewayII $controllerDnsII
  askConfirmInterface $controllerOpenstackInterface $controllerInetOI $controllerAddressOI $controllerNetmaskOI
  echo -e "$RED Your Network file will are Change$NORMAL"
  read -p "Do you want to continue ? (Y/N) " write
# Write File /etc/network/interfaces if continue=Y
  if [ "$write" == "Y" ]
  then
    writeInterface $controllerInternetInterface $controllerInetII $controllerAddressII $controllerNetmaskII $controllerGatewayII $controllerDnsII "Internet Interface"
    writeInterface $controllerOpenstackInterface $controllerInetOI $controllerAddressOI $controllerNetmaskOI "OpenStack"
  fi
  /etc/init.d/networking restart
  if [ "$controllerInetII" == "dhcp" ]
  then
    controllerAddressII=$(ifconfig $controllerInternetInterface | grep -o "inet [a-zA-Z]*:[0-9][\.0-9]*[0-9]" | grep -o "[0-9][\.0-9]*[0-9]")
    controllerNetmaskII=$(ifconfig $controllerInternetInterface | grep -o "Mas[a-zA-Z]*:[0-9][\.0-9]*[0-9]" | grep -o "[0-9][\.0-9]*[0-9]")
  fi
echo "controllerInternetInterface=$controllerInternetInterface" >> openstack.conf
echo "controllerInetII=$controllerInetII" >> openstack.conf
echo "controllerAddressII=$controllerAddressII" >> openstack.conf
echo "controllerNetmaskII=$controllerNetmaskII" >> openstack.conf
echo "controllerOpenstackInterface=$controllerOpenstackInterface" >> openstack.conf
echo "controllerAddressOI=$controllerAddressOI" >> openstack.conf
echo "controllerNetmaskOI=$controllerNetmaskOI" >> openstack.conf

# MySQL + RabbitMQ
  echo -e "$BLUE -- MySQL & RabbitMQ --$NORMAL"
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
GRANT ALL ON cinder.* TO 'cinderUser'@'%' IDENTIFIED BY 'cinderPass';" > mysqlOpenStack.sql
mysql -u root -p < mysqlOpenStack.sql

# Other (vlan-bridge)
  echo -e "$BLUE -- Other --$NORMAL"
  apt-get install -y vlan bridge-utils
  sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  sysctl net.ipv4.ip_forward=1

# Keystone
  echo -e "$BLUE -- Keystone --$NORMAL"
  apt-get install -y keystone
# Change sql connection keystone.conf
  sed -i 's/^\(connection.*\)/#\1\nconnection = mysql:\/\/keystoneUser:keystonePass@'"$controllerAddressOI"'\/keystone/g' /etc/keystone/keystone.conf
  service keystone restart
  keystone-manage db_sync
# Download 2 scripts
  wget https://raw.github.com/mseknibilel/OpenStack-Grizzly-Install-Guide/OVS_MultiNode/KeystoneScripts/keystone_basic.sh
  wget https://raw.github.com/mseknibilel/OpenStack-Grizzly-Install-Guide/OVS_MultiNode/KeystoneScripts/keystone_endpoints_basic.sh
# Change IP in scripts
  sed -i 's/^\(HOST_IP.*\)/#\1\nHOST_IP='"$controllerAddressOI"'/g' keystone_basic.sh
  sed -i 's/^\(HOST_IP.*\)/#\1\nHOST_IP='"$controllerAddressOI"'/g' keystone_endpoints_basic.sh
  sed -i 's/^\(EXT_HOST_IP.*\)/#\1\nEXT_HOST_IP='"$controllerAddressII"'/g' keystone_endpoints_basic.sh
  chmod +x keystone_basic.sh
  chmod +x keystone_endpoints_basic.sh
  ./keystone_basic.sh
  ./keystone_endpoints_basic.sh
# Create soource files for services connection
  touch sources
  echo "export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=admin_pass
export OS_AUTH_URL=\"http://"$controllerAddressII":5000/v2.0/\"
export OS_SERVICE_ENDPOINT=http://"$controllerAddressOI":35357/v2.0
export OS_SERVICE_TOKEN=ADMIN" > sources
  source sources
  echo -e "$GREEN Comande keystone user-list$NORMAL"
  keystone user-list

# Glance
  echo -e "$BLUE -- GLANCE --$NORMAL"
  apt-get install -y glance
# Edit glance-api-paste.ini
  echo "auth_host = $controllerAddressOI
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = service_pass" >> /etc/glance/glance-api-paste.ini
# Edit glance-registry-paste.ini
  echo "auth_host = $controllerAddressOI
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = service_pass" >> /etc/glance/glance-registry-paste.ini
# Edit glance-api.conf
  sed -i 's/^\(sql_connection.*\)/#\1\nsql_connection = mysql:\/\/glanceUser:glancePass@'"$controllerAddressOI"'\/glance/g' /etc/glance/glance-api.conf
  echo "flavor = keystone" >> /etc/glance/glance-api.conf
# Edit glance-registry.conf
  sed -i 's/^\(sql_connection.*\)/#\1\nsql_connection = mysql:\/\/glanceUser:glancePass@'"$controllerAddressOI"'\/glance/g' /etc/glance/glance-registry.conf
  echo "flavor = keystone" >> /etc/glance/glance-registry.conf
  service glance-api restart; service glance-registry restart
# Sync Database
  glance-manage db_sync
# Download Image and Add
  echo -e "$GREEN Download Image$NORMAL"
  glance image-create --name myFirstImage --is-public true --container-format bare --disk-format qcow2 --location https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
  echo -e "$GREEN Commande glance image-list$NORMAL"
  glance image-list

# Quantum
  echo -e "$BLUE -- Quantum --$NORMAL"
# Installation
  apt-get install -y quantum-server
# Edit ovs_quantum_plugin.ini
  sed -i 's/^\(sql_connection.*\)/#\1\nsql_connection = mysql:\/\/quantumUser:quantumPass@'"$controllerAddressOI"'\/quantum/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Example: tenant_network_type = gre\)/\1\ntenant_network_type = gre/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Example: tunnel_id_ranges = 1:1000\)/\1\ntunnel_id_ranges = 1:1000/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Default: enable_tunneling = False\)/\1\nenable_tunneling = True/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
# Edit api-paste.ini
  sed -i 's/\(paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory\)/\1\nauth_host = '"$controllerAddressOI"'\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = quantum\nadmin_password = service_pass/g' /etc/quantum/api-paste.ini
# Edit quantum.conf
  sed -i 's/\(^auth_host.*\)/#\1\nauth_host = '"$controllerAddressOI"'/g' /etc/quantum/quantum.conf
  sed -i 's/\(^admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/quantum/quantum.conf
  sed -i 's/\(^admin_user.*\)/#\1\nadmin_user = quantum/g' /etc/quantum/quantum.conf
  sed -i 's/\(^admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/quantum/quantum.conf
  service quantum-server restart

# Nova
  echo -e "$BLUE -- Nova --$NORMAL"
# Installation
  apt-get install -y nova-api nova-cert novnc nova-consoleauth nova-scheduler nova-novncproxy nova-doc nova-conductor
# Edit api-paste.ini
  sed -i 's/\(^auth_host.*\)/#\1\nauth_host = '"$controllerAddressOI"'/g' /etc/nova/api-paste.ini
  sed -i 's/\(^admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/nova/api-paste.ini
  sed -i 's/\(^admin_user.*\)/#\1\nadmin_user = nova/g' /etc/nova/api-paste.ini
  sed -i 's/\(^admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/nova/api-paste.ini
# Edit nova.conf
  sed -i 's/\(^[a-z].*\)/#\1/g' /etc/nova/nova.conf
  echo "logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/run/lock/nova
verbose=True
api_paste_config=/etc/nova/api-paste.ini
compute_scheduler_driver=nova.scheduler.simple.SimpleScheduler
rabbit_host="$controllerAddressOI"
nova_url=http://"$controllerAddressOI":8774/v1.1/
sql_connection=mysql://novaUser:novaPass@"$controllerAddressOI"/nova
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf

# Auth
use_deprecated_auth=false
auth_strategy=keystone

# Imaging service
glance_api_servers="$controllerAddressOI":9292
image_service=nova.image.glance.GlanceImageService

# Vnc configuration
novnc_enabled=true
novncproxy_base_url=http://"$controlleraAddressII":6080/vnc_auto.html
novncproxy_port=6080
vncserver_proxyclient_address="$controllerAddressOI"
vncserver_listen=0.0.0.0

# Network settings
network_api_class=nova.network.quantumv2.api.API
quantum_url=http://"$controllerAddressOI":9696
quantum_auth_strategy=keystone
quantum_admin_tenant_name=service
quantum_admin_username=quantum
quantum_admin_password=service_pass
quantum_admin_auth_url=http://"$controllerAddressOI":35357/v2.0
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver

#Metadata
service_quantum_metadata_proxy = True
quantum_metadata_proxy_shared_secret = helloOpenStack
metadata_host = "$controllerAddressOI"
metadata_listen = "$controllerAddressOI"
metadata_listen_port = 8775

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
  echo -e "$GREEN Commende nova-manage service list$NORMAL"
  nova-manage service list

# Cinder
  echo -e "$BLUE -- Cinder --$NORMAL"
# Installation
  apt-get install -y cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms
  sed -i 's/false/true/g' /etc/default/iscsitarget
  service iscsitarget start
  service open-iscsi start
# Edit api-paste.ini
  sed -i 's/\(^service_host.*\)/#\1\nservice_host = '"$controllerAddressII"'/g' /etc/cinder/api-paste.ini
  sed -i 's/\(^auth_host.*\)/#\1\nauth_host = '"$controllerAddressOI"'/g' /etc/cinder/api-paste.ini
  sed -i 's/\(^admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/cinder/api-paste.ini
  sed -i 's/\(^admin_user.*\)/#\1\nadmin_user = cinder/g' /etc/cinder/api-paste.ini
  sed -i 's/\(^admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/cinder/api-paste.ini
# Edit cinder.conf
  echo "sql_connection = mysql://cinderUser:cinderPass@"$controllerAddressOI"/cinder" >> /etc/cinder/cinder.conf
  echo "iscsi_ip_address=$controllerAddressOI" >> /etc/cinder/cinder.conf
# Sync Database
  cinder-manage db sync
  read -p "What is the disk for your Volume Group ? " diskVG
# Create PV and VG
  pvcreate $diskVG
  vgcreate cinder-volumes $diskVG
  cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i restart; done
  echo -e "$GREEN Commande to vrify all cinder services$NORMAL"
  cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i status; done
  cd $home

# Horizon
echo -e "$BLUE -- HORIZON --$NORMAL"
  apt-get install -y openstack-dashboard memcached
# Remove Ubuntu Theme
  dpkg --purge openstack-dashboard-ubuntu-theme
  service apache2 restart; service memcached restart
}

function doNetwork
{
  if [ "$(cat openstack.conf | grep "^doControllerNode.*" | grep -o "[a-z]*$")" == "true" ]
  then
    doControllerNode="true"
    contorllerInternetInterface="$(cat openstack.conf | grep "^controllerInternetInterface.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerInetII="$(cat openstack.conf | grep "^controllerInetII.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerAddressII="$(cat openstack.conf | grep "^controllerAddressII.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerNetmaskII="$(cat openstack.conf | grep "^controllerNetmaskII.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerGatewayII="$(cat openstack.conf | grep "^controllerGatewayII.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerDnsII="$(cat openstack.conf | grep "^controllerDnsII.*" | grep -o "[a-zA-Z0-9\.]*$")"
    contorllerOpenstackInterface="$(cat openstack.conf | grep "^controllerOpenstackInterface.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerInetOI="$(cat openstack.conf | grep "^controllerInetOI.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerAddressOI="$(cat openstack.conf | grep "^controllerAddressOI.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerNetmaskOI="$(cat openstack.conf | grep "^controllerNetmaskOI.*" | grep -o "[a-zA-Z0-9\.]*$")"
  fi
# Ubuntu Preparation
  if [ "$doControllerNode" != "true" ]
  then
    echo -e "$BLUE -- Preparing Ubuntu --$NORMAL"
    apt-get install -y ubuntu-cloud-keyring
    echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main >> /etc/apt/sources.list.d/grizzly.list
    apt-get update -y
    apt-get upgrade -y
    apt-get dist-upgrade -y
  fi

# Install vlan bridge
  apt-get install -y vlan bridge-utils
  sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  sysctl net.ipv4.ip_forward=1

# Networking
  echo -e "$BLUE -- Networking --$NORMAL"
# Internet Network Questions
  if [ "$doControllerNode" != "true" ]
  then
    read -p 'What is Internet Interface (Exposing Interface API) ? ' networkInternetInterface
    read -p 'Is she Static or Dynamique ? (static|dhcp) ' networkInetII
  else
    networkInternetInterface=$controllerInternetInterface
    networkInetII=$controllerInetII
  fi
  if [ "$networkInetII" = "static" ] && [ "$doControllerNode" != "true" ]
  then
    read -p 'What is address of this Interface ? ' networkAddressII
    read -p 'What is netmask of this Interface ? ' networkNetmaskII
    read -p 'What is gateway of this Interface ? ' networkGatewayII
    read -p 'What is DNS of this Interface ? ' networkDnsII
  elif [ "$networkInetII" = "static" ]
  then
    controllerGatewayII="$(cat openstack.conf | grep "^controllerGatewayII.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerDnsII="$(cat openstack.conf | grep "^controllerDnsII.*" | grep -o "[a-zA-Z0-9\.]*$")"
    networkAddressII=$controllerAddressII
    networkNetmaskII=$controllerNetmaskII
    networkGatewayII=$controllerGatewayII
    networkDnsII=$controllerDnsII
  fi
# Openstack Management Network Questions
  if [ "$doControllerNode" != "true" ]
  then
    read -p 'What is OpenStack Management Interface ? ' networkOpenstackInterface
    inetOI="static"
    read -p 'What is address of this Interface ? ' networkAddressOI
    read -p 'What is netmask of this Interface ? ' networkNetmaskOI
  else
    networkOpenstackInterface=$controllerOpenstackInterface
    networkAddressOI=$controllerAddressOI
    networkNetmaskOI=$controllerNetmaskOI
  fi
# Openstack Virtual Machine Network Questions
  read -p 'What is Virtual Machine Network Interface ? ' networkVmInterface
  networkInetVMI="static"
  read -p 'What is address of this Interface ? ' networkAddressVMI
  read -p 'What is netmask of this Interface ? ' networkNetmaskVMI
# Ask Confirmation For Change
  echo -e "$RED Your Network file will are Change$NORMAL"
  if [ "$doControllerNode" != "true" ]
  then
    askConfirmInterface $networkInternetInterface $networkInetII $networkAddressII $networkNetmaskII $networkGatewayII $networkDnsII
    askConfirmInterface $networkOpenstackInterface $networkInetOI $networkAddressOI $networkNetmaskOI
  fi
  askConfirmInterface $networkVmInterface $networkInetVMI $networkAddressVMI $networkNetmaskVMI
  read -p "Do you want to continue ? (Y/N) " write
# Write File /etc/network/interfaces if continue=Y
  if [ "$write" == "Y" ] && [ "$doControllerNode" != "true" ]
  then
    writeInterface $networkInternetInterface $networkInetII $networkAddressII $networkNetmaskII $networkGatewayII $networkDnsII "Internet Interface"
    writeInterface $networkOpenstackInterface $networkInetOI $networkAddressOI $networkNetmaskOI "OpenStack Management"
    echo "Your file was writed with new values"
  elif  [ "$write" == "Y" ]
  then
    writeInterface $networkVmInterface $networkInetVMI $networkAddressVMI $networkNetmaskVMI "VM Interface"
    echo "Your file was writed with new values"
  fi
  /etc/init.d/networking restart
  if [ "$networkInetII" == "dhcp" ]
  then
    networkAddressII=$(ifconfig $networkInternetInterface | grep -o "inet [a-zA-Z]*:[0-9][\.0-9]*[0-9]" | grep -o "[0-9][\.0-9]*[0-9]")
    networkNetmaskII=$(ifconfig $networkInternetInterface | grep -o "Mas[a-zA-Z]*:[0-9][\.0-9]*[0-9]" | grep -o "[0-9][\.0-9]*[0-9]")
  fi
echo "networkVmInterface=$networkVmInterface" >> openstack.conf
echo "networkAddressVMI=$networkAddressVMI" >> openstack.conf
echo "networkNetmaskVMI=$networkNetmaskVMI" >> openstack.conf

  if [ "$doControllerNode" != "true" ]
  then
    read -p 'What is Openstack controller management address ? ' controllerAddressOI
    controllerAddressOI=$controllerAddressOI
    echo "controllerAddressOI=$controllerAddressOI" >> .bashrc
  fi

# Install and configure ntp
  apt-get install -y ntp
  sed -i 's/server 0.ubuntu.pool.ntp.org/#server 0.ubuntu.pool.ntp.org/g' /etc/ntp.conf
  sed -i 's/server 1.ubuntu.pool.ntp.org/#server 1.ubuntu.pool.ntp.org/g' /etc/ntp.conf
  sed -i 's/server 2.ubuntu.pool.ntp.org/#server 2.ubuntu.pool.ntp.org/g' /etc/ntp.conf
  sed -i 's/server 3.ubuntu.pool.ntp.org/#server 3.ubuntu.pool.ntp.org/g' /etc/ntp.conf
  sed -i 's/server ntp.ubuntu.com/server '"$controllerAddressOI"'/g' /etc/ntp.conf
  service ntp restart

# OpenVSwitch Part 1
  echo -e "$BLUE -- OpenVSwitch Part 1 --$NORMAL"
# Installation
  apt-get install -y openvswitch-switch openvswitch-datapath-dkms
# Create Bridge
  ovs-vsctl add-br br-int
  ovs-vsctl add-br br-ex

# Quantum
  echo -e "$BLUE -- Quantum --$NORMAL"
# Installation
  apt-get -y install quantum-plugin-openvswitch-agent quantum-dhcp-agent quantum-l3-agent quantum-metadata-agent
# Edit api-paste.ini
  if [ "$doControllerNode" != "true" ]
  then
    sed -i 's/\(paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory\)/\1\nauth_host = '"$controllerAddressOI"'\nauth_port = 35357\nauth_protocol = http\nadmin_tenant_name = service\nadmin_user = quantum\nadmin_password = service_pass/g' /etc/quantum/api-paste.ini
  fi
# Edit ovs_quantum_plugin.ini
  if [ "$doControllerNode" != "true" ]
  then
    sed -i 's/^\(sql_connection.*\)/#\1\nsql_connection = mysql:\/\/quantumUser:quantumPass@'"$controllerAddressOI"'\/quantum/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i 's/\(# Example: tenant_network_type = gre\)/\1\ntenant_network_type = gre/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i 's/\(# Example: tunnel_id_ranges = 1:1000\)/\1\ntunnel_id_ranges = 1:1000/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i 's/\(# Default: enable_tunneling = False\)/\1\nenable_tunneling = True/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  fi
  sed -i 's/\(# Default: integration_bridge = br-int\)/\1\nintegration_bridge = br-int/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Default: tunnel_bridge = br-tun\)/\1\ntunnel_bridge = br-tun/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  sed -i 's/\(# Default: local_ip =\)/\1\nlocal_ip = '"$networkAddressVMI"'/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
# Edit metadata_agent.ini
  sed -i 's/\(auth_url.*\)/#\1\nauth_url = http:\/\/'"$controllerAddressOI"':35357\/v2.0/g' /etc/quantum/metadata_agent.ini
  sed -i 's/\(admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/quantum/metadata_agent.ini
  sed -i 's/\(admin_user.*\)/#\1\nadmin_user = quantum/g' /etc/quantum/metadata_agent.ini
  sed -i 's/\(admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/quantum/metadata_agent.ini
  sed -i 's/# \(nova_metadata_ip = \)127.0.0.1/\1'"$controllerAddressOI"'/g' /etc/quantum/metadata_agent.ini
  sed -i 's/# \(nova_metadata_port.*\)/\1/g' /etc/quantum/metadata_agent.ini
  sed -i 's/# \(metadata_proxy_shared_secret =\)/\1 helloOpenStack/g' /etc/quantum/metadata_agent.ini
# Edit quantum.conf
  sed -i 's/\(# rabbit_host = localhost\)/\1\nrabbit_host = '"$controllerAddressOI"'/g' /etc/quantum/quantum.conf
  if [ "$doControllerNode" != "true" ]
  then
    sed -i 's/\(^auth_host.*\)/#\1\nauth_host = '"$controllerAddressOI"'/g' /etc/quantum/quantum.conf
    sed -i 's/\(^admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/quantum/quantum.conf
    sed -i 's/\(^admin_user.*\)/#\1\nadmin_user = quantum/g' /etc/quantum/quantum.conf
    sed -i 's/\(^admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/quantum/quantum.conf
  fi
# Path of home directory
  home=$(pwd)
  cd /etc/init.d/; for i in $( ls quantum-* ); do sudo service $i restart; done
  cd $home

# OpenVSwitch part 2
echo -e "$BLUE -- OpenVSwitch Part 2 --$NORMAL"
removeInterface $networkInternetInterface
  echo '
# Internet Interface with br-ex
auto '$networkInternetInterface'
iface '$networkInternetInterface' inet manual
up ifconfig $IFACE 0.0.0.0 up
up ip link set $IFACE promisc on
down ip link set $IFACE promisc off
down ifconfig $IFACE down' >> /etc/network/interfaces
  if [ "$networkInetII" == "static" ]
  then
    echo "
# Internet Interface br-ex
auto br-ex
iface br-ex inet static
address $networkAddressII
netmask $networkNetmaskII
gateway $networkGatewayII
dns-netmask $networkDnsII" >> /etc/network/interfaces
  elif [ "$networkInetII" == "dhcp" ]
  then
    echo "
# Internet Interface br-ex
auto br-ex
iface br-ex inet dhcp" >> /etc/network/interfaces
  fi
  ovs-vsctl add-port br-ex $networkInternetInterface
  /etc/init.d/networking restart
}

function doCompute
{
  if [ "$(cat openstack.conf | grep "^doControllerNode.*" | grep -o "[a-z]*$")" == "true" ]
  then
    doControllerNode="true"
    contorllerInternetInterface="$(cat openstack.conf | grep "^controllerInternetInterface.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerInetII="$(cat openstack.conf | grep "^controllerInetII.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerAddressII="$(cat openstack.conf | grep "^controllerAddressII.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerNetmaskII="$(cat openstack.conf | grep "^controllerNetmaskII.*" | grep -o "[a-zA-Z0-9\.]*$")"
    contorllerOpenstackInterface="$(cat openstack.conf | grep "^controllerOpenstackInterface.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerInetOI="$(cat openstack.conf | grep "^controllerInetOI.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerAddressOI="$(cat openstack.conf | grep "^controllerAddressOI.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerNetmaskOI="$(cat openstack.conf | grep "^controllerNetmaskOI.*" | grep -o "[a-zA-Z0-9\.]*$")"
  fi
  if [ "$(cat openstack.conf | grep "^doNetworkNode.*" | grep -o "[a-z]*$")" == "true" ]
  then
    doNetworkNode="true"
    contorllerVmInterface="$(cat openstack.conf | grep "^controllerVmInterface.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerAddressVMI="$(cat openstack.conf | grep "^controllerAddressVMI.*" | grep -o "[a-zA-Z0-9\.]*$")"
    controllerNetmaskVMI="$(cat openstack.conf | grep "^controllerNetmaskVMI.*" | grep -o "[a-zA-Z0-9\.]*$")"
  fi


# Ubntu Preparation
  if [ "$doControllerNode" != "true" ] && [ "$doNetworkNode" != "true" ]
  then
    apt-get install -y ubuntu-cloud-keyring
    echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main >> /etc/apt/sources.list.d/grizzly.list
    apt-get update -y
    apt-get upgrade -y
    apt-get dist-upgrade -y
  fi

# Install vlan bridge
  apt-get install -y vlan bridge-utils
  sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  sysctl net.ipv4.ip_forward=1

# Networking
  echo -e "$BLUE -- Networking --$NORMAL"
# Openstack Management Network Questions
  if [ "$doControllerNode" != "true" ]
  then
    read -p 'What is OpenStack Management Interface ? ' computeOpenstackInterface
    inetOI="static"
    read -p 'What is address of this Interface ? ' computeAddressOI
    read -p 'What is netmask of this Interface ? ' computeNetmaskOI
  else
    computeOpenstackInterface=$controllerOpenstackInterface
    computeAddressOI=$controllerAddressOI
    computeNetmaskOI=$controllerNetmaskOI
  fi
# Virtual Machine Network Questions
  if [ "$doNetworkNode" != "true" ]
  then
    read -p 'What is Virtual Machine Interface ? ' computeVmInterface
    inetVMI="static"
    read -p 'What is address of this Interface ? ' computeAddressVMI
    read -p 'What is netmask of this Interface ? ' computeNetmaskVMI
  else
    computeVmInterface=$networkVmInterface
    computeAddressVMI=$networkAddressVMI
    computeNetmaskVMI=$networkNetmaskVMI
  fi
# Ask Confirmation For Change
  if [ "$doControllerNode" != "true" ]
  then
    askConfirmInterface $computeOpenstackInterface $computeInetOI $computeAddressOI $computeNetmaskOI
  fi
  if [ "$doNetworkNode" != "true" ]
  then
    askConfirmInterface $computeVmInterface $computeInetVMI $computeAddressVMI $computeNetmaskVMI
  fi
  echo -e "$RED Your Network file will are Change$NORMAL"
  read -p "Do you want to continue ? (Y/N) " write
# Write File /etc/network/interfaces if continue=Y
  if [ "$write" == "Y" ] && [ "$doControllerNode" != "true" ]
  then
    writeInterface $computeOpenstackInterface $computeInetOI $computeAddressOI $computeNetmaskOI "OpenStack Management"
  fi
  if [ "$write" == "Y" ] && [ "$doNetworkNode" != "true" ]
  then
    writeInterface $computeVmInterface $computeInetVMI $computeAddressVMI $computeNetmaskVMI "VM Interface"
  fi
  /etc/init.d/networking restart

  if [ "$doControllerNode" != "true" ] && [ "$doNetworkNode" != "true" ]
  then
    read -p 'What is Openstack controller management address ? ' controllerAddressOI
  elif [ "$doControllerNode" != "true" ]
  then
    read -p 'What is Openstack controller internet address ? ' controllerAddressII
  fi

# Install and configure ntp
  if [ "$doNetworkNode" != "true" ]
  then
    apt-get install -y ntp
    sed -i 's/server 0.ubuntu.pool.ntp.org/#server 0.ubuntu.pool.ntp.org/g' /etc/ntp.conf
    sed -i 's/server 1.ubuntu.pool.ntp.org/#server 1.ubuntu.pool.ntp.org/g' /etc/ntp.conf
    sed -i 's/server 2.ubuntu.pool.ntp.org/#server 2.ubuntu.pool.ntp.org/g' /etc/ntp.conf
    sed -i 's/server 3.ubuntu.pool.ntp.org/#server 3.ubuntu.pool.ntp.org/g' /etc/ntp.conf
    sed -i 's/server ntp.ubuntu.com/server '"$controllerAddressOI"'/g' /etc/ntp.conf
    service ntp restart
  fi

# KVM
  echo -e "$BLUE -- KVM --$NORMAL"
# Install kvv-checker
  apt-get install -y cpu-checker
  kvm-ok
# Install kvm
  apt-get install -y kvm libvirt-bin pm-utils
# configure quemu
  echo "cgroup_device_acl = [
"/dev/null", "/dev/full", "/dev/zero",
"/dev/random", "/dev/urandom",
"/dev/ptmx", "/dev/kvm", "/dev/kqemu",
"/dev/rtc", "/dev/hpet","/dev/net/tun"
]" >> /etc/libvirt/quemu.conf
# Delete Default Virtuel Bridge
  virsh net-destroy default
  virsh net-undefine default
# Enable Live Migration in /etc/libvirt/libvirtd.conf
  sed -i 's/#\(listen_tls = 0\)/\1/g' /etc/libvirt/libvirtd.conf
  sed -i 's/#\(listen_tcp = 1\)/\1/g' /etc/libvirt/libvirtd.conf
  sed -i 's/\(#auth_tcp = "sasl"\)/\1\nauth_tcp = "none"/g' /etc/libvirt/libvirtd.conf
# Edit /etc/init/libvirt-bin.conf
  sed -i 's/\(env libvirtd_opts="-d\)/\1 -l/g' /etc/init/libvirt-bin.conf
# Edit /etc/default/libvirt-bin
  sed -i 's/\(libvirtd_opts="-d\)/\1 -l/g' /etc/default/libvirt-bin
# Restart Service
  service libvirt-bin restart

# OpenVSwitch
  echo -e "$BLUE -- OpenVSwitch --$NORMAL"
# Installation
  apt-get install -y openvswitch-switch openvswitch-datapath-dkms
# Create Bridge
  if [ "$doNetworkNode" != "true" ]
  then
    ovs-vsctl add-br br-int
  fi
# Quantum
  echo -e "$BLUE -- Quantum --$NORMAL"
# Installation
  apt-get -y install quantum-plugin-openvswitch-agent
# Edit ovs_quantum_plugin.ini
  if [ "$doControllerNode" != "true" ]
  then
    read -p 'What is Openstack controller address ? ' controllerAddressOI
    sed -i 's/^\(sql_connection.*\)/#\1\nsql_connection = mysql:\/\/quantumUser:quantumPass@'"$controllerAddressOI"'\/quantum/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i 's/\(# Example: tenant_network_type = gre\)/\1\ntenant_network_type = gre/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i 's/\(# Example: tunnel_id_ranges = 1:1000\)/\1\ntunnel_id_ranges = 1:1000/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i 's/\(# Default: enable_tunneling = False\)/\1\nenable_tunneling = True/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  fi
  if [ "$doNetworkNode" != "true" ]
  then
    sed -i 's/\(# Default: integration_bridge = br-int\)/\1\nintegration_bridge = br-int/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i 's/\(# Default: tunnel_bridge = br-tun\)/\1\ntunnel_bridge = br-tun/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i 's/\(# Default: local_ip =\)/\1\nlocal_ip = '"$computeAddressOI"'/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
  fi
# Edit quantum.conf
  if [ "$doControllerNode" != "true" ]
  then
    sed -i 's/\(^auth_host.*\)/#\1\nauth_host = '"$controlelrAddressOI"'/g' /etc/quantum/quantum.conf
    sed -i 's/\(^admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/quantum/quantum.conf
    sed -i 's/\(^admin_user.*\)/#\1\nadmin_user = quantum/g' /etc/quantum/quantum.conf
    sed -i 's/\(^admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/quantum/quantum.conf
  fi
  if [ "$doNetworkNode" != "true" ]
  then
    sed -i 's/\(# rabbit_host = localhost\)/\1\nrabbit_host = '"$controllerAddressOI"'/g' /etc/quantum/quantum.conf
  fi
# Restart Service
  service quantum-plugin-openvswitch-agent restart

# Nova
  echo -e "$BLUE -- Nova --$NORMAL"
# Installation
  apt-get install -y nova-compute-kvm
# Edit api-paste.ini
  if [ "$doControllerNode" != "true" ]
  then
    sed -i 's/\(^auth_host.*\)/#\1\nauth_host = '"$controllerAddressOI"'/g' /etc/nova/api-paste.ini
    sed -i 's/\(^admin_tenant_name.*\)/#\1\nadmin_tenant_name = service/g' /etc/nova/api-paste.ini
    sed -i 's/\(^admin_user.*\)/#\1\nadmin_user = nova/g' /etc/nova/api-paste.ini
    sed -i 's/\(^admin_password.*\)/#\1\nadmin_password = service_pass/g' /etc/nova/api-paste.ini
  fi
# Edit nova-compute.conf
   sed -i 's/\(compute_driver.*\)/#\1/g' /etc/nova/nova-compute.conf
  echo "libvirt_ovs_bridge=br-int
libvirt_vif_type=ethernet
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
libvirt_use_virtio_for_bridges=True" >> /etc/nova/nova-compute.conf
# Edit nova.conf
  if [ "$doControllerNode" != "true" ]
  then
    sed -i 's/\(^[a-z].*\)/#\1/g' /etc/nova/nova.conf
    echo "logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/run/lock/nova
verbose=True
api_paste_config=/etc/nova/api-paste.ini
compute_scheduler_driver=nova.scheduler.simple.SimpleScheduler
rabbit_host=$controllerAddressOI
nova_url=http://"$controllerAddressOI":8774/v1.1/
sql_connection=mysql://novaUser:novaPass@"$controllerAddressOI"/nova
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf

# Auth
use_deprecated_auth=false
auth_strategy=keystone

# Imaging service
glance_api_servers="$controllerAddressOI":9292
image_service=nova.image.glance.GlanceImageService

# Vnc configuration
novnc_enabled=true
novncproxy_base_url=http://"$controllerAddressII":6080/vnc_auto.html
novncproxy_port=6080
vncserver_proxyclient_address=$computeAddressOI
vncserver_listen=0.0.0.0

# Network settings
network_api_class=nova.network.quantumv2.api.API
quantum_url=http://"$controllerAddressOI":9696
quantum_auth_strategy=keystone
quantum_admin_tenant_name=service
quantum_admin_username=quantum
quantum_admin_password=service_pass
quantum_admin_auth_url=http://"$controllerAddressOI":35357/v2.0
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver

#Metadata
service_quantum_metadata_proxy = True
quantum_metadata_proxy_shared_secret = helloOpenStack
metadata_host = "$controllerAddressOI"
metadata_listen = "$controllerAddressOI"
metadata_listen_port = 8775

# Compute #
compute_driver=libvirt.LibvirtDriver

# Cinder #
volume_api_class=nova.volume.cinder.API
osapi_volume_listen_port=5900" >> /etc/nova/nova.conf
  fi
  echo "cinder_catalog_info=volume:cinder:internalURL" >> /etc/nova/nova.conf
  home=$(pwd)
# Restart Service
  cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done
  cd $home
  nova-manage service list
}

# Ask what node he want install
node=""

read -p 'Do you whant to install Controller node ? (Y/N) ' controllerNode

if [ "$controllerNode" == "Y" ]
then
  doControllerNode="true"
  echo "doControllerNode=true" >> openstack.conf
  doController
fi

read -p 'Do you whant to install Network node ? (Y/N) ' networkNode

if [ "$networkNode" == "Y" ]
then
  doNetworkNode="true"
  echo "doNetworkNode=true" >> openstack.conf
  doNetwork
fi

read -p 'Do you whant to install Conpute node ? (Y/N) ' computeNode

if [ "$computeNode" == "Y" ]
then
  doComputeNode="true"
  echo "doComputeNode=true" >> openstack.conf
  doCompute
fi
