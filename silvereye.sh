#!/bin/bash
#
# Copyright (c) 2012  Eucalyptus Systems, Inc.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, only version 3 of the License.
#
#
#   This file is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   Please contact Eucalyptus Systems, Inc., 6755 Hollister Ave.
#   Goleta, CA 93117 USA or visit <http://www.eucalyptus.com/licenses/>
#   if you need additional information or have any questions.
#
#
# This script will create a customized CentOS x86_64 minimal installation
# CD image that includes Eucalyptus in the installations.
# The script should be used from an existing CentOS x86_64 installation.
# If the EPEL, ELRepo, euca2ools and Eucalyptus package repositories are not
# present on the system this script will install/create them.
#
set -a
#
# If you have a local mirror that you prefer to use, modify and uncomment the
# line(s) below.
#CENTOSMIRROR="http://10.1.1.240/centos/"
#EPELMIRROR="http://10.1.1.240/epel/"
#ELREPOMIRROR="http://10.1.1.240/elrepo/"
#
# Set the EUCALYPTUSVERSION variable to the version of Eucalyptus you would like
# to create an installation disk for.
# Valid values are "3.1", and "nightly".
EUCALYPTUSVERSION="3.1"

# Modification below this point shouldn't be necessary

# Set the ELVERSION variable
ELVERSION=`cat /etc/redhat-release | sed -e 's/.* \([56]\).*/\1/'`

# Exit if the script is not run with root privileges
if [ "$EUID" != "0" ] ; then
  echo "This script must be run with root privileges."
  exit 1
fi

# Create the build directory, cd into it, and set the log file variable
DATESTAMP=`date +%s.%N | rev | cut -b 4- | rev`
mkdir -p silvereye_build.${DATESTAMP}
cd silvereye_build.$DATESTAMP
BUILDDIR=`pwd`
SILVEREYELOGFILE="${BUILDDIR}/silvereye.$DATESTAMP.log"
echo "$(date) - Created $BUILDDIR" | tee -a $SILVEREYELOGFILE

#Exit if we're not running on CentOS 5 or 6
case "$ELVERSION" in
"5"|"6")
  echo "$(date) - Building installation CD image for CentOS $ELVERSION with Eucalyptus $EUCALYPTUSVERSION." | tee -a $SILVEREYELOGFILE
  ;;
*)
  echo "$(date) - Error: This script must be run on CentOS version 5 or 6" | tee -a $SILVEREYELOGFILE
  exit 1
  ;;
esac

# Install silvereye dependencies
../scripts/install_silvereye_dependencies.sh | tee -a $SILVEREYELOGFILE

# Create the build directory structure
../scripts/get_silvereye_build_files.sh | tee -a $SILVEREYELOGFILE

# Create kickstart files
../scripts/create_silvereye_kickstarts.sh

# Copy configuration scripts
cp ${BUILDDIR}/../scripts/eucalyptus-frontend-config.sh ${BUILDDIR}/image/scripts/
cp ${BUILDDIR}/../scripts/eucalyptus-nc-config.sh ${BUILDDIR}/image/scripts/
cp ${BUILDDIR}/../scripts/eucalyptus-create-emi.sh ${BUILDDIR}/image/scripts/

# Configure yum repositories
../scripts/configure_silvereye_yum_reops.sh | tee -a $SILVEREYELOGFILE

# Retrieve the RPMs for CentOS, Eucalyptus, and dependencies
../scripts/get_silvereye_rpms.sh | tee -a $SILVEREYELOGFILE

# Test the installation of the RPMs to verify that we have all dependencies
../scripts/test_silvereye_rpm_install.sh | tee -a $SILVEREYELOGFILE

# Create a repository
../scripts/create_silvereye_repo.sh | tee -a $SILVEREYELOGFILE

# Create boot logo
../scripts/create_silvereye_boot_logo.sh | tee -a $SILVEREYELOGFILE

# Edit the boot menu
../scripts/edit_silvereye_boot_menu.sh | tee -a $SILVEREYELOGFILE

# Create the .iso image
../scripts/create_silvereye_iso.sh | tee -a $SILVEREYELOGFILE

