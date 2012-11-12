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
import string
import gui
from iw_gui import *
from flags import flags
from constants import *
import _isys
import re
import network
import os

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
    def getScreen(self, anaconda):
        self.intf = anaconda.intf

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

        self.validDevs = network.getActiveNetDevs()
        if not self.validDevs:
            # TODO: raise a warning box?
            pass

        privif = config.get('VNET_PRIVINTERFACE', '')
        if privif and privif in self.validDevs:
            self.privif.set_text(privif)
        else:
            self.privif.set_text(self.validDevs[0])

        pubif = config.get('VNET_PUBINTERFACE', '')
        if pubif and pubif in self.validDevs:
            self.pubif.set_text(pubif)
        else:
            self.pubif.set_text(self.validDevs[0])

        ns = config.get('VNET_DNS', '')
        if ns:
            self.privdns.set_text(ns)
        else:
            nameservers = [ x.strip().split()[1] for x in \
                            open('/etc/resolv.conf').readlines() if \
                            x.startswith('nameserver') ]
            self.privdns.set_text(' '.join(nameservers))

        self.addrspernet.set_text(config.get('VNET_ADDRSPERNET', ''))
        self.privnet.set_text(config.get('VNET_SUBNET', ''))
        self.privmask.set_text(config.get('VNET_NETMASK', ''))
        self.pubnet.set_text(config.get('VNET_PUBLICIPS', ''))

        # load the icon
        gui.readImageFromFile("eucalyptus-E.png", image=self.icon)

        # connect hotkeys
        """
        self.pw.set_text_with_mnemonic(_("Root _Password:"))
        self.pwlabel.set_mnemonic_widget(self.pw)
        self.confirmlabel.set_text_with_mnemonic(_("_Confirm:"))
        self.confirmlabel.set_mnemonic_widget(self.confirm)
        """

        # pressing Enter in Pub Net == clicking Next
        vbox = self.xml.get_widget("frontend_box")
        self.pubnet.connect("activate", lambda widget,
                             vbox=vbox: self.ics.setGrabNext(1))

        return self.align

    def focus(self):
        self.privnet.grab_focus()

    def validationError(self):
        self.privnet.set_text("")
        self.pubnet.set_text("")
        self.privnet.grab_focus()
        raise gui.StayOnScreen

    def getNext (self):
        anaconda = self.ics.getICW().anaconda

        privif = self.privif.get_text()
        privnet = self.privnet.get_text()
        privmask = self.privmask.get_text()
        pubif = self.pubif.get_text()
        pubnet = self.pubnet.get_text()
        addrspernet = self.addrspernet.get_text()
        privdns = self.privdns.get_text()

        errors = []

        if not privif in self.validDevs:
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

        if privnet and privmask:
            try:
                checkSubnet(privnet, privmask)
            except Exception, e:
                errors.append(repr(e))

        if not privmask:
            errors.append('Private netmask must be set.')
        if not addrspernet:
            errors.append('Addrs per new must be set.')
        if privmask and addrspernet and getSubnetSize(privmask) < int(addrspernet):
            errors.append("Addrs per net must be smaller than private network size.")

        if addrspernet and not re.match(r'^0b10*$', bin(int(addrspernet))):
            errors.append("Addrs per net must be an integer power of two.")

        if len(errors):
            self.intf.messageWindow(_("Error with Configuration"),
                                    _(" ".join(errors)),
                                    custom_icon="error")
            self.validationError()

        # convert to long ugly names
        # NOTE: We are hard-coding network mode
        config = {
                   "VNET_PRIVINTERFACE": "br0",
                   "VNET_SUBNET": privnet,
                   "VNET_NETMASK": privmask,
                   "VNET_DNS": privdns,
                   "VNET_PUBINTERFACE": pubif,
                   "VNET_PUBLICIPS": pubnet,
                   "VNET_ADDRSPERNET": addrspernet,
                   "VNET_MODE": "MANAGED-NOVLAN",
                   "CREATE_SC_LOOP_DEVICES": "256",
                 }
        eucaConf = open('/tmp/eucalyptus.conf', 'w')
        eucaConf.write("\n".join([ '%s="%s"' % (x, config[x]) for x in config.keys() ]))
        eucaConf.close()

        # connect the private interface to a bridge
        privifcfg = anaconda.id.network.netdevices[privif]
        privifcfg.set(("NM_CONTROLLED", "no"))
        privifcfg.set(("BRIDGE", "br0"))
        privifcfg.set(("NOZEROCONF", "true"))

        bridgeifcfg = network.NetworkDevice(network.netscriptsDir, "br0")
        bridgeifcfg.set(("TYPE", "Bridge"))
        bridgeifcfg.set(("DEVICE", "br0"))
        bridgeifcfg.set(("NM_CONTROLLED", "no"))

        for attr in [ "BOOTPROTO", "IPADDR", "NETMASK" ]:  
           value = privifcfg.get(attr)
           bridgeifcfg.set((attr, value))
           privifcfg.unset(attr)

        anaconda.id.network.netdevices["br0"] = bridgeifcfg
        bridgeifcfg.write()
        
        return None
