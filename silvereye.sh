#!/bin/bash
#
# Copyright (c) 2011  Eucalyptus Systems, Inc.
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
# This script will create a customized CentOS 5.x x86_64 minimal installation
# CD image that includes Eucalyptus in the installations.
# The script should be used from an existing CentOS 5.x x86_64 installation.
# If the EPEL and Eucalyptus package repositories are not present on the system
# this script will install/create them.
#
# If you have a local mirror that you prefer to use, set up your yum
# configuration to use it, and uncomment the line below.
#MIRROR="http://192.168.7.65/centos/5/os/x86_64/"

# Modification below this point shouldn't be necessary

# Create the build directory structure and cd into it
DATESTAMP=`date +%s`
mkdir -p silvereye_build.${DATESTAMP}/isolinux/{CentOS,images,ks}
mkdir -p silvereye_build.${DATESTAMP}/isolinux/images/{pxeboot,xen}
cd silvereye_build.$DATESTAMP
BUILDDIR=`pwd`
SILVEREYELOGFILE="${BUILDDIR}/silvereye.$DATESTAMP.log"
echo "$(date) - Created $BUILDDIR directory structure" | tee -a $SILVEREYELOGFILE

if [ -z $MIRROR ] ; then
  MIRROR=`curl -s http://mirrorlist.centos.org/?release=5\&arch=x86_64\&repo=os | head -n 1`
fi

echo "$(date) - Using $MIRROR for downloads" | tee -a $SILVEREYELOGFILE

# Retrieve the comps.xml file
echo "$(date) - Retrieving files" | tee -a $SILVEREYELOGFILE
wget ${MIRROR}/repodata/comps.xml

# Retrieve the files for the root filesystem of the CD
wget ${MIRROR}/.discinfo -O isolinux/.discinfo

ROOTFILES="
isolinux/boot.msg
isolinux/general.msg
isolinux/initrd.img
isolinux/isolinux.bin
isolinux/isolinux.cfg
isolinux/memtest
isolinux/options.msg
isolinux/param.msg
isolinux/rescue.msg
isolinux/splash.lss
isolinux/vmlinuz
"
for FILE in $ROOTFILES ; do
wget ${MIRROR}/${FILE} -O ${FILE}
done

# Retrieve the files for the images directory
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
for FILE in $IMAGESFILES ; do
wget ${MIRROR}/images/${FILE} -O ./isolinux/images/${FILE}
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
@base
@core
-crash
-autofs
-pcmciautils
-gpm
-firstboot-tui
-NetworkManager
-rp-pppoe
-irda-utils
-bluez-utils
epel-release
ntp
java-1.6.0-openjdk
ant
ant-nodeps
dhcp
bridge-utils
perl-Convert-ASN1
scsi-target-utils
httpd
eucalyptus-cloud
eucalyptus-cc
eucalyptus-walrus
eucalyptus-sc
euca2ools

%post
# Disable Eucalyptus services before first boot
/sbin/chkconfig eucalyptus-cloud off
/sbin/chkconfig eucalyptus-cc off

# Create Eucalyptus yum repo config file
cat >> /etc/yum.repos.d/euca-2.0.3.repo <<"EOF"
[eucalyptus]
name=Eucalyptus
baseurl=http://www.eucalyptussoftware.com/downloads/repo/eucalyptus/2.0.3/yum/centos/$basearch/
gpgcheck=0

EOF

# Create fe_config.sh script
mkdir /root/bin
cat >> /root/bin/fe_config.sh <<"EOF"
#!/bin/bash
#
# Copyright (c) 2011  Eucalyptus Systems, Inc.
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

# We need a cluster name for registration
export CLUSTER_NAME=cluster00

# Set log file destination
export LOGFILE=/var/log/fe_config.log

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

echo "Welcome to the Eucalyptus frontend configuration script"
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

# Set clock and enable ntpd service
echo "$(date)- Setting clock via NTP.  This may take a few minutes." |tee -a $LOGFILE
/sbin/ntpd -q -g >>$LOGFILE 2>&1
chkconfig ntpd on >>$LOGFILE 2>&1
service ntpd start >>$LOGFILE 2>&1
error_check
echo "$(date)- Set clock and enabled ntp" |tee -a $LOGFILE

# Configure sudoers
chmod 660 /etc/sudoers
sed --in-place 's/^Defaults[ ]*requiretty/#Defaults    requiretty/g' /etc/sudoers >>$LOGFILE 2>&1
chmod 440 /etc/sudoers

