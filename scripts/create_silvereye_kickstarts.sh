#!/bin/bash

# Copy kickstart templates
cp ${BUILDDIR}/../ks_templates/*.cfg ${BUILDDIR}/image/ks/

# Customize kickstart files for CentOS 5 or CentOS 6, and Eucalyptus version
case "$ELVERSION" in
"5")
  # sed -i -e '/%end/d' ${BUILDDIR}/image/ks/*.cfg
  ;;
"6")
  sed -i -e '/^network .*query$/d' ${BUILDDIR}/image/ks/*.cfg
  sed -i -e '/^dbus-python$/d' ${BUILDDIR}/image/ks/*.cfg
  sed -i -e '/^kernel-xen$/d' ${BUILDDIR}/image/ks/*.cfg
  sed -i -e '/^libxml2-python$/d' ${BUILDDIR}/image/ks/*.cfg
  sed -i -e '/^xen$/d' ${BUILDDIR}/image/ks/*.cfg
  sed -i -e '/^-kernel$/d' ${BUILDDIR}/image/ks/*.cfg
  ;;
esac
case "$EUCALYPTUSVERSION" in
"3.1")
  sed -i -e 's/EUCALYPTUSRELEASEPACKAGEREPLACEME/eucalyptus-release/' ${BUILDDIR}/image/ks/*.cfg
  ;;
"nightly")
  sed -i -e 's/EUCALYPTUSRELEASEPACKAGEREPLACEME/eucalyptus-release-nightly/' ${BUILDDIR}/image/ks/*.cfg
  ;;
esac

