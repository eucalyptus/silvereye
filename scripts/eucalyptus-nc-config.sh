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

# Set VNET_PUBINTERFACE and VNET_PRIVINTERFACE with default values if the
# current values don't have IP addresses assigned to them
DEFAULTROUTEINTERFACE=`route -n | grep '^0.0.0.0' | awk '{ print $NF }'`
EUCACONF_PUBINTERFACE=`grep '^VNET_PUBINTERFACE' /etc/eucalyptus/eucalyptus.conf | sed -e 's/VNET_PUBINTERFACE=\"\(.*\)\"/\1/'`
EUCACONF_PRIVINTERFACE=`grep '^VNET_PRIVINTERFACE' /etc/eucalyptus/eucalyptus.conf | sed -e 's/VNET_PRIVINTERFACE=\"\(.*\)\"/\1/'`
EUCACONF_PUBINTERFACEIPS=`ip addr | grep inet | grep $EUCACONF_PUBINTERFACE | wc -l`
EUCACONF_PRIVINTERFACEIPS=`ip addr | grep inet | grep $EUCACONF_PRIVINTERFACE | wc -l`
if [ $DEFAULTROUTEINTERFACE ] ; then
  if [ $EUCACONF_PUBINTERFACEIPS -eq 0 ] ; then
    sed -i -e "s/^VNET_PUBINTERFACE.*$/VNET_PUBINTERFACE=\"$DEFAULTROUTEINTERFACE\"/" /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
  fi
  if [ $EUCACONF_PRIVINTERFACEIPS -eq 0 ] ; then
    sed -i -e "s/^VNET_PRIVINTERFACE.*$/VNET_PRIVINTERFACE=\"$DEFAULTROUTEINTERFACE\"/" /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
  fi
fi

# Test for Internet connectivity, and give the user a chance to exit prior to NTP sync
curl http://www.eucalyptus.com/ >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo ""
  echo "***************"
  echo "*** WARNING ***"
  echo "***************"
  echo ""
  echo "This system is unable to reach www.eucalyptus.com on the Internet."
  echo ""
  echo "If your system should have Internet connectivity, then this is likely the result"
  echo "of incorrect network settings."
  echo ""
  echo "The next section of this script uses Internet connectivity to set the system"
  echo "clock and will not function correctly without it."
  RECONFIGURENETWORK=""
  while ! echo "$RECONFIGURENETWORK" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
    RECONFIGURENETWORK="Yes"
    echo ""
    read -p "Would you like to exit this script to reconfigure your network? [$RECONFIGURENETWORK] " reconfigure_network
    if [ $reconfigure_network ]
    then
      RECONFIGURENETWORK=$reconfigure_network
    fi
    echo ""
    case "$RECONFIGURENETWORK" in
    y|Y|yes|YES|Yes)
      echo "Please fix your network settings using one of the methods below:"
      echo ""
      echo "1) Use the 'system-config-network' command to get a menu-driven interface for"
      echo "   modifying your network settings."
      echo ""
      echo "2) Manually edit one or more of these network configuration files:"
      echo "   a) /etc/sysconfig/network-scripts/ifcfg-*"
      echo "   b) /etc/sysconfig/network"
      echo "   c) /etc/sysconfig/resolv.conf"
      echo ""
        echo "3) Re-install your system, and make sure you click the 'Configure Network'"
        echo "   button when prompted to enter your hostname.  Also make sure to check the"
        echo "   'Connect Automatically' box for each network interface that you want enabled"
        echo "   when the system boots."
      esac
      echo ""
      echo "If you choose (1) or (2) to fix your existing installation, use"
      echo "'service network restart' to apply your networking changes, then re-run this"
      echo "configuration script, /usr/local/sbin/eucalyptus-frontend-config.sh"
      echo ""
      exit -1;
      ;;
    n|N|no|NO|No)
      echo ""
      echo "$(date)- Continuing without Internet connectivity." | tee -a $LOGFILE
      echo ""
      echo "It is recommended that you skip NTP configuration and syncronization in the"
      echo "next step."
      echo ""
      ;;
    *)
      echo "Please answer either 'yes' or 'no'."
      ;;
    esac
  done
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
  read -p "Enable NTP and synchronize clock? [$ENABLENTPSYNC]" enable_ntp_sync
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
    echo ""
    ;;
  n|N|no|NO|No)
    echo "$(date)- Skipped NTP configuration and syncrhonization." | tee -a $LOGFILE
    echo ""
    ;;
  *)
    echo "Please answer either 'yes' or 'no'."
    echo ""
    ;;
  esac
done
echo ""

# Edit the default eucalyptus.conf
sed --in-place 's/^VNET_MODE="SYSTEM"/#VNET_MODE="SYSTEM"/' /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1

# Gather information from the user, and perform eucalyptus.conf property edits
echo "We need some network information"
echo ""
EUCACONFIG=/etc/eucalyptus/eucalyptus.conf
edit_prop VNET_MODE "Which Eucalyptus networking mode would you like to use? " $EUCACONFIG
edit_prop VNET_PUBINTERFACE "The NC public ethernet interface (connected to Frontend private network)" $EUCACONFIG
NC_PUBINTERFACE=`grep '^VNET_PUBINTERFACE=' /etc/eucalyptus/eucalyptus.conf | sed -e 's/.*VNET_PUBINTERFACE=\"\(.*\)\"/\1/'`

# Make some configuration changes based on user input
  NC_BRIDGE="br0"
  sed -i -e "s/.*VNET_BRIDGE=\".*\"/VNET_BRIDGE=\"$NC_BRIDGE\"/" /etc/eucalyptus/eucalyptus.conf
  sed -i -e "s/#CREATE_NC_LOOP_DEVICES.*/CREATE_NC_LOOP_DEVICES=256/" /etc/eucalyptus/eucalyptus.conf
  error_check
  brctl show | grep ^${NC_BRIDGE}
  if [ $? -ne 0 ] ; then
    echo "$(date) - Creating bridge $NC_BRIDGE on $NC_PUBINTERFACE" | tee -a $LOGFILE
    if [ ! -f /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE} ] ; then
      cp /etc/sysconfig/network-scripts/ifcfg-${NC_PUBINTERFACE} /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      sed -i -e "s/DEVICE=.*/DEVICE=\"${NC_BRIDGE}\"/" /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      sed -i -e '/HWADDR=/d' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      sed -i -e '/UUID=/d' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      sed -i -e '/NAME=/d' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
      sed -i -e 's/TYPE=.*/TYPE="Bridge"/g' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE}
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

sed -i -e '/^-A FORWARD -j REJECT/d' /etc/sysconfig/iptables
iptables-restore < /etc/sysconfig/iptables

# Start and configure eucalyptus-nc service
/etc/init.d/eucalyptus-nc start >>$LOGFILE 2>&1
error_check
/sbin/chkconfig eucalyptus-nc on >>$LOGFILE 2>&1
error_check

echo ""
echo "This machine is ready and running as a Node Controller."
echo ""
echo "You can re-run this configuration script later by executing"
echo "/usr/local/sbin/eucalyptus-nc-config.sh as root."
echo ""
echo "After all Node Controllers are installed and configured, install and configure"
echo "your Frontend server."
echo ""
