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

# We need a default cluster name for registration
export CLUSTER_NAME=cluster01

# Set log file destination
export LOGFILE=/var/log/eucalyptus-frontend-config.log

# Set ELVERSION
export ELVERSION=`cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/'`

# Error checking function
function error_check {
  count=`grep -i 'error\|fail\|exception' $LOGFILE|wc -l`
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

# Ask user to reconfigure networking if no static IP address settings are detected
STATICIPS=`grep IPADDR /etc/sysconfig/network-scripts/ifcfg-* | grep -v 127.0.0.1 | wc -l`
if [ $STATICIPS -lt 1 ] ; then
  echo "It looks like none of your network interfaces are configured with static IP"
  echo "addresses."
  echo ""
  echo "It is recommended that you use static IP addressing for configuring the network"
  echo "interfaces on your Eucalyptus infrastructure servers."
  echo ""
  while ! echo "$CONFIGURE_NETWORKING" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
    read -p "Would you like to reconfigure your network settings now? " CONFIGURE_NETWORKING
    case "$CONFIGURE_NETWORKING" in
    y|Y|yes|YES|Yes)
      echo "$(date)- Configuring network settings." | tee -a $LOGFILE
      system-config-network-tui
      error_check
      echo "$(date)- Reconfigured network settings." | tee -a $LOGFILE
      ;;
    n|N|no|NO|No)
      echo "$(date)- Skipped network configuration." | tee -a $LOGFILE
      ;;
    *)
      echo "Please answer either 'yes' or 'no'."
    esac
  done
fi

# Verify that each disabled interface is supposed to be that way
for INTERFACE in `ls /etc/sysconfig/network-scripts/ | grep ifcfg | cut -d- -f2 | grep -v '^lo$'` ; do
  if grep 'ONBOOT=no' /etc/sysconfig/network-scripts/ifcfg-${INTERFACE} > /dev/null ; then
    echo ""
    echo "Interface ${INTERFACE} is currently disabled."
    while ! echo "$ENABLE_INTERFACE" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
      read -p "Would you like to enable the interface ${INTERFACE}? " ENABLE_INTERFACE
      case "$ENABLE_INTERFACE" in
      y|Y|yes|YES|Yes)
        echo "$(date)- Enabling interface ${INTERFACE}." | tee -a $LOGFILE
        sed -i -e 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-${INTERFACE} | tee -a $LOGFILE
        service network restart
        error_check
        ;;
      n|N|no|NO|No)
        echo "$(date)- Skipped enabling interface ${INTERFACE}." | tee -a $LOGFILE
        ;;
      *)
        echo "Please answer either 'yes' or 'no'."
      esac
    done
  fi
done

# Ask user to reconfigure DNS if no DNS servers are detected
NAMESERVERS=`grep ^nameserver /etc/resolv.conf | wc -l`
if [ $NAMESERVERS -lt 1 ] ; then
  echo ""
  echo "It looks like you do not have DNS resolvers configured."
  echo ""
  while ! echo "$CONFIGURE_DNS" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
    read -p "Would you like to reconfigure your DNS settings now? " CONFIGURE_DNS
    case "$CONFIGURE_DNS" in
    y|Y|yes|YES|Yes)
      echo "$(date)- Configuring DNS settings." | tee -a $LOGFILE
      system-config-network-tui
      service network restart
      error_check
      echo "$(date)- Reconfigured DNS settings." | tee -a $LOGFILE
      ;;
    n|N|no|NO|No)
      echo "$(date)- Skipped DNS configuration." | tee -a $LOGFILE
      ;;
    *)
      echo "Please answer either 'yes' or 'no'."
    esac
  done
fi

# Verify the configured hostname and ask the user to change it
CONFIGUREDHOSTNAME=`grep '^HOSTNAME=' /etc/sysconfig/network | sed -e 's/^HOSTNAME=//'`
echo ""
if grep -E '^HOSTNAME.*localhost' /etc/sysconfig/network > /dev/null ; then
  echo "It is recommended to configure a hostname other than 'localhost'."
  echo ""
