from snack import *
from constants_text import *
from constants import *
import sys
import gettext
_ = lambda x: gettext.ldgettext("anaconda", x)

from system_config_eucalyptus.euca_tui import EucaBaseGrid
from system_config_eucalyptus.configfile import ConfigFile
from system_config_eucalyptus import euca_backend

class FrontendInstallWindow:
    def __call__(self, screen, anaconda):
        #  Shoehorn in package selection, though!
        anaconda.id.instClass.setGroupSelection(anaconda)

        roles = [ 'CLC', 'WS', 'SC', 'CC' ]
        open('/tmp/eucalyptus.conf', 'w').close()
        euca_conf = ConfigFile('/tmp/eucalyptus.conf')

        if getattr(anaconda.id.instClass, 'colocated_nc', 0):
            roles.append('NC')

        bb = ButtonBar(screen, [TEXT_OK_BUTTON, TEXT_BACK_BUTTON])
        base = EucaBaseGrid()(screen, euca_conf, roles, bb)

        while True:
            rc = base.grid.runOnce()

            button = bb.buttonPressed(rc)

            if button == TEXT_BACK_CHECK:
                return INSTALL_BACK

            euca_conf._save_to_file = False
            euca_conf['VNET_PUBLICIPS'] = base.pub_ip.value()
            euca_conf['VNET_PUBINTERFACE'] = base.pub_if.value()
            euca_conf['VNET_PRIVINTERFACE'] = base.priv_if.value()
            euca_conf['VNET_SUBNET'] = base.priv_net.value()
            euca_conf['VNET_NETMASK'] = base.priv_mask.value()
            euca_conf['VNET_DNS'] = base.dnsserver.value()
            euca_conf['VNET_ADDRSPERNET'] = base.addrspernet.value()
            euca_conf['VNET_BRIDGE'] = 'br0'

            errors = euca_backend.validateEucaConfig(euca_conf, roles)
            if not errors:
                euca_conf.save()
                return INSTALL_OK
            else:
                ButtonChoiceWindow(screen, 'Configuration Errors', "\n".join(errors), buttons=["OK"])