# Generate root's SSH keys if they aren't already present
if [ ! -f /root/.ssh/id_rsa ]
then
  ssh-keygen -N "" -f /root/.ssh/id_rsa >>$LOGFILE 2>&1
  echo "$(date)- Generated root's SSH keys" |tee -a $LOGFILE
else
  echo "$(date)- root's SSH keys already exist" |tee -a $LOGFILE
fi
if ! grep root /root/.ssh/authorized_keys > /dev/null 2>&1
then
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  echo "$(date)- Appended root's public key to authorized_keys" |tee -a $LOGFILE
else
  echo "$(date)- root's public key already present in authorized_keys" |tee -a $LOGFILE
fi

# Generate eucalyptus user's home directory and SSH keys if they aren't already present
if [ ! -d /home/eucalyptus ]
then
  cp -a /etc/skel /home/eucalyptus >>$LOGFILE 2>&1
  chown -R eucalyptus:eucalyptus /home/eucalyptus >>$LOGFILE 2>&1
  chmod 700 /home/eucalyptus >>$LOGFILE 2>&1
  echo "$(date)- Generated eucalyptus user's home directory" |tee -a $LOGFILE
else
  echo "$(date)- eucalyptus user's home directory already exists" |tee -a $LOGFILE
fi
if [ ! -f /home/eucalyptus/.ssh/id_rsa ]
then
  su eucalyptus -c 'ssh-keygen -C Eucalyptus -N "" -f /home/eucalyptus/.ssh/id_rsa' >>$LOGFILE 2>&1
  echo "$(date)- Generated eucalyptus user's SSH keys" |tee -a $LOGFILE
else
  echo "$(date)- eucalyptus user's SSH keys already exist" |tee -a $LOGFILE
fi
if ! grep Eucalyptus /home/eucalyptus/.ssh/authorized_keys > /dev/null 2>&1
then
  su eucalyptus -c 'cat /home/eucalyptus/.ssh/id_rsa.pub >> /home/eucalyptus/.ssh/authorized_keys' >>$LOGFILE 2>&1
  echo "$(date)- Appended eucalyptus user's public key to authorized_keys" |tee -a $LOGFILE
else
  echo "$(date)- eucalyptus user's public key already present in authorized_keys" |tee -a $LOGFILE
fi

# Fix /usr/sbin/euca*
if [ `grep python2.6 /usr/sbin/euca-describe-clusters|wc -l` -eq "0" ]
then
  sed --in-place s/python/python2.6/ /usr/sbin/euca-* >>$LOGFILE 2>&1
  echo "$(date)- Fixed /usr/sbin/euca*" |tee -a $LOGFILE
else
  echo "$(date)- /usr/sbin/euca* already fixed" |tee -a $LOGFILE
fi

# Edit the default eucalyptus.conf, insert default values if no previous configuration is present
sed --in-place 's/^VNET_MODE="SYSTEM"/#VNET_MODE="SYSTEM"/' /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1
if ! grep -E '(^VNET_MODE)' /etc/eucalyptus/eucalyptus.conf
then
  echo 'VNET_MODE="MANAGED-NOVLAN"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_SUBNET)' /etc/eucalyptus/eucalyptus.conf
then
  echo 'VNET_SUBNET="192.168.0.0"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_NETMASK)' /etc/eucalyptus/eucalyptus.conf
then
  echo 'VNET_NETMASK="255.255.255.0"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_DNS)' /etc/eucalyptus/eucalyptus.conf
then
  PRIMARY_DNS=`grep nameserver /etc/resolv.conf | head -n1 | awk '{print $2}'`
  echo "VNET_DNS=\"$PRIMARY_DNS\"" >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_ADDRSPERNE)' /etc/eucalyptus/eucalyptus.conf
then
  echo 'VNET_ADDRSPERNET="32"' >> /etc/eucalyptus/eucalyptus.conf
fi
if ! grep -E '(^VNET_PUBLICIPS)' /etc/eucalyptus/eucalyptus.conf
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
ADDRSPER_REC=16
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
edit_prop VNET_ADDRSPERNET "How many addresses per net?" $EUCACONFIG "[0-9]*"
echo "The range of public IP addresses should be two IP adresses on the public network separated by a - (e.g. '192.168.1.10-192.168.1.50')"
edit_prop VNET_PUBLICIPS "The range of public IP addresses" $EUCACONFIG "[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}-[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"

