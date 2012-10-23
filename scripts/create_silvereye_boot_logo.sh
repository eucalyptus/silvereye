#!/bin/bash

# Extract the Eucalyptus logo and use it for the boot logo
case "$ELVERSION" in
"5")
  convert -size 640x120 xc:#ffffff white_background.png
  composite -gravity center $LOGOFILE white_background.png splash.png
  convert splash.png -depth 8 -colors 14 splash.ppm
  ppmtolss16 < splash.ppm > ${BUILDDIR}/image/isolinux/splash.lss 
;;
"6")
  # The below should work for creating a gradient, but because it doesn't, we hack around it.
  # convert -size 640x480 gradient:'#022b40-#abbfca' gradient_background.png
  convert -size 1x1 xc:#022b40 top.png
  convert -size 1x1 xc:#abbfca bottom.png
  convert top.png bottom.png -append merged.png
  convert merged.png -resize 640x480\! gradient_background.png
  composite -gravity south -geometry +0+50 $LOGOFILE gradient_background.png ${BUILDDIR}/image/isolinux/splash.jpg
;;
esac
