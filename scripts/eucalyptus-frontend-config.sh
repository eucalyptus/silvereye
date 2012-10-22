#!/bin/bash
#
# Copyright (c) 2012  Eucalyptus Systems, Inc.
#  
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, only version 3 of the License.
#  
#  
#   This file is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#  
#   You should have received a copy of the GNU General Public License along
#   with this program.  If not, see <http://www.gnu.org/licenses/>.
#  
#   Please contact Eucalyptus Systems, Inc., 6755 Hollister Ave.
#   Goleta, CA 93117 USA or visit <http://www.eucalyptus.com/licenses/>
#   if you need additional information or have any questions.
#  

# Adding a spinner function, thanks to Louis Marascio for the snippet:
# http://fitnr.com/showing-a-bash-spinner.html

spinner()
{
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# We need a default cluster name for registration
export CLUSTER_NAME=cluster01

# Set log file destination
export LOGFILE=/var/log/eucalyptus-frontend-config.log

# Set ELVERSION
export ELVERSION=`cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/'`

# Set CIAB to Y for single server clouds
rpm -q eucalyptus-nc > /dev/null
if [ $? -eq 1 ] ; then
  export CIAB="N"
else
  export CIAB="Y"
fi

# Error checking function
function error_check {
  count=`grep -i 'error\|fail\|exception' $LOGFILE|grep -v 'libgpg-error'|wc -l`
  if [ $count -gt "0" ]
  then
    echo "An error occured in the last step, look at $LOGFILE for more details"
    exit -1;
  fi
}

# Function for editing eucalyptus.conf properties
# params: prop_name, prompt, file, optional-regex
function edit_prop {
  prop_line=`grep $1 $3|tail -1`
  prop_value=`echo $prop_line |cut -d '=' -f 2|tr -d "\""`
  new_value=$prop_value
  done="n"
  while [ $done = "n" ]
  do
    read -p "$2 [$prop_value] " value
    if [ $value ]
    then
      if [ $4 ]
      then
            if [ `echo $value |grep $4` ]
            then
          new_value=$value
            else
              echo \"$value\" doesn\'t match the pattern, please refer to the previous value for input format.
            fi
      else
        new_value=$value
      fi
      if [ $new_value = $value ]
      then
        sed -i.bak "s/$1=\"$prop_value\"/$1=\"$new_value\"/g" $3
                done="y"
      fi
        else
          done="y"
    fi
  done
}

# Function for configuring the Eucalyptus frontend
function configure_frontend {
# Save old log file
if [ -f $LOGFILE ]
then
  if [ -f $LOGFILE.bak ]
  then
    rm $LOGFILE.bak
  fi
  mv $LOGFILE $LOGFILE.bak
  touch $LOGFILE
fi

# Use network service instead of NetworkManager to manage networking
sed -i -e 's/NM_CONTROLLED=yes/NM_CONTROLLED=no/' /etc/sysconfig/network-scripts/ifcfg-*

# Set VNET_PUBINTERFACE and VNET_PRIVINTERFACE with default values if the
# current values don't have IP addresses assigned to them
DEFAULTROUTEINTERFACE=`route -n | grep '^0.0.0.0' | awk '{ print $NF }'`
EUCACONF_PUBINTERFACE=`grep '^VNET_PUBINTERFACE' /etc/eucalyptus/eucalyptus.conf | sed -e 's/VNET_PUBINTERFACE=\"\(.*\)\"/\1/'`
EUCACONF_PRIVINTERFACE=`grep '^VNET_PRIVINTERFACE' /etc/eucalyptus/eucalyptus.conf | sed -e 's/VNET_PRIVINTERFACE=\"\(.*\)\"/\1/'`
EUCACONF_PUBINTERFACEIPS=`ip addr | grep inet | grep $EUCACONF_PUBINTERFACE | wc -l`
EUCACONF_PRIVINTERFACEIPS=`ip addr | grep inet | grep $EUCACONF_PRIVINTERFACE | wc -l`
if [ $EUCACONF_PUBINTERFACEIPS -eq 0 ] ; then
  sed -i -e "s/^VNET_PUBINTERFACE.*$/VNET_PUBINTERFACE=\"$DEFAULTROUTEINTERFACE\"/" /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
fi
if [ $EUCACONF_PRIVINTERFACEIPS -eq 0 ] ; then
  sed -i -e "s/^VNET_PRIVINTERFACE.*$/VNET_PRIVINTERFACE=\"$DEFAULTROUTEINTERFACE\"/" /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
fi

# Set clock and enable ntpd service
echo ""
echo "It is important that time is synchronized across your Eucalyptus infrastructure."
echo ""
echo "The recommended way to ensure time remains synchronized is to enable the NTP"
echo "service, which synchronizes time with Internet servers."
echo ""
echo "If your systems have Internet access, and you would like to use NTP to"
echo "synchronize their clocks with the default pool.ntp.org servers, please answer"
echo "yes."
echo ""
while ! echo "$ENABLENTPSYNC" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
  ENABLENTPSYNC="Yes"
  read -p "Would you like to enable NTP and synchronize clock? [$ENABLENTPSYNC] " enable_ntp_sync
  if [ $enable_ntp_sync ] 
  then
    ENABLENTPSYNC=$enable_ntp_sync
  fi
  case "$ENABLENTPSYNC" in
  y|Y|yes|YES|Yes)
    echo "$(date)- Setting clock via NTP.  This may take a few minutes." | tee -a $LOGFILE
    if [ -f /var/run/ntpd.pid ] ; then
      service ntpd stop
    fi
    (`which ntpd` -q -g >>$LOGFILE 2>&1) & 
    spinner $!
    hwclock --systohc >>$LOGFILE 2>&1
    chkconfig ntpd on >>$LOGFILE 2>&1
    service ntpd start >>$LOGFILE 2>&1
    error_check
    echo "$(date)- Set clock and enabled ntp" | tee -a $LOGFILE
    ;;
  n|N|no|NO|No)
    echo "$(date)- Skipped NTP configuration and syncrhonization." | tee -a $LOGFILE
    ;;
  *)
    echo "Please answer either 'yes' or 'no'."
    ;;
  esac