# Start Eucalyptus services prior to registration
echo ""
echo "$(date)- Starting services " |tee -a $LOGFILE
/etc/init.d/eucalyptus-cloud start >>$LOGFILE 2>&1
/sbin/chkconfig eucalyptus-cloud on >>$LOGFILE 2>&1
/etc/init.d/eucalyptus-cc start >>$LOGFILE 2>&1
/sbin/chkconfig eucalyptus-cc on >>$LOGFILE 2>&1
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
export EUCALYPTUS=/
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
ssh -o StrictHostKeyChecking=no $PUBLIC_IP_ADDRESS true
ssh -o StrictHostKeyChecking=no $PRIVATE_IP_ADDRESS true
su eucalyptus -c "ssh -o StrictHostKeyChecking=no $PUBLIC_IP_ADDRESS true"
su eucalyptus -c "ssh -o StrictHostKeyChecking=no $PRIVATE_IP_ADDRESS true"
if [ `$EUCALYPTUS/usr/sbin/euca_conf --list-walruses|tail -n+2|wc -l` -eq '0' ]
then
  $EUCALYPTUS/usr/sbin/euca_conf --register-walrus $PUBLIC_IP_ADDRESS |tee -a $LOGFILE 
else
  echo "Walrus already registered. Will not re-register walrus" |tee -a $LOGFILE
fi

# Deregister previous SCs and clusters
for i in `$EUCALYPTUS/usr/sbin/euca_conf --list-scs|tail -n+2`
do
  SVC_IP=`echo $i |awk '{ print $1 }'`
  $EUCALYPTUS/usr/sbin/euca_conf --deregister-sc $SVC_IP >>$LOGFILE 2>&1
done
for i in `$EUCALYPTUS/usr/sbin/euca_conf --list-clusters|tail -n+2`
do
  SVC_IP=`echo $i |awk '{ print $1 }'`
  $EUCALYPTUS/usr/sbin/euca_conf --deregister-cluster $SVC_IP >>$LOGFILE 2>&1
done

# Now register clusters and SCs
$EUCALYPTUS/usr/sbin/euca_conf --register-cluster $CLUSTER_NAME $PRIVATE_IP_ADDRESS |tee -a $LOGFILE
$EUCALYPTUS/usr/sbin/euca_conf --register-sc $CLUSTER_NAME $PRIVATE_IP_ADDRESS |tee -a $LOGFILE
error_check

# Deregister previous node controllers
for i in `$EUCALYPTUS/usr/sbin/euca_conf --list-nodes|tail -n+2`
do
  SVC_IP=`echo $i |awk '{ print $2 }'`
  $EUCALYPTUS/usr/sbin/euca_conf --deregister-nodes $SVC_IP >>$LOGFILE 2>&1
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
    scp -rp /home/eucalyptus root@${node}:/home/ >>$LOGFILE 2>&1
    ssh root@${node} "chown -R eucalyptus:eucalyptus /home/eucalyptus" >>$LOGFILE 2>&1
    grep -E '^VNET_MODE' /etc/eucalyptus/eucalyptus.conf > /tmp/eucalyptus_vnet_config.txt
    grep -E '^VNET_SUBNET' /etc/eucalyptus/eucalyptus.conf >> /tmp/eucalyptus_vnet_config.txt
    grep -E '^VNET_NETMASK' /etc/eucalyptus/eucalyptus.conf >> /tmp/eucalyptus_vnet_config.txt
    grep -E '^VNET_DNS' /etc/eucalyptus/eucalyptus.conf >> /tmp/eucalyptus_vnet_config.txt
    grep -E '^VNET_ADDRSPERNET' /etc/eucalyptus/eucalyptus.conf >> /tmp/eucalyptus_vnet_config.txt
    grep -E '^VNET_PUBLICIPS' /etc/eucalyptus/eucalyptus.conf >> /tmp/eucalyptus_vnet_config.txt
    scp /tmp/eucalyptus_vnet_config.txt root@${node}:/tmp/
    ssh root@${node} "cat /tmp/eucalyptus_vnet_config.txt >> /etc/eucalyptus/eucalyptus.conf"
    rm -f /tmp/eucalyptus_vnet_config.txt
    ssh root@${node} "rm -f /tmp/eucalyptus_vnet_config.txt"
    ssh root@${node} "service eucalyptus-nc restart"
    $EUCALYPTUS/usr/sbin/euca_conf --register-nodes $node |tee -a $LOGFILE
  fi
done
error_check
echo "$(date)- Registered components " |tee -a $LOGFILE
echo "Please visit https://$PUBLIC_IP_ADDRESS:8443/ to start using your cloud!"

EOF

chmod 770 /root/bin/fe_config.sh

# Create a backup copy of root's .bash_profile
/bin/cp -a /root/.bash_profile /root/.bash_profile.orig

