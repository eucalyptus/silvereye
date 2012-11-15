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
export LOGFILE=/var/log/eucalyptus/frontend-config.log

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

function configure_frontend {
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

eval export PUBLIC_INTERFACE=$( awk -F= '/^VNET_PUBINTERFACE/ { print $2 }' /etc/eucalyptus/eucalyptus.conf )
PUB_BRIDGE=$( brctl show | awk "/$PUBLIC_INTERFACE/ { print \$1 }" )
if [ -n "$PUB_BRIDGE" ]; then
  export PUBLIC_IP_ADDRESS=$( ip addr show $PUB_BRIDGE | awk -F"[\t /]*" '/inet.*global/ { print $3 }' )
else
  export PUBLIC_IP_ADDRESS=$( ip addr show $PUBLIC_INTERFACE | awk -F"[\t /]*" '/inet.*global/ { print $3 }' )
fi

eval export PRIVATE_INTERFACE=$( awk -F= '/^VNET_PRIVINTERFACE/ { print $2 }' /etc/eucalyptus/eucalyptus.conf )
PRIV_BRIDGE=$( brctl show | awk "/$PRIVATE_INTERFACE/ { print \$1 }" )
if [ -n "$PRIV_BRIDGE" ]; then
  export PRIVATE_IP_ADDRESS=$( ip addr show $PRIV_BRIDGE | awk -F"[\t /]*" '/inet.*global/ { print $3 }' )
else
  export PRIVATE_IP_ADDRESS=$( ip addr show $PRIVATE_INTERFACE | awk -F"[\t /]*" '/inet.*global/ { print $3 }' )
fi

echo "Using public IP $PUBLIC_IP_ADDRESS and private IP $PRIVATE_IP_ADDRESS to" | tee -a $LOGFILE
echo "register components" | tee -a $LOGFILE

# Register Walrus
if [ `/usr/sbin/euca_conf --list-walruses 2>/dev/null |wc -l` -eq 0 ]
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

CLUSTER_NAME=CLUSTER01

# Now register clusters and SCs
/usr/sbin/euca_conf --register-cluster --partition $CLUSTER_NAME --host $PUBLIC_IP_ADDRESS --component=cc_01 | tee -a $LOGFILE
/usr/sbin/euca_conf --register-sc --partition $CLUSTER_NAME --host $PRIVATE_IP_ADDRESS --component=sc_01 | tee -a $LOGFILE

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

configure_frontend

# Get the cloud admin's credentials
get_credentials

euca-modify-property -p ${CLUSTER_NAME}.storage.blockstoragemanager=overlay

install-unpacked-image.py -t /tmp/img -b centos6 -s "CentOS 6 demo" -a x86_64

chkconfig eucalyptus-cloud on
