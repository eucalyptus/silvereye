import iutil
import isys
import os
import time
import sys
import string
import language
import shutil
import traceback
from flags import flags
from constants import *

import logging
log = logging.getLogger("anaconda")

import gettext
_ = lambda x: gettext.ldgettext("anaconda", x)

def memCheck(anaconda):
    totalMem = 0

    if anaconda.dir == DISPATCH_BACK:
        return DISPATCH_NOOP

    mem = open('/proc/meminfo', 'r')
    memTotalRE = re.compile('MemTotal:\s+(\d+)\s+kB')
    for line in mem.readlines():
        m = memTotalRE.match(line)
        if m:
            totalMem = int(m.groups()[0]) / 1024
            if totalMem > 2000:
                return
            else:
                break

    while 1:
        rc = anaconda.intf.messageWindow( _("Warning! Insufficient Memory"),
                                      _("This installation requires at least "
                                        "2 GB (2048 MB) of RAM to function "
                                        "properly. This system appears to "
                                        "have %d MB of RAM." % totalMem),
                                   type="custom", custom_icon="warning",
                                   custom_buttons=[_("_Exit"), _("_Install anyway")])
        if not rc:
            msg =  _("Your system will now be rebooted...")
            buttons = [_("_Back"), _("_Reboot")]
            rc = anaconda.intf.messageWindow( _("Warning! Insufficient Memory!"),
                                     msg,
                                     type="custom", custom_icon="warning",
                                     custom_buttons=buttons)
            if rc:
                sys.exit(0)
        else:
            break

