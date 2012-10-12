#!/bin/bash

case "$ELVERSION" in
"5")
  cd ${BUILDDIR}/image/isolinux
  sed -i -e 's/ -  To install or upgrade in graphical mode, press the '`echo "\o017"`'0b<ENTER>'`echo "\o017"`'07 key./NOTE: It is recommended that you install and configure Node Controllers prior to installing and configuring your Frontend.\n\n -  To install CentOS 5 with Eucalyptus Node Controller, type: '`echo "\o017"`'0bnc <ENTER>'`echo "\o017"`'07.\n\n -  To install CentOS 5 with Eucalyptus Frontend, type: '`echo "\o017"`'0bfrontend <ENTER>'`echo "\o017"`'07.\n\n -  To install a single-server, Eucalyptus Cloud-in-a-box, type: '`echo "\o017"`'0bciab <ENTER>'`echo "\o017"`'07.\n\n -  To install a minimal CentOS 5 without Eucalyptus, type: '`echo "\o017"`'0bminimal <ENTER>'`echo "\o017"`'07./g' boot.msg
  sed -i -e 's/ -  To install or upgrade in text mode, type: '`echo "\o017"`'0blinux text <ENTER>'`echo "\o017"`'07./ -  For text mode installations, append the word text, e.g., '`echo "\o017"`'0bnc text <ENTER>'`echo "\o017"`'07./g' boot.msg
  sed -i -e 's/default linux/default local/g' isolinux.cfg
  sed -i -e 's%  append -%\0\nlabel nc\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/nc.cfg\nlabel frontend\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/frontend.cfg\nlabel ciab\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/ciab.cfg\nlabel minimal\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/minimal.cfg\n%g' isolinux.cfg
  ;;
"6")
  cd ${BUILDDIR}/image/isolinux
  sed -i -e '/  menu default/d' isolinux.cfg
  sed -i -e 's/^\(  menu label Boot from .*drive\)$/\1\n  menu default/g' isolinux.cfg
  sed -i -e 's/label linux/label nc/' isolinux.cfg
  sed -i -e 's/menu label ^Install or upgrade an existing system/menu label Install CentOS 6 with Eucalyptus ^Node Controller/' isolinux.cfg
  sed -i -e 's%^  append initrd=initrd.img$%  append initrd=initrd.img ks=cdrom:/ks/nc.cfg%' isolinux.cfg
  sed -i -e 's/label vesa/label frontend/' isolinux.cfg
  sed -i -e 's/menu label Install system with ^basic video driver/menu label Install CentOS 6 with Eucalyptus ^Frontend/' isolinux.cfg
  sed -i -e 's%^  append initrd=initrd.img xdriver=vesa nomodeset%  append initrd=initrd.img ks=cdrom:/ks/frontend.cfg%' isolinux.cfg
  sed -i -e 's%^\(label rescue\)$%label ciab\n  menu label Install CentOS 6 with Eucalyptus ^Cloud-in-a-box\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/ciab.cfg\nlabel minimal\n  menu label Install a ^minimal CentOS 6 without Eucalyptus\n  kernel vmlinuz\n  append initrd=initrd.img ks=cdrom:/ks/minimal.cfg\n\1%' isolinux.cfg
  sed -i -e 's/menu title Welcome to CentOS .*$/menu title Install NCs before installing Frontend./' isolinux.cfg
  ;;
esac

cd ${BUILDDIR}/image

echo "$(date) - Boot menu edited"

