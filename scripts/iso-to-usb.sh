#!/bin/sh
# requires packages that may not be installed on a minimal system
# run: yum install genisoimage dosfstools syslinux-extlinux

ISO=$1
DEVNAME=$2

if [ -z $ISO ] || [ -z $DEVNAME ]; then
  echo "Usage: $0 <iso file> <usb device>" >&2
  exit 1
fi

if [ ! -e "$DEVNAME" ]; then
  echo "Device $DEVNAME is not present" >&2
  exit 2
fi

if [ ! -b "$DEVNAME" ]; then
  echo -e "ERROR: Device $DEVNAME does not appear to be a block device!\nThis script does not yet support loopback images." >&2
  exit 3
elif [ $( cat /sys/block/$( basename $DEVNAME )/removable ) != 1 ]; then 
  echo "WARNING: Device $DEVNAME does not appear to be a removable device" >&2
  echo "Proceed? "
  read ans
  if [ ans == "n" ]; then
    exit 4
  fi
fi

MTPT=$( mktemp -d )

# Repartition the stick
cat <<EOF | sfdisk $DEVNAME
unit: sectors

/dev/sdb1 : start=     2048, size=  3991552, Id= c, bootable
/dev/sdb2 : start=        0, size=        0, Id= 0
/dev/sdb3 : start=        0, size=        0, Id= 0
/dev/sdb4 : start=        0, size=        0, Id= 0
EOF

# Make a filesystem and mount it
mkfs.vfat ${DEVNAME}1
mkdir -p $MTPT
mount ${DEVNAME}1 $MTPT

# Install extlinux on MBR
extlinux --install $MTPT
dd if=/usr/share/syslinux/mbr.bin of=$DEVNAME

# Install images which need to be outside the ISO.
# There may be a better way to do this.
mkdir -p $MTPT/images
for img in install.img product.img updates.img; do
  isoinfo -x /images/$img -J -R -i $ISO > $MTPT/images/$img
done

# Install syslinux config files
mkdir $MTPT/syslinux
for f in $( isoinfo -J -R -i $ISO -f | grep '/isolinux' | grep -v ldlinux ); do
  isoinfo -x $f -J -R -i $ISO > $MTPT/syslinux/$( basename $f )
done

# Reference the disk image UUID in the boot options
eval $( blkid ${DEVNAME}1 | cut -d: -f2 )
sed -e "s#initrd=initrd.img#initrd=initrd.img repo=hd:UUID=$UUID:/#" < $MTPT/syslinux/isolinux.cfg > $MTPT/syslinux/syslinux.cfg
rm $MTPT/syslinux/isolinux.cfg

# Copy ISO onto the stick
cp $ISO $MTPT

# Clean up
umount $MTPT
rmdir $MTPT
