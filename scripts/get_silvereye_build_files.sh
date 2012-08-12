#!/bin/bash

# Create the build directory structure
mkdir -p ${BUILDDIR}/isolinux/{CentOS,images,ks,scripts}
mkdir -p ${BUILDDIR}/isolinux/images/pxeboot
if [ $ELVERSION -eq 5 ] ; then
  mkdir -p ${BUILDDIR}/isolinux/images/xen
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
wget ${FETCHMIRROR}/.discinfo -O isolinux/.discinfo > /dev/null 2>&1

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
wget ${FETCHMIRROR}/${FILE} -O ${FILE} > /dev/null 2>&1
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
wget ${FETCHMIRROR}/${FILE} -O ${FILE} > /dev/null 2>&1
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
wget ${FETCHMIRROR}/images/${FILE} -O ./isolinux/images/${FILE} > /dev/null 2>&1
done

# Fix EL5 anaconda bug to allow copying files from CD during %post scripts
if [ $ELVERSION -eq 5 ] ; then
  mkdir tmp-anaconda-fix
  cd tmp-anaconda-fix
  mkdir anaconda
  mkdir anaconda-new
  mount -rw -t squashfs -o loop ${BUILDDIR}/isolinux/images/stage2.img anaconda/
  cd anaconda
  tar cf - * .buildstamp | ( cd ${BUILDDIR}/tmp-anaconda-fix/anaconda-new; tar xfp -)
  cd ../anaconda-new
  umount ${BUILDDIR}/tmp-anaconda-fix/anaconda
  sed -i -e 's/    ("dopostaction", doPostAction, ),/#####/g' usr/lib/anaconda/dispatch.py
  sed -i -e 's/    ("methodcomplete", doMethodComplete, ),/    ("dopostaction", doPostAction, ),/g' usr/lib/anaconda/dispatch.py
  sed -i -e 's/#####/    ("methodcomplete", doMethodComplete, ),/g' usr/lib/anaconda/dispatch.py
  mksquashfs . ${BUILDDIR}/tmp-anaconda-fix/stage2.img.new -all-root -no-fragments
  rm -f ${BUILDDIR}/isolinux/images/stage2.img
  mv ${BUILDDIR}/tmp-anaconda-fix/stage2.img.new ${BUILDDIR}/isolinux/images/stage2.img
  cd ${BUILDDIR}
  rm -rf tmp-anaconda-fix
  echo "$(date) - Created patched stage2.img"
fi

