Silvereye is an automated installer for Eucalyptus 3.1.

Running the script silvereye.sh will generate a CentOS-based ISO.  Booting from this ISO
will allow you to install either a frontend (cloud controller + cluster controller + storage
controller + walrus) or a node controller.  We recommend installing node controllers first 
so that the frontend can then attach to them.

NOTE #1: Eucalyptus runs its own DHCP server. It can play nicely with yours *if* you tell your current
DHCP server to ignore all mac addresses that start with D0:0D.  (And don't worry; Eucalyptus will
only respond to mac addresses that start with D0:0D.)

NOTE #2: Silvereye is not supported.  At all.  If you use it, there are ABSOLUTELY NO GUARANTEES that 
it won't burn down your house, steal your pickup truck, or throw your mother into a wood-chipper.

For basic installation instructions from the ISO itself, please see INSTALL.md.

More documentation on Eucalyptus configuration can be found at:

http://www.eucalyptus.com/eucalyptus-cloud/documentation