fi
echo "Your currently configured hostname is ${CONFIGUREDHOSTNAME}."
echo ""
echo "You can change this in your DNS settings."
echo ""
while ! echo "$CONFIGURE_HOSTNAME" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
  read -p "Would you like to change this now? " CONFIGURE_HOSTNAME
    case "$CONFIGURE_HOSTNAME" in
    y|Y|yes|YES|Yes)
      echo "$(date)- Configuring DNS settings." | tee -a $LOGFILE
      system-config-network-tui
      service network restart
      error_check
      echo "$(date)- Reconfigured DNS settings." | tee -a $LOGFILE
      ;;
    n|N|no|NO|No)
      echo "$(date)- Skipped DNS configuration." | tee -a $LOGFILE
      ;;
    *)
      echo "Please answer either 'yes' or 'no'."
    esac
done

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
while ! echo "$ENABLE_NTP_SYNC" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
  read -p "Would you like to enable NTP and synchronize clock? " ENABLE_NTP_SYNC
  case "$ENABLE_NTP_SYNC" in
  y|Y|yes|YES|Yes)
    echo "$(date)- Setting clock via NTP.  This may take a few minutes." | tee -a $LOGFILE
    if [ -f /var/run/ntpd.pid ] ; then
      service ntpd stop
    fi
    `which ntpd` -q -g >>$LOGFILE 2>&1
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
  ssh -o StrictHostKeyChecking=no $FEIP "true"
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
EUCACONFIG=/etc/eucalyptus/eucalyptus.conf
edit_prop VNET_PUBINTERFACE "The public ethernet interface" $EUCACONFIG
edit_prop VNET_PRIVINTERFACE "The private ethernet interface" $EUCACONFIG
edit_prop VNET_DNS "The DNS server address" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"
edit_prop VNET_SUBNET "Eucalyptus-only dedicated subnet" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"
edit_prop VNET_NETMASK "Eucalyptus subnet netmask" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"
SUBNET_VAL=`grep VNET_NETMASK $EUCACONFIG|tail -1|cut -d '=' -f 2|tr -d "\""`
ZERO_OCTETS=`echo $SUBNET_VAL |tr "." "\n" |grep 0 |wc -l`
ADDRSPER_REC=32
if [ $ZERO_OCTETS -eq "3" ]     # class A subnet
then
  ADDRSPER_REC=128
elif [ $ZERO_OCTETS -eq "2" ] # class B subnet
then
  ADDRSPER_REC=64
elif [ $ZERO_OCTETS -eq "1" ] # class C subnet
then
  ADDRSPER_REC=32
fi
echo "Based on the size of your private subnet, we recommend the next value be set to $ADDRSPER_REC"
sed --in-place "s/VNET_ADDRSPERNET=\"32\"/VNET_ADDRSPERNET=\"${ADDRSPER_REC}\"/" /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
edit_prop VNET_ADDRSPERNET "How many addresses per net?" $EUCACONFIG "[0-9]*"
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
  /usr/sbin/euca_conf --initialize
fi

# Start Eucalyptus services prior to registration
echo ""
echo "$(date)- Starting services " | tee -a $LOGFILE
if [ ! -f /var/run/eucalyptus/eucalyptus-cloud.pid ] ; then
  service eucalyptus-cloud start >> $LOGFILE 2>&1
fi
/sbin/chkconfig eucalyptus-cloud on >>$LOGFILE 2>&1
if [ ! -f /var/run/eucalyptus/eucalyptus-cc.pid ] ; then
  curl http://localhost:8443/ >/dev/null 2>&1
  while [ $? -ne 0 ] ; do
    # Wait for CLC to start
    echo "Waiting for cloud controller to finish starting"
    sleep 5
    curl http://localhost:8443/ >/dev/null 2>&1
  done
  service eucalyptus-cc start >> $LOGFILE 2>&1
else
  service eucalyptus-cc restart >> $LOGFILE 2>&1
