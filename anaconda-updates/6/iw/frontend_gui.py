#
# frontend_gui.py: gui config for Eucalyptus front end
#
# Copyright (C) 2012 Eucalyptus Systems, Inc.
# All rights reserved.
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

import gtk
import gobject
import string
import gui
from iw_gui import *
from flags import flags
from constants import *
import isys
import re
import network
import os
import urlgrabber.grabber
import struct
import socket
import dbus

import gettext
_ = lambda x: gettext.ldgettext("anaconda", x)

from system_config_eucalyptus.euca_gui import FrontendWindow
from system_config_eucalyptus.configfile import ConfigFile

class FrontendInstallWindow (InstallWindow, FrontendWindow):
    colocated_nc = 0

    def __init__(self, ics):
        InstallWindow.__init__(self, ics)
        FrontendWindow.__init__(self)

    def getScreen(self, anaconda):
        self.intf = anaconda.intf
        self.colocated_nc = getattr(anaconda.id.instClass, 'colocated_nc', 0)
        open('/tmp/eucalyptus.conf', 'w').close()
        euca_conf = ConfigFile('/tmp/eucalyptus.conf')
        roles = ['CLC', 'WS', 'SC', 'CC']
        if self.colocated_nc:
            roles.append('NC')

        self.validDevs = network.getActiveNetDevs()
        if not self.validDevs:
            self.intf.messageWindow(_("No Network Device"),
                                    _("Please go back and configure at least"
                                      " one network device to continue"),
                                    custom_icon="error",
                                    custom_buttons=[_("_Back")])

            anaconda.dispatch.gotoPrev()
            self.intf.icw.setScreen ()

        self.win = self.intf.icw.window

        return FrontendWindow.getScreen(self, euca_conf=euca_conf, roles=roles)

    def focus(self):
        self.pubnet.grab_focus()

    def validationError(self):
        self.pubnet.grab_focus()
        raise gui.StayOnScreen

    def getNext (self):
        euca_conf = FrontendWindow.getNext(self)
        if not euca_conf:
            self.validationError()
        anaconda = self.ics.getICW().anaconda

        # someday we may support Managed or System mode
        netmode = "MANAGED-NOVLAN"

        errors = []

        if not self.colocated_nc:
            privifcfg = anaconda.id.network.netdevices[euca_conf['VNET_PRIVINTERFACE']]
            privifcfg.set(("NOZEROCONF", "true"))

        if self.colocated_nc or netmode == "MANAGED":
            bridgeifcfg = network.NetworkDevice(network.netscriptsDir, "br0")
            bridgeifcfg.set(("TYPE", "Bridge"))
            bridgeifcfg.set(("DEVICE", "br0"))
            bridgeifcfg.set(("NM_CONTROLLED", "no"))
            bridgeifcfg.set(("DELAY", "0"))
            bridgeifcfg.set(("ONBOOT", "yes"))

            if self.colocated_nc:
                ncbridge = self.xml.get_widget('ncbridge').get_text()

                bridgeifcfg.set(("BOOTPROTO", "static"))
                bridgeifcfg.set(("IPADDR", ncbridge))
                # I don't think there's any need for more than one IP here
                bridgeifcfg.set(("NETMASK", "255.255.255.255"))
            elif netmode == "MANAGED":
                # connect the private interface to a bridge
                # XXX: this breaks network installs!
                privifcfg.set(("BRIDGE", "br0"))
                privifcfg.set(("NM_CONTROLLED", "no"))

                for attr in [ "BOOTPROTO", "IPADDR", "NETMASK" ]:  
                    value = privifcfg.get(attr)
                    bridgeifcfg.set((attr, value))
                    privifcfg.unset(attr)

            anaconda.id.network.netdevices["br0"] = bridgeifcfg
            bridgeifcfg.write()

        if not self.colocated_nc:
            privifcfg.write()
        
        euca_conf.save()

        return None
