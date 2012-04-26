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
#
# This script will create a customized CentOS x86_64 minimal installation
# CD image that includes Eucalyptus in the installations.
# The script should be used from an existing CentOS x86_64 installation.
# If the EPEL, ELRepo, euca2ools and Eucalyptus package repositories are not
# present on the system this script will install/create them.
#
# If you have a local mirror that you prefer to use, set up your yum
# configuration to use it, and uncomment the line below.
#MIRROR="http://192.168.7.65/centos/$(cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/')/os/x86_64/"
#EPELMIRROR="http://192.168.7.65/epel/$(cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/')/x86_64/"
#if grep -E '(CentOS release 5)' /etc/redhat-release ; then
#  ELREPO_PACKAGE_URL='http://192.168.7.65/elrepo/el5/x86_64/RPMS/elrepo-release-5-3.el5.elrepo.noarch.rpm'
#elif grep -E '(CentOS release 6)' /etc/redhat-release ; then
#  ELREPO_PACKAGE_URL='http://192.168.7.65/elrepo/el6/x86_64/RPMS/elrepo-release-6-4.el6.elrepo.noarch.rpm'
#fi
#YUM_ELREPO_URL='http://192.168.7.65/elrepo'

EUCALYPTUSVERSION="3.0"

# For paid subscriptions, enter your yum credentials in these variables
ENTERPRISECERT="-----BEGIN CERTIFICATE-----
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXX
-----END CERTIFICATE-----"
ENTERPRISEPRIVATEKEY="-----BEGIN RSA PRIVATE KEY-----
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
-----END RSA PRIVATE KEY-----"
EUCAGPGKEY="-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.11 (GNU/Linux)

mQINBE4yDpIBEADNEtgH4rY7UvCJ5M/i3z1hNaIPyWaDx2CpiCDR+P13eDDBSQ7m
9n8lOKYQtFG3v37XgtNeZSiKvcelNflYsAlGohcPnGcYE3QU58oq7nBhKer2ozdQ
3GDm/KxsvwUF2sqiRHG+HVcK3QGeZHaOGhIj2n/4d0dmbphvDf7EzYhsz+ylZGRo
0S1jL1VXi1hDqjTNYvdv3BS2lmpRKnfuyTF2vBP11m/i2y0JvrZkWgQB1CcMU1U5
tQSuxV6q0e2rTU3w4NPrDJwC9+Y2ajWGGZozqyN+tPJ6DZTbql/5msFJXdS2tvKq
nWvyo5M2Ke92tn6JnNWl6a/NudtQOitlgky0DkgFhTGArGwPImdhKGTOsQOw2vln
SbhOOd0+Fg8woEM8S27ViVH75ULe5WsxqzN9EdlgFh0JfFT6HgN95U5o+yjOsAr3
xaX/r1uyevooe3ow+MiFEMYlASgkxfjklveaPE4b00n/cZSq03i0Fz5+Nwgq1Uwj
wqSEJMOGtBO2sXroB7Qzcm1dlQJL2au+by5yFvmIR3v2tDyu84T4SVSMfU61B0+b
Z2+ufwUrGHkvQSEmfI3NswzJKP4lEh52VaLQx9NZ0qYlap2i3QkW+xCx37VTAViU
TbggQzck25fiIveVpyi/0khDHio3ZeX06i4XoAdtsaYckfROzpwZnu0MawARAQAB
tEBFdWNhbHlwdHVzIFN5c3RlbXMsIEluYy4gKHJlbGVhc2Uga2V5KSA8c2VjdXJp
dHlAZXVjYWx5cHR1cy5jb20+iQI4BBMBAgAiBQJOMhAnAhsDBgsJCAcDAgYVCAIJ
CgsEFgIDAQIeAQIXgAAKCRC+Jk0JwSQFluz9D/sHoShHF6MCc+c+VI8yYHXAkv7h
nOahm/H76Pnt1VTGI2J4Sl+A/e3KpGjxa3Ii8xN5MhQNQ9jSJFDdLuaD4BmbjZF3
WOObFvgTTw42mfXrUo/F4sthVwEvU4o1cvfVyM91kzg5X6u8K91gcVmsJvPOn3Uh
Z7SQOfv0BzbBb6XR3Wi5fvMlE0Tfbc2SEJ1l0Au9QjvuH2tVfCaHkPsWn6s8ONfQ
l+jclkfZNjfaAPStMj8ZylizA0Wgib+RffNAe8BlbGrZwum8Sk005jhGKkQmYz7L
nMg8dPIvQFxKeQddE4o11Jy9LUMXuJBsu2TMFWf1zEzrVi+BzBj61HeM3CbTYO9i
fbOhYdiaRtHHuWnH2Nh7+u2rDkU1lfNotFM1yEoldhYnHklN2ZB4OiY3yCG1a4qN
KYTshqoyQPOa8PYAObydKJweNgNRhO74s6AZHMR4TR/Mp+cgXMXZIbnuxut0UwkC
GditoANmgURXaZ2GA3Vy+5IgNCwJjOikjeGZLqijCj5T92Viju70UW8nipp5eIXp
i23Z9QLc/+V1HhkiONLLAaGPCuAtvPLOCkALKjKOBJ4uMdPRl/Vqo2S7URUbjml1
tZQspPYhQh95SwUg0imvo7k2UO4sW/Tatq3oS25T9wtJYREYjn4MbEUI0FBxGn5k
2T2jSGSw43cM9hVBqQ==
=Xs3z
-----END PGP PUBLIC KEY BLOCK-----"

# Modification below this point shouldn't be necessary

# Function to install packages on build system if they aren't already present
function install_package {
  rpm -q $1 > /dev/null
  if [ $? -eq 1 ] ; then
    echo "$(date) - Installing $1 package" | tee -a $SILVEREYELOGFILE
    yum -y install $1
  else
    echo "$(date) - $1 package already installed" | tee -a $SILVEREYELOGFILE
  fi
}

# Create the build directory structure and cd into it
ELVERSION=`cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/'`
DATESTAMP=`date +%s.%N | rev | cut -b 4- | rev`
case "$ELVERSION" in
"5")
  PACKAGESDIR="CentOS"
  ;;
"6")
  PACKAGESDIR="Packages"
  ;;
*)
  echo "$(date)- Error: This script must be run on CentOS version 5 or 6" |tee -a $SILVEREYELOGFILE
  exit 1
  ;;
esac
mkdir -p silvereye_build.${DATESTAMP}/isolinux/{${PACKAGESDIR},images,ks}
mkdir -p silvereye_build.${DATESTAMP}/isolinux/images/pxeboot
if [ $ELVERSION -eq 5 ] ; then
  mkdir -p silvereye_build.${DATESTAMP}/isolinux/images/xen
fi
cd silvereye_build.$DATESTAMP
BUILDDIR=`pwd`
SILVEREYELOGFILE="${BUILDDIR}/silvereye.$DATESTAMP.log"
echo "$(date) - Created $BUILDDIR directory structure" | tee -a $SILVEREYELOGFILE

# Install curl and wget if they aren't already installed
install_package curl
install_package wget

#Set the mirror to use for retrieving files
if [ -z "$MIRROR" ] ; then
  FETCHMIRROR=`curl -s http://mirrorlist.centos.org/?release=$(cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/')\&arch=x86_64\&repo=os | grep -vE '(^#|^ftp)' | head -n 1`
else
  FETCHMIRROR="${MIRROR}"
fi
echo "$(date) - Using $FETCHMIRROR for downloads" | tee -a $SILVEREYELOGFILE

# Retrieve the comps.xml file
echo "$(date) - Retrieving files" | tee -a $SILVEREYELOGFILE
COMPSFILE=`curl -s ${FETCHMIRROR}repodata/ | grep 'comps.xml\"' | sed -e 's/.*href=\"\(.*comps.xml\)\".*/\1/'`
wget ${FETCHMIRROR}/repodata/${COMPSFILE}