fi
/sbin/chkconfig eucalyptus-cc on >> $LOGFILE 2>&1
error_check
echo "$(date)- Started services " | tee -a $LOGFILE

# Prepare to register components
echo "$(date)- Registering components " | tee -a $LOGFILE
curl http://localhost:8443/ >/dev/null 2>&1
while [ $? -ne 0 ]
do
  echo "Waiting for cloud controller to finish starting"
    sleep 5
    curl http://localhost:8443/ >/dev/null 2>&1
done
export PUBLIC_INTERFACE=`grep -E '^VNET_PUBINTERFACE=' /etc/eucalyptus/eucalyptus.conf | cut -d\" -f2`
export PRIVATE_INTERFACE=`grep -E '^VNET_PRIVINTERFACE=' /etc/eucalyptus/eucalyptus.conf | cut -d\" -f2`
export PUBLIC_IP_ADDRESS=`ip addr show $PUBLIC_INTERFACE |grep inet |grep global|awk -F"[\t /]*" '{ print $3 }'`
export PRIVATE_IP_ADDRESS=`ip addr show $PRIVATE_INTERFACE |grep inet |grep global|awk -F"[\t /]*" '{ print $3 }'`
# Prompt for ip confirm
read -p "Public IP for Cloud Controller and Walrus [$PUBLIC_IP_ADDRESS]" public_ip
read -p "Private IP for Cluster Controller and Storage Controller [$PRIVATE_IP_ADDRESS]" private_ip
if [ $public_ip ]
then
  export PUBLIC_IP_ADDRESS=$public_ip
fi
if [ $private_ip ]
then
  export PRIVATE_IP_ADDRESS=$private_ip
fi
echo "Using public IP $PUBLIC_IP_ADDRESS and private IP $PRIVATE_IP_ADDRESS to" | tee -a $LOGFILE
echo "register components" | tee -a $LOGFILE

# Register Walrus
if [ `/usr/sbin/euca_conf --list-walruses 2>/dev/null |wc -l` -eq '0' ]
then
  /usr/sbin/euca_conf --register-walrus --partition walrus --host $PUBLIC_IP_ADDRESS --component=walrus | tee -a $LOGFILE 
else
  echo "Walrus already registered. Will not re-register walrus" | tee -a $LOGFILE
fi

# Deregister previous SCs and clusters
for OLDSCIP in `/usr/sbin/euca_conf --list-scs|awk '{print $4}'`
do
  OLDSCPARTITION=`/usr/sbin/euca_conf --list-scs|awk '{print $2}'`
  OLDSCCOMPONENT=`/usr/sbin/euca_conf --list-scs|awk '{print $3}'`
  /usr/sbin/euca_conf --deregister-sc --partition ${OLDSCPARTITION} --host ${OLDSCIP} --component=${OLDSCCOMPONENT} >>$LOGFILE 2>&1
done
for OLDCCIP in `/usr/sbin/euca_conf --list-clusters|awk '{print $4}'`
do
  OLDCCPARTITION=`/usr/sbin/euca_conf --list-clusters|awk '{print $2}'`
  OLDCCCOMPONENT=`/usr/sbin/euca_conf --list-clusters|awk '{print $3}'`
  /usr/sbin/euca_conf --deregister-cluster --partition ${OLDCCPARTITION} --host ${OLDCCIP} --component=${OLDCCCOMPONENT} >>$LOGFILE 2>&1
done

# Now register clusters and SCs
/usr/sbin/euca_conf --register-cluster --partition $CLUSTER_NAME --host $PUBLIC_IP_ADDRESS --component=cc_01 | tee -a $LOGFILE
/usr/sbin/euca_conf --register-sc --partition $CLUSTER_NAME --host $PRIVATE_IP_ADDRESS --component=sc_01 | tee -a $LOGFILE
error_check

