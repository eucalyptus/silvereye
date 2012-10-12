#!/bin/bash

# Set list of RPMs to download
case "$ELVERSION" in
"5")
  RPMS="alsa-lib.x86_64 antlr.x86_64 apr.x86_64 apr-util.x86_64 atk.x86_64 \
audiofile.x86_64 audit-libs.x86_64 audit-libs-python.x86_64 authconfig.x86_64 \
avahi.x86_64 avalon-framework.x86_64 avalon-logkit.x86_64 axis.x86_64 \
axis2c.x86_64 basesystem.noarch bash.x86_64 bc.x86_64 bcel.x86_64 \
binutils.x86_64 bitstream-vera-fonts.noarch bridge-utils.x86_64 bzip2.x86_64 \
bzip2-libs.x86_64 cairo.x86_64 centos-release.x86_64 \
centos-release-notes.x86_64 checkpolicy.x86_64 chkconfig.x86_64 \
classpathx-jaf.x86_64 classpathx-mail.x86_64 coreutils.x86_64 cpio.x86_64 \
cracklib.x86_64 cracklib-dicts.x86_64 crontabs.noarch cryptsetup-luks.x86_64 \
cups-libs.x86_64 curl.x86_64 cyrus-sasl.x86_64 cyrus-sasl-lib.x86_64 \
cyrus-sasl-md5.x86_64 db4.x86_64 dbus.x86_64 dbus-glib.x86_64 dbus-libs.x86_64 \
dbus-python.x86_64 device-mapper.x86_64 device-mapper-event.x86_64 \
device-mapper-multipath.x86_64 dhclient.x86_64 dhcp.x86_64 diffutils.x86_64 \
dmidecode.x86_64 dmraid.x86_64 dmraid-events.x86_64 dnsmasq.x86_64 \
e2fsprogs.x86_64 e2fsprogs-libs.x86_64 e4fsprogs-libs.x86_64 ebtables.x86_64 \
ed.x86_64 elfutils-libelf.x86_64 elrepo-release.noarch epel-release.noarch \
esound.x86_64 ethtool.x86_64 euca2ools.noarch euca2ools-release.noarch \
eucalyptus.x86_64 eucalyptus-admin-tools.x86_64 eucalyptus-cc.x86_64 \
eucalyptus-cloud eucalyptus-common-java.x86_64 eucalyptus-gl.x86_64 \
eucalyptus-nc.x86_64 eucalyptus-sc.x86_64 eucalyptus-walrus.x86_64 \
expat.x86_64 file.x86_64 filesystem.x86_64 findutils.x86_64 fipscheck.x86_64 \
fipscheck-lib.x86_64 fontconfig.x86_64 freetype.x86_64 fuse-libs.x86_64 \
gawk.x86_64 gdbm.x86_64 geronimo-specs.x86_64 geronimo-specs-compat.x86_64 \
giflib.x86_64 gjdoc.x86_64 glib2.x86_64 glibc.i686 glibc.x86_64 \
glibc-common.x86_64 gnutls.x86_64 gpm.x86_64 grep.x86_64 grub.x86_64 \
gtk2.x86_64 gzip.x86_64 hal.x86_64 hdparm.x86_64 hesiod.x86_64 \
hicolor-icon-theme.noarch hmaccalc.x86_64 httpd.x86_64 hwdata.noarch \
info.x86_64 initscripts.x86_64 iproute.x86_64 iptables.x86_64 \
iptables-ipv6.x86_64 iputils.x86_64 iscsi-initiator-utils.x86_64 \
jakarta-commons-collections.x86_64 jakarta-commons-discovery.x86_64 \
jakarta-commons-httpclient.x86_64 jakarta-commons-logging.x86_64 \
jakarta-oro.x86_64 java-1.4.2-gcj-compat.x86_64 java-1.6.0-openjdk.x86_64 \
jdom.x86_64 jpackage-utils.noarch kbd.x86_64 kernel.x86_64 kernel-xen.x86_64 \
keyutils-libs.x86_64 kmod-drbd83.x86_64 kpartx.x86_64 krb5-libs.x86_64 \
kudzu.x86_64 less.x86_64 libacl.x86_64 libart_lgpl.x86_64 libattr.x86_64 \
libcap.x86_64 libdaemon.x86_64 libevent.x86_64 libffi.x86_64 libgcc.i386 \
libgcc.x86_64 libgcj.x86_64 libgcrypt.x86_64 libgpg-error.x86_64 \
libgssapi.x86_64 libICE.x86_64 libidn.x86_64 libibverbs.x86_64 libjpeg.x86_64 \
libpng.x86_64 librdmacm.x86_64 libselinux.x86_64 libselinux-python.x86_64 \
libselinux-utils.x86_64 libsemanage.x86_64 libsepol.x86_64 libSM.x86_64 \
libstdc++.x86_64 libsysfs.x86_64 libtermcap.x86_64 libtiff.x86_64 \
libusb.x86_64 libuser.x86_64 libutempter.x86_64 libvirt.x86_64 \
libvirt-python.x86_64 libvolume_id.x86_64 libX11.x86_64 libXau.x86_64 \
libXcursor.x86_64 libXdmcp.x86_64 libXext.x86_64 libXfixes.x86_64 \
libXft.x86_64 libXi.x86_64 libXinerama.x86_64 libxml2.x86_64 \
libxml2-python.x86_64 libXrandr.x86_64 libXrender.x86_64 libxslt.x86_64 \
libXtst.x86_64 log4j.x86_64 logrotate.x86_64 lvm2.x86_64 lzo.x86_64 \
m2crypto.x86_64 mailcap.noarch MAKEDEV.x86_64 mcstrans.x86_64 \
mdadm.x86_64 mingetty.x86_64 mkinitrd.x86_64 mktemp.x86_64 \
module-init-tools.x86_64 mx4j.x86_64 nash.x86_64 nc.x86_64 ncurses.x86_64 \
net-tools.x86_64 newt.x86_64 nfs-utils.x86_64 nfs-utils-lib.x86_64 nspr.x86_64 \
nss.x86_64 ntp.x86_64 numactl.x86_64 openib.noarch openldap.x86_64 \
openssh.x86_64 openssh-clients.x86_64 openssh-server.x86_64 openssl.x86_64 \
pam.x86_64 pango.x86_64 parted.x86_64 passwd.x86_64 pciutils.x86_64 \
pcre.x86_64 perl.x86_64 perl-Config-General.noarch \
perl-Crypt-OpenSSL-Bignum.x86_64 perl-Crypt-OpenSSL-Random.x86_64 \
perl-Crypt-OpenSSL-RSA.x86_64 perl-DBI.x86_64 pm-utils.x86_64 \
policycoreutils.x86_64 popt.x86_64 portmap.x86_64 postgresql-libs.x86_64 \
postgresql91.x86_64 postgresql91-libs.x86_64 postgresql91-server.x86_64 \
prelink.x86_64 procmail.x86_64 procps.x86_64 psmisc.x86_64 python.x86_64 \
python-elementtree.x86_64 python-iniparse.noarch python-libs.x86_64 \
python-sqlite.x86_64 python-urlgrabber.noarch python-virtinst.noarch \
python26.x86_64 python26-boto.noarch python26-eucadmin.x86_64 \
python26-libs.x86_64 python26-m2crypto.x86_64 rampartc.x86_64 readline.x86_64 \
redhat-logos.noarch regexp.x86_64 rhpl.x86_64 rootfiles.noarch rpm.x86_64 \
rpm-libs.x86_64 rpm-python.x86_64 rsync.x86_64 rsyslog.x86_64 \
scsi-target-utils.x86_64 SDL.x86_64 sed.x86_64 selinux-policy.noarch \
selinux-policy-targeted.noarch sendmail.x86_64 setools.x86_64 setup.noarch \
sgpio.x86_64 shadow-utils.x86_64 slang.x86_64 sqlite.x86_64 sudo.x86_64 \
sysfsutils.x86_64 sysklogd.x86_64 system-config-network-tui.noarch \
SysVinit.x86_64 tar.x86_64 tcl.x86_64 tcp_wrappers.x86_64 termcap.noarch \
tomcat5-servlet-2.4-api.x86_64 tzdata.x86_64 tzdata-java.x86_64 udev.x86_64 \
udftools.x86_64 unzip.x86_64 usermode.x86_64 util-linux.x86_64 vblade.x86_64 \
vconfig.x86_64 velocity.x86_64 vim-minimal.x86_64 vtun.x86_64 \
werken-xpath.x86_64 wget.x86_64 which.x86_64 wireless-tools.x86_64 \
wsdl4j.x86_64 xalan-j2.x86_64 xen.x86_64 xen-libs.x86_64 xinetd.x86_64 \
xml-commons.x86_64 xml-commons-apis.x86_64 xml-commons-resolver.x86_64 \
xorg-x11-filesystem.noarch xz.x86_64 xz-libs.x86_64 yum.noarch \
yum-fastestmirror.noarch yum-metadata-parser.x86_64 zip.x86_64 zlib.x86_64"
  ;;
