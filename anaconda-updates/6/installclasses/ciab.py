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

import frontend
from constants import *
from product import *
from flags import flags
import os
import re
import types
import iutil

class InstallClass(frontend.InstallClass):
    # name has underscore used for mnemonics, strip if you dont need it
    id = "cloudinabox"
    name = N_("Silvereye Eucalyptus Cloud-in-a-box Installer")
    _description = N_("The default installation of %s is a 'Cloud in a Box'"
                      "install. You can optionally select a different set of"
                      "software now.")
    _descriptionFields = (productName,)
    sortPriority = 10099
    if flags.cmdline.has_key('ciab'):
      hidden = 0
    else:
      hidden = 1

    bootloaderTimeoutDefault = 5
    bootloaderExtraArgs = ["crashkernel=auto"]

    tasks = [(N_("Eucalyptus Cloud in a Box"),
              ["core", "eucalyptus-cloud-controller",
               "eucalyptus-storage-controller", "eucalyptus-walrus",
               "eucalyptus-cluster-controller", "eucalyptus-node-controller"]),
              ]
 
    def setGroupSelection(self, anaconda):
        frontend.InstallClass.setGroupSelection(self, anaconda)
        anaconda.backend.selectGroup("eucalyptus-node-controller")

    def setInstallData(self, anaconda):
        frontend.InstallClass.setInstallData(self, anaconda)
        anaconda.id.firewall.portlist.extend([ '8775:tcp' ])

    def setSteps(self, anaconda):
        frontend.InstallClass.setSteps(self, anaconda)
        anaconda.dispatch.skipStep("vtcheck", skip = 0)

    def postAction(self, anaconda):
        frontend.InstallClass.postAction(self, anaconda)
        messages = "/dev/null"
        iutil.execWithRedirect("/sbin/chkconfig", ["eucalyptus-nc", "off" ],
                                    stdin = messages, stdout = messages, stderr = messages,
                                    root = anaconda.rootPath)
 
    def __init__(self):
        frontend.InstallClass.__init__(self)