done
echo ""

# Create a bridge interface and configure networking for single server clouds
if [ $CIAB = "Y" ] ; then
  # Set NC_HYPERVISOR
  case "$ELVERSION" in
  "5")
    NC_HYPERVISOR="xen"
  ;;
  "6")
    NC_HYPERVISOR="kvm"
  ;;
  esac
  # Edit the default eucalyptus.conf
  sed -i -e "s/.*HYPERVISOR=\".*\"/HYPERVISOR=\"$NC_HYPERVISOR\"/" /etc/eucalyptus/eucalyptus.conf
  sed --in-place 's/^VNET_MODE="SYSTEM"/#VNET_MODE="SYSTEM"/' /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
  # Disable dnsmasq and ZEROCONF
  service dnsmasq stop
  chkconfig dnsmasq off
  rm -f /etc/libvirt/qemu/networks/autostart/*
  if ! grep -E '(^NOZEROCONF)' /etc/sysconfig/network > /dev/null
  then
    echo "NOZEROCONF=true" >> /etc/sysconfig/network
  else
    sed -i -e 's/NOZEROCONF=.*/NOZEROCONF=true/' /etc/sysconfig/network
  fi
  # Try to guess/set some apprpriate network settings for the virtual networks
  echo "The single server configuration requires two virtual networks to function."
  echo ""
  echo "The addresses for these networks should not be in use on the rest of your network."
  echo ""
  if ! route -n | grep -E '^[[:digit:]]' | awk '{print $1}' | grep -E '^172\.' ; then
    CIABBRIDGESUBNET="172.31.254.0"
    CIABVNETSUBNET="172.31.252.0"
    CIABBRIDGENETMASK="255.255.254.0"
    CIABVNETNETMASK="255.255.254.0"
  elif ! route -n | grep -E '^[[:digit:]]' | awk '{print $1}' | grep -E '^192\.' ; then
    CIABBRIDGESUBNET="192.168.254.0"
    CIABVNETSUBNET="192.168.252.0"
    CIABBRIDGENETMASK="255.255.254.0"
    CIABVNETNETMASK="255.255.254.0"
  elif ! route -n | grep -E '^[[:digit:]]' | awk '{print $1}' | grep -E '^10\.' ; then
    CIABBRIDGESUBNET="10.255.254.0"
    CIABVNETSUBNET="10.255.252.0"
    CIABBRIDGENETMASK="255.255.254.0"
    CIABVNETNETMASK="255.255.254.0"
  else
    CIABBRIDGESUBNET="###.###.###.###"
    CIABVNETSUBNET="###.###.###.###"
    CIABBRIDGENETMASK="###.###.###.###"
    CIABVNETNETMASK="###.###.###.###"
  fi
  case "$CIABBRIDGESUBNET" in
  "###.###.###.###")
    echo "The configuration script was unable to determine suitable networks to suggest."
    echo ""
    CHANGECIABNETWORKS="Yes"
    ;;
  *)
    CHANGECIABNETWORKS="No"
    echo "Local Bridge subnet: $CIABBRIDGESUBNET"
    echo "Local Bridge netmask: $CIABBRIDGENETMASK"
    echo "Eucalyptus VNET_SUBNET: $CIABVNETSUBNET"
    echo "Eucalyptus VNET_NETMASK: $CIABVNETNETMASK"
    echo ""
    read -p "Would you like to change these virtual network addresses? [$CHANGECIABNETWORKS] " change_ciab_networks
    if [ $change_ciab_networks ]
    then
      export CHANGECIABNETWORKS=$change_ciab_networks
    fi
    ;;
  esac
  while ! echo "$CHANGECIABNETWORKS" | grep -iE '(^n$|^no$)' > /dev/null ; do
    read -p "Local Bridge Subnet [$CIABBRIDGESUBNET] " ciab_bridge_subnet
    if [ $ciab_bridge_subnet ]
    then
      export CIABBRIDGESUBNET=$ciab_bridge_subnet
    fi
    read -p "Local Bridge netmask [$CIABBRIDGENETMASK] " ciab_bridge_netmask
    if [ $ciab_bridge_netmask ]
    then
      export CIABBRIDGENETMASK=$ciab_bridge_netmask
    fi
    read -p "Eucalyptus VNET_SUBNET [$CIABVNETSUBNET] " ciab_vnet_subnet
    if [ $ciab_vnet_subnet ]
    then
      export CIABVNETSUBNET=$ciab_vnet_subnet
    fi
    read -p "Eucalyptus VNET_NETMASK [$CIABVNETNETMASK] " ciab_vnet_netmask
    if [ $ciab_vnet_netmask ]
    then
      export CIABVNETNETMASK=$ciab_vnet_netmask
    fi
    CHANGECIABNETWORKS="N"
    echo "Local Bridge subnet: $CIABBRIDGESUBNET"
    echo "Local Bridge netmask: $CIABBRIDGENETMASK"
    echo "Eucalyptus VNET_SUBNET: $CIABVNETSUBNET"
    echo "Eucalyptus VNET_NETMASK: $CIABVNETNETMASK"
    echo ""
    read -p "Would you like to change these virtual network addresses? [$CHANGECIABNETWORKS] " change_ciab_networks
    if [ $change_ciab_networks ]
    then
      export CHANGECIABNETWORKS=$change_ciab_networks
    fi
  done
  CIABBRIDGEIP=`echo ${CIABBRIDGESUBNET} | sed -e 's/\.0$/.1/g'`
  # Make some configuration changes based on user input and OS version
  case "$ELVERSION" in
  "5")
    cat > /etc/sysconfig/network-scripts/ifcfg-xenbr0 <<EOF
