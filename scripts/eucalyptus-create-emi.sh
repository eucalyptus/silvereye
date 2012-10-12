#!/bin/bash
#
# Create instance store-backed EMI
#
# Exit if the script is not run with root privileges
if [ "$EUID" != "0" ] ; then
  echo "This script must be run with root privileges."
  exit 1
fi

# Set log file destination
export LOGFILE=/var/log/eucalyptus-create-emi.log

# Set the ELVERSION variable
ELVERSION=`cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/'`

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
  echo "The default instance type/disk sizes for EMIs are:"
  echo "small:   2 GB (1.5 GB root, 512 MB swap)"
  echo "medium:  5 GB (4.5 GB root, 512 MB swap)"
  echo "large:  10 GB (9.5 GB root, 512 MB swap)"
  echo ""
  echo "A smaller EMI will be quicker to launch, but will provide less storage."
  echo "A larger EMI will be incompatible with small instance types (i.e. "
  echo "an m1.small instance started with a large EMI will fail to launch.)"
  echo ""
  echo "When you launch an instance, any storage provided by the instance type that is"
  echo "greater than the root filesystem + 512 MB swap is allocated as an 'ephemeral'"
  echo "storage partition."
  echo ""
  read -p "Would you like a small, medium, or large root filesystem for this EMI? " IMAGESIZE
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
  TEMPNODE=`euca_conf --list-nodes 2>/dev/null | grep NODE | awk '{print $2}' | head -n 1`
  scp ${TEMPNODE}:/boot/vmlinuz*xen ./
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

