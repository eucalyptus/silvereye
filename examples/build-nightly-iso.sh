#!/bin/bash

./silvereye.py --builddir build --isofile build/silvereye-nightly.iso \
    --eucaversion 3.3 \
    --elrepo-repo http://mirror.symnds.com/distributions/elrepo/elrepo/el6/x86_64/ \
    --epel-repo http://dl.fedoraproject.org/pub/epel/6/x86_64/ \
    --eucalyptus-repo http://downloads.eucalyptus.com/software/eucalyptus/nightly/3.3/centos/ \
    --euca2ools-repo http://repos.fedorapeople.org/repos/gholms/cloud/epel-6/x86_64/ \
    --cachedir yumcache $@