DEVICE=xenbr0
ONBOOT=yes
TYPE=Bridge
BOOTPROTO=none
NM_CONTROLLED=no
EOF
    echo "NETWORK=${CIABBRIDGESUBNET}" >> /etc/sysconfig/network-scripts/ifcfg-xenbr0
    echo "NETMASK=${CIABBRIDGENETMASK}" >> /etc/sysconfig/network-scripts/ifcfg-xenbr0
    echo "IPADDR=${CIABBRIDGEIP}" >> /etc/sysconfig/network-scripts/ifcfg-xenbr0
    echo 'VNET_MODE="MANAGED-NOVLAN"' >> /etc/eucalyptus/eucalyptus.conf
    echo "VNET_SUBNET=\"${CIABVNETSUBNET}\"" >> /etc/eucalyptus/eucalyptus.conf 
    echo "VNET_NETMASK=\"${CIABVNETNETMASK}\"" >> /etc/eucalyptus/eucalyptus.conf
    echo 'VNET_ADDRSPERNET="32"' >> /etc/eucalyptus/eucalyptus.conf
    sed -i -e "s/^VNET_PRIVINTERFACE.*$/VNET_PRIVINTERFACE=\"xenbr0\"/" /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
    service network restart >>$LOGFILE 2>&1
    NC_PUBINTERFACE="xenbr0"
    NC_BRIDGE="xenbr0"
    sed -i -e "s/.*VNET_BRIDGE=\".*\"/VNET_BRIDGE=\"$NC_BRIDGE\"/" /etc/eucalyptus/eucalyptus.conf
    # Edit the xen configuration files
    echo "$(date) - Configuring xen" | tee -a $LOGFILE
    sed -i -e "s/.*(xend-http-server .*/(xend-http-server yes)/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
    sed -i -e "s/.*(xend-address localhost)/(xend-address localhost)/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
    sed -i -e "s#^(network-script network-bridge)#(network-script /bin/true)#" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
    sed -i -e "s/^(xend-relocation-hosts-allow/#(xend-relocation-hosts-allow/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
    sed -i -e "s/(dom0-min-mem 256)/(dom0-min-mem 196)/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
    sed -i -e "s/.*XENCONSOLED_LOG_GUESTS.*/XENCONSOLED_LOG_GUESTS=yes/" /etc/sysconfig/xend >>$LOGFILE 2>&1
    service xend restart >>$LOGFILE 2>&1
    error_check
    echo "$(date) - Customized xen configuration" | tee -a $LOGFILE
    # Edit the libvirt.conf file
    echo "$(date) - Configuring libvirt " | tee -a $LOGFILE
    sed -i -e 's/.*unix_sock_group.*/unix_sock_group = "eucalyptus"/' /etc/libvirt/libvirtd.conf >>$LOGFILE 2>&1
    sed -i -e 's/.*unix_sock_ro_perms.*/unix_sock_ro_perms = "0777"/' /etc/libvirt/libvirtd.conf >>$LOGFILE 2>&1
    sed -i -e 's/.*unix_sock_rw_perms.*/unix_sock_rw_perms = "0770"/' /etc/libvirt/libvirtd.conf >>$LOGFILE 2>&1
    service libvirtd restart  >>$LOGFILE 2>&1
    error_check
    echo "$(date) - Customized libvirt configuration" | tee -a $LOGFILE
    # Enable 256 loop devices
    if [ ! -f /etc/modprobe.d/eucalyptus-loop ] ; then
      echo "options loop max_loop=256" > /etc/modprobe.d/eucalyptus-loop
      if lsmod | grep ^loop ; then
        rmmod loop
      fi
      modprobe loop
      echo "$(date) - Loop module customized" | tee -a $LOGFILE
    else
      echo "$(date) - Loop module already customized" | tee -a $LOGFILE
    fi
  ;;
  "6")
    cat > /etc/sysconfig/network-scripts/ifcfg-br0 <<EOF
