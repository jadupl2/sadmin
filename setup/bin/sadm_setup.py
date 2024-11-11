#!/usr/bin/env python3  
# ==================================================================================================
#   Author      :   Jacques Duplessis
#   Date        :   2017-09-09
#   Name        :   sadm_setup.py
#   Synopsis    :   Install SADMIN tools (Client or Server) on system.
#   License     :   You can redistribute it or modify under the terms of GNU General Public 
#                   License, v.2 or above.
# ==================================================================================================
#    2016-2017 Jacques Duplessis <sadmlinux@gmail.com>
#
#   The SADMIN Tool is a free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <https://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2018_01_18    v1.0 Initial Version
# 2018_04_06    v1.6 Running SADM Scripts at the end of setup to feed DN and Web Interface
# 2018_04_14    v1.7 Commands fping and arp-scan are now part of requirement for web network report page
# 2018_04_24    v1.8 Ubuntu 16.04 Server - Missing Apache2 Lib,Network Collection Added,Install Non-Interactive
# 2018_04_27    v1.9 Tested on Ubuntu 18.04 Server - Minor fix 
# 2018_04_30    v2.1 Enhance user experience, re-tested Ubuntu 18.04,16.04 Server/Desktop,RedHat/CentOS7,Debian9 
# 2018_05_01    v2.2 Fix Bugs after Testing on Fedora 27
# 2018_05_03    v2.3 Fix Bugs fix with pip3 installation, firewalld setting check added
# 2018_05_05    v2.4 Database Standard User Password are now recorded in .dbpass
# 2018_06_03    v2.5 Change name of sadm_dr_fs_save_info.sh ,Put Backup in comment in client crontab
# 2018_06_11    v2.6 Add SADMIN=$SADMIN in /etc/environment - Needed when ssh from server to client
# 2018_06_14    v2.7 Remove client & server crontab entry not needed
# 2018_06_19    v2.8 Change way to get current domain name
# 2018_06_25    sadm_setup.py   v2.9 Add log to client sysmon crontab line & change ending message
# 2018_06_29    sadm_setup.py   v3.0 Bux Fixes (Re-Test on CentOS7,Debian9,Ubuntu1804,Raspbian9)
# 2018_07_08    v3.1 Correct Index Error (due to hostname without domain) when entering Domain Name
# 2018_07_13    v3.2 Added "SADMIN=..." Line to SADM server/client crontab 
# 2018_07_15    v3.3 Refuse SADM ServerName if resolve to localhost, Fix Server Crontab,
# 2018_07_21    v3.4 Remove Some validation of SADMIN Server Name
# 2018_07_30    v3.5 Add line 'Defaults !requiretty' to sudo file,so script can use sudo in crontab.
# 2018_08_29    v3.6 https://sadmin.YourDomain is now the standard to access sadmin web Site.
# 2018_10_28    v3.7 Linefeed was missing in file '/etc/sudoers.d/033_sadmin-nopasswd'
# 2018_11_24    v3.8 Added -e '' options for sadmin user creation
# 2018_12_11    V3.9 When installing server, default alert group is set to sysadmin email.
# 2019_01_03    Changed: sadm_setup.py V3.10 - Adapt crontab for MacOS and Aix, Setup Postfix
# 2019_01_25 Fix: v3.11 Fix problem with crash and multiple change to simplify process.
# 2019_01_28 Added: v3.12 For security reason, assign SADM_USER a password during installation.
# 2019_01_29 Added: v3.13 SADM_USER Home Directory is /home/SADM_USER no longer the install Dir.
# 2019_02_25 Added: v3.14 Reduce output on initial execution of daily scripts.
# 2019_03_08 Change: v3.15 Change related to RHEL/CentOS 8 and change some text messages.
# 2019_03_17 Change: v3.16 Perl DateTime module no longer a requirement.
# 2019_03_17 Change: v3.17 Default installation server group is 'Regular' instead of 'Service'.
# 2019_03_17 smtp.gmail.comUpdate: v3.21 Password for User sadmin and squery wasn't updating properly .dbpass file.
# 2019_04_15 Fix: v3.22 File /etc/environment was not properly updated under certain condition.
# 2019_04_15 Fix: v3.23 Fix 'squery' database user password typo error.
# 2019_04_18 Update: v3.24 Release 0.97 Re-tested with Ubuntu version.
# 2019_04_18 Fix: v3.25 Release 0.97 Re-tested with CentOS/RedHat version.
# 2019_06_19 Update: v3.26 Ask for sadmin Database password until it's valid.
# 2019_06_21 Update: v3.27 Ask user 'sadmin' & 'squery' database password until it's valid.
# 2019_06_25 Update: v3.28 Modification of the text displayed at the end of installation.
# 2019_07_04 Update: v3.29 Crontab client and Server definition revised for Aix and Linux.
# 2019_08_25 Update: v3.30 On Client setup Web USer and Group in sadmin.cfg to sadmin user & group.
# 2019_10_30 Update: v3.31 Remove installation of 'facter' package (Depreciated).
# 2019_12_18 Fix: v3.32 Fix problem when inserting server into database on Ubuntu/Raspbian.
# 2019_12_20 Update: v3.33 Remove installation of ruby (was used for facter) & of pymysql (Done)
# 2020_03_08 Update: v3.34 Added 'hwinfo' package to installation requirement.
# 2020_03_16 Update: v3.35 Set default alert group to sysadmin email in .alert_group.cfg. 
# 2020_04_19 Update: v3.36 Minor adjustments.
# 2020_04_21 Update: v3.37 Add syslinux,genisomage,rear packages req. & hwinfo to EPEL(RHEL/CentOS8)
# 2020_04_23 Update: v3.38 Fix Renaming Apache config error.
# 2020_04_27 Usmtp.gmail.compdate: v3.42 Minor script changes.
# 2020_07_11 Update: v3.43 Added rsync package to client installation. 
# 2020_09_05 Update: v3.44 Minor change to sadm_client crontab file.
# 2020_11_09 New: v3.45 Add Daily Email Report to crontab of sadm_server.
# 2020_11_15 Update: v3.46 'wkhtmltopdf' package was added to server installation.
# 2020_12_21 Update: v3.47 Bypass installation of 'ReaR' on Arm platform (Not available).
# 2020_12_21 Update: v3.48 Bypass installation of 'syslinux' on Arm platform (Not available).
# 2020_12_23 Fix: v3.49 Fix typo error.
# 2020_12_24 Update: v3.50 CentOSStream return CENTOS.
# 2020_12_27 Fix: v3.51 Fix problem with 'rear' & 'syslinux' when installing SADMIN server.
# 2021_01_06 Update: v3.52 Ensure that package util-linux is installed on client & server.
# 2021_01_27 Update: v3.53 Activate Startup and Shutdown Script (SADMIN Service)
# 2021_04_19 Update: v3.54 Fix Path to sadm_service_ctrl.sh
# 2021_06_06 Update: v3.55 Add to sadm_client crontab, script to make sure 'nmon' is running
# 2021_06_30 Update: v3.56 Adjust Client, Server crontab with documentation
# 2021_07_20 install: v3.57 Fix sadmin.service configuration problem.
# 2021_07_20 install: v3.58 Bug fix when installing SADMIN server 'mysql' packages.
# 2021_07_20 install: v3.59 Update alert group file, default now assigned to 'mail_sysadmin' group.
# 2021_07_20 install: v3.60 Client package to install changed from 'util-linux-ng' to 'util-linux'.
# 2021_07_21 install: v3.61 Fix server install problem on rpm system with package 'php-mysqlnd'.
# 2021_07_21 install: v3.62 Fix 'srv_rear_ver' field didn't have a default value in Database.
# 2021_11_07 install: v3.63 Remove SADM_RRDTOOL variable from sadmin.cfg (depreciated).
# 2022_04_11 install v3.64 Use /etc/os-release file to get O/S info ('lsb_release' depreciated).
# 2022_04_16 install v3.65 Updated for RHEL, Rocky, AlmaLinux and CentOS 9.
# 2022_04_19 install v3.66 Fixes for setup on CentOS 9.
# 2022_05_03 install v3.67 Ask info about smtp server information to send email from Python library.
# 2022_05_04 install v3.68 Added modification to 'postfix' config file (After making a backup).
# 2022_05_06 install v3.69 Improve 'postfix' configuration and update password file 'sasl_passwd'.
# 2022_05_06 install v3.70 Change finger information for root ('sadmin' replace 'root' in email)
# 2022_05_10 install v3.71 Remove installation of mail command & add 'inxi' command for sysInfo.
# 2022_05_26 install v3.72 Minor modification to question asked while installing 'sadmin'.
# 2022_05_27 install v3.73 Fix for AlmaLinux, problem with blank line in /etc/os-release.
# 2022_05_28 install v3.74 Add firewall rule if SSH port specified is different than 22.
# 2022_06_01 install v3.75 Add some 'SELinux' comments at the end of the installation.
# 2022_06_10 install v3.76 Update some parameters at the end of '/etc/postfix/main.cf' file.
# 2022_06_18 install v3.77 Fix SSH port setting problem during installation on AlmaLinux v9.
# 2022_07_02 install v3.78 Fix input problem related to smtp server data.
# 2022_07_19 install v3.79 Update of the commands requirements.
# 2023_02_08 install v3.80 Default smtp mail server is now 'smtp.gmail.com' and hide smtp password.
# 2023_04_04 install v3.81 Access to sadmin web interface is now done using https.
# 2023_04_29 install v3.82 Ensure that 'coreutils' package are installed.
# 2023_05_19 install v3.83 Make sure 'isohybrid' is installed (Needed to produce ReaR bootable USB).
# 2023_05_20 install v3.84 Add 'extlinux' package to client that is sometime used by ReaR backup.
# 2023_06_03 install v3.85 Fix intermittent problem when validating the FQDN of the SADMIN server.
# 2023_06_03 install v3.86 Daily email report is now depreciated, the web interface have all info.
# 2023_06_05 install v3.87 Minor corrections after testing installation on Debian 11.
# 2023_06_20 install v3.88 Add $SADMIN/usr/bin to sudo secure path.
# 2023_07_09 install v3.89 Update sadmin web server config for Debian 12.
# 2023_07_12 install v3.90 Initial 'sadm_client' crontab, now use python ver. of 'sadm_nmon_watcher'.
# 2023_07_16 install v3.91 Ask for the SADMIN server IP instead of FQDN.
# 2023_07_26 install v3.92 Adjust list of packages required to use 'ReaR' image backup (+xorriso).
# 2023_08_23 install v3.93 Package detection, was failing under certain condition.
# 2023_11_06 install v3.94 Misc. typo change & minor fixes.
# 2023_12_10 install v3.95 If not present, package 'nfs-utils (rpm) & 'nfs-common' (deb) are install.
# 2023_12_20 install v3.96 Package 'wkhtmltopdf' is no longer require (depreciated).
# 2023_12_20 install v3.97 Script 'sadm_daily_report.sh' remove from sadm_server crontab (depreciated).
# 2023_12_24 install v3.98 Make setup 'Alma' and 'Rocky' Linux aware.
# 2023_12_26 install v3.99 More comment added to 'sadm_client' & 'sadm_server' crontab file.
# 2023_12_27 install v4.00 If not present, package 'cron' (deb) 'cronie' (rpm) are install.
# 2024_01_04 install v4.01 Minor fixes.
# 2024_01_09 install v4.02 If not present, package 'grub2-efi-x64-modules' install (needed for ReaR).
# 2024_02_12 install v4.03 Execution of 'sadm_startup.sh & sadm_shutdown.sh' now controlled by 'sadmin.service'.
# 2024_02_12 install v4.03 Script 'sadm_service_ctrl.sh' is depreciated (Use 'systemctl').
# 2024_02_13 install v4.04 Setup will now ask for 'sadmin' user password & force to change it on login.
# 2024_02_15 install v4.05 Bug fix on postfix configuration & various corrections and enhancements.
# 2024_07_10 install v4.06 Minor changes and fixes.
# ==================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch,shutil,getpass  # Import Std Python3 Modules
    import subprocess 
    #from subprocess import Popen
    import pymysql, platform
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                        # Activate Python Debugging




#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
sver                = "4.06"                                            # Setup Version Number
pn                  = os.path.basename(sys.argv[0])                     # Program name
inst                = os.path.basename(sys.argv[0]).split('.')[0]       # Pgm name without Ext
phostname           = platform.node().split('.')[0].strip()             # Get current hostname
sadm_base_dir       = ""                                                # SADMIN Install Directory
conn                = ""                                                # MySQL Database Connector
cur                 = ""                                                # MySQL Database Cursor
DEBUG               = False                                             # Debug Activated or Not
DRYRUN              = False                                             # Don't Install, Print Cmd
#
sroot               = ""                                                # SADMIN Root Directory
stype               = ""                                                # C=Client S=Server Install
fhlog               = ""                                                # Log File Handle
logfile             = ""                                                # Log FileName
req_work            = {}                                                # Active Requirement Dict.

# Logic to get O/S Distribution Information into Dictionary os_dict
osrelease           = "/etc/os-release"                                 # Distribution Info file
os_dict             = {}                                                # Dict. for O/S Info
with open(osrelease) as f:                                              # Open /etc/os-release as f
    for line in f:                                                      # Process each line
        if len(line) < 2  : continue                                    # Skip empty Line
        if line[0].strip == "#" : continue                              # Skip line beginning with #
        k,v = line.rstrip().split("=")                                  # Get Key,Value of each line
        os_dict[k] = v.strip('"')                                       # Store info in Dictionnary

# Text Colors Attributes Class
class color:
    PURPLE      = '\033[95m'
    CYAN        = '\033[96m'
    DARKCYAN    = '\033[36m'
    BLUE        = '\033[94m'
    GREEN       = '\033[92m'
    YELLOW      = '\033[93m'
    RED         = '\033[91m'
    BOLD        = '\033[1m'
    UNDERLINE   = '\033[4m'
    END         = '\033[0m'

# Some package are only available on these platform
rear_supported_architecture     = ["i686","i386","x86_64","amd64"] 
syslinux_supported_architecture = ["i686","i386","x86_64","amd64"] 

# Supported Distribution by SADMIN
rhel_family   = ["RHEL","FEDORA","CENTOS","ALMA","ROCKY"]
debian_family = ["DEBIAN","UBUNTU","MINT","RASPBIAN"]

# Command and package require by SADMIN Client to work correctly
req_client = {}                                                         # Require Packages Dict.
req_client = { 
    'lsb_release':{ 'rpm':'lsb-release',                    'rrepo':'base',  
                    'deb':'lsb-release',                    'drepo':'base'},
    'crontab'    :{ 'rpm':'cronie',                         'rrepo':'base',  
                    'deb':'cron',                           'drepo':'base'},
    'nmon'       :{ 'rpm':'nmon',                           'rrepo':'epel',  
                    'deb':'nmon',                           'drepo':'base'},
    'ethtool'    :{ 'rpm':'ethtool',                        'rrepo':'base',  
                    'deb':'ethtool',                        'drepo':'base'},
    'coreutils'  :{ 'rpm':'coreutils',                      'rrepo':'base',  
                    'deb':'coreutils',                      'drepo':'base'},
    'dig'        :{ 'rpm':'bind-utils ',                    'rrepo':'base',  
                    'deb':'bind9-dnsutils',                 'drepo':'base'},
    'genisoimage':{ 'rpm':'genisoimage',                    'rrepo':'base',  
                    'deb':'genisoimage',                    'drepo':'base'},
    'rsync'      :{ 'rpm':'rsync',                          'rrepo':'base',  
                    'deb':'rsync',                          'drepo':'base'},
    'hwinfo'     :{ 'rpm':'hwinfo',                         'rrepo':'epel',  
                    'deb':'hwinfo',                         'drepo':'base'},
    'ifconfig'   :{ 'rpm':'net-tools',                      'rrepo':'base',  
                    'deb':'net-tools',                      'drepo':'base'},
    'sudo'       :{ 'rpm':'sudo',                           'rrepo':'base',  
                    'deb':'sudo',                           'drepo':'base'},
    'lshw'       :{ 'rpm':'lshw',                           'rrepo':'base',  
                    'deb':'lshw',                           'drepo':'base'},
    'mount.nfs'  :{ 'rpm':'nfs-utils',                      'rrepo':'base',  
                    'deb':'nfs-common',                     'drepo':'base'},
    'parted'     :{ 'rpm':'parted',                         'rrepo':'base',  
                    'deb':'parted',                         'drepo':'base'},
    'rear'       :{ 'rpm':'rear xorriso syslinux syslinux-extlinux grub2-efi-x64-modules', 'rrepo':'base',
                    'deb':'rear xorriso syslinux-utils extlinux'   , 'drepo':'base'},
    'mutt'       :{ 'rpm':'mutt',                           'rrepo':'base',
                    'deb':'mutt',                           'drepo':'base'},
    'gawk'       :{ 'rpm':'gawk',                           'rrepo':'base',
                    'deb':'gawk',                           'drepo':'base'},
    'bc'         :{ 'rpm':'bc',                             'rrepo':'base',  
                    'deb':'bc',                             'drepo':'base'},
    'curl'       :{ 'rpm':'curl',                           'rrepo':'base',  
                    'deb':'curl',                           'drepo':'base'},
    'inxi'       :{ 'rpm':'inxi',                           'rrepo':'base',  
                    'deb':'inxi',                           'drepo':'base'},
    'ssh'        :{ 'rpm':'openssh-clients',                'rrepo':'base',
                    'deb':'openssh-client',                 'drepo':'base'},
    'dmidecode'  :{ 'rpm':'dmidecode',                      'rrepo':'base',
                    'deb':'dmidecode',                      'drepo':'base'},
    'perl'       :{ 'rpm':'perl',                           'rrepo':'base',  
                    'deb':'perl-base',                      'drepo':'base'},
    'iostat'     :{ 'rpm':'sysstat',                        'rrepo':'base',  
                    'deb':'sysstat',                        'drepo':'base'},
    'apt-file'   :{ 'rpm':'none',                           'rrepo':'base',  
                    'deb':'apt-file',                       'drepo':'base'},
    'libwww'     :{ 'rpm':'perl-libwww-perl ',              'rrepo':'base',
                    'deb':'libwww-perl ',                   'drepo':'base'},
    'lscpu'      :{ 'rpm':'util-linux',                     'rrepo':'base',  
                    'deb':'util-linux',                     'drepo':'base'}
}

# Command and package require by SADMIN Server to work correctly
req_server = {}                                                         # Require Packages Dict.
req_server = { 
    'httpd'         :{ 'rpm':'httpd httpd-tools',                              'rrepo':'base',
                       'deb':'apache2 apache2-utils libapache2-mod-php ',      'drepo':'base'},
    'openssl'       :{ 'rpm':'openssl mod_ssl',                                'rrepo':'base',
                       'deb':'openssl',                                        'drepo':'base'},
    'rrdtool'       :{ 'rpm':'rrdtool',                                        'rrepo':'base',
                       'deb':'rrdtool',                                        'drepo':'base'},
    'fping'         :{ 'rpm':'fping',                                          'rrepo':'epel',
                       'deb':'fping monitoring-plugins-standard',              'drepo':'base'},
#    'arp-scan'      :{ 'rpm':'arp-scan',                                       'rrepo':'epel',
#                       'deb':'arp-scan',                                       'drepo':'base'},
    'php'           :{ 'rpm':'php php-common php-cli php-mysqlnd php-mbstring','rrepo':'base', 
                       'deb':'php php-common php-cli php-mysql php-mbstring',  'drepo':'base'},
    'mysql'         :{ 'rpm':'mariadb-server ',                                'rrepo':'base',
                       'deb':'mariadb-server mariadb-client',                  'drepo':'base'}
}