# Deregister previous node controllers
for NCIP in `/usr/sbin/euca_conf --list-nodes 2>/dev/null | awk '{print $2}'`
do
  /usr/sbin/euca_conf --deregister-nodes $NCIP >>$LOGFILE 2>&1
done

# Register node controllers
echo ""
echo "Ready to register node controllers. Once they are installed, enter their IP"
echo "addresses here, one by one (ENTER when done)"
done="not"
while [ $done != "done" ]
do
  read -p "Node IP (ENTER when done): " node
  if [ ! $node ]
  then
    done="done"
    echo "To register node controllers in the future, please run:"
    echo '/usr/sbin/euca_conf --register-nodes "host host ..."'
  else
    echo "Please enter the root password of the node controller when prompted"
    scp -rp /root/.ssh root@${node}:/root/
    ssh root@${node} "service eucalyptus-nc restart"
    /usr/sbin/euca_conf --register-nodes $node | tee -a $LOGFILE
  fi
done
error_check
echo "$(date)- Registered components " | tee -a $LOGFILE
echo ""
}

# Function to retrieve cloud admin credentials
function get_credentials {
  if [ ! -f /root/credentials/admin/eucarc ] ; then
    mkdir -p /root/credentials/admin | tee -a $LOGFILE
    cd /root/credentials/admin
    euca_conf --get-credentials admin.zip | tee -a $LOGFILE
    unzip admin.zip | tee -a $LOGFILE
    source eucarc
    euca-add-keypair admin > admin.private
    cd /root
    ln -s /root/credentials/admin/eucarc .eucarc
    chmod -R go-rwx credentials | tee -a $LOGFILE
    chmod go-rwx .eucarc | tee -a $LOGFILE
  fi
}

# Function to create instance store-backed EMI
function create_emi {
  CDORINTERNET=""
  while ! echo "$CDORINTERNET" | grep -iE '(^cd$|^internet$)' > /dev/null ; do
  echo "Which installation source would you like to use?"
  echo ""
  read -p "(cd/internet): " CDORINTERNET
    case "$CDORINTERNET" in
    Internet|internet)
      echo "$(date)- Creating EMI from Internet repositories." | tee -a $LOGFILE
      rpm -q yum-utils > /dev/null
      if [ $? -eq 1 ] ; then
        echo "$(date) - Installing yum-utils package." | tee -a $LOGFILE
        yum -y install yum-utils > /dev/null
      else
        echo "$(date) - yum-utils package already installed." | tee -a $LOGFILE
      fi
      ;;
    cd|CD)
      echo "$(date)- Creating EMI from Eucalyptus installation CD." | tee -a $LOGFILE
      CDNOTMOUNTED=`ls /media/cdrom/repodata/repomd.xml > /dev/null 2>&1 ; echo $?`
      while [ $CDNOTMOUNTED -ne 0 ] ; do
        read -p "Please insert your Eucalyptus installation CD and press ENTER: "
        sleep 5
        mkdir -p /media/cdrom
        mount /dev/cdrom /media/cdrom
        CDNOTMOUNTED=`ls /media/cdrom/repodata/repomd.xml > /dev/null 2>&1 ; echo $?`
        if [ $CDNOTMOUNTED -ne 0 ] ; then
          echo "Unable to locate Eucalyptus installation CD.  Press Ctrl-C to abort."
          echo ""
        fi
      done
      ;;
    *)
      echo "Please answer either 'cd' or 'internet'."
      ;;
    esac
  done
  IMAGESIZE=""
  while ! echo "$IMAGESIZE" | grep -iE '(^small$|^medium$|^large$)' > /dev/null ; do
    echo "There are several instance types available, each with different virtual disk"
    echo "sizes."
    echo ""
    echo "The default instance type/disk sizes are:"
    echo "small:   2 GB"
    echo "medium:  5 GB"
    echo "large:  10 GB"
    echo ""
    echo "EMIs with larger root filesystems may take longer to launch, but provide more"
    echo "storage for the root partition."
    echo "EMIs with smaller root filesystems may launch quicker, but have limited storage"
    echo "for the root filesystem."
    echo ""
    echo "You will not be able to run an EMI unless the instance type provides enough"
    echo "storage for the root filesystem."
    echo "i.e. If you attempt to run a large EMI using a small instance type, it will"
    echo "fail to launch."
    echo ""
    echo "When you launch an instance, any storage provided by the instance type that is"
    echo "greater than the root filesystem + 512 MB swap is allocated as an 'ephemeral'"
    echo "storage partition."
    echo ""
    read -p "Would you like a small (1.5GB), medium (4.5GB), or large (9.5GB) root filesystem for your EMI? " IMAGESIZE
    case "$IMAGESIZE" in
    "small")
      SEEKBLOCKS=1533
    ;;
    "medium")
      SEEKBLOCKS=4605
    ;;
    "large")
      SEEKBLOCKS=9725
    ;;
    *)
      echo "Please enter 'small', 'medium', or 'large'."
    ;;
    esac
  done 
  echo "$(date)- Creating and mounting disk image file." | tee -a $LOGFILE
  dd if=/dev/zero of=centos-${ELVERSION}-x86_64-${IMAGESIZE}.img bs=1M count=1 seek=${SEEKBLOCKS}
  parted centos-${ELVERSION}-x86_64-${IMAGESIZE}.img mklabel msdos
  mkfs.ext3 -F -L root centos-${ELVERSION}-x86_64-${IMAGESIZE}.img
  losetup -f centos-${ELVERSION}-x86_64-${IMAGESIZE}.img
  IMAGELOOPDEVICE=`losetup -a | grep -E "centos-${ELVERSION}-x86_64-${IMAGESIZE}.img" | awk '{print $1}' | sed 's/://g'`
  mkdir -p /mnt/image
  mount ${IMAGELOOPDEVICE} /mnt/image
  mkdir -p /mnt/image/{proc,etc,dev,var/{cache,log,lock}}
  MAKEDEV -d /mnt/image/dev -x console
  MAKEDEV -d /mnt/image/dev -x null
  MAKEDEV -d /mnt/image/dev -x zero
  MAKEDEV -d /mnt/image/dev -x urandom
  mount -t proc none /mnt/image/proc
  cat > /mnt/image/etc/fstab << EOF
