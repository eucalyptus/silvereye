#
# network_gui.py: Network configuration dialog
#
# Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005, 2006,  Red Hat, Inc.
#               2007, 2008, 2009
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
# Author(s): Michael Fulbright <msf@redhat.com>
#            David Cantrell <dcantrell@redhat.com>
#

import string
from iw_gui import *
import gui
import network
import iutil
import gobject
import subprocess
import gtk
import isys
import urlgrabber.grabber
import socket, struct

from constants import *
import gettext
_ = lambda x: gettext.ldgettext("anaconda", x)

def netmask2prefix(netmask):
    nmInt = struct.unpack("!L", socket.inet_aton(netmask))[0]
    prefix = 32
    while prefix > 0:
        if nmInt & 1:
            break
        nmInt >>= 1
        prefix -= 1
    return prefix

class NetworkWindow(InstallWindow):
    def getScreen(self, anaconda):
        self.intf = anaconda.intf
        self.anaconda = anaconda
        self.hostname = network.getDefaultHostname(anaconda)

        # load the UI
        (self.xml, self.align) = gui.getGladeWidget("network.glade",
                                                    "network_align")
        self.icon = self.xml.get_widget("icon")
        self.hostnameEntry = self.xml.get_widget("hostnameEntry")
        self.hostnameEntry.set_text(self.hostname)

        self.netconfButton = self.xml.get_widget("netconfButton")
        self.netconfButton.connect("clicked", self._netconfButton_clicked)
        if len(self.anaconda.id.network.netdevices) == 0:
            self.netconfButton.set_sensitive(False)

        # pressing Enter in confirm == clicking Next
        self.hostnameEntry.connect("activate",
                                   lambda w: self.ics.setGrabNext(1))

        self.netifCombo = self.xml.get_widget("netifcombo")
        cell = gtk.CellRendererText()
        self.ipaddr = self.xml.get_widget("ipaddr")
        self.netmask = self.xml.get_widget("netmask")
        self.defaultgw = self.xml.get_widget("defaultgw")
        self.netifCombo.set_model(gtk.ListStore(gobject.TYPE_STRING))
        self.netifCombo.pack_start(cell)
        self.netifCombo.add_attribute(cell, 'text', 0)
        for dev in anaconda.id.network.netdevices.keys():
            self.netifCombo.append_text(dev)
        self.netifCombo.set_active(0)
        self.netifCombo.connect("changed", self._netifCombo_changed)
        self.dhcpCombo = self.xml.get_widget("dhcpcombo")
        self.dhcpCombo.connect("changed", self._dhcpCombo_changed)

        self.dnsserver = self.xml.get_widget("dnsserver")

        # load current network settings
        self._netifCombo_changed()

        # Only reset to Static mode when we are going forward.
        # A little hacky, but good enough for now.
        if anaconda.dir == DISPATCH_FORWARD:
            self.dhcpCombo.set_active(0)
            self._dhcpCombo_changed()
 
        # load the icon
        gui.readImageFromFile("network.png", image=self.icon)

        return self.align

    def _dhcpCombo_changed(self, *args):
        val = self.dhcpCombo.get_model()[self.dhcpCombo.get_active()][0]
        editable = True
        if val == "DHCP":
            editable = False
        for widget in [ self.ipaddr, self.netmask, self.defaultgw ]:
            widget.set_editable(editable)
            widget.set_sensitive(editable)

    def _netifCombo_changed(self, *args):
        val = self.netifCombo.get_model()[self.netifCombo.get_active()][0]
        dev = self.anaconda.id.network.netdevices[val]
        if dev.get('BOOTPROTO') in ["static", "none"]:
            self.dhcpCombo.set_active(0)
            self.ipaddr.set_text(dev.get("IPADDR"))
            netmask = dev.get("NETMASK")
            if not netmask:
                prefix = dev.get("PREFIX")
                if prefix:
                    netmask = socket.inet_ntoa(struct.pack("<L", ((1L<<int(prefix))-1)))

            self.netmask.set_text(netmask)
            self.defaultgw.set_text(dev.get("GATEWAY"))
            dnsservers = []
            i = 1
            while True:
                server = dev.get("DNS%d" % i)
                if server:
                    dnsservers.append(server)
                else:
                    break
                i += 1
            self.dnsserver.set_text(",".join(dnsservers))
        else:
            self.dhcpCombo.set_active(1)
            self.ipaddr.set_text("")
            self.netmask.set_text("")
            self.defaultgw.set_text("")
            self.dnsserver.set_text("")
        self._dhcpCombo_changed()

    def _netconfButton_clicked(self, *args):
        setupNetwork(self.intf)
        self._netifCombo_changed(self, *args)

    def focus(self):
        self.hostnameEntry.grab_focus()

    def hostnameError(self):
        self.hostnameEntry.grab_focus()
        raise gui.StayOnScreen

    def getNext(self):
        hostname = string.strip(self.hostnameEntry.get_text())
        herrors = network.sanityCheckHostname(hostname)

        if not hostname:
            self.intf.messageWindow(_("Error with Hostname"),
                                    _("You must enter a valid hostname for this "
                                      "computer."), custom_icon="error")
            self.hostnameError()

        if herrors is not None:
            self.intf.messageWindow(_("Error with Hostname"),
                                    _("The hostname \"%(hostname)s\" is not "
                                      "valid for the following reason:\n\n"
                                      "%(herrors)s")
                                    % {'hostname': hostname,
                                       'herrors': herrors},
                                    custom_icon="error")
            self.hostnameError()

        netif = self.netifCombo.get_model()[self.netifCombo.get_active()][0]
        mode  = self.dhcpCombo.get_model()[self.dhcpCombo.get_active()][0]
        ipaddr = ''
        netmask = ''
        defaultgw = ''
        errors = []
        if mode == "Static":
            ipaddr = self.ipaddr.get_text()
            try:
                network.sanityCheckIPString(ipaddr)
            except network.IPError, e:
                errors.append(e.message)
            except network.IPMissing, e:
                errors.append(e.message)

            netmask = self.netmask.get_text()
            try:
                network.sanityCheckIPString(netmask)
            except network.IPError, e:
                errors.append(e.message)
            except network.IPMissing, e:
                errors.append(e.message)

            defaultgw = self.defaultgw.get_text()
            try:
                network.sanityCheckIPString(defaultgw)
            except network.IPError, e:
                errors.append(e.message)
            except network.IPMissing, e:
                errors.append(e.message)

        if len(errors):
            self.intf.messageWindow(_("Error with Network Configuration"),
                                    _("The network configuration is not "
                                      "valid for the following reason(s):\n\n"
                                      "%s")
                                    % "\n".join(errors),
                                    custom_icon="error")
            raise gui.StayOnScreen

        if mode == "DHCP":
            rc = self.intf.messageWindow(_("Dynamic IP Warning"),
                                    _("You have selected DHCP mode for "
                                      "your primary interface.  Note that "
                                      "you *must* have a static DHCP "
                                      "reservation for this to work.  IP "
                                      "address changes after installation "
                                      "are completely unsupported\n"),
                                      type="custom",
                                      custom_icon="warning",
                                      custom_buttons=[_("_Back"), _("_Continue")])
            if not rc:
                raise gui.StayOnScreen

        dnsservers = []
        [ dnsservers.extend(x.split()) for x in self.dnsserver.get_text().split(",") ]
        for server in dnsservers:
            try:
                network.sanityCheckIPString(server)
            except network.IPError, e:
                errors.append(e.message)
            except network.IPMissing, e:
                errors.append(e.message)
            
        self.anaconda.id.network.setHostname(hostname)
        dev = self.anaconda.id.network.netdevices[netif]
        dev.set(("BOOTPROTO", mode.lower()))
        if mode == "Static":
            dev.set(("IPADDR", ipaddr))
            dev.set(("NETMASK", netmask))
            dev.set(("GATEWAY", defaultgw))
            dev.set(("PREFIX", str(netmask2prefix(netmask))))
        else:
            dev.unset("IPADDR")
            dev.unset("NETMASK")
            dev.unset("GATEWAY")
            dev.unset("PREFIX")
        dev.set(('ONBOOT', 'yes'))

        self.anaconda.id.network.setDNS(','.join(dnsservers), netif)

        w = self.anaconda.intf.waitWindow(_("Configuring Network Interfaces"), _("Waiting for NetworkManager"))
        result = self.anaconda.id.network.bringUp()
        w.pop()
        if not result:
            self.anaconda.intf.messageWindow(_("Network Error"),
                                             _("There was an error configuring "
                                               "network device %s") % dev.get('DEVICE'))
            raise gui.StayOnScreen

        return None

