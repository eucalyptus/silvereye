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
# If the EPEL, ELRepo, console, euca2ools and Eucalyptus package repositories are not
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

# Debugger boilerplate
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
# End debugger boilerplate

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
    parser.add_argument('--console-repo',
                        help='Set the base URL for your Eucalyptus Console repository')
    parser.add_argument('--elrepo-repo',
                        help='Set the base URL for your ELRepo repository')
    parser.add_argument('--kexec-kernel-url',
                        help='URL from which to download the kexec loader kernel')
    parser.add_argument('--kexec-initramfs-url',
                        help='URL from which to download the kexec loader initramfs')
    parser.add_argument('--release', action="store_true",
                        help='Indicates that this is an official product release')
    parser.add_argument('--no-iso', action="store_true",
                        help='Just build updates.img.  Skip ISO generation')
    parser.add_argument('--sce',
                        help='Path to system-config-eucalyptus files')
    self.parser = parser

  def run(self):
    kwargs = dict()
    parsedargs = self.parser.parse_args()
    sys.excepthook = gen_except_hook(parsedargs.debugger, parsedargs.debug)
    for attr in [ 'builddir', 'distroname', 'distroversion',
                  'eucaversion', 'isofile', 'updatesurl',
                  'cachedir', 'verbose', 'quiet', 'noclean',
                  'kexec_kernel_url', 'kexec_initramfs_url',
                  'release', 'no_iso', 'sce',
                ]:
      value = getattr(parsedargs, attr)
      if value is not None:
        kwargs[attr] = value

    repoMap = dict()
    for attr in [ 'centos_repo', 'epel_repo', 'eucalyptus_repo',
                  'euca2ools_repo', 'console_repo', 'elrepo_repo'
                ]:
      value = getattr(parsedargs, attr)
      if value is not None:
        repoMap[attr.split('_')[0]] = value

    builder = SilvereyeBuilder(**kwargs) 
    builder.distroCheck()

    builder.installBuildDeps()

    builder.makeUpdatesImg()

    if parsedargs.no_iso:
        return

    builder.setupRequiredRepos(repoMap=repoMap)
    builder.getIsolinuxFiles()
    builder.getImageFiles()
    builder.createKickstartFiles()
    builder.downloadPackages()
    builder.makeProductImg()
    builder.createRepo()
    builder.createBootLogo()
    builder.createBootMenu()
    builder.createISO()
    
