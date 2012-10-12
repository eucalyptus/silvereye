#!/bin/bash

# Extract the Eucalyptus logo and use it for the boot logo
echo "$(date) - Creating boot logo"
mkdir -p ${BUILDDIR}/tmplogo
cd ${BUILDDIR}/tmplogo
rpm2cpio ${BUILDDIR}/image/CentOS/eucalyptus-common-java-*.rpm | cpio -idmv ./var/lib/eucalyptus/webapps/root.war > /dev/null 2>&1
jar -xf ./var/lib/eucalyptus/webapps/root.war > /dev/null 2>&1
case "$ELVERSION" in
"5")
  convert -size 640x120 xc:#ffffff white_background.png
  convert themes/eucalyptus/logo.png -resize 250% large-logo.png
  composite -gravity center large-logo.png white_background.png splash.png
  convert splash.png -depth 8 -colors 14 splash.ppm
  ppmtolss16 < splash.ppm > splash.lss 2> /dev/null
  rm -f splash.png
  rm -f splash.ppm
;;
"6")
  # The below should work for creating a gradient, but because it doesn't, we hack around it.
  # convert -size 640x480 gradient:'#022b40-#abbfca' gradient_background.png
  convert -size 1x1 xc:#022b40 top.png
  convert -size 1x1 xc:#abbfca bottom.png
  convert top.png bottom.png -append merged.png
  convert merged.png -resize 640x480\! gradient_background.png
  convert themes/eucalyptus/logo.png -resize 250% large-logo.png
  composite -gravity south -geometry +0+50 large-logo.png gradient_background.png splash.jpg
;;
esac
rm -f ${BUILDDIR}/image/isolinux/splash.*
mv splash.* ${BUILDDIR}/image/isolinux/
cd ..
rm -rf tmplogo