#===================================================================================================
# Ping the specified host (Return 0 if ping work else 1)
#===================================================================================================
def ping(host):
    param = "-n" if platform.system().lower() == "windows" else "-c"
    command = ["ping", param, "1", host]
    return subprocess.call(command) == 0

#===================================================================================================
#                   Print [ERROR] in Red, followed by a the message received
#===================================================================================================
def printError(emsg):
    print ( color.RED + color.BOLD + "[ERROR] " + emsg + color.END)

#===================================================================================================
#                  Print [WARNING] in Red, followed by a the message received
#===================================================================================================
def printWarning(emsg):
    print ( color.YELLOW + color.BOLD + "[WARNING] " + emsg + color.END)

#===================================================================================================
#                   Print [OK] in Yellow, followed by a the message received
#===================================================================================================
def printOk(emsg):
    print ( color.GREEN + color.BOLD + "[OK] " + emsg + color.END)

#===================================================================================================
#                           Print the message received in Bold
#===================================================================================================
def printBold(emsg):
    print ( color.DARKCYAN + color.BOLD + emsg + color.END)

#===================================================================================================
#           Print the message received & Ask for Yes (Return True) or No (Return False)
#===================================================================================================
def askyesno(emsg,sdefault="Y"):
    while True:
        wmsg = emsg + " (" + color.DARKCYAN + color.BOLD + "Y/N" + color.END + ") " 
        wmsg += "[" + sdefault + "] ? "
        wanswer = input(wmsg)
        if (len(wanswer) == 0) : wanswer=sdefault
        if ((wanswer.upper() == "Y") or (wanswer.upper() == "N")):
            break
        else:
            print ("Please respond by 'Y' or 'N'\n")
    if (wanswer.upper() == "Y") : 
        return True
    else:
        return False
        
#===================================================================================================
#                       Open the Script Log File in $SADMIN/log Directory
#===================================================================================================
def open_logfile(sroot):
    global fhlog                                                        # Need to share file Handle

    # Make sure log Directory exist
    try:                                                                # Catch mkdir error
        os.mkdir ("%s/setup/log" % (sroot),mode=0o777)                  # Make ${SADMIN}/log dir.
    except FileExistsError as e :                                       # If Dir. already exists 
        pass                                                            # It's ok if it exist

    # Setup the name of the Log file
    logfile = "%s/setup/log/%s.log" % (sroot,'sadm_setup')              # Set Log file name
    if (DEBUG) : print ("Open the log file %s" % (logfile))             # Debug, Show Log file

    # Open the Script log in append mode (setup.sh create the log, don't want to erae it)
    try:                                                                # Try to Open/Create Log
        fhlog=open(logfile,'a')                                         # Open Log File 
    except IOError as e:                                                # If Can't Create Log
        print ("Error creating log file %s" % (logfile))                # Print Log FileName
        print ("Error Number : {0}".format(e.errno))                    # Print Error Number    
        print ("Error Text   : {0}".format(e.strerror))                 # Print Error Message
        sys.exit(1)                                                     # Exit with Error
    
    writelog ("SADMIN Setup V%s\n------------------" % (sver),'log')    # Print Version Number
    return (fhlog,logfile)                                              # Return File Handle



#===================================================================================================
#                           Write Log to Log File, Screen or Both
#===================================================================================================
def writelog(sline,stype="normal"):
    global fhlog                                                        # Need to share file handler
    fhlog.write ("%s\n" % (sline))                                      # Write Line to Log 
    if (stype == "log") : return                                        # Log Only,Nothing on screen   

    # Display Line on Screen
    if (stype == "normal") : 
        print (sline)  
    if (stype == "nonl") : 
        print (sline,end='') 
    if (stype == "bold") : 
        print ( color.DARKCYAN + color.BOLD + sline + color.END)




#===================================================================================================
#                                    RUN O/S COMMAND FUNCTION
#===================================================================================================
def oscommand(command) :
    if DEBUG : print ("In sadm_oscommand function to run command : %s" % (command))
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out = p.stdout.read().strip().decode()
    err = p.stderr.read().strip().decode()
    returncode = p.wait()
    if (DEBUG) :
        print ("In sadm_oscommand function stdout is      : %s" % (out))
        print ("In sadm_oscommand function stderr is      : %s " % (err))
        print ("In sadm_oscommand function returncode is  : %s" % (returncode))
    #if returncode:
    #    raise Exception(returncode,err)
    #else :
    return (returncode,out,err)


# ----------------------------------------------------------------------------------------------
# RETURN THE OS TYPE (LINUX,AIX or DARWIN ) -- ALWAYS RETURNED IN UPPERCASE
# ----------------------------------------------------------------------------------------------
def get_ostype():
    ccode, cstdout, cstderr = oscommand("uname -s")
    wostype=cstdout.upper()
    return wostype


#===================================================================================================
#                              MAKE SURE SADMIN LINE IS IN /etc/hosts FILE
#===================================================================================================
def update_host_file(wdomain,wip) :

    writelog('')
    writelog('----------')
    writelog ("Adding 'sadmin.%s' to /etc/hosts file" % (wdomain),'bold')
    try : 
        hf = open('/etc/hosts','r+')                                    # Open /etc/hosts file
    except :
        writelog("Error Opening /etc/hosts file")
        sys.exit(1)

    # Add SADMIN server IP and name to /etc/hosts        
    eline = "%s     sadmin.%s     sadmin " % (wip,wdomain)              # Line to add to /etc/hosts
    found_line = False                                                  # Assume sadmin line not in
    for line in hf:                                                     # Read Input file until EOF
        if (eline.rstrip() == line.rstrip()):                           # Line already there    
            found_line = True                                           # Line is Found 
    if not found_line:                                                  # If line was not found
        hf.write ("#\n%s\n#\n" % (eline))                               # Write SADMIN line to hosts
    hf.close()                                                          # Close /etc/hosts file
    return()                                                            # Return Cmd Path


#===================================================================================================
#                            MAKE SURE SADMIN CLIENT CRONTAB FILE IS IN PLACE
#===================================================================================================
def update_client_crontab_file(logfile,sroot,wostype,wuser) :

    # Setup crontab filename
    if wostype == "LINUX" :                                             # Under Linux
        ccron_file = "/etc/cron.d/sadm_client"                          # Client Crontab File Name
        if not os.path.exists("/etc/cron.d") :                          # Test if Dir. Exist
            writelog("[ ERROR ] Crontab Directory /etc/cron.d doesn't exist ?",'bold')
            writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
            return(1)                                                   # Return to Caller with Err.
    if wostype == "AIX" :                                               # Under AIX
        ccron_file = "/var/spool/cron/crontabs/%s" % (wuser)            # Client Crontab File Name
        if not os.path.exists("/var/spool/cron/crontabs") :             # Test if Dir. Exist
            writelog("[ ERROR ] Crontab Directory /var/spool/cron/crontabs doesn't exist ?",'bold')
            writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
            return(1)                                                   # Return to Caller with Err.
    if wostype == "DARWIN" :                                            # Under MacOS 
        ccron_file = "/var/at/tabs/%s" % (wuser)                        # Crontab File on MacOS
        if not os.path.exists("/var/at/tabs") :                         # Test if Dir. Exist
            writelog("[ ERROR ] Crontab Directory /var/at/tabs doesn't exist ?",'bold')
            writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
            return(1)                                                   # Return to Caller with Err.

    # Check if crontab directory exist - Procedure may not be supported on this O/S
    writelog('')
    writelog('--------------------')
    writelog ("Creating SADMIN client crontab file (%s)" % (ccron_file),'bold')
    # If SADMIN old crontab file exist, delete it and recreate it
    try:                                                                # In case old file exist
        os.remove(ccron_file)                                           # Remove old crontab file
    except :                                                            # If not then it's OK
        pass                                                            # If don't exist continue
        
    # Create the SADMIN Client Crontab file
    try : 
        hcron = open(ccron_file,'w')                                    # Open Crontab file
    except :                                                            # If could not create output
        writelog("Error Opening %s file" % (ccron_file),'bold')         # Advise Usr couldn't create
        writelog("Could not create SADMIN crontab file")                # Crontab file not created
        return(1)

    # Populate SADMIN Client Crontab File
    hcron.write ("# SADMIN Client Crontab File \n")
    #hcron.write ("# Please don't edit manually, SADMIN Tools generated file\n")
    hcron.write ("# \n")
    hcron.write ("PATH=%s\n" % (os.environ["PATH"]))
    hcron.write ("SADMIN=%s\n" % (sroot))
    hcron.write ("# " + '\n')
    hcron.write ("# Min, Hrs, Date, Mth, Day, User, Script\n")
    hcron.write ("# Day 0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat\n")
    hcron.write ("#  " + '\n')
    hcron.write ("# Every 30 Min, this script make sure the 'nmon' performance collector is running.\n")
    hcron.write ("*/30 * * * *  %s sudo ${SADMIN}/bin/sadm_nmon_watcher.py > /dev/null 2>&1\n" % (wuser))
    hcron.write ("# " + '\n')
    hcron.write ("# sadm_client_sunset.sh, run these four scripts in sequence, just before midnight every day:\n")
    hcron.write ("# (1) sadm_housekeeping_client.sh (Make sure files in $SADMIN have proper owner:group & permission)\n")
    hcron.write ("# (2) sadm_dr_savefs.sh (Save lvm filesystems metadata to recreate them easily in Disaster Recovery)\n")
    hcron.write ("# (3) sadm_create_cfg2html.sh (Run cfg2html tool - Produce system configuration web page).\n")
    hcron.write ("# (4) sadm_create_sysinfo.sh (Collect hardware & software info of system to update SADMIN database).\n")
    hcron.write ("23 23 * * *  %s sudo ${SADMIN}/bin/sadm_client_sunset.sh > /dev/null 2>&1\n" % (wuser))
    hcron.write ("# " + '\n')

    # Insert line that run System monitor every 5 minutes.
    chostname = socket.gethostname().split('.')[0]
    cscript="sudo ${SADMIN}/bin/sadm_sysmon.pl" 
    clog=">${SADMIN}/log/%s_sadm_sysmon.log 2>&1" % (chostname)
    if wostype == "AIX" : 
        hcron.write ("# Run SADMIN System Monitoring every 5 minutes (*/5 Don't work on Aix)\n")
        hcron.write ("2,7,12,17,22,27,32,37,42,47,52,57 * * * * %s %s %s\n" % (wuser,cscript,clog))
        hcron.write ("# " + '\n')
        hcron.write ("# " + '\n')
    else:
        hcron.write ("# " + '\n')
        hcron.write ("# Run SADMIN System Monitoring every 5 minutes\n")
        hcron.write ("*/5 * * * * %s %s %s\n"  % (wuser,cscript,clog))
        hcron.write ("# " + '\n')
    hcron.close()                                                       # Close SADMIN Crontab file

    # Change Client Crontab file permission to 644
    cmd = "chmod 600 %s" % (ccron_file)                                 # chmod 644 on ccron_file
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chmod on ccron_file
    if (ccode == 0):                                                    # If chmod went ok
        writelog( "  - Client Crontab Permission changed successfully") # Show success
    else:                                                               # Did not went well
        writelog ("Problem changing Client crontab file permission")    # Had error on chmod cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    # Change Client Crontab file Owner and Group
    cmd = "chown %s.%s %s" % ('root','root',ccron_file)                 # chowner on ccron_file
    if wostype == "DARWIN" :                                            # Under MacOS 
        cmd = "chown %s.%s %s" % ('root','wheel',ccron_file)            # chownn ccron_file on MacOS
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chown on cron file
    if (ccode == 0):                                                    # If chown went ok
        writelog( "  - Ownership of client crontab changed successfully") # Show success to user
    else:                                                               # Did not went well
        writelog ("Problem changing ownership of client crontab file")  # Had an error on chown cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr


    # Show sadm_client cron file content
    #writelog ("Content of %s" % (ccron_file))
    #hcron = open(ccron_file,'r')
    #for line in hcron:                                                  # Read sadm_client cron
    #    writelog (line)                                                 # Write line to output file
    #hcron.close()

    return()                                                            # Return Cmd Path


#===================================================================================================
#                            MAKE SURE SADMIN SERVER CRONTAB FILE IS IN PLACE
#===================================================================================================
def update_server_crontab_file(logfile,sroot,wostype,wuser) :

    # Setup crontab on Linux 
    if wostype == "LINUX" :                                             # Under Linux
        ccron_file = "/etc/cron.d/sadm_server"                          # Server Crontab File Name
        if not os.path.exists("/etc/cron.d") :                          # Test if Dir. Exist
            writelog("Crontab Directory /etc/cron.d doesn't exist ?",'bold')
            writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
            return(1)                                                   # Return to Caller with Err.
        try:                                                            # In case old file exist
            os.remove(ccron_file)                                       # Remove old crontab file
        except :                                                        # If not then it's OK
            pass                                                        # If don't exist continue
        try :                                                           # Try Create New cron file
            hcron = open(ccron_file,'w')                                # Open Server Crontab file
        except :                                                        # If could not create output
            writelog("Error Opening %s file" % (ccron_file),'bold')     # Advise Usr couldn't create
            writelog("Could not create SADMIN crontab file")            # Crontab file not created
            return(1)

    # Setup crontab on Aix - Crontab Entries for SADMIN Client and Server goes in the same file.
    if wostype == "AIX" :                                               # Under AIX
        ccron_file = "/var/spool/cron/crontabs/%s" % (wuser)            # Client/Server Crontab File
        if not os.path.exists("/var/spool/cron/crontabs") :             # Test if Dir. Exist
            writelog("Crontab Directory /var/spool/cron/crontabs doesn't exist ?",'bold')
            writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
            return(1)                                                   # Return to Caller with Err.
        try :                                                           # Try Create New cron file
            hcron = open(ccron_file,'a+')                               # Open Append Server Crontab
        except :                                                        # If could not create output
            writelog("Error Opening %s file" % (ccron_file),'bold')     # Advise Usr couldn't create
            writelog("Could not append crontab file")                   # Crontab file not appended
            return(1)

    # Setup crontab on Aix - Crontab Entries for SADMIN Client and Server goes in the same file.
    if wostype == "DARWIN" :                                            # Under MacOS 
        ccron_file = "/var/at/tabs/%s" % (wuser)                        # Crontab File on MacOS
        if not os.path.exists("/var/at/tabs") :                         # Test if Dir. Exist
            writelog("Crontab Directory /var/at/tabs doesn't exist ?",'bold')
            writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
            return(1)                                                   # Return to Caller with Err.
        try :                                                           # Try Create New cron file
            hcron = open(ccron_file,'a+')                               # Open Append Server Crontab
        except :                                                        # If could not create output
            writelog("Error Opening %s file" % (ccron_file),'bold')     # Advise Usr couldn't create
            writelog("Could not append crontab file")                   # Crontab file not appended
            return(1)

    writelog('')
    writelog('--------------------')
    writelog("Creating SADMIN server crontab file (%s)" % (ccron_file),'bold')

    # Populate SADMIN Server Crontab File
    hcron.write ("# SADMIN Server Crontab File \n")
    #hcron.write ("# Please don't edit manually, SADMIN Tools generated file\n")
    hcron.write ("# " + '\n')
    hcron.write ("PATH=%s\n" % (os.environ["PATH"]))
    hcron.write ("SADMIN=%s\n" % (sroot))
    hcron.write ("# " + '\n')
    hcron.write ("# Min, Hrs, Date, Mth, Day, User, Script\n")
    hcron.write ("# 0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat\n")
    hcron.write ("# \n")
    hcron.write ("\n")
    #
    hcron.write ("# Rsync all *.rch,*.log,*.rpt files from all actives clients.\n")
    cscript="sudo ${SADMIN}/bin/sadm_fetch_clients.sh >/dev/null 2>&1"
    if wostype == "AIX" : 
        hcron.write ("# */5 don't work on Aix.\n")
        hcron.write ("4,10,16,22,28,34,40,46,52,58 * * * * %s %s\n" % (wuser,cscript))
    else:
        hcron.write ("*/5 * * * * %s %s\n" % (wuser,cscript))
    #
    cscript="sudo ${SADMIN}/bin/sadm_server_sunrise.sh >/dev/null 2>&1"
    hcron.write ("#\n")
    hcron.write ("# Daily & early in the morning the sunrise script is started.\n")
    hcron.write ("# This script collect information and performance data from active clients.\n")
    hcron.write ("# The SADMIN database is then updated with the latest data (Default is 5:08 am).\n")
    hcron.write ("08 05 * * * %s %s\n" % (wuser,cscript))
    #
    # Report email is now depreciated.
    #cscript="sudo ${SADMIN}/bin/sadm_daily_report.sh >/dev/null 2>&1"
    #hcron.write ("#\n")
    #hcron.write ("# Daily SADMIN Report by Email\n")
    #hcron.write ("07 07 * * * %s %s\n" % (wuser,cscript))    
    #hcron.write ("#\n")
    #
    cscript="sudo ${SADMIN}/bin/sadm_push_sadmin.sh >/dev/null 2>&1"
    hcron.write ("\n")
    hcron.write ("# Optional daily push of $SADMIN server version to all actives clients.\n")
    hcron.write ("# Will not erase any of your data or configuration files.\n")
    hcron.write ("# Good way to update version on some or all SADMIN clients.\n")
    hcron.write ("#   -n Push SADMIN version to the client host name you specify.\n")
    hcron.write ("#   -c Also $SADMIN/cfg/sadmin_client.cfg to active sadmin clients.\n")
    hcron.write ("#   -s Also push $SADMIN/sys to active sadmin clients.\n")
    hcron.write ("#   -u Also push $SADMIN/(usr/bin usr/lib usr/cfg) to active sadmin clients.\n")
    hcron.write ("#10 13,21 * * * %s %s\n" % (wuser,cscript))
    hcron.write ("#\n")
    #
    hcron.close()                                                       # Close SADMIN Crontab file

    # Change Server Crontab file permission to 644
    cmd = "chmod 644 %s" % (ccron_file)                                 # chmod 644 on ccron_file
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chmod on cron_file
    if (ccode == 0):                                                    # If chmod went ok
        writelog( "  - Server crontab permission changed successfully") # Show success
    else:                                                               # Did not went well
        writelog ("Problem changing Server crontab file permission")    # Had error on chmod cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    # Change Server Crontab file Owner and Group
    cmd = "chown %s.%s %s" % ('root','root',ccron_file)                 # chowner on ccron_file
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chown on cron_file
    if (ccode == 0):                                                    # If chown went ok
        writelog( "  - Ownership of server crontab changed successfully") # Show success to user
    else:                                                               # Did not went well
        writelog ("Problem changing ownership of Server crontab file")  # Had an error on chown cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    return()                                                            # Return Cmd Path




