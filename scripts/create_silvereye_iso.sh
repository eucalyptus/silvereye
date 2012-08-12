#!/bin/bash

cd ${BUILDDIR}
mkisofs -o silvereye.${DATESTAMP}.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -T -joliet-long isolinux/ > /dev/null 2>&1
case "$ELVERSION" in
"5")
  /usr/lib/anaconda-runtime/implantisomd5 silvereye.${DATESTAMP}.iso > /dev/null
  ;;
"6")
  /usr/bin/implantisomd5 silvereye.${DATESTAMP}.iso > /dev/null
  ;;
esac
mv silvereye.${DATESTAMP}.iso ../
cd ..

echo "$(date) - CD image silvereye.${DATESTAMP}.iso successfully created"