# Create a backup of /etc/rc.d/rc.local
cp /etc/rc.d/rc.local /etc/rc.d/rc.local.orig
cat >> /etc/rc.d/rc.local <<"EOF"

# Add fe_config.sh script to root's .bash_profile, and have the original .bash_profile moved in after the first run
echo '/root/bin/fe_config.sh' >> /root/.bash_profile
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
@base
@core
-crash
-autofs
-pcmciautils
-gpm
-firstboot-tui
-NetworkManager
-rp-pppoe
-irda-utils
-bluez-utils
-kernel
epel-release
kernel-xen
ntp
xen
eucalyptus-nc
euca2ools

%post
# Disable Eucalyptus services before first boot
/sbin/chkconfig eucalyptus-nc off

# Create Eucalyptus yum repo config file
cat >> /etc/yum.repos.d/euca-2.0.3.repo <<"EOF"
[eucalyptus]
name=Eucalyptus
baseurl=http://www.eucalyptussoftware.com/downloads/repo/eucalyptus/2.0.3/yum/centos/$basearch/
gpgcheck=0

EOF

mkdir /root/bin
cat >> /root/bin/nc_config.sh <<"EOF"
#!/bin/bash
#
# Copyright (c) 2011  Eucalyptus Systems, Inc.
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
export LOGFILE=/var/log/nc_config.log

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

echo "Welcome to the Eucalyptus node controller configuration script"
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

# Set clock and enable ntpd service
echo "$(date)- Setting clock via NTP.  This may take a few minutes." |tee -a $LOGFILE
/sbin/ntpd -q -g >>$LOGFILE 2>&1
chkconfig ntpd on >>$LOGFILE 2>&1
service ntpd start >>$LOGFILE 2>&1
error_check
echo "$(date)- Set clock and enabled ntp" |tee -a $LOGFILE

# Customize loop module options
loop_module_configured=`grep 'options loop max_loop=255' /etc/modprobe.conf`
if [ $loop_module_configured ]
then
  echo "loop module already customized" | tee -a $LOGFILE
else
  echo "options loop max_loop=255" >> /etc/modprobe.conf 2>$LOGFILE
  rmmod loop ; modprobe loop max_loop=255 >>$LOGFILE 2>&1
  echo "loop module customized" | tee -a $LOGFILE
fi
error_check
echo "$(date)- Customized loop module options" |tee -a $LOGFILE

# Customize xen configuration
sed --in-place 's/#(xend-http-server no)/(xend-http-server yes)/' /etc/xen/xend-config.sxp  >>$LOGFILE 2>&1
sed --in-place 's/#(xend-address localhost)/(xend-address localhost)/' /etc/xen/xend-config.sxp >>$LOGFILE 2>&1
/etc/init.d/xend restart >>$LOGFILE 2>&1
error_check
echo "$(date)- Customized xen configuration" |tee -a $LOGFILE

# Configure sudoers
chmod 660 /etc/sudoers
sed --in-place 's/^Defaults[ ]*requiretty/#Defaults    requiretty/g' /etc/sudoers >>$LOGFILE 2>&1
chmod 440 /etc/sudoers

# Configure libvirt
echo "$(date)- Configuring libvirt " |tee -a $LOGFILE
if ! grep ^libvirt /etc/group >/dev/null 2>&1
then
  groupadd libvirt
  echo "$(date)- Added libvirt group to /etc/group" | tee -a $LOGFILE
fi
if ! grep -E '(^libvirt.*eucalyptus)' /etc/group
then
  usermod -a -G libvirt eucalyptus
  echo "$(date)- Added eucalyptus user to libvirt group" | tee -a $LOGFILE
fi
sed --in-place 's/#unix_sock_group/unix_sock_group/' /etc/libvirt/libvirtd.conf  >>$LOGFILE 2>&1
sed --in-place 's/#unix_sock_ro_perms/unix_sock_ro_perms/' /etc/libvirt/libvirtd.conf  >>$LOGFILE 2>&1
sed --in-place 's/#unix_sock_rw_perms/unix_sock_rw_perms/' /etc/libvirt/libvirtd.conf  >>$LOGFILE 2>&1
/etc/init.d/libvirtd restart >>$LOGFILE 2>&1
is_running=`su eucalyptus -c "virsh list" |grep Domain |awk '{ print $3 };'`
if [ $is_running ]
  then
    echo "libvirt configured" |tee -a $LOGFILE
  else
    echo "unable to find running virtual domain. check $LOGFILE"  |tee -a $LOGFILE
	exit -1;
fi
error_check