#===================================================================================================
# Install Python MySQL module Based on current System
#python3-PyMySQL
#===================================================================================================
def special_install(lpacktype,sosname,logfile) :

    if ((lpacktype != "deb") and (lpacktype != "rpm")):                 # Only rpm & deb Supported 
        writelog ("Package type invalid (%s)" % (lpacktype),'bold')     # Advise User UnSupported
        return (False)                                                  # Return False to caller

    # INSTALL PIP3 - IF 'pip3' ISN'T PRESENT ON SYSTEM (Installed by Default on RHEL/CentOS 8) -----
    writelog("Checking for python pip3 command ... ","nonl")
    if (locate_command('pip3') == "") :                                 # If pip3 command not found
        writelog("Installing python3 pip3")                             # Inform User - install pip3
        if (lpacktype == "deb"):                                        # Is Debian Style Package
            cmd =  "apt-get -y update >> %s 2>&1" % (logfile)           # Build Refresh Pack Cmd
            writelog ("Running apt-get -y update...","nonl")            # Show what we are running
            (ccode, cstdout, cstderr) = oscommand(cmd)                  # Run the apt-get command
            if (ccode == 0) :                                           # If command went ok
                writelog (" Done ")                                     # Print DOne
            else:                                                       # If we had error 
                writelog ("Error Code is %d" % (ccode))                 # Advise user of error     
            writelog ('Installing python3-pip',"nonl")                  # Show User Pkg Installing
            icmd = "DEBIAN_FRONTEND=noninteractive "                    # No Prompt While installing
            icmd += "apt-get -y install python3-pip >>%s 2>&1" % (logfile)
        else:                                                           # 
            if (sosname != "FEDORA"):                                   # On Redhat/CentOS
                writelog('Installing python34-pip from EPEL ... ',"nonl") # Need Help of EPEL Repo
                icmd = "yum install --enablerepo=epel -y python3-pip >>%s 2>&1" % (logfile)
            else:                                                       # On Fedora
                writelog ('Installing python3-pip ... ',"nonl")         # Inform User Pkg installing
                icmd="dnf install -y python3-pip >>%s 2>&1" % (logfile) # Fedora pip3 install cmd

        # Install pip3 command 
        if (DEBUG): writelog (icmd)                                     # Inform User Pkg installing
        ccode, cstdout, cstderr = oscommand(icmd)                       # Run Install Cmd for pip3
        if (ccode == 0) :                                               # If no problem installing
            writelog (" Done ")                                         # Show user it is done
        else:                                                           # If error while installing
            writelog("Error Code is %d - See log %s" % (ccode,logfile),'bold') # Show Err & Logname
            writelog ("stdout=%s stderr=%s" % (cstdout,cstderr))
    else:
        writelog("Done")


    # Install pymysql python3 module using pip3
    writelog ("Installing python3 PyMySQL module (pip3 install PyMySQL) ... ","nonl") 
    cmd = "pip3 install PyMySQL"                                        # Command to execute
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute Command 
    if (ccode == 0):                                                    # If install went ok
        writelog( " Done ")                                             # Show success to user
    else:                                                               # Did not went well
        writelog ("Problem Installing PyMysql Python module")           # Had an error on cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    return()                                                            # Return Cmd Path



#===================================================================================================
# MAKE SURE SADMIN SUDO FILE IS IN PLACE
#===================================================================================================
def update_sudo_file(sroot,logfile,wuser) :

    writelog('')
    writelog('--------------------')
    writelog("Creating '%s' user sudo file" % (wuser),'bold')
    sudofile = "/etc/sudoers.d/033_%s" % (wuser)
    writelog("  - Creating SADMIN sudo file (%s)" % (sudofile))


    # Check if sudoers directory exist - Procedure may not be supported on this O/S
    if not os.path.exists("/etc/sudoers.d"):
        writelog("SUDO Directory /etc/sudoers doesn't exist ?",'bold')
        writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
        return

    # If SADMIN sudo file exist, delete it and recreate it
    try:                                                                # In case old file exist
        os.remove(sudofile)                                             # Remove old sudo file
    except :                                                            # If not then it's OK
        pass                                                            # If don't exist continue
        
    # Create the SADMIN sudo file
    try : 
        hsudo = open(sudofile,'w')                                      # Open sudo file
    except :                                                            # If could not create output
        writelog("Error Opening %s file" % (sudofile),'bold')           # Advise Usr couldn't create
        writelog("Could not adjust 'sudo' configuration")               # Sudo file not updated
        sys.exit(1) 
    hsudo.write ('\nDefaults  !requiretty')                             # Session don't require tty
    hsudo.write ('\nDefaults  env_keep += "SADMIN"')                    # Keep Env. Var. SADMIN 
    hsudo.write ("\n%s ALL=(ALL) NOPASSWD: ALL\n" % (wuser))            # No Passwd for SADMIN User
    hsudo.write ("\nDefaults secure_path='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:%s/bin:%s/usr/bin'" % (sroot,sroot))
    hsudo.write ("\n")
    hsudo.close()                                                       # Close SADMIN sudo  file

    # Change sudo file permission to 440
    cmd = "chmod 640 %s" % (sudofile)                                   # chmod 440 on sudofile
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chmod on sudofile
    if (ccode == 0):                                                    # If chmod went ok
        writelog( "  - Permission on sudo file changed successfully")   # Show success to user
    else:                                                               # Did not went well
        writelog ("Problem changing sudo file permission")              # Had an error on sudo cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    # Change sudo file Owner and Group
    cmd = "chown %s.%s %s" % ('root','root',sudofile)                   # chowner on sudofile
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chown on sudofile
    if (ccode == 0):                                                    # If chown went ok
        writelog( "  - Ownership of sudo file changed successfully")    # Show success to user
    else:                                                               # Did not went well
        writelog ("Problem changing ownership of sudo file")            # Had an error on chown cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    return()                                                            # Return Cmd Path




#===================================================================================================
# IF FIREWALL IS RUNNING - OPEN PORT (80 & 443 ) FOR HTTP/HTTPS
#===================================================================================================
def rpm_firewall_rule(ussh_port) :
    writelog('')
    writelog('--------------------')
    writelog("Checking Firewall Information",'bold')

    # Check if the command 'firewalld-cmd' is present on system - If not return to caller
    writelog("  - Checking Firewall ... ","nonl")
    if (locate_command('firewall-cmd') == "") :                         # firewalld command not found
        writelog("Firewall (firewalld) not installed")
        return (0)                                                      # No need to continue
    else :
        writelog("Firewall (firewalld) installed")

    # Check if Firewall is running - If not then return to caller 
    writelog("  - Checking if firewall is running ... ","nonl")
    COMMAND = "systemctl status firewalld"                              # Check if Firewall running
    if (DEBUG): print ("O/S command : %s " % (COMMAND))                 # Under Debug print cmd   
    ccode,cstdout,cstderr = oscommand(COMMAND)                          # Try to Locate Command
    if ccode != 0 :  
        writelog("Firewall (firewalld) not running")
        return (0)                                                      # If Firewall not running
    else:
        writelog("Firewall (firewalld) running")

    # Open TCP Port 80 on Firewall
    writelog("  - Adding rule to allow incoming connection for http (port 80)")
    COMMAND="firewall-cmd --zone=public --add-service=http --permanent" 
    if (DEBUG): print ("O/S command : %s " % (COMMAND))                 
    ccode,cstdout,cstderr = oscommand(COMMAND)                          

    # Open TCP Port 443 on Firewall
    writelog("  - Adding rule to allow incoming connection for https (port 443)")
    COMMAND="firewall-cmd --zone=public --add-service=https --permanent" 
    if (DEBUG): print ("O/S command : %s " % (COMMAND))
    ccode,cstdout,cstderr = oscommand(COMMAND)

    # Iff SSH Port chosen was not 22 add firewall rule 
    if ussh_port != 22 : 
        writelog("  - Adding rule to allow SSH on port %d" % (ussh_port))
        COMMAND="firewall-cmd --zone=public --add-port=%d/tcp --permanent" % (ussh_port)
        if (DEBUG): print ("O/S command : %s " % (COMMAND))             # Under Debug print cmd   
        ccode,cstdout,cstderr = oscommand(COMMAND)                      

    # Reload Firewall rules
    COMMAND = "firewall-cmd --reload"                                   # Activate Rule - Restart FW
    if (DEBUG): print ("O/S command : %s " % (COMMAND))                 # Under Debug print cmd   
    ccode,cstdout,cstderr = oscommand(COMMAND)                          # Try to Locate Command

    return (0)                                                          # Return to Caller




#===================================================================================================
#       THIS FUNCTION VERIFY IF THE COMMAND RECEIVED IN PARAMETER IS AVAILABLE ON THE SERVER 
#===================================================================================================
def locate_command(lcmd) :
    COMMAND = "which %s" % (lcmd)                                       # Build the which command
    if (DEBUG): print ("O/S command : %s " % (COMMAND))                 # Under Debug print cmd   
    ccode,cstdout,cstderr = oscommand(COMMAND)                          # Try to Locate Command
    if ccode != 0 :                                                     # Command was not Found
        cmd_path=""                                                     # Cmd Path Null when Not fnd
    else :                                                              # If command Path is Found
        cmd_path = cstdout                                              # Save command Path
    return (cmd_path)                                                   # Return Cmd Path




#===================================================================================================
#       This function verify if the Package Received in parameter is available on the server 
# 
# Parameters : 
#   lpackages = Package Name
#   lpacktype = Package Type rpm, deb or cus (Custom from local directory)
#===================================================================================================
def locate_package(lpackages,lpacktype) :

    if (DEBUG):
        writelog ("Package name(s) received by locate_package : %s" % (lpackages))
        writelog ("Package Type received in locate_package is %s" % (lpacktype))

    if ((lpacktype != "deb") and (lpacktype != "rpm")):                 # Only rpm & deb Supported 
        writelog ("Package type invalid (%s)" % (lpacktype),'bold')     # Advise User UnSupported
        return (False)                                                  # Return False to caller

    found = True                                                        # Assume will found Package
    for pack in lpackages.split(" "):                                   # Split Packages List
        if (lpacktype == "deb") :                                       # If Debian Package Style
            COMMAND = "dpkg -s %s  >/dev/null 2>&1" % (pack)            # Check if Package Installed
            if (DEBUG): print ("O/S command : %s " % (COMMAND))         # Debug: Show Command used
            ccode,cstdout,cstderr = oscommand(COMMAND)                  # Try to Locate Command
            if (ccode != 0):                                            # If Package wasn't found
                found = False                                           # Found Package now False
        else:                                                           # If not an rpm pkg type
            if (lpacktype == "rpm"):                                    # Is it a rpm style package?
                COMMAND = "rpm -qi %s >/dev/null 2>&1" % (pack)         # Try to get info on package
                if (DEBUG): print ("O/S command : %s " % (COMMAND))     # Debug: Show Command used
                ccode,cstdout,cstderr = oscommand(COMMAND)              # Try to Locate Command
                if (ccode != 0):                                        # If package wasn't found
                    found = False                                       # Found Package is now false
            else:                                                       # Not rpm or deb pkg style
                writelog ("Package type (%s) not supported" % (lpacktype),'bold') # Advise User 
                cmd_path=''                                             # Command path set blank
                found = False
    return(found)                                                       # Return True or False
    

#===================================================================================================
#                       S A T I S F Y    R E Q U I R E M E N T   F U N C T I O N 
#===================================================================================================
#
def satisfy_requirement(stype,sroot,packtype,logfile,sosname,sosver,sosbits,sosarch):
    global fhlog

    # Based on installation Type (Client or Server), Move client or server dict. in Work Dict.
    writelog (" ")
    writelog ("--------------------")
    if (stype == 'C'):
        req_work = req_client                                           # Move CLient Dict in WDict.
        writelog ("Verifying SADMIN Client Package requirements",'bold')  # Show User what we do
    else:
        req_work = req_server                                           # Move Server Dict in WDict.
        writelog ("Verifying SADMIN Server package requirements",'bold')  # Show User what we do
    writelog (" ")

    # If Debian Package, Refresh The Local Repository 
    if (packtype == "deb"):                                             # Is Debian Style Package
        cmd =  "apt -y update >> %s 2>&1" % (logfile)                   # Refresh Cache
        if (DRYRUN):                                                    # If Running if DRY-RUN Mode
            print ("DryRun - would run : %s" % (cmd))                   # Only shw cmd we would run
        else:                                                           # If running in normal mode
            writelog ("Running apt update...","nonl")                   # Show what we are running
            (ccode, cstdout, cstderr) = oscommand(cmd)                  # Run the apt-get command
            if (ccode == 0) :                                           # If command went ok
                writelog (" Done ")                                     # Print DOne
            else:                                                       # If we had error 
                writelog ("Error Code is %d" % (ccode))                 # Advise user of error

    # Under Debug Mode, Display the working dictionnary that we will be processing below
    if (DEBUG):                                                         # Under Debug Show Req Dict.
        for cmd,pkginfo in req_work.items():                            # For all items in Work Dict
            writelog("\nFor command '{0}' we need package :" .format(cmd)) # Show Command name
            writelog('RPM Repo:{0} - Package: {1} ' .format(pkginfo['rrepo'], pkginfo['rpm']))
            writelog('DEB Repo:{0} - Package: {1} ' .format(pkginfo['drepo'], pkginfo['deb']))

    # Process Package requirement and check if package is installedm, if not install it
    for cmd,pkginfo in req_work.items():                                # For all item in Work Dict.
        needed_cmd = cmd                                                # File/Cmd Req. Check 
        if (packtype == "deb"):                                         # If Current host use .deb
            needed_packages = pkginfo['deb']                            # Save Packages to install
            needed_repo     = pkginfo['drepo']                          # Packages Repository to use
        else:                                                           # If Current Host use .rpm
            needed_packages = pkginfo['rpm']                            # Save Packages to install
            needed_repo     = pkginfo['rrepo']                          # Packages Repository to use

        if needed_packages == "none" :                                  # Package not avail. on O/S
            #writelog ("...") 
            continue                                                    # Continue with next Package

        # Verify if needed package is installed
        #pline = "Is the package '%s' installed... " % (needed_packages) # Show what we are doing
        #writelog (pline,"nonl")                                         # Show What is looking for

        # Rear Only available on Intel platform Architecture
        if needed_packages.split()[0] == 'rear' and sosarch not in rear_supported_architecture :
            writelog ("[ INFO ] 'ReaR' Backup & Recovery tool isn't supported on %s." % (sosarch)) 
            continue                                                    # Proceed with Next Package

        # 'lsb_release' package is present on all platform.
        #   - Except RHEL 7-8, package name is named "redhat-lsb-core'.
        if (needed_packages == "lsb_release") : 
            if (sosname in rhel_family and sosver < 9) : 
                needed_packages = "redhat-lsb-core" 

        if locate_package(needed_packages,packtype) :                   # If Package is installed
            writelog ("[ OK ] Package '%s' already installed." % (needed_packages))  # Check Result
            continue                                                    # Proceed with Next Package

        if needed_packages == "" :
            writelog ("[ WARNING ] Not available on '%s'." % (sosname))
            continue

        # Install Missing Packages 
        # Setup the command to install missing package
        if (packtype == "deb") :                                        # If Package type is '.deb'
            icmd = "DEBIAN_FRONTEND=noninteractive "                    # No Prompt While installing
            icmd += "apt -y install %s >>%s 2>&1" % (needed_packages,logfile)
        if (packtype == "rpm") :                                        # If Package type is '.rpm'
            if (needed_repo == "epel") and (sosname != "FEDORA"):       # Repo needed is EPEL
                icmd = "yum install --enablerepo=epel -y %s >>%s 2>&1" % (needed_packages,logfile)
            else:
                icmd = "yum install -y %s >>%s 2>&1" % (needed_packages,logfile)

        # To Test if install went ok, try to execute install command.
        ccode, cstdout, cstderr = oscommand(icmd)
        if (ccode == 0) : 
            writelog ("[ OK ] Package '%s' is now installed." % (needed_packages)) 
            continue
        else : 
            writelog("[ WARNING ] '%s' isn't available on %s v%s." % (needed_packages,sosname.capitalize(),sosver))
            continue

    return()



#===================================================================================================
#   Test if user received (uname) exist in the MariaDB, root password must is needed (dbroot_pwd)                                 M A I N     P R O G R A M
#===================================================================================================
#
def user_exist(uname,dbroot_pwd):
    userfound = False
    sql = "select User from mysql.user where User='%s';" % (uname) 
    cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command 
    if (ccode == 0):
        userlist = cstdout.splitlines()
        for user in userlist:
            if (user == uname) : userfound = True
    return (userfound)



#===================================================================================================
# Test if user received (uname) can connect to Database with password in $SADMIN/cfg/.dbpass file
#===================================================================================================
#
def user_can_connect(uname,sroot):
    userpwd = ""                                                        # Clear Default User Passwd

    # Get User password in Database password file
    dpfile = "%s/cfg/.dbpass" % (sroot)                                 # Database Password FileName
    try:    
        FH_DBPWD = open(dpfile,'r')                                     # Open DB Password File
    except IOError as e:                                                # If Can't open DB Pwd  file
            #print ("Database password file '%s' not found\n" % dpfile)  # Print DBPass FileName
            return (userpwd)                                            # Return Empty Pwd to caller
    for dbline in FH_DBPWD :                                            # Loop until on all lines
        wline = dbline.strip()                                          # Strip CR/LF & Trail spaces
        if (wline[0:1] == '#' or len(wline) == 0) :                     # If comment or blank line
            continue                                                    # Go read the next line
        if wline.startswith(uname) :                                    # LineStart with UserName
            split_line = wline.split(',')                               # Split Line based on comma
            userpwd = split_line[1]                                     # Save user Passwd
    FH_DBPWD.close()                                                    # Close DB Password file

    # Try to connect to Database Now that we have the user password.
    try :
        conn = pymysql.connect( 
            host='localhost', 
            user=uname,  
            password=userpwd, 
            db='sadmin',
            cursorclass=pymysql.cursors.DictCursor
        )
    except TypeError:                                                   # Catch Error
        print ("Error connecting to Database 'sadmin'")                 # Advise USer
        print ("'pymsql.connect' error")
    except (pymysql.err.OperationalError,TypeError) as error :          # Catch Error
        enum,emsg = error.args                                          # Get Error No. & Message
        print ("Error connecting to Database 'sadmin'")                 # Advise USer
        print (">>>>>>>>>>>>>",enum,emsg)                               # Print Error No. & Message
    conn.close()                                                        # Close connection to DB
    return (userpwd)                                                    # Return User Pwd to caller



#===================================================================================================
#   Test if sadmin database exist
#===================================================================================================
#
def database_exist(dbname,dbroot_pwd):
    dbfound = False                                                     # Default sadminDB not there
    sql = 'show databases;'                                             # Command to list Databases
    cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)             # Build CmdLine to run SQL
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command 
    if (ccode == 0):                                                    # If Execution went well
        listdb = cstdout.splitlines()                                   # Split Database Line
        for db in listdb:                                               # For each DB in List
             if (db == dbname) : dbfound = True                         # If sadmin Database Found
    return (dbfound)                                                    # Return if sadmin DB found



