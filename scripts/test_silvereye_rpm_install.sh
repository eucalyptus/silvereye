#!/bin/bash

echo "$(date) - Verifying package dependencies are met"
mkdir -p ${BUILDDIR}/tmprpmdb
rpm --initdb --dbpath ${BUILDDIR}/tmprpmdb
rpm --test --dbpath ${BUILDDIR}/tmprpmdb -Uvh ${BUILDDIR}/isolinux/CentOS/*.rpm > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo "$(date) - Package dependencies not met! Exiting."
  exit 1
else
  echo "$(date) - Package dependencies are OK"
fi
rm -rf ${BUILDDIR}/tmprpmdb

