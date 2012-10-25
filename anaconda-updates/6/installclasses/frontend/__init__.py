#
# frontend.py
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

import silvereye
from constants import *
from pykickstart.constants import *
from product import *
from flags import flags
import os
import re
import shutil
import types

class InstallClass(silvereye.InstallClass):
    # name has underscore used for mnemonics, strip if you dont need it
    id = "silvereyefrontendparent"
    name = N_("Silvereye Eucalyptus Front End Installer Parent")
    _description = N_("The default installation of %s is a 'Cloud in a Box'"
                      "install. You can optionally select a different set of"
                      "software now.")
    _descriptionFields = (productName,)
    sortPriority = 10999

    hidden = 1

    bootloaderTimeoutDefault = 5
    bootloaderExtraArgs = ["crashkernel=auto"]

    tasks = [(N_("Eucalyptus Front-end Only"),
              ["core", "eucalyptus-cloud-controller",
               "eucalyptus-storage-controller", "eucalyptus-walrus",
               "eucalyptus-cluster-controller"]),
              ]
 
    def setGroupSelection(self, anaconda):
        silvereye.InstallClass.setGroupSelection(self, anaconda)
        map(lambda x: anaconda.backend.selectGroup(x),
                      ["core", "eucalyptus-cloud-controller",
                       "eucalyptus-storage-controller", "eucalyptus-walrus",
                       "eucalyptus-cluster-controller"])

    def setInstallData(self, anaconda):
        silvereye.InstallClass.setInstallData(self, anaconda)
        anaconda.id.security.setSELinux(SELINUX_PERMISSIVE)
        anaconda.id.firewall.portlist.extend([ '53:tcp',
                                               '53:udp',
                                               '67:udp',
                                               '3260:tcp',
                                               '8443:tcp',
                                               '8772:tcp',
                                               '8773:tcp',
                                               '8774:tcp'])

    def setSteps(self, anaconda):
        silvereye.InstallClass.setSteps(self, anaconda)

    def postAction(self, anaconda):
        silvereye.InstallClass.postAction(self, anaconda)
        # XXX: use proper constants for path names
        shutil.copyfile('/mnt/source/scripts/eucalyptus-frontend-config.sh',
                        '/mnt/sysimage/usr/local/sbin/eucalyptus-frontend-config.sh')
        os.chmod('/mnt/sysimage/usr/local/sbin/eucalyptus-frontend-config.sh', 0770)
        shutil.copyfile('/mnt/source/scripts/eucalyptus-create-emi.sh',
                        '/mnt/sysimage/usr/local/sbin/eucalyptus-create-emi.sh')
        os.chmod('/mnt/sysimage/usr/local/sbin/eucalyptus-create-emi.sh', 0770)
        postscriptlines ="""
# Set the default Eucalyptus networking mode
sed -i -e 's/^VNET_MODE=\"SYSTEM\"/VNET_MODE=\"MANAGED-NOVLAN"/' /etc/eucalyptus/eucalyptus.conf

# Disable Eucalyptus services before first boot
/sbin/chkconfig eucalyptus-cloud off
/sbin/chkconfig eucalyptus-cc off

# Create a backup copy of root's .bash_profile
/bin/cp -a /root/.bash_profile /root/.bash_profile.orig

# Create a backup of /etc/rc.d/rc.local
cp /etc/rc.d/rc.local /etc/rc.d/rc.local.orig
cat >> /etc/rc.d/rc.local <<"EOF"

# Add eucalyptus-frontend-config.sh script to root's .bash_profile, and have
# the original .bash_profile moved in on the first run
echo '/bin/cp -af /root/.bash_profile.orig /root/.bash_profile' >> /root/.bash_profile
echo '/usr/local/sbin/eucalyptus-frontend-config.sh' >> /root/.bash_profile

# Replace /etc/rc.d/rc.local with the original backup copy
rm -f /etc/rc.d/rc.local
cp /etc/rc.d/rc.local.orig /etc/rc.d/rc.local
EOF
"""
        postscript = AnacondaKSScript(postscriptlines,
                                      inChroot=True,
                                      logfile='/root/frontend-ks-post.log',
                                      type=KS_SCRIPT_POST)
        postscript.run(anaconda.rootPath, flags.serial, anaconda.intf)

    def __init__(self):
        silvereye.InstallClass.__init__(self)