#===================================================================================================
#           Add the new server into the Database as a Starting point for Web Interface
#===================================================================================================
#
def add_server_to_db(sserver,dbroot_pwd,sdomain):

    insert_ok = False                                                   # Default Insert Failed
    server    = sserver.split('.')                                      # Split FQDN Server Name
    sname     = server[0]                                               # Only Keep Server Name
    writelog('')
    writelog("Inserting '%s' system in database ... " % (sname),'bold') # Show adding Server
    #
    cnow    = datetime.datetime.now()                                   # Get Current Time
    curdate = cnow.strftime("%Y-%m-%d")                                 # Format Current date
    curtime = cnow.strftime("%H:%M:%S")                                 # Format Current Time
    dbdate  = curdate + " " + curtime                                   # MariaDB Insert Date/Time  
    
    # Get O/S Distribution Name
    if os.path.isfile('/usr/bin/lsb_release') : 
        wcmd = "%s %s" % ("lsb_release","-si")
        ccode, cstdout, cstderr = oscommand(wcmd)
        osdist=cstdout.upper()
    else: 
        try: 
            osdist=os_dict['ID'].upper()
        except KeyError as e:     
            writelog('Cannot determine O/S distribution')
    if osdist == "REDHATENTERPRISESERVER" : osdist="REDHAT"
    if osdist == "REDHATENTERPRISEAS"     : osdist="REDHAT"
    if osdist == "RHEL"                   : osdist="REDHAT"
    if osdist == "REDHATENTERPRISE"       : osdist="REDHAT"
    if osdist == "CENTOSSTREAM"           : osdist="CENTOS"    
    if osdist == "ROCKYLINUX"             : osdist="ROCKY"    
    if osdist == "ALMALINUX"              : osdist="ALMA"    
    if osdist == "LINUXMINT"              : osdist="MINT"    
    
    # Get O/S Version
    if os.path.isfile('/usr/bin/lsb_release') : 
      ccode, cstdout, cstderr = oscommand("lsb_release" + " -sr")
      osver=cstdout
    else:
        try: 
            osver=os_dict['VERSION_ID']
        except KeyError as e:     
            osver="0.0"

    # Get O/S Code Name
    if os.path.isfile('/usr/bin/lsb_release') : 
        wcmd = "%s %s" % ("lsb_release","-c | awk '{print$2}'")
        ccode, cstdout, cstderr = oscommand(wcmd)
        oscodename=cstdout
    else:
        try: 
            oscodename=os_dict['VERSION_CODENAME']
        except KeyError as e:     
            oscodename=""

    # Get Architecture
    warch=platform.machine() 

    # Construct insert new server SQL Statement
    sql = "use sadmin; "
    sql += "insert into server set srv_name='%s', srv_domain='%s'," % (sname,sdomain);
    sql += " srv_desc='SADMIN Server', srv_active='1', srv_date_creation='%s'," % (dbdate)
    sql += " srv_sporadic='0', srv_monitor='1', srv_cat='Prod', srv_group='Regular', "
    sql += " srv_backup='0', srv_update_auto='0', srv_tag='SADMin Server', " 
    sql += " srv_osname='%s'," % (osdist)
    sql += " srv_arch='%s'  ," % (warch) 
    sql += " srv_osversion='%s'," % (osver)
    sql += " srv_ostype='linux', srv_graph='1', srv_note='', srv_kernel_version='', srv_model='',"
    sql += " srv_serial='', srv_memory='0', srv_rear_ver='unknown', srv_cpu_speed='0' ;"
    #
    # Execute the Insert New Server Statement
    cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command 
    if (ccode == 0):                                                    # Insert SQL Went OK
        writelog(" Done")                                               # Inform User
        insert_ok = True                                                # Return Value will be True
    else:                                                               # If Problem with the insert
        writelog("Problem inserting new server")                        # Infor User
        writelog("SQL Statement : %s" % (sql))                          # Show SQL used for insert
        writelog("Error %d - %s - %s" % (ccode,cstdout,cstderr))        # Show Error#,Stdout,Stderr
    return (insert_ok)                                                  # Return Insert Status



#===================================================================================================
#                       Setup MySQL Package and Load the SADMIN Database
# sroot = SADMIN Root Directory
# sserver = Server FQDN 
# sdomain = Domain Name 
# sosname = Name of Distribution in Uppercase
#===================================================================================================
#
def setup_mysql(sroot,sserver,sdomain,sosname):
    
    writelog ('  ')
    writelog ('--------------------')
    writelog ("Setup SADMIN MariaDB Database",'bold')

    # Copy SADMIN MariaDB config in /etc/my.cnf.d (Problem on old MariabDB Version)
    mysql_file1 = "%s/setup/etc/sadmin.cnf" % (sroot)                   # MariaDB sadmin cfg file
    mysql_file2 = "/etc/my.cnf.d/sadmin.cnf"                            # MariaDB sadmin in /etc
    if os.path.exists("/etc/my.cnf.d") == True:                         # If MariaDB Dir. Exist
        try:
            shutil.copyfile(mysql_file1,mysql_file2)                    # Copy Initial Web cfg
        except IOError as e:
            writelog("Error copying Mariadb %s config file. %s" % (mysql_file1,e)) 
            sys.exit(1)                                                 # Exit to O/S With Error
        except:
            writelog("Unexpected error:", sys.exc_info())               # Advise Usr Show Error Msg
            sys.exit(1)          
    
    # Test if system is using Systemd or SystemV Init ----------------------------------------------
    cmd = "pidof systemd >/dev/null 2>&1"                               # Cmd = systemd is running ?
    ccode,cstdout,cstderr = oscommand(cmd)                              # Test systemd or SysVinit
    if (ccode == 0):                                                    # System is using SystemD
        SYSTEMD=True                                                    # So Systemd is True
    else:                                                               # Using SysVInit
        SYSTEMD=False                                                   # So Systemd is False


    # Make Sure MariaDB is Running -----------------------------------------------------------------
    writelog ('  ')
    if (SYSTEMD):                                                       # If Using Systemd
        cmd = "systemctl restart mariadb.service"                       # Systemd Restart MariaDB
    else:                                                               # If Using SystemV Init
        cmd = "/etc/init.d/mysql restart"                               # SystemV Restart MariabDB
    writelog ("ReStarting MariaDB Service - %s ... " % (cmd),"nonl")    # Make Sure MariabDB Started
    ccode,cstdout,cstderr = oscommand(cmd)                              # Restart MariaDB Server
    if (ccode != 0):                                                    # Problem Starting DB
        writelog ("Problem Starting MariabDB server... ")               # Advise User
        writelog ("Return code is %d - %s" % (ccode,cmd))               # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    else:
        writelog (' Done ')


    # Make sure MariaDB restart upon reboot --------------------------------------------------------
    if (SYSTEMD):                                                       # If Using Systemd
        cmd = "systemctl enable mariadb.service"                        # Enable MariaDB at BootTime
    else:                                                               # If Using System V
        cmd = "update-rc.d mysql enable"                                # On SystemV Debian,Ubuntu
        if (sosname == "REDHAT") or (sosname == "CENTOS") :             # RedHat/CentOS = chkconfig
            cmd = "chkconfig mysql on"                                  # No MariabDB, MySQL
    writelog ("Enabling MariaDB Service - %s ... " % (cmd),"nonl")      # Inform User
    ccode,cstdout,cstderr = oscommand(cmd)                              # Enable MariaDB Server
    if (ccode != 0):                                                    # Problem Enabling Service
        writelog ("Problem with enabling MariabDB Service.")            # Advise User
        writelog ("Return code is %d - %s" % (ccode,cmd))               # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    else:
        writelog (' Done ')


    # Set 'sadmin' Database Host to localhost in sadmin.cfg
    update_sadmin_cfg(sroot,"SADM_DBHOST","localhost",False)            # Update Value in sadmin.cfg
       

    # Accept 'root' Database user password (And validate access) -----------------------------------
    sdefault = ""                                                       # No Default Password 
    sprompt  = "Enter MariaDB Database 'root' user password"            # Prompt for Answer
    dbroot_pwd = accept_field(sroot,"SADM_DBROOT",sdefault,sprompt,"P") # Accept Mysql root pwd
 
    # Test Access/Change MariaDB with the password given by user -----------------------------------
    cmd = "mysql -uroot -p%s -e 'show databases;'" % (dbroot_pwd)       # Cmd to show databases
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command
    if (ccode != 0):                                                    # If can't connect 
        cmd = "mysqladmin -u root password '%s'" % (dbroot_pwd)         # Try Changing Password
        ccode,cstdout,cstderr = oscommand(cmd)                          # Execute MySQL Load DB
        if (ccode != 0):                                                # If problem Changing Passwd
            writelog ("Error accessing or changing MariaDB password (mysqladmin)") # Advise User
            writelog ("Return code is %d" % (ccode))                    # Show Return Code No
            writelog ("Standard out is %s" % (cstdout))                 # Print command stdout
            writelog ("Standard error is %s" % (cstderr))               # Print command stderr
            writelog ("ERROR: Cannot continue sadmin database setup",'bold')
            time.sleep(2)                                               # Sleep 2 Seconds
            return (1)                                                  # Abort MySQL Setup
    writelog("Access to Database is working ...",'bold')                # Access to Database went OK


    # Check if the initial Database Load SQL is present (sadmin.sql) -------------------------------
    init_sql = "%s/setup/etc/sadmin.sql" % (sroot)                      # Initial DB Load SQL File
    if not os.path.isfile(init_sql):                                    # Initial SQL don't exist
        writelog("Initial Load SADMIN SQL Data (%s) file is missing" % (init_sql),'bold')
        writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
        return (1)


    # Test if SADMIN Database exist in MariaDB -----------------------------------------------------
    dbname = "sadmin"                                                   # Set DB Name to check 
    load_db = False                                                     # Default not to Load Init
    if not (database_exist(dbname,dbroot_pwd)):                         # If SADMIN DB don't exist
        load_db = True                                                  # Default is to load Init DB
    else:                                                               # If SADMIN DB Exist=Warning
        writelog ('')                                                   # Space Line
        writelog ("Database 'sadmin' already exist !")                  # Show user DB exist
        uquery="Do you really want to reload initial 'sadmin' Database (WILL ERASE ACTUAL CONTENT)"
        answer=askyesno(uquery,'N')                                     # Ask if want to Init DB
        if (answer): load_db = True                                     # Answer Yes Reload Database


    # If Database SADMIN don't exist or user want to drop SADMIN DB and reload initial Data --------
    if (load_db) :                                                      # If Load/Reload Selected
        writelog('  ')                                                  # Space Line
        writelog('----------')                                          # Separation Line
        cmd = "mysql -u root -p%s < %s" % (dbroot_pwd,init_sql)         # SQL Cmd to Load DB
        writelog("Loading initial data in SADMIN database ... ",'bold') # Load Initial Database 
        ccode,cstdout,cstderr = oscommand(cmd)                          # Execute MySQL Lload DB
        if (ccode != 0):                                                # If problem deleting user
            writelog ("Problem loading the database ...")               # Advise User
            writelog ("Return code is %d - %s" % (ccode,cmd))           # Show Return Code No
            writelog ("Standard out is %s" % (cstdout))                 # Print command stdout
            writelog ("Standard error is %s" % (cstderr))               # Print command stderr
        else:                                                           # If user deleted
            writelog (' Done ')                                         # Advise User ok to proceed
        time.sleep(1)                                                   # Sleep for user to see

    # LOOP TILL CREATE USER WORK *************** COCO ******
    # Check if 'sadmin' user exist in Database, if not create User and Grant permission ------------
    password_ok = False                                                 # Default Password not valid
    while password_ok == False :                                        # Loop until valid password
        uname     = "sadmin"                                            # User to check in DB
        sdefault  = "Nimdas2018"                                        # Default 'sadmin' Password 
        sprompt   = "Enter Read/Write 'sadmin' database user password"  # Prompt for Answer
        rw_passwd = ""                                                  # Clear dbpass sadmin Pwd
        writelog(' ')                                                   # Blank Line
        writelog('----------')                                          # Separation Line
        if user_exist(uname,dbroot_pwd) :                               # User Exist in Database ?
            writelog ("User '%s' exist in Database ..." % (uname))      # Show user was found
            wcfg_rw_dbpwd = user_can_connect(uname,sroot)               # Can connect? Return Pwd
            if (wcfg_rw_dbpwd != "" ) :                                 # No blank Pwd, connect ok
                writelog ("User '%s' able to connect to Database using password file ..." % (uname))
                password_ok = True                                      # Ok Exit the loop
            else:                                                       # sadmin password is wrong
                writelog ("Not able to connect to Database using '%s' .dbpass password." % (uname))
                wcfg_rw_dbpwd = accept_field(sroot,"SADM_RW_DBPWD",sdefault,sprompt,"P") # Enter Usr pwd
                writelog ("Updating 'sadmin' user password and grant ... ","nonl")
                sql = " SET PASSWORD FOR '%s'@'localhost' = PASSWORD('%s');" % (uname,wcfg_rw_dbpwd)
                sql += " revoke all privileges on *.* from '%s'@'localhost';" % (uname)
                sql += " grant all privileges on sadmin.* to '%s'@'localhost';" % (uname)
                sql += " flush privileges;"                             # Flush Buffer
                cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql) # Build Create User SQL
                if (DEBUG):       
                    writelog ("SQL executing : \n%s\n" % (cmd))
                ccode,cstdout,cstderr = oscommand(cmd)                  # Execute MySQL Command 
                if (ccode != 0):                                        # If problem creating user
                    writelog ("Error code returned is %d \n%s" % (ccode,cmd))   # Show Return Code No
                    writelog ("Standard out is %s" % (cstdout))         # Print command stdout
                    writelog ("Standard error is %s" % (cstderr))       # Print command stderr
                else:
                    password_ok = True                                  # Ok Exit the loop
        else:                                                           # Database user don't exist
            writelog ("User '%s' don't exist in database, will create it now." % (uname))   # Show user was found
            wcfg_rw_dbpwd = accept_field(sroot,"SADM_RW_DBPWD",sdefault,sprompt,"P") # Sadmin user pwd
            writelog ("Creating 'sadmin' user ... ","nonl")             # Show User Creating DB Usr
            sql =  "drop user 'sadmin'@'localhost'; flush privileges; " # Drop Usr,ByPass Bug Debian
            cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)     # Build Create User SQL
            ccode,cstdout,cstderr = oscommand(cmd)                      # Execute MySQL Command 
            sql  = " CREATE USER '%s'@'localhost' IDENTIFIED BY '%s';" % (uname,wcfg_rw_dbpwd)
            sql += " grant all privileges on sadmin.* to '%s'@'localhost';" % (uname)
            sql += " flush privileges;"                                 # Flush Buffer
            cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)     # Build Create User SQL
            ccode,cstdout,cstderr = oscommand(cmd)                      # Execute MySQL Command 
            if (ccode != 0):                                            # If problem creating user
                writelog ("Error code returned is %d \n%s" % (ccode,cmd)) # Show Return Code No
                writelog ("Standard out is %s" % (cstdout))             # Print command stdout
                writelog ("Standard error is %s" % (cstderr))           # Print command stderr
            else:                                                       # User Created with Success
                password_ok = True                                      # Ok Exit the loop
    #
    rw_passwd = wcfg_rw_dbpwd                                           # DBpwd R/W sadmin Password
    writelog (" [ OK ]")                                                # Advise User ok to proceed


    # Check if 'squery' user exist in Database, if not create User and Grant permission ------------
    password_ok = False                                                 # Default Password not valid
    while password_ok == False :                                        # Loop until valid password
        uname     = "squery"                                            # Default Query DB UserName
        sdefault  = "Squery18"                                          # Default Password 
        sprompt   = "Enter 'squery' database user password"             # Prompt for Answer
        ro_passwd = ""                                                  # Clear dbpass squery Pwd
        writelog(' ')                                                   # Blank Line
        writelog('----------')                                          # Separation Line
        if user_exist(uname,dbroot_pwd) :                               # User Exist in Database ?
            writelog ("User '%s' exist in Database ..." % (uname))      # Show user was found
            wcfg_ro_dbpwd = user_can_connect(uname,sroot)               # Can connect? Return Pwd
            if (wcfg_ro_dbpwd != "" ) :                                 # No blank Pwd, connect ok
                writelog ("User '%s' able to connect to Database using password file ..." % (uname))
                password_ok = True                                      # Ok Exit the loop
            else:                                                       # sadmin password is wrong
                writelog ("Not able to connect to Database using '%s' .dbpass password ..." % (uname))
                wcfg_ro_dbpwd = accept_field(sroot,"SADM_RO_DBPWD",sdefault,sprompt,"P") # Enter Usr pwd
                writelog ("Updating 'squery' user password and grant ... ","nonl")
                sql = " SET PASSWORD FOR '%s'@'localhost' = PASSWORD('%s');" % (uname,wcfg_ro_dbpwd)
                sql += " revoke all privileges on *.* from 'squery'@'localhost';"
                sql += " grant select, show view on sadmin.* to 'squery'@'localhost';"
                sql += " flush privileges;"                             # Flush Buffer
                cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql) # Build Create User SQL
                if (DEBUG):       
                    writelog ("SQL executing : \n%s\n" % (cmd))
                ccode,cstdout,cstderr = oscommand(cmd)                  # Execute MySQL Command 
                if (ccode != 0):                                        # If problem creating user
                    writelog ("Error code returned is %d \n%s" % (ccode,cmd)) # Show Return Code No
                    writelog ("Standard out is %s" % (cstdout))         # Print command stdout
                    writelog ("Standard error is %s" % (cstderr))       # Print command stderr
                else:
                    password_ok = True                                  # Ok Exit the loop
        else:                                                           # Database user don't exist
            writelog ("User '%s' don't exist in database, will created now." % (uname))   # Show user was found
            wcfg_ro_dbpwd = accept_field(sroot,"SADM_RO_DBPWD",sdefault,sprompt,"P") # Accept user pwd
            writelog ("Creating '%s' user ... " % (uname),"nonl")       # Show User Creating DB Usr
            sql =  "drop user 'squery'@'localhost'; flush privileges; " # Drop User - ByPass Bug Deb
            cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)     # Build Create User SQL
            ccode,cstdout,cstderr = oscommand(cmd)                      # Execute MySQL Command 
            sql  = " CREATE USER '%s'@'localhost' IDENTIFIED BY '%s';" % (uname,wcfg_ro_dbpwd)
            sql += " grant all privileges on sadmin.* to '%s'@'localhost';" % (uname)
            sql += " flush privileges;"                                 # Flush Buffer
            cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)     # Build Create User SQL
            ccode,cstdout,cstderr = oscommand(cmd)                      # Execute MySQL Command 
            if (ccode != 0):                                            # If problem creating user
                writelog ("Error code returned is %d \n%s" % (ccode,cmd)) # Show Return Code No
                writelog ("Standard out is %s" % (cstdout))             # Print command stdout
                writelog ("Standard error is %s" % (cstderr))           # Print command stderr
            else:                                                       # User Created with Success
                password_ok = True                                      # Ok Exit the loop
    #
    ro_passwd = wcfg_ro_dbpwd                                           # DBpwd R/W sadmin Password
    writelog (" [ OK ]")                                                # Advise User ok to proceed


    # Add current system to server table in MySQL Database
    if (load_db) :                                                      # If Load/Reload Database
        writelog('----------')                                          # Separation Line
        add_server_to_db(sserver,dbroot_pwd,sdomain)                    # Add current Server to DB


    # Create/Update $SADMIN/cfg/.dbpass (Database Password file) Only if it doesn't exist ----------
    dpfile = "%s/cfg/.dbpass" % (sroot)                                 # Database Password FileName
    if not os.path.isfile(dpfile):                                      # If .dbpass don't exist
        writelog ("Creating Database Password File (%s)" % (dpfile))    # Advise user create .dbpass
    else:                                                               # If file already exist
        writelog ("Updating Database Password File (%s)" % (dpfile))    # Advise user create .dbpass
    dbpwd  = open(dpfile,'w')                                           # Create Database Pwd File
    dbpwd.write("sadmin,%s\n" % (rw_passwd))                            # Create R/W user & Password
    dbpwd.write("squery,%s\n" % (ro_passwd))                            # Create R/O user & Password
    dbpwd.close()                                                       # Close DB Password File
        


    # Make Sure MariaDB is Running -----------------------------------------------------------------
    #writelog ('  ')
    #if (SYSTEMD):                                                       # If Using Systemd
    #    cmd = "systemctl restart mariadb.service"                       # Systemd Restart MariaDB
    #else:                                                               # If Using SystemV Init
    #    cmd = "/etc/init.d/mysql restart"                               # SystemV Restart MariabDB
    #writelog('----------')                                              # Separation Line
    #writelog ("ReStarting MariaDB Service - %s ..." % (cmd),"nonl")     # Make Sure MariabDB Started
    #ccode,cstdout,cstderr = oscommand(cmd)                              # Restart MariaDB Server
    #if (ccode != 0):                                                    # Problem Starting DB
    #    writelog ("Problem Starting MariabDB server... ")               # Advise User
    #    writelog ("Return code is %d - %s" % (ccode,cmd))               # Show Return Code No
    #    writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
    #    writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    #else:
    #    writelog (' Done ')