LABEL=root    /        ext3   defaults       1 1
none          /dev/pts devpts gid=5,mode=620 0 0
none          /dev/shm tmpfs  defaults       0 0
none          /proc    proc   defaults       0 0
none          /sys     sysfs  defaults       0 0
EOF
  echo "$(date)- Installing packages in image." | tee -a $LOGFILE
  case "$CDORINTERNET" in
  Internet|internet)
    mkdir -p /mnt/image/var/lib/rpm
    rpm --initdb --dbpath /mnt/image/var/lib/rpm
    yumdownloader centos-release epel-release euca2ools-release
    rpm -ivh --nodeps --root /mnt/image *release*.rpm
    rm -f *release*.rpm
    case "$ELVERSION" in
    "5")
      yum -y --nogpgcheck --installroot=/mnt/image/ groupinstall 'Core'
      yum -y --nogpgcheck --installroot=/mnt/image/ install authconfig bzip2 curl euca2ools euca2ools-release iptables iptables-ipv6 kernel-xen mdadm ntp openssh-clients parted selinux-policy unzip wget which zip
    ;;
    "6")
      yum -y --nogpgcheck --installroot=/mnt/image/ groupinstall 'Core'
      yum -y --nogpgcheck --installroot=/mnt/image/ install authconfig bzip2 curl euca2ools euca2ools-release iptables iptables-ipv6 kernel mdadm ntp openssh-clients parted selinux-policy unzip wget which zip
    ;;
    esac
    ;;
  cd|CD)
    case "$ELVERSION" in
    "5")
      yum -y --disablerepo=\* --enablerepo="c${ELVERSION}-media" --nogpgcheck --installroot=/mnt/image/ groupinstall 'Core'
      yum -y --disablerepo=\* --enablerepo="c${ELVERSION}-media" --nogpgcheck --installroot=/mnt/image/ install authconfig bzip2 curl euca2ools euca2ools-release iptables iptables-ipv6 kernel-xen mdadm ntp openssh-clients parted selinux-policy unzip wget which zip
    ;;
    "6")
      yum -y --disablerepo=\* --enablerepo="c${ELVERSION}-media" --nogpgcheck --installroot=/mnt/image/ groupinstall 'Core'
      yum -y --disablerepo=\* --enablerepo="c${ELVERSION}-media" --nogpgcheck --installroot=/mnt/image/ install authconfig bzip2 curl euca2ools euca2ools-release iptables iptables-ipv6 kernel mdadm ntp openssh-clients parted selinux-policy unzip wget which zip
    ;;
    esac
    echo "$(date)- Unmounting Eucalyptus installation CD." | tee -a $LOGFILE
    umount /media/cdrom
    rm -rf /media/cdrom
    ;;
  esac
  echo "$(date)- Creating configuration files and scripts in image." | tee -a $LOGFILE
  sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/' /mnt/image/etc/selinux/config
  touch /mnt/image/.autorelabel
  cat > /mnt/image/etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF
  cat > /mnt/image/etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