DEVICE=br0
ONBOOT=yes
TYPE=Bridge
BOOTPROTO=none
NM_CONTROLLED=no
EOF
    echo "NETWORK=${CIABBRIDGESUBNET}" >> /etc/sysconfig/network-scripts/ifcfg-br0
    echo "NETMASK=${CIABBRIDGENETMASK}" >> /etc/sysconfig/network-scripts/ifcfg-br0
    echo "IPADDR=${CIABBRIDGEIP}" >> /etc/sysconfig/network-scripts/ifcfg-br0
    echo 'VNET_MODE="MANAGED-NOVLAN"' >> /etc/eucalyptus/eucalyptus.conf
    echo "VNET_SUBNET=\"${CIABVNETSUBNET}\"" >> /etc/eucalyptus/eucalyptus.conf 
    echo "VNET_NETMASK=\"${CIABVNETNETMASK}\"" >> /etc/eucalyptus/eucalyptus.conf
    echo 'VNET_ADDRSPERNET="32"' >> /etc/eucalyptus/eucalyptus.conf
    sed -i -e "s/^VNET_PRIVINTERFACE.*$/VNET_PRIVINTERFACE=\"br0\"/" /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
    service network restart >>$LOGFILE 2>&1
    NC_PUBINTERFACE="br0"
    NC_BRIDGE="br0"
    sed -i -e "s/.*VNET_BRIDGE=\".*\"/VNET_BRIDGE=\"$NC_BRIDGE\"/" /etc/eucalyptus/eucalyptus.conf
    sed -i -e "s/#CREATE_NC_LOOP_DEVICES.*/CREATE_NC_LOOP_DEVICES=256/" /etc/eucalyptus/eucalyptus.conf
    error_check
    # Modify /etc/hosts if hostname is not resolvable
    ping -c 1 `hostname` > /dev/null
    if [ $? -ne 0 ] ; then
      NC_PUB_IP_ADDRESS=`ip addr show $NC_BRIDGE |grep inet |grep global|awk -F"[\t /]*" '{ print $3 }'`
      NC_HOSTNAME=`hostname`
      NC_SHORTHOSTNAME=`hostname | cut -d. -f1`
      if [ $NC_HOSTNAME = $NC_SHORTHOSTNAME ] ; then
        echo "$NC_PUB_IP_ADDRESS ${NC_HOSTNAME}" >> /etc/hosts
      else
        echo "$NC_PUB_IP_ADDRESS ${NC_HOSTNAME} ${NC_SHORTHOSTNAME}" >> /etc/hosts
      fi
    fi
    error_check
  ;;
  esac
  # Start and configure eucalyptus-nc service
  /etc/init.d/eucalyptus-nc start >>$LOGFILE 2>&1
  error_check
  /sbin/chkconfig eucalyptus-nc on >>$LOGFILE 2>&1
  error_check
fi

# Generate root's SSH keys if they aren't already present
if [ ! -f /root/.ssh/id_rsa ]
then
  ssh-keygen -N "" -f /root/.ssh/id_rsa >>$LOGFILE 2>&1
  echo "$(date)- Generated root's SSH keys" | tee -a $LOGFILE
else
  echo "$(date)- root's SSH keys already exist" | tee -a $LOGFILE
fi
SSH_HOSTNAME=`hostname`
if ! grep "root@${SSH_HOSTNAME}" /root/.ssh/authorized_keys > /dev/null 2>&1
then
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  echo "$(date)- Appended root's public key to authorized_keys" | tee -a $LOGFILE
else
  echo "$(date)- root's public key already present in authorized_keys" | tee -a $LOGFILE
fi

# populate the SSH known_hosts file
for FEIP in `ip addr show |grep inet |grep global|awk -F"[\t /]*" '{ print $3 }'` ; do
  ssh -o StrictHostKeyChecking=no $FEIP "true" > /dev/null 2>&1
done

# Edit the default eucalyptus.conf, insert default values if no previous
# configuration is present
if ! grep -E '(^VNET_MODE)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  echo 'VNET_MODE="MANAGED-NOVLAN"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_SUBNET)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  echo 'VNET_SUBNET="172.16.0.0"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_NETMASK)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  echo 'VNET_NETMASK="255.255.0.0"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_DNS)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  PRIMARY_DNS=`grep nameserver /etc/resolv.conf | head -n1 | awk '{print $2}'`
  echo "VNET_DNS=\"$PRIMARY_DNS\"" >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_ADDRSPERNET)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  echo 'VNET_ADDRSPERNET="64"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_PUBLICIPS)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  echo 'VNET_PUBLICIPS="###.###.###.###-###.###.###.###"' >> /etc/eucalyptus/eucalyptus.conf
fi

# Gather information from the user, and perform eucalyptus.conf property edits
echo ""
echo "We need some network information"
echo ""
EUCACONFIG=/etc/eucalyptus/eucalyptus.conf
if [ $CIAB = "N" ] ; then
  edit_prop VNET_MODE "Which Eucalyptus networking mode would you like to use? " $EUCACONFIG
  edit_prop VNET_PUBINTERFACE "The public ethernet interface" $EUCACONFIG
  edit_prop VNET_PRIVINTERFACE "The private ethernet interface" $EUCACONFIG
  edit_prop VNET_DNS "The DNS server address" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"
  edit_prop VNET_SUBNET "Eucalyptus-only dedicated subnet" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"
  edit_prop VNET_NETMASK "Eucalyptus subnet netmask" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"
  SUBNET_VAL=`grep VNET_NETMASK $EUCACONFIG|tail -1|cut -d '=' -f 2|tr -d "\""`
  ZERO_OCTETS=`echo $SUBNET_VAL |tr "." "\n" |grep 0 |wc -l`
  ADDRSPER_REC=32
  if [ $ZERO_OCTETS -eq 3 ]     # class A subnet
  then
    ADDRSPER_REC=128
  elif [ $ZERO_OCTETS -eq 2 ] # class B subnet
  then
    ADDRSPER_REC=64
  elif [ $ZERO_OCTETS -eq 1 ] # class C subnet
  then
    ADDRSPER_REC=32
  fi
  echo "Based on the size of your private subnet, we recommend the next value be set to $ADDRSPER_REC"
  sed --in-place "s/VNET_ADDRSPERNET=\"32\"/VNET_ADDRSPERNET=\"${ADDRSPER_REC}\"/" /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
  edit_prop VNET_ADDRSPERNET "How many addresses per net?" $EUCACONFIG "[0-9]*"