#===================================================================================================
#                                   Setup Apache Web Server 
#===================================================================================================
#
def setup_webserver(sroot,spacktype,sdomain,semail):

    writelog ('  ')
    writelog ('  ')
    writelog ('--------------------')
    writelog ("Setup SADMIN Web Site",'bold')
    writelog ('  ')

    # Set the name of Web Server Service depending on Linux O/S
    sservice = "httpd"
    if (spacktype == "deb" ) : sservice = "apache2" 
    open("/var/log/%s/sadmin_error.log"  % (sservice),'a').close()      # Init Apache SADMIN err log
    open("/var/log/%s/sadmin_access.log" % (sservice),'a').close()      # Init Apache SADMIN log

# Set Path and Certicate related files.
    if (spacktype == "deb" ) :
        SSL_KEY_DIR = '/etc/ssl/private'
        SSL_KEY     = SSL_KEY_DIR + "/sadmin.key"
        SSL_CRT_DIR = '/etc/ssl/certs'
        SSL_CRT     = SSL_CRT_DIR + "/sadmin.crt"
        if not os.path.exists(SSL_KEY_DIR): os.makedirs(SSL_KEY_DIR)
        if not os.path.exists(SSL_CRT_DIR): os.makedirs(SSL_CRT_DIR)
    else:
        SSL_KEY_DIR = '/etc/pki/tls/private'
        SSL_KEY     = SSL_KEY_DIR + "/sadmin.key"
        SSL_CRT_DIR = '/etc/pki/tls/certs' 
        SSL_CRT     = SSL_CRT_DIR + "/sadmin.crt"
        if not os.path.exists(SSL_KEY_DIR): os.makedirs(SSL_KEY_DIR)
        if not os.path.exists(SSL_CRT_DIR): os.makedirs(SSL_CRT_DIR)

# Generate https certificate
    if not os.path.exists(SSL_KEY) : 
        cmd1 = "openssl req -newkey rsa:2048 -nodes " 
        cmd2 = "-keyout %s -x509 -days 3650 -out %s " % (SSL_KEY,SSL_CRT)
        cmd3 = "-subj '/C=CA/ST=Quebec/L=Montreal/O=Personnal Home/OU=IT/CN=sadmin.%s'" % (sdomain)
        cmd  = "%s%s%s" % (cmd1,cmd2,cmd3)
        ccode,cstdout,cstderr = oscommand(cmd)                              # Execute O/S Command
        if (ccode != 0):                                                    # If problem creating user
            writelog ("[ ERROR %d ] Generation sadmin SSL certificate.\n%s" % (ccode,cmd)) 
            writelog ("Standard out is %s" % (cstdout)) 
            writelog ("Standard error is %s" % (cstderr))
    os.chmod(SSL_KEY, 0o640) 
    if (spacktype == "deb" ) : 
        stat_info = os.stat(SSL_KEY_DIR)
        xuid = stat_info.st_uid
        xgid = stat_info.st_gid
        os.chown(SSL_KEY,xuid,xgid)

# Verify now if the certificate files exist
    if not os.path.exists(SSL_KEY) or  not os.path.exists(SSL_CRT) :
        writelog ("[ ERROR ] Certificate file %s and %s are missing." % (SSL_KEY,SSL_CRT)) 
        writelog ("The Web service may not start. ")

# Start Web Server
    if (spacktype == "deb" ) : 
        cmd = "a2enmod ssl" 
        writelog ("  - Activate Apache encryption module - %s" % (cmd))
        ccode,cstdout,cstderr = oscommand(cmd)
        if (ccode != 0):                                                    # If problem creating user
            writelog ("Problem Activating apache2 encryption module.")      # Show Return Code No
            writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
            writelog ("Standard error is %s" % (cstderr))                   # Print command stderr

    cmd = "systemctl restart %s" % (sservice)
    writelog ("  - Making sure Web Server is started - %s" % (cmd))
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Load DB
    if (ccode != 0):                                                    # If problem creating user
        writelog ("Problem Restarting Web Server - Error %d \n%s" % (ccode,cmd)) # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr

    # Get the httpd process owner
    time.sleep( 4 )                                                     # Wait Web Server to Start
    cmd = "ps -ef | grep -Ev 'root| grep' |grep '%s' | awk '{ print $1 }' |sort |uniq" % (sservice)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute O/S Command
    apache_user = cstdout                                               # Get Apache Process Usr
    if (DEBUG):                                                         # If Debug Activated
        writelog ("Return code for getting httpd user name is %d" % (ccode))
    writelog ("  - Apache process user name  : %s" % (apache_user))     # Show Apache Proc. User

    # Get the group of httpd process owner 
    cmd = "id -gn %s" % (apache_user)                                   # Get Apache User Group
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute O/S Command
    apache_group = cstdout                                              # Get Group from StdOut
    if (DEBUG):                                                         # If Debug Activated
        writelog ("Return code for getting httpd group name is %d" % (ccode))                 
    writelog ("  - Apache process group name : %s" % (apache_group))    # Show Apache  Group

    # If Package type is 'deb', (Debian, LinuxMint, Ubuntu, Raspbian,...) ... 
    if (spacktype == "deb") :
        # Updating the apache2 configuration file 
        sadm_file="%s/setup/etc/sadmin.conf" % (sroot)                  # Init. Sadmin Web Cfg
        apache2_file="/etc/apache2/sites-available/sadmin.conf"         # Apache Path to cfg File
        if os.path.exists(apache2_file)==False:                         # If Web cfg Not Found
            try:
                shutil.copyfile(sadm_file,apache2_file)                 # Copy Initial Web cfg
            except IOError as e:
                writelog("Unable to copy apache2 config file. %s" % e)  # Advise user before exiting
                sys.exit(1)                                             # Exit to O/S With Error
            except:
                writelog("Unexpected error:", sys.exc_info())           # Advise Usr Show Error Msg
                sys.exit(1)                                             # Exit to O/S with Error
        update_apache_config(sroot,apache2_file,"{WROOT}",sroot)        # Set WWW Root Document
        update_apache_config(sroot,apache2_file,"{EMAIL}",semail)       # Set WWW Admin Email
        update_apache_config(sroot,apache2_file,"{DOMAIN}",sdomain)     # Set WWW sadmin.{Domain}
        update_apache_config(sroot,apache2_file,"{SERVICE}",sservice)   # Set WWW sadmin log dir
        update_apache_config(sroot,apache2_file,"{SSL_CRT}",SSL_CRT)    # Set Certificate file
        update_apache_config(sroot,apache2_file,"{SSL_KEY}",SSL_KEY)    # Set Certificate Key File
        # Disable Default apache2 configuration
        cmd = "a2dissite 000-default.conf"                              # Disable default Web Site 
        ccode,cstdout,cstderr = oscommand(cmd)                          # Execute Command
        if (ccode == 0):
            writelog( "  - Disable default apache configuration")
        else:
            writelog ("Problem disabling apache2 default configuration")
            writelog ("%s - %s" % (cstdout,cstderr))        
        # Enable SADMIN Configuration
        cmd = "a2ensite sadmin.conf"                                    # Enable Web Site In Apache
        ccode,cstdout,cstderr = oscommand(cmd)                          # Execute Command                       
        if (ccode == 0):
            writelog( "  - SADMIN Web Site enable")
        else:
            writelog ("Problem enabling SADMIN Web Site")
            writelog ("%s - %s" % (cstdout,cstderr))
        apache2_config = "/etc/apache2/sites-enabled/sadmin.conf"

    # Setup Web configuration for RedHat, CentOS, Fedora (rpm)
    if (spacktype == "rpm") :
        # Updating the httpd configuration file 
        sadm_file="%s/setup/etc/sadmin.conf" % (sroot)                  # Init. Sadmin Web Cfg
        apache2_config="/etc/httpd/conf.d/sadmin.conf"                  # Apache Path to cfg File
        if not os.path.exists(apache2_config):                          # If Web cfg Not Found
            try:
                shutil.copyfile(sadm_file,apache2_config)               # Copy Initial Web cfg
            except IOError as e:
                writelog("Unable to copy httpd config file. %s" % e)    # Advise user before exiting
                sys.exit(1)                                             # Exit to O/S With Error
            except:
                writelog("Unexpected error:", sys.exc_info())           # Advise Usr Show Error Msg
                sys.exit(1)                                             # Exit to O/S with Error
        update_apache_config(sroot,apache2_config,"{WROOT}",sroot)      # Set WWW Root Document
        update_apache_config(sroot,apache2_config,"{EMAIL}",semail)     # Set WWW Admin Email
        update_apache_config(sroot,apache2_config,"{DOMAIN}",sdomain)   # Set WWW sadmin.{Domain}     
        update_apache_config(sroot,apache2_config,"{SERVICE}",sservice) # Set WWW sadmin log dir
        update_apache_config(sroot,apache2_config,"{SSL_CRT}",SSL_CRT)  # Set Certificate file
        update_apache_config(sroot,apache2_config,"{SSL_KEY}",SSL_KEY)  # Set Certificate Key File

               
    # Update the sadmin.cfg with Web Server User and Group
    #writelog('')
    writelog ("  - SADMIN Web site configuration now in place (%s)" % (apache2_config))
    writelog ("  - Record Apache Process Owner in SADMIN configuration (%s/cfg/sadmin.cfg)" % (sroot))
    update_sadmin_cfg(sroot,"SADM_WWW_USER",apache_user,False)          # Update Value in sadmin.cfg
    update_sadmin_cfg(sroot,"SADM_WWW_GROUP",apache_group,False)        # Update Value in sadmin.cfg

    # Setting Files and Directories Permissions for Web sites 
    writelog ("  - Setting Owner/Group on SADMIN WebSite(%s/www) ... " % (sroot),"nonl") 
    cmd = "chown -R %s.%s %s/www" % (apache_user,apache_group,sroot)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chown on Web Dir.
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem changing Web Site Owner and Group")
        writelog ("%s - %s" % (cstdout,cstderr))        

    # Setting Access permission on web site
    writelog ("  - Setting Permission on SADMIN WebSite (%s/www) ... " % (sroot),"nonl") 
    #cmd = "find %s/www -type d -exec chmod 775 {} \;" % (sroot)        # chmod 775 on all www dir.
    cmd = "find %s/www -type d | xargs chmod 775 " % (sroot)            # chmod 775 on all www dir.
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem changing Web Site permission")
        writelog ("%s - %s" % (cstdout,cstderr))        
    
    # Setting permissions on Website images
    writelog ("  - Setting Permission on SADMIN WebSite images (%s/www/images) ... " % (sroot),"nonl") 
    cmd = "chmod -R 664 %s/www/images/*" % (sroot)                      # chmod 644 on all images
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem changing Website images permission")
        writelog ("%s - %s" % (cstdout,cstderr))        
                

    # Restarting Web Server with new configuration
    cmd = "systemctl restart %s" % (sservice) 
    writelog ("  - Web Server Restarting - %s ..." % (cmd),"nonl")
    ccode,cstdout,cstderr = oscommand(cmd)                          
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem Starting the Web Server",'bold')
        writelog ("%s - %s" % (cstdout,cstderr))        

    # Enable Web Server Service so it restart upon reboot
    cmd = "systemctl enable %s" % (sservice) 
    writelog ("  - Enabling Web Server Service - %s ... " % (cmd),"nonl")
    ccode,cstdout,cstderr = oscommand(cmd)                          
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem enabling Web Server Service",'bold')
        writelog ("%s - %s" % (cstdout,cstderr))        
 


#===================================================================================================
#               Replacing Value in Apache Configuration file by users specified values
#   1st parameter = Name of file,  2nd parameter = Name field to replace,  3rd Parameter = Value
#===================================================================================================
#
def update_apache_config(sroot,sfile,sname,svalue):
    """
    [Update the Apache configuration File.]
    Arguments:
    sroot  {[string]}   --  [Root Dir. of SADMIN]
    sfile  {[string]}   --  [Full Path Apache configuration file]
    sname  {[string]}   --  [Variable name to change value]
    svalue {[string]}   --  [Variable New value]
    """   

    dirname = os.path.dirname(sfile)
    wtmp_file = "%s/apache.tmp" % (dirname)                             # Tmp Apache config file
    wbak_file = "%s/apache.bak" % (dirname)                             # Backup Apache config file
#    wtmp_file = "%s/tmp/apache.tmp" % (sroot)                           # Tmp Apache config file
#    wbak_file = "%s/tmp/apache.bak" % (sroot)                           # Backup Apache config file
    if (DEBUG) :
        writelog ("Update_apache_config - sroot=%s - sfile=%s - sname=%s - svalue=%s\n" % (sroot,sfile,sname,svalue))
        writelog ("\nsfile=%s\nwtmp_file=%s\nwbak_file=%s" % (sfile,wtmp_file,wbak_file))

    fi = open(sfile,'r')                                                # Current Apache Input File
    fo = open(wtmp_file,'w')                                            # New Apache Config File  

    # Replace Line Starting with 'sname' with new 'svalue' 
    for line in fi:                                                     # Read sadmin.cfg until EOF
        sline = line.replace(sname,svalue)
        fo.write (sline)                                                # Write line to output file
    fi.close()                                                          # File read now close it
    fo.close()                                                          # Close the output file

    # Rename Apache Current file to .bak
    try:                                                                # Will try rename env. file
        os.rename(sfile,wbak_file)                                      # Rename Current to tmp
    except:
        writelog ("Error renaming %s to %s" % (sfile,wbak_file))           # Advise user of problem
        sys.exit(1)                                                     # Exit to O/S with Error

    # Rename tmp file to Apache Config file name
    try:                                                                # Will try rename env. file
        os.rename(wtmp_file,sfile)                                      # Rename tmp to sadmin.cfg
    except:
        writelog ("Error renaming %s to %s" % (wtmp_file,sfile))        # Advise user of problem
        sys.exit(1)                                                     # Exit to O/S with Error

    # Remove backup file
    try:                                                                # Will try Remove bak file
        os.remove(wbak_file)                                            
    except:
        writelog ("Error removing %s" % (wbak_file))                    # Advise user of problem
        sys.exit(1)                                                     # Exit to O/S with Error

#===================================================================================================
#   Set and/or Validate that SADMIN Environment Variable is set in /etc/environment file
#===================================================================================================
#
def set_sadmin_env(ver):

    # Is SADMIN Environment Variable Defined ? , If not ask user to specify it
    if "SADMIN" in os.environ:                                          # Is SADMIN Env. Var. Exist?
        sadm_base_dir = os.environ.get('SADMIN')                        # Get SADMIN Base Directory
    else:                                                               # If Not Ask User Full Path
        sadm_base_dir = input("Enter directory path where SADMIN is installed : ")

    # Does Directory specify exist ? , if not exit to O/S with error
    if not os.path.exists(sadm_base_dir) :                              # Check if SADMIN Dir. Exist
        print ("Directory %s doesn't exist." % (sadm_base_dir))         # Advise User
        sys.exit(1)                                                     # Exit with Error Code

    # Validate That Directory specify contain the Shell SADMIN Library 
    libname="%s/lib/sadmlib_std.sh" % (sadm_base_dir)                   # Set Full Path to Shell Lib
    if os.path.exists(libname)==False:                                  # If SADMIN Lib Not Found
        printBold ("The directory %s isn't the SADMIN directory" % (sadm_base_dir)) # Reject Msg
        printBold ("It doesn't contains the file %s\n" % (libname))     # Show Why we Refused
        sys.exit(1)                                                     # Exit with Error Code

    # Ok now we can Set SADMIN Environnement Variable, for the moment
    os.environ['SADMIN'] = sadm_base_dir                                # Setting SADMIN Env. Dir.


    # Making sure that 'export SADMIN=' line is in /etc/profile.d/sadmin.sh (So it survive a reboot)
    SADM_PROFILE='/etc/profile.d/sadmin.sh'                             # SADMIN Environment File
    SADM_TMPFILE='/etc/profile.d/sadmin.tmp'                            # SADMIN New Env. Temp File
    SADM_ORGFILE='/etc/profile.d/sadmin.org'                            # SADMIN Original  Env. File
    SADM_INIFILE="%s/setup/etc/sadmin.sh" % (sadm_base_dir)             # Init. Sadmin Env File

    # If /etc/profile.d/sadmin.sh script don't exist, use template $SADMIN/setup/etc/sadmin.sh.
    if os.path.exists(SADM_PROFILE)==False:                             # /etc/profile.d/admin.sh
        try:
            shutil.copyfile(SADM_INIFILE,SADM_PROFILE)                  # Copy Template of sadmin.sh 
        except IOError as e:
            print("Unable to copy %s to %s" % (SADM_INIFILE,SADM_PROFILE)) # Advise user 
            sys.exit(1)                                                 # Exit to O/S With Error
        except:
            print("Unexpected error:", sys.exc_info())               # Advise Usr Show Error Msg
            sys.exit(1)                                                 # Exit to O/S with Error

    # Form the two lines that need to be in /etc/profile.d/sadmin.sh file
    ppath = os.environ.get('PATH')                                      # Get Current O/S PATH 
    pline = "PATH=%s:%s/bin:%s/usr/bin\n" % (ppath,sadm_base_dir,sadm_base_dir) # PATH EnvVar. Line
    eline = "SADMIN=%s\n" % (sadm_base_dir)                             # SADMIN EnvVar. Line Needed

    # Open the current /etc/profile.d/sadmin.sh in read mode
    # If file don't exist, create it and add line for PATH and one for SADMIN assigment.
    try : 
        fi = open(SADM_PROFILE,'r')                                     # Open SADMIN Env. Setting 
    except FileNotFoundError as e :                                     # If Env file doesn't exist
        fi = open(SADM_PROFILE,'w')                                     # Open in Write Mode(Create)
        fi.write (eline)                                                # Write line to output file
        fi.write (pline)                                                # Write line to output file
        fi.close()                                                      # Just to create file
        fi = open(SADM_PROFILE,'r')                                     # Re-open in read mode

    # Open the new sadmin.sh tmp file to make sure SADMIN variable is set properly
    fo = open(SADM_TMPFILE,'w')                                         # Environment Output File
    fileEmpty=True                                                      # Env. file assume empty
    for line in fi:                                                     # Read Input file until EOF
        if line.startswith('SADMIN=') :                                 # line Start with 'SADMIN='?
           line = "%s" % (eline)                                        # Replace line with latest
        if line.startswith('PATH=') :                                   # line Start with 'SADMIN='?
           line = "%s" % (eline)                                        # Replace line with latest
        fo.write (line)                                                 # Write line to output file
        fileEmpty=False                                                 # File was not empty flag
    fi.close()                                                          # File read now close it
    if (fileEmpty) :                                                    # If Input file was empty
        line = "%s\n" % (eline)                                         # Add line with needed line
        fo.write (line)                                                 # Write 'export SADMIN=' Line
    fo.close()                                                          # Close the output file
    try:                                                                # Will try rename env. file
        os.remove(SADM_PROFILE)                                         # Remove current sadmin.cfg
        os.rename(SADM_TMPFILE,SADM_PROFILE)                            # Rename tmp to real one
    except:
        print ("Error removing or renaming %s" % (SADM_PROFILE))        # Show User if error
        sys.exit(1)                                                     # Exit to O/S with Error


    # Setup /etc/environnment Work Files 
    SADM_ENVFILE='/etc/environment'                                     # System Environment File
    SADM_TMPFILE='/etc/environment.tmp'                                 # System Env. Temp File
    SADM_ORGFILE='/etc/environment.org'                                 # System Original Env. FIle

    # If not already done, make a copy of /etc/environment to /etc/environment.org
    if os.path.exists(SADM_ORGFILE)==False:                             # If Original Copy not exist
        try:
            shutil.copyfile(SADM_ENVFILE,SADM_ORGFILE)                  # Put Template in place
        except IOError as e:
            print("Unable to copy %s to %s" % (SADM_ENVFILE,SADM_ORGFILE)) # Advise user 
            sys.exit(1)                                                 # Exit to O/S With Error
        except:
            print("Unexpected error:", sys.exc_info())               # Advise Usr Show Error Msg
            sys.exit(1)                                                 # Exit to O/S with Error

    # Open the current /etc/environment
    eline = "SADMIN=%s\n" % (sadm_base_dir)                             # Needed in /etc/environment
    try : 
        fi = open(SADM_ENVFILE,'r')                                     # Open SADMIN Env. Setting 
    except FileNotFoundError as e :                                     # If Env file doesn't exist
        fi = open(SADM_ENVFILE,'w')                                     # Open in Write Mode(Create)
        fi.write (eline)                                                # Write SADMIN=Install Dir.
        fi.close()                                                      # Just to create file
        fi = open(SADM_ENVFILE,'r')                                     # Re-open in read mode
    if (DEBUG) : 
        print ("eline = %s" % (eline))

    # Make sure /etc/environment have line SADMIN= Installation Directory
    fo = open(SADM_TMPFILE,'w')                                         # Environment TMP File
    fileUpdated=False                                                   # Env. file Updated
    for line in fi:                                                     # Read Input file until EOF
        line = line.strip()                                             # Del trailing/heading space
        if line.startswith('SADMIN=') :                                 # line Start with 'SADMIN='?
           line = "%s" % (eline)                                        # Replace line with latest
           fileUpdated=True                                             # SADMIN Line Found & Update
        fo.write ("%s\n" % (line))                                      # Write line to output file
    fi.close()                                                          # File read now close it
    if (not fileUpdated) :                                              # SADMIN Line not Updated
        if (DEBUG) : 
            print ("/etc/environment was empty, line '%s' added." % (eline))
        fo.write ("%s\n" % (eline))                                     # Write 'SADMIN=' Line
    fo.close()                                                          # Close the output file
    try:                                                                # Will try rename env. file
        os.remove(SADM_ENVFILE)                                         # Remove current sadmin.cfg
        os.rename(SADM_TMPFILE,SADM_ENVFILE)                            # Rename tmp to real one
    except:
        print ("Error removing or renaming %s" % (SADM_ENVFILE))        # Show User if error
        sys.exit(1)                                                     # Exit to O/S with Error

    print ("Environment variable 'SADMIN' is now set to %s" % (sadm_base_dir))
    print ("  - Line below is now in %s & %s" % (SADM_PROFILE,SADM_ENVFILE)) 
    print ("    %s" % (eline),end='')                                   # SADMIN Line in sadmin.sh
    print ("  - This make 'SADMIN' environment variable persistent across reboot.")
    return (sadm_base_dir)                                              # Return SADMIN Root Dir


