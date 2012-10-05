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

# Set log file destination
export LOGFILE=/var/log/eucalyptus-nc-config.log

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

echo ""
echo "Welcome to the Eucalyptus node controller configuration script."
echo ""

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
      hostname `grep '^HOSTNAME=' /etc/sysconfig/network | sed -e 's/^HOSTNAME=//'`
      service network restart
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
      hostname `grep '^HOSTNAME=' /etc/sysconfig/network | sed -e 's/^HOSTNAME=//'`
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
if grep -E '^HOSTNAME.*localhost' /etc/sysconfig/network ; then
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
      hostname `grep '^HOSTNAME=' /etc/sysconfig/network | sed -e 's/^HOSTNAME=//'`
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
  read -p "Enable NTP and synchronize clock? " ENABLE_NTP_SYNC
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

# Gather information from the user, and perform eucalyptus.conf property edits
echo ""
echo "We need some network information"
EUCACONFIG=/etc/eucalyptus/eucalyptus.conf
edit_prop VNET_MODE "Which Eucalyptus networking mode would you like to use? " $EUCACONFIG
edit_prop VNET_PUBINTERFACE "The NC public ethernet interface (connected to Frontend private network)" $EUCACONFIG
NC_PUBINTERFACE=`grep '^VNET_PUBINTERFACE=' /etc/eucalyptus/eucalyptus.conf | sed -e 's/.*VNET_PUBINTERFACE=\"\(.*\)\"/\1/'`

# Make some configuration changes based on user input and OS version
case "$ELVERSION" in
"5")
  NC_BRIDGE="xenbr0"
  sed -i -e "s/.*VNET_BRIDGE=\".*\"/VNET_BRIDGE=\"$NC_BRIDGE\"/" /etc/eucalyptus/eucalyptus.conf
  # Edit the xen configuration files
  echo "$(date) - Configuring xen" | tee -a $LOGFILE
  sed -i -e "s/.*(xend-http-server .*/(xend-http-server yes)/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
  sed -i -e "s/.*(xend-address localhost)/(xend-address localhost)/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
  sed -i -e "s/^(network-script network-bridge)/(network-script 'network-bridge netdev=$NC_PUBINTERFACE')/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
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
  if ! grep -E '^NM_CONTROLLED=' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE} > /dev/null ; then
    echo 'NM_CONTROLLED=no' >> /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
  else
    sed -i -e 's/NM_CONTROLLED=.*/NM_CONTROLLED=no/' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
  fi
  if ! grep -E '^ONBOOT=' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE} > /dev/null ; then
    echo 'ONBOOT=yes' >> /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
  else
    sed -i -e 's/ONBOOT=.*/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
  fi
  service network restart
;;
"6")
  NC_BRIDGE="br0"
  sed -i -e "s/.*VNET_BRIDGE=\".*\"/VNET_BRIDGE=\"$NC_BRIDGE\"/" /etc/eucalyptus/eucalyptus.conf
  sed -i -e "s/#CREATE_NC_LOOP_DEVICES.*/CREATE_NC_LOOP_DEVICES=256/" /etc/eucalyptus/eucalyptus.conf
  error_check
  brctl show | grep ^${NC_BRIDGE}
  if [ $? -ne 0 ] ; then
    echo "$(date) - Creating bridge $NC_BRIDGE on $NC_PUBINTERFACE" | tee -a $LOGFILE
    if [ ! -f /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE} ] ; then
      cp /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE} /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      sed -i -e "s/DEVICE=${NC_PUBINTERFACE}/DEVICE=${NC_BRIDGE}/" /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      sed -i -e '/HWADDR=/d' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      sed -i -e 's/TYPE=Ethernet/TYPE=Bridge/g' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      if ! grep -E 'TYPE' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE} > /dev/null ; then
        echo "TYPE=Bridge" >> /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      fi
      if ! grep -E 'DELAY' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE} > /dev/null ; then
        echo "DELAY=0" >> /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      fi
      if ! grep -E '^NM_CONTROLLED=' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE} > /dev/null ; then
        echo 'NM_CONTROLLED=no' >> /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      else
        sed -i -e 's/NM_CONTROLLED=.*/NM_CONTROLLED=no/' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      fi
      if ! grep -E '^ONBOOT=' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE} > /dev/null ; then
        echo 'ONBOOT=yes' >> /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      else
        sed -i -e 's/ONBOOT=.*/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      fi
      if ! grep -E "BRIDGE=${NC_BRIDGE}" /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE} > /dev/null ; then
        echo "BRIDGE=${NC_BRIDGE}" >> /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
      fi
      sed -i -e '/BOOTPROTO/d' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
      sed -i -e '/IPADDR/d' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
      sed -i -e '/NETMASK/d' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
      if ! grep -E '^NM_CONTROLLED=' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE} > /dev/null ; then
        echo 'NM_CONTROLLED=no' >> /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
      else
        sed -i -e 's/NM_CONTROLLED=.*/NM_CONTROLLED=no/' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
      fi
      if ! grep -E '^ONBOOT=' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE} > /dev/null ; then
        echo 'ONBOOT=yes' >> /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
      else
        sed -i -e 's/ONBOOT=.*/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE}
      fi
    fi
    chkconfig network on
    service network restart
    error_check
  fi
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

echo "This machine is ready and running as a Node Controller."
echo "You can re-run this configuration scipt  later by executing"
echo "/usr/local/sbin/eucalyptus-nc-config.sh as root."
echo ""
echo "After all Node Controllers are installed and configured, install and configure"
echo "your Frontend server."

if [ $ELVERSION -eq 5 ] ; then
  echo "Your system needs to reboot to complete configuration changes."
  read -p "Press [Enter] key to reboot..."
  shutdown -r now
fi

