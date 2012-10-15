#!/bin/bash

# groupinfo is ugly in shell.  Maybe pythonify it?
RPMS=$( yum groupinfo Core | grep "^   " )" \
centos-release.x86_64 epel-release.noarch euca2ools-release.noarch \
authconfig fuse-libs gpm libsysfs mdadm ntp postgresql-libs prelink \
setools system-config-network-tui tzdata tzdata-java udftools unzip \
wireless-tools \
eucalyptus.x86_64 eucalyptus-admin-tools.x86_64 eucalyptus-cc.x86_64 \
eucalyptus-cloud eucalyptus-common-java.x86_64 eucalyptus-gl.x86_64 \
eucalyptus-nc.x86_64 eucalyptus-sc.x86_64 eucalyptus-walrus.x86_64"

# Set list of RPMs to download
case "$ELVERSION" in
"5")
  ;;
"6")
  RPMS="$RPMS ntpdate libvirt-client elrepo-release iwl6000g2b-firmware \
sysfsutils"
  ;;
esac

# Download the base rpms
cd ${BUILDDIR}/image/CentOS
echo "$(date) - Retrieving packages"
yumdownloader --resolve --installroot ${BUILDDIR} --setopt "exclude=*.i?86" --releasever $ELVERSION $RPMS > /dev/null

# Download Eucalyptus release package
case "$EUCALYPTUSVERSION" in
"3.1")
  yumdownloader eucalyptus-release.noarch > /dev/null
  ;;
"nightly")
  yumdownloader eucalyptus-release-nightly.noarch > /dev/null
  ;;
esac

