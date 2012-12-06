#!/usr/bin/python
import gtk

from firstboot.config import *
from firstboot.constants import *
from firstboot.functions import *
from firstboot.module import *
import subprocess
import re

import gettext
_ = lambda x: gettext.ldgettext("firstboot", x)
N_ = lambda x: x

class moduleClass(Module):
    def __init__(self):
        Module.__init__(self)
        self.priority = 999
        self.sidebarTitle = N_("Configuration Complete")
        self.title = N_("Configuration Complete")
        self.icon = "workstation.png"

    def apply(self, interface, testing=False):
        return RESULT_SUCCESS

    def createScreen(self):
        self.vbox = gtk.VBox(spacing=10)

        # Get the IP address that corresponds to the default route
        dev = "up"
        ipaddr = "<ip address>"
        routes = [ x.split() for x in open("/proc/net/route", "r").readlines() if x.split()[1] == "00000000" ]
        if len(routes):
            dev = routes[0][0]
        po = subprocess.Popen(["ip", "-o", "-f", "inet", "addr", "show", dev], stdout=subprocess.PIPE)
        out = po.communicate()[0]
        m = re.match(".*inet (\S+)/\d+ brd.*", out)
        if m:
            ipaddr = m.groups()[0]
        else:
            # LOLWUT?
            pass

        label = gtk.Label(_("Your eucalyptus installation is now complete.  "
                            "You may now login to the local desktop environment "
                            "on this system, or you can use a web browser to connect "
                            "from a remote system.\n\nUser Console URL: https://%s:8888/\n\n"
                            "User Credentials:\n"
                            "  * Account:  demo\n"
                            "  * Username: admin\n"
                            "  * Password: demo\n\n"
                            "Admin Console URL: https://%s:8443/\n\n"
                            "Admin Credentials:\n"
                            "  * Account:  eucalyptus\n"
                            "  * Username: admin\n"
                            "  * Password: admin\n" % (ipaddr, ipaddr)))
        label.set_line_wrap(True)
        label.set_alignment(0.0, 0.5)
        label.set_size_request(500, -1)

        self.vbox.pack_start(label, False, True)

    def initializeUI(self):
        pass

