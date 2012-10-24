#!/usr/bin/python
#
# Copyright (c) 2012  Eucalyptus Systems, Inc.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, only version 3 of the License.
#
#
#   This file is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   Please contact Eucalyptus Systems, Inc., 6755 Hollister Ave.
#   Goleta, CA 93117 USA or visit <http://www.eucalyptus.com/licenses/>
#   if you need additional information or have any questions.
#
#
# This script will create a customized CentOS x86_64 minimal installation
# CD image that includes Eucalyptus in the installations.
# The script should be used from an existing CentOS x86_64 installation.
# If the EPEL, ELRepo, euca2ools and Eucalyptus package repositories are not
# present on the system this script will install/create them.

import argparse
import cookielib
import glob
import gzip
import logging
import os
import re
import shutil
import subprocess
import sys
from tempfile import mkstemp, mkdtemp
import time
from urllib import urlencode
import urllib2
import yum

import bdb
import traceback
try:
    import epdb as debugger
except ImportError:
    import pdb as debugger

def gen_except_hook(debugger_flag, debug_flag):
  def excepthook(typ, value, tb):
    if typ is bdb.BdbQuit:
      sys.exit(1)
    sys.excepthook = sys.__excepthook__

    if debugger_flag and sys.stdout.isatty() and sys.stdin.isatty():
      if debugger.__name__ == 'epdb':
        debugger.post_mortem(tb, typ, value)
      else:
        print traceback.print_tb(tb)
        debugger.post_mortem(tb)
    elif debug_flag:
      print traceback.print_tb(tb)
      sys.exit(1)
    else:
      print value
      sys.exit(1)

  return excepthook

def mkdir(x):
  if not os.path.exists(x):
    os.makedirs(x)

def get_distro_and_version():
  releasedata = open('/etc/redhat-release', 'r').read().strip()
  m = re.match('(.*) release ([0-9]+).*', releasedata)
  return m.groups()

def chunked_download(url, dest):
  req = urllib2.urlopen(url)
  CHUNK = 16 * 1024
  fp = open(dest, 'wb')
  while True:
    chunk = req.read(CHUNK)
    if not chunk: break
    fp.write(chunk)
  fp.close()


class SilvereyeCLI():
  def __init__(self):
    parser = argparse.ArgumentParser(description='Silvereye ISO builder')
    parser.add_argument('--eucaversion', default='3.1',
                        help='The version of eucalyptus to include')
    parser.add_argument('--builddir', default=None,
                        help='The build directory')
    parser.add_argument('--verbose', action="store_true",
                        help='Enable verbose logging')
    parser.add_argument('--isofile', default=None,
                        help='The name of the output ISO file')
    parser.add_argument('--debug', action="store_true",
                        help='Enable tracebacks on exceptions')
    parser.add_argument('--debugger', action="store_true",
                        help='Enable debugger on exceptions')
    parser.add_argument('--distroname', 
                        help='(EXPERIMENTAL) The Linux distribution name (usually CentOS)')
    parser.add_argument('--distroversion', 
                        help='(EXPERIMENTAL) The version of $DISTRONAME to use')
    parser.add_argument('--noclean', action="store_true",
                        help='Reuse contents in builddir')
    parser.add_argument('--cachedir',
                        help='The yum cache directory')
    parser.add_argument('--updatesurl', 
                        help='Fetch an updates img via url (CD will boot in debug mode)')
    parser.add_argument('--quiet', action="store_true",
                        help='Suppress non-log output')
    parser.add_argument('--epel-repo',
                        help='Set the base URL for your EPEL yum repository')
    parser.add_argument('--centos-repo',
                        help='Set the base URL for your CentOS yum repository')
    parser.add_argument('--eucalyptus-repo',
                        help='Set the base URL for your Eucalyptus repository')
    parser.add_argument('--euca2ools-repo',
                        help='Set the base URL for your Euca2ools repository')
    parser.add_argument('--kexec-kernel-url',
                        help='URL from which to download the kexec loader kernel')
    parser.add_argument('--kexec-initramfs-url',
                        help='URL from which to download the kexec loader initramfs')
    parser.add_argument('--release', action="store_true",
                        help='Indicates that this is an official product release')
    self.parser = parser

  def run(self):
    kwargs = dict()
    parsedargs = self.parser.parse_args()
    sys.excepthook = gen_except_hook(parsedargs.debugger, parsedargs.debug)
    for attr in [ 'builddir', 'distroname', 'distroversion',
                  'eucaversion', 'isofile', 'updatesurl',
                  'cachedir', 'verbose', 'quiet', 'noclean',
                  'kexec_kernel_url', 'kexec_initramfs_url',
                  'release'
                ]:
      value = getattr(parsedargs, attr)
      if value is not None:
        kwargs[attr] = value

    repoMap = dict()
    for attr in [ 'centos_repo', 'epel_repo', 'eucalyptus_repo',
                  'euca2ools_repo'
                ]:
      value = getattr(parsedargs, attr)
      if value is not None:
        repoMap[attr.split('_')[0]] = value

    builder = SilvereyeBuilder(**kwargs) 
    builder.distroCheck()
    builder.installBuildDeps()
    builder.getIsolinuxFiles()
    builder.getImageFiles()
    builder.getKexecFiles()
    builder.createKickstartFiles()
    builder.copyConfigScripts()
    builder.setupRequiredRepos(repoMap=repoMap)
    builder.downloadPackages()
    builder.makeUpdatesImg()
    builder.makeProductImg()
    builder.createRepo()
    builder.createBootLogo()
    builder.createBootMenu()
    builder.createISO()
    