def setupNetwork(intf):
    intf.enableNetwork(just_setup=True)
    if network.hasActiveNetDev():
        urlgrabber.grabber.reset_curl_obj()

def NMCEExited(pid, condition, anaconda):
    if anaconda:
        anaconda.intf.icw.window.set_sensitive(True)

# TODORV: get rid of setting sensitive completely?
def runNMCE(anaconda=None, blocking=True):
    if not blocking and anaconda:
        anaconda.intf.icw.window.set_sensitive(False)
    cmd = ["/usr/bin/nm-connection-editor"]
    out = open("/dev/tty5", "w")
    try:
        proc = subprocess.Popen(cmd, stdout=out, stderr=out)
    except Exception as e:
        if not blocking and anaconda:
            anaconda.intf.icw.window.set_sensitive(True)
        import logging
        log = logging.getLogger("anaconda")
        log.error("Could not start nm-connection-editor: %s" % e)
        return None
    else:
        if blocking:
            proc.wait()
        else:
            gobject.child_watch_add(proc.pid, NMCEExited, data=anaconda, priority=gobject.PRIORITY_DEFAULT)


def selectInstallNetDeviceDialog(network, devices = None):

    devs = devices or network.netdevices.keys()
    if not devs:
        return None
    devs.sort()

    dialog = gtk.Dialog(_("Select network interface"))
    dialog.add_button('gtk-cancel', gtk.RESPONSE_CANCEL)
    dialog.add_button('gtk-ok', 1)
    dialog.set_position(gtk.WIN_POS_CENTER)
    gui.addFrame(dialog)

    dialog.vbox.pack_start(gui.WrappingLabel(
        _("This requires that you have an active "
          "network connection during the installation "
          "process.  Please configure a network interface.")))

    combo = gtk.ComboBox()
    cell = gtk.CellRendererText()
    combo.pack_start(cell, True)
    combo.set_attributes(cell, text = 0)
    cell.set_property("wrap-width", 525)
    combo.set_size_request(480, -1)
    store = gtk.TreeStore(gobject.TYPE_STRING, gobject.TYPE_STRING)
    combo.set_model(store)

    ksdevice = network.getKSDevice()
    if ksdevice:
        ksdevice = ksdevice.get('DEVICE')
    preselected = None

    for dev in devices:
        i = store.append(None)
        if not preselected:
            preselected = i

        desc = network.netdevices[dev].description
        if desc:
            desc = "%s - %s" %(dev, desc)
        else:
            desc = "%s" %(dev,)

        hwaddr = network.netdevices[dev].get("HWADDR")

        if hwaddr:
            desc = "%s - %s" %(desc, hwaddr,)

        if ksdevice and ksdevice == dev:
            preselected = i

        store[i] = (desc, dev)

    combo.set_active_iter(preselected)
    dialog.vbox.pack_start(combo)

    dialog.show_all()

    rc = dialog.run()

    if rc in [gtk.RESPONSE_CANCEL, gtk.RESPONSE_DELETE_EVENT]:
        install_device = None
    else:
        active = combo.get_active_iter()
        install_device = combo.get_model().get_value(active, 1)

    dialog.destroy()
    return install_device

