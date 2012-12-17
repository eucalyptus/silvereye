#
# Chris Lumens <clumens@redhat.com>
#
# Copyright 2007 Red Hat, Inc.
#
# This copyrighted material is made available to anyone wishing to use, modify,
# copy, or redistribute it subject to the terms and conditions of the GNU
# General Public License v.2.  This program is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY expressed or implied, including the
# implied warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.  Any Red Hat
# trademarks that are incorporated in the source code or documentation are not
# subject to the GNU General Public License and may only be used or replicated
# with the express permission of Red Hat, Inc. 
#
import gtk
import os
import glob

from firstboot.config import *
from firstboot.constants import *
from firstboot.functions import *
from firstboot.module import *

from eucadmin.synckeys import SyncKeys
from eucadmin.configfile import ConfigFile
import subprocess
import os
import socket

import gettext
_ = lambda x: gettext.ldgettext("firstboot", x)
N_ = lambda x: x

class moduleClass(Module):
    def __init__(self):
        Module.__init__(self)
        self.priority = 2
        self.sidebarTitle = N_("Node Registration")
        self.title = N_("Node Registration")
        self.icon = "workstation.png"

    def apply(self, interface, testing=False):
        eucaconfig = ConfigFile('/etc/eucalyptus/eucalyptus.conf')
        current_nodes = eucaconfig['NODES'].split()
        nodes_to_add = self.nodeIP.get_text().split()

        keys = ['node-cert.pem', 'cluster-cert.pem', 'cloud-cert.pem',
                'node-pk.pem']

        key_dir = os.path.join('/var/lib/eucalyptus/keys')
        file_paths = [os.path.join(key_dir, key) for key in keys]

        for node in nodes_to_add:
            try:
                socket.inet_pton(socket.AF_INET, node)
            except socket.error:
                self._showErrorMessage("IPv4 addresses must contain four numbers between 0 and 255, separated by periods.")
                self.nodeIP.grab_focus()
                return RESULT_FAILURE

        display = os.environ.get('DISPLAY', '')
        if not display:
            x = getattr(config.frontend, 'x', '')
            if x:
                display = open('/proc/%s/cmdline' % x.pid, 'r').read().split('\0')[1]

        for node in nodes_to_add:
            if node not in current_nodes:
                current_nodes.append(node)

            cmd = ['rsync', '-e', 'ssh -oStrictHostKeyChecking=no', '-az'] + file_paths
            cmd.append('root@%s:%s' % (node, key_dir))
            p = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE,
                                      env={ 'PATH': os.environ['PATH'],
                                            'DISPLAY': display,
                                            'SSH_ASKPASS': '/usr/libexec/openssh/gnome-ssh-askpass' } )
            out, err = p.communicate()
            if p.returncode:
                # TODO: display errors in a message window
                self._showErrorMessage(err)
                self.nodeIP.grab_focus()
                return RESULT_FAILURE

        eucaconfig['NODES'] = ' '.join(current_nodes)
        
        return RESULT_SUCCESS

    def createScreen(self):
        self.vbox = gtk.VBox(spacing=10)
        self.vbox.set_border_width(10)
        self.vbox.set_spacing(5)

        label = gtk.Label("""
Please enter the IP address of one or more nodes to register.  You will be prompted for the root password of each node.
""")
        label.set_line_wrap(True)
        label.set_alignment(0.0, 0.5)
        label.set_size_request(500, -1)

        self.nodeIP = gtk.Entry(50)

        self.vbox.pack_start(label, False, True)
        self.vbox.pack_start(self.nodeIP, False)

    def focus(self):
        self.nodeIP.grab_focus()

    def renderModule(self, interface):
        # We are not supposed to override this, but it's the only way to
        # connect this event.
        Module.renderModule(self, interface)
        self.nodeIP.connect("activate", interface._nextClicked)

    def initializeUI(self):
        pass

    def _showErrorMessage(self, text):
        dlg = gtk.MessageDialog(None, 0, gtk.MESSAGE_ERROR, gtk.BUTTONS_OK, text)
        dlg.set_position(gtk.WIN_POS_CENTER)
        dlg.set_modal(True)
        rc = dlg.run()
        dlg.destroy()
        return None

