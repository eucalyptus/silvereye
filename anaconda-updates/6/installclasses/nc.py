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
from product import *
from flags import flags
import os
import shutil
import re
import types
from kickstart import AnacondaKSScript 

class InstallClass(silvereye.InstallClass):
    # name has underscore used for mnemonics, strip if you dont need it
    id = "silvereyefrontend"
    name = N_("Silvereye Eucalyptus Noce Controller Installer")
    _description = N_("The default installation installs a Node Controller")
    _descriptionFields = (productName,)
    sortPriority = 10999

    if flags.cmdline.has_key('nc'):
      hidden = 0
    else:
      hidden = 1

    bootloaderTimeoutDefault = 5
    bootloaderExtraArgs = ["crashkernel=auto"]

    tasks = [(N_("Eucalyptus Node Controller"),
              ["core", "eucalyptus-node-controller"]) ]
 
    def setGroupSelection(self, anaconda):
        silvereye.InstallClass.setGroupSelection(self, anaconda)
        anaconda.backend.selectGroup("core")
        anaconda.backend.selectPackage("eucalyptus-nc")

    def setInstallData(self, anaconda):
        silvereye.InstallClass.setInstallData(self, anaconda)
        anaconda.id.firewall.portlist.extend([ '8775:tcp'])

    def setSteps(self, anaconda):
        silvereye.InstallClass.setSteps(self, anaconda)
        anaconda.dispatch.skipStep("vtcheck", skip = 0)

    def postAction(self, anaconda):
        silvereye.InstallClass.postAction(self, anaconda)
        # XXX: use proper constants for path names
        shutil.copyfile('/tmp/updates/scripts/eucalyptus-nc-config.sh',
                        '/mnt/sysimage/usr/local/sbin/eucalyptus-nc-config.sh')
        os.chmod('/mnt/sysimage/usr/local/sbin/eucalyptus-nc-config.sh', 0770)
        postscriptlines = """
# Set the default Eucalyptus networking mode
sed -i -e 's/^VNET_MODE=\"SYSTEM\"/VNET_MODE=\"MANAGED-NOVLAN"/' /etc/eucalyptus/eucalyptus.conf

# Disable Eucalyptus services before first boot
/sbin/chkconfig eucalyptus-nc off

# Create a backup copy of root's .bash_profile
/bin/cp -a /root/.bash_profile /root/.bash_profile.orig

# Create a backup of /etc/rc.d/rc.local
cp /etc/rc.d/rc.local /etc/rc.d/rc.local.orig
cat >> /etc/rc.d/rc.local <<"EOF"

# Add eucalyptus-nc-config.sh script to root's .bash_profile, and have the
# original .bash_profile moved in on the first run
echo '/bin/cp -af /root/.bash_profile.orig /root/.bash_profile' >> /root/.bash_profile
echo '/usr/local/sbin/eucalyptus-nc-config.sh' >> /root/.bash_profile

# Replace /etc/rc.d/rc.local with the original backup copy
rm -f /etc/rc.d/rc.local
cp /etc/rc.d/rc.local.orig /etc/rc.d/rc.local
EOF
"""
        postscript = AnacondaKSScript(postscriptlines,
                                      inChroot=True,
                                      logfile='/root/nc-ks-post.log',
                                      type=KS_SCRIPT_POST)
        postscript.run(anaconda.rootPath, flags.serial, anaconda.intf)

    def __init__(self):
        silvereye.InstallClass.__init__(self)
