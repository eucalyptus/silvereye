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

import frontend
from constants import *
from product import *
from flags import flags
import os
import re
import shutil
import types

class InstallClass(frontend.InstallClass):
    # name has underscore used for mnemonics, strip if you dont need it
    id = "silvereyefrontendonly"
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
 
    def postAction(self, anaconda):
        frontend.InstallClass.postAction(self, anaconda):
        shutil.copyfile('/tmp/updates/scripts/eucalyptus-firstboot-nodereg.py',
                        '/mnt/sysimage/usr/share/firstboot/modules/eucalyptus-firstboot-nodereg.py')