"6")
  RPMS="acl.x86_64 alsa-lib.x86_64 apache-tomcat-apis.noarch apr.x86_64 \
apr-util.x86_64 apr-util-ldap.x86_64 atk.x86_64 attr.x86_64 audit.x86_64 \
audit-libs.x86_64 augeas-libs.x86_64 authconfig.x86_64 avahi-libs.x86_64 \
avalon-framework.x86_64 avalon-logkit.noarch axis.noarch axis2c.x86_64 \
b43-openfwwf.noarch basesystem.noarch bash.x86_64 bc.x86_64 bcel.x86_64 \
bfa-firmware.noarch binutils.x86_64 bridge-utils.x86_64 bwidget.noarch \
bzip2.x86_64 bzip2-libs.x86_64 ca-certificates.noarch cairo.x86_64 \
celt051.x86_64 centos-release.x86_64 checkpolicy.x86_64 chkconfig.x86_64 \
classpathx-jaf.x86_64 classpathx-mail.noarch ConsoleKit.x86_64 \
ConsoleKit-libs.x86_64 coreutils.x86_64 coreutils-libs.x86_64 cpio.x86_64 \
cracklib.x86_64 cracklib-dicts.x86_64 crda.x86_64 cronie.x86_64 \
cronie-anacron.x86_64 crontabs.noarch cryptsetup-luks.x86_64 \
cryptsetup-luks-libs.x86_64 cups-libs.x86_64 curl.x86_64 cvs.x86_64 \
cyrus-sasl.x86_64 cyrus-sasl-lib.x86_64 cyrus-sasl-md5.x86_64 dash.x86_64 \
db4.x86_64 db4-utils.x86_64 dbus.x86_64 dbus-glib.x86_64 dbus-libs.x86_64 \
dbus-python.x86_64 dejavu-fonts-common.noarch dejavu-serif-fonts.noarch \
device-mapper.x86_64 device-mapper-event.x86_64 \
device-mapper-event-libs.x86_64 device-mapper-libs.x86_64 diffutils.x86_64 \
dhclient.x86_64 dhcp-common.x86_64 dhcp41.x86_64 dhcp41-common.x86_64 \
dmidecode.x86_64 dnsmasq.x86_64 dracut.noarch dracut-kernel.noarch \
drbd83-utils.x86_64 e2fsprogs.x86_64 e2fsprogs-libs.x86_64 ebtables.x86_64 \
eggdbus.x86_64 elfutils-libelf.x86_64 efibootmgr.x86_64 elrepo-release.noarch \
epel-release.noarch ethtool.x86_64 euca2ools.noarch euca2ools-release.noarch \
eucalyptus.x86_64 eucalyptus-admin-tools.noarch eucalyptus-cc.x86_64 \
eucalyptus-cloud eucalyptus-common-java.x86_64 eucalyptus-gl.x86_64 \
eucalyptus-nc.x86_64 eucalyptus-sc.x86_64 eucalyptus-walrus.x86_64 \
expat.x86_64 file.x86_64 file-libs.x86_64 filesystem.x86_64 findutils.x86_64 \
fipscheck.x86_64 fipscheck-lib.x86_64 flac.x86_64 fontconfig.x86_64 \
fontpackages-filesystem.noarch freetype.x86_64 fuse-libs.x86_64 gamin.x86_64 \
gawk.x86_64 gdbm.x86_64 geronimo-specs.noarch geronimo-specs-compat.noarch \
gettext.x86_64 giflib.x86_64 glib2.x86_64 glibc.i686 glibc.x86_64 \
glibc-common.x86_64 gmp.x86_64 gnupg2.x86_64 gnutls.x86_64 gnutls-utils.x86_64 \
gpgme.x86_64 gpm.x86_64 gpm-libs.x86_64 gpxe-roms-qemu.noarch grep.x86_64 \
groff.x86_64 grub.x86_64 grubby.x86_64 gtk2.x86_64 gzip.x86_64 hal.x86_64 \
hal-info.noarch hal-libs.x86_64 hdparm.x86_64 hicolor-icon-theme.noarch \
httpd.x86_64 httpd-tools.x86_64 hwdata.noarch info.x86_64 initscripts.x86_64 \
iproute.x86_64 iptables.x86_64 iptables-ipv6.x86_64 iputils.x86_64 \
ipw2100-firmware.noarch ipw2200-firmware.noarch iscsi-initiator-utils.x86_64 \
iw.x86_64 iwl1000-firmware.noarch iwl100-firmware.noarch \
iwl3945-firmware.noarch iwl4965-firmware.noarch iwl5000-firmware.noarch \
iwl5150-firmware.noarch iwl6000-firmware.noarch iwl6000g2a-firmware.noarch \
iwl6000g2b-firmware.noarch iwl6050-firmware.noarch \
jakarta-commons-collections.noarch jakarta-commons-discovery.noarch \
jakarta-commons-httpclient.x86_64 jakarta-commons-logging.noarch \
jakarta-oro.x86_64 jasper-libs.x86_64 java-1.5.0-gcj.x86_64 \
java-1.6.0-openjdk.x86_64 java_cup.x86_64 jdom.noarch jline.noarch \
jpackage-utils.noarch kbd.x86_64 kbd-misc.noarch kernel.x86_64 \
kernel-firmware.noarch keyutils.x86_64 keyutils-libs.x86_64 kmod-drbd83.x86_64 \
krb5-libs.x86_64 less.x86_64 libacl.x86_64 libaio.x86_64 libart_lgpl.x86_64 \
libasyncns.x86_64 libattr.x86_64 libblkid.x86_64 libcap.x86_64 \
libcap-ng.x86_64 libcgroup.x86_64 libcom_err.x86_64 libcurl.x86_64 \
libdrm.x86_64 libedit.x86_64 libevent.x86_64 libffi.x86_64 libgcc.i686 \
libgcc.x86_64 libgcj.x86_64 libgcrypt.x86_64 libglade2.x86_64 libgomp.x86_64 \
libgpg-error.x86_64 libgssglue.x86_64 libibverbs.x86_64 libICE.x86_64 \
libidn.x86_64 libjpeg.x86_64 libnih.x86_64 libnl.x86_64 libogg.x86_64 \
libpcap.x86_64 libpciaccess.x86_64 libpng.x86_64 librdmacm.x86_64 \
libselinux.x86_64 libselinux-python.x86_64 libselinux-utils.x86_64 \
libsemanage.x86_64 libsepol.x86_64 libSM.x86_64 libsndfile.x86_64 libss.x86_64 \
libssh2.x86_64 libstdc++.x86_64 libsysfs.x86_64 libtasn1.x86_64 libthai.x86_64 \
libtiff.x86_64 libtirpc.x86_64 libudev.x86_64 libusb.x86_64 libusb1.x86_64 \
libuser.x86_64 libutempter.x86_64 libuuid.x86_64 libvirt.x86_64 \
libvirt-client.x86_64 libvorbis.x86_64 libX11.x86_64 libX11-common.noarch \
libXau.x86_64 libxcb.x86_64 libXcomposite.x86_64 libXcursor.x86_64 \
libXdamage.x86_64 libXext.x86_64 libXfixes.x86_64 libXft.x86_64 libXi.x86_64 \
libXinerama.x86_64 libxml2.x86_64 libXrandr.x86_64 libXrender.x86_64 \
libxslt.x86_64 libXtst.x86_64 log4j.x86_64 logrotate.x86_64 lsof.x86_64 \
lua.x86_64 lvm2.x86_64 lvm2-libs.x86_64 lzo.x86_64 lzop.x86_64 m2crypto.x86_64 \
m4.x86_64 mailcap.noarch MAKEDEV.x86_64 mdadm.x86_64 mingetty.x86_64 \
module-init-tools.x86_64 mx4j.noarch mysql-libs.x86_64 nc.x86_64 \
ncurses.x86_64 ncurses-base.x86_64 ncurses-libs.x86_64 net-tools.x86_64 \
netcf-libs.x86_64 newt.x86_64 newt-python.x86_64 nfs-utils.x86_64 \
nfs-utils-lib.x86_64 nspr.x86_64 nss.x86_64 nss-softokn.x86_64 \
nss-softokn-freebl.i686 nss-softokn-freebl.x86_64 nss-sysinit.x86_64 \
nss-tools.x86_64 nss-util.x86_64 ntp.x86_64 ntpdate.x86_64 numactl.x86_64 \
numad.x86_64 openldap.x86_64 openssh.x86_64 openssh-clients.x86_64 \
openssh-server.x86_64 openssl.x86_64 pam.x86_64 pango.x86_64 parted.x86_64 \
passwd.x86_64 pciutils.x86_64 pciutils-libs.x86_64 pcre.x86_64 perl.x86_64 \
perl-Config-General.noarch perl-Crypt-OpenSSL-Bignum.x86_64 \
perl-Crypt-OpenSSL-Random.x86_64 perl-Crypt-OpenSSL-RSA.x86_64 \
perl-libs.x86_64 perl-Module-Pluggable.x86_64 perl-Pod-Escapes.x86_64 \
perl-Pod-Simple.x86_64 perl-version.x86_64 pinentry.x86_64 pixman.x86_64 \
pkgconfig.x86_64 plymouth.x86_64 plymouth-core-libs.x86_64 \
plymouth-scripts.x86_64 pm-utils.x86_64 policycoreutils.x86_64 polkit.x86_64 \
popt.x86_64 postfix.x86_64 postgresql-libs.x86_64 postgresql91.x86_64 \
postgresql91-libs.x86_64 postgresql91-server.x86_64 prelink.x86_64 \
procps.x86_64 psmisc.x86_64 pth.x86_64 pulseaudio-libs.x86_64 pygpgme.x86_64 \
python.x86_64 python-boto.noarch python-ethtool.x86_64 python-eucadmin.noarch \
python-iniparse.noarch python-iwlib.x86_64 python-libs.x86_64 \
python-pycurl.x86_64 python-urlgrabber.noarch qemu-img.x86_64 qemu-kvm.x86_64 \
ql2100-firmware.noarch ql2200-firmware.noarch ql23xx-firmware.noarch \
ql2400-firmware.noarch ql2500-firmware.noarch radvd.x86_64 rampartc.x86_64 \
readline.x86_64 redhat-logos.noarch regexp.x86_64 rhino.noarch \
rootfiles.noarch rpcbind.x86_64 rpm.x86_64 rpm-libs.x86_64 rpm-python.x86_64 \
rsync.x86_64 rsyslog.x86_64 rt61pci-firmware.noarch rt73usb-firmware.noarch \
scsi-target-utils.x86_64 seabios.x86_64 sed.x86_64 selinux-policy.noarch \
selinux-policy-targeted.noarch setools.x86_64 setools-console.x86_64 \
setools-gui.x86_64 setools-libs.x86_64 setools-libs-tcl.x86_64 setup.noarch \
sg3_utils.x86_64 sg3_utils-libs.x86_64 sgabios-bin.noarch shadow-utils.x86_64 \
sinjdoc.x86_64 slang.x86_64 spice-server.x86_64 sqlite.x86_64 sudo.x86_64 \
sysfsutils.x86_64 system-config-network-tui.noarch sysvinit-tools.x86_64 \
tar.x86_64 tcl.x86_64 tcp_wrappers-libs.x86_64 tk.x86_64 \
tomcat6-servlet-2.5-api.noarch tzdata.noarch tzdata-java.noarch udev.x86_64 \
udftools.x86_64 unzip.x86_64 upstart.x86_64 usbredir.x86_64 usermode.x86_64 \
ustr.x86_64 util-linux-ng.x86_64 vblade.x86_64 vconfig.x86_64 velocity.noarch \
vgabios.noarch vim-minimal.x86_64 vtun.x86_64 werken-xpath.noarch wget.x86_64 \
which.x86_64 wireless-tools.x86_64 wsdl4j.noarch xalan-j2.noarch xinetd.x86_64 \
xml-common.noarch xml-commons-apis.x86_64 xml-commons-resolver.x86_64 \
xz.x86_64 xz-libs.x86_64 yajl.x86_64 yum.noarch yum-metadata-parser.x86_64 \
yum-plugin-fastestmirror.noarch zd1211-firmware.noarch zip.x86_64 zlib.x86_64"
  ;;
esac

# Download the base rpms
cd ${BUILDDIR}/image/CentOS
echo "$(date) - Retrieving packages"
yumdownloader ${RPMS} > /dev/null

# Download Eucalyptus release package
case "$EUCALYPTUSVERSION" in
"3.1")
  yumdownloader eucalyptus-release.noarch > /dev/null
  ;;
"nightly")
  yumdownloader eucalyptus-release-nightly.noarch > /dev/null
  ;;
esac

# Download rpms that vary according to Cent OS version
case "$ELVERSION" in
"5")
  yumdownloader drbd83-utils.x86_64 mx.x86_64 postgresql91-python26.x86_64 > /dev/null
  ;;
"6")
  yumdownloader PyGreSQL.x86_64 > /dev/null
  ;;
esac

