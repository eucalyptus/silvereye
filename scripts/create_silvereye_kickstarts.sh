#!/bin/bash

# Copy kickstart templates
cp ${BUILDDIR}/../ks_templates/*.cfg ${BUILDDIR}/isolinux/ks/

# Customize kickstart files for CentOS 5 or CentOS 6, and Eucalyptus version
case "$ELVERSION" in
"5")
  # sed -i -e '/%end/d' ${BUILDDIR}/isolinux/ks/*.cfg
  ;;
"6")
  sed -i -e 's/^network .*query$/network --activate/' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/^dbus-python$/d' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/^kernel-xen$/d' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/^libxml2-python$/d' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/^xen$/d' ${BUILDDIR}/isolinux/ks/*.cfg
  sed -i -e '/^-kernel$/d' ${BUILDDIR}/isolinux/ks/*.cfg
  ;;
esac
case "$EUCALYPTUSVERSION" in
"3.1")
  sed -i -e 's/EUCALYPTUSRELEASEPACKAGEREPLACEME/eucalyptus-release/' ${BUILDDIR}/isolinux/ks/*.cfg
  ;;
"nightly")
  sed -i -e 's/EUCALYPTUSRELEASEPACKAGEREPLACEME/eucalyptus-release-nightly/' ${BUILDDIR}/isolinux/ks/*.cfg
  ;;
esac