fi
echo ""
echo "The range of public IP addresses should be two IP adresses on the public"
echo "network separated by a - (e.g. '192.168.1.10-192.168.1.50')"
echo "Other public IP address configurations are possible by manually editing your"
echo "configuration later.  Please read the notes in /etc/eucalyptus/eucalyptus.conf"
edit_prop VNET_PUBLICIPS "The range of public IP addresses" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}-[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"

# If we are running in MANAGED mode, make sure that our private interface is a bridge
if grep -E '^VNET_MODE="MANAGED"$' /etc/eucalyptus/eucalyptus.conf ; then
  # configure bridge
  EUCACONF_PRIVINTERFACE=`grep '^VNET_PRIVINTERFACE' /etc/eucalyptus/eucalyptus.conf | sed -e 's/VNET_PRIVINTERFACE=\"\(.*\)\"/\1/'`
  brctl show | grep ^${EUCACONF_PRIVINTERFACE}
  if [ $? -ne 0 ] ; then
    FE_BRIDGE="br0"
    sed -i -e "s/^VNET_PRIVINTERFACE=\".*\"/VNET_PRIVINTERFACE=\"$FE_BRIDGE\"/" /etc/eucalyptus/eucalyptus.conf
    error_check
    brctl show | grep ^${FE_BRIDGE}
    if [ $? -ne 0 ] ; then
      echo "$(date) - Creating bridge $FE_BRIDGE on $EUCACONF_PRIVINTERFACE" | tee -a $LOGFILE
      if [ ! -f /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE} ] ; then
        cp /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE} /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE}
        sed -i -e "s/DEVICE=${EUCACONF_PRIVINTERFACE}/DEVICE=${FE_BRIDGE}/" /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE}
        sed -i -e '/HWADDR=/d' /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE}
        sed -i -e 's/TYPE=Ethernet/TYPE=Bridge/g' /etc/sysconfig/network-scripts/ifcfg-${NFEBRIDGE}
        if ! grep -E 'TYPE' /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE} ; then
          echo "TYPE=Bridge" >> /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE}
        fi
        if ! grep -E 'DELAY' /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE} ; then
          echo "DELAY=0" >> /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE}
        fi
        if ! grep -E '^NM_CONTROLLED=' /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE} > /dev/null ; then
          echo 'NM_CONTROLLED=no' >> /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE}
        else
          sed -i -e 's/NM_CONTROLLED=.*/NM_CONTROLLED=no/' /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE}
        fi
        if ! grep -E '^ONBOOT=' /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE} > /dev/null ; then
          echo 'ONBOOT=yes' >> /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE}
        else
          sed -i -e 's/ONBOOT=.*/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-${FE_BRIDGE}
        fi
        if ! grep -E "BRIDGE=${FE_BRIDGE}" /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE} > /dev/null ; then
          echo "BRIDGE=${FE_BRIDGE}" >> /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE}
        fi
        sed -i -e '/BOOTPROTO/d' /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE}
        sed -i -e '/IPADDR/d' /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE}
        sed -i -e '/NETMASK/d' /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE}
        if ! grep -E '^NM_CONTROLLED=' /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE} > /dev/null ; then
          echo 'NM_CONTROLLED=no' >> /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE}
        else
          sed -i -e 's/NM_CONTROLLED=.*/NM_CONTROLLED=no/' /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE}
        fi
        if ! grep -E '^ONBOOT=' /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE} > /dev/null ; then
          echo 'ONBOOT=yes' >> /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE}
        else
          sed -i -e 's/ONBOOT=.*/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-${EUCACONF_PRIVINTERFACE}
        fi
      fi
      chkconfig network on
      service network restart
      error_check
    fi
  fi
fi

# Set up loop device settings
case "$ELVERSION" in
"5")
  # Enable 256 loop devices
  echo "options loop max_loop=256" > /etc/modprobe.d/eucalyptus-loop
  if lsmod | grep ^loop ; then
    rmmod loop
  fi
  modprobe loop
  ;;
"6")
  sed -i -e "s/#CREATE_SC_LOOP_DEVICES.*/CREATE_SC_LOOP_DEVICES=256/" /etc/eucalyptus/eucalyptus.conf
  ;;
esac

# Modify /etc/hosts if hostname is not resolvable
ping -c 1 `hostname` > /dev/null
if [ $? -ne 0 ] ; then
  EUCACONF_PUBINTERFACE=`grep '^VNET_PUBINTERFACE' /etc/eucalyptus/eucalyptus.conf | sed -e 's/VNET_PUBINTERFACE=\"\(.*\)\"/\1/'`
  CLOUD_PUBLIC_IP_ADDRESS=`ip addr show $EUCACONF_PUBINTERFACE |grep inet |grep ${EUCACONF_PUBINTERFACE}\$|grep global|awk -F"[\t /]*" '{ print $3 }'`
  CLOUD_HOSTNAME=`hostname`
  CLOUD_SHORTHOSTNAME=`hostname | cut -d. -f1`
  if [ $CLOUD_HOSTNAME = $CLOUD_SHORTHOSTNAME ] ; then
    echo "$CLOUD_PUBLIC_IP_ADDRESS ${CLOUD_HOSTNAME}" >> /etc/hosts
  else
    echo "$CLOUD_PUBLIC_IP_ADDRESS ${CLOUD_HOSTNAME} ${CLOUD_SHORTHOSTNAME}" >> /etc/hosts
  fi
fi

# Initialize the CLC if there is no existing cloud-cert.pem
if [ ! -f /var/lib/eucalyptus/keys/cloud-cert.pem ] ; then
  echo "$(date)- Initializing Cloud Controller " | tee -a $LOGFILE
  (/usr/sbin/euca_conf --initialize) &
  spinner $!
fi

