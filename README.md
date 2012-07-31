Silvereye is an automated installer for Eucalyptus 3.1.

Running the script silvereye.sh will generate a CentOS-based ISO.  Booting from this ISO
will allow you to install either a frontend (cloud controller + cluster controller + storage
controller + walrus) or a node controller.  We recommend installing node controllers first 
so that the frontend can then attach to them.

More documentation on Eucalyptus configuration can be found at:

http://www.eucalyptus.com/eucalyptus-cloud/documentation