# Retrieve the files for the root filesystem of the CD
wget ${FETCHMIRROR}/.discinfo -O isolinux/.discinfo

# Retrieve the files for the isolinux directory
COMMONISOLINUXFILES="
isolinux/boot.msg
isolinux/initrd.img
isolinux/isolinux.bin
isolinux/isolinux.cfg
isolinux/memtest
isolinux/vmlinuz
"
for FILE in $COMMONISOLINUXFILES ; do
wget ${FETCHMIRROR}/${FILE} -O ${FILE}
done

case "$ELVERSION" in
"5")
  ISOLINUXFILES="
isolinux/general.msg
isolinux/options.msg
isolinux/param.msg
isolinux/rescue.msg
isolinux/splash.lss
"
  ;;
"6")
  ISOLINUXFILES="
isolinux/grub.conf
isolinux/splash.jpg
isolinux/vesamenu.c32
"
  ;;
esac

for FILE in $ISOLINUXFILES ; do
wget ${FETCHMIRROR}/${FILE} -O ${FILE}
done

# Retrieve the files for the images directory
case "$ELVERSION" in
"5")
  IMAGESFILES="
README
boot.iso
minstg2.img
stage2.img
diskboot.img
xen/vmlinuz
xen/initrd.img
pxeboot/README
pxeboot/vmlinuz
pxeboot/initrd.img
"
  ;;
"6")
  IMAGESFILES="
efiboot.img
efidisk.img
install.img
pxeboot/initrd.img
pxeboot/vmlinuz
"
  ;;
esac

for FILE in $IMAGESFILES ; do
wget ${FETCHMIRROR}/images/${FILE} -O ./isolinux/images/${FILE}
done

# Create kickstart files
cat > ${BUILDDIR}/isolinux/ks/frontend.cfg <<"EOFFRONTENDKICKSTART"
# Kickstart file

install
cdrom
network --device=eth0 --bootproto=query
firewall --disabled
authconfig --enableshadow --enablemd5                                                                                                                                                         
selinux --disabled

%packages
@Base
@Core
dbus-python
elrepo-release
epel-release
EUCALYPTUSRELEASEPACKAGEREPLACEME
java-1.6.0-openjdk
libxml2-python
ntp
system-config-network-tui
unzip
eucalyptus-cloud
eucalyptus-cc
eucalyptus-walrus
eucalyptus-sc
euca2ools

%post --log=/root/frontend-ks-post.log
# Set the default Eucalyptus networking mode
sed -i -e 's/^VNET_MODE=\"SYSTEM\"/VNET_MODE=\"MANAGED-NOVLAN"/' /etc/eucalyptus/eucalyptus.conf

# Disable Eucalyptus services before first boot
/sbin/chkconfig eucalyptus-cloud off
/sbin/chkconfig eucalyptus-cc off

# Create Eucalyptus Enterprise download cert/keys
REPLACEMEENTERPRISECERT
REPLACEMEENTERPRISEPRIVATEKEY
REPLACEMEEUCAGPGKEY

# Create eucalyptus-frontend-config.sh script
cat >> /usr/local/sbin/eucalyptus-frontend-config.sh <<"EOF"
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

ELVERSION=`cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/'`

echo ""
echo "Welcome to the Eucalyptus frontend configuration script."
echo ""
echo "It is recommended that the Node Controllers are installed and configured prior to continuing this frontend configuration."
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

# Use network service instead of NetworkManager to manage networking
sed -i -e 's/NM_CONTROLLED=yes/NM_CONTROLLED=no/' /etc/sysconfig/network-scripts/ifcfg-*

# Ask user to reconfigure networking if no static IP address settings are detected
STATICIPS=`grep IPADDR /etc/sysconfig/network-scripts/ifcfg-* | grep -v 127.0.0.1 | wc -l`
if [ $STATICIPS -lt 1 ] ; then
  echo "It looks like none of your network interfaces are configured with static IP addresses."
  echo ""
  echo "It is recommended that you use static IP addressing for configuring the network interfaces on your Eucalyptus infrastructure servers."
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
while ! echo "$CONFIGURE_HOSTNAME" | grep -iE '(^y$|^yes$|^n$|^no$)' ; do
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

# Set VNET_PUBINTERFACE and VNET_PRIVINTERFACE with default values if the current values don't have IP addresses assigned to them
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
echo "The recommended way to ensure time remains synchronized is to enable the NTP service, which synchronizes time with Internet servers."
echo ""
echo "If your systems have Internet access, and you would like to use NTP to synchronize their clocks with the default pool.ntp.org servers, please answer yes."
echo ""
while ! echo "$ENABLE_NTP_SYNC" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
  read -p "Enable NTP and synchronize clock? " ENABLE_NTP_SYNC
  case "$ENABLE_NTP_SYNC" in
  y|Y|yes|YES|Yes)
    echo "$(date)- Setting clock via NTP.  This may take a few minutes." |tee -a $LOGFILE
    if [ -f /var/run/ntpd.pid ] ; then
      service ntpd stop
    fi
    `which ntpd` -q -g >>$LOGFILE 2>&1
    hwclock --systohc >>$LOGFILE 2>&1
    chkconfig ntpd on >>$LOGFILE 2>&1
    service ntpd start >>$LOGFILE 2>&1
    error_check
    echo "$(date)- Set clock and enabled ntp" |tee -a $LOGFILE
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
  echo "$(date)- Generated root's SSH keys" |tee -a $LOGFILE
else
  echo "$(date)- root's SSH keys already exist" |tee -a $LOGFILE
fi
SSH_HOSTNAME=`hostname`
if ! grep "root@${SSH_HOSTNAME}" /root/.ssh/authorized_keys > /dev/null 2>&1
then
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  echo "$(date)- Appended root's public key to authorized_keys" |tee -a $LOGFILE
else
  echo "$(date)- root's public key already present in authorized_keys" |tee -a $LOGFILE
fi

# populate the SSH known_hosts file
for FEIP in `ip addr show |grep inet |grep global|awk -F"[\t /]*" '{ print $3 }'` ; do
  ssh -o StrictHostKeyChecking=no $FEIP "true"
done

# Edit the default eucalyptus.conf, insert default values if no previous configuration is present
if ! grep -E '(^VNET_MODE)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  echo 'VNET_MODE="MANAGED-NOVLAN"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_SUBNET)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  echo 'VNET_SUBNET="192.168.0.0"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_NETMASK)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  echo 'VNET_NETMASK="255.255.255.0"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_DNS)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  PRIMARY_DNS=`grep nameserver /etc/resolv.conf | head -n1 | awk '{print $2}'`
  echo "VNET_DNS=\"$PRIMARY_DNS\"" >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_ADDRSPERNET)' /etc/eucalyptus/eucalyptus.conf > /dev/null
then
  echo 'VNET_ADDRSPERNET="32"' >> /etc/eucalyptus/eucalyptus.conf
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
edit_prop VNET_SUBNET "Eucalyptus-only dedicated subnet" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"
edit_prop VNET_NETMASK "Eucalyptus subnet netmask" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"
edit_prop VNET_DNS "The DNS server address" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"
SUBNET_VAL=`grep VNET_NETMASK $EUCACONFIG|tail -1|cut -d '=' -f 2|tr -d "\""`
ZERO_OCTETS=`echo $SUBNET_VAL |tr "." "\n" |grep 0 |wc -l`
ADDRSPER_REC=32
if [ $ZERO_OCTETS -eq "3" ]	# class A subnet
then
  ADDRSPER_REC=64
elif [ $ZERO_OCTETS -eq "2" ] # class B subnet
then
  ADDRSPER_REC=32
elif [ $ZERO_OCTETS -eq "1" ] # class C subnet
then
  ADDRSPER_REC=16
fi
echo "Based on the size of your private subnet, we recommend the next value be set to $ADDRSPER_REC"
sed --in-place "s/VNET_ADDRSPERNET=\"32\"/VNET_ADDRSPERNET=\"${ADDRSPER_REC}\"/" /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
edit_prop VNET_ADDRSPERNET "How many addresses per net?" $EUCACONFIG "[0-9]*"
echo ""
echo "The range of public IP addresses should be two IP adresses on the public network separated by a - (e.g. '192.168.1.10-192.168.1.50')"
echo "Other public IP address configurations are possible by manually editing your configuration later.  Please read the notes in /etc/eucalyptus/eucalyptus.conf"
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
  echo "$(date)- Initializing Cloud Controller " |tee -a $LOGFILE
  /usr/sbin/euca_conf --initialize
fi

# Start Eucalyptus services prior to registration
echo ""
echo "$(date)- Starting services " |tee -a $LOGFILE
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
echo "$(date)- Started services " |tee -a $LOGFILE

# Prepare to register components
echo "$(date)- Registering components " |tee -a $LOGFILE
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
echo "using public IP $PUBLIC_IP_ADDRESS and private IP $PRIVATE_IP_ADDRESS to register components" |tee -a $LOGFILE

# Register Walrus
if [ `/usr/sbin/euca_conf --list-walruses 2>/dev/null |wc -l` -eq '0' ]
then
  /usr/sbin/euca_conf --register-walrus --partition walrus --host $PUBLIC_IP_ADDRESS --component=walrus |tee -a $LOGFILE 
else
  echo "Walrus already registered. Will not re-register walrus" |tee -a $LOGFILE
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
/usr/sbin/euca_conf --register-cluster --partition $CLUSTER_NAME --host $PUBLIC_IP_ADDRESS --component=cc_01 |tee -a $LOGFILE
/usr/sbin/euca_conf --register-sc --partition $CLUSTER_NAME --host $PRIVATE_IP_ADDRESS --component=sc_01 |tee -a $LOGFILE
error_check

# Deregister previous node controllers
for NCIP in `/usr/sbin/euca_conf --list-nodes 2>/dev/null | awk '{print $2}'`
do
  /usr/sbin/euca_conf --deregister-nodes $NCIP >>$LOGFILE 2>&1
done

# Register node controllers
echo ""
echo "Ready to register node controllers. Once they are installed, enter their IP addresses here, one by one (ENTER when done)"
done="not"
while [ $done != "done" ]
do
  read -p "Node IP :" node
  if [ ! $node ]
  then
    done="done"
    echo "To register node controllers in the future, please run:"
    echo '/usr/sbin/euca_conf --register-nodes "host host ..."'
  else
    echo "Please enter the root password of the node controller when prompted"
    scp -rp /root/.ssh root@${node}:/root/
    ssh root@${node} "service eucalyptus-nc restart"
    /usr/sbin/euca_conf --register-nodes $node |tee -a $LOGFILE
  fi
done
error_check
echo "$(date)- Registered components " |tee -a $LOGFILE
echo ""
echo "Please visit https://$PUBLIC_IP_ADDRESS:8443/ to start using your cloud!"
echo ""

# Ask the user if they would like to install a graphical desktop on the Frontend server
while ! echo "$INSTALL_DESKTOP" | grep -iE '(^y$|^yes$|^n$|^no$)' ; do
echo "If you have Internet access, you can optionally install a graphical desktop."
echo "This will download approximately 300 MB of packages, which may take a long time,"
echo "depending on the speed of your Internet connection."
echo ""
read -p "Would you like to install a graphical desktop on this Frontend server? " INSTALL_DESKTOP
  case "$INSTALL_DESKTOP" in
  y|Y|yes|YES|Yes)
    echo "$(date)- Installing graphical desktop.  This may take a few minutes." |tee -a $LOGFILE
    echo ""
    case "$ELVERSION" in
    "5")
      yum -y groupinstall 'GNOME Desktop Environment' 'X Window System'
      ;;
    "6")
      yum -y groupinstall 'X Window System' 'Desktop'
      ;;
    esac
    yum -y install firefox
    echo ""
    echo "In order to log in to the graphical desktop you must use a non-root user."
    LOCALUSER=""
    while [ -z "$LOCALUSER" ] ; do
      read -p "Please provide a user name for logging in to the graphical desktop: " LOCALUSER
    done
    useradd -d /home/${LOCALUSER} -m ${LOCALUSER}
    echo ""
    echo "Please enter a password for ${LOCALUSER}."
    passwd ${LOCALUSER}
    sed --in-place 's/id:3:initdefault:/id:5:initdefault:/g' /etc/inittab
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
    error_check
    echo "$(date)- Graphical desktop installed.  The system will now change runlevels." |tee -a $LOGFILE
    read -p "Press [Enter] key to change runlevels..."
    init 5
    ;;
  n|N|no|NO|No)
    echo "$(date)- Skipped graphical desktop installation." | tee -a $LOGFILE
    ;;
  *)
    echo "Please answer either 'yes' or 'no'."
    ;;
  esac
done
EOF

chmod 770 /usr/local/sbin/eucalyptus-frontend-config.sh

# Create a backup copy of root's .bash_profile
/bin/cp -a /root/.bash_profile /root/.bash_profile.orig

# Create a backup of /etc/rc.d/rc.local
cp /etc/rc.d/rc.local /etc/rc.d/rc.local.orig
cat >> /etc/rc.d/rc.local <<"EOF"

# Add eucalyptus-frontend-config.sh script to root's .bash_profile, and have the original .bash_profile moved in after the first run
echo '/usr/local/sbin/eucalyptus-frontend-config.sh' >> /root/.bash_profile
echo '/bin/cp -af /root/.bash_profile.orig /root/.bash_profile' >> /root/.bash_profile

# Replace /etc/rc.d/rc.local with the original backup copy
rm -f /etc/rc.d/rc.local
cp /etc/rc.d/rc.local.orig /etc/rc.d/rc.local
EOF

EOFFRONTENDKICKSTART

cat > ${BUILDDIR}/isolinux/ks/nc.cfg <<"EOFNCKICKSTART"
# Kickstart file

install
cdrom
network --device=eth0 --bootproto=query
firewall --disabled
authconfig --enableshadow --enablemd5                                                                                                                                                         
selinux --disabled

%packages
@Base
@Core
bridge-utils
dbus-python
elrepo-release
epel-release
EUCALYPTUSRELEASEPACKAGEREPLACEME
kernel-xen
libxml2-python
ntp
xen
eucalyptus-nc
euca2ools
-kernel

%post --log=/root/nc-ks-post.log
# Workaround for grub not getting installed correctly on software RAID /boot partitions
rpm -q kernel-xen > /dev/null
if [ $? -eq 0 ] ; then
  if mount | grep -E '^/dev/md.*/boot' > /dev/null ; then
    grub-install $(mount | grep -E '^/dev/md.*/boot'|awk '{print $1}')
  fi
fi

# Set the default Eucalyptus networking mode
sed -i -e 's/^VNET_MODE=\"SYSTEM\"/VNET_MODE=\"MANAGED-NOVLAN"/' /etc/eucalyptus/eucalyptus.conf

# Disable Eucalyptus services before first boot
/sbin/chkconfig eucalyptus-nc off

# Create Eucalyptus Enterprise download cert/keys
REPLACEMEENTERPRISECERT
REPLACEMEENTERPRISEPRIVATEKEY
REPLACEMEEUCAGPGKEY

# Create eucalyptus-nc-config.sh script
cat >> /usr/local/sbin/eucalyptus-nc-config.sh <<"EOF"
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