class SilvereyeBuilder(yum.YumBase):
  def __init__(self, *args, **kwargs):
    """
    NOTE: Valid kwargs here are numerous.  All CLI long options are
    also keywords here, except those for repo mapping
    """
    yum.YumBase.__init__(self)

    # This is the directory for the silvereye source file tree
    self.basedir=kwargs.get('basedir', os.path.dirname(sys.argv[0]))
    if not self.basedir:
      self.basedir=os.getcwd()
    else:
      self.basedir=os.path.abspath(self.basedir)

    self.datestamp = str(time.time())

    self.eucaversion = kwargs.get('eucaversion', '3.2')

    hostdistroname, hostdistroversion = get_distro_and_version()
    self.distroname = kwargs.get('distroname', hostdistroname)
    self.distroversion = kwargs.get('distroversion', hostdistroversion)
    self.updatesurl = kwargs.get('updatesurl', None)
    self.no_iso = kwargs.get('no_iso', False)
    self.sce = kwargs.get('sce', None)

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
    if self.release:
        # Using a cookie jar here is required for automated builds
        self.cookieJar = cookielib.LWPCookieJar('.cookiejar.lwp')
        try:
            self.cookieJar.load( ignore_discard=True )
        except Exception, e:
            self.logger.warn("Cookie jar did not exist.  Creating...")
            self.cookieJar.save()


  @property 
  def pkgdir(self):
    if self.distroversion.startswith("5"):
      return os.path.join(self.builddir, 'image', 'CentOS')
    else:
      return os.path.join(self.builddir, 'image', 'Packages')

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
    if self.distroversion.startswith("5") or self.distroversion.startswith("6"):
      self.logger.info("Building installation CD image for %s release %s with Eucalyptus %s." % \
                (self.distroname, self.distroversion, self.eucaversion))
    else:
      self.logger.error("This script must be run on CentOS version 5 or 6")
      sys.exit(2)

  def chunked_download(self, url, dest):
    self.logger.info("Downloading %s to %s" % (url, dest))
    chunked_download(url, dest)

  def installBuildDeps(self):
    # Install silvereye dependencies
    deps = set([ 'ImageMagick' ])
    if not self.no_iso:
      deps.update([ 'yum-utils', 'createrepo', 'syslinux' ])

      if self.distroversion.startswith("5"):
        deps.update([ 'anaconda-runtime' ])
      else:
        deps.update([ 'syslinux-perl', 'genisoimage', 'isomd5sum' ])

    for x in list(deps):
      if self.isPackageInstalled(x):
        deps.remove(x)

    if not len(deps):
      return

    matching = [ x for x in self.searchGenerator(['name'], deps) ]
    if not len(matching):
      return

    if os.geteuid() != 0:
      self.logger.error("Missing build dependencies: " + ' '.join([ x[0].name for x in matching if x[0].name in deps ]))
      raise Exception("Missing build dependencies ( %s ) cannot be installed as a non-root user" % ' '.join([ x[0].name for x in matching if x[0].name in deps ]))
    
    for (po, matched_value) in matching:
      if po.name in deps:
        self.install(po)
    self.buildTransaction()
    self.processTransaction()

  def getIsolinuxFiles(self):
    # Create the build directory structure
    repo = self.repos.getRepo('base')
    downloadUrl = repo.urls[0]

    # Create the build directory structure
    for x in [ os.path.basename(self.pkgdir), 'images/pxeboot', 'isolinux', 'ks', 'scripts' ]:
      mkdir(os.path.join(self.imgdir, x))

    if self.distroversion.startswith("5"):
      mkdir(os.path.join(self.imgdir, 'images', 'xen'))

    self.logger.info("Created %s directory structure" % self.builddir)
    self.logger.info("Using %s for downloads" % downloadUrl)

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

    if self.distroversion.startswith("5"):
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
        self.chunked_download(downloadUrl + x,
                              os.path.join(self.imgdir, x))

  def getImageFiles(self):
    repo = self.repos.getRepo('base')
    downloadUrl = repo.urls[0]

    imgfileset = set([
                      'pxeboot/vmlinuz',
                      'pxeboot/initrd.img'
                     ])

    if self.distroversion.startswith("5"):
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
        self.chunked_download(downloadUrl + 'images/' + x,
                              os.path.join(self.imgdir, 'images', x))

  def makeUpdatesImg(self):
    sudo = []
    # Fix anaconda bugs to allow copying files from CD during %post
    # scripts in EL5, and network prompting in EL6
    updatesdir = os.path.join(self.builddir, 'updates')
    mkdir(os.path.join(self.imgdir, 'images'))
    updatesimg = os.path.join(self.imgdir, 'images', 'updates.img')

    if self.distroversion.startswith("5"):
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
    elif self.distroversion.startswith("6"):
      if os.path.exists(updatesdir):
        shutil.rmtree(updatesdir)
      shutil.copytree(os.path.join(self.basedir, 'anaconda-updates', self.distroversion[0]), updatesdir)
      pixmapDir = os.path.join(updatesdir, 'pixmaps')
      mkdir(pixmapDir)
      shutil.copyfile(self.getLogo(), os.path.join(pixmapDir, 'splash.png'))
      if not os.path.exists(os.path.join(pixmapDir, 'progress_first.png')):
          os.link(os.path.join(pixmapDir, 'splash.png'),
                  os.path.join(pixmapDir, 'progress_first.png'))
      shutil.copyfile(self.getIcon(), os.path.join(pixmapDir, 'vendor-icon.png'))

      # The scripts directory is really a catch-all here
      scriptsDir = os.path.join(updatesdir, 'scripts')
      if not os.path.exists(scriptsDir):
          os.mkdir(scriptsDir)
      self.getKexecFiles(scriptsDir)
      self.writeMetadata(scriptsDir)
      self.getAmiCreator(scriptsDir)
      self.getSCE(updatesdir)
      shutil.copyfile(os.path.join(self.basedir, 'scripts', 'eucalyptus-nc-config.sh'),
                      os.path.join(scriptsDir, 'eucalyptus-nc-config.sh'))

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

  def writeMetadata(self, path):
    # Write some info to identify this installer
    f = open(os.path.join(path, 'silvereye-release'), 'w')
    commit = "unknown"
    if os.path.exists(os.path.join(self.basedir, '.git')):
      p = subprocess.Popen(['git','rev-parse','HEAD'], stdout=subprocess.PIPE)
      commit = p.communicate()[0].strip()
    f.write('commit=%s\n' % commit)
    f.write('version=%s\n' % self.eucaversion) 
    f.close()

  def createKickstartFiles(self):
    # Create kickstart files
    ksdest = os.path.join(self.imgdir, 'ks')
    ksTmplDir = os.path.join(self.basedir, 'ks_templates')
    for ks in os.listdir(ksTmplDir):
      dest = open(os.path.join(ksdest, ks), 'w')
      for line in open(os.path.join(ksTmplDir, ks), 'r').readlines():
        if self.distroversion.startswith("6"):
          if line.strip() in [ 'dbus-python', 'kernel-xen', 'libxml2-python',
                               'xen', '-kernel' ]:
            continue
          elif re.match('network .*query', line):
            continue
        # elif self.eucaversion == 'nightly' and line.startswith('eucalyptus-release'):
        #   dest.write("eucalyptus-release-nightly\n")
        #   continue
        dest.write(line)

  def getKexecFiles(self, dest):
    urlRE = re.compile(r'(https?|ftp)://')
    if urlRE.match(self.kexec_kernel):
      self.chunked_download(self.kexec_kernel, os.path.join(dest, 'vmlinuz-kexec'))
    else:
      shutil.copyfile(self.kexec_kernel, os.path.join(dest, 'vmlinuz-kexec'))

    if urlRE.match(self.kexec_initramfs):
      self.chunked_download(self.kexec_initramfs, os.path.join(dest, 'initramfs-kexec'))
    else:
      shutil.copyfile(self.kexec_initramfs, os.path.join(dest, 'initramfs-kexec'))

  def getAmiCreator(self, dest):
    self.chunked_download('https://raw.github.com/eucalyptus/ami-creator/master/ami_creator/ami_creator.py', 
                     os.path.join(dest, 'ami_creator.py'))

  def getSCE(self, dest):
    if self.sce:
      if not os.path.exists(self.sce):
        raise Exception("Specified path %s does not exist" % self.sce)
      if os.path.exists(os.path.join(self.sce, 'src')):
        self.sce = os.path.join(self.sce, 'src')
    else:
      os.system('git clone https://github.com/eucalyptus/system-config-eucalyptus.git %s' %
                os.path.join(self.builddir, 'system-config-eucalyptus'))
      self.sce = os.path.join(self.builddir, 'system-config-eucalyptus', 'src')
      
    mkdir(os.path.join(dest, 'system_config_eucalyptus'))
    for x in glob.glob(os.path.join(self.sce, '*.py')):
      shutil.copyfile(x, os.path.join(dest, 'system_config_eucalyptus', os.path.basename(x)))
    shutil.copyfile(os.path.join(self.sce, 'euca_gui.glade'),
                    os.path.join(dest, 'ui', 'euca_gui.glade'))

  # Configure yum repositories
  def setupRepo(self, repoid, pkgname=None, ignoreHostCfg=False, mirrorlist=None, baseurl=None):
    if ignoreHostCfg and self.repos.repos.has_key(repoid):
      self.logger.info("Removing host configuration for %s" % repoid)
      self.repos.delete(repoid)

    # We were checking for whether the release package was installed,
    # but that will only matter if we try to grab GPG keys
    if not self.repos.repos.has_key(repoid):
      self.logger.info("Adding repo %s at %s" % (repoid, mirrorlist and mirrorlist or baseurl))
      newrepo = yum.yumRepo.YumRepository(repoid)
      newrepo.enabled = 1
      newrepo.gpgcheck = 0  # This is because we aren't installing the key.  Fix this.
      newrepo.enablegroups = 1
      if mirrorlist:
        newrepo.mirrorlist = mirrorlist
      else:
        newrepo.baseurl = baseurl
      self.repos.add(newrepo)

  def setupRequiredRepos(self, repoMap=None):
    if repoMap is None:
        repoMap = {}

    # Install/configure CentOS repos
    if repoMap.has_key('centos'):
      self.setupRepo('base', baseurl='%s/%s/os/%s' % (repoMap['centos'], 
                     self.distroversion, self.conf.yumvar['basearch']),
                     ignoreHostCfg=True)
      self.setupRepo('updates', baseurl='%s/%s/updates/%s' % (repoMap['centos'], 
                     self.distroversion, self.conf.yumvar['basearch']),
                     ignoreHostCfg=True)
    # ...else we just keep the defaults

    # Install/configure EPEL repository
    if repoMap.has_key('epel'):
      self.setupRepo('epel',
                     baseurl=repoMap['epel'],
                     ignoreHostCfg=True)
    else:
      self.setupRepo('epel', 'epel-release',
                   mirrorlist="http://mirrors.fedoraproject.org/mirrorlist?repo=epel-%s&arch=%s" % 
                   (self.distroversion, self.conf.yumvar['basearch']))

    # Install/configure ELRepo repository
    if repoMap.has_key('elrepo'):
      self.setupRepo('elrepo', 
                     baseurl=repoMap['elrepo'],
                     ignoreHostCfg=True)
    else:
      self.setupRepo('elrepo', 'elrepo-release',
                   mirrorlist="http://elrepo.org/mirrors-elrepo.el%s" % self.distroversion[0])

    # Install/configure Eucalyptus repository
    # TODO:  Make sure the yum configuration pulls packages that match the requested release?
    # We should disable repos that might interfere with downloading the correct packages
    if repoMap.has_key('eucalyptus'): 
      self.setupRepo('eucalyptus',
                     baseurl=repoMap['eucalyptus'],
                     ignoreHostCfg=True)
    elif self.eucaversion == "nightly":
      self.setupRepo('eucalyptus', 'eucalyptus-release',
                     ignoreHostCfg=True,
                     baseurl="http://downloads.eucalyptus.com/software/eucalyptus/nightly/3.4/centos/%s/%s/" % 
                     (self.distroversion[0], self.conf.yumvar['basearch']))
    else:
      self.setupRepo('eucalyptus', 'eucalyptus-release',
                     ignoreHostCfg=True,
                     baseurl="http://downloads.eucalyptus.com/software/eucalyptus/%s/centos/%s/%s/" % 
                     (self.eucaversion, self.distroversion[0], self.conf.yumvar['basearch']))

    # Install euca2ools repository
    if repoMap.has_key('euca2ools'):
      self.setupRepo('euca2ools',
                     baseurl=repoMap.get('euca2ools'),
                     ignoreHostCfg=True)
    else:
      self.setupRepo('euca2ools', 'euca2ools-release',
                   baseurl="http://downloads.eucalyptus.com/software/euca2ools/3.0/centos/%s/%s/" % 
                   (self.distroversion[0], self.conf.yumvar['basearch']))

    # Install console repository
    #
    # Note that if the console repository is not specified on the command line
    # then we will not bother adding a repository. This package is normally
    # contained within the Eucalyptus repository.
    if repoMap.has_key('console'):
      self.setupRepo('console',
                     baseurl=repoMap.get('console'),
                     ignoreHostCfg=True)

  def downloadPackages(self):
    # Retrieve the RPMs for CentOS, Eucalyptus, and dependencies
    rpms = set()
    for groupList in self.doGroupLists():
      for x in groupList:
        if x.name in ['Core', 'X Window System', 'Desktop', 'Fonts']:
          rpms.update(x.packages)

    rpms.update(['centos-release', 'epel-release', 'euca2ools-release',
                 'authconfig', 'fuse-libs', 'gpm', 'libsysfs', 'mdadm',
                 'ntp', 'postgresql-libs', 'prelink', 'setools',
                 'system-config-network-tui', 'tzdata', 'tzdata-java',
                 'udftools', 'unzip', 'wireless-tools', 'livecd-tools',
                 'eucalyptus', 'eucalyptus-admin-tools', 'eucalyptus-cc',
                 'eucalyptus-cloud', 'eucalyptus-common-java',
                 'eucalyptus-console', 'eucalyptus-load-balancer-image', 
                 'eucalyptus-gl', 'eucalyptus-nc', 'eucalyptus-sc',
                 'eucalyptus-walrus', 'eucalyptus-release' ])

    # These are specifically for the EMI
    rpms.update(['cloud-init', 'system-config-securitylevel-tui',
                 'system-config-firewall-base', 'acpid'])

    # Add desktop bits.  Do we want a build flag to ignore this?
    rpms.update(['firefox'])

    # Useful tools
    rpms.update(['tcpdump', 'strace', 'man'])

    if self.distroversion == "6":
      rpms.update(['ntpdate', 'libvirt-client', 'elrepo-release', 
                   'iwl6000g2b-firmware', 'sysfsutils'])

    # Monitoring
    rpms.update(['nrpe', 'nagios-plugins-all', 'nagios'])

    # Download the base rpms
    self.logger.info("Retrieving Packages")

    if self.conf.yumvar['basearch'] == 'x86_64':
      self.conf.exclude.append('*.i?86')
    self.conf.assumeyes = 1
    if self.distroversion.startswith("6"):
      self.conf.releasever = self.distroversion[0]
      self.conf.plugins=1
    yumconf = os.path.join(self.builddir, 'yum.conf')
    self.conf.write(open(yumconf, 'w'))

    # TODO: convert this to API?
    if self.distroversion.startswith("6"):
      subprocess.call(['yumdownloader', 'centos-release'],
                      stdout=self.cmdout, stderr=self.cmdout)
      centospkg = glob.glob('centos-release-*')[0]
      subprocess.call(['rpm', '-iv', '--nodeps', '--justdb', '--root',
                           self.builddir, centospkg],
                      stdout=self.cmdout, stderr=self.cmdout)

    yumrepodir = os.path.join(self.builddir, 'etc', 'yum.repos.d')
    mkdir(yumrepodir)
    for repoid in ['base', 'updates', 'epel', 'elrepo', 'eucalyptus', 'euca2ools', 'console']:
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
      elif repoid == 'console':
          # We don't mind if there's no console repository
          pass
      else:
        raise Exception('repo %s not configured' % repoid)

    self.logger.info("Downloading packages")

    if not os.path.exists(os.path.join(self.imgdir, 'base')):
        os.symlink(self.pkgdir, os.path.join(self.imgdir, 'base'))
    for path in [ 'console', 'euca2ools', 'epel', 'elrepo', 'eucalyptus', 'updates' ]:
        mkdir(os.path.join(self.imgdir, path))

    subprocess.call([os.path.join(self.basedir, 'scripts', 'yumdownloader'), 
                     '-c', yumconf,
                     '--resolve', '--installroot', self.builddir,
                     '--destdir', self.imgdir, '--splitbyrepo',
                     '--releasever', '6' ] + list(rpms),
                      stdout=self.cmdout, stderr=self.cmdout) 

    # Call again to dep close Packages dir from 6.3 base
    subprocess.call([os.path.join(self.basedir, 'scripts', 'yumdownloader'), 
                     '-c', yumconf,
                     '--disablerepo', 'updates',
                     '--resolve', '--installroot', self.builddir,
                     '--destdir', self.imgdir, '--splitbyrepo',
                     '--releasever', '6' ] + list(rpms),
                      stdout=self.cmdout, stderr=self.cmdout) 

  # Create a repository
  def createRepo(self):
    compsfile = os.path.join(self.builddir, 'comps.xml')

    # write merged comps
    self.comps.add(os.path.join(self.basedir, 'comps.xml'))
    if not self.comps.has_group('eucalyptus-cloud-controller'):
        raise Exception, "eucalyptus-cloud-controller not found in comps"
    open(compsfile, 'w').write(self.comps.xml())

    self.logger.info("Creating repodata")
    retcode = subprocess.call(['createrepo', '-u', 'media://' + self.datestamp, '-o', self.imgdir,
                     '-g', compsfile, 
                     '-x', 'console/*',
                     '-x', 'eucalyptus/*',
                     '-x', 'euca2ools/*',
                     '-x', 'epel/*',
                     '-x', 'elrepo/*',
                     '-x', 'base/*',
                     '-x', 'updates/*',
                     self.imgdir ],
                      stdout=self.cmdout, stderr=self.cmdout)
    if retcode:
      raise Exception("creatrepo failed!!")

    self.logger.info("Base repo created")
    for repo in [ 'console', 'eucalyptus', 'euca2ools', 'epel', 'elrepo', 'updates' ]:
        retcode = subprocess.call(['createrepo', 
                                   '-o', os.path.join(self.imgdir, repo),
                                   os.path.join(self.imgdir, repo) ],
                                   stdout=self.cmdout, stderr=self.cmdout)
        if retcode:
            raise Exception("creatrepo failed!!")

  # Create boot logo
  def getLogo(self):
    tmplogo = os.path.join(self.builddir, 'splash.png')

    if os.path.exists(tmplogo):
      return tmplogo

    if self.release:
      opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(self.cookieJar))
      #self.getWikiCreds(opener)
      logo_url='https://s3.amazonaws.com/euca-silvereye/silvereye-logo.png'
      handle = opener.open(logo_url)
      open(tmplogo, 'w').write(handle.read())
    else:
      # AgI logo (CC BY-SA 3.0) via Activism1234 on Wikipedia
      self.chunked_download(urllib2.Request('http://upload.wikimedia.org/wikipedia/commons/f/f5/Silver_Iodide_Balls_and_Sticks.png', None, { 'User-agent' : 'Mozilla/4.0 (compatible; Silvereye 3; Linux)'}),
                      os.path.join(self.builddir, 'logo.png'))
      subprocess.call(['convert', os.path.join(self.builddir, 'logo.png'),
                       '-transparent', 'white', tmplogo])

    return tmplogo

  def getIcon(self):
    tmp_icon = os.path.join(self.builddir, 'tmp_icon.png')
    icon = os.path.join(self.builddir, 'icon.png')

    if os.path.exists(icon):
      return icon

    if self.release:
      opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(self.cookieJar))
      #self.getWikiCreds(opener)
      icon_url='https://s3.amazonaws.com/euca-silvereye/euc-017_favicon_fnl.jpg'
      handle = opener.open(icon_url)
      open(tmp_icon, 'w').write(handle.read())
    else:
      tmp_icon = self.getLogo()

    subprocess.call(['convert', '-resize', '48x45!', tmp_icon, icon ])
    return icon

  def getWikiCreds(self, opener):
    if len([ y for x,y in enumerate(self.cookieJar) 
             if y.domain=='wiki.eucalyptus-systems.com' ]) < 2:
      import getpass
      user = getpass.getuser()
      prompt = 'Dokuwiki username [%s]: ' % user
      newuser = raw_input(prompt)
      if len(newuser):
        user = newuser
      password = getpass.getpass('DokuWiki password: ')
      txdata = urlencode(dict([('u', user), ('p', password),
                               ('id', 'start'), ('do', 'login'),
                              ]))
      txheaders = { 'User-agent' : 'Mozilla/4.0 (compatible; Silvereye 3; Linux)'}
      req = urllib2.Request('https://wiki.eucalyptus-systems.com/doku.php' , txdata, txheaders)
      handle = opener.open(req)
      data = handle.read()
      self.cookieJar.save( ignore_discard=True )
    return opener
   
  def createBootLogo(self):
    self.logger.info("Creating boot logo")
    # It would be nice to do all of the ImageMagick stuff with PIL, but I don't know how.
    os.environ['ELVERSION'] = self.distroversion[0]
    os.environ['BUILDDIR'] = self.builddir
    os.environ['LOGOFILE'] = self.getLogo()

    tmplogodir = os.path.join(self.builddir, 'tmplogo')
    mkdir(tmplogodir)
    retcode = subprocess.call([os.path.join(self.basedir, 'scripts', 'create_silvereye_boot_logo.sh')], 
                      stdout=self.cmdout, stderr=self.cmdout, cwd=tmplogodir)
    shutil.rmtree(tmplogodir)

  # Replace the boot menu
  def createBootMenu(self):
    bootcfgdir = os.path.join(self.basedir, 'isolinux', self.distroversion[0])
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
    sudo = []

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
    if self.distroversion.startswith("5"):
      subprocess.call(["/usr/lib/anaconda-runtime/implantisomd5", self.isofile],
                      stdout=self.cmdout, stderr=self.cmdout)
    else:
      subprocess.call(["/usr/bin/implantisomd5", self.isofile],
                      stdout=self.cmdout, stderr=self.cmdout)
    self.logger.info("CD image " + self.isofile + " successfully created")

if __name__ == "__main__":
  cli = SilvereyeCLI()
  cli.run()