#===================================================================================================
#           Make sure $SADMIN/cfg/sadmin.cfg exist, if not cp .sadmin.cfg to sadmin.cfg
#===================================================================================================
#
def create_sadmin_config_file(sroot,sostype):
    cfgfile="%s/cfg/sadmin.cfg" % (sroot)                               # Set Full Path to cfg File
    cfgfileo="%s/cfg/.sadmin.cfg" % (sroot)                             # Template for sadmin.cfg
    if os.path.exists(cfgfile)==False:                                  # If sadmin.cfg Not Found
        try:
            shutil.copyfile(cfgfileo,cfgfile)                           # Copy Template 2 sadmin.cfg
        except IOError as e:
            writelog("Unable to copy file. %s" % e)                     # Advise user before exiting
            sys.exit(1)                                                 # Exit to O/S With Error
        except:
            writelog("Unexpected error:", sys.exc_info())               # Advise Usr Show Error Msg
            sys.exit(1)                                                 # Exit to O/S with Error
    writelog ("  - Initial SADMIN configuration file (%s) created." % (cfgfile)) # Advise User
    writelog (' ')
    


#===================================================================================================
# Replace default line - Put the Sadmin Email as the default value for alert
#
# Parameters: 
#  1st = Root Dir. of SADMIN
#  2nd = Email of Sysadmin entered previously
#
# ===================================================================================================
#
def update_alert_group_default(sroot,semail):
    """
    Create $SADMIN/alert_group.cfg from $SADMIN/cfg/.alert_group.cfg template file
    Change the email address of 'mail_sysadmin' group to sysadmin entered previously.
    Arguments:
    sroot  {[string]}   --  [SADMIN root install directory]
    semail {[string]}   --  [Sysadmin email Address]
    """    

    winput  = "%s/cfg/.alert_group.cfg" % (sroot)                       # AlertGroup Base Def. File
    woutput = "%s/cfg/alert_group.cfg" % (sroot)                        # AlertGroup New Default File
    if (DEBUG) :
        writelog ("In update_alert_group_default - Setting Email to %s \n" % (semail))
        writelog ("\nwinput=%s\nwoutput=%s" % (winput,woutput))

    fi = open(winput,'r')                                               # Open Base AlertGroup File
    fo = open(woutput,'w')                                              # AlertGroup New Default File
    cline = "mail_sysadmin       m   %s\n" % (semail)                   # Line to Insert in AlertGrp

    # Replace Line Starting with default with a new one with sysadmin email.
    lineNotFound=True                                                   # 'mail_sysadmin' != in file
    for line in fi:                                                     # Read sadmin.cfg until EOF
        if line.startswith("%s" % ('mail_sysadmin')) :                  # 'mail_sysadmin' at BOL ?
           line = "%s" % (cline)                                        # Change Line with new one
           lineNotFound=False                                           # Line was found in file
        fo.write (line)                                                 # Write line to output file
    fi.close()                                                          # File read now close it
    if (lineNotFound) :                                                 # Line wasn't found in file
        line = "%s\n" % (cline)                                         # Add needed line
        fo.write (line)                                                 # Write 'SNAME = semail Line
    fo.close()                                                          # Close the output file


#===================================================================================================
#                     Replacing Value in SADMIN configuration file (sadmin.cfg)
#  1st = Root Dir. of SADMIN, 2nd = Name of setting, 3rd = Value of the setting, 4th = Show Upd. line
# ===================================================================================================
#
def update_postfix_cf(sroot,sname,svalue,show=True):

    wcfg_file = "/etc/postfix/main.cf"                                  # Postfix main config file
    wtmp_file = "%s/tmp/main_cf.tmp" % (sroot)                          # Tmp Postfix config file
    wbak_file = "/etc/postfix/main.cf.bak"                              # Backup Postfix config file
    if (DEBUG) :
        writelog ("In update_postfix_cf - sname = %s - svalue = %s\n" % (sname,svalue))
        writelog ("\nwcfg_file=%s\nwtmp_file=%s\nwbak_file=%s" % (wcfg_file,wtmp_file,wbak_file))

    fi = open(wcfg_file,'r')                                            # Current main.cf file
    fo = open(wtmp_file,'w')                                            # Will become new main.cf
    lineNotFound=True                                                   # Assume String not in file
    cline = "%s = %s\n" % (sname,svalue)                                # Line to Insert in file

    # Replace Line Starting with 'sname' with new 'svalue' 
    for line in fi:                                                     # Read sadmin.cfg until EOF
        if line.startswith("%s" % (sname)) :                            # Line Start with SNAME ?
           line = "%s" % (cline)                                        # Change Line with new one
           lineNotFound=False                                           # Line was found in file
        fo.write (line)                                                 # Write line to output file
    if (lineNotFound) :                                                 # SNAME wasn't found in file
        line = "%s" % (cline)                                           # Add line if wasn't present
        fo.write (line)                                                 # Write 'SNAME = SVALUE Line
    fi.close()                                                          # File read now close it
    fo.close()                                                          # Close the output file

    # Rename main.cf to main.cf.bak (if main.cf.bak doesn't already exist)
    if not os.path.isfile(wbak_file):                                   # main.cf.bak doesn't exist
        try:                                                            # Will try rename env. file
            os.rename(wcfg_file,wbak_file)                              # Rename Current to tmp
        except:
            writelog ("Error renaming %s to %s" % (wcfg_file,wbak_file))# Advise user of problem
            sys.exit(1)                                                 # Exit to O/S with Error

    # Put new main.cf in place - Rename $SADMIN/tmp/main_cf.tmp to main.cf
    try:                                                                # Will try rename env. file
        os.rename(wtmp_file,wcfg_file)                                  # Rename tmp to sadmin.cfg
    except:
        writelog ("Error renaming %s to %s" % (wtmp_file,wcfg_file))    # Advise user of problem
        sys.exit(1)                                                     # Exit to O/S with Error

    if (show) : 
        writelog ("[%s] set to '%s' in %s" % (sname,svalue,wcfg_file),'bold') 



#===================================================================================================
#                     Replacing Value in SADMIN configuration file (sadmin.cfg)
#  1st = Root Dir. of SADMIN, 2nd = Name of setting, 3rd = Value of the setting, 4th = Show Upd. line
# ===================================================================================================
#
def update_sadmin_cfg(sroot,sname,svalue,show=True):

    wcfg_file = sroot + "/cfg/sadmin.cfg"                               # Actual sadmin config file
    wtmp_file = "%s/cfg/sadmin.tmp" % (sroot)                           # Tmp sadmin config file
    wbak_file = "%s/cfg/sadmin.bak" % (sroot)                           # Backup sadmin config file
    if (DEBUG) :
        writelog ("In update_sadmin_cfg - sname = %s - svalue = %s\n" % (sname,svalue))
        writelog ("\nwcfg_file=%s\nwtmp_file=%s\nwbak_file=%s" % (wcfg_file,wtmp_file,wbak_file))

    fi = open(wcfg_file,'r')                                            # Current sadmin.cfg File
    fo = open(wtmp_file,'w')                                            # Will become new sadmin.cfg
    lineNotFound=True                                                   # Assume String not in file
    cline = "%s = %s\n" % (sname,svalue)                                # Line to Insert in file

    # Replace Line Starting with 'sname' with new 'svalue' 
    for line in fi:                                                     # Read sadmin.cfg until EOF
        if line.startswith("%s" % (sname.upper())) :                    # Line Start with SNAME ?
           line = "%s" % (cline)                                        # Change Line with new one
           lineNotFound=False                                           # Line was found in file
        fo.write (line)                                                 # Write line to output file
    fi.close()                                                          # File read now close it
    if (lineNotFound) :                                                 # SNAME wasn't found in file
        line = "%s\n" % (cline)                                         # Add needed line
        fo.write (line)                                                 # Write 'SNAME = SVALUE Line
    fo.close()                                                          # Close the output file

    # Rename sadmin.cfg sadmin.bak
    try:                                                                # Will try rename env. file
        os.rename(wcfg_file,wbak_file)                                  # Rename Current to tmp
    except:
        writelog ("Error renaming %s to %s" % (wcfg_file,wbak_file))    # Advise user of problem
        sys.exit(1)                                                     # Exit to O/S with Error

    # Rename sadmin.tmp sadmin.cfg
    try:                                                                # Will try rename env. file
        os.rename(wtmp_file,wcfg_file)                                  # Rename tmp to sadmin.cfg
    except:
        writelog ("Error renaming %s to %s" % (wtmp_file,wcfg_file))    # Advise user of problem
        sys.exit(1)                                                     # Exit to O/S with Error

    if (show) : 
        writelog ("[%s] set to '%s' in %s" % (sname,svalue,wcfg_file),'bold') # Bold Attr. Name in sadmin





#===================================================================================================
#             Accept Integer, Alphanumeric and Password field based on parameter received.
#   1) Root Directory of SADMIN    2) Parameter name in sadmin.cfg    3) Default Value    
#   4) Prompt text                 5) Type of input ([I]nteger [A]lphanumeric [P]assword) 
#   6) smin & smax = Minimum and Maximum value for integer prompt
#===================================================================================================
#
def accept_field(sroot,sname,sdefault,sprompt,stype="A",smin=0,smax=3):
    """
    summary]
        Accept Integer, Alphanumeric and Password field based on parameter received.
        If present Text file ($SADMIN/doc/cfg/sname.lower().txt) is displayed before input.

    Arguments:
        sroot {[string]} -- [Root Directory of SADMIN]
        sname {[string]} -- [Name of doc file to display and appear in Bracket before input]
        sdefault {[any]} -- [Default Value]
        sprompt {[type]} -- [Text to display before input (Question)]

    Keyword Arguments:
        stype {str} -- [Type of input ([I]nteger [A]lphanumeric [P]assword)] (default: {"A"})
        smin  {int} -- [Minimum Value for Integer input] (default: {0})
        smax  {int} -- [Maximum value for Integer input] (default: {3})

    Returns:
        [any] -- [Value entered by user (or default value)]
    """


    # Validate the type of input received (A for alphanumeric, I for Integer, P for Password)
    if (stype.upper() != "A" and stype.upper() != "I" and stype.upper() != "P") :  # Alpha/Int/Pwd
        writelog ("Type of input received is invalid (%s)" % (stype))   # If Not A,I,P - Advise Usr
        writelog ("Expecting [I]nteger, [A]lphanumeric and [P]assword") # Question is Skipped
        return 1                                                        # Return Error to caller
 
    # Print Field name we will input (name used in sadmin.cfg file)
    writelog (" ")
    writelog ("----------")
    if sname != "" : 
        writelog ("[%s]" % (sname),'bold')                              # Bold Attr. Name in sadmin

    # Display field documentation file  
    docname = "%s/setup/msg/%s.txt" % (sroot,sname.lower())             # Set Documentation FileName
    try :                                                               # Try to Open Doc File
        doc = open(docname,'r')                                         # Open Documentation file
        for line in doc:                                                # Read Doc. file until EOF
            if ((line.startswith("#")) or (len(line) == 0)):            # Line Start with # or empty
               continue                                                 # Skip Line that start with#
            writelog ("%s" % (line.rstrip()))                           # Print Documentation Line
        doc.close()                                                     # Close Document File
    except FileNotFoundError:                                           # If no mesg file to show
        pass
    #    writelog ("Doc file %s not found, question skipped" % (docname))   # Advise User, Question Skip
    #writelog ("--------------------")+++++++

    # Accept a Password from the user    
    if (stype.upper() == "P"):                                          # If Password Input
        wdata=""
        while (wdata == ""):                                            # Input until something 
            wdata = getpass.getpass("%s : " % (sprompt))                # Accept Password
            wdata = wdata.strip()                                       # Del leading/trailing space
            if (len(wdata) == 0) : wdata = sdefault                     # No Input = Default Value
            return wdata                                                # Return Data to caller

    # Accept Alphanumeric Value from the user    
    if (stype.upper() == "A"):                                          # If Alphanumeric Input
        wdata=""
        while (wdata == ""):                                            # Input until something 
            eprompt = sprompt                                           # Save Default Prompt Unmodified
            if len(sdefault) != 0:                                     # If Default Value received
                eprompt = sprompt + " [" + color.BOLD + sdefault + color.END + "]" # Ins Def. Val. in prompt
            wdata = input("%s : " % (eprompt))                          # Accept user response
            wdata = wdata.strip()                                       # Del leading/trailing space
            if (len(wdata) == 0) : wdata = sdefault                     # No Input = Default Value
            return wdata                                                # Return Data to caller

    # Accept Integer Value from the user    
    if (stype.upper() == "I"):                                          # If Numeric Input
        wdata = 0                                                       # Where response is store
        while True:                                                     # Loop until Valid response
            eprompt = sprompt + " [" + color.BOLD + str(sdefault) + color.END + "]" # Ins Def. in prompt
            wdata = input("%s : " % (eprompt))                          # Accept an Integer
            if len(wdata) == 0 : wdata = sdefault
            try:
                wdata = int(wdata)
            except ValueError as e:                                     # If Value is not an Integer
                writelog ("Value Error - Not an integer (%s)" % (wdata)) # Advise User Message
                continue                                                # Continue at start of loop
            except TypeError as e:                                      # If Value is not an Integer
                writelog ("Type Error - Not an integer (%s)" % (wdata)) # Advise User Message
                continue                                                # Continue at start of loop
            if (wdata == 0) : wdata = sdefault                          # No Input = Default Value
            if (wdata > smax) or (wdata < smin):                        # Must be between min & max
                writelog ("Value must be between %d and %d" % (smin,smax)) # Input out of Range 
                continue                                                # Continue at start of loop
            break                                                       # Break out of the loop

    return wdata



#===================================================================================================
# Setup postfix configuration (/etc/postfix/main.cf)
#===================================================================================================
#
def setup_postfix(sroot,wostype,wsmtp_server,wsmtp_port,wsmtp_sender,wsmtp_pwd,sosname):

    if wostype != "LINUX" : return                                      # Configure Only on Linux

    # What is the package type (rpm or debian)
    if (locate_command('rpm')   != "") : packtype="rpm"                 # Is rpm command on system ? 
    if (locate_command('dpkg')  != "") : packtype="deb"                 # is deb command on system ?

    # Make sure postfix is installed
    needed_packages="postfix"
    writelog("Configuring postfix ...")
    if (packtype == "deb") :                                            # If Package type is '.deb'
        icmd = "DEBIAN_FRONTEND=noninteractive "                        # No Prompt While installing
        icmd += "apt -y install %s >>%s 2>&1" % (needed_packages,'/dev/null')
    if (packtype == "rpm") :                                            # If Package type is '.rpm'
        icmd = "dnf install -y %s >>%s 2>&1" % (needed_packages,'/dev/null')
    ccode, cstdout, cstderr = oscommand(icmd)
    if (ccode != 0) : 
        writelog("[ WARNING ] Package 'postfix' is not available on %s." % sosname.capitalize())

    maincf="/etc/postfix/main.cf"                                       # Postfix Config FileName
    if not os.path.isfile(maincf): return                               # Postfix not installed

    # Update lines in main.cf
    #update_postfix_cf(sroot,"inet_interfaces","\$myhostname,localhost")
    #update_postfix_cf(sroot,"myhostname",phostname)
    update_postfix_cf(sroot,"smtp_use_tls","yes")
    update_postfix_cf(sroot,"smtp_sasl_auth_enable","yes")
    update_postfix_cf(sroot,"smtp_sasl_security_options","noanonymous")
    update_postfix_cf(sroot,"smtp_sasl_password_maps","hash:/etc/postfix/sasl_passwd")
 
    relayhost =  "[%s]:%d" % (wsmtp_server,wsmtp_port)  
    update_postfix_cf(sroot,"relayhost",relayhost)
    
    # Create/Update /etc/postfix/sasl_passwd  
    pfix_pwd = "/etc/postfix/sasl_passwd"
    sasl =  "[%s]:%d %s:%s\n" % (wsmtp_server,wsmtp_port,wsmtp_sender,wsmtp_pwd) 
    fpw = open(pfix_pwd,'w')                                            # Will become sass_passwd
    fpw.write (sasl)                                                    # Server:port User:Pwd
    fpw.close()                                                         # Close file
    os.chmod(pfix_pwd, 0o600)

    ccode,cstdout,cstderr = oscommand("postmap %s" % (pfix_pwd))
    if (ccode != 0):
        writelog ("Problem running postmap command")
        writelog ("%s - %s" % (cstdout,cstderr)) 
    
    ccode,cstdout,cstderr = oscommand("systemctl restart postfix && systemctl enable postfix") 
    if (ccode != 0):
        writelog ("Problem restarting postfix ")
        writelog ("%s - %s" % (cstdout,cstderr)) 
    
    #writelog ("Changing finger information for root")
    #ccode,cstdout,cstderr = oscommand("chfn -f sadmin root")
    #if (ccode != 0):
    #    writelog ("Problem running postmap command")
    #    writelog ("%s - %s" % (cstdout,cstderr)) 
    
    return()