ELVERSION=`cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/'`

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
  echo "It looks like none of your network interfaces are configured with static IP addresses."
  echo ""
  echo "It is recommended that you use static IP addressing for configuring the network interfaces on your Eucalyptus infrastructure servers."
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
if grep -E '^HOSTNAME.*localhost' /etc/sysconfig/network ; then
  echo "It is recommended to configure a hostname other than 'localhost'."
  echo ""
fi
echo "Your currently configured hostname is ${CONFIGUREDHOSTNAME}."
echo ""
echo "You can change this in your DNS settings."
echo ""
while ! echo "$CONFIGURE_HOSTNAME" | grep -iE '(^y$|^yes$|^n$|^no$)' ; do
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

# Set VNET_PUBINTERFACE and VNET_PRIVINTERFACE with default values if the current values don't have IP addresses assigned to them
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
echo "The recommended way to ensure time remains synchronized is to enable the NTP service, which synchronizes time with Internet servers."
echo ""
echo "If your systems have Internet access, and you would like to use NTP to synchronize their clocks with the default pool.ntp.org servers, please answer yes."
echo ""
while ! echo "$ENABLE_NTP_SYNC" | grep -iE '(^y$|^yes$|^n$|^no$)' > /dev/null ; do
  read -p "Enable NTP and synchronize clock? " ENABLE_NTP_SYNC
  case "$ENABLE_NTP_SYNC" in
  y|Y|yes|YES|Yes)
    echo "$(date)- Setting clock via NTP.  This may take a few minutes." |tee -a $LOGFILE
    if [ -f /var/run/ntpd.pid ] ; then
      service ntpd stop
    fi
    `which ntpd` -q -g >>$LOGFILE 2>&1
    hwclock --systohc >>$LOGFILE 2>&1
    chkconfig ntpd on >>$LOGFILE 2>&1
    service ntpd start >>$LOGFILE 2>&1
    error_check
    echo "$(date)- Set clock and enabled ntp" |tee -a $LOGFILE
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
  echo "$(date) - Configuring xen" |tee -a $LOGFILE
  sed -i -e "s/.*(xend-http-server .*/(xend-http-server yes)/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
  sed -i -e "s/.*(xend-address localhost)/(xend-address localhost)/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
  sed -i -e "s/^(network-script network-bridge)/(network-script 'network-bridge netdev=$NC_PUBINTERFACE')/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
  sed -i -e "s/^(xend-relocation-hosts-allow/#(xend-relocation-hosts-allow/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
  sed -i -e "s/(dom0-min-mem 256)/(dom0-min-mem 196)/" /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
  sed -i -e "s/.*XENCONSOLED_LOG_GUESTS.*/XENCONSOLED_LOG_GUESTS=yes/" /etc/sysconfig/xend >>$LOGFILE 2>&1
  service xend restart >>$LOGFILE 2>&1
  error_check
  echo "$(date) - Customized xen configuration" |tee -a $LOGFILE
  # Edit the libvirt.conf file
  echo "$(date) - Configuring libvirt " |tee -a $LOGFILE
  sed -i -e 's/.*unix_sock_group.*/unix_sock_group = "eucalyptus"/' /etc/libvirt/libvirtd.conf >>$LOGFILE 2>&1
  sed -i -e 's/.*unix_sock_ro_perms.*/unix_sock_ro_perms = "0777"/' /etc/libvirt/libvirtd.conf >>$LOGFILE 2>&1
  sed -i -e 's/.*unix_sock_rw_perms.*/unix_sock_rw_perms = "0770"/' /etc/libvirt/libvirtd.conf >>$LOGFILE 2>&1
  service libvirtd restart  >>$LOGFILE 2>&1
  error_check
  echo "$(date) - Customized libvirt configuration" |tee -a $LOGFILE
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
      if ! grep -E 'TYPE' /etc/sysconfig/network-scripts/ifcfg-${NC_BRIDGE} ; then
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
echo "You can re-run this configuration scipt  later by executing /usr/local/sbin/eucalyptus-nc-config.sh as root."
echo ""
echo "After all Node Controllers are installed and configured, install and configure your Frontend server."

if [ $ELVERSION -eq 5 ] ; then
  echo "Your system needs to reboot to complete configuration changes."
  read -p "Press [Enter] key to reboot..."
  shutdown -r now
fi

EOF

chmod 770 /usr/local/sbin/eucalyptus-nc-config.sh

# Create a backup copy of root's .bash_profile
/bin/cp -a /root/.bash_profile /root/.bash_profile.orig

# Create a backup of /etc/rc.d/rc.local
cp /etc/rc.d/rc.local /etc/rc.d/rc.local.orig
cat >> /etc/rc.d/rc.local <<"EOF"

# Add eucalyptus-nc-config.sh script to root's .bash_profile, and have the original .bash_profile moved in after the first run
echo '/usr/local/sbin/eucalyptus-nc-config.sh' >> /root/.bash_profile
echo '/bin/cp -af /root/.bash_profile.orig /root/.bash_profile' >> /root/.bash_profile

# Replace /etc/rc.d/rc.local with the original backup copy
rm -f /etc/rc.d/rc.local
cp /etc/rc.d/rc.local.orig /etc/rc.d/rc.local
EOF

EOFNCKICKSTART

cat > ${BUILDDIR}/isolinux/ks/minimal.cfg <<"EOFMINIMALKICKSTART"
# Kickstart file

install
cdrom
network --device=eth0 --bootproto=query
firewall --disabled
authconfig --enableshadow --enablemd5                                                                                                                                                         
selinux --disabled

%packages
@Core

EOFMINIMALKICKSTART

cat > ${BUILDDIR}/isolinux/ks/core.cfg <<"EOFCOREKICKSTART"
# Kickstart file

install
cdrom
network --device=eth0 --bootproto=query
firewall --disabled
authconfig --enableshadow --enablemd5                                                                                                                                                         
selinux --disabled

%packages --nobase --excludedocs
@Core

EOFCOREKICKSTART

# Customize kickstart files for CentOS 5 or CentOS 6, and Eucalyptus Enterprise or Open Source
case "$ELVERSION" in
"5")
  # sed -i -e '/%end/d' ${BUILDDIR}/isolinux/ks/*.cfg
  ;;
"6")
  sed -i -e 's/^network .*query$/network --activate/' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/^dbus-python$/d' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/^kernel-xen$/d' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/^libxml2-python$/d' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/^xen$/d' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/^-kernel$/d' ${BUILDDIR}/isolinux/ks/*.cfg
  ;;
