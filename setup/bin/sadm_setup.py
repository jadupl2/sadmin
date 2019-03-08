#!/usr/bin/env python3  
# ==================================================================================================
#   Author      :   Jacques Duplessis
#   Date        :   2017-09-09
#   Name        :   sadm_setup.py
#   Synopsis    : 
#   Licence     :   You can redistribute it or modify under the terms of GNU General Public 
#                   License, v.2 or above.
# ==================================================================================================
#   Copyright (C) 2016-2017 Jacques Duplessis f<duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is a free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
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
# 2018_08_29    v3.6 http://sadmin.YourDomain is now the standard to access sadmin web Site.
# 2018_10_28    v3.7 Linefeed was missing in file '/etc/sudoers.d/033_sadmin-nopasswd'
# 2018_11_24    v3.8 Added -e '' options for sadmin user creation
# 2018_12_11    V3.9 When installing server, default alert group is set to sysadmin email.
# 2019_01_03    Changed: sadm_setup.py V3.10 - Adapt crontab for MacOS and Aix, Setup Postfix
# 2019_01_25 Fix: v3.11 Fix problem with crash and multiple change to simplify process.
# 2019_01_28 Added: v3.12 For security reason, assign SADM_USER a password during installation.
# 2019_01_29 Added: v3.13 SADM_USER Home Directory is /home/SADM_USER no longer the install Dir.
#@2019_02_25 Added: v3.14 Reduce Output when error occurs when first time script are executed.
#@2019_03_08 Change: v3.15 Change related to RHEL8 and change some text messages.
# 
# ==================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch,shutil,getpass  # Import Std Python3 Modules
    from subprocess import Popen, PIPE
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                        # Activate Python Debugging

 
#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
sver                = "3.15"                                            # Setup Version Number
pn                  = os.path.basename(sys.argv[0])                     # Program name
inst                = os.path.basename(sys.argv[0]).split('.')[0]       # Pgm name without Ext
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


# Command and package require by SADMIN Client to work correctly
req_client = {}                                                         # Require Packages Dict.
req_client = { 
    'lsb_release':{ 'rpm':'redhat-lsb-core',                'rrepo':'base',  
                    'deb':'lsb-release',                    'drepo':'base'},
    'nmon'       :{ 'rpm':'nmon',                           'rrepo':'epel',  
                    'deb':'nmon',                           'drepo':'base'},
    'ethtool'    :{ 'rpm':'ethtool',                        'rrepo':'base',  
                    'deb':'ethtool',                        'drepo':'base'},
    'ifconfig'   :{ 'rpm':'net-tools',                      'rrepo':'base',  
                    'deb':'net-tools',                      'drepo':'base'},
    'sudo'       :{ 'rpm':'sudo',                           'rrepo':'base',  
                    'deb':'sudo',                           'drepo':'base'},
    'lshw'       :{ 'rpm':'lshw',                           'rrepo':'base',  
                    'deb':'lshw',                           'drepo':'base'},
    'parted'     :{ 'rpm':'parted',                         'rrepo':'base',  
                    'deb':'parted',                         'drepo':'base'},
    'mail'       :{ 'rpm':'mailx',                          'rrepo':'base',
                    'deb':'mailutils',                      'drepo':'base'},
    'mutt'       :{ 'rpm':'mutt',                           'rrepo':'base',
                    'deb':'mutt',                           'drepo':'base'},
    'gawk'       :{ 'rpm':'gawk',                           'rrepo':'base',
                    'deb':'gawk',                           'drepo':'base'},
    'facter'     :{ 'rpm':'facter',                         'rrepo':'epel',  
                    'deb':'facter',                         'drepo':'base'},
    'ruby-libs'  :{ 'rpm':'ruby-libs',                      'rrepo':'epel',  
                    'deb':'ruby-full',                      'drepo':'base'},
    'bc'         :{ 'rpm':'bc',                             'rrepo':'base',  
                    'deb':'bc',                             'drepo':'base'},
    'ssh'        :{ 'rpm':'openssh-clients',                'rrepo':'base',
                    'deb':'openssh-client',                 'drepo':'base'},
    'dmidecode'  :{ 'rpm':'dmidecode',                      'rrepo':'base',
                    'deb':'dmidecode',                      'drepo':'base'},
    # 'pymsql'     :{ 'rpm':'python34-pip python3-pip',       'rrepo':'epel',
    #                 'deb':'python3-pip',                    'drepo':'base'},
    'perl'       :{ 'rpm':'perl',                           'rrepo':'base',  
                    'deb':'perl-base',                      'drepo':'base'},
    'datetime'   :{ 'rpm':'perl-DateTime ',                 'rrepo':'base',
                    'deb':'libdatetime-perl ',              'drepo':'base'},
    'libwww'     :{ 'rpm':'perl-libwww-perl ',              'rrepo':'base',
                    'deb':'libwww-perl ',                   'drepo':'base'},
    'lscpu'      :{ 'rpm':'util-linux',                     'rrepo':'base',  
                    'deb':'util-linux',                     'drepo':'base'}
}