#===================================================================================================
# ASK IMPORTANT INFO THAT NEED TO BE ACCURATE IN THE $SADMIN/CFG/SADMIN.CFG FILE
#===================================================================================================
#
def setup_sadmin_config_file(sroot,wostype,sosname):
#"""[Ask important info that need to be accurate in the $sadmin/cfg/sadmin.cfg file]
#    It Return SADMIN ServerName, ServerIP, Default, SysAdminEmail, SadminUser, SadminGroup
#
#Arguments:
#    sroot {[string]} -- [Install Directory Path]
#    wostype {[string]} -- [O/S Type (LINUX,AIX,DARWIN)]
#"""    
    global stype                                                        # C=Client S=Server Install


    # Is the current server a SADMIN [S]erver or a [C]lient
    sdefault = "C"                                                      # This is the default value
    sname    = "SADM_HOST_TYPE"                                         # Var. Name in sadmin.cfg
    sprompt  = "Host will be a SADMIN [S]erver or a [C]lient"           # Prompt for Answer
    wcfg_host_type = ""                                                 # Define Var. First
    while ((wcfg_host_type.upper() != "S") and (wcfg_host_type.upper() != "C")): # Loop until S or C
        wcfg_host_type = accept_field(sroot,sname,sdefault,sprompt)     # Go Accept Response 
    wcfg_host_type = wcfg_host_type.upper()                             # Make Host Type Uppercase
    update_sadmin_cfg(sroot,"SADM_HOST_TYPE",wcfg_host_type)            # Update Value in sadmin.cfg
    stype = wcfg_host_type                                              # Save Host Intallation type


    # Accept the Company Name
    sdefault = ""                                                       # This is the default value
    sprompt  = "Enter your Company Name"                                # Prompt for Answer
    wcfg_cie_name = ""                                                  # Clear Cie Name
    while (wcfg_cie_name == ""):                                        # Until something entered
        wcfg_cie_name = accept_field(sroot,"SADM_CIE_NAME",sdefault,sprompt)# Accept Cie Name
    update_sadmin_cfg(sroot,"SADM_CIE_NAME",wcfg_cie_name)              # Update Value in sadmin.cfg


    # Accept SysAdmin Email address
    sdefault = "" 
    sprompt  = "Enter System Administrator Email"                       # Prompt for Answer
    wcfg_mail_addr = ""                                                 # Clear Email Address
    while True :                                                        # Until Valid Email Address
        wcfg_mail_addr = accept_field(sroot,"SADM_MAIL_ADDR",sdefault,sprompt)
        x = wcfg_mail_addr.split('@')                                   # Split Email Entered 
        if (len(x) != 2):                                               # If not 2 fields = Invalid
            writelog ("Invalid email address - no '@' sign",'bold')     # Advise user no @ sign
            continue                                                    # Go Back Re-Accept Email
        try :
            xip = socket.gethostbyname(x[1])                            # Try Get IP of Domain
        except (socket.gaierror) as error :                             # If Can't - domain invalid
            writelog ("The domain %s is not valid" % (x[1]),'bold')     # Advise User
            continue                                                    # Go Back re-accept email
        break                                                           # Ok Email seem valid enough
    update_sadmin_cfg(sroot,"SADM_MAIL_ADDR",wcfg_mail_addr)            # Update Value in sadmin.cfg 
    update_alert_group_default(sroot,wcfg_mail_addr)                    # Upd. AlertGroup Def. Email 


    # Accept the Alert type to use at the end of each script execution
    # 0=No Alert Sent, 1=On Error Only, 2=On Success Only, 3=Always send alert    
    sdefault = 1                                                        # Default value 1
    sprompt  = "Enter default alert type"                               # Prompt for Answer
    wcfg_mail_type = accept_field(sroot,"SADM_ALERT_TYPE",sdefault,sprompt,"I",0,3)
    update_sadmin_cfg(sroot,"SADM_ALERT_TYPE",wcfg_mail_type)           # Update Value in sadmin.cfg


    # Accept the Default Domain Name
    try :
        sdefault = socket.getfqdn(socket.gethostname(  )).split('.',1)[1] # Get Domain Name of host
    except (IndexError) as error :
        sdefault = ""
    while True:   
        sprompt  = "Enter default domain name"                          # Prompt for Domain Name
        wcfg_domain = accept_field(sroot,"SADM_DOMAIN",sdefault,sprompt)# Accept Default Domain Name
        if (len(wcfg_domain) < 1):                                      # If DomainName is Blank
            writelog ("  ")
            writelog ("ERROR : You must specify a domain name")         # Advise USer
            continue                                                    # Go Re-Accept Domain Name
        break                                                           # Ok Name pass the test
    update_sadmin_cfg(sroot,"SADM_DOMAIN",wcfg_domain)                  # Update Value in sadmin.cfg


    # Accept the SADMIN FQDN Server name
    sdefault = ""                                                       # No Default value 
    sprompt  = "Enter SADMIN server IP address "    
    while True:                                                         # Accept until valid server
        wcfg_ip = accept_field(sroot,"SADM_SERVER",sdefault,sprompt)    # Accept SADMIN Server Name
        isSuccessful = ping(wcfg_ip) 
        if not isSuccessful :
            writelog ("  ")
            writelog ("[ ERROR ] Was not able to ping this ip, please retry.")
            continue
        digit1=wcfg_ip.split('.')[0]                                    # 1st Digit=127 = Invalid
        if ((digit1 == "127") or (wcfg_ip.count(".") != 3)):            # If Resolve to loopback IP
            writelog ("  ")
            writelog ("[ ERROR ] There is not 3 period in IP, you have %d." % (wcfg_ip.count(".")))
            writelog ("          Or you specify a loopback address witch is invalid.")
            continue
        break                                                  # Go Re-Accept Server Name
    host_line = "%s     sadmin.%s     sadmin" % (wcfg_ip, wcfg_domain)
    with open('/etc/hosts', 'a') as file: file.write("%s\n" % (host_line))
    writelog ("")
    writelog ("Line '%s' was added to /etc/hosts." % (host_line))
    wcfg_server = "%s.%s" % (phostname,wcfg_domain)
    sadmin_server= "sadmin.%s" % wcfg_domain
    update_sadmin_cfg(sroot,"SADM_SERVER",sadmin_server)                 # Update Value in sadmin.cfg


    # Accept PostFix RelayHost
    #sdefault = ""                                                       # No Default Value
    #sprompt  = "Enter Postfix Internet mail relayhost (for postfix)"    # Prompt for Relay Host
    #wcfg_prelay = ""                                                    # Clear Field
    #while (wcfg_prelay == ""):                                          # Until something entered
    #    wcfg_prelay = accept_field(sroot,"SADM_RELAYHOST",sdefault,sprompt) # Accept RelayHost
    #setup_postfix(sroot,wostype,wcfg_prelay)                            # Set relayhost in main.cf


    # Accept smtp mail server, where to send email (Default smtp-gmail.com)
    # Use by python Library to send email
    while True :  
        sdefault = "smtp.gmail.com"                                     # Default Your ISP SMTP
        sprompt  = "Enter your ISP SMTP server name"                    # Prompt for Answer
        wsmtp_server = accept_field(sroot,"SADM_SMTP_SERVER",sdefault,sprompt)
        ccode,cstdout,cstderr = oscommand("host %s >/dev/null 2>&1" % (wsmtp_server))
        if ccode != 0 :                                                 # smtp name can't be resolve
            writelog("The smtp host name '%s' cannot be resolved." % (wsmtp_server))
            continue                                                    # Go ReAccept the smtp name
        break
    update_sadmin_cfg(sroot,"SADM_SMTP_SERVER",wsmtp_server)            # Update Value in sadmin.cfg

    # Accept smtp server port (25, 465, 587 or 2525)
    # For Google it's 'smtp.gmail.com'
    sdefault = 587                                                      # Default SMTP Port No.
    sprompt  = "Enter SMTP port number"                                 # Prompt for Answer
    while True :  
        wsmtp_port = accept_field(sroot,"SADM_SMTP_PORT",sdefault,sprompt,'I',25,2525)
        if wsmtp_port != 25 and wsmtp_port != 465 and wsmtp_port != 587 and wsmtp_port != 2525 :
            writelog("Invalid port number, valid smtp port are 25, 465, 587 or 2525")
            continue                                                    # Go Back Re-Accept Email
        break
    update_sadmin_cfg(sroot,"SADM_SMTP_PORT",wsmtp_port)                # Update Value in sadmin.cfg

    # Accept sender email address
    sdefault = "account@gmail.com"                                      # Default SMTP Port No.
    sprompt  = "Enter sender email address "                            # Prompt for Answer
    wsmtp_sender = ""                                                   # Clear Email Address
    while True :                                                        # Until Valid Email Address
        wsmtp_sender = accept_field(sroot,"SADM_SMTP_SENDER",sdefault,sprompt)
        x = wsmtp_sender.split('@')                                     # Split Email Entered 
        if (len(x) != 2):                                               # If not 2 fields = Invalid
            writelog ("Invalid email address - no '@' sign",'bold')     # Advise user no @ sign
            continue                                                    # Go Back Re-Accept Email
        try :
            xip = socket.gethostbyname(x[1])                            # Try Get IP of Domain
        except (socket.gaierror) as error :                             # If Can't - domain invalid
            writelog ("The domain %s is not valid" % (x[1]),'bold')     # Advise User
            continue                                                    # Go Back re-accept email
        break        
    update_sadmin_cfg(sroot,"SADM_SMTP_SENDER",wsmtp_sender)            # Update Value in sadmin.cfg

    # Accept smtp user password 
    sdefault = ""                                                       # No Default for user pwd 
    sprompt  = "Enter SMTP user password "                              # Prompt for User password
    while True :  
        #wsmtp_pwd = accept_field(sroot,"SADM_SMTP_PWD",sdefault,sprompt,'A')
        wsmtp_pwd = accept_field(sroot,"SADM_SMTP_PWD",sdefault,sprompt,'P')
        if len(wsmtp_pwd) < 1 :                                         # Need at least 1 Char
            writelog ("You need to give your user password.")           # Advise user 
            continue 
        break
    writelog(" ")
    setup_postfix(sroot,wostype,wsmtp_server,wsmtp_port,wsmtp_sender,wsmtp_pwd,sosname) 

    # Accept the maximum number of lines we want in every log produce
    sdefault = 400                                                      # No Default value 
    sprompt  = "Maximum number of lines in LOG files"                   # Prompt for Answer
    wcfg_max_logline = accept_field(sroot,"SADM_MAX_LOGLINE",sdefault,sprompt,"I",1,10000)
    update_sadmin_cfg(sroot,"SADM_MAX_LOGLINE",wcfg_max_logline)        # Update Value in sadmin.cfg

    # Accept the maximum number of lines we want in every RCH file produce
    sdefault = 20                                                       # No Default value 
    sprompt  = "Maximum number of lines in history (.rch) files"        # Prompt for Answer
    wcfg_max_rchline = accept_field(sroot,"SADM_MAX_RCHLINE",sdefault,sprompt,"I",1,300)
    update_sadmin_cfg(sroot,"SADM_MAX_RCHLINE",wcfg_max_rchline)        # Update Value in sadmin.cfg


    # Accept the Default User Group
    sdefault = "sadmin"                                                 # Set Default value 
    if wostype == "DARWIN" :                                            # Under MacOS
        sdefault = "staff"                                              # Set MacOS Default Group
    sprompt  = "Enter SADMIN User Group"                                # Prompt for Answer
    wcfg_group=accept_field(sroot,"SADM_GROUP",sdefault,sprompt)        # Accept Defaut SADMIN Group
    found_grp = False                                                   # Not in group file Default
    with open('/etc/group',mode='r') as f:                              # Open the system group file
        for line in f:                                                  # For every line in Group
            if line.startswith( "%s:" % (wcfg_group) ):                 # If Line start with Group:
                found_grp = True                                        # Found Grp entered in file
    if (found_grp == True):                                             # Group were found in file
        writelog("Group %s is an existing group" % (wcfg_group),'bold') # Existing group Advise User 
    else:
        writelog ("Creating group '%s' ... " % (wcfg_group),"nonl")     # Show creating the group
        if wostype == "LINUX" :                                         # Under Linux
            ccode,cstdout,cstderr = oscommand("groupadd %s" % (wcfg_group))   # Add Group on Linux
        if wostype == "AIX" :                                           # Under AIX
            ccode,cstdout,cstderr = oscommand("mkgroup %s" % (wcfg_group))    # Add Group on Aix
        if wostype == "DARWIN" :                                        # Under MacOS
            writelog ("Group %s doesn't exist, create it and rerun this script")
            writelog ("We can't create group for the moment")           # Advise USer
            sys.exit(1)                                                 # Exit to O/S  
        if (ccode == 0) :                                               # If Group Creation went well
            writelog ("Group '%s' created." % (wcfg_group))             # Show action action result
        else:                                                           # If Error creating group
            writelog ("Error %s creating group '%s'" % (ccode,wcfg_group))# Show AddGroup Cmd Error No
            writelog ("%s" % cstderr )                                  # Show AddGroup Cmd Error No
    update_sadmin_cfg(sroot,"SADM_GROUP",wcfg_group)                    # Update Value in sadmin.cfg


    # Accept the Default User Name
    sdefault = "sadmin"                                                 # Set Default value 
    sprompt  = "Enter the default user name"                            # Prompt for Answer
    wcfg_user = accept_field(sroot,"SADM_USER",sdefault,sprompt)        # Accept default SADMIN User
    found_usr = False                                                   # Not in user file Default
    with open('/etc/passwd',mode='r') as f:                             # Open System user File
        for line in f:                                                  # For every line in passwd
            if line.startswith( "%s:" % (wcfg_user) ):                  # Line Start with user name 
                found_usr = True                                        # Found User in passwd file
    if (found_usr == True):                                             # User Name found in file
        writelog ("User %s is an existing user" % (wcfg_user),'bold')   # Existing user Advise user
        writelog ("Add user %s to group %s" % (wcfg_user,wcfg_group),'bold')
        if wostype == "LINUX" :                                         # Under Linux
            cmd = "usermod -g %s %s" % (wcfg_group,wcfg_user)           # Add group to User Command 
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Create User
        if wostype == "AIX" :                                           # Under AIX
            cmd = "chuser pgrp='%s' %s" % (wcfg_group,wcfg_user)        # Build chuser command
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Create User
        if wostype == "DARWIN" :                                        # Under MacOS
            writelog ("User %s doesn't exist, create it and rerun this script")
            writelog ("We can't create user for the moment")            # Advise USer
            sys.exit(1)                                                 # Exit to O/S  
        if (DEBUG):                                                     # If Debug Activated
            writelog ("Return code is %d" % (ccode))                    # Show AddGroup Cmd Error #
    else:
        writelog ("Creating user '%s' ... " % (wcfg_user))              # Create user on system
        if wostype == "LINUX" :                                         # Under Linux
            cmd = "useradd -g %s -s /bin/bash " % (wcfg_group)          # Build Add user Command 
            cmd += " -m -d /home/%s "    % (wcfg_user)                  # Assign Home Directory
            cmd += " -c'%s' -e '' %s" % ("SADMIN Tools User",wcfg_user) # Comment,user name,noexpire
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Create User

            # Under Debian/Ubuntu/Rasbian Home Directory not created
            #uhome="/home/%s" % (wcfg_user)
            #; mkdir $WHOME ; chown git.git $WHOME ; chmod 700 $WHOME

            #cmd = "echo 'Gotham20!' | passwd --stdin %s" % (wcfg_user)     # Cmd to assign password
            cmd = "usermod -p '$6$gfz87SfX$XA2N1ZXl79D3Z2C/gtp1d1rba7TenH2XzweeF9oKGIMGzdabzxKF8f9SCsu7m304BoCjal.h/UGMJ4UUKMuF4/' %s" % (wcfg_user)
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Assign Password
            #writelog ("The password 'Gotham20!' have been assign to '%s' user." % (wcfg_user),'bold') 
            #writelog ("We strongly recommend that you change it after installation.",'bold') 
        if wostype == "AIX" :                                           # Under AIX
            cmd = "mkuser pgrp='%s' -s /bin/ksh " % (wcfg_group)        # Build mkuser command
            cmd += " home='%s' " % (os.environ.get('SADMIN'))           # Set Home Directory
            cmd += " gecos='%s' %s" % ("SADMIN Tools User",wcfg_user)   # Set comment and user name
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Create User
        if (ccode != 0) :                                               # If Group Creation went well
            writelog ("Error %s creating user %s" % (ccode,wcfg_user))  # Show AddUser Cmd Error No 
            writelog (cmd)
            writelog (cstderr)                                          # Show Error msg returned
    update_sadmin_cfg(sroot,"SADM_USER",wcfg_user)                      # Update Value in sadmin.cfg
    

    # Accept the sadmin user password
    sdefault  = ""                                                      # No Default value 
    sprompt   = "Enter the '%s' user password" % (wcfg_user)            # Prompt for user password
    wcfg_upwd = accept_field(sroot,"SADM_USER_PASS",sdefault,sprompt,"P") # Accept password.
    # Set sadmin user password
    #cmd = "chpasswd \<\<\< %s:%s" % (wcfg_user,wcfg_upwd) 
    cmd = "echo %s:%s | chpasswd" % (wcfg_user,wcfg_upwd) 
    #cmd = "echo %s | passwd --stdin %s" % (wcfg_upwd,wcfg_user)         # Set user passwd command
    ccode, cstdout, cstderr = oscommand(cmd)                            # Set user password
    if (ccode != 0) :                                                   # If Group Creation went well
        writelog ("Error setting '%s' user password." % (wcfg_user)) 
        writelog (cmd)
        writelog (cstderr)                                              # Show Error msg returned
        writelog ("Continuing installation.")                           # Show Error msg returned
    # Set sadmin user to expire (Force to change upon next login).
    cmd = "passwd --expire %s" % (wcfg_user)                            # Set password to expire
    ccode, cstdout, cstderr = oscommand(cmd)                            # Go Create User
    if (ccode != 0) :                                                   # If Group Creation went well
        writelog ("Error setting '%s' password to expire." % (wcfg_user)) 
        writelog (cmd)
        writelog (cstderr)                                              # Show Error msg returned
        writelog ("Continuing installation.")                           # Show Error msg returned
    #writelog("pwd=%s" % wcfg_user)

    # Change owner of all files in $SADMIN
    writelog (" ")
    writelog ("----------")
    writelog ("Please wait while we set the owner and group of %s directories ..." % (sroot))
    #cmd = "find %s -exec chown %s.%s {} \;" % (sroot,wcfg_user,wcfg_group)
    cmd = "find %s | xargs chown %s.%s " % (sroot,wcfg_user,wcfg_group)
    if (DEBUG):
        writelog (" ")                                                  # White Line
        writelog ("Setting %s ownership : %s" % (sroot,cmd))            # Show what we are doing
    ccode, cstdout, cstderr = oscommand(cmd)                            # Change SADMIN Dir Owner 



    # Questions ask only if on the SADMIN Server
    if (wcfg_host_type == "S"):                                         # If Host is SADMIN Server
        
        # Accept the default SSH port your use
        sdefault = 22                                                   # SSH Port Default value 
        sprompt  = "SSH port number to connect to client"               # Prompt for Answer
        wcfg_ssh_port = accept_field(sroot,"SADM_SSH_PORT",sdefault,sprompt,"I",1,65536)
        update_sadmin_cfg(sroot,"SADM_SSH_PORT",wcfg_ssh_port)          # Update Value in sadmin.cfg
        
        # Accept the Network IP
        sdefault = "192.168.1.0"                                        # Network Default value 
        sprompt  = "Enter the network IP"                               # Prompt for Answer
        wcfg_network1a = accept_field(sroot,"SADM_NETWORK1",sdefault,sprompt) # Accept Net to Watch
        
        # Accept the Network Netmask
        sdefault = "24"                                                 # Network Mask Default value 
        sprompt  = "Enter the network netmask [1-30]"                   # Prompt for Answer
        wcfg_network1b = accept_field(sroot,"SADM_NETMASK1",sdefault,sprompt,"I",1,30) # NetMask
        update_sadmin_cfg(sroot,"SADM_NETWORK1","%s/%s" % (wcfg_network1a,wcfg_network1b))
    else:
        wcfg_ssh_port=22
        
    return(wcfg_server,wcfg_ip,wcfg_domain,wcfg_mail_addr,wcfg_user,wcfg_group,wcfg_ssh_port) 
    wcfg_ssh_port


