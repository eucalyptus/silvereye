#!/bin/bash

# Configure CentOS repository
if [ -n "$CENTOSMIRROR" ] ; then
  sed -i -e 's%^mirrorlist=http.*%#\0%g' /etc/yum.repos.d/CentOS-*.repo
  sed -i -e "s%#baseurl=http://mirror.centos.org/centos/%baseurl=${CENTOSMIRROR}%g" /etc/yum.repos.d/CentOS-*.repo
fi

# Install/configure EPEL repository
rpm -q epel-release > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing EPEL package"
  if [ -z "$EPELMIRROR" ] ; then
    EPELFETCHMIRROR=`curl -s http://mirrors.fedoraproject.org/mirrorlist?repo=epel-${ELVERSION}\&arch=x86_64 | grep -vE '(^#|^ftp)' | head -n 1`
  else
    EPELFETCHMIRROR="${EPELMIRROR}${ELVERSION}/x86_64/"
  fi
  case "$ELVERSION" in
  "5")
    wget ${EPELFETCHMIRROR}epel-release-5-4.noarch.rpm
    ;;
  "6")
    wget ${EPELFETCHMIRROR}epel-release-6-7.noarch.rpm
    ;;
  esac
  rpm -Uvh epel-release-*.noarch.rpm
  rm -f epel-release-*.noarch.rpm
else
  echo "$(date) - EPEL package already installed"
fi
if [ -n "$EPELMIRROR" ] ; then
  sed -i -e 's%^mirrorlist=http.*%#\0%g' /etc/yum.repos.d/epel.repo
  sed -i -e "s%#baseurl=http://download.fedoraproject.org/pub/epel/%baseurl=${EPELMIRROR}%g" /etc/yum.repos.d/epel.repo
fi

# Install/configure ELRepo repository
rpm -q elrepo-release > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing ELRepo package"
  if [ -z "$ELREPOMIRROR" ] ; then
    ELREPOFETCHMIRROR=`curl -s http://elrepo.org/mirrors-elrepo.el${ELVERSION} | grep -vE '(^#|^ftp)' | sed -e 's/$basearch/x86_64/' | head -n 1`
  else
    ELREPOFETCHMIRROR="${ELREPOMIRROR}el${ELVERSION}/x86_64/"
  fi
  case "$ELVERSION" in
  "5")
    wget ${ELREPOFETCHMIRROR}/RPMS/elrepo-release-5-3.el5.elrepo.noarch.rpm
    ;;
  "6")
    wget ${ELREPOFETCHMIRROR}/RPMS/elrepo-release-6-4.el6.elrepo.noarch.rpm
    ;;
  esac
  rpm -Uvh elrepo-release-*.noarch.rpm
  rm -f elrepo-release-*.noarch.rpm
else
  echo "$(date) - ELRepo package already installed"
fi
if [ -n "$ELREPOMIRROR" ] ; then
  sed -i -e 's%^mirrorlist=http.*%#\0%g' /etc/yum.repos.d/elrepo.repo
  sed -i -e "s%baseurl=http://elrepo.org/linux/elrepo/%baseurl=${ELREPOMIRROR}%g" /etc/yum.repos.d/elrepo.repo
fi

# Install/configure Eucalyptus repository
case "$EUCALYPTUSVERSION" in
"3.1")
  rpm -q eucalyptus-release > /dev/null
  if [ $? -eq 1 ] ; then
    echo "$(date) - Installing Eucalyptus release repository package"
    wget http://downloads.eucalyptus.com/software/eucalyptus/3.1/centos/$ELVERSION/x86_64/eucalyptus-release-3.1.noarch.rpm
    rpm -Uvh eucalyptus-release*.rpm
    rm -f eucalyptus-release*.rpm
  else
    echo "$(date) - Eucalyptus release repository package already installed"
  fi
  rpm -q eucalyptus-release-nightly > /dev/null
  if [ $? -eq 0 ] ; then
    echo "$(date) - Removing Eucalyptus nightly repository package"
    yum -y remove eucalyptus-release-nightly*
  else
    echo "$(date) - Eucalyptus nightly repository package not present"
  fi
  if [ -f /etc/yum.repos.d/eucalyptus-nightly.repo ] ; then
    rm -f /etc/yum.repos.d/eucalyptus-nightly.repo
  fi
  ;;
"nightly")
  rpm -q eucalyptus-release-nightly > /dev/null
  if [ $? -eq 1 ] ; then
    echo "$(date) - Installing Eucalyptus nightly repository package"
    wget http://downloads.eucalyptus.com/software/eucalyptus/nightly/3.1/centos/$ELVERSION/x86_64/eucalyptus-release-nightly-3.1.noarch.rpm
    rpm -Uvh eucalyptus-release-nightly*.rpm
    rm -f eucalyptus-release-nightly*.rpm
  else
    echo "$(date) - Eucalyptus nightly repository package already installed"
  fi
  rpm -q eucalyptus-release > /dev/null
  if [ $? -eq 0 ] ; then
    echo "$(date) - Removing Eucalyptus release repository package"
    yum -y remove eucalyptus-release*
  else
    echo "$(date) - Eucalyptus release repository package not present"
  fi
  if [ -f /etc/yum.repos.d/eucalyptus.repo ] ; then
    rm -f /etc/yum.repos.d/eucalyptus.repo
  fi
  ;;
*)
  echo "$(date) - Unsupported EUCALYPTUSVERSION $EUCALYPTUSVERSION"
  ;;
esac

# Install euca2ools repository
rpm -q euca2ools-release > /dev/null
if [ $? -eq 1 ] ; then
  echo "$(date) - Installing euca2ools repository package"
  case "$EUCALYPTUSVERSION" in
    "3.1")
      wget http://downloads.eucalyptus.com/software/euca2ools/2.1/centos/${ELVERSION}/x86_64/euca2ools-release-2.1.noarch.rpm
    ;;
    "nightly")
      wget http://downloads.eucalyptus.com/software/euca2ools/2.1/centos/${ELVERSION}/x86_64/euca2ools-release-2.1.noarch.rpm
    ;;
  esac
  rpm -Uvh euca2ools-release*.rpm
  rm -f euca2ools-release*.rpm
else
  echo "$(date) - euca2ools repository package already installed"
fi

