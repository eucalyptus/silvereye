#!/usr/bin/python
# -*- coding: utf-8 -*-

# Software License Agreement (BSD License)
#
# Copyright (c) 2009-2011, Eucalyptus Systems, Inc.
# All rights reserved.
#
# Redistribution and use of this software in source and binary forms, with or
# without modification, are permitted provided that the following conditions
# are met:
#
#   Redistributions of source code must retain the above
#   copyright notice, this list of conditions and the
#   following disclaimer.
#
#   Redistributions in binary form must reproduce the above
#   copyright notice, this list of conditions and the
#   following disclaimer in the documentation and/or other
#   materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Author: Andy Grimm agrimm@eucalyptus.com

import glob
import os
import sys

from euca2ools.commands.eustore.installimage import *

class InstallUnpackedImage(InstallImage):
    def get_tarball(self, workdir):
        return None

    def bundle_and_register_all(self, dir, tarfile):
        names = glob.glob(os.path.join(dir, '*'))
        kernel_id = None
        ramdisk_id = None
        machine_id = None
        for name in names:
            if os.path.basename(name).startswith('vmlin'):
                kernel_id = self._upload_and_register(name, 'kernel', dir)
            elif os.path.basename(name).startswith('initr'):
                ramdisk_id = self._upload_and_register(name, 'ramdisk', dir)

        for name in names: 
            if os.path.basename(name).endswith('.img'):
                machine_id = self._upload_and_register(name, 'machine', dir,
                                                       kernel_id=kernel_id,
                                                       ramdisk_id=ramdisk_id)
        return dict(machine=machine_id, kernel=kernel_id, ramdisk=ramdisk_id)

    def _upload_and_register(self, name, image_type, dir, **kwargs):
        print "Bundling/uploading {0}".format(image_type)
        manifest_loc = self.bundle_and_upload_image(name, image_type, dir,
                                                    **kwargs)
        req = RegisterImage(config=self.config,
                service=self._InstallImage__eucalyptus,
                ImageLocation=manifest_loc, Name=name,
                Description=self.args.get('description'),
                Architecture=self.args.get('architecture'))
        response = req.main()
        image_id = response.get('imageId')
        if self.args['show_progress']:
            print 'Registered {0} image {1}'.format(image_type, image_id)
        os.system('euca-modify-image-attribute -l -a all {0}'.format(image_id))
        return image_id


if __name__ == '__main__':
    InstallUnpackedImage.run()