# Command and package require by SADMIN Server to work correctly
req_server = {}                                                         # Require Packages Dict.
req_server = { 
    'httpd'      :{ 'rpm':'httpd httpd-tools',                              'rrepo':'base',
                    'deb':'apache2 apache2-utils libapache2-mod-php',       'drepo':'base'},
    'rrdtool'    :{ 'rpm':'rrdtool',                                        'rrepo':'base',
                    'deb':'rrdtool',                                        'drepo':'base'},
    'fping'      :{ 'rpm':'fping',                                          'rrepo':'epel',
                    'deb':'fping monitoring-plugins-standard',              'drepo':'base'},
    'arp-scan'   :{ 'rpm':'arp-scan',                                       'rrepo':'epel',
                    'deb':'arp-scan',                                       'drepo':'base'},
    'php'        :{ 'rpm':'php php-common php-cli php-mysqlnd php-mbstring','rrepo':'base', 
                    'deb':'php php-mysql php-common php-cli ',              'drepo':'base'},
#    'mysql'      :{ 'rpm':'mariadb-server MySQL-python',                    'rrepo':'base',
    'mysql'      :{ 'rpm':'mariadb-server ',                                'rrepo':'base',
                    'deb':'mariadb-server mariadb-client',                  'drepo':'base'}
}

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
    if (stype == "log") : return                                        # Log Only Nothing on screen   

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
    p = Popen(command, stdout=PIPE, stderr=PIPE, shell=True)
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
    writelog ("Adding 'sadmin' to /etc/hosts file",'bold')
    try : 
        hf = open('/etc/hosts','r+')                                    # Open /etc/hosts file
    except :
        writelog("Error Opening /etc/hosts file")
        sys.exit(1)
    eline = "%s    sadmin.%s   sadmin " % (wip,wdomain)                 # Line that should be hosts
    found_line = False                                                  # Assume sadmin line not in
    for line in hf:                                                     # Read Input file until EOF
        if (eline.rstrip() == line.rstrip()):                           # Line already there    
            found_line = True                                           # Line is Found 
    if not found_line:                                                  # If line was not found
        hf.write ("%s\n" % (eline))                                     # Write SADMIN line to hosts
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
            writelog("Crontab Directory /etc/cron.d doesn't exist ?",'bold')
            writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
            return(1)                                                   # Return to Caller with Err.
    if wostype == "AIX" :                                               # Under AIX
        ccron_file = "/var/spool/cron/crontabs/%s" % (wuser)            # Client Crontab File Name
        if not os.path.exists("/var/spool/cron/crontabs") :             # Test if Dir. Exist
            writelog("Crontab Directory /var/spool/cron/crontabs doesn't exist ?",'bold')
            writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
            return(1)                                                   # Return to Caller with Err.
    if wostype == "DARWIN" :                                            # Under MacOS 
        ccron_file = "/var/at/tabs/%s" % (wuser)                        # Crontab File on MacOS
        if not os.path.exists("/var/at/tabs") :                         # Test if Dir. Exist
            writelog("Crontab Directory /var/at/tabs doesn't exist ?",'bold')
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
    hcron.write ("# Please don't edit manually, SADMIN Tools generated file\n")
    hcron.write ("# \n")
    hcron.write ("PATH=%s\n" % (os.environ["PATH"]))
    hcron.write ("SADMIN=%s\n" % (sroot))
    hcron.write ("# \n")
    hcron.write ("# \n")
    hcron.write ("# Min, Hrs, Date, Mth, Day, User, Script\n")
    hcron.write ("# 0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat\n")
    hcron.write ("# \n")
    hcron.write ("# Run Daily before midnight\n")
    hcron.write ("# Housekeeping, Save Filesystem Info, Create SysInfo & Set Files/Dir. Owner\n")
    hcron.write ("23 23 * * *  %s sudo ${SADMIN}/bin/sadm_client_sunset.sh > /dev/null 2>&1\n" % (wuser))
    hcron.write ("#\n")
    hcron.write ("# Run SADMIN System Monitoring every 5 minutes (*/5 Don't work on Aix)\n")
    chostname = socket.gethostname().split('.')[0]
    hcron.write ("2,7,12,17,22,27,32,37,42,47,52,57 * * * * %s sudo ${SADMIN}/bin/sadm_sysmon.pl >${SADMIN}/log/%s_sadm_sysmon.log 2>&1\n" % (wuser,chostname))
    hcron.write ("#\n")
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
    hcron.write ("# Please don't edit manually, SADMIN Tools generated file\n")
    hcron.write ("# \n")
    hcron.write ("PATH=%s\n" % (os.environ["PATH"]))
    hcron.write ("SADMIN=%s\n" % (sroot))
    hcron.write ("# \n")
    hcron.write ("# \n")
    hcron.write ("# Min, Hrs, Date, Mth, Day, User, Script\n")
    hcron.write ("# 0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat\n")
    hcron.write ("# \n")
    hcron.write ("# Rsync all *.rch,*.log,*.rpt files from all actives clients (*/5 don't work on Aix).\n")
    hcron.write ("4,9,14,19,24,29,34,39,44,49,54,59 * * * * %s sudo ${SADMIN}/bin/sadm_fetch_clients.sh >/dev/null 2>&1\n" % (wuser))
    hcron.write ("#\n")
    hcron.write ("# Early morning daily run, Collect Perf data - Update Database, Housekeeping\n")
    hcron.write ("05 05 * * * %s sudo ${SADMIN}/bin/sadm_server_sunrise.sh >/dev/null 2>&1\n" % (wuser))
    hcron.write ("#\n")
    #hcron.write ("# Morning report sent to Sysadmin by Email\n")
    #hcron.write ("03 08 * * * ${SADMIN}/bin/sadm_rch_scr_summary.sh -m >/dev/null 2>&1\n")
    #hcron.write ("#\n")
    hcron.close()                                                       # Close SADMIN Crontab file

    # Change Server Crontab file permission to 644
    cmd = "chmod 644 %s" % (ccron_file)                                 # chmod 644 on ccron_file
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chmod on ccron_file
    if (ccode == 0):                                                    # If chmod went ok
        writelog( "  - Server crontab permission changed successfully") # Show success
    else:                                                               # Did not went well
        writelog ("Problem changing Server crontab file permission")    # Had error on chmod cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    # Change Server Crontab file Owner and Group
    cmd = "chown %s.%s %s" % ('root','root',ccron_file)                 # chowner on ccron_file
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chown on ccron_file
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
    writelog("Checking for python pip3 command ... ",'nonl')
    if (locate_command('pip3') == "") :                                 # If pip3 command not found
        writelog("Installing python3 pip3")                             # Inform User - install pip3
        if (lpacktype == "deb"):                                        # Is Debian Style Package
            cmd =  "apt-get -y update >> %s 2>&1" % (logfile)           # Build Refresh Pack Cmd
            writelog ("Running apt-get -y update...",'nonl')            # Show what we are running
            (ccode, cstdout, cstderr) = oscommand(cmd)                  # Run the apt-get command
            if (ccode == 0) :                                           # If command went ok
                writelog (" Done ")                                     # Print DOne
            else:                                                       # If we had error 
                writelog ("Error Code is %d" % (ccode))                 # Advise user of error     
            writelog ('Installing python3-pip','nonl')                  # Show User Pkg Installing
            icmd = "DEBIAN_FRONTEND=noninteractive "                    # No Prompt While installing
            icmd += "apt-get -y install python3-pip >>%s 2>&1" % (logfile)
        else:                                                           # 
            if (sosname != "FEDORA"):                                   # On Redhat/CentOS
                writelog('Installing python34-pip from EPEL ... ','nonl') # Need Help of EPEL Repo
                icmd = "yum install --enablerepo=epel -y python34-pip >>%s 2>&1" % (logfile)
            else:                                                       # On Fedora
                writelog ('Installing python3-pip ... ','nonl')         # Inform User Pkg installing
                icmd="yum install -y python3-pip >>%s 2>&1" % (logfile) # Fedora pip3 install cmd

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
    writelog ("Installing python3 PyMySQL module (pip3 install PyMySQL) ... ",'nonl') 
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
def update_sudo_file(logfile,wuser) :

    writelog('')
    writelog('--------------------')
    writelog("Creating '%s' user sudo file" % (wuser),'bold')
    sudofile = "/etc/sudoers.d/033_%s-nopasswd" % (wuser)
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
    hsudo.write ('Defaults  !requiretty')                               # Session don't require tty
    hsudo.write ('\nDefaults  env_keep += "SADMIN"')                    # Keep Env. Var. SADMIN 
    hsudo.write ("\n%s ALL=(ALL) NOPASSWD: ALL\n" % (wuser))            # No Passwd for SADMIN User
    hsudo.close()                                                       # Close SADMIN sudo  file

    # Change sudo file permission to 440
    cmd = "chmod 440 %s" % (sudofile)                                   # chmod 440 on sudofile
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
# IF FIREWALL IS RUNNING - OPEN PORT (80) FOR HTTP
#===================================================================================================
def firewall_rule() :
    writelog('')
    writelog('--------------------')
    writelog("Checking Firewall Information",'bold')

    # Check if the command 'firewalld-cmd' is present on system - If not return to caller
    writelog("  - Checking Firewall ... ",'nonl')
    if (locate_command('firewall-cmd') == "") :                         # firewalld command not found
        writelog("Not installed")
        return (0)                                                      # No need to continue
    else :
        writelog("Installed")

    # Check if Firewall is running - If not then return to caller 
    writelog("  - Checking if firewall is running ... ",'nonl')
    COMMAND = "systemctl status firewalld"                              # Check if Firewall running
    if (DEBUG): print ("O/S command : %s " % (COMMAND))                 # Under Debug print cmd   
    ccode,cstdout,cstderr = oscommand(COMMAND)                          # Try to Locate Command
    if ccode is not 0 :  
        writelog("Not running")
        return (0)                                                      # If Firewall not running
    else:
        writelog("Running")

    # Open TCP Port 80 on Firewall
    writelog("  - Adding rules to allow incoming connection on port 80")
    COMMAND="firewall-cmd --zone=public --add-port=80/tcp --permanent"  # Allow port 80 for HTTP 
    if (DEBUG): print ("O/S command : %s " % (COMMAND))                 # Under Debug print cmd   
    ccode,cstdout,cstderr = oscommand(COMMAND)                          # Try to Locate Command

    # Restart Firewall to activate the new rule
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
    if ccode is not 0 :                                                 # Command was not Found
        cmd_path=""                                                     # Cmd Path Null when Not fnd
    else :                                                              # If command Path is Found
        cmd_path = cstdout                                              # Save command Path
    return (cmd_path)                                                   # Return Cmd Path