#===================================================================================================
# DETERMINE THE INSTALLATION PACKAGE TYPE OF CURRENT O/S AND OPEN THE SCRIPT LOG FILE 
#
# Return :
#   Package Type (deb,rpm,dmg,aix)
#   O/S Name (AIX/CENTOS/REDHAT,UBUNTU,ROCKY,ALMA,DEBIAN,RASPBIAN,...)
#   O/S Major Version Number
#   O/S Running in 32 or 64 bits (32,64)
#   O/S Architecture (Aarch64,Armv6l,Armv7l,I686,X86_64)
#===================================================================================================
#
def getpacktype(sroot,sostype):

    # Determine type of software package format based on command present on system 
    packtype=""                                                         # Initial Packaging is None
    if (locate_command('rpm')   != "") : packtype="rpm"                 # Is rpm command on system ?
    if (locate_command('dpkg')  != "") : packtype="deb"                 # is deb command on system ?
    if (locate_command('lslpp') != "") : packtype="aix"                 # Is lslpp cmd on system ?
    if (locate_command('launchctl') != "") : packtype="dmg"             # launchctl MacOS on system?
    if (packtype == ""):                                                # If unknow/unsupported O/S
        writelog ('None of these commands are found (rpm, pkg, dmg or lslpp absent)')
        writelog ('No supported package type is detected')
        writelog ('Process aborted')
        sys.exit(1)                                                     # Exit to O/S  

    # Get O/S Distribution Name                                         # CentOS,Redhat,
    if os.path.isfile('/usr/bin/lsb_release') : 
        wcmd = "%s %s" % ("lsb_release","-si")
        ccode, cstdout, cstderr = oscommand(wcmd)
        osname=cstdout.upper()
    else: 
        try: 
            osname=os_dict['ID'].upper()
        except KeyError as e:     
            writelog('Cannot determine O/S distrobution')
    if osname == "REDHATENTERPRISESERVER" : osname="REDHAT"
    if osname == "RHEL"                   : osname="REDHAT"
    if osname == "REDHATENTERPRISEAS"     : osname="REDHAT"
    if osname == "REDHATENTERPRISE"       : osname="REDHAT"
    if osname == "CENTOSSTREAM"           : osname="CENTOS"

    # Get O/S Major Version Number
    if sostype == "LINUX" :
        if os.path.isfile('/usr/bin/lsb_release') : 
            ccode, cstdout, cstderr = oscommand("lsb_release" + " -sr")
            osver=cstdout
        else:
            try: 
                osver=os_dict['VERSION_ID']
            except KeyError as e:     
                osver="0.0"
    if sostype == "AIX" :
        ccode, cstdout, cstderr = oscommand("uname -v")
        osver=cstdout
    if sostype== "DARWIN":
        wcmd = "sw_vers -productVersion | awk -F '.' '{print $1 \".\" $2}'"
        ccode, cstdout, cstderr = oscommand(wcmd)
        osver=cstdout

    # Get running kernel bits (32 or 64)
    cstdout = 64
    if sostype == "LINUX" :                                              # Under Linux
        ccode, cstdout, cstderr = oscommand("getconf LONG_BIT")
    if sostype == "AIX" :                                                # Under AIX
        ccode, cstdout, cstderr = oscommand("getconf KERNEL_BITMODE")
    osbits=cstdout

    # Get the O/S Architecture (Aarch64,Armv6l,Armv7l,I686,X86_64)
    if sostype == "LINUX" or sostype == "DARWIN" :
        ccode, cstdout, cstderr = oscommand("arch")
        osarch=cstdout
    if sostype == "AIX" :
        ccode, cstdout, cstderr = oscommand("uname -p")
        osarch=cstdout

    return (packtype,osname,osver,osbits,osarch)                        # Return Packtype & O/S Name



#===================================================================================================
# Just before ending - Run some SADM scripts to gather information and feed database/Web Interface 
#===================================================================================================
#
def run_script(sroot,sname):
    run_status = False                                                  # Default Run Failed
    writelog("Running '%s/bin/%s' script ... " % (sroot,sname),"nonl")  # Show User Script running
    script = "%s/bin/%s" % (sroot,sname)                                # Bld Full Path Script name
    ccode,cstdout,cstderr = oscommand(script)                           # Execute Script
    if (ccode == 0):                                                    # Command Execution Went OK
        writelog(" [ OK ]")                                             # Inform User
        run_status = True                                               # Return Value will be True
    else:                                                               # If Problem with the insert
        writelog("Problem running %s" % (script))                       # Infor User
        writelog("Error No.%d" % (ccode))                               # Show Error#
        writelog("Standard Output :")                                   # Show Stdout header
        writelog("%s" % (cstdout))                                      # Show Stdout content
        writelog("Standard Error :")                                    # Show Stderr header
        writelog("%s" % (cstderr))                                      # Show Stderr content
    return (run_status)                                                 # Return Insert Status


#===================================================================================================
#                                 END OF SCRIPT - MESSAGE TO USER
#===================================================================================================
#
def end_message(sroot,sdomain,sserver,stype):
    writelog ("\n\n\n")
    writelog ("SADMIN tools successfully installed",'bold')
    writelog ("===========================================================================")
    writelog ("You need to logout & log back in before using SADMIN (or reboot).")
    writelog ("Or you can type the command ; '. /etc/profile.d/sadmin.sh', that will ")
    writelog ("define the 'SADMIN' environment variable.")
    if (stype == "S") :
        writelog (" ")
        writelog ("TAKE A LOOK AT 'SADMIN' WEB INTERFACE.",'bold')
        writelog ("The Web interface is available at : https://sadmin.%s" % (sdomain))
        writelog ("  - Use it to add, update and delete system in your server farm.")
        writelog ("  - View performance graph of your systems up to two years in the past.")
        writelog ("  - If you want, you can schedule automatic O/S update of your systems.")
        writelog ("  - Have system configuration on hand, useful in case of a disaster recovery.")
        writelog ("  - View your systems subnet utilization and see what IP are free or not.")
        writelog ("  - Copy the templates to start your new Python or Bash script.")
        writelog ("    - You can then view any system script log and result file on the web interface (or CLI).")
        writelog ("  - SADMIN is tested without SELinux 'SELINUX=disabled' in /etc/selinux/config.")
        writelog ("    - If you need to use it, modify the configuration to access the web interface.")
    writelog (" ")
    writelog ("RUN ONE OF THE TEMPLATES",'bold')
    writelog ("  - $ sudo $SADMIN/bin/templates/sadm_template.sh")
    writelog ("  - $ sudo $SADMIN/bin/templates/sadm_template_with_db.sh")
    writelog ("  - $ sudo $SADMIN/bin/templates/sadm_template.py")
    writelog ("  - $ sudo $SADMIN/bin/templates/sadm_template_with_db.py")
    writelog ("  - $ sudo $SADMIN/bin/templates/sadm_template_menus.sh")
    writelog (" ")
    writelog ("CREATE YOUR OWN SCRIPT USING SADMIN TEMPLATES",'bold')
    writelog ("  - cp $SADMIN/bin/templates/sadm_template.sh $SADMIN/usr/bin/ScriptName.sh")
    writelog ("  - cp $SADMIN/bin/templates/sadm_template.py $SADMIN/usr/bin/ScriptName.py")
    writelog ("  - cp $SADMIN/bin/templates/sadm_template_with_db.sh $SADMIN/usr/bin/ScriptName.sh")
    writelog ("  - cp $SADMIN/bin/templates/sadm_template_with_db.py $SADMIN/usr/bin/ScriptName.py")
    writelog ("  - Visit the Bash template documentation page at https://sadmin.ca/sadm-template-sh/")
    writelog ("  - Visit the Python template documentation page at https://sadmin.ca/sadm-template-py/")
    writelog ("  - Run any of the templates and see how simple they are.") 
    writelog (" ")
    writelog ("RUN ONE OF THE LIBRARY USAGE DEMO",'bold')
    writelog ("  - $ sudo $SADMIN/bin/sadmlib_std_demo.sh")
    writelog ("  - $ sudo $SADMIN/bin/sadmlib_std_demo.py")
    writelog (" ")
    writelog ("USE THE WRAPPER TO RUN YOUR EXISTING SCRIPT & ENJOY THE BENEFITS.",'bold')
    writelog ("  - $SADMIN/bin/sadm_wrapper.sh /YourPath/YourScript.sh")
    writelog ("\n===========================================================================")
    writelog ("ENJOY !!",'bold')



#===================================================================================================
# Activate SADMIN Service 
#   - Startup Script ($SADMIN/sys/sadm_startup.sh) 
#   - Shutdown Script ($SADMIN/sys/sadm_shutdown.sh) 
#===================================================================================================
#
def sadmin_service(sroot):

    writelog (" ")
    writelog ("----------")
    writelog ("Creating SADMIN service unit",'bold')

    ifile="%s/cfg/.sadmin.service" % (sroot)                            # Input Source Service file
    ofile="/etc/systemd/system/sadmin.service"                          # Output sadmin service file
    if os.path.exists(ofile)==False:                                    # Service already in place
        try:
            shutil.copyfile(ifile,ofile)                                # Copy sadmin service file
        except IOError as e:
            writelog("Unable to copy file. %s" % e)                     # Advise user before exiting
            sys.exit(1)                                                 # Exit to O/S With Error
        except:
            writelog("Unexpected error:", sys.exc_info())               # Advise Usr Show Error Msg
            sys.exit(1)                                                 # Exit to O/S with Error
    writelog ("   - SADMIN service unit created %s." % ofile)           # Advise User
    #writelog (' ')

    cmd = "systemctl enable sadmin.service"                             # Enable SADMIN Service 
    writelog ("   - Enabling SADMIN Service: %s " % (cmd),"nonl")       # Inform User
    ccode,cstdout,cstderr = oscommand(cmd)                              # Enable SADMIN service
    if (ccode != 0):                                                    # Problem Enabling Service
        writelog ("Problem with enabling SADMIN service.")              # Advise User
        writelog ("Return code    : %d - %s" % (ccode,cmd))             # Show Return Code No
        writelog ("Standard out   : %s" % (cstdout))                    # Print command stdout
        writelog ("Standard error : %s" % (cstderr))                    # Print command stderr
    else:
        writelog (' [ OK ]')



#===================================================================================================
# Main Flow of Setup Script
#===================================================================================================
def mainflow(sroot):
    global fhlog, packtype                                              # Script Log File Handler   

    # Create Script Log, Return Log FileHandle and log fileName
    (fhlog,logfile) = open_logfile(sroot)                               # Return File Handle/LogName
    if (DEBUG) :                                                        # If Debug Activated
        writelog ("Directory SADMIN now set to %s" % (sroot))           # Show SADMIN Root Dir.
        writelog ("Log file open and set to %s" % (logfile))            # Show LogFile Name

    # Get O/S Type (Linux, Aix, Darwin or OpenBSD) returned in UPPERCASE
    wostype=get_ostype()                                                # OSTYPE = LINUX/AIX/DARWIN
    if (DEBUG) : writelog ("Current OStype is: %s" % (wostype))         # Print O/S Type (LINUX,AIX)

    # Create initial $SADMIN/cfg/sadmin.cfg from template ($SADMIN/cfg/.sadmin.cfg)
    create_sadmin_config_file(sroot,wostype)                            # Create Initial sadmin.cfg

    # Get the Distribution Package Type (rpm,deb,aix,dmg), O/S Name (REDHAT,CENTOS,UBUNTU,...), 
    # O/S Major version number, the running kernel bit mode (32 or 64) and the system architecture
    # (Aarch64,Armv6l,Armv7l,I686,X86_64,...)
    (packtype,sosname,sosver,sosbits,sosarch) = getpacktype(sroot,wostype)
    if (DEBUG) : writelog("Package type on system is %s" % (packtype))  # Debug, Show Packaging Type 
    if (DEBUG) : writelog("O/S Name detected is %s" % (sosname))        # Debug, Show O/S Name
    if (DEBUG) : writelog("O/S Major version number is %s" % (sosver))  # Debug, Show O/S Version
    if (DEBUG) : writelog("O/S is running in %sBits mode." % (sosbits)) # Debug, Show O/S Bits MOde
    if (DEBUG) : writelog("O/S architecture is %s" % (sosarch))         # Debug, Show O/S Arch

     # Go and Ask Setup Question to user 
    # (Return SADMIN ServerName and IP, Default Domain, SysAdmin Email, sadmin User and Group).
    (userver,uip,udomain,uemail,uuser,ugroup,ussh_port) = setup_sadmin_config_file(sroot,wostype,sosname) 

    # On SADMIN Client, Apache web server is not installed, 
    # But we need to set the WebUser and the WebGroup to some default value (SADMIN user and Group)
    update_sadmin_cfg(sroot,"SADM_WWW_USER",uuser,False)                # Update Value in sadmin.cfg
    update_sadmin_cfg(sroot,"SADM_WWW_GROUP",ugroup,False)              # Update Value in sadmin.cfg

    # Check and if needed install missing packages require.
    satisfy_requirement('C',sroot,packtype,logfile,sosname,sosver,sosbits,sosarch) 
    # special_install(packtype,sosname,logfile)                           # Install pymysql module

    # Create SADMIN user sudo file
    update_sudo_file(sroot,logfile,uuser)                                     # Create User sudo file

    # Create SADMIN User crontab file
    update_client_crontab_file(logfile,sroot,wostype,uuser)             # Create SADM User Crontab 

    # Functions excuted if only installing a SADMIN Server .
    if (stype == 'S') :                                                 # If install SADMIN Server
        #update_host_file(udomain,uip)                                   # Update /etc/hosts file
        satisfy_requirement('S',sroot,packtype,logfile,sosname,sosver,sosbits,sosarch) 
        if (packtype == "rpm"): rpm_firewall_rule(ussh_port)            # Open HTTP/HTTPS/SSH Ports
        setup_mysql(sroot,userver,udomain,sosname)                      # Setup/Load MySQL Database
        setup_webserver(sroot,packtype,udomain,uemail)                  # Setup & Start Web Server
        update_server_crontab_file(logfile,sroot,wostype,uuser)         # Create Server Crontab File 
        #rrdtool_path = locate_command("rrdtool")                        # Get rrdtool path
        #update_sadmin_cfg(sroot,"SADM_RRDTOOL",rrdtool_path,False)      # Update Value in sadmin.cfg

    # Run First SADM Client Script to feed Web interface and Database
    writelog ('  ')
    writelog ('  ')
    writelog ('--------------------')
    writelog ("Run initial SADMIN daily scripts to feed database and web interface",'bold')
    writelog ('  ')
    writelog ("Running Client Scripts",'bold')
    os.environ['SADMIN'] = sroot                                        # Define SADMIN For Scripts
    run_script(sroot,"sadm_create_sysinfo.sh")                          # Server Spec in dat/dr dir.
    run_script(sroot,"sadm_client_housekeeping.sh")                     # Validate Owner/Grp/Perm
    run_script(sroot,"sadm_dr_savefs.sh")                               # Client Save LVM FS Info
    run_script(sroot,"sadm_cfg2html.sh")                                # Produce cfg2html html file
    try:                                                                # In case sysmon is running
        os.remove("%s/sysmon.lock" % (sroot))                           # Remove lock file
    except :                                                            # If not then it's OK
        pass                                                            # If didn't work it is ok.
    run_script(sroot,"sadm_sysmon.pl")                                  # Run SADM System MOnitor

    # Run First SADM Server Script to feed Web interface and Database
    if (stype == "S"):                                                  # If Server Installation
        writelog ('  ')
        writelog ("Running Server Scripts",'bold')
        run_script(sroot,"sadm_fetch_clients.sh")                       # Grab Status from clients
        run_script(sroot,"sadm_daily_farm_fetch.sh")                    # mv ClientData to ServerDir
        run_script(sroot,"sadm_server_housekeeping.sh")                 # Validate Owner/Grp/Perm
        run_script(sroot,"sadm_subnet_lookup.py")                       # Collect Network Info 
        run_script(sroot,"sadm_database_update.py")                     # Update DB with info collec
        
    # End of Setup
    sadmin_service(sroot)                                               # Startup/Shutdown Script ON
    end_message(sroot,udomain,userver,stype)                            # Last Message to User
    fhlog.close()                                                       # Close Script Log



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    

    global fhlog                                                        # Script Log File Handler
    print ("\n\nSADMIN Setup V%s" % (sver))                             # Print Version Number
    print ("---------------------------------------------------------------------------")
   
    # Insure that this script is only run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
       print ("This script must be run by the 'root' user.")            # Advise User Message / Log
       print ("Try sudo ./%s" % (pn))                                   # Suggest to use 'sudo'
       print ("Process aborted")                                        # Process Aborted Msg
       sys.exit(1)                                                      # Exit with Error Code

    # Set SADMIN Environment Variable, populate /etc/environment and /etc/profile.d/sadmin.sh
    sroot=set_sadmin_env(sver)                                          # Set SADMIN Var./Return Dir

    mainflow(sroot)                                                     # Script Main Flow Function
    sys.exit(0)                                                         # Exit to Operating System

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