esac
case "$EUCALYPTUSVERSION" in
"3.0")
  sed -i -e 's/EUCALYPTUSRELEASEPACKAGEREPLACEME/eucalyptus-release-enterprise/' ${BUILDDIR}/isolinux/ks/*.cfg
  # Fix Eucalyptus Enterprise download cert/keys
  sed -i -e "s#REPLACEMEENTERPRISECERT#echo \"`echo -e "${ENTERPRISECERT}" | sed ':a;N;$!ba;s/\n/NEWLINETAG/g'`\" > /etc/pki/tls/certs/eucalyptus-enterprise.crt#" ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e "s#REPLACEMEENTERPRISEPRIVATEKEY#echo \"`echo -e "${ENTERPRISEPRIVATEKEY}" | sed ':a;N;$!ba;s/\n/NEWLINETAG/g'`\" > /etc/pki/tls/certs/eucalyptus-enterprise.crt#" ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e "s#REPLACEMEEUCAGPGKEY#echo \"`echo -e "${EUCAGPGKEY}" | sed ':a;N;$!ba;s/\n/NEWLINETAG/g'`\" > /etc/pki/tls/certs/eucalyptus-enterprise.crt#" ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e 's/NEWLINETAG/\n/g' ${BUILDDIR}/isolinux/ks/*.cfg
  ;;
"3.1")
  sed -i -e 's/EUCALYPTUSRELEASEPACKAGEREPLACEME/eucalyptus-nightly-release/' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/REPLACEMEENTERPRISECERT/d' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/REPLACEMEENTERPRISEPRIVATEKEY/d' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/REPLACEMEEUCAGPGKEY/d' ${BUILDDIR}/isolinux/ks/*.cfg
  ;;
esac

# Install yum-utils if it isn't already installed
install_package yum-utils

# Install/configure yum repositories
# Install/configure EPEL repository
rpm -q epel-release > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing EPEL package" | tee -a $SILVEREYELOGFILE
  if [ -z "$EPELMIRROR" ] ; then
    EPELFETCHMIRROR=`curl -s http://mirrors.fedoraproject.org/mirrorlist?repo=epel-$(cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/')\&arch=x86_64 | grep -vE '(^#|^ftp)' | head -n 1`
  else
    EPELFETCHMIRROR="${EPELMIRROR}"
  fi
  case "$ELVERSION" in
  "5")
    wget ${EPELFETCHMIRROR}epel-release-5-4.noarch.rpm
    ;;
  "6")
    wget ${EPELFETCHMIRROR}epel-release-6-5.noarch.rpm
    ;;
  esac
  rpm -Uvh epel-release-*.noarch.rpm
  rm -f epel-release-*.noarch.rpm
else
  echo "$(date) - EPEL package already installed" | tee -a $SILVEREYELOGFILE
fi

# Install/configure ELRepo repository
rpm -q elrepo-release > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing ELRepo package" | tee -a $SILVEREYELOGFILE
  if [ ! $ELREPO_PACKAGE_URL ] ; then
    case "$ELVERSION" in
    "5")
      ELREPO_PACKAGE_URL='http://elrepo.org/linux/elrepo/el5/x86_64/RPMS/elrepo-release-5-3.el5.elrepo.noarch.rpm'
      ;;
    "6")
      ELREPO_PACKAGE_URL='http://elrepo.org/linux/elrepo/el6/x86_64/RPMS/elrepo-release-6-4.el6.elrepo.noarch.rpm'
      ;;
    esac
  fi
  wget $ELREPO_PACKAGE_URL
  rpm -Uvh elrepo-release-*.noarch.rpm
  rm -f elrepo-release-*.noarch.rpm
else
  echo "$(date) - ELRepo package already installed" | tee -a $SILVEREYELOGFILE
fi
if [ -n "$YUM_ELREPO_URL" ] ; then
  sed -i -e 's%^mirrorlist=http.*%#\0%g' /etc/yum.repos.d/elrepo.repo
  sed -i -e "s%baseurl=http://elrepo.org/linux/elrepo%baseurl=$YUM_ELREPO_URL%g" /etc/yum.repos.d/elrepo.repo
fi

# Install/configure Eucalyptus repository
case "$EUCALYPTUSVERSION" in
"3.0")
  # Create Eucalyptus yum credentials
  echo "$ENTERPRISECERT" > /etc/pki/tls/certs/eucalyptus-enterprise.crt
  echo "$ENTERPRISEPRIVATEKEY" > /etc/pki/tls/private/eucalyptus-enterprise.key
  echo "$EUCAGPGKEY" > /etc/pki/rpm-gpg/eucalyptus-release-key.pub
  # Create Eucalyptus yum repository files
  echo "$(date) - Creating Eucalyptus Enterprise repository" | tee -a $SILVEREYELOGFILE
  cat > /etc/yum.repos.d/eucalyptus-enterprise.repo << "EOF"
[eucalyptus-enterprise]
name=Eucalyptus Enterprise 3.0
baseurl=https://downloads.eucalyptus.com/software/enterprise/3.0/centos/$releasever/$basearch
gpgkey=file:///etc/pki/rpm-gpg/eucalyptus-release-key.pub
gpgcheck=1
sslclientcert=/etc/pki/tls/certs/eucalyptus-enterprise.crt
sslclientkey=/etc/pki/tls/private/eucalyptus-enterprise.key
EOF
  ;;
"3.1")
  rpm -q eucalyptus-nightly-release > /dev/null
  if [ $? -eq 1 ] ; then
    echo "$(date) - Installing Eucalyptus nightly repository package" | tee -a $SILVEREYELOGFILE
    wget http://downloads.eucalyptus.com/devel/packages/3-devel/nightly/centos/${ELVERSION}/x86_64/eucalyptus-nightly-release-3-1.el.noarch.rpm
    rpm -Uvh eucalyptus-nightly-release-*.rpm
    rm -f eucalyptus-nightly-release-*.rpm
  else
    echo "$(date) - Eucalyptus nightly repository package already installed" | tee -a $SILVEREYELOGFILE
  fi
  ;;
*)
  echo "$(date) - Unsupported EUCALYPTUSVERSION $EUCALYPTUSVERSION" | tee -a $SILVEREYELOGFILE
  ;;
esac

# Create euca2ools repository file
echo "$(date) - Creating euca2ools repository" | tee -a $SILVEREYELOGFILE
cat > /etc/yum.repos.d/euca2ools.repo << "EOF"
[euca2ools]
name=Euca2ools 2.0
baseurl=https://downloads.eucalyptus.com/software/euca2ools/2.0/centos/$releasever/$basearch
gpgkey=file:///etc/pki/rpm-gpg/eucalyptus-release-key.pub
gpgcheck=1
EOF

# Retrieve the RPMs for a minimal CentOS, Eucalyptus, and Eucalyptus dependencies
# Set list of RPMs to download
case "$ELVERSION" in
"5")
  RPMS="alsa-lib.x86_64 antlr.x86_64 apr.x86_64 apr-util.x86_64 atk.x86_64 audiofile.x86_64 \
audit-libs.x86_64 avahi.x86_64 avalon-framework.x86_64 avalon-logkit.x86_64 axis.x86_64 \
axis2c.x86_64 basesystem.noarch bash.x86_64 bcel.x86_64 binutils.x86_64 \
bitstream-vera-fonts.noarch bridge-utils.x86_64 bzip2.x86_64 bzip2-libs.x86_64 cairo.x86_64 \
centos-release.x86_64 centos-release-notes.x86_64 chkconfig.x86_64 classpathx-jaf.x86_64 \
classpathx-mail.x86_64 coreutils.x86_64 cpio.x86_64 cracklib.x86_64 cracklib-dicts.x86_64 \
crontabs.noarch cryptsetup-luks.x86_64 cups-libs.x86_64 curl.x86_64 cyrus-sasl.x86_64 \
cyrus-sasl-lib.x86_64 cyrus-sasl-md5.x86_64 db4.x86_64 dbus.x86_64 dbus-glib.x86_64 \
dbus-libs.x86_64 dbus-python.x86_64 device-mapper.x86_64 device-mapper-event.x86_64 \
device-mapper-multipath.x86_64 dhclient.x86_64 dhcp.x86_64 diffutils.x86_64 dmidecode.x86_64 \
dmraid.x86_64 dmraid-events.x86_64 dnsmasq.x86_64 drbd83-utils.x86_64 e2fsprogs.x86_64 \
e2fsprogs-libs.x86_64 e4fsprogs-libs.x86_64 ebtables.x86_64 ed.x86_64 elfutils-libelf.x86_64 \
elrepo-release.noarch epel-release.noarch esound.x86_64 ethtool.x86_64 euca2ools.noarch \
eucalyptus.x86_64 eucalyptus-admin-tools.x86_64 eucalyptus-broker.x86_64 eucalyptus-cc.x86_64 \
eucalyptus-cloud eucalyptus-common-java.x86_64 eucalyptus-gl.x86_64 eucalyptus-nc.x86_64 \
eucalyptus-sc.x86_64 eucalyptus-walrus.x86_64 expat.x86_64 file.x86_64 filesystem.x86_64 \
findutils.x86_64 fipscheck.x86_64 fipscheck-lib.x86_64 fontconfig.x86_64 freetype.x86_64 \
fuse-libs.x86_64 gawk.x86_64 gdbm.x86_64 geronimo-specs.x86_64 geronimo-specs-compat.x86_64 \
giflib.x86_64 gjdoc.x86_64 glib2.x86_64 glibc.i686 glibc.x86_64 glibc-common.x86_64 gnutls.x86_64 \
grep.x86_64 grub.x86_64 gtk2.x86_64 gzip.x86_64 hal.x86_64 hesiod.x86_64 hicolor-icon-theme.noarch \
hmaccalc.x86_64 httpd.x86_64 hwdata.noarch info.x86_64 initscripts.x86_64 iproute.x86_64 \
iptables.x86_64 iptables-ipv6.x86_64 iputils.x86_64 iscsi-initiator-utils.x86_64 \
jakarta-commons-collections.x86_64 jakarta-commons-discovery.x86_64 \
jakarta-commons-httpclient.x86_64 jakarta-commons-logging.x86_64 jakarta-oro.x86_64 \
java-1.4.2-gcj-compat.x86_64 java-1.6.0-openjdk.x86_64 jdom.x86_64 jpackage-utils.noarch kbd.x86_64 \
kernel.x86_64 kernel-xen.x86_64 keyutils-libs.x86_64 kmod-drbd83.x86_64 kpartx.x86_64 \
krb5-libs.x86_64 kudzu.x86_64 less.x86_64 libacl.x86_64 libart_lgpl.x86_64 libattr.x86_64 \
libcap.x86_64 libdaemon.x86_64 libevent.x86_64 libffi.x86_64 libgcc.i386 libgcc.x86_64 \
libgcj.x86_64 libgcrypt.x86_64 libgpg-error.x86_64 libgssapi.x86_64 libICE.x86_64 libidn.x86_64 \
libibverbs.x86_64 libjpeg.x86_64 libpng.x86_64 librdmacm.x86_64 libselinux.x86_64 \
libselinux-python.x86_64 libsepol.x86_64 libSM.x86_64 libstdc++.x86_64 libsysfs.x86_64 \
libtermcap.x86_64 libtiff.x86_64 libusb.x86_64 libuser.x86_64 libutempter.x86_64 libvirt.x86_64 \
libvirt-python.x86_64 libvolume_id.x86_64 libX11.x86_64 libXau.x86_64 libXcursor.x86_64 \
libXdmcp.x86_64 libXext.x86_64 libXfixes.x86_64 libXft.x86_64 libXi.x86_64 libXinerama.x86_64 \
libxml2.x86_64 libxml2-python.x86_64 libXrandr.x86_64 libXrender.x86_64 libxslt.x86_64 \
libXtst.x86_64 log4j.x86_64 logrotate.x86_64 lvm2.x86_64 lzo.x86_64 m2crypto.x86_64 mailcap.noarch \
MAKEDEV.x86_64 mcstrans.x86_64 mdadm.x86_64 mingetty.x86_64 mkinitrd.x86_64 mktemp.x86_64 \
module-init-tools.x86_64 mx4j.x86_64 mysql.x86_64 nash.x86_64 nc.x86_64 ncurses.x86_64 \
net-tools.x86_64 newt.x86_64 nfs-utils.x86_64 nfs-utils-lib.x86_64 nspr.x86_64 nss.x86_64 \
ntp.x86_64 numactl.x86_64 openib.noarch openldap.x86_64 openssh.x86_64 openssh-clients.x86_64 \
openssh-server.x86_64 openssl.x86_64 pam.x86_64 pango.x86_64 parted.x86_64 passwd.x86_64 \
pciutils.x86_64 pcre.x86_64 perl.x86_64 perl-Config-General.noarch perl-Crypt-OpenSSL-Bignum.x86_64 \
perl-Crypt-OpenSSL-Random.x86_64 perl-Crypt-OpenSSL-RSA.x86_64 perl-DBI.x86_64 pm-utils.x86_64 \
popt.x86_64 portmap.x86_64 postgresql-libs.x86_64 procmail.x86_64 procps.x86_64 psmisc.x86_64 \
python.x86_64 python-elementtree.x86_64 python-iniparse.noarch python-libs.x86_64 \
python-sqlite.x86_64 python-urlgrabber.noarch python-virtinst.noarch python26.x86_64 \
python26-boto.noarch python26-eucadmin.x86_64 python26-libs.x86_64 python26-m2crypto.x86_64 \
rampartc.x86_64 readline.x86_64 redhat-logos.noarch regexp.x86_64 rhpl.x86_64 rootfiles.noarch \
rpm.x86_64 rpm-libs.x86_64 rpm-python.x86_64 rsync.x86_64 rsyslog.x86_64 scsi-target-utils.x86_64 \
SDL.x86_64 sed.x86_64 sendmail.x86_64 setup.noarch sgpio.x86_64 shadow-utils.x86_64 slang.x86_64 \
sqlite.x86_64 sudo.x86_64 system-config-network-tui.noarch SysVinit.x86_64 tar.x86_64 \
tcp_wrappers.x86_64 termcap.noarch tomcat5-servlet-2.4-api.x86_64 tzdata.x86_64 tzdata-java.x86_64 \
udev.x86_64 unzip.x86_64 usermode.x86_64 util-linux.x86_64 vblade.x86_64 vconfig.x86_64 \
velocity.x86_64 vim-minimal.x86_64 vtun.x86_64 werken-xpath.x86_64 wget.x86_64 which.x86_64 \
wireless-tools.x86_64 wsdl4j.x86_64 xalan-j2.x86_64 xen.x86_64 xen-libs.x86_64 xinetd.x86_64 \
xml-commons.x86_64 xml-commons-apis.x86_64 xml-commons-resolver.x86_64 xorg-x11-filesystem.noarch \
xz.x86_64 xz-libs.x86_64 yum.noarch yum-fastestmirror.noarch yum-metadata-parser.x86_64 zip.x86_64 \
zlib.x86_64"
  ;;
"6")
  RPMS="alsa-lib.x86_64 apache-tomcat-apis.noarch apr.x86_64 apr-util.x86_64 apr-util-ldap.x86_64 \
atk.x86_64 audit-libs.x86_64 augeas-libs.x86_64 authconfig.x86_64 avahi-libs.x86_64 \
avalon-framework.x86_64 avalon-logkit.noarch axis.noarch axis2c.x86_64 b43-openfwwf.noarch \
basesystem.noarch bash.x86_64 bcel.x86_64 bfa-firmware.noarch binutils.x86_64 bridge-utils.x86_64 \
bzip2.x86_64 bzip2-libs.x86_64 ca-certificates.noarch cairo.x86_64 celt051.x86_64 \
centos-release.x86_64 chkconfig.x86_64 classpathx-jaf.x86_64 classpathx-mail.noarch \
ConsoleKit.x86_64 ConsoleKit-libs.x86_64 coreutils.x86_64 coreutils-libs.x86_64 cpio.x86_64 \
cracklib.x86_64 cracklib-dicts.x86_64 crda.x86_64 cronie.x86_64 cronie-anacron.x86_64 \
crontabs.noarch cups-libs.x86_64 curl.x86_64 cvs.x86_64 cyrus-sasl.x86_64 cyrus-sasl-lib.x86_64 \
cyrus-sasl-md5.x86_64 dash.x86_64 db4.x86_64 db4-utils.x86_64 dbus.x86_64 dbus-glib.x86_64 \
dbus-libs.x86_64 dbus-python.x86_64 dejavu-fonts-common.noarch dejavu-serif-fonts.noarch \
device-mapper.x86_64 device-mapper-event.x86_64 device-mapper-event-libs.x86_64 \
device-mapper-libs.x86_64 dhclient.x86_64 dhcp-common.x86_64 dhcp41.x86_64 dhcp41-common.x86_64 \
dnsmasq.x86_64 dracut.noarch dracut-kernel.noarch drbd83-utils.x86_64 e2fsprogs.x86_64 \
e2fsprogs-libs.x86_64 ebtables.x86_64 eggdbus.x86_64 elfutils-libelf.x86_64 efibootmgr.x86_64 \
elrepo-release.noarch epel-release.noarch ethtool.x86_64 euca2ools.noarch eucalyptus.x86_64 \
eucalyptus-admin-tools.noarch eucalyptus-broker.x86_64 eucalyptus-cc.x86_64 eucalyptus-cloud \
eucalyptus-common-java.x86_64 eucalyptus-gl.x86_64 eucalyptus-nc.x86_64 eucalyptus-sc.x86_64 \
eucalyptus-walrus.x86_64 expat.x86_64 file.x86_64 file-libs.x86_64 filesystem.x86_64 \
findutils.x86_64 fipscheck.x86_64 fipscheck-lib.x86_64 flac.x86_64 fontconfig.x86_64 \
fontpackages-filesystem.noarch freetype.x86_64 fuse-libs.x86_64 gamin.x86_64 gawk.x86_64 \
gdbm.x86_64 geronimo-specs.noarch geronimo-specs-compat.noarch gettext.x86_64 giflib.x86_64 \
glib2.x86_64 glibc.i686 glibc.x86_64 glibc-common.x86_64 gmp.x86_64 gnupg2.x86_64 gnutls.x86_64 \
gnutls-utils.x86_64 gpgme.x86_64 gpxe-roms-qemu.noarch grep.x86_64 groff.x86_64 grub.x86_64 \
grubby.x86_64 gtk2.x86_64 gzip.x86_64 hicolor-icon-theme.noarch httpd.x86_64 httpd-tools.x86_64 \
hwdata.noarch info.x86_64 initscripts.x86_64 iproute.x86_64 iptables.x86_64 iptables-ipv6.x86_64 \
iputils.x86_64 ipw2100-firmware.noarch ipw2200-firmware.noarch iscsi-initiator-utils.x86_64 \
iw.x86_64 iwl1000-firmware.noarch iwl100-firmware.noarch iwl3945-firmware.noarch \
iwl4965-firmware.noarch iwl5000-firmware.noarch iwl5150-firmware.noarch iwl6000-firmware.noarch \
iwl6000g2a-firmware.noarch iwl6000g2b-firmware.noarch iwl6050-firmware.noarch \
jakarta-commons-collections.noarch jakarta-commons-discovery.noarch \
jakarta-commons-httpclient.x86_64 jakarta-commons-logging.noarch jakarta-oro.x86_64 \
jasper-libs.x86_64 java-1.5.0-gcj.x86_64 java-1.6.0-openjdk.x86_64 java_cup.x86_64 jdom.noarch \
jline.noarch jpackage-utils.noarch kbd.x86_64 kbd-misc.noarch kernel.x86_64 kernel-firmware.noarch \
keyutils-libs.x86_64 kmod-drbd83.x86_64 krb5-libs.x86_64 less.x86_64 libacl.x86_64 libaio.x86_64 \
libart_lgpl.x86_64 libasyncns.x86_64 libattr.x86_64 libblkid.x86_64 libcap.x86_64 libcap-ng.x86_64 \
libcgroup.x86_64 libcom_err.x86_64 libcurl.x86_64 libdrm.x86_64 libedit.x86_64 libevent.x86_64 \
libffi.x86_64 libgcc.i686 libgcc.x86_64 libgcj.x86_64 libgcrypt.x86_64 libgomp.x86_64 \
libgpg-error.x86_64 libgssglue.x86_64 libibverbs.x86_64 libICE.x86_64 libidn.x86_64 libjpeg.x86_64 \
libnih.x86_64 libnl.x86_64 libogg.x86_64 libpcap.x86_64 libpciaccess.x86_64 libpng.x86_64 \
librdmacm.x86_64 libselinux.x86_64 libselinux-python.x86_64 libsepol.x86_64 libSM.x86_64 \
libsndfile.x86_64 libss.x86_64 libssh2.x86_64 libstdc++.x86_64 libtasn1.x86_64 libthai.x86_64 \
libtiff.x86_64 libtirpc.x86_64 libudev.x86_64 libusb.x86_64 libuser.x86_64 libutempter.x86_64 \
libuuid.x86_64 libvirt.x86_64 libvirt-client.x86_64 libvorbis.x86_64 libX11.x86_64 \
libX11-common.noarch libXau.x86_64 libxcb.x86_64 libXcomposite.x86_64 libXcursor.x86_64 \
libXdamage.x86_64 libXext.x86_64 libXfixes.x86_64 libXft.x86_64 libXi.x86_64 libXinerama.x86_64 \
libxml2.x86_64 libXrandr.x86_64 libXrender.x86_64 libxslt.x86_64 libXtst.x86_64 log4j.x86_64 \
logrotate.x86_64 lua.x86_64 lvm2.x86_64 lvm2-libs.x86_64 lzo.x86_64 lzop.x86_64 m2crypto.x86_64 \
mailcap.noarch MAKEDEV.x86_64 mdadm.x86_64 mingetty.x86_64 module-init-tools.x86_64 mx4j.noarch \
mysql.x86_64 mysql-libs.x86_64 nc.x86_64 ncurses.x86_64 ncurses-base.x86_64 ncurses-libs.x86_64 \
net-tools.x86_64 netcf-libs.x86_64 newt.x86_64 newt-python.x86_64 nfs-utils.x86_64 \
nfs-utils-lib.x86_64 nspr.x86_64 nss.x86_64 nss-softokn.x86_64 nss-softokn-freebl.i686 \
nss-softokn-freebl.x86_64 nss-sysinit.x86_64 nss-util.x86_64 ntp.x86_64 ntpdate.x86_64 \
numactl.x86_64 openldap.x86_64 openssh.x86_64 openssh-clients.x86_64 openssh-server.x86_64 \
openssl.x86_64 pam.x86_64 pango.x86_64 parted.x86_64 passwd.x86_64 pciutils.x86_64 \
pciutils-libs.x86_64 pcre.x86_64 perl.x86_64 perl-Config-General.noarch \
perl-Crypt-OpenSSL-Bignum.x86_64 perl-Crypt-OpenSSL-Random.x86_64 perl-Crypt-OpenSSL-RSA.x86_64 \
perl-libs.x86_64 perl-Module-Pluggable.x86_64 perl-Pod-Escapes.x86_64 perl-Pod-Simple.x86_64 \
perl-version.x86_64 pinentry.x86_64 pixman.x86_64 pkgconfig.x86_64 plymouth.x86_64 \
plymouth-core-libs.x86_64 plymouth-scripts.x86_64 polkit.x86_64 popt.x86_64 postfix.x86_64 \
procps.x86_64 psmisc.x86_64 pth.x86_64 pulseaudio-libs.x86_64 pygpgme.x86_64 python.x86_64 \
python-boto.noarch python-ethtool.x86_64 python-eucadmin.noarch python-iniparse.noarch \
python-iwlib.x86_64 python-libs.x86_64 python-pycurl.x86_64 python-urlgrabber.noarch \
qemu-img.x86_64 qemu-kvm.x86_64 ql2100-firmware.noarch ql2200-firmware.noarch \
ql23xx-firmware.noarch ql2400-firmware.noarch ql2500-firmware.noarch radvd.x86_64 rampartc.x86_64 \
readline.x86_64 redhat-logos.noarch regexp.x86_64 rhino.noarch rootfiles.noarch rpcbind.x86_64 \
rpm.x86_64 rpm-libs.x86_64 rpm-python.x86_64 rsync.x86_64 rsyslog.x86_64 rt61pci-firmware.noarch \
rt73usb-firmware.noarch scsi-target-utils.x86_64 seabios.x86_64 sed.x86_64 setup.noarch \
sgabios-bin.noarch shadow-utils.x86_64 sinjdoc.x86_64 slang.x86_64 spice-server.x86_64 \
sqlite.x86_64 sudo.x86_64 system-config-network-tui.noarch sysvinit-tools.x86_64 tar.x86_64 \
tcp_wrappers-libs.x86_64 tomcat6-servlet-2.5-api.noarch tzdata.noarch tzdata-java.noarch \
udev.x86_64 unzip.x86_64 upstart.x86_64 usermode.x86_64 util-linux-ng.x86_64 vblade.x86_64 \
vconfig.x86_64 velocity.noarch vgabios.noarch vim-minimal.x86_64 vtun.x86_64 werken-xpath.noarch \
wget.x86_64 which.x86_64 wireless-tools.x86_64 wsdl4j.noarch xalan-j2.noarch xinetd.x86_64 \
xml-commons-apis.x86_64 xml-commons-resolver.x86_64 xz.x86_64 xz-libs.x86_64 yajl.x86_64 yum.noarch \
yum-metadata-parser.x86_64 yum-plugin-fastestmirror.noarch zd1211-firmware.noarch zip.x86_64 \
zlib.x86_64"
  ;;
esac

# Download the rpms
cd ${BUILDDIR}/isolinux/${PACKAGESDIR}
echo "$(date) - Retrieving packages" | tee -a $SILVEREYELOGFILE
yumdownloader ${RPMS}

# Download the Eucalyptus release repository rpm
case "$EUCALYPTUSVERSION" in
"3.0")
  yumdownloader eucalyptus-release-enterprise.noarch
  ;;
"3.1")
  yumdownloader eucalyptus-nightly-release.noarch
  ;;
esac

# Test the installation of the RPMs to verify that we have all dependencies
echo "$(date) - Verifying package dependencies are met" | tee -a $SILVEREYELOGFILE
mkdir -p ${BUILDDIR}/tmprpmdb
rpm --initdb --dbpath ${BUILDDIR}/tmprpmdb
rpm --test --dbpath ${BUILDDIR}/tmprpmdb -Uvh ${BUILDDIR}/isolinux/${PACKAGESDIR}/*.rpm
if [ $? -ne 0 ] ; then
  echo "$(date) - Package dependencies not met! Exiting." | tee -a $SILVEREYELOGFILE
  exit 1
else
  echo "$(date) - Package dependencies are OK" | tee -a $SILVEREYELOGFILE
fi
rm -rf ${BUILDDIR}/tmprpmdb

# Create a repository
install_package createrepo
echo "$(date) - Creating repodata" | tee -a $SILVEREYELOGFILE
cd ${BUILDDIR}/isolinux
declare -x discinfo="$DATESTAMP"
createrepo -u "media://$discinfo" -g ${BUILDDIR}/${COMPSFILE} .
echo "$(date) - Repodata created" | tee -a $SILVEREYELOGFILE

# Extract the Eucalyptus logo and use it for the boot logo
install_package ImageMagick
install_package syslinux
install_package java-1.6.0-openjdk-devel
echo "$(date) - Creating boot logo" | tee -a $SILVEREYELOGFILE
mkdir -p ${BUILDDIR}/tmplogo
cd ${BUILDDIR}/tmplogo
rpm2cpio ${BUILDDIR}/isolinux/${PACKAGESDIR}/eucalyptus-common-java-*.rpm | cpio -idmv ./var/lib/eucalyptus/webapps/root.war
jar -xf ./var/lib/eucalyptus/webapps/root.war
case "$ELVERSION" in
"5")
  convert -size 640x120 xc:#ffffff white_background.png
  convert themes/eucalyptus/logo.png -resize 250% large-logo.png
  composite -gravity center large-logo.png white_background.png splash.png
  convert splash.png -depth 8 -colors 14 splash.ppm
  ppmtolss16 < splash.ppm > splash.lss
  rm -f splash.png
  rm -f splash.ppm
;;
"6")
  if [ $ELVERSION -eq 6 ] ; then
    install_package syslinux-perl
  fi
  convert -size 640x480 gradient:#022b40-#abbfca gradient_background.png
  convert themes/eucalyptus/logo.png -resize 250% large-logo.png
  composite -gravity south -geometry +0+50 large-logo.png gradient_background.png splash.jpg
;;
esac
rm -f ${BUILDDIR}/isolinux/splash.*
mv splash.* ${BUILDDIR}/isolinux/
cd ..
rm -rf tmplogo

# edit the boot menu
case "$ELVERSION" in
"5")
  cd ${BUILDDIR}/isolinux
  sed -i -e 's/ -  To install or upgrade in graphical mode, press the '`echo "\o017"`'0b<ENTER>'`echo "\o017"`'07 key./NOTE: It is recommended that you install and configure Node Controllers prior to installing and configuring your Frontend.\n\n -  To install CentOS 5 with Eucalyptus Node Controller, type: '`echo "\o017"`'0bnc <ENTER>'`echo "\o017"`'07.\n\n -  To install CentOS 5 with Eucalyptus Frontend, type: '`echo "\o017"`'0bfrontend <ENTER>'`echo "\o017"`'07.\n\n -  To install a minimal CentOS 5 without Eucalyptus, type: '`echo "\o017"`'0bminimal <ENTER>'`echo "\o017"`'07./g' boot.msg
  sed -i -e 's/ -  To install or upgrade in text mode, type: '`echo "\o017"`'0blinux text <ENTER>'`echo "\o017"`'07./ -  For text mode installations, append the word text, e.g., '`echo "\o017"`'0bnc text <ENTER>'`echo "\o017"`'07./g' boot.msg
  sed -i -e 's/default linux/default local/g' isolinux.cfg
  sed -i -e 's%  append -%\0\nlabel nc\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/nc.cfg\nlabel frontend\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/frontend.cfg\nlabel minimal\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/minimal.cfg\n%g' isolinux.cfg
  ;;
"6")
  cd ${BUILDDIR}/isolinux
  sed -i -e '/  menu default/d' isolinux.cfg
  sed -i -e 's/^\(  menu label Boot from .*drive\)$/\1\n  menu default/g' isolinux.cfg
  sed -i -e 's/label linux/label nc/' isolinux.cfg
  sed -i -e 's/menu label ^Install or upgrade an existing system/menu label Install CentOS 6 with Eucalyptus ^Node Controller/' isolinux.cfg
  sed -i -e 's%^  append initrd=initrd.img$%  append initrd=initrd.img ks=cdrom:/ks/nc.cfg%' isolinux.cfg
  sed -i -e 's/label vesa/label frontend/' isolinux.cfg
  sed -i -e 's/menu label Install system with ^basic video driver/menu label Install CentOS 6 with Eucalyptus ^Frontend/' isolinux.cfg
  sed -i -e 's%^  append initrd=initrd.img xdriver=vesa nomodeset%  append initrd=initrd.img ks=cdrom:/ks/frontend.cfg%' isolinux.cfg
  sed -i -e 's%^\(label rescue\)$%label minimal\n  menu label Install a ^minimal CentOS 6 without Eucalyptus\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/minimal.cfg\n\1%' isolinux.cfg
  sed -i -e 's/menu title Welcome to CentOS .*$/menu title Install NCs before installing Frontend./' isolinux.cfg
  ;;
esac

# Create the .iso image
install_package anaconda-runtime
cd ${BUILDDIR}
mkisofs -o silvereye.${DATESTAMP}.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -T -joliet-long isolinux/
case "$ELVERSION" in
"5")
  /usr/lib/anaconda-runtime/implantisomd5 silvereye.${DATESTAMP}.iso
  ;;
"6")
  /usr/bin/implantisomd5 silvereye.${DATESTAMP}.iso
  ;;
esac
mv silvereye.${DATESTAMP}.iso ../