#===================================================================================================
#       This function verify if the Package Received in parameter is available on the server 
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
            COMMAND = "dpkg-query -W %s  >/dev/null 2>&1" % (pack)      # Check if Package Installed
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
def satisfy_requirement(stype,sroot,packtype,logfile,sosname,sosver,sosbits):
    global fhlog

    # Based on installation Type (Client or Server), Move client or server dict. in Work Dict.
    writelog (" ")
    writelog ("--------------------")
    if (stype == 'C'):
        req_work = req_client                                           # Move CLient Dict in WDict.
        writelog ("Checking SADMIN Client Package requirement",'bold')  # Show User what we do
    else:
        req_work = req_server                                           # Move Server Dict in WDict.
        writelog ("Checking SADMIN Server Package requirement",'bold')  # Show User what we do
    writelog (" ")

    # If Debian Package, Refresh The Local Repository 
    if (packtype == "deb"):                                             # Is Debian Style Package
        cmd =  "apt-get -y update >> %s 2>&1" % (logfile)               # Build Refresh Pack Cmd
        if (DRYRUN):                                                    # If Running if DRY-RUN Mode
            print ("DryRun - Would run : %s" % (cmd))                   # Only shw cmd we would run
        else:                                                           # If running in normal mode
            writelog ("Running apt-get update...",'nonl')               # Show what we are running
            (ccode, cstdout, cstderr) = oscommand(cmd)                  # Run the apt-get command
            if (ccode == 0) :                                           # If command went ok
                writelog (" Done ")                                     # Print DOne
            else:                                                       # If we had error 
                writelog ("Error Code is %d" % (ccode))                 # Advise user of error

    # Under Debug Mode, Display the working dictionnary we will be processing below
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
            needed_repo = pkginfo['drepo']                              # Packages Repository to use
        else:                                                           # If Current Host use .rpm
            needed_packages = pkginfo['rpm']                            # Save Packages to install
            needed_repo = pkginfo['rrepo']                              # Packages Repository to use

        # Verify if needed package is installed
        pline = "Checking for %s ... " % (needed_packages)		        # Show What were looking for
        writelog (pline,'nonl')                                         # Show What were looking for
        if locate_package(needed_packages,packtype) :                   # If Package is installed
            writelog (" Ok ")                                           # Show User Check Result
            continue                                                    # Proceed with Next Package

        # Install Missing Packages
        writelog ("Installing %s ... " % (needed_packages),'nonl')      # Show user what installing
        
        # Setup command to install missing package
        if (packtype == "deb") :                                        # If Package type is '.deb'
            icmd = "DEBIAN_FRONTEND=noninteractive "                    # No Prompt While installing
            icmd += "apt-get -y install %s >>%s 2>&1" % (needed_packages,logfile)
        if (packtype == "rpm") :                                        # If Package type is '.rpm'
            if (needed_repo == "epel") and (sosname != "FEDORA"):       # Repo needed is EPEL
                writelog (" from EPEL ... ",'nonl')                 
                icmd = "yum install --enablerepo=epel -y %s >>%s 2>&1" % (needed_packages,logfile)
            else:
                icmd = "yum install -y %s >>%s 2>&1" % (needed_packages,logfile)
        writelog ("-----------------------",'log')
        writelog (icmd,'log')
        writelog ("-----------------------",'log')
        
        # Execute install Command 
        ccode, cstdout, cstderr = oscommand(icmd)
        if (ccode == 0) : 
            writelog (" Done ")
            #writelog ("Installed successfully")
        else:
            if (needed_cmd == "nmon"):
                package_path="%s/pkg/%s/%s/%s/%sBits/%s*.rpm"  % (sroot,needed_cmd,sosname.lower(),sosver,sosbits,needed_cmd)
                writelog (" from local rpm ... ",'nonl')                 
                if (DEBUG) : writelog("Installing package %s" % (package_path))
                icmd = "yum install -y %s" % (package_path) 
                writelog ("-----------------------",'log')
                writelog (icmd,'log')
                writelog ("-----------------------",'log')
                ccode, cstdout, cstderr = oscommand(icmd)
                if (ccode == 0) : 
                    writelog (" Done ")
                else: 
                    writelog   ("Error, was unable to install package." % (ccode),'bold')
            else: 
                writelog   ("Error, was unable to install package." % (ccode),'bold')



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
    writelog("Inserting server '%s' in Database ... " % (sname),'bold') # Show User adding Server
    #
    cnow    = datetime.datetime.now()                                   # Get Current Time
    curdate = cnow.strftime("%Y-%m-%d")                                 # Format Current date
    curtime = cnow.strftime("%H:%M:%S")                                 # Format Current Time
    dbdate  = curdate + " " + curtime                                   # MariaDB Insert Date/Time  
    #
    # Get O/S Distribution Name
    wcmd = "%s %s" % ("lsb_release","-si")
    ccode, cstdout, cstderr = oscommand(wcmd)
    osdist=cstdout.upper()
    #
    wcmd = "%s %s" % ("lsb_release","-sr")
    ccode, cstdout, cstderr = oscommand(wcmd)
    osver=cstdout
    #
    # Construct insert new server SQL Statement
    sql = "use sadmin; "
    sql += "insert into server set srv_name='%s', srv_domain='%s'," % (sname,sdomain);
    sql += " srv_desc='SADMIN Server', srv_active='1', srv_date_creation='%s'," % (dbdate);
    sql += " srv_sporadic='0', srv_monitor='1', srv_cat='Prod', srv_group='Service', ";
    sql += " srv_backup='0', srv_update_auto='0', srv_tag='SADMin Server', ";
    sql += " srv_osname='%s'," % (osdist);
    sql += " srv_osversion='%s'," % (osver);
    sql += " srv_ostype='linux', srv_graph='1' ;"
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
    writelog ("ReStarting MariaDB Service - %s ... " % (cmd),'nonl')    # Make Sure MariabDB Started
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
       

    # Accept 'root' Database user password ---------------------------------------------------------
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
        writelog("Loading Initial Data in SADMIN Database ... ",'bold') # Load Initial Database 
        ccode,cstdout,cstderr = oscommand(cmd)                          # Execute MySQL Lload DB
        if (ccode != 0):                                                # If problem deleting user
            writelog ("Problem loading the database ...")               # Advise User
            writelog ("Return code is %d - %s" % (ccode,cmd))           # Show Return Code No
            writelog ("Standard out is %s" % (cstdout))                 # Print command stdout
            writelog ("Standard error is %s" % (cstderr))               # Print command stderr
        else:                                                           # If user deleted
            writelog (' Done ')                                         # Advise User ok to proceed
        time.sleep(1)                                                   # Sleep for user to see


    # Check if 'sadmin' user exist in Database, if not create User and Grant permission ------------
    writelog ('')                                                       # Space line
    uname = "sadmin"                                                    # User to check in DB
    rw_passwd = ""                                                      # Clear dbpass sadmin Pwd
    writelog(' ')                                                       # Blank Line
    writelog('----------')                                              # Separation Line
    writelog ("Checking if '%s' user exist in MariaDB ... " % (uname),'nonl') # Show User
    if (user_exist(uname,dbroot_pwd)):
        print ("User '%s' already exist" % (uname))                     # Show user was found
    else:                                                               # User sadmin was not found
        writelog ("User don't exist.")                                  # Inform User
        sdefault = "Nimdas2018"                                         # Default sadmin Password 
        sprompt  = "Enter Read/Write 'sadmin' database user password"   # Prompt for Answer
        wcfg_rw_dbpwd = accept_field(sroot,"SADM_RW_DBPWD",sdefault,sprompt,"P") # Sadmin user pwd
        writelog ("Creating 'sadmin' user ... ",'nonl')                 # Show User Creating DB Usr
        sql  = "CREATE USER 'sadmin'@'localhost' IDENTIFIED BY '%s';" % (wcfg_rw_dbpwd)
        sql += " grant all privileges on sadmin.* to 'sadmin'@'localhost';"
        sql += " flush privileges;"                                     # Flush Buffer
        cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)         # Build Create User SQL
        ccode,cstdout,cstderr = oscommand(cmd)                          # Execute MySQL Command 
        if (ccode != 0):                                                # If problem creating user
            writelog ("Error code returned is %d \n%s" % (ccode,cmd))   # Show Return Code No
            writelog ("Standard out is %s" % (cstdout))                 # Print command stdout
            writelog ("Standard error is %s" % (cstderr))               # Print command stderr
        else:                                                           # If user created
            rw_passwd = wcfg_rw_dbpwd                                   # DBpwd R/W sadmin Password
            writelog (" Done ")                                         # Advise User ok to proceed


    # Check if 'squery' user exist in Database, if not create User and Grant permission ------------
    uname = "squery"                                                    # Default Query DB UserName
    ro_passwd = ""                                                      # Clear dbpass squery Pwd
    writelog('----------')                                              # Separation Line
    writelog ("Checking if '%s' user exist in MariaDB ... " % (uname),'nonl')    
    if (user_exist(uname,dbroot_pwd)):                                  # Check if squery Usr Exist
        print ("User '%s' already exist" % (uname))                     # Advise User that it exist
    else:
        writelog ("User don't exist.")                                  # Inform User
        sdefault = "Squery18"                                           # Default Password 
        sprompt  = "Enter 'squery' database user password"              # Prompt for Answer
        wcfg_ro_dbpwd = accept_field(sroot,"SADM_RO_DBPWD",sdefault,sprompt,"P")# sadmin DB user pwd
        writelog ("Creating 'squery' user ... ",'nonl')                 # Show User Creating DB Usr
        sql  = "CREATE USER 'squery'@'localhost' IDENTIFIED BY '%s';" % (wcfg_ro_dbpwd)
        sql += " grant select, show view on sadmin.* to 'squery'@'localhost';"
        sql += " flush privileges;"                                     # Flush Buffer
        cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)         # Build Create User SQL
        ccode,cstdout,cstderr = oscommand(cmd)                          # Execute MySQL Command 
        if (ccode != 0):                                                # If problem creating user
            writelog ("Error code returned is %d \n%s" % (ccode,cmd))   # Show Return Code No
            writelog ("Standard out is %s" % (cstdout))                 # Print command stdout
            writelog ("Standard error is %s" % (cstderr))               # Print command stderr
        else:                                                           # If user created
            ro_passwd = wcfg_ro_dbpwd                                   # DBpwd R/O squery Password
            writelog (" Done ")                                         # Advise User ok to proceed


    if (load_db) :                                                      # If Load/Reload Database
        writelog('----------')                                          # Separation Line
        add_server_to_db(sserver,dbroot_pwd,sdomain)                    # Add current Server to DB


    # Create $SADMIN/cfg/.dbpass (Database Password file) Only if it doesn't exist -----------------
    dpfile = "%s/cfg/.dbpass" % (sroot)                                 # Database Password FileName
    if not os.path.isfile(dpfile):                                      # If .dbpass don't exist
        writelog ("Creating Database Password File (%s)" % (dpfile))    # Advise user create .dbpass
        dbpwd  = open(dpfile,'w')                                       # Create Database Pwd File
        dbpwd.write("sadmin,%s\n" % (rw_passwd))                        # Create R/W user & Password
        dbpwd.write("squery,%s\n" % (ro_passwd))                        # Create R/O user & Password
        dbpwd.close()                                                   # Close DB Password File
    else:
        writelog ("Leaving Database Password File as it is (%s)" % (dpfile)) # Advise user 
        


    # Make Sure MariaDB is Running -----------------------------------------------------------------
    writelog ('  ')
    if (SYSTEMD):                                                       # If Using Systemd
        cmd = "systemctl restart mariadb.service"                       # Systemd Restart MariaDB
    else:                                                               # If Using SystemV Init
        cmd = "/etc/init.d/mysql restart"                               # SystemV Restart MariabDB
    writelog ("ReStarting MariaDB Service - %s" % (cmd))                # Make Sure MariabDB Started
    ccode,cstdout,cstderr = oscommand(cmd)                              # Restart MariaDB Server
    if (ccode != 0):                                                    # Problem Starting DB
        writelog ("Problem Starting MariabDB server... ")               # Advise User
        writelog ("Return code is %d - %s" % (ccode,cmd))               # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    else:
        writelog (' Done ')


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
    open("/var/log/%s/sadmin_error.log"  % (sservice),'a').close()      # Touch Apache SADMIN log
    open("/var/log/%s/sadmin_access.log" % (sservice),'a').close()      # Touch Apache SADMIN log
    
    # Start Web Server
    cmd = "systemctl restart %s" % (sservice)
    writelog ("  - Making sure Web Server is started - %s" % (cmd))
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode != 0):                                                    # If problem creating user
        writelog ("Problem Restarting Web Server - Error %d \n%s" % (ccode,cmd)) # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr

    # Get the httpd process owner
    time.sleep( 4 )                                                     # Wait Web Server to Start
    cmd = "ps -ef | grep -Ev 'root|grep' | grep '%s' | awk '{ print $1 }' | sort | uniq" % (sservice)
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
 
               
    # Update the sadmin.cfg with Web Server User and Group
    #writelog('')
    writelog ("  - SADMIN Web site configuration now in place (%s)" % (apache2_config))
    writelog ("  - Record Apache Process Owner in SADMIN configuration (%s/cfg/sadmin.cfg)" % (sroot))
    update_sadmin_cfg(sroot,"SADM_WWW_USER",apache_user,False)          # Update Value in sadmin.cfg
    update_sadmin_cfg(sroot,"SADM_WWW_GROUP",apache_group,False)        # Update Value in sadmin.cfg

    # Setting Files and Directories Permissions for Web sites 
    writelog ("  - Setting Owner/Group on SADMIN WebSite(%s/www) ... " % (sroot),'nonl') 
    cmd = "chown -R %s.%s %s/www" % (apache_user,apache_group,sroot)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chown on Web Dir.
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem changing Web Site Owner and Group")
        writelog ("%s - %s" % (cstdout,cstderr))        

    # Setting Access permission on web site
    writelog ("  - Setting Permission on SADMIN WebSite (%s/www) ... " % (sroot),'nonl') 
    cmd = "find %s/www -type d -exec chmod 775 {} \;" % (sroot)         # chmod 775 on all www dir.
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem changing Web Site permission")
        writelog ("%s - %s" % (cstdout,cstderr))        
    
    # Setting permissions on Website images
    writelog ("  - Setting Permission on SADMIN WebSite images (%s/www/images) ... " % (sroot),'nonl') 
    cmd = "chmod -R 664 %s/www/images/*" % (sroot)                      # chmod 644 on all images
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem changing Website images permission")
        writelog ("%s - %s" % (cstdout,cstderr))        
                

    # Restarting Web Server with new configuration
    cmd = "systemctl restart %s" % (sservice) 
    writelog ("  - Web Server Restarting - %s ..." % (cmd),'nonl')
    ccode,cstdout,cstderr = oscommand(cmd)                          
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem Starting the Web Server",'bold')
        writelog ("%s - %s" % (cstdout,cstderr))        

    # Enable Web Server Service so it restart upon reboot
    cmd = "systemctl enable %s" % (sservice) 
    writelog ("  - Enabling Web Server Service - %s ... " % (cmd),'nonl')
    ccode,cstdout,cstderr = oscommand(cmd)                          
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem enabling Web Server Service",'bold')
        writelog ("%s - %s" % (cstdout,cstderr))        
 