ONBOOT=yes
DEVICE=eth0
BOOTPROTO=dhcp
EOF
  cat > /mnt/image/etc/rc.d/rc.local << "EOF"
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#

# since ephemeral or swap may not be mounted or on different devices
# (specially on xen) let's look for them. This is fairly hackish.
if ! swapon -s|grep partition > /dev/null ; then
# no swap partition
for x in `ls /dev/[xvsh]*d[a-z]3` ; do
swapon $x 2> /dev/null
done
fi
if ! mount | cut -f 1 -d ' '|grep /dev|grep 2 > /dev/null ; then
mkdir -p /media/ephemeral0
if [ -d /media/ephemeral0 ]; then
if [ -z "`ls /media/ephemeral0/*`" ]; then
# try to mount only if the mount point is empty
for x in `ls /dev/[xvsh]*d[a-z]2` ; do
mount $x /media/ephemeral0 2> /dev/null
done
fi
fi
fi

# load pci hotplug for dynamic disk attach in KVM (for EBS)
depmod -a
modprobe acpiphp || true

# simple attempt to get the user ssh key using the meta-data service
mkdir -p /root/.ssh
echo >> /root/.ssh/authorized_keys
curl --retry 3 --retry-delay 10 -m 45 -s http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key | grep 'ssh-rsa' >> /root/.ssh/authorized_keys
echo "AUTHORIZED_KEYS:"
echo "************************"
cat /root/.ssh/authorized_keys
echo "************************"

# set the hostname to something sensible
META_HOSTNAME="`curl -s http://169.254.169.254/latest/meta-data/local-hostname`"
META_IP="`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`"

if [ ${META_HOSTNAME} = ${META_IP} ]; then
        META_HOSTNAME="`echo $META_HOSTNAME | sed -e 's/\./-/g' | xargs -I {} echo "ip-{}"`"
fi

hostname $META_HOSTNAME
echo >> /etc/hosts
echo "${META_IP} ${META_HOSTNAME}" >> /etc/hosts


# check if the user-data is a script, and if so execute it
TMP_FILE="/tmp/user-data-$$"
curl --retry 3 --retry-delay 10 -m 60 -o $TMP_FILE http://169.254.169.254/latest/user-data
if [ -s $TMP_FILE ]; then
echo "Downloaded user data in $TMP_FILE"
if [ "`head -c 2 $TMP_FILE`" = '#!' ]; then
chmod 700 $TMP_FILE
echo "User data is a script: executing it"
$TMP_FILE > /root/user-data.out 2>&1
fi
fi