# Start Eucalyptus services prior to registration
echo ""
echo "$(date)- Starting services " | tee -a $LOGFILE
if [ ! -f /var/run/eucalyptus/eucalyptus-cloud.pid ] ; then
  service eucalyptus-cloud start >> $LOGFILE 2>&1
fi
/sbin/chkconfig eucalyptus-cloud on >>$LOGFILE 2>&1
if [ ! -f /var/run/eucalyptus/eucalyptus-cc.pid ] ; then
  retries=0
  curl http://localhost:8443/ >/dev/null 2>&1
  while [ $? -ne 0 ] ; do
    # Wait for CLC to start
    echo "Waiting for cloud controller to finish starting"
    sleep 10
    retries=$(($retries + 1))
    if [ $retries -eq 30 ] ; then # this waits for 5 minutes
      fail=true
      break
    fi
    curl http://localhost:8443/ >/dev/null 2>&1
  done
  if [ $fail ] ; then
    echo "$(date)- Cloud controller failed to start after 5 minutes. Check in /var/log/eucalyptus/startup.log" |tee -a $LOGFILE
  fi
  service eucalyptus-cc start >> $LOGFILE 2>&1
else
  service eucalyptus-cc restart >> $LOGFILE 2>&1
fi
/sbin/chkconfig eucalyptus-cc on >> $LOGFILE 2>&1
error_check
echo "$(date)- Started services " | tee -a $LOGFILE

# Prepare to register components
echo "$(date)- Registering components " | tee -a $LOGFILE
retries=0
curl http://localhost:8443/ >/dev/null 2>&1
while [ $? -ne 0 ] ; do
  echo "Waiting for cloud controller to finish starting"
    sleep 10
    retries=$(($retries + 1))
    if [ $retries -eq 30 ] ; then # this waits for 5 minutes
      fail=true
      break
    fi
    curl http://localhost:8443/ >/dev/null 2>&1
done
if [ $fail ] ; then
  echo "$(date)- Cloud controller failed to start after 5 minutes. Check in /var/log/eucalyptus/startup.log" |tee -a $LOGFILE
fi
export PUBLIC_INTERFACE=`grep -E '^VNET_PUBINTERFACE=' /etc/eucalyptus/eucalyptus.conf | cut -d\" -f2`
export PRIVATE_INTERFACE=`grep -E '^VNET_PRIVINTERFACE=' /etc/eucalyptus/eucalyptus.conf | cut -d\" -f2`
export PUBLIC_IP_ADDRESS=`ip addr show $PUBLIC_INTERFACE |grep inet |grep global|awk -F"[\t /]*" '{ print $3 }'`
export PRIVATE_IP_ADDRESS=`ip addr show $PRIVATE_INTERFACE |grep inet |grep global|awk -F"[\t /]*" '{ print $3 }'`
# Prompt for ip confirm
if [ $CIAB = "N" ] ; then
  echo ""
  read -p "Public IP for Cloud Controller, Walrus, and Cluster Controller [$PUBLIC_IP_ADDRESS] " public_ip
  read -p "Private IP for Storage Controller [$PRIVATE_IP_ADDRESS] " private_ip
  if [ $public_ip ]
  then
    export PUBLIC_IP_ADDRESS=$public_ip
  fi
  if [ $private_ip ]
  then
    export PRIVATE_IP_ADDRESS=$private_ip
  fi
fi
echo ""
echo "Using public IP $PUBLIC_IP_ADDRESS and private IP $PRIVATE_IP_ADDRESS to" | tee -a $LOGFILE
echo "register components" | tee -a $LOGFILE

# Register Walrus
if [ `/usr/sbin/euca_conf --list-walruses 2>/dev/null |wc -l` -eq 0 ]
then
  /usr/sbin/euca_conf --register-walrus --partition walrus --host $PUBLIC_IP_ADDRESS --component=walrus >>$LOGFILE 2>&1 
  echo "$(date)- Registered Walrus at $PUBLIC_IP_ADDRESS" | tee -a $LOGFILE
else
  echo "$(date)- Walrus already registered. Will not re-register walrus" | tee -a $LOGFILE
fi

# Deregister previous SCs and clusters
for OLDSCIP in `/usr/sbin/euca_conf --list-scs 2>/dev/null|awk '{print $4}'`
do
  OLDSCPARTITION=`/usr/sbin/euca_conf --list-scs|awk '{print $2}'`
  OLDSCCOMPONENT=`/usr/sbin/euca_conf --list-scs|awk '{print $3}'`
  /usr/sbin/euca_conf --deregister-sc --partition ${OLDSCPARTITION} --host ${OLDSCIP} --component=${OLDSCCOMPONENT} >>$LOGFILE 2>&1
done
for OLDCCIP in `/usr/sbin/euca_conf --list-clusters 2>/dev/null|awk '{print $4}'`
do
  OLDCCPARTITION=`/usr/sbin/euca_conf --list-clusters|awk '{print $2}'`
  OLDCCCOMPONENT=`/usr/sbin/euca_conf --list-clusters|awk '{print $3}'`
  /usr/sbin/euca_conf --deregister-cluster --partition ${OLDCCPARTITION} --host ${OLDCCIP} --component=${OLDCCCOMPONENT} >>$LOGFILE 2>&1
done

# Now register clusters and SCs
/usr/sbin/euca_conf --register-cluster --partition $CLUSTER_NAME --host $PUBLIC_IP_ADDRESS --component=cc_01 >>$LOGFILE 2>&1
echo "$(date)- Registered Cluster Controller at $PUBLIC_IP_ADDRESS" | tee -a $LOGFILE
/usr/sbin/euca_conf --register-sc --partition $CLUSTER_NAME --host $PRIVATE_IP_ADDRESS --component=sc_01 >>$LOGFILE 2>&1
echo "$(date)- Registered Storage Controller at $PRIVATE_IP_ADDRESS" | tee -a $LOGFILE
error_check