# Fix /usr/sbin/euca*
if [ `grep python2.6 /usr/sbin/euca-describe-clusters|wc -l` -eq "0" ]
then
  sed --in-place s/python/python2.6/ /usr/sbin/euca-* >>$LOGFILE 2>&1
  echo "$(date)- Fixed /usr/sbin/euca*" |tee -a $LOGFILE
else
  echo "$(date)- /usr/sbin/euca* already fixed" |tee -a $LOGFILE
fi

# Edit the default eucalyptus.conf
sed --in-place 's/^VNET_MODE="SYSTEM"/#VNET_MODE="SYSTEM"/' /etc/eucalyptus/eucalyptus.conf >>$LOGFILE 2>&1

# Gather information from the user, and perform eucalyptus.conf property edits
echo ""
echo "We need some network information"
EUCACONFIG=/etc/eucalyptus/eucalyptus.conf
edit_prop VNET_PUBINTERFACE "The public ethernet interface" $EUCACONFIG
edit_prop VNET_PRIVINTERFACE "The private ethernet interface" $EUCACONFIG

# Start and configure eucalyptus-nc service
/etc/init.d/eucalyptus-nc start >>$LOGFILE 2>&1
error_check
/sbin/chkconfig eucalyptus-nc on >>$LOGFILE 2>&1
euca_conf --setup >>$LOGFILE 2>&1
error_check

echo "This machine is ready and running as a node controller."

EOF

chmod 770 /root/bin/nc_config.sh

# Create a backup copy of root's .bash_profile
/bin/cp -a /root/.bash_profile /root/.bash_profile.orig

# Create a backup of /etc/rc.d/rc.local
cp /etc/rc.d/rc.local /etc/rc.d/rc.local.orig
cat >> /etc/rc.d/rc.local <<"EOF"

# Add nc_config.sh script to root's .bash_profile, and have the original .bash_profile moved in after the first run
echo '/root/bin/nc_config.sh' >> /root/.bash_profile
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
@base
@core
-crash
-autofs
-pcmciautils
-gpm
-firstboot-tui
-NetworkManager
-rp-pppoe
-irda-utils
-bluez-utils

EOFMINIMALKICKSTART

# Retrieve the RPMs for a minimal CentOS, Eucalyptus, and Eucalyptus dependencies
rpm -q yum-utils > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing yum-utils package" | tee -a $SILVEREYELOGFILE
  yum -y install yum-utils
else
  echo "$(date) - yum-utils package already installed" | tee -a $SILVEREYELOGFILE
fi
rpm -q epel-release > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing EPEL package" | tee -a $SILVEREYELOGFILE
  wget http://download.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
  rpm -Uvh epel-release-*.noarch.rpm
  rm -f epel-release-*.noarch.rpm
else
  echo "$(date) - EPEL package already installed" | tee -a $SILVEREYELOGFILE
