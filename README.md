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

More documentation on Eucalyptus configuration can be found at:

http://www.eucalyptus.com/eucalyptus-cloud/documentation

* * * * *

INSTALLATION FROM SILVEREYE ISO:

(NOTE: these are *draft* instructions.  We recommend following them to the letter, but even then, 
you may run into issues.  Patches welcome.)

STEP 1: Sort out your network!  Rule number one for running a private cloud: Know Thy Network.

Here's what you need:

* Static IP addresses for your physical machines (frontend and each Node Controller).  
* A safe IP range for your Eucalyptus instances.
* If these addresses are all NATted, that's a-ok!

Note that you can get all of these with a traditional at-home router setup.  I myself use a 
Linksys 4-port router plugged into my cable modem.

STEP 2: Sort out your hardware!  You need at least two systems that support virtualization, 
and have 100GB of disk, 8Gig of ram, an Ethernet NIC, and a DVD drive (or a way to boot an ISO
such as a PXE server).  The systems can be laptops, desktops, servers, or whatever.  One system 
is for the frontend; all the rest are for Node Controllers.

STEP 3: Get your silvereye ISO.  Go get it from here and burn it to DVD: 

http://downloads.eucalyptus.com/software/contrib/silvereye/

STEP 4: Boot your first machine, which will be a node controller, with your Silvereye DVD.  When you get 
to the pretty Eucalyptus boot prompt, you will see several options, the first of which should be 
"Install CentOS 6 with Eucalyptus Node Controller."  Pick that option and hit enter.  You will then be 
taken through a standard CentOS install.  You should be able to safely choose all default options.  
After CentOS successfully installs, reboot.

STEP 5: when the machine reboots, log in as root and the Eucalyptus node controller configuration 
script will begin.  Configure your network settings for this machine, using the static IP addresses
you set aside before installation.  (Note: if you have a laptop, we advise against setting up the
wireless network card; use the built-in ethernet NIC.)  You should be able to select defaults all the 
way through.  When you're done, you should have a functioning Node Controller!  

Repeat steps 4 and 5 as often as needed, once for each NC.  Be sure to note the IP addresses of your NCs; 
you will need them later when you set up your frontend.

STEP 6: Boot your frontend with the Silvereye DVD.  Go through the same install process for Centos 6, 
as you did for the NC in Step Four.

STEP 7: When the machine reboots, log in as root and the Eucalyptus frontend configration script will 
begin.  Configure network settings with your static IP address, and accept all defaults. 

Type "yes" when prompted to build an EMI. (If you need to put in the installer disc again, put it in.)  
Type "small" when asked about root filesystem size for the default image (recommend small for the first 
time out.)  Install graphical front end if you like.  Reboot.

STEP 8: Test your install!  From your front-end machine, bring up terminal.  
To set up your credentials, run "source /root/credentials/admin/eucarc".  You should then be able
to type "euca-describe-images" and see images in your cloud!