# Deregister previous node controllers
for NCIP in `/usr/sbin/euca_conf --list-nodes 2>/dev/null | awk '{print $2}'`
do
  /usr/sbin/euca_conf --deregister-nodes $NCIP >>$LOGFILE 2>&1
done

# Register node controllers
if [ $CIAB = "N" ] ; then
  echo ""
  echo "Ready to register node controllers. Once they are installed, enter their IP"
  echo "addresses here, one by one (ENTER when done)"
  done="not"
  while [ $done != "done" ]
  do
    echo ""
    read -p "Node IP (ENTER when done): " node
    echo ""
    if [ ! $node ]
    then
      done="done"
      echo "To register node controllers in the future, please run:"
      echo '/usr/sbin/euca_conf --register-nodes "host host ..."'
    else
      echo "Please enter the root password of the node controller when prompted"
      echo ""
      cat /root/.ssh/id_rsa.pub | ssh ${node} "umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys; test -x /sbin/restorecon && /sbin/restorecon .ssh .ssh/authorized_keys" || exit 1
      /usr/sbin/euca_conf --register-nodes $node >>$LOGFILE 2>&1
      echo "$(date)- Registered Node Controller at $node" | tee -a $LOGFILE
    fi
  done
else
  /usr/sbin/euca_conf --register-nodes $CIABBRIDGEIP >>$LOGFILE 2>&1
  echo "$(date)- Registered Node Controller at $CIABBRIDGEIP" | tee -a $LOGFILE
fi
error_check
echo ""
echo "$(date)- Registered components" | tee -a $LOGFILE
echo ""
}

# Function to retrieve cloud admin credentials
function get_credentials {
  if [ ! -f /root/credentials/admin/eucarc ] ; then
    mkdir -p /root/credentials/admin | tee -a $LOGFILE
    cd /root/credentials/admin
    euca_conf --get-credentials admin.zip >>$LOGFILE 2>&1
    unzip admin.zip >>$LOGFILE 2>&1
    source eucarc
    euca-add-keypair admin > admin.private
    cd /root
    ln -s /root/credentials/admin/eucarc .eucarc
    chmod -R go-rwx credentials | tee -a $LOGFILE
    chmod go-rwx .eucarc | tee -a $LOGFILE
    echo "$(date)- Downloaded cloud admin credentials to /root/credentials/admin" | tee -a $LOGFILE
    echo ""
  fi
}

# Function for installing graphical desktop
function install_desktop {
  echo "$(date)- Installing graphical desktop.  This may take a few minutes." | tee -a $LOGFILE
  echo ""
  case "$ELVERSION" in
  "5")
    (yum -y groupinstall 'GNOME Desktop Environment' 'X Window System' >> $LOGFILE 2>&1) &
    spinner $!
    ;;
  "6")
    (yum -y groupinstall 'X Window System' 'Desktop' 'Fonts' >> $LOGFILE 2>&1) &
    spinner $!
    ;;
  esac
  (yum -y install firefox >> $LOGFILE 2>&1) &
  spinner $!
  sed --in-place 's/id:3:initdefault:/id:5:initdefault:/g' /etc/inittab
  chkconfig NetworkManager off
  sed -i -e 's/NM_CONTROLLED=yes/NM_CONTROLLED=no/' /etc/sysconfig/network-scripts/ifcfg-*
  echo ""
  echo "$(date)- Graphical desktop installed." | tee -a $LOGFILE
  echo ""
}

# Function to create users
function create_user {
  LOCALUSER=""
  while [ -z "$LOCALUSER" ] ; do
    read -p "Please provide a user name for logging in to the graphical desktop: " LOCALUSER
  done
  useradd -d /home/${LOCALUSER} -m ${LOCALUSER}
  echo ""
  echo "Please enter a password for ${LOCALUSER}."
  passwd ${LOCALUSER}
  mkdir -p /home/${LOCALUSER}/Desktop
  cat >> /home/${LOCALUSER}/Desktop/Eucalyptus.desktop << "DESKTOPSHORTCUT"
[Desktop Entry]
Encoding=UTF-8
Name=Eucalyptus Web Admin
Type=Link
URL=https://REPLACE_PUBLIC_IP_ADDRESS:8443/
Icon=gnome-fs-bookmark
Name[en_US]=Eucalyptus Web Admin
DESKTOPSHORTCUT
  cat >> /home/${LOCALUSER}/Desktop/Eucalyptus_Docs.desktop << "DOCSSHORTCUT"
[Desktop Entry]
Encoding=UTF-8
Name=Eucalyptus Documentation
Type=Link
URL=http://www.eucalyptus.com/docs
Icon=gnome-fs-bookmark
Name[en_US]=Eucalyptus Documentation
DOCSSHORTCUT
  sed -i -e "s/REPLACE_PUBLIC_IP_ADDRESS/$PUBLIC_IP_ADDRESS/" /home/${LOCALUSER}/Desktop/Eucalyptus.desktop
  chown -R ${LOCALUSER}:${LOCALUSER} /home/${LOCALUSER}/Desktop
  cp -a /root/credentials /home/${LOCALUSER}/
  cd /home/${LOCALUSER}
  ln -s credentials/admin/eucarc .eucarc
  chown -R ${LOCALUSER}:${LOCALUSER} /home/${LOCALUSER}/credentials
  chown -R ${LOCALUSER}:${LOCALUSER} /home/${LOCALUSER}/.eucarc
  cd
  error_check
}

