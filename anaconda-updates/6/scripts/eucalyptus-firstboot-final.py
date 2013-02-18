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
        label = gtk.Label(_("Your eucalyptus installation is now complete.  "
                            "You may now login to the local desktop environment "
                            "on this system, or you can use a web browser to connect "
                            "from a remote system.  Please make note of the following "
                            "login credentials:\n\n") + open('/etc/motd', 'r').read())
        label.set_alignment(0.0, 0.5)
        label.set_size_request(500, -1)

        self.vbox.pack_start(label, False, True)

    def initializeUI(self):
        pass

