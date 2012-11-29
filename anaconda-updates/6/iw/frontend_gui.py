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
import _isys
import re
import network
import os
import urlgrabber.grabber

import gettext
_ = lambda x: gettext.ldgettext("anaconda", x)

def getSubnetSize(mask):
    maskcomp = 0
    for octet in mask.split('.'):
        maskcomp = (maskcomp<<8)+255-int(octet)
    return maskcomp

def checkSubnet(net, mask):
    netsum = 0
    for octet in net.split('.'):
        netsum = (netsum<<8)+int(octet)
    maskcomp = getSubnetSize(mask)
    if netsum & maskcomp > 0:
        raise Exception("Invalid netmask for private network")
    else:
        return

class FrontendWindow (InstallWindow):
    colocated_nc = 0

    def getScreen(self, anaconda):
        self.intf = anaconda.intf
        self.colocated_nc = getattr(anaconda.id.instClass, 'colocated_nc', 0)

        config = dict()
        configLineRE = re.compile(r'''\s*(\w+)\s*=\s*((['"])(.*)\3)''')
        if os.path.exists('/tmp/eucalyptus.conf'):
            for line in open('/tmp/eucalyptus.conf', 'r').readlines():
                if line.startswith('#'):
                    continue
                tokens = configLineRE.match(line.strip()).groups()
                config[tokens[0]] = tokens[3]

        (self.xml, self.align) = gui.getGladeWidget("frontend.glade",
                                                    "frontend_align")
        self.icon = self.xml.get_widget("icon")
        self.priviflabel = self.xml.get_widget("priviflabel")
        self.privif = self.xml.get_widget("privif")
        self.privnetlabel = self.xml.get_widget("privnetlabel")
        self.privnet = self.xml.get_widget("privnet")
        self.privmasklabel = self.xml.get_widget("privmasklabel")
        self.privmask = self.xml.get_widget("privmask")
        self.pubiflabel = self.xml.get_widget("pubiflabel")
        self.pubif = self.xml.get_widget("pubif")
        self.pubnetlabel = self.xml.get_widget("pubnetlabel")
        self.pubnet = self.xml.get_widget("pubnet")
        self.addrspernetlabel = self.xml.get_widget("addrspernetlabel")
        self.addrspernet = self.xml.get_widget("addrspernet")
        self.privdnslabel = self.xml.get_widget("privdnslabel")
        self.privdns = self.xml.get_widget("privdns")
        self.ncbridgelabel = self.xml.get_widget("ncbridgelabel")
        self.ncbridge = self.xml.get_widget("ncbridge")

        self.validDevs = network.getActiveNetDevs()
        if not self.validDevs:
            self.intf.messageWindow(_("No Network Device"),
                                    _("Please go back and configure at least"
                                      " one network device to continue"),
                                    custom_icon="error",
                                    custom_buttons=[_("_Back")])

            self.anaconda.dispatch.gotoPrev()
            self.icw.setScreen ()

        privif = config.get('VNET_PRIVINTERFACE', '')
        '''
        if self.colocated_nc:
            self.privif.set_text("br0")
            self.privif.set_editable(False)
        else:
            if privif and privif in self.validDevs:
                self.privif.set_text(privif)
            else:
                 self.privif.set_text(self.validDevs[0])
        '''
        cell = gtk.CellRendererText()
        self.privif.set_model(gtk.ListStore(gobject.TYPE_STRING))
        self.privif.pack_start(cell)
        self.privif.add_attribute(cell, 'text', 0)
        if self.colocated_nc:
            self.privif.append_text('br0')
            self.ncbridge.set_text('172.31.252.1')
        else:
            # TODO: preserve privif selection if it existed
            self.ncbridge.set_editable(False)
            for interface in self.validDevs:
                self.privif.append_text(interface)
        self.privif.set_active(0)

        cell = gtk.CellRendererText()
        self.pubif.set_model(gtk.ListStore(gobject.TYPE_STRING))
        self.pubif.pack_start(cell)
        self.pubif.add_attribute(cell, 'text', 0)
        for interface in self.validDevs:
            self.pubif.append_text(interface)
        self.pubif.set_active(0)

        ns = config.get('VNET_DNS', '')
        if ns:
            self.privdns.set_text(ns)
        else:
            nameservers = [ x.strip().split()[1] for x in \
                            open('/etc/resolv.conf').readlines() if \
                            x.startswith('nameserver') ]
            self.privdns.set_text(' '.join(nameservers))

        '''
        self.addrspernet.set_text(config.get('VNET_ADDRSPERNET', ''))
        '''
        self.addrspernet.set_active(1)

        # Set default values for private net
        self.privnet.set_text(config.get('VNET_SUBNET', '172.31.254.0'))
        self.privmask.set_text(config.get('VNET_NETMASK', '255.255.254.0'))
        self.pubnet.set_text(config.get('VNET_PUBLICIPS', ''))

        # load the icon
        gui.readImageFromFile("vendor-icon.png", image=self.icon)

        # pressing Enter in Pub Net == clicking Next
        # vbox = self.xml.get_widget("frontend_box")
        # self.pubnet.connect("activate", lambda widget,
        #                      vbox=vbox: self.ics.setGrabNext(1))

        return self.align

    def focus(self):
        self.privnet.grab_focus()

    def validationError(self):
        self.privnet.grab_focus()
        raise gui.StayOnScreen

    def getNext (self):
        anaconda = self.ics.getICW().anaconda

        privif = self.privif.get_model()[self.privif.get_active()][0]
        privnet = self.privnet.get_text()
        privmask = self.privmask.get_text()
        pubif = self.pubif.get_model()[self.pubif.get_active()][0]
        pubnet = self.pubnet.get_text()
        addrspernet = self.addrspernet.get_model()[self.addrspernet.get_active()][0]
        privdns = self.privdns.get_text()
        ncbridge = self.ncbridge.get_text()
        # someday we may support Managed or System mode
        netmode = "MANAGED-NOVLAN"

        errors = []

        if not self.colocated_nc and not privif in self.validDevs:
            errors.append("Private interface %s is not a valid device" % privif)
        if not pubif in self.validDevs:
            errors.append("Public interface %s is not a valid device" % pubif)

        try:
            network.sanityCheckIPString(privnet) 
            network.sanityCheckIPString(privmask)

            nameservers = privdns.split()
            for n in nameservers:
                network.sanityCheckIPString(n)

            if pubnet.find('-') == -1:
                pubips = pubnet.split()
                for ip in pubips:
                     network.sanityCheckIPString(ip)
            else:
                start, end = pubnet.split('-')
                network.sanityCheckIPString(start)
                network.sanityCheckIPString(end)
        except network.IPError, e:
            errors.append(e.message)
        except network.IPMissing, e:
            errors.append(e.message)

        if self.colocated_nc:
            try:
                network.sanityCheckIPString(ncbridge)
            except network.IPError, e:
                errors.append(e.message)
            except network.IPMissing, e:
                errors.append(e.message)

        if privnet and privmask:
            try:
                checkSubnet(privnet, privmask)
            except Exception, e:
                errors.append(repr(e))

        if not privmask:
            errors.append('Private netmask must be set.')
        if not addrspernet:
            errors.append('Addrs per net must be set.')
        try:
            if privmask and addrspernet and getSubnetSize(privmask) < int(addrspernet):
                errors.append("Addrs per net must be smaller than private network size.")

            if addrspernet and not re.match(r'^0b10*$', bin(int(addrspernet))):
                errors.append("Addrs per net must be an integer power of two.")
        except ValueError:
            errors.append('Addrs per net must be an integer')

        if len(errors):
            self.intf.messageWindow(_("Error with Configuration"),
                                    _(" ".join(errors)),
                                    custom_icon="error")
            self.validationError()

        # convert to long ugly names
        config = {
                   "VNET_PRIVINTERFACE": privif,
                   "VNET_SUBNET": privnet,
                   "VNET_NETMASK": privmask,
                   "VNET_DNS": privdns,
                   "VNET_PUBINTERFACE": pubif,
                   "VNET_PUBLICIPS": pubnet,
                   "VNET_ADDRSPERNET": addrspernet,
                   "VNET_MODE": netmode,
                   "CREATE_SC_LOOP_DEVICES": "256",
                 }

        privifcfg = anaconda.id.network.netdevices[privif]
        privifcfg.set(("NM_CONTROLLED", "no"))
        privifcfg.set(("NOZEROCONF", "true"))

        if self.colocated_nc or netmode == "MANAGED":
            config["VNET_PRIVINTERFACE"] = "br0"
            bridgeifcfg = network.NetworkDevice(network.netscriptsDir, "br0")
            bridgeifcfg.set(("TYPE", "Bridge"))
            bridgeifcfg.set(("DEVICE", "br0"))
            bridgeifcfg.set(("NM_CONTROLLED", "no"))
            bridgeifcfg.set(("DELAY", "0"))
            bridgeifcfg.set(("ONBOOT", "yes"))

            if self.colocated_nc:
                bridgeifcfg.set(("BOOTPROTO", "static"))
                bridgeifcfg.set(("IPADDR", ncbridge))
                # I don't think there's any need for more than one IP here
                bridgeifcfg.set(("NETMASK", "255.255.255.255"))
            elif netmode == "MANAGED":
                # connect the private interface to a bridge
                privifcfg.set(("BRIDGE", "br0"))

                for attr in [ "BOOTPROTO", "IPADDR", "NETMASK" ]:  
                    value = privifcfg.get(attr)
                    bridgeifcfg.set((attr, value))
                    privifcfg.unset(attr)

            anaconda.id.network.netdevices["br0"] = bridgeifcfg
            bridgeifcfg.write()

        privifcfg.write()
        
        eucaConf = open('/tmp/eucalyptus.conf', 'w')
        eucaConf.write("\n".join([ '%s="%s"' % (x, config[x]) for x in config.keys() ]))
        eucaConf.close()

        return None