# User interaction starts here
echo ""
echo "Welcome to the Eucalyptus configuration script."
echo ""
if [ $CIAB = "N" ] ; then
  echo "It is recommended that the Node Controllers are installed and configured prior"
  echo "to continuing this Frontend configuration."
  echo ""
fi
CONFIGUREFRONTEND=""
while ! echo "$CONFIGUREFRONTEND" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
  if [ -f /var/log/eucalyptus/cloud-output.log ] ; then
    read -p "Would you like to reconfigure your Eucalyptus services now? " CONFIGUREFRONTEND
  else
    CONFIGUREFRONTEND="yes"
  fi
  case "$CONFIGUREFRONTEND" in
  y|Y|yes|YES|Yes)
    echo "$(date)- Configuring Eucalyptus services." | tee -a $LOGFILE
    configure_frontend
    echo "$(date)- Configured Eucalyptus services." | tee -a $LOGFILE
    echo ""
    if [ $CIAB = "N" ] ; then
      echo "This machine is ready and running as a Cloud Controller."
    else
      echo "This machine is ready and running as a cloud-in-a-box."
    fi
    echo ""
    ;;
  n|N|no|NO|No)
    echo "$(date)- Skipped Eucalyptus service configuration." | tee -a $LOGFILE
    echo ""
    echo "You can re-run this configuration script later by executing"
    echo "/usr/local/sbin/eucalyptus-frontend-config.sh as root."
    echo ""
    exit 0
    ;;
  *)
    echo "Please answer either 'yes' or 'no'."
    ;;
  esac
done

# Get the cloud admin's credentials
get_credentials

# Ask the user if they would like to create an EMI from the installation CD
CREATEEMI=""
ANTEXT="an"
echo "Virtual machine images (EMIs) are required to run instances in your cloud."
while ! echo "$CREATEEMI" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
  echo ""
  if [ $ANTEXT = "an" ] ; then
    CREATEEMI="Yes"
  else
    CREATEEMI="No"
  fi
  read -p "Would you like to create $ANTEXT EMI now? [$CREATEEMI] " create_emi
  if [ $create_emi ]
  then
    export CREATEEMI=$create_emi
  fi
  case "$CREATEEMI" in
  y|Y|yes|YES|Yes)
    eucalyptus-create-emi.sh
    error_check
    CREATEEMI=""
    ANTEXT="another"
    echo ""
    ;;
  n|N|no|NO|No)
    if [ $ANTEXT = "an" ] ; then
      echo "$(date)- Skipped EMI creation." | tee -a $LOGFILE
    fi
    echo ""
    ;;
  *)
    echo "Please answer either 'yes' or 'no'."
    ;;
  esac
done

# Ask the user if they would like to install a graphical desktop on the Frontend server
INSTALLDESKTOP=""
while ! echo "$INSTALLDESKTOP" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
  echo "If you have Internet access, you can optionally install a graphical desktop,"
  echo "which will allow you to test web access to your new cloud from this system."
  echo ""
  echo "This will download approximately 300 MB of packages, which may take a long time,"
  echo "depending on the speed of your Internet connection."
  echo ""
  INSTALLDESKTOP="No"
  read -p "Would you like to install a graphical desktop on this server? [$INSTALLDESKTOP] " install_graphical_desktop
  if [ $install_graphical_desktop ]
  then
    export INSTALLDESKTOP=$install_graphical_desktop
  fi
  echo ""
  case "$INSTALLDESKTOP" in
  y|Y|yes|YES|Yes)
    install_desktop
    ;;
  n|N|no|NO|No)
    echo "$(date)- Skipped graphical desktop installation." | tee -a $LOGFILE
    echo ""
    ;;
  *)
    echo "Please answer either 'yes' or 'no'."
    ;;
  esac
done

# If the graphical desktop installed, make sure we have a non-root user
rpm -q gdm > /dev/null
if [ $? -eq 0 ] ; then
  echo "In order to log in to the graphical desktop you must use a non-root user."
  echo ""
  CREATEUSER=""
  while ! echo "$CREATEUSER" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
    HIGHESTUID=`cut -d: -f3 /etc/passwd | sort -n | grep -v 65534 | tail -n 1`
    if [ $HIGHESTUID -lt 500 ] ; then
      CREATEUSER="Yes"
    else
      CREATEUSER="No"
      read -p "Would you like to create another user? [$CREATEUSER] " create_user
      if [ $create_user ]
      then
        export CREATEUSER=$create_user
      fi
    fi
    case "$CREATEUSER" in
    y|Y|yes|YES|Yes)
      create_user
      ;;
    n|N|no|NO|No)
      echo "$(date)- Skipped user creation." | tee -a $LOGFILE
      echo ""
      ;;
    *)
      echo "Please answer either 'yes' or 'no'."
      ;;
    esac
  done
fi

echo "You can re-run this configuration scipt later by executing"
echo "/usr/local/sbin/eucalyptus-frontend-config.sh as root."
echo ""
case "$INSTALLDESKTOP" in
  y|Y|yes|YES|Yes)
    echo "Your system needs to reboot to complete configuration changes."
    read -p "Press ENTER to reboot." REBOOTME
    shutdown -r now
    ;;
  n|N|no|NO|No)
    echo "Point any browser on your network to https://$PUBLIC_IP_ADDRESS:8443/ to start using your cloud!"
    echo ""
    ;;
esac

if [ $CIAB = "Y" ] ; then
  if [ $ELVERSION = "5" ] ; then
    echo "Your system needs to reboot to complete configuration changes."
    read -p "Press ENTER to reboot." REBOOTME
    shutdown -r now
  fi
fi