exit 0
EOF
  echo "$(date)- Generating and setting random root password." | tee -a $LOGFILE
  chroot /mnt/image authconfig --enableshadow --passalgo=sha512 --updateall
  dd if=/dev/urandom bs=1M count=1 2>/dev/null | sha512sum | awk '{print $1}' | chroot /mnt/image passwd --stdin root
  echo "$(date)- Disabling iptables in image." | tee -a $LOGFILE
  chroot /mnt/image chkconfig iptables off
  chroot /mnt/image chkconfig ip6tables off
  case "$ELVERSION" in
  "5")
    echo "$(date)- Generating ramdisk and copying kernel from Node Controller." | tee -a $LOGFILE
    TEMPNODE=`euca_conf --list-nodes | awk '{print $2}' | head -n 1`
    scp ${TEMPNODE}:/boot/vmlinuz* ./
    ssh ${TEMPNODE} 'mkinitrd --omit-scsi-modules --with=xennet --with=xenblk --preload=xenblk /tmp/initrd-$(uname -r).img $(uname -r)'
    scp ${TEMPNODE}:/tmp/initrd-* ./
    ssh ${TEMPNODE} "rm -f /tmp/initrd-*"
  ;;
  "6")
    echo "$(date)- Copying kernel and ramdisk from image." | tee -a $LOGFILE
    cp /mnt/image/boot/vmlinuz-* ./
    cp /mnt/image/boot/init* ./
  ;;
  esac
  echo "$(date)- Unmounting and image file." | tee -a $LOGFILE
  sync
  umount /mnt/image/proc
  umount /mnt/image
  rm -rf /mnt/image
  losetup -d $IMAGELOOPDEVICE
  echo "$(date)- Creating EMI." | tee -a $LOGFILE
  IMAGENAME=`ls centos*.img | sed -e 's/\.img$//'`
  KERNELIMAGE=`ls vmlinuz*`
  INITRDIMAGE=`ls init*`
  echo "$(date)- Bundling, uploading, and registering kernel image." | tee -a $LOGFILE
  KERNELMANIFEST=`euca-bundle-image -i $KERNELIMAGE --kernel true | grep 'Generating manifest' | awk '{print $3}'`
  KERNELUPLOADEDBUNDLE=`euca-upload-bundle -b $IMAGENAME -m $KERNELMANIFEST | grep 'Uploaded image as' | awk '{print $4}'`
  KERNELEKI=`euca-register -n $KERNELIMAGE -a x86_64 --kernel true $KERNELUPLOADEDBUNDLE | awk '{print $2}'`
  echo "$(date)- Bundling, uploading, and registering ramdisk image." | tee -a $LOGFILE
  INITRDMANIFEST=`euca-bundle-image -i $INITRDIMAGE --ramdisk true | grep 'Generating manifest' | awk '{print $3}'`
  INITRDUPLOADEDBUNDLE=`euca-upload-bundle -b $IMAGENAME -m $INITRDMANIFEST | grep 'Uploaded image as' | awk '{print $4}'`
  INITRDERI=`euca-register -n $INITRDIMAGE -a x86_64 --ramdisk true $INITRDUPLOADEDBUNDLE | awk '{print $2}'`
  echo "$(date)- Bundling, uploading and registering EMI." | tee -a $LOGFILE
  EMIMANIFEST=`euca-bundle-image -i ${IMAGENAME}.img --kernel $KERNELEKI --ramdisk $INITRDERI | grep 'Generating manifest' | awk '{print $3}'`
  EMIUPLOADEDBUNDLE=`euca-upload-bundle -b $IMAGENAME -m $EMIMANIFEST | grep 'Uploaded image as' | awk '{print $4}'`
  EMI=`euca-register -n $IMAGENAME -a x86_64 --kernel $KERNELEKI --ramdisk $INITRDERI $EMIUPLOADEDBUNDLE  | awk '{print $2}'`
  echo "$(date)- EMI image $EMI is ready to use." | tee -a $LOGFILE
  rm -f ${IMAGENAME}.img $KERNELIMAGE $INITRDIMAGE
}

