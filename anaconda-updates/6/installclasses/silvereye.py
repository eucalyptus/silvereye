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

from installclass import BaseInstallClass
from constants import *
from product import *
from flags import flags
import os
import re
import types

import installmethod
import yuminstall

class InstallClass(BaseInstallClass):
    # name has underscore used for mnemonics, strip if you dont need it
    id = "silvereye"
    name = N_("Silvereye Eucalyptus Installer")
    _description = N_("The default installation of %s is a 'Cloud in a Box'"
                      "install. You can optionally select a different set of"
                      "software now.")
    _descriptionFields = (productName,)
    sortPriority = 10099
    hidden = 0

    bootloaderTimeoutDefault = 5
    bootloaderExtraArgs = ["crashkernel=auto"]

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
 
    def getPackagePaths(self, uri):
        if not type(uri) == types.ListType:
            uri = [uri,]

        return {productName: uri}

    def setInstallData(self, anaconda):
        BaseInstallClass.setInstallData(self, anaconda)
        BaseInstallClass.setDefaultPartitioning(self,
                                                anaconda.id.storage,
                                                anaconda.platform)

    def setSteps(self, anaconda):
        BaseInstallClass.setSteps(self, anaconda)
        # Unskip memcheck
        anaconda.dispatch.skipStep("memcheck", skip = 0)
        anaconda.dispatch.skipStep("betanag",permanent=1)

    def getBackend(self):
        if flags.livecdInstall:
            import livecd
            return livecd.LiveCDCopyBackend
        else:
            return yuminstall.YumBackend

    def __init__(self):
        BaseInstallClass.__init__(self)