class SilvereyeBuilder(yum.YumBase):
  def __init__(self, *args, **kwargs):
    """
    NOTE: Valid kwargs are builddir, distroname, distroversion,
          isofile, and eucaversion
    """
    yum.YumBase.__init__(self)

    # This is the directory for the silvereye source file tree
    self.basedir=kwargs.get('basedir', os.path.dirname(sys.argv[0]))
    if not self.basedir:
      self.basedir=os.getcwd()
    else:
      self.basedir=os.path.abspath(self.basedir)

    self.datestamp = str(time.time())

    self.eucaversion = kwargs.get('eucaversion', '3.1')

    hostdistroname, hostdistroversion = get_distro_and_version()
    self.distroname = kwargs.get('distroname', hostdistroname)
    self.distroversion = kwargs.get('distroversion', hostdistroversion)
    self.updatesurl = kwargs.get('updatesurl', None)

    self.cmdout = None
    if kwargs.get('quiet', False):
      self.cmdout = open('/dev/null', 'w')

    self.builddir = kwargs.get('builddir',
                                os.path.join(os.getcwd(), 
                                             'silvereye_build.' + self.datestamp))
    if os.path.exists(self.builddir) and kwargs.get('noclean', False) != True:
      shutil.rmtree(os.path.abspath(self.builddir))
    mkdir(self.builddir)
    self.builddir = os.path.abspath(self.builddir)

    # Define the logger, but it must be set up after final configuration
    self.logger = logging.getLogger('silvereye')
    self.setupLogging(kwargs.get('verbose', False))

    self.isofile = kwargs.get('isofile', 
                              os.path.join(self.builddir, 
                                           "silvereye.%s.iso" % self.datestamp))

    tmpdir = os.path.abspath(kwargs.get('cachedir', '/var/tmp'))
    mkdir(tmpdir)
    self.setCacheDir(tmpdir=tmpdir)
    # This is for yumdownloader calls
    os.environ['TMPDIR'] = tmpdir

    # TODO: Make more official download links
    self.kexec_kernel = kwargs.get('kexec_kernel_url',
                                   'https://raw.github.com/monolive/euca-single-kernel/master/examples/vmlinuz')
    self.kexec_initramfs = kwargs.get('kexec_initramfs_url',
                                      'https://raw.github.com/monolive/euca-single-kernel/master/examples/initrd-kexec_load')

    self.release = kwargs.get('release', False)

  @property 
  def pkgdir(self):
    return os.path.join(self.builddir, 'image', 'CentOS')

  @property
  def imgdir(self):
    return os.path.join(self.builddir, 'image')

  def setupLogging(self, verbose=False):
    # Enable logging to a file in the build directory
    handler = logging.FileHandler(os.path.join(self.builddir, 'silvereye.%s.log' % self.datestamp))
    handler.setFormatter(logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
    self.logger.addHandler(handler)

    if verbose:
      self.logger.setLevel(logging.DEBUG)
    else:
      self.logger.setLevel(logging.INFO)

  def distroCheck(self):
    if self.distroversion in [ "5", "6" ]:
      self.logger.info("Building installation CD image for %s release %s with Eucalyptus %s." % \
                (self.distroname, self.distroversion, self.eucaversion))
    else:
      self.logger.error("This script must be run on CentOS version 5 or 6")
      sys.exit(2)

  def installBuildDeps(self):
    # Install silvereye dependencies
    deps = set([ 'yum-utils', 'createrepo',
                 'ImageMagick', 'syslinux' ])

    if self.distroversion == "5":
      deps.update([ 'anaconda-runtime' ])
    else:
      deps.update([ 'syslinux-perl', 'anaconda' ])

    for x in list(deps):
      if self.isPackageInstalled(x):
        deps.remove(x)

    if not len(deps):
      return

    matching = [ x for x in self.searchGenerator(['name'], deps) ]
    if not len(matching):
      return

    if os.geteuid() != 0:
      self.logger.error("Missing build dependencies: " + ' '.join([ x.name for x in matching ]))
      raise Exception("Missing build dependencies cannot be installed as a non-root user")
    
    for (po, matched_value) in matching:
      self.install(po)
    self.buildTransaction()
    self.processTransaction()

  def getIsolinuxFiles(self):
    # Create the build directory structure
    repo = self.repos.getRepo('base')
    downloadUrl = repo.urls[0]

    # Create the build directory structure
    for x in [ 'CentOS', 'images/pxeboot', 'isolinux', 'ks', 'scripts' ]:
      mkdir(os.path.join(self.imgdir, x))

    if self.distroversion == "5":
      mkdir(os.path.join(self.imgdir, 'images', 'xen'))

    self.logger.info("Created %s directory structure" % self.builddir)
    self.logger.info("Using %s for downloads" % downloadUrl)

    # write merged comps
    self.comps.add(os.path.join(self.basedir, 'comps.xml'))
    open(os.path.join(self.builddir, 'comps.xml'), 'w').write(self.comps.xml())

    fileset = set(['.discinfo',
                   'EULA',
                   'GPL',
                   'isolinux/boot.msg',
                   'isolinux/initrd.img',
                   'isolinux/isolinux.bin',
                   'isolinux/isolinux.cfg',
                   'isolinux/memtest',
                   'isolinux/vmlinuz'
                  ])

    if self.distroversion == "5":
      fileset.update(['isolinux/general.msg',
                      'isolinux/options.msg',
                      'isolinux/param.msg',
                      'isolinux/rescue.msg',
                      'isolinux/splash.lss'
                     ])
    else:
      fileset.update(['isolinux/grub.conf',
                      'isolinux/splash.jpg',
                      'isolinux/vesamenu.c32',
                     ])

    for x in fileset:
      # we should probably compare timestamps here
      if not os.path.exists(os.path.join(self.imgdir, x)):
        self.logger.info("Downloading " + downloadUrl + x)
        chunked_download(downloadUrl + x,
                         os.path.join(self.imgdir, x))

  def getImageFiles(self):
    repo = self.repos.getRepo('base')
    downloadUrl = repo.urls[0]

    imgfileset = set([
                      'pxeboot/vmlinuz',
                      'pxeboot/initrd.img'
                     ])

    if self.distroversion == "5":
      imgfileset.update([
                         'README',
                         'boot.iso',
                         'minstg2.img',
                         'stage2.img',
                         'diskboot.img',
                         'xen/vmlinuz',
                         'xen/initrd.img',
                         'pxeboot/README',
                        ])
    else:
      imgfileset.update([
                         'efiboot.img',
                         'efidisk.img',
                         'install.img',
                        ])

    for x in imgfileset:
      # we should probably compare timestamps here
      if not os.path.exists(os.path.join(self.imgdir, 'images', x)):
        self.logger.info("Downloading " + downloadUrl + 'images/' + x)
        chunked_download(downloadUrl + 'images/' + x,
                         os.path.join(self.imgdir, 'images', x))
  def makeUpdatesImg(self):
    sudo = []
    # Fix anaconda bugs to allow copying files from CD during %post
    # scripts in EL5, and network prompting in EL6
    updatesdir = os.path.join(self.builddir, 'updates')
    updatesimg = os.path.join(self.imgdir, 'images', 'updates.img')

    if self.distroversion == "5":
      mkdir(updatesdir)
      if os.geteuid() != 0:
        self.logger.warning("Not running as root; attempting to use sudo for mount/umount")
        sudo = ['sudo']

      imgfile = open(updatesimg, 'w')
      imgfile.seek(128 * 1024)
      imgfile.write('\0')
      imgfile.close()

      subprocess.call(["/sbin/mkfs.ext2", "-F", "-L", "updates", updatesimg], 
                      stdout=self.cmdout, stderr=self.cmdout)
      subprocess.call(sudo + [ "/bin/mount", "-o", "loop", updatesimg, updatesdir ],
                      stdout=self.cmdout, stderr=self.cmdout)
      os.chmod(updatesdir, 0777)
      f = open('/usr/lib/anaconda/dispatch.py', 'r')
      g = open('updates/dispatch.py', 'w')
      for line in f.readlines():
        line1 = line.replace('("dopostaction", doPostAction, )', 
                             '("methodcomplete", doMethodComplete, )')
        if line1 != line:
          g.write(line1)
        else:
          g.write(line.replace('("methodcomplete", doMethodComplete, )',
                               '("dopostaction", doPostAction, )'))
      f.close()
      g.close()
      subprocess.call(sudo + ['/bin/umount', updatesdir ],
                      stdout=self.cmdout, stderr=self.cmdout)
    elif self.distroversion == "6":
      if os.path.exists(updatesdir):
        shutil.rmtree(updatesdir)
      shutil.copytree(os.path.join(self.basedir, 'anaconda-updates', self.distroversion), updatesdir)
      pixmapDir = os.path.join(updatesdir, 'pixmaps')
      shutil.copyfile(self.getLogo(), os.path.join(pixmapDir, 'splash.png'))
      os.link(os.path.join(pixmapDir, 'splash.png'), os.path.join(pixmapDir, 'progress_first.png'))

      # TODO: Remove this, I think, because we no longer rely on kickstart for EL6
      f = open('/usr/lib/anaconda/kickstart.py', 'r')
      g = open(os.path.join(updatesdir, 'kickstart.py'), 'w')
      for line in f.readlines():
        if re.match('.*dispatch.skipStep.*network.*', line):
          continue
        g.write(line)
      f.close()
      g.close()

      filelist = []
      def appender(ign, dir, files):
        filelist.extend([ os.path.join(dir.replace(updatesdir, '.'), f) for f in files ])
      os.path.walk(updatesdir, appender, None)
      p = subprocess.Popen(['cpio', '-H', 'newc', '-o'],
                       cwd=os.path.abspath(updatesdir),
                       stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE)
      zipball = gzip.GzipFile(updatesimg, 'w')
      zipball.write(p.communicate(input='\n'.join(filelist))[0])
      zipball.close()

  def createKickstartFiles(self):
    # Create kickstart files
    ksdest = os.path.join(self.imgdir, 'ks')
    ksTmplDir = os.path.join(self.basedir, 'ks_templates')
    for ks in os.listdir(ksTmplDir):
      dest = open(os.path.join(ksdest, ks), 'w')
      for line in open(os.path.join(ksTmplDir, ks), 'r').readlines():
        if self.distroversion == "6":
          if line.strip() in [ 'dbus-python', 'kernel-xen', 'libxml2-python',
                               'xen', '-kernel' ]:
            continue
          elif re.match('network .*query', line):
            continue
        # elif eucaversion == 'nightly' and line.startswith('eucalyptus-release'):
        #  dest.write("eucalyptus-release-nightly\n")
        #  continue
        dest.write(line)

  def copyConfigScripts(self):
    for script in [ 'eucalyptus-frontend-config.sh',
                    'eucalyptus-nc-config.sh',
                    'eucalyptus-create-emi.sh' ]:
      shutil.copyfile(os.path.join(self.basedir, 'scripts', script),
                      os.path.join(self.imgdir, 'scripts', script))

  def getKexecFiles(self):
    urlRE = re.compile(r'(https?|ftp)://')
    if urlRE.match(self.kexec_kernel):
      chunked_download(self.kexec_kernel, os.path.join(self.imgdir, 'scripts', 'vmlinuz-kexec'))
    else:
      shutil.copyfile(self.kexec_kernel, os.path.join(self.imgdir, 'scripts', 'vmlinuz-kexec'))

    if urlRE.match(self.kexec_initramfs):
      chunked_download(self.kexec_initramfs, os.path.join(self.imgdir, 'scripts', 'initramfs-kexec'))
    else:
      shutil.copyfile(self.kexec_initramfs, os.path.join(self.imgdir, 'scripts', 'initramfs-kexec'))

  # Configure yum repositories
  def setupRepo(self, repoid, pkgname=None, ignoreHostCfg=False, mirrorlist=None, baseurl=None):
    if ignoreHostCfg and self.repos.repos.has_key(repoid):
      self.repos.delete(repoid)

    # We were checking for whether the release package was installed,
    # but that will only matter if we try to grab GPG keys
    if not self.repos.repos.has_key(repoid):
      newrepo = yum.yumRepo.YumRepository(repoid)
      newrepo.enabled = 1
      newrepo.gpgcheck = 0  # This is because we aren't installing the key.  Fix this.
      if mirrorlist:
        newrepo.mirrorlist = mirrorlist
      else:
        newrepo.baseurl = baseurl
      self.repos.add(newrepo)

  def setupRequiredRepos(self, repoMap={}):
    # Install/configure EPEL repository
    if repoMap.has_key('epel'):
      self.setupRepo('epel', baseurl='%s/%s/%s/' % (repoMap['epel'], self.distroversion, self.conf.yumvar['basearch']),
                     ignoreHostCfg=True)
    else:
      self.setupRepo('epel', 'epel-release',
                   mirrorlist="http://mirrors.fedoraproject.org/mirrorlist?repo=epel-%s&arch=%s" % 
                   (self.distroversion, self.conf.yumvar['basearch']))

    # Install/configure ELRepo repository
    if repoMap.has_key('elrepo'):
      self.setupRepo('elrepo', 
                     baseurl='%s/%s/%s/' % (repoMap['epel'],
                                            self.distroversion,
                                            self.conf.yumvar['basearch']),
                     ignoreHostCfg=True)
    self.setupRepo('elrepo', 'elrepo-release',
                   mirrorlist="http://elrepo.org/mirrors-elrepo.el%s" % self.distroversion)

    # Install/configure Eucalyptus repository
    # TODO:  Make sure the yum configuration pulls packages that match the requested release?
    # We should disable repos that might interfere with downloading the correct packages
    if repoMap.has_key('eucalyptus'): 
      self.setupRepo('eucalyptus',
                     baseurl='%s/%s/%s/' % (repoMap['eucalyptus'],
                                            self.distroversion,
                                            self.conf.yumvar['basearch']),
                     ignoreHostConf=True)
    elif self.eucaversion == "nightly":
      self.setupRepo('eucalyptus', 'eucalyptus-release',
                     ignoreHostCfg=True,
                     baseurl="http://downloads.eucalyptus.com/software/eucalyptus/nightly/3.2/centos/%s/%s/" % 
                     (self.distroversion, self.conf.yumvar['basearch']))
    else:
      self.setupRepo('eucalyptus', 'eucalyptus-release',
                     ignoreHostCfg=True,
                     baseurl="http://downloads.eucalyptus.com/software/eucalyptus/%s/centos/%s/%s/" % 
                     (self.eucaversion, self.distroversion, self.conf.yumvar['basearch']))

    # Install euca2ools repository
    if repoMap.has_key('euca2ools'):
      self.setupRepo('euca2ools',
                     baseurl='%s/%s/%s/' % (repoMap['euca2ools'],
                                            self.distroversion,
                                            self.conf.yumvar['basearch']),
                     ignoreHostConf=True)
    else:
      self.setupRepo('euca2ools', 'euca2ools-release',
                   baseurl="http://downloads.eucalyptus.com/software/euca2ools/2.1/centos/%s/%s/" % 
                   (self.distroversion, self.conf.yumvar['basearch']))

  def downloadPackages(self):
    # Retrieve the RPMs for CentOS, Eucalyptus, and dependencies
    coregroup = None
    for groupList in self.doGroupLists():
      for x in groupList:
        if x.name == "Core":
          coregroup = x
          break
      if coregroup: break

    rpms = set(coregroup.packages)
    rpms.update(['centos-release', 'epel-release', 'euca2ools-release',
                 'authconfig', 'fuse-libs', 'gpm', 'libsysfs', 'mdadm',
                 'ntp', 'postgresql-libs', 'prelink', 'setools',
                 'system-config-network-tui', 'tzdata', 'tzdata-java',
                 'udftools', 'unzip', 'wireless-tools', 'livecd-tools',
                 'eucalyptus', 'eucalyptus-admin-tools', 'eucalyptus-cc',
                 'eucalyptus-cloud', 'eucalyptus-common-java',
                 'eucalyptus-gl', 'eucalyptus-nc', 'eucalyptus-sc',
                 'eucalyptus-walrus', 'eucalyptus-release'])

    if self.eucaversion in [ 'nightly', '3.2' ]:
      rpms.update(['eucalyptus-console', 'eucadw'])

    if self.distroversion == "6":
      rpms.update(['ntpdate', 'libvirt-client', 'elrepo-release', 
                   'iwl6000g2b-firmware', 'sysfsutils'])

    # Download the base rpms
    self.logger.info("Retrieving Packages")

    if self.conf.yumvar['basearch'] == 'x86_64':
      self.conf.exclude.append('*.i?86')
    self.conf.assumeyes = 1
    if self.distroversion == "6":
      self.conf.releasever = self.distroversion
      self.conf.plugins=1
    yumconf = os.path.join(self.builddir, 'yum.conf')
    self.conf.write(open(yumconf, 'w'))

    # TODO: convert this to API?
    if self.distroversion == "5":
      subprocess.call(['yumdownloader', 'centos-release'],
                      stdout=self.cmdout, stderr=self.cmdout)
      centospkg = glob.glob('centos-release-*')[0]
      subprocess.call(['rpm', '-iv', '--nodeps', '--justdb', '--root',
                           self.builddir, centospkg],
                      stdout=self.cmdout, stderr=self.cmdout)

    yumrepodir = os.path.join(self.builddir, 'etc', 'yum.repos.d')
    mkdir(yumrepodir)
    for repoid in ['base', 'epel', 'elrepo', 'eucalyptus', 'euca2ools']:
      if self.repos.repos.has_key(repoid):
        if hasattr(self.repos.repos[repoid], 'cfg'):
          self.repos.repos[repoid].cfg.set(repoid, 'enabled', '1')
          self.repos.repos[repoid].cfg.write(open(os.path.join(yumrepodir, repoid + '.repo'), 'w'))
        else:
          repo = self.repos.repos[repoid]
          f = open(os.path.join(yumrepodir, repoid + '.repo'), 'w')
          f.write("[%s]\nenabled=%s\ngpgcheck=%s\n" % (repoid, repo.enabled, repo.gpgcheck))
          if repo.mirrorlist:
            f.write("mirrorlist=" + repo.mirrorlist)
          else:
            f.write("baseurl=" + repo.baseurl[0])
          f.close()
      else:
        raise Exception('repo %s not configured' % repoid)

    self.logger.info("Downloading packages")
    releasever = []
    if self.distroversion == "6":
      releasever = [ '--releasever', '6' ]
    subprocess.call(['yumdownloader', '-c', yumconf,
                     '--resolve', '--installroot', self.builddir,
                     '--destdir', self.pkgdir ] + releasever + list(rpms),
                      stdout=self.cmdout, stderr=self.cmdout) 

  # Create a repository
  def createRepo(self):
    compsfile = os.path.join(self.builddir, 'comps.xml')
    self.logger.info("Creating repodata")
    retcode = subprocess.call(['createrepo', '-u', 'media://' + self.datestamp, '-o', self.imgdir,
                     '-g', compsfile, self.imgdir ],
                      stdout=self.cmdout, stderr=self.cmdout)
    if retcode:
      raise Exception("creatrepo failed!!")
    self.logger.info("Repo created")

  # Create boot logo
  def getLogo(self):
    tmplogo = os.path.join(self.builddir, 'splash.png')

    if os.path.exists(tmplogo):
      return tmplogo

    if self.release:
      cookieJar = cookielib.LWPCookieJar()
      user, password = self.getWikiCreds()
      txdata = urlencode(dict([('u', user), ('p', password),
                               ('id', 'start'), ('do', 'login'),
                              ]))
      txheaders = { 'User-agent' : 'Mozilla/4.0 (compatible; Silvereye 3; Linux)'}
      opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cookieJar))
      req = urllib2.Request('https://wiki.eucalyptus-systems.com/doku.php' , txdata, txheaders)
      handle = opener.open(req)
      data = handle.read()
      logo_url='https://wiki.eucalyptus-systems.com/lib/exe/fetch.php?cache=&media=silvereye-logo.png'
      handle = opener.open(logo_url)
      open(tmplogo, 'w').write(handle.read())
    else:
      # AgI logo (CC BY-SA 3.0) via Activism1234 on Wikipedia
      chunked_download(urllib2.Request('http://upload.wikimedia.org/wikipedia/commons/f/f5/Silver_Iodide_Balls_and_Sticks.png', None, { 'User-agent' : 'Mozilla/4.0 (compatible; Silvereye 3; Linux)'}),
                      os.path.join(self.builddir, 'logo.png'))
      subprocess.call(['convert', os.path.join(self.builddir, 'logo.png'),
                       '-transparent', 'white', tmplogo])

    '''
    # This code extracts the logo from our web UI.  It looks bad at this size,
    # and the image is a trademark.

    javarpm = glob.glob(os.path.join(self.pkgdir, 'eucalyptus-common-java-3*'))[0]

    rootwar = os.path.join(self.builddir, 'root.war')
    p1 = subprocess.Popen(["rpm2cpio", os.path.join(self.pkgdir, javarpm) ], stdout=subprocess.PIPE)
    p2 = subprocess.Popen(['cpio', '-i', '--to-stdout', 
                           './var/lib/eucalyptus/webapps/root.war' ], 
                          stdin=p1.stdout, stdout=open(rootwar, 'w'), cwd=self.builddir)
    p1.stdout.close()
    p2.wait()
    subprocess.call(['unzip', '-j', rootwar,
                     'themes/eucalyptus/logo.png'], 
                      stdout=self.cmdout, stderr=self.cmdout, cwd=self.builddir)

    subprocess.call(['convert', os.path.join(self.builddir, 'logo.png'), 
                     '-resize', '250%', tmplogo])
    '''

    return tmplogo

  def getWikiCreds(self):
    import getpass
    user = getpass.getuser()
    prompt = 'Dokuwiki username [%s]: ' % user
    newuser = raw_input(prompt)
    if len(newuser):
      user = newuser
    password = getpass.getpass('DokuWiki password: ')
    return (user, password)
   
  def createBootLogo(self):
    self.logger.info("Creating boot logo")
    # It would be nice to do all of the ImageMagick stuff with PIL, but I don't know how.
    os.environ['ELVERSION'] = self.distroversion
    os.environ['BUILDDIR'] = self.builddir
    os.environ['LOGOFILE'] = self.getLogo()

    tmplogodir = os.path.join(self.builddir, 'tmplogo')
    mkdir(tmplogodir)
    retcode = subprocess.call([os.path.join(self.basedir, 'scripts', 'create_silvereye_boot_logo.sh')], 
                      stdout=self.cmdout, stderr=self.cmdout, cwd=tmplogodir)
    shutil.rmtree(tmplogodir)

  # Replace the boot menu
  def createBootMenu(self):
    bootcfgdir = os.path.join(self.basedir, 'isolinux', self.distroversion)
    for bootfile in os.listdir(bootcfgdir):
      shutil.copyfile(os.path.join(bootcfgdir, bootfile), 
                      os.path.join(self.imgdir, 'isolinux', bootfile))
    if self.updatesurl:
      isolinuxcfg = open(os.path.join(self.imgdir, 'isolinux', 'isolinux.cfg'), 'r').readlines()
      newcfg = open(os.path.join(self.imgdir, 'isolinux', 'isolinux.cfg'), 'w')
      for x in isolinuxcfg:
        newcfg.write(re.sub(r'(.*append initrd=.*)', 
                            r'\1 debug=1 updates=%s' % self.updatesurl, x))
      newcfg.close()

  def makeProductImg(self):
    productdir = os.path.join(self.builddir, 'product')
    productimg = os.path.join(self.imgdir, 'images', 'product.img')

    mkdir(productdir)
    if os.geteuid() != 0:
      self.logger.warning("Not running as root; attempting to use sudo for mount/umount")
      sudo = ['sudo']

    imgfile = open(productimg, 'w')
    imgfile.seek(128 * 1024)
    imgfile.write('\0')
    imgfile.close()

    subprocess.call(["/sbin/mkfs.ext2", "-F", "-L", "product", productimg],
                    stdout=self.cmdout, stderr=self.cmdout)
    subprocess.call(sudo + [ "/bin/mount", "-o", "loop", productimg, productdir ],
                    stdout=self.cmdout, stderr=self.cmdout)
    os.chmod(productdir, 0777)

    buildstamp = open(os.path.join(productdir, '.buildstamp'), 'w')
    buildstamp.write("""%s.%s
Eucalyptus
%s
final=%s
http://eucalyptus.atlassian.net/
""" % (time.strftime('%y%m%d%H%M', time.localtime()), self.conf.yumvar['basearch'], 
       self.eucaversion, (self.release and "yes" or "no") ))
    buildstamp.close()

    subprocess.call(sudo + [ "/bin/umount", productimg ],
                    stdout=self.cmdout, stderr=self.cmdout)

  # Create the .iso image
  def createISO(self):
    excludeUpdates = []
    if self.updatesurl:
      excludeUpdates = [ '-exclude', 'updates.img' ]
    cmd = ['mkisofs', 
                     '-o', self.isofile, 
                     '-b', 'isolinux/isolinux.bin',
                     '-c', 'isolinux/boot.cat',
                     '-no-emul-boot', '-boot-load-size', '4',
                     '-boot-info-table', '-R', '-J', '-v', '-T', '-joliet-long' ] + \
                     excludeUpdates + [ self.imgdir ]
    print ' '.join(cmd)
    subprocess.call(cmd,
                      stdout=self.cmdout, stderr=self.cmdout)
    if self.distroversion == "5":
      subprocess.call(["/usr/lib/anaconda-runtime/implantisomd5", self.isofile],
                      stdout=self.cmdout, stderr=self.cmdout)
    else:
      subprocess.call(["/usr/bin/implantisomd5", self.isofile],
                      stdout=self.cmdout, stderr=self.cmdout)
    self.logger.info("CD image " + self.isofile + " successfully created")

if __name__ == "__main__":
  cli = SilvereyeCLI()
  cli.run()
