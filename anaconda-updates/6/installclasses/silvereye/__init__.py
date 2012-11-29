#
# silverye.py
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

import installclass
from constants import *
from pykickstart.constants import *
from product import *
from flags import flags
import iutil
import os
import re
import types
from kickstart import AnacondaKSScript
from storage.partspec import *

import installmethod
import yuminstall

class InstallClass(installclass.BaseInstallClass):
    # name has underscore used for mnemonics, strip if you dont need it
    id = "silvereye"
    name = N_("Silvereye Eucalyptus Installer")
    _description = N_("The default installation of %s is a 'Cloud in a Box'"
                      "install. You can optionally select a different set of"
                      "software now.")
    _descriptionFields = (productName,)
    sortPriority = 100
    hidden = 1

    bootloaderTimeoutDefault = 5
    bootloaderExtraArgs = ["crashkernel=auto"]
    colocated_nc = 0

    tasks = [(N_("Eucalyptus Cloud in a Box"),
              ["core", "eucalyptus-cloud-controller",
               "eucalyptus-storage-controller", "eucalyptus-walrus",
               "eucalyptus-cluster-controller", "eucalyptus-node-controller"]),
             (N_("Eucalyptus Front-end Only"),
              ["core", "eucalyptus-cloud-controller",
               "eucalyptus-storage-controller", "eucalyptus-walrus",
               "eucalyptus-cluster-controller"]),
             (N_("Eucalyptus Node Controller Only"),
              ["core", "eucalyptus-node-controller"]),
             (N_("Minimal"),
              ["core"])]
 
    def setGroupSelection(self, anaconda):
        for pkg in [ 'epel-release', 'elrepo-release',
                     'euca2ools-release', 'eucalyptus-release',
                     'ntp', 'tcpdump', 'strace' ]:
            anaconda.backend.selectPackage(pkg)

    def setInstallData(self, anaconda):
        installclass.BaseInstallClass.setInstallData(self, anaconda)
        anaconda.id.simpleFilter = True
        self.setDefaultPartitioning(anaconda.id.storage,
                                    anaconda.platform)
        anaconda.id.security.setSELinux(SELINUX_PERMISSIVE)

    def setDefaultPartitioning(self, storage, platform):
        autorequests = [PartSpec(mountpoint="/", fstype=storage.defaultFSType,
                                 size=10240, grow=True, asVol=False, requiredSpace=20*1024)]

        bootreq = platform.setDefaultPartitioning()
        if bootreq:
            autorequests.extend(bootreq)

        (minswap, maxswap) = iutil.swapSuggestion()
        autorequests.append(PartSpec(fstype="swap", size=minswap, maxSize=maxswap,
                                     grow=True, asVol=False))

        storage.autoPartitionRequests = autorequests

    def setSteps(self, anaconda):
        installclass.BaseInstallClass.setSteps(self, anaconda)
        # Unskip memcheck
        anaconda.dispatch.skipStep("memcheck", skip = 0)
        anaconda.dispatch.skipStep("protectstorage", skip = 0)
        anaconda.dispatch.skipStep("tasksel",permanent=1)
        anaconda.dispatch.skipStep("firewall")
        anaconda.dispatch.skipStep("group-selection")
        anaconda.dispatch.skipStep("filtertype")
        anaconda.dispatch.skipStep("filter")
        anaconda.dispatch.skipStep("partition")
        # anaconda.dispatch.skipStep("parttype")

    def getBackend(self):
        if flags.livecdInstall:
            import livecd
            return livecd.LiveCDCopyBackend
        else:
            return yuminstall.YumBackend

    def postAction(self, anaconda):
        installclass.BaseInstallClass.postAction(self, anaconda)

        postscriptlines ="""
if [ -e /etc/libvirt/qemu/networks/autostart/default.xml ]; then
  rm -f /etc/libvirt/qemu/networks/autostart/default.xml
fi
"""
        postscript = AnacondaKSScript(postscriptlines,
                                      inChroot=True,
                                      logfile='/root/euca-common-ks-post.log',
                                      type=KS_SCRIPT_POST)
        postscript.run(anaconda.rootPath, flags.serial, anaconda.intf)


    def __init__(self):
        installclass.BaseInstallClass.__init__(self)
