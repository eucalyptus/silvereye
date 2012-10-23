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
    name = N_("Silvereye Eucalyptus Front End Installer")
    _description = N_("The default installation of %s is a 'Cloud in a Box'"
                      "install. You can optionally select a different set of"
                      "software now.")
    _descriptionFields = (productName,)
    sortPriority = 10999

    if flags.cmdline.has_key('frontend'):
      hidden = 0
    else:
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

    def __init__(self):
        silvereye.InstallClass.__init__(self)