# Function for installing graphical desktop
function install_desktop {
  echo "$(date)- Installing graphical desktop.  This may take a few minutes." | tee -a $LOGFILE
  echo ""
  case "$ELVERSION" in
  "5")
    yum -y groupinstall 'GNOME Desktop Environment' 'X Window System'
    ;;
  "6")
    yum -y groupinstall 'X Window System' 'Desktop' 'Fonts'
    ;;
  esac
  yum -y install firefox
  sed --in-place 's/id:3:initdefault:/id:5:initdefault:/g' /etc/inittab
  chkconfig NetworkManager off
  sed -i -e 's/NM_CONTROLLED=yes/NM_CONTROLLED=no/' /etc/sysconfig/network-scripts/ifcfg-*
  error_check
  echo "$(date)- Graphical desktop installed." | tee -a $LOGFILE
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
echo "Welcome to the Eucalyptus frontend configuration script."
echo ""
echo "It is recommended that the Node Controllers are installed and configured prior"
echo "to continuing this Frontend configuration."
echo ""
CONFIGUREFRONTEND=""
while ! echo "$CONFIGUREFRONTEND" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
  read -p "Would you like to configure your Frontend server now? " CONFIGUREFRONTEND
  case "$CONFIGUREFRONTEND" in
  y|Y|yes|YES|Yes)
    echo "$(date)- Configuring Frontend." | tee -a $LOGFILE
    configure_frontend
    echo "$(date)- Configured Frontend." | tee -a $LOGFILE
    echo ""
    echo "This machine is ready and running as a Frontend."
    echo ""
    ;;
  n|N|no|NO|No)
    echo "$(date)- Skipped Frontend configuration." | tee -a $LOGFILE
    echo ""
    echo "You can re-run this configuration scipt later by executing"
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
while ! echo "$CREATEEMI" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
echo "Virtual machine images (EMIs) are required to run instances in your cloud."
echo ""
echo "You can dowload starter images from http://emis.eucalyptus.com."
echo ""
echo "You can also create EMIs from the Eucalyptus installation CD or Internet repositories."
echo ""
read -p "Would you like to create an EMI from the Eucalyptus installation CD or Internet repositories? " CREATEEMI
  case "$CREATEEMI" in
  y|Y|yes|YES|Yes)
    create_emi
    error_check
    CREATEEMI=""
    echo "Answer 'no' when you are done creating EMIs."
    echo ""
    ;;
  n|N|no|NO|No)
    echo "$(date)- Skipped EMI creation." | tee -a $LOGFILE
    ;;
  *)
    echo "Please answer either 'yes' or 'no'."
    ;;
  esac
done

# Ask the user if they would like to install a graphical desktop on the Frontend server
INSTALLDESKTOP=""
while ! echo "$INSTALLDESKTOP" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
echo "If you have Internet access, you can optionally install a graphical desktop."
echo "This will download approximately 300 MB of packages, which may take a long time,"
echo "depending on the speed of your Internet connection."
echo ""
read -p "Would you like to install a graphical desktop on this server? " INSTALLDESKTOP
  case "$INSTALLDESKTOP" in
  y|Y|yes|YES|Yes)
    install_desktop
    ;;
  n|N|no|NO|No)
    echo "$(date)- Skipped graphical desktop installation." | tee -a $LOGFILE
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
  CREATEUSER=""
  while ! echo "$CREATEUSER" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
    HIGHESTUID=`cut -d: -f3 /etc/passwd | sort -n | grep -v 65534 | tail -n 1`
    if [ $HIGHESTUID -lt 500 ] ; then
      CREATEUSER="yes"
    else
      read -p "Would you like to create another user? " CREATEUSER
    fi
    case "$CREATEUSER" in
    y|Y|yes|YES|Yes)
      create_user
      ;;
    n|N|no|NO|No)
      echo "$(date)- Skipped user creation." | tee -a $LOGFILE
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
    echo "Please visit https://$PUBLIC_IP_ADDRESS:8443/ to start using your cloud!"
    echo ""
    ;;
esac