fi
if ! grep eucalyptussoftware.com /etc/yum.repos.d/* | grep -v euca2ools ; then
  echo "$(date) - Creating Eucalyptus yum repository file" | tee -a $SILVEREYELOGFILE
  cat >> /etc/yum.repos.d/euca-2.0.3.repo <<"EOF"
[eucalyptus]
name=Eucalyptus
baseurl=http://www.eucalyptussoftware.com/downloads/repo/eucalyptus/2.0.3/yum/centos/$basearch/
gpgcheck=0
EOF
else
  echo "$(date) - Eucalyptus yum repository file already present" | tee -a $SILVEREYELOGFILE
fi
RPMS="acl acpid alsa-lib.i386 alsa-lib.x86_64 amtu anacron ant antlr ant-nodeps aoetools apr.i386 apr.x86_64 apr-util.i386 apr-util.x86_64 aspell.i386 aspell.x86_64 aspell-en at atk.i386 atk.x86_64 attr audiofile.i386 audiofile.x86_64 audit.x86_64 audit-libs.i386 audit-libs.x86_64 audit-libs-python authconfig avahi.i386 avahi.x86_64 basesystem bash bc bind-libs.i386 bind-libs.x86_64 bind-utils binutils bitstream-vera-fonts bridge-utils bzip2.x86_64 bzip2-libs.i386 bzip2-libs.x86_64 cairo.i386 cairo.x86_64 ccid centos-release centos-release-notes checkpolicy chkconfig conman coolkey.i386 coolkey.x86_64 coreutils cpio cpuspeed cracklib.i386 cracklib.x86_64 cracklib-dicts crontabs cryptsetup-luks.i386 cryptsetup-luks.x86_64 cups-libs.i386 cups-libs.x86_64 curl.i386 curl.x86_64 cyrus-sasl.i386 cyrus-sasl.x86_64 cyrus-sasl-lib.i386 cyrus-sasl-lib.x86_64 cyrus-sasl-md5.i386 cyrus-sasl-md5.x86_64 cyrus-sasl-plain.i386 cyrus-sasl-plain.x86_64 db4.i386 db4.x86_64 dbus.i386 dbus.x86_64 dbus-glib.i386 dbus-glib.x86_64 dbus-libs.i386 dbus-libs.x86_64 dbus-python desktop-file-utils device-mapper.i386 device-mapper.x86_64 device-mapper-event device-mapper-multipath dhclient dhcp dhcpv6-client diffutils dmidecode dmraid dmraid-events dnsmasq dos2unix dosfstools dump e2fsprogs e2fsprogs-libs.i386 e2fsprogs-libs.x86_64 e4fsprogs-libs.i386 e4fsprogs-libs.x86_64 ebtables ecryptfs-utils.i386 ecryptfs-utils.x86_64 ed eject elfutils-libelf.i386 elfutils-libelf.x86_64 epel-release esound.i386 esound.x86_64 ethtool euca2ools euca-axis2c eucalyptus eucalyptus-cc eucalyptus-cloud eucalyptus-common-java eucalyptus-debuginfo eucalyptus-gl eucalyptus-nc eucalyptus-sc eucalyptus-walrus euca-rampartc expat.i386 expat.x86_64 fbset file filesystem findutils finger fipscheck fipscheck-lib.i386 fipscheck-lib.x86_64 fontconfig.i386 fontconfig.x86_64 freetype.i386 freetype.x86_64 ftp gamin.i386 gamin.x86_64 gamin-python gawk gdbm.i386 gdbm.x86_64 gettext.i386 gettext.x86_64 giflib.i386 giflib.x86_64 gjdoc.x86_64 glib2.i386 glib2.x86_64 glibc.i686 glibc.x86_64 glibc-common gnupg gnutls.i386 gnutls.x86_64 grep groff grub gtk2.i386 gtk2.x86_64 gzip hal.i386 hal.x86_64 hdparm hesiod.i386 hesiod.x86_64 hicolor-icon-theme hmaccalc htmlview httpd hwdata ifd-egate info initscripts iproute ipsec-tools iptables iptables-ipv6 iptstate iputils irqbalance iscsi-initiator-utils java-1.4.2-gcj-compat java-1.6.0-openjdk java-1.6.0-openjdk-devel jpackage-utils jwhois kbd kernel kernel-xen keyutils keyutils-libs.i386 keyutils-libs.x86_64 kpartx krb5-libs.i386 krb5-libs.x86_64 krb5-workstation ksh kudzu less lftp libacl.i386 libacl.x86_64 libaio.i386 libaio.x86_64 libart_lgpl.i386 libart_lgpl.x86_64 libattr.i386 libattr.x86_64 libcap.i386 libcap.x86_64 libdaemon.i386 libdaemon.x86_64 libevent.i386 libevent.x86_64 libffi.i386 libffi.x86_64 libgcc.i386 libgcc.x86_64 libgcj.i386 libgcj.x86_64 libgcrypt.i386 libgcrypt.x86_64 libgomp.i386 libgomp.x86_64 libgpg-error.i386 libgpg-error.x86_64 libgssapi.i386 libgssapi.x86_64 libhugetlbfs.i386 libhugetlbfs.x86_64 libibverbs.i386 libibverbs.x86_64 libICE.i386 libICE.x86_64 libidn.i386 libidn.x86_64 libjpeg.i386 libjpeg.x86_64 libpng.i386 libpng.x86_64 librdmacm.i386 librdmacm.x86_64 libselinux.i386 libselinux.x86_64 libselinux-python libselinux-utils libsemanage libsepol.i386 libsepol.x86_64 libSM.i386 libSM.x86_64 libstdc++.i386 libstdc++.x86_64 libsysfs.i386 libsysfs.x86_64 libtermcap.i386 libtermcap.x86_64 libtiff.i386 libtiff.x86_64 libusb.i386 libusb.x86_64 libuser.i386 libuser.x86_64 libutempter.i386 libutempter.x86_64 libvirt.i386 libvirt.x86_64 libvirt-python libvolume_id.i386 libvolume_id.x86_64 libX11.i386 libX11.x86_64 libXau.i386 libXau.x86_64 libXcursor.i386 libXcursor.x86_64 libXdmcp.i386 libXdmcp.x86_64 libXext.i386 libXext.x86_64 libXfixes.i386 libXfixes.x86_64 libXft.i386 libXft.x86_64 libXi.i386 libXi.x86_64 libXinerama.i386 libXinerama.x86_64 libxml2.i386 libxml2.x86_64 libxml2-python libXrandr.i386 libXrandr.x86_64 libXrender.i386 libXrender.x86_64 libXtst.i386 libXtst.x86_64 logrotate logwatch lsof lvm2 lzo2 m2crypto m4 mailcap mailx make MAKEDEV man man-pages man-pages-overrides mcelog mcstrans mdadm mgetty microcode_ctl mingetty mkbootdisk mkinitrd.i386 mkinitrd.x86_64 mktemp mlocate module-init-tools mtools mtr nano nash nc ncurses.i386 ncurses.x86_64 net-tools newt.i386 newt.x86_64 nfs-utils nfs-utils-lib.i386 nfs-utils-lib.x86_64 nscd nspr.i386 nspr.x86_64 nss.i386 nss.x86_64 nss_db.i386 nss_db.x86_64 nss_ldap.i386 nss_ldap.x86_64 nss-tools ntp ntsysv numactl.i386 numactl.x86_64 oddjob oddjob-libs.i386 oddjob-libs.x86_64 openib openldap.i386 openldap.x86_64 openssh openssh-clients openssh-server openssl.i686 openssl.x86_64 pam.i386 pam.x86_64 pam_ccreds.i386 pam_ccreds.x86_64 pam_krb5.i386 pam_krb5.x86_64 pam_passwdqc.i386 pam_passwdqc.x86_64 pam_pkcs11.i386 pam_pkcs11.x86_64 pam_smb.i386 pam_smb.x86_64 pango.i386 pango.x86_64 parted.i386 parted.x86_64 passwd patch pax pciutils pcre.i386 pcre.x86_64 pcsc-lite pcsc-lite-libs.i386 pcsc-lite-libs.x86_64 perl perl-Config-General perl-Convert-ASN1 perl-Crypt-OpenSSL-Bignum perl-Crypt-OpenSSL-Random perl-Crypt-OpenSSL-RSA perl-Crypt-X509 perl-String-CRC32 pinfo pkinit-nss pm-utils policycoreutils popt.i386 popt.x86_64 portmap postgresql-libs.i386 postgresql-libs.x86_64 prelink procmail procps psacct psmisc pygobject2 python python25 python25-devel python25-libs python26 python26-boto python26-libs.i386 python26-libs.x86_64 python26-m2crypto python-elementtree python-iniparse python-libs python-sqlite python-urlgrabber python-virtinst quota rdate rdist readahead readline.i386 readline.x86_64 redhat-logos redhat-lsb.i386 redhat-lsb.x86_64 redhat-menus rhpl rmt rng-utils rootfiles rpm rpm-libs.i386 rpm-libs.x86_64 rpm-python rsh rsync scsi-target-utils SDL.i386 SDL.x86_64 sed selinux-policy selinux-policy-targeted sendmail setarch setools setserial setup setuptool sgpio shadow-utils slang.i386 slang.x86_64 smartmontools sos specspo sqlite.i386 sqlite.x86_64 stunnel sudo swig symlinks sysfsutils sysklogd syslinux system-config-network-tui system-config-securitylevel-tui SysVinit talk tar tcl.i386 tcl.x86_64 tcpdump tcp_wrappers.i386 tcp_wrappers.x86_64 tcsh telnet termcap time tmpwatch traceroute tree trousers.i386 trousers.x86_64 tzdata tzdata-java udev udftools unix2dos unzip usbutils usermode util-linux vblade vconfig vim-minimal virt-what vixie-cron vtun wget which wireless-tools.i386 wireless-tools.x86_64 words xen xen-libs.i386 xen-libs.x86_64 xml-commons xml-commons-apis xorg-x11-filesystem xz xz-libs.i386 xz-libs.x86_64 ypbind yp-tools yum yum-fastestmirror yum-metadata-parser yum-updatesd zip zlib.i386 zlib.x86_64"
cd ${BUILDDIR}/isolinux/CentOS
echo "$(date) - Retrieving packages" | tee -a $SILVEREYELOGFILE
yumdownloader ${RPMS}

# Test the installation of the RPMs to verify that we have all dependencies
echo "$(date) - Verifying package dependencies are met" | tee -a $SILVEREYELOGFILE
mkdir -p ${BUILDDIR}/tmprpmdb
rpm --initdb --dbpath ${BUILDDIR}/tmprpmdb
rpm --test --dbpath ${BUILDDIR}/tmprpmdb -Uvh ${BUILDDIR}/isolinux/CentOS/*.rpm
if [ $? -ne 0 ] ; then
  echo "$(date) - Package dependencies not met! Exiting." | tee -a $SILVEREYELOGFILE
  exit 1
else
  echo "$(date) - Package dependencies are OK" | tee -a $SILVEREYELOGFILE
fi
rm -rf ${BUILDDIR}/tmprpmdb

# Create a repository
rpm -q createrepo > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing createrepo package" | tee -a $SILVEREYELOGFILE
  yum -y install createrepo
else
  echo "$(date) - createrepo package already installed" | tee -a $SILVEREYELOGFILE
fi
echo "$(date) - Creating repodata" | tee -a $SILVEREYELOGFILE
cd ${BUILDDIR}/isolinux
declare -x discinfo=`head -1 .discinfo`
createrepo -u "media://$discinfo" -g ${BUILDDIR}/comps.xml .
echo "$(date) - Repodata created" | tee -a $SILVEREYELOGFILE

# Extract the Eucalyptus logo and use it for the boot logo
rpm -q ImageMagick > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing ImageMagick package" | tee -a $SILVEREYELOGFILE
  yum -y install ImageMagick
else
  echo "$(date) - ImageMagick package already installed" | tee -a $SILVEREYELOGFILE
fi
rpm -q syslinux > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing syslinux package" | tee -a $SILVEREYELOGFILE
  yum -y install syslinux
else
  echo "$(date) - syslinux package already installed" | tee -a $SILVEREYELOGFILE
fi
rpm -q java-1.6.0-openjdk-devel > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing java-1.6.0-openjdk-devel package" | tee -a $SILVEREYELOGFILE
  yum -y install java-1.6.0-openjdk-devel
else
  echo "$(date) - java-1.6.0-openjdk-devel package already installed" | tee -a $SILVEREYELOGFILE
fi
echo "$(date) - Creating boot logo" | tee -a $SILVEREYELOGFILE
mkdir -p ${BUILDDIR}/tmplogo
cd ${BUILDDIR}/tmplogo
rpm2cpio ${BUILDDIR}/isolinux/CentOS/eucalyptus-common-java-2.0.3-0.1.el5.x86_64.rpm | cpio -idmv ./var/lib/eucalyptus/webapps/root.war
jar -xf ./var/lib/eucalyptus/webapps/root.war
convert themes/share/eucalyptus-logo-big.jpg -depth 8 -colors 14 -resize 143.2% splash.ppm
ppmtolss16 < splash.ppm > splash.lss
rm -f ${BUILDDIR}/isolinux/splash.lss
mv splash.lss ${BUILDDIR}/isolinux/
cd ..
rm -rf tmplogo

# edit the boot menu
cd ${BUILDDIR}/isolinux
sed -i -e 's/ -  To install or upgrade in graphical mode, press the '`echo "\o017"`'0b<ENTER>'`echo "\o017"`'07 key./ -  To install CentOS 5 with Eucalyptus Frontend, type: '`echo "\o017"`'0bfrontend <ENTER>'`echo "\o017"`'07.\n\n -  To install CentOS 5 with Eucalyptus Node Controller, type: '`echo "\o017"`'0bnc <ENTER>'`echo "\o017"`'07.\n\n -  To install a minimal CentOS 5 without Eucalyptus, type: '`echo "\o017"`'0bminimal <ENTER>'`echo "\o017"`'07./g' boot.msg
sed -i -e 's/ -  To install or upgrade in text mode, type: '`echo "\o017"`'0blinux text <ENTER>'`echo "\o017"`'07./ -  For text mode installations, append the word text, e.g., '`echo "\o017"`'0bnc text <ENTER>'`echo "\o017"`'07./g' boot.msg
sed -i -e 's/default linux/default local/g' isolinux.cfg
sed -i -e 's%  append -%\0\nlabel nc\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/nc.cfg\nlabel frontend\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/frontend.cfg\nlabel minimal\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/minimal.cfg\n%g' isolinux.cfg

# Create the .iso image
rpm -q anaconda-runtime > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing anaconda-runtime package" | tee -a $SILVEREYELOGFILE
  yum -y install anaconda-runtime
else
  echo "$(date) - anaconda-runtime package already installed" | tee -a $SILVEREYELOGFILE
fi
cd ${BUILDDIR}
mkisofs -o silvereye.${DATESTAMP}.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -T isolinux/
/usr/lib/anaconda-runtime/implantisomd5 silvereye.${DATESTAMP}.iso
mv silvereye.${DATESTAMP}.iso ../
