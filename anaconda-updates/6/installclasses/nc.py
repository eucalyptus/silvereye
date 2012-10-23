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
import re
import types

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
        map(lambda x: anaconda.backend.selectGroup(x),
                      ["core", "eucalyptus-node-controller"])

    def setInstallData(self, anaconda):
        silvereye.InstallClass.setInstallData(self, anaconda)
        anaconda.id.firewall.portlist.extend([ '8775:tcp'])

    def setSteps(self, anaconda):
        silvereye.InstallClass.setSteps(self, anaconda)

    def __init__(self):
        silvereye.InstallClass.__init__(self)
