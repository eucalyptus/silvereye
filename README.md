# About Silvereye

Silvereye is an automated installer for Eucalyptus 3.  It is intended for
quick cloud deployments for demos, testing, or PoCs.  It is *not*
intended for production deployments, nor is it supported by Eucalyptus.

Silvereye targets three very simple cloud topologies:

* One "front end" with a single NIC, and one or more node controllers with 
a single NIC.
* One "front end" with two NICs, "public" and "private", and one or more
node controllers on the "private" subnet.
* A "cloud-in-a-box", where the front end and a node controller reside on
the same machine, with a single NIC.

In all of these scenarios, silvereye uses the "MANAGED-NOVLAN" networking mode
in Eucalyptus, to avoid requirements for specific network switch hardware.

Silvereye does not yet support any other network modes, nor does it support
the separation of the front end's components.

# Prerequisites

For the latest official Eucalyptus hardware requirements, please see
<http://www.eucalyptus.com/docs/3.2/ig/system_requirements.html>

For demo purposes, smaller configurations are sometimes possible, though not
recommended.  If the target system has less than 2 GB of RAM or less than 
35 GB of disk space, it is likely that the install will not produce a usable
cloud.  Other notes about the installation:

1. Systems which run as node controllers (including "cloud-in-a-box" systems)
*must* have CPUs which support Intel-VT or AMD-V, and this support must be
enabled in the BIOS.
2. Eucalyptus runs its own DHCP server. It can coexist with another DHCP
server *if* the other server is configured to ignore all mac addresses that 
start with D0:0D.  (Eucalyptus will _only_ respond to mac addresses that start
with D0:0D.)
3. Each system must have a statically assigned IP address.  This can be a
DHCP reservation, but it must not change. IP address changes require database
modifications which are currently unsupported.
4. The front end and node controllers must be connected to the same subnet; it
is okay for the front end to have a separate "public" and "private" network,
where the node controllers should be on the "private" network.
5. There must be a set of free IP addresses on the same network as the front
end's "public" interface.   

More documentation on Eucalyptus configuration can be found at:

http://www.eucalyptus.com/eucalyptus-cloud/documentation

# Downloading an official ISO

Silvereye ISOs (rebranded as "FastStart" for official Eucalyptus releases)
can be downloaded from <http://downloads.eucalyptus.com/software/faststart/>

New features are being added in each release, so please reference the 
version-specific "FastStart Guide" at <http://www.eucalyptus.com/docs>

# Building an ISO

Running the silvereye.py script will generate a CentOS 6 based ISO.  This
build script has a large set of command-line options, all of which are
documented in the help text.

The script requires that several packages be installed on your build system:

* python-argparse (This comes from EPEL, so you need to configure this
repository first.  See 
<http://fedoraproject.org/wiki/EPEL#How_can_I_use_these_extra_packages.3F> )
* ImageMagick
* syslinux-perl
* anaconda (this may no longer be needed)
* git (unless the --sce option is used)

*NOTE*: If you don't want to build a full ISO, see the --no-iso option,
which builds only the updates.img file.

# Reporting Bugs

Please report bugs at <https://eucalyptus.atlassian.net/browse/INST>

