#!/bin/bash

# Function to install packages on build system if they aren't already present
function install_package {
  rpm -q $1 > /dev/null
  if [ $? -eq 1 ] ; then
    echo "$(date) - Installing $1 package"
    yum -y install $1 > /dev/null
  else
    echo "$(date) - $1 package already installed"
  fi
}

install_package curl
install_package wget
install_package yum-utils
install_package createrepo
install_package ImageMagick
install_package syslinux
install_package java-1.6.0-openjdk-devel
case "$ELVERSION" in
"5")
  install_package anaconda-runtime
  install_package squashfs-tools
  ;;
"6")
  install_package syslinux-perl
  install_package anaconda
  ;;
esac

