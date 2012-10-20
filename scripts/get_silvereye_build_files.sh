#!/bin/bash

# Create the build directory structure
mkdir -p ${BUILDDIR}/image/{CentOS,images,isolinux,ks,scripts}
mkdir -p ${BUILDDIR}/image/images/pxeboot
if [ $ELVERSION -eq 5 ] ; then
  mkdir -p ${BUILDDIR}/image/images/xen
fi
echo "$(date) - Created $BUILDDIR directory structure"

#Set the mirror to use for retrieving files
if [ -z "$CENTOSMIRROR" ] ; then
  FETCHMIRROR=`curl -s http://mirrorlist.centos.org/?release=${ELVERSION}\&arch=x86_64\&repo=os | grep -vE '(^#|^ftp)' | head -n 1`
else
  FETCHMIRROR="${CENTOSMIRROR}${ELVERSION}/os/x86_64/"
fi
echo "$(date) - Using $FETCHMIRROR for downloads"

# Retrieve the comps.xml file
echo "$(date) - Retrieving files"
COMPSFILE=`curl -s ${FETCHMIRROR}repodata/ | grep 'comps.xml\"' | sed -e 's/.*href=\"\(.*comps.xml\)\".*/\1/'`
wget ${FETCHMIRROR}/repodata/${COMPSFILE} > /dev/null 2>&1

# Retrieve the files for the root filesystem of the CD
wget ${FETCHMIRROR}/.discinfo -O image/.discinfo > /dev/null 2>&1

# Retrieve the files for the isolinux directory
COMMONFILES="
EULA
GPL
isolinux/boot.msg
isolinux/initrd.img
isolinux/isolinux.bin
isolinux/isolinux.cfg
isolinux/memtest
isolinux/vmlinuz
"
for FILE in $COMMONFILES ; do
wget ${FETCHMIRROR}/${FILE} -O image/${FILE} > /dev/null 2>&1
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
wget ${FETCHMIRROR}/${FILE} -O image/${FILE} > /dev/null 2>&1
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
wget ${FETCHMIRROR}/images/${FILE} -O ./image/images/${FILE} > /dev/null 2>&1
done

# Customize anaconda to allow copying files from CD during %post scripts in EL5, and network prompting in EL6
case "$ELVERSION" in
"5")
  echo "$(date) - Creating updates.img"
  mkdir -p tmp-anaconda-updates/{stage2,updates}
  cd tmp-anaconda-updates
  mount -rw -t squashfs -o loop ${BUILDDIR}/image/images/stage2.img stage2
  dd if=/dev/zero of=updates.img bs=1K count=1 seek=127 > /dev/null 2>&1
  parted updates.img mklabel msdos
  mkfs.ext2 -F -L updates updates.img > /dev/null 2>&1
  losetup -f updates.img
  UPDATESLOOPDEVICE=`losetup -a | grep -E "updates.img" | awk '{print $1}' | sed 's/://g'`
  mount $UPDATESLOOPDEVICE updates
  cp stage2/usr/lib/anaconda/dispatch.py updates/
  sed -i -e 's/    ("dopostaction", doPostAction, ),/#####/g' updates/dispatch.py
  sed -i -e 's/    ("methodcomplete", doMethodComplete, ),/    ("dopostaction", doPostAction, ),/g' updates/dispatch.py
  sed -i -e 's/#####/    ("methodcomplete", doMethodComplete, ),/g' updates/dispatch.py
  umount stage2
  umount updates
  losetup -d $UPDATESLOOPDEVICE
  mv updates.img ${BUILDDIR}/image/images/
  cd ${BUILDDIR}
  rm -rf tmp-anaconda-updates
  echo "$(date) - Created updates.img"
  ;;
"6")
  echo "$(date) - Creating updates.img"
  mkdir -p tmp-anaconda-updates/{install,updates}
  cd tmp-anaconda-updates
  mount -rw -t squashfs -o loop ${BUILDDIR}/image/images/install.img install/
  cp install/usr/lib/anaconda/kickstart.py updates/
  sed -i '/dispatch.skipStep.*network/d' updates/kickstart.py
  cd updates
  find . | cpio -H newc -o > ../updates.img.tmp 2>/dev/null
  cd ..
  gzip updates.img.tmp
  mv updates.img.tmp.gz ${BUILDDIR}/image/images/updates.img
  umount install
  cd ${BUILDDIR}
  rm -rf tmp-anaconda-updates
  echo "$(date) - Created updates.img"
  ;;
esac