#===================================================================================================
# Read the SADMIN version file and return the current version number
#===================================================================================================
#
def get_sadmin_version(sroot):
    vfile = "%s/cfg/.version" % (sroot)                                 # Current Version File Name
    sversion = open(vfile).readline()                                   # Open,Read 1st line,Close
    return (sversion.rstrip())                                          # Return Version Number


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
    sname  {[string]}   --  [Variable nameto change value]
    svalue {[string]}   --  [Variable New value]
    """    

    wtmp_file = "%s/tmp/apache.tmp" % (sroot)                           # Tmp Apache config file
    wbak_file = "%s/tmp/apache.bak" % (sroot)                           # Backup Apache config file
    if (DEBUG) :
        writelog ("Update_apache_config - sfile=%s - sname=%s - svalue=%s\n" % (sfile,sname,svalue))
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
        writelog ("Error renaming %s to %s" % (wtmp_file,sfile))           # Advise user of problem
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
            writelog("Unable to copy %s to %s" % (SADM_INIFILE,SADM_PROFILE)) # Advise user 
            sys.exit(1)                                                 # Exit to O/S With Error
        except:
            writelog("Unexpected error:", sys.exc_info())               # Advise Usr Show Error Msg
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
            writelog("Unable to copy %s to %s" % (SADM_ENVFILE,SADM_ORGFILE)) # Advise user 
            sys.exit(1)                                                 # Exit to O/S With Error
        except:
            writelog("Unexpected error:", sys.exc_info())               # Advise Usr Show Error Msg
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

    # Make sure /etc/environment have line SADMIN= Installation Directory
    fo = open(SADM_TMPFILE,'w')                                         # Environment TMP File
    fileEmpty=True                                                      # Env. file assume empty
    for line in fi:                                                     # Read Input file until EOF
        if line.startswith('SADMIN=') :                                 # line Start with 'SADMIN='?
           line = "%s" % (eline)                                        # Replace line with latest
        fo.write (line)                                                 # Write line to output file
        fileEmpty=False                                                 # File was not empty flag
    fi.close()                                                          # File read now close it
    if (fileEmpty) :                                                    # If Input file was empty
        fo.write (eline)                                                # Write 'export SADMIN=' Line
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
    print ("  - This will make 'SADMIN' environment variable set upon reboot")
    return sadm_base_dir                                                # Return SADMIN Root Dir


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
    writelog ("  - Initial SADMIN configuration file (%s) in place." % (cfgfile)) # Advise User
    writelog (' ')
    


#===================================================================================================
#             Replace default line - Put the Sadmin Email as the default value for alert
#  1st = Root Dir. of SADMIN, 2nd = Name of setting, 3rd = Value of the setting, 4th = Show Upd. line
# ===================================================================================================
#
def update_alert_group_default(sroot,semail):
    """
    Create $SADMIN/.alert_group.cfg & alert_group.cfg based on $SADMIN/setup/etc/alert_group.def file
    Change the default group value to be the sysadmin email address.
    Arguments:
    sroot  {[string]}   --  [SADMIN root install directory]
    sname  {[string]}   --  [Name of variable in sadmin.cfg to change value]
    semail {[string]}   --  [New value of the variable]
    """    
    winput  = "%s/cfg/.alert_group.cfg" % (sroot)                       # AlertGroup Base Def. File
    woutput = "%s/cfg/alert_group.cfg" % (sroot)                        # AlertGroup New Default File
    if (DEBUG) :
        writelog ("In update_alert_group_default - Setting Email to %s \n" % (semail))
        writelog ("\nwinput=%s\nwoutput=%s" % (winput,woutput))

    fi = open(winput,'r')                                               # Open Base AlertGroup File
    fo = open(woutput,'w')                                              # AlertGroup New Default File
    lineNotFound=True                                                   # Assume '^default ' != in file
    cline = "default    m %s\n" % (semail)                              # Line to Insert in AlertGrp

    # Replace Line Starting with default with a new one with sysadmin email.
    for line in fi:                                                     # Read sadmin.cfg until EOF
        if line.startswith("%s" % ('default')) :                        # Line Start with default ?
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
        smin {int} -- [Minimum Value for Integer input] (default: {0})
        smax {int} -- [Maximum value for Integer input] (default: {3})

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
    writelog ("[%s]" % (sname),'bold')                                  # Bold Attr. Name in sadmin

    # Display field documentation file  
    docname = "%s/setup/msg/%s.txt" % (sroot,sname.lower())             # Set Documentation FileName
    try :                                                               # Try to Open Doc File
        doc = open(docname,'r')                                         # Open Documentation file
        for line in doc:                                                # Read Doc. file until EOF
            if ((line.startswith("#")) or (len(line) == 0)):            # Line Start with # or empty
               continue                                                 # Skip Line that start with#
            writelog ("%s" % (line.rstrip()))                                    # Print Documentation Line
        doc.close()                                                     # Close Document File
    except FileNotFoundError:                                           # If Open File Failed
        writelog ("Doc file %s not found, question skipped" % (docname))   # Advise User, Question Skip
    #writelog ("--------------------")

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
            if (len(sdefault) !=0):                                     # If Default Value received
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
            wdata = input("%s : " % (eprompt))                       # Accept an Integer
            if (len(wdata) ==0): wdata = sdefault
            try:
                wdata = int(wdata)
            except ValueError as e:                    # If Value is not an Integer
                writelog ("Value Error - Not an integer (%s)" % (wdata))                            # Advise User Message
                continue                                                # Continue at start of loop
            except TypeError as e:                    # If Value is not an Integer
                writelog ("Type Error - Not an integer (%s)" % (wdata))                            # Advise User Message
                continue                                                # Continue at start of loop
            if (wdata == 0) : wdata = sdefault                          # No Input = Default Value
            if (wdata > smax) or (wdata < smin):                        # Must be between min & max
                writelog ("Value must be between %d and %d" % (smin,smax)) # Input out of Range 
                continue                                                # Continue at start of loop
            break                                                       # Break out of the loop

    return wdata



#===================================================================================================
# SETUP POSTFIX CONFIGURATION FILE (/ETC/POSTFIX/MAIN.CF)
#===================================================================================================
#
def setup_postfix(sroot,wostype,wrelay):
    if wostype != "LINUX" :                                             # Configure Only on Linux
        return

    pfile="/etc/postfix/main.cf"                                        # Postfix Config FileName
    pfile_org="/etc/postfix/main.cf.org"                                # Backup of original main.cf
    pfile_tmp="/etc/postfix/main.tmp"                                   # Temp will become cf file
    if not os.path.isfile(pfile):                                       # If main.cf don't exist
        return                                                          # Will not create one

    # Make a Backup of main.cf - If main.cf.org don't exist, copy main.cfg to main.cf.org
    if not os.path.isfile(pfile_org):                                   # If main.cf.org don't exist
        try:
            shutil.copyfile(pfile,pfile_org)                            # Backup original main.cf
        except IOError as e:
            writelog("Error copying Postfix %s config file. %s" % (pfile,e)) 
            sys.exit(1)                                                 # Exit to O/S With Error
        except:
            writelog("Unexpected error:", sys.exc_info())               # Advise Usr Show Error Msg
            sys.exit(1)          


    writelog ("Updating relayhost in postfix configuration file (%s) ..." % (pfile))
    fi = open(pfile,'r')                                                # Current Postfix main.cf
    fo = open(pfile_tmp,'w')                                            # Open new tmp main.cf file
    norelay=True                                                        # Assume no relayhost is set
    for line in fi:                                                     # Read Input file until EOF
        if line.startswith('relayhost=') :                              # line Start with relayhost?
            line = "relayhost=%s" % (wrelay)                            # Replace with new relayhost
            norelay=False                                               # RelayHost was Set
        fo.write (line)                                                 # Write line to output file
    fi.close()                                                          # File read now close it
    if (norelay) :                                                      # If no relayhost was set
        line = "relayhost=%s" % (wrelay)                                # Insert new relayhost line
        fo.write (line)                                                 # Write line to output file
    fo.close()                                                          # Close the output file

    # Delete main.cf and copy main.cf.tmp to main.cf
    try:                                                                # Will try rename env. file
        os.remove(pfile)                                                # Remove current main.cf
        os.rename(pfile_tmp,pfile)                                      # Rename tmp to main.cf
    except:
        print ("Error removing or renaming %s" % (pfile))               # Show User if error
        sys.exit(1)                                                     # Exit to O/S with Error
    return()



#===================================================================================================
# ASK IMPORTANT INFO THAT NEED TO BE ACCURATE IN THE $SADMIN/CFG/SADMIN.CFG FILE
#===================================================================================================
#
def setup_sadmin_config_file(sroot,wostype):
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
    sdefault = ""                                                       # No default value
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
    if (wcfg_host_type == "S"):                                         # If Host is SADMIN Server
        update_alert_group_default(sroot,wcfg_mail_addr)                # Upd. AlertGroup Def. Email 

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
    #if (stype == "S"): sdefault = socket.getfqdn()                      # Server Install=Hostname
    sprompt  = "Enter SADMIN (FQDN) server name"                        # Prompt for Answer
    while True:                                                         # Accept until valid server
        wcfg_server = accept_field(sroot,"SADM_SERVER",sdefault,sprompt)# Accept SADMIN Server Name
        writelog ("Validating server name ...")                         # Advise User Validating
        ccode,SADM_IP,cstderr = oscommand("host %s |awk '{ print $4 }' |head -1" % (wcfg_server))
        #writelog ("wcfg_server = %s SADM_IP = %s ccode = %s cstderr = %s" % (wcfg_server,SADM_IP,ccode,cstderr))
        digit1=SADM_IP.split('.')[0]                                    # 1st Digit=127 = Invalid
        if ((digit1 == "127") or (SADM_IP.count(".") != 3)):            # If Resolve to loopback IP
            writelog ("  ")
            #writelog ("SADM_IP.count %s" % (SADM_IP.count(".")))
            writelog ("*** ERROR ***")
            writelog ("SADMIN server name '%s' can't be resolve." %(wcfg_server))
            writelog ("SADMIN clients would not be able to get to the SADMIN Server.")
            writelog ("SADMIN Server name must resolve to an IP other than in 127.0.0.0/24 subnet.")
            writelog ("You may need to press CTRL-C to abort installation and correct the situation.")
            writelog ("Once resolve, just execute the setup program again or enter a valid hostname.")
            continue                                                    # Go Re-Accept Server Name
        sname=wcfg_server.split('.')                                    # Split Server Name in Array
        if (len(sname) != 3):                                           # If not 3 Fields not FQDN
            writelog ("  ")
            writelog ("*** ERROR ***")
            writelog ("SADMIN server name must be fully qualified, please specify domain name")
            continue                                                    # Go Re-Accept Server Name
        break                                                           # Ok Name pass the test
    update_sadmin_cfg(sroot,"SADM_SERVER",wcfg_server)                  # Update Value in sadmin.cfg


    # Accept PostFix RelayHost
    sdefault = ""                                                       # No Default Value
    sprompt  = "Enter Postfix Internet mail relayhost (for postfix)"    # Prompt for Relay Host
    wcfg_prelay = ""                                                    # Clear Field
    while (wcfg_prelay == ""):                                          # Until something entered
        wcfg_prelay = accept_field(sroot,"SADM_RELAYHOST",sdefault,sprompt) # Accept RelayHost
    setup_postfix(sroot,wostype,wcfg_prelay)                            # Set relayhost in main.cf


    # Accept the maximum number of lines we want in every log produce
    #sdefault = 500                                                      # No Default value 
    #sprompt  = "Maximum number of lines in LOG file"                    # Prompt for Answer
    #wcfg_max_logline = accept_field(sroot,"SADM_MAX_LOGLINE",sdefault,sprompt,"I",1,10000)
    #update_sadmin_cfg(sroot,"SADM_MAX_LOGLINE",wcfg_max_logline)        # Update Value in sadmin.cfg

    # Accept the maximum number of lines we want in every RCH file produce
    #sdefault = 125                                                      # No Default value 
    #sprompt  = "Maximum number of lines in RCH file"                    # Prompt for Answer
    #wcfg_max_rchline = accept_field(sroot,"SADM_MAX_RCHLINE",sdefault,sprompt,"I",1,300)
    #update_sadmin_cfg(sroot,"SADM_MAX_RCHLINE",wcfg_max_rchline)        # Update Value in sadmin.cfg

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
        writelog ("Creating group %s" % (wcfg_group),'nonl')            # Show creating the group
        if wostype == "LINUX" :                                         # Under Linux
            ccode,cstdout,cstderr = oscommand("groupadd %s" % (wcfg_group))   # Add Group on Linux
        if wostype == "AIX" :                                           # Under AIX
            ccode,cstdout,cstderr = oscommand("mkgroup %s" % (wcfg_group))    # Add Group on Aix
        if wostype == "DARWIN" :                                        # Under MacOS
            writelog ("Group %s doesn't exist, create it and rerun this script")
            writelog ("We can't create group for the moment")           # Advise USer
            sys.exit(1)                                                 # Exit to O/S  
        if (ccode == 0) :                                               # If Group Creation went well
            writelog ('Done')                                           # Show action action result
        else:                                                           # If Error creating group
            writelog ("Error %s creating group %s" % (ccode,wcfg_group))# Show AddGroup Cmd Error No
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
        writelog ("Creating user %s ... " % (wcfg_user),'nonl')         # Create user on system
        if wostype == "LINUX" :                                         # Under Linux
            cmd = "useradd -g %s -s /bin/bash " % (wcfg_group)          # Build Add user Command 
            #cmd += " -d %s "    % (os.environ.get('SADMIN'))            # Assign Home Directory
            cmd += " -c'%s' %s -e ''" % ("SADMIN Tools User",wcfg_user) # Comment,user name,noexpire
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Create User
            cmd = "echo 'nimdas' | passwd --stdin %s" % (wcfg_user)     # Cmd to assign password
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Assign Password
            writelog ("The password 'nimdas' have been assign to %s user." % (wcfg_user),'bold') 
            writelog ("We suggest you change it after installation.",'bold') # Inform user to change pwd
        if wostype == "AIX" :                                           # Under AIX
            cmd = "mkuser pgrp='%s' -s /bin/ksh " % (wcfg_group)        # Build mkuser command
            cmd += " home='%s' " % (os.environ.get('SADMIN'))           # Set Home Directory
            cmd += " gecos='%s' %s" % ("SADMIN Tools User",wcfg_user)   # Set comment and user name
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Create User
        if (ccode == 0) :                                               # If Group Creation went well
            writelog ('Done')                                           # Show action action result
        else:                                                           # If Error creating group
            writelog ("Error %s creating user %s" % (ccode,wcfg_user))  # Show AddUser Cmd Error No 
    update_sadmin_cfg(sroot,"SADM_USER",wcfg_user)                      # Update Value in sadmin.cfg
    
    # Change owner of all files in $SADMIN
    writelog (" ")
    writelog ("Please wait while we set owner and group in %s directory ..." % (sroot))
    cmd = "find %s -exec chown %s.%s {} \;" % (sroot,wcfg_user,wcfg_group)
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
        sprompt  = "Enter the Network Netmask [1-30]"                   # Prompt for Answer
        wcfg_network1b = accept_field(sroot,"SADM_NETMASK1",sdefault,sprompt,"I",1,30) # NetMask
        update_sadmin_cfg(sroot,"SADM_NETWORK1","%s/%s" % (wcfg_network1a,wcfg_network1b))
    
    return(wcfg_server,SADM_IP,wcfg_domain,wcfg_mail_addr,wcfg_user,wcfg_group) # Return to Caller


#===================================================================================================
# DETERMINE THE INSTALLATION PACKAGE TYPE OF CURRENT O/S AND OPEN THE SCRIPT LOG FILE 
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
    cmd = "lsb_release -si"                                             # Get OSName with lsb_release
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute Script
    if (ccode == 0):                                                    # Command Execution Went OK
        osname = cstdout.upper()
        if (cstdout == "REDHATENTERPRISESERVER"): osname="REDHAT" 
        if (cstdout == "REDHATENTERPRISEAS")    : osname="REDHAT" 
        if (cstdout == "REDHATENTERPRISE")      : osname="REDHAT"   
    else:                                                               # If Problem with the cmd
        writelog("Problem running %s" % (cmd))                          # Infor User
        writelog("Error %d - %s " % (ccode,cstderr))                    # Show Error# and Stderror

    # Get O/S Major Version Number
    if sostype == "LINUX" :
        ccode, cstdout, cstderr = oscommand("lsb_release -sr")
        osversion=cstdout
        osver=osversion.split('.')[0]
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

    # Return :
    # Package Type (deb,rpm,dmg,aix)
    # O/S Name (AIX/CENTOS/REDHAT,UBUNTU,DEBIAN,RASPBIAN,...)
    # O/S Major Version Number
    # O/S Running in 32 or 64 bits (32,64)
    return (packtype,osname,osver,osbits)                               # Return Packtype & O/S Name



#===================================================================================================
# Just before ending - Run some SADM scripts to gather information and feed database/Web Interface 
#===================================================================================================
#
def run_script(sroot,sname):
    run_status = False                                                  # Default Run Failed
    writelog("Running '%s/bin/%s' script ... " % (sroot,sname),'nonl')  # Show User Script running
    script = "%s/bin/%s" % (sroot,sname)                                # Bld Full Path Script name
    ccode,cstdout,cstderr = oscommand(script)                           # Execute Script
    if (ccode == 0):                                                    # Command Execution Went OK
        writelog(" Done")                                               # Inform User
        run_status = True                                               # Return Value will be True
    else:                                                               # If Problem with the insert
        writelog("Problem running %s" % (script))                       # Infor User
        writelog("Error %d - %s - %s" % (ccode,cstdout,cstderr))        # Show Error#,Stdout,Stderr
    return (run_status)                                                 # Return Insert Status


#===================================================================================================
#                                 END OF SCRIPT - MESSAGE TO USER
#===================================================================================================
#
def end_message(sroot,sdomain,sserver,stype):
    #os.system('clear')                                                 # Clear the screen
    sversion = get_sadmin_version(sroot)
    writelog ("\n\n\n\n\n")
    writelog ("SADMIN TOOLS - VERSION %s - Successfully Installed" % (sversion),'bold')
    writelog ("===========================================================================")
    writelog ("You need to logout and log back in before using SADMIN Tools,")
    writelog ("or type the following command : '. /etc/profile.d/sadmin.sh'")
    writelog ("This will define SADMIN environment variable.")
    writelog (" ")
    if (stype == "S") :
        writelog ("\nUSE THE WEB INTERFACE TO ADMINISTRATE YOUR LINUX SERVER FARM\n",'bold')
        writelog ("The Web interface is available at : http://sadmin.%s" % (sdomain))
        #writelog ("Remember, 'sadmin.%s' need to be defined in your DNS to be accessible from other servers." % (sdomain))
        writelog (" ")
        writelog ("  - Use it to add, update and delete server in your server farm.")
        writelog ("  - View performance graph of your servers up to two years in the past.")
        writelog ("  - If you want, you can schedule automatic O/S update of your servers.")
        writelog ("  - Have server configuration on hand, usefull in case of a Disaster Recovery.")
        writelog ("  - View your servers farm subnet utilization and see what IP are free to use.")
        #writelog ("  - There's still a lot more to come.")
        writelog (" ")
    writelog ("\nCREATE YOUR OWN SCRIPT USING SADMIN LIBRARIES\n",'bold')
    writelog ("Create your own script using SADMIN tools templates, take a look & run them ")
    writelog ("  - bash shell script      : %s/bin/sadm_template.sh " % (sroot))
    writelog ("  - python script          : %s/bin/sadm_template.py " % (sroot))
    writelog (" ")
    writelog ("Create your own shell script starting with the included templates :")
    writelog ("  # copy %s/bin/sadm_template.sh %s/usr/bin/newscript.sh" % (sroot,sroot))
    writelog ("  # copy %s/bin/sadm_template.py %s/usr/bin/newscript.py" % (sroot,sroot))
    writelog (" ")
    writelog ("Modify it to your need, run it and see the result.") 
    writelog (" ")
    writelog ("SEE SADMIN FUNCTIONS IN ACTION AND LEARN HOW TO USE THEM BY RUNNING :\n",'bold')
    writelog ("  - %s/bin/sadmlib_std_demo.sh " % (sroot))
    writelog ("  - %s/bin/sadmlib_std_demo.py." % (sroot))
    writelog (" ")
    writelog ("USE THE SADMIN WRAPPER TO RUN YOUR EXISTING SCRIPT\n",'bold')
    writelog ("  - # $SADMIN/bin/sadm_wrapper.sh $SADMIN/usr/bin/yourscript.sh")
    writelog ("\n===========================================================================")
    writelog ("ENJOY !!",'bold')



#===================================================================================================
# Main Flow of Setup Script
#===================================================================================================
def mainflow(sroot):
    global fhlog                                                        # Script Log File Handler   

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

    # Get the Distribution Package Type (rpm,deb,aix,dmg), O/S Name (REDHAT,CENTOS,UBUNTU,...) 
    # O/S Major version number and the running kernel bit mode (32 or 64).
    (packtype,sosname,sosver,sosbits) = getpacktype(sroot,wostype)      # Type(deb,rpm),OSName,OSVer
    if (DEBUG) : writelog("Package type on system is %s" % (packtype))  # Debug, Show Packaging Type 
    if (DEBUG) : writelog("O/S Name detected is %s" % (sosname))        # Debug, Show O/S Name
    if (DEBUG) : writelog("O/S Major version number is %s" % (sosver))  # Debug, Show O/S Version
    if (DEBUG) : writelog("O/S is running in %sBits mode." % (sosbits)) # Debug, Show O/S Bits MOde

    # Go and Ask Setup Question to user 
    # (Return SADMIN ServerName and IP, Default Domain, SysAdmin Email, sadmin User and Group).
    (userver,uip,udomain,uemail,uuser,ugroup) = setup_sadmin_config_file(sroot,wostype) # Ask Config questions

    satisfy_requirement('C',sroot,packtype,logfile,sosname,sosver,sosbits) # Install Client Req.
    special_install(packtype,sosname,logfile)                           # Install pymysql module

    # Create SADMIN user sudo file
    update_sudo_file(logfile,uuser)                                     # Create User sudo file

    # Create SADMIN User crontab file
    update_client_crontab_file(logfile,sroot,wostype,uuser)             # Create SADM User Crontab 

    # Functions excuted if only installing a SADMIN Server .
    if (stype == 'S') :                                                 # If install SADMIN Server
        update_host_file(udomain,uip)                                   # Update /etc/hosts file
        satisfy_requirement('S',sroot,packtype,logfile,sosname,sosver,sosbits)  # Verify/Install Server Req.
        firewall_rule()                                                 # Open Port 80 for HTTP
        setup_mysql(sroot,userver,udomain,sosname)                      # Setup/Load MySQL Database
        setup_webserver(sroot,packtype,udomain,uemail)                  # Setup & Start Web Server
        update_server_crontab_file(logfile,sroot,wostype,uuser)         # Create Server Crontab File 
        rrdtool_path = locate_command("rrdtool")                        # Get rrdtool path
        update_sadmin_cfg(sroot,"SADM_RRDTOOL",rrdtool_path,False)      # Update Value in sadmin.cfg

    # Run First SADM Client Script to feed Web interface and Database
    writelog ('  ')
    writelog ('  ')
    writelog ('--------------------')
    writelog ("Run Initial SADMIN Daily scripts to feed Database and Web Interface",'bold')
    writelog ('  ')
    writelog ("Running Client Scripts")
    os.environ['SADMIN'] = sroot                                        # Define SADMIN For Scripts
    run_script(sroot,"sadm_create_sysinfo.sh")                          # Server Spec in dat/dr dir.
    run_script(sroot,"sadm_client_housekeeping.sh")                     # Validate Owner/Grp/Perm
    run_script(sroot,"sadm_dr_savefs.sh")                               # Client Save LVM FS Info
    run_script(sroot,"sadm_cfg2html.sh")                                # Produce cfg2html html file
    run_script(sroot,"sadm_sysmon.pl")                                  # Run SADM System MOnitor

    # Run First SADM Server Script to feed Web interface and Database
    if (stype == "S"):                                                  # If Server Installation
        writelog ('  ')
        writelog ("Running Server Scripts")
        run_script(sroot,"sadm_fetch_clients.sh")                       # Grab Status from clients
        run_script(sroot,"sadm_daily_farm_fetch.sh")                    # mv ClientData to ServerDir
        run_script(sroot,"sadm_server_housekeeping.sh")                 # Validate Owner/Grp/Perm
        run_script(sroot,"sadm_subnet_lookup.py")                       # Collect Network Info 
        run_script(sroot,"sadm_database_update.py")                     # Update DB with info collec
        
    # End of Setup
    end_message(sroot,udomain,userver,stype)                            # Last Message to User
    fhlog.close()                                                       # Close Script Log



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    global fhlog                                                        # Script Log File Handler
    print ("SADMIN Setup V%s" % (sver))                                 # Print Version Number
    print ("---------------------------------------------------------------------------")
   
    # Insure that this script is only run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
       print ("This script must be run by the 'root' user")             # Advise User Message / Log
       print ("Try sudo ./%s" % (pn))                                   # Suggest to use 'sudo'
       print ("Process aborted")                                        # Process Aborted Msg
       sys.exit(1)                                                      # Exit with Error Code

    # Set SADMIN Environment Variable, populate /etc/environment and /etc/profile.d/sadmin.sh
    sroot=set_sadmin_env(sver)                                          # Set SADMIN Var./Return Dir
    mainflow(sroot)                                                     # Script Main Flow Function
    sys.exit(0)                                                         # Exit to Operating System

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
