#!/bin/bash

REPOCOMPSFILE=`ls ${BUILDDIR}/*comps.xml`
echo "$(date) - Creating repodata"
cd ${BUILDDIR}/image
declare -x discinfo="$DATESTAMP"
createrepo -u "media://$discinfo" -g ${REPOCOMPSFILE} . > /dev/null
echo "$(date) - Repodata created"

