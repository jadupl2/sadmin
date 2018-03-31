#!/usr/bin/env python3 
# ==================================================================================================
#   Author      :   Jacques Duplessis
#   Date        :   2017-09-09
#   Name        :   sadm_setup.py
#   Synopsis    :
#   Licence     :   You can redistribute it or modify under the terms of GNU General Public 
#                   License, v.2 or above.
# ==================================================================================================
#   Copyright (C) 2016-2017 Jacques Duplessis <duplessis.jacques@gmail.com>
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
# 2018_01_18 JDuplessis 
#   V1.0 Initial Version
#   V1.0b WIP Version#   
# 2018_02_23 JDuplessis
#   V1.1 First Beta Version 
# 2018_03_02 JDuplessis
#   V1.2b Second Beta Version 
# 2018_03_13 JDuplessis
#   V1.3 Third Beta Version 
# 2018_03_22 JDuplessis
#   V1.5 Setup Release Candidate 2
# 2018_03_31 JDuplessis
#   V1.5G Setup Release Candidate 3
#===================================================================================================
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
sver                = "1.5G"                                            # Setup Version Number
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
    'facter'     :{ 'rpm':'facter',                         'rrepo':'epel',  
                    'deb':'facter',                         'drepo':'base'},
    'bc'         :{ 'rpm':'bc',                             'rrepo':'base',  
                    'deb':'bc',                             'drepo':'base'},
    'fdisk'      :{ 'rpm':'util-linux',                     'rrepo':'base',  
                    'deb':'util-linux',                     'drepo':'base'},
    'ssh'        :{ 'rpm':'openssh-clients',                'rrepo':'base',
                    'deb':'openssh-client',                 'drepo':'base'},
    'dmidecode'  :{ 'rpm':'dmidecode',                      'rrepo':'base',
                    'deb':'dmidecode',                      'drepo':'base'},
#    'pymsql'     :{ 'rpm':'python3-pip',                    'rrepo':'base',
#                    'deb':'python3-pip',                    'drepo':'base'},
    'perl'       :{ 'rpm':'perl',                           'rrepo':'base',  
                    'deb':'perl-base',                      'drepo':'base'},
#    'cfg2html'   :{ 'rpm':'cfg2html',                       'rrepo':'local',
#                    'deb':'cfg2html',                       'drepo':'base'},
    'datetime'   :{ 'rpm':'perl-DateTime',                  'rrepo':'base',
                    'deb':'libdatetime-perl libwww-perl',   'drepo':'base'},
    'lscpu'      :{ 'rpm':'util-linux',                     'rrepo':'base',  
                    'deb':'util-linux',                     'drepo':'base'}
}

# Command and package require by SADMIN Server to work correctly
req_server = {}                                                         # Require Packages Dict.
req_server = { 
    'httpd'      :{ 'rpm':'httpd httpd-tools',              'rrepo':'base',
                    'deb':'apache2 apache2-utils',          'drepo':'base'},
    'rrdtool'    :{ 'rpm':'rrdtool',                        'rrepo':'base',
                    'deb':'rrdtool',                        'drepo':'base'},
    'php'        :{ 'rpm':'php php-common php-cli php-mysqlnd php-mbstring','rrepo':'base', 
                    'deb':'php php-mysql php-common php-cli ',       'drepo':'base'},
    'mysql'      :{ 'rpm':'mariadb-server MySQL-python',    'rrepo':'base',
                    'deb':'mariadb-server mariadb-client',  'drepo':'base'}
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
def askyesno(emsg):
    while True:
        wmsg = emsg + " (" + color.DARKCYAN + color.BOLD + "Y/N" + color.END + ") ? " 
        wanswer = input(wmsg)
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

    # Open/Create the setup script log
    logfile = "%s/setup/log/%s.log" % (sroot,'sadm_setup')              # Set Log file name
    if (DEBUG) : print ("Open the log file %s" % (logfile))             # Debug, Show Log file
    try:                                                                # Try to Open/Create Log
        fhlog=open(logfile,'w')                                         # Open Log File 
    except IOError as e:                                                # If Can't Create Log
        print ("Error creating log file %s" % (logfile))                # Print Log FileName
        print ("Error Number : {0}".format(e.errno))                    # Print Error Number    
        print ("Error Text   : {0}".format(e.strerror))                 # Print Error Message
        sys.exit(1)                                                     # Exit with Error
    return (fhlog,logfile)                                              # Return File Handle


#===================================================================================================
#                           Write Log to Log File, Screen or Both
#===================================================================================================
def writelog(sline,stype="normal"):
    global fhlog                                                        # Need to share file handler
    fhlog.write ("%s\n" % (sline))                                      # Write Line to Log
    if (stype == "log") : return                                        # Nothing on screen  

    # Display Line on Screen
    if (stype == "normal") : print (sline)                              
    if (stype == "nonl")   : print (sline, end='')                              
    if (stype == "bold")   : print ( color.DARKCYAN + color.BOLD + sline + color.END)


#===================================================================================================
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
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


#===================================================================================================
#                              MAKE SURE SADMIN LINE IS IN /etc/hosts FILE
#===================================================================================================
def update_host_file(wdomain) :

    writelog('')
    writelog('----------')
    writelog ("Adding 'sadmin' to /etc/hosts file")
    try : 
        hf = open('/etc/hosts','r+')                                    # Open /etc/hosts file
    except :
        writelog("Error Opening /etc/hosts file")
        sys.exit(1)
    eline = "127.0.0.1      sadmin  sadmin.%s" % (wdomain)              # Line that should be hosts
    found_line = False                                                  # Assume sadmin line not in
    for line in hf:                                                     # Read Input file until EOF
        if (eline.rstrip() == line.rstrip()):                           # Line already there    
            found_line = True                                           # Line is Found 
    if not found_line:                                                  # If line was not found
        hf.write ("%s\n" % (eline))                                     # Write SADMIN line to hosts
    hf.close                                                            # Close /etc/hosts file
    return()                                                            # Return Cmd Path


#===================================================================================================
#                            MAKE SURE SADMIN CLIENT CRONTAB FILE IS IN PLACE
#===================================================================================================
def update_client_crontab_file(logfile) :

    writelog('')
    writelog('--------------------')
    writelog ('Updating SADMIN Client Crontab file (/etc/cron.d/sadm_client)')
    ccron_file = '/etc/cron.d/sadm_client'                              # Client Crontab File

    # Check if crontab directory exist - Procedure may not be supported on this O/S
    if not os.path.exists("/etc/cron.d"):
        writelog("Crontab Directory /etc/cron.d doesn't exist ?",'bold')
        writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
        return(1)

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
    hcron.write ("# Please don't edit manually, SADMIN Tools generated file\n")
    hcron.write ("# \n")
    hcron.write ("# Run Daily, late at night - Create Host Info Files, Check permission\n")
    hcron.write ("23 23 * * *  sadmin sudo ${SADMIN}/bin/sadm_client_sunset.sh > /dev/null 2>&1\n")
    hcron.write ("#\n")
    hcron.write ("# Run every 11 minutes - Make sure performance nmon daemon is running\n")
    hcron.write ("*/11 * * * * sadmin sudo ${SADMIN}/bin/sadm_nmon_watcher.sh >/dev/null 2>&1\n")
    hcron.write ("#\n")
    hcron.write ("# Daily backup of importants Files & Dir.\n")
    hcron.write ("47 22 * * *  sadmin sudo ${SADMIN}/bin/sadm_backup.sh -c >/dev/null 2>&1\n")
    hcron.write ("#\n")
    hcron.write ("# Run SADM System Monitoring every 6 minutes\n")
    hcron.write ("*/6 * * * *  sadmin sudo ${SADMIN}/bin/sadm_sysmon.pl >/dev/null/sysmon.log 2>&1\n")
    hcron.write ("#\n")
    hcron.close                                                         # Close SADMIN Crontab file

    # Change Client Crontab file permission to 644
    cmd = "chmod 644 %s" % (ccron_file)                                 # chmod 644 on ccron_file
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chmod on ccron_file
    if (ccode == 0):                                                    # If chmod went ok
        writelog( "Client Crontab Permission changed successfully")     # Show success
    else:                                                               # Did not went well
        writelog ("Problem changing Client crontab file permission")    # Had error on chmod cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    # Change Client Crontab file Owner and Group
    cmd = "chown %s.%s %s" % ('root','root',ccron_file)                 # chowner on ccron_file
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chown on ccron_file
    if (ccode == 0):                                                    # If chown went ok
        writelog( "Ownership of client crontab changed successfully")   # Show success to user
    else:                                                               # Did not went well
        writelog ("Problem changing ownership of client crontab file")  # Had an error on chown cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    return()                                                            # Return Cmd Path


#===================================================================================================
#                            MAKE SURE SADMIN SERVER CRONTAB FILE IS IN PLACE
#===================================================================================================
def update_server_crontab_file(logfile) :

    writelog('')
    writelog('--------------------')
    writelog ('Updating SADMIN Server Crontab file (/etc/cron.d/sadm_server)')
    ccron_file = '/etc/cron.d/sadm_server'                              # Server Crontab File

    # Check if crontab directory exist - Procedure may not be supported on this O/S
    if not os.path.exists("/etc/cron.d"):
        writelog("Crontab Directory /etc/cron.d doesn't exist ?",'bold')
        writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
        return(1)

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

    # Populate SADMIN Server Crontab File
    hcron.write ("# Please don't edit manually, SADMIN Tools generated file\n")
    hcron.write ("# \n")
    hcron.write ("# Get all rch/log/rpt status files from all active client\n")
    hcron.write ("*/4 * * * * ${SADMIN}/bin/sadm_fetch_servers.sh >/dev/null 2>&1\n")
    hcron.write ("#\n")
    hcron.write ("# Run Daily, Early in morning - Collect Performance,Host Info, Upd. DB\n")
    hcron.write ("17 05 * * * ${SADMIN}/bin/sadm_server_sunrise.sh >/dev/null 2>&1\n")
    hcron.write ("#\n")
    hcron.write ("# Morning report sent to Sysadmin by Email\n")
    hcron.write ("03 08 * * * ${SADMIN}/bin/sadm_rch_scr_summary.sh -m >/dev/null 2>&1\n")
    hcron.write ("#\n")
    hcron.write ("# O/S Update of all your servers - Optional\n")
    hcron.write ("#04 07 * * 1 ${SADMIN}/bin/sadm_osupdate_server.sh >/dev/null  2>&1\n")
    hcron.write ("#\n")
    hcron.close                                                         # Close SADMIN Crontab file

    # Change Server Crontab file permission to 644
    cmd = "chmod 644 %s" % (ccron_file)                                 # chmod 644 on ccron_file
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chmod on ccron_file
    if (ccode == 0):                                                    # If chmod went ok
        writelog( "Server Crontab Permission changed successfully")     # Show success
    else:                                                               # Did not went well
        writelog ("Problem changing Server crontab file permission")    # Had error on chmod cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    # Change Server Crontab file Owner and Group
    cmd = "chown %s.%s %s" % ('root','root',ccron_file)                 # chowner on ccron_file
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chown on ccron_file
    if (ccode == 0):                                                    # If chown went ok
        writelog( "Ownership of Server crontab changed successfully")   # Show success to user
    else:                                                               # Did not went well
        writelog ("Problem changing ownership of Server crontab file")  # Had an error on chown cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    return()                                                            # Return Cmd Path

#===================================================================================================
#                            Install pymysql module 
#===================================================================================================
def special_install(lpacktype) :

    if ((lpacktype != "deb") and (lpacktype != "rpm")):                 # Only rpm & deb Supported 
        writelog ("Package type invalid (%s)" % (lpacktype),'bold')     # Advise User UnSupported
        return (False)                                                  # Return False to caller

    # Install pymysql python3 module using pip3
    writelog ("Installing python3 PyMySQL module ... ",'nonl')          # Show what we are doing  
    cmd = "pip3 install PyMySQL"                                        # Command to execute
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute Command 
    if (ccode == 0):                                                    # If install went ok
        writelog( " Done ")                                             # Show success to user
    else:                                                               # Did not went well
        writelog ("Problem Installing PyMysql Python module")           # Had an error on cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    return()                                                            # Return Cmd Path



#===================================================================================================
#                            MAKE SURE SADMIN SUDO FILE IS IN PLACE
#===================================================================================================
def update_sudo_file(logfile) :

    writelog('')
    writelog('--------------------')
    writelog ('Updating SADMIN sudo file (/etc/sudoers.d/033_sadmin-nopasswd)')
    sudofile = '/etc/sudoers.d/033_sadmin-nopasswd'

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
    hsudo.write ('Defaults  env_keep += "SADMIN"')                      # Keep Env. Var. SADMIN 
    hsudo.write ("\nsadmin ALL=(ALL) NOPASSWD: ALL\n")                  # No Passwd for SADMIN
    hsudo.close                                                         # Close SADMIN sudo  file

    # Change sudo file permission to 440
    cmd = "chmod 440 %s" % (sudofile)                                   # chmod 440 on sudofile
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chmod on sudofile
    if (ccode == 0):                                                    # If chmod went ok
        writelog( "Permission on sudo file changed successfully")       # Show success to user
    else:                                                               # Did not went well
        writelog ("Problem changing sudo file permission")              # Had an error on sudo cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    # Change sudo file Owner and Group
    cmd = "chown %s.%s %s" % ('root','root',sudofile)                   # chowner on sudofile
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute chown on sudofile
    if (ccode == 0):                                                    # If chown went ok
        writelog( "Ownership of sudo file changed successfully")        # Show success to user
    else:                                                               # Did not went well
        writelog ("Problem changing ownership of sudo file")            # Had an error on chown cmd
        writelog ("%s - %s" % (cstdout,cstderr))                        # Write stdout & stderr

    return()                                                            # Return Cmd Path


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
def satisfy_requirement(stype,sroot,packtype,logfile):
    global fhlog

    # Based on installation Type (Client or Server), Move client or server dict. in Work Dict.
    writelog (" ")
    writelog ("--------------------")
    if (stype == 'C'):
        req_work = req_client                                           # Move CLient Dict in WDict.
        writelog ("Checking SADMIN Client Package requirement",'bold')  # Show User what we do
    else:
        # if (packtype == "rpm"):
        #     cmd = "setenforce 0" 
        #     ccode,cstdout,cstderr = oscommand(cmd)                      # Set SELinux to Permissive
        #     if (ccode == 0):
        #         writelog( "SeLinux Set to permissive mode for installation")
        #     else:
        #         writelog ("Problem changing SeLinux")
        #         writelog ("%s - %s" % (cstdout,cstderr))       
        req_work = req_server                                           # Move Server Dict in WDict.
        writelog (" ")
        writelog ("--------------------")
        writelog ("Checking SADMIN Server Package requirement",'bold')  # Show User what we do
    writelog (" ")

    # If Debian Package, Refresh The Local Repository 
    if (packtype == "deb"):                                             # Is Debian Style Package
        cmd =  "apt-get -y update >> %s 2>&1" % (logfile)               # Build Refresh Pack Cmd
        if (DRYRUN):                                                    # If Running if DRY-RUN Mode
            print ("DryRun - Would run : %s" % (cmd))                   # Only shw cmd we would run
        else:                                                           # If running in normal mode
            writelog ("Running apt-get update...",'nonl')               # Show what we are running
            (ccode, cstdout, cstderr) = oscommand(cmd)                    # Run the apt-get command
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
        pline = "Installing %s ... " % (needed_packages)
        writelog (pline,'nonl')        
        if (packtype == "deb") : 
            icmd = "apt-get -y install %s >>%s 2>&1" % (needed_packages,logfile)
        if (packtype == "rpm") : 
            if (needed_repo == "epel"):
                writelog (" from EPEL ... ",'nonl')
                icmd = "yum install --enablerepo=epel -y %s >>%s 2>&1" % (needed_packages,logfile)
            else:
                icmd = "yum install -y %s >>%s 2>&1" % (needed_packages,logfile)
        if (DRYRUN):
            writelog ("We would install %s with %s" % (needed_packages,icmd))
            continue                                                    # Proceed with Next Package
        writelog (icmd,'log')
        ccode, cstdout, cstderr = oscommand(icmd)
        if (ccode == 0) : 
            writelog (" Done ")
            #writelog ("Installed successfully")
        else:
            writelog   ("Error Code is %d - See log %s" % (ccode,logfile),'bold')


#===================================================================================================
#                       Setup MySQL Package and Load the SADMIN Database
#===================================================================================================
#
def setup_mysql(sroot,wcfg_server,wpass):
    
    writelog ('  ')
    writelog ('--------------------')
    writelog ("Setup SADMIN MySQL Database",'bold')
    
    # Accept 'root' Database user password
    sdefault = ""                                                       # No Default Password 
    sprompt  = "Enter MySQL Database 'root' user password"              # Prompt for Answer
    dbroot_pwd = accept_field(sroot,"SADM_ROOT",sdefault,sprompt,"P")   # Accept Mysql root pwd

    # Accept 'sadmin' Database Host to localhost 
    update_sadmin_cfg(sroot,"SADM_DBHOST","localhost",False)            # Update Value in sadmin.cfg
   
    # Accept 'sadmin' (Read/Write) User Password
    sdefault = "Nimdas1701"                                             # Default Password 
    sprompt  = "Enter Read/Write 'sadmin' database user password"       # Prompt for Answer
    wcfg_rw_dbpwd = accept_field(sroot,"SADM_RW_DBPWD",sdefault,sprompt,"P") # Accept sadmin DB user pwd
    update_sadmin_cfg(sroot,"SADM_RW_DBPWD",wcfg_rw_dbpwd,False)        # Update Value in sadmin.cfg
   
    # Accept 'squery' (Read Only) User Password
    sdefault = "Query18"                                                # Default Password 
    sprompt  = "Enter 'squery' database user password"                  # Prompt for Answer
    wcfg_ro_dbpwd = accept_field(sroot,"SADM_RO_DBPWD",sdefault,sprompt,"P")# Accept sadmin DB user pwd
    update_sadmin_cfg(sroot,"SADM_RO_DBPWD",wcfg_ro_dbpwd,False)        # Update Value in sadmin.cfg

    # Check if the initial Database Load SQL is present (sadmin.sql)
    init_sql = "%s/setup/etc/sadmin.sql" % (sroot)                      # Initial DB LOad SQL File
    if not os.path.isfile(init_sql):                                    # Initial SQL don't exist
        writelog("Initial Load SADMIN SQL Data (%s) file is missing" % (init_sql),'bold')
        writelog('Send log (%s) and submit problem to support@sadmin.ca' % (logfile),'bold')
        return (1)

    # # Stop the MariaDB Process & Start in Safe Mode
    # writelog (" ")
    # writelog ("Stopping MariaDB Server")
    # cmd = "systemctl stop mariadb"
    # ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    # cmd = "service mariadb stop" 
    # ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    # if os.path.isfile("/run/mariadb/mariadb.pid")     : cmd = "pkill -F /run/mariadb/mariadb.pid"
    # if os.path.isfile("/var/run/mysqld/mysqld.pid")   : cmd = "pkill -F /var/run/mysqld/mysqld.pid"
    # if os.path.isfile("/var/run/mariadb/mariadb.pid") : cmd = "pkill -F /var/run/mariadb/mariadb.pid"
    # ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    # time.sleep(1)
 
    # writelog ("Starting MariaDB Server in safe mode")
    # cmd = "mysqld_safe --user=mysql &"
    # ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    # time.sleep(1)

    # Starting and Enabling MariabDB Service
    writelog ('  ')
    writelog ('----------')
    writelog ("Restart Mariadb Service & Setup Service",'bold')
    cmd = "systemctl restart mariadb"
    writelog ("Starting MariaDB Service - %s" % (cmd))
    ccode,cstdout,cstderr = oscommand(cmd)                              # Restart MariaDB Server
    if (ccode != 0):                                                    # Problem Starting DB
        writelog ("Problem Starting MariabDB server... ")               # Advise User
        writelog ("Return code is %d - %s" % (ccode,cmd))               # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    time.sleep(1)
    cmd = "systemctl enable mariadb"                                    # Enable MariaDB on boot
    writelog ("Enabling MariaDB Service - %s" % (cmd))
    ccode,cstdout,cstderr = oscommand(cmd)                              # Enable MariaDB Server
    if (ccode != 0):                                                    # Problem Enabling Service
        writelog ("Problem with enabling MariabDB Service.")            # Advise User
        writelog ("Return code is %d - %s" % (ccode,cmd))               # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    time.sleep(1)

    # Change MariaDB root password
    cmd = "mysqladmin -u root password '%s'" % (dbroot_pwd)             # Cmd to change root pwd
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode != 0):                                                    # If problem Changing Passwd
        writelog ("Problem changing MariaDB password (mysqladmin)... ") # Advise User
        writelog ("Return code is %d" % (ccode))                        # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    time.sleep(1)
    cmd = "mysqladmin -u root -h %s password '%s'" % (wcfg_server,dbroot_pwd) # Cmd to change root pwd
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode != 0):                                                    # If problem deleting user
        writelog ("Problem changing MariaDB password (mysqladmin)... ") # Advise User
        writelog ("Return code is %d" % (ccode))                        # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    time.sleep(1)

    # Load Initial Database
    writelog ('  ')
    writelog ('----------')
    writelog ("Loading Initial Data in SADMIN Database ... ",'nonl')    # Load Initial Database 
    cmd = "mysql -u root -p%s < %s" % (dbroot_pwd,init_sql)             # SQL Cmd to Load DB
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode != 0):                                                    # If problem deleting user
        writelog ("Problem loading the database ...")                   # Advise User
        writelog ("Return code is %d - %s" % (ccode,cmd))               # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    else:                                                               # If user deleted
        writelog (' Done ')                                             # Advise User ok to proceed
    time.sleep(1)
    
    # Create 'sadmin' user and Grant permission 
    writelog ("Creating 'sadmin' user ... ",'nonl')
    sql  = "CREATE USER 'sadmin'@'localhost' IDENTIFIED BY '%s';" % (wcfg_rw_dbpwd)
    sql += " grant all privileges on sadmin.* to 'sadmin'@'localhost';"
    sql += " flush privileges;"
    cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command 
    if (ccode != 0):                                                    # If problem creating user
        writelog ("Error code returned is %d \n%s" % (ccode,cmd))       # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    else:                                                               # If user created
        writelog (" Done ")                                             # Advise User ok to proceed
    
    # Create 'squery' user and Grant permission 
    writelog ("Creating 'squery' user ... ",'nonl')
    sql  = "CREATE USER 'squery'@'localhost' IDENTIFIED BY '%s';" % (wcfg_ro_dbpwd)
    sql += " grant select, show view on sadmin.* to 'squery'@'localhost';"
    sql += " flush privileges;"
    cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command 
    if (ccode != 0):                                                    # If problem creating user
        writelog ("Error code returned is %d \n%s" % (ccode,cmd))       # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    else:                                                               # If user created
        writelog (" Done ")                                             # Advise User ok to proceed
    time.sleep(1)

    # Change root mysql password to the one user entered
    #sql = "grant all privileges on *.* to 'root'@'localhost' identified by '%s';" % (dbroot_pwd)
    #sql += " flush privileges;"
    #cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)
    #cmd = "mysql -u root -e \"%s\"" % (sql)
    #ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command 
    #if (ccode != 0):                                                    # If problem creating user
    #    writelog ("Error code returned is %d \n%s" % (ccode,cmd))       # Show Return Code No
    #    writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
    #    writelog ("Standard error is %s" % (cstderr))                   # Print command stderr
    #else:                                                               # If user created
    #    writelog (" Done ")                                             # Advise User ok to proceed
    #time.sleep(1)

    # Stop / Restart the MariaDB Process
    #writelog ("Stopping MariaDB Server")
    #cmd = "systemctl stop mariadb"
    #ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    #cmd = "service mariadb stop" 
    #ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    #if os.path.isfile("/run/mariadb/mariadb.pid")     : cmd = "pkill -F /run/mariadb/mariadb.pid"
    #if os.path.isfile("/var/run/mysqld/mysqld.pid")   : cmd = "pkill -F /var/run/mysqld/mysqld.pid"
    #if os.path.isfile("/var/run/mariadb/mariadb.pid") : cmd = "pkill -F /var/run/mariadb/mariadb.pid"
    #ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    #time.sleep(1)
    writelog ("Restarting MariaDB Server ...",'nonl')
    cmd = "systemctl restart mariadb"
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode != 0):                                                    # If problem creating user
        writelog ("Problem Restarting MariaDB Service - Error %d \n%s" % (ccode,cmd)) # Show Error#
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
    open("%s/log/sadmin_error.log"  % (sroot),'a').close                  # Touch Apache SADMIN log
    open("%s/log/sadmin_access.log" % (sroot),'a').close                  # Touch Apache SADMIN log

    # Set the name of Web Server Service depending on Linux O/S
    sservice = "httpd"
    if (spacktype == "deb" ) : sservice = "apache2" 
    
    # Start Web Server
    writelog ("Making sure Web Server is started")
    cmd = "systemctl restart %s" % (sservice)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode != 0):                                                    # If problem creating user
        writelog ("Problem Restarting Web Server - Error %d \n%s" % (ccode,cmd)) # Show Return Code No
        writelog ("Standard out is %s" % (cstdout))                     # Print command stdout
        writelog ("Standard error is %s" % (cstderr))                   # Print command stderr

    # Get the httpd process owner
    cmd = "ps -ef | grep -Ev 'root|grep' | grep '%s' | awk '{ print $1 }' | sort | uniq" % (sservice)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute O/S Command
    apache_user = cstdout                                               # Get Apache Process Usr
    if (DEBUG):                                                         # If Debug Activated
        writelog ("Return code for getting httpd user name is %d" % (ccode))
    writelog ("Apache process user name  : %s" % (apache_user))         # Show Apache Proc. User

    # Get the group of httpd process owner 
    cmd = "id -gn %s" % (apache_user)                                   # Get Apache User Group
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute O/S Command
    apache_group = cstdout                                              # Get Group from StdOut
    if (DEBUG):                                                         # If Debug Activated
        writelog ("Return code for getting httpd group name is %d" % (ccode))                 
    writelog ("Apache process group name : %s" % (apache_group))        # Show Apache  Group

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
        # Disable Default apache2 configuration
        cmd = "a2dissite 000-default.conf"                              # Disable default Web Site 
        ccode,cstdout,cstderr = oscommand(cmd)                          # Execute Command
        if (ccode == 0):
            writelog( "Disable default apache configuration")
        else:
            writelog ("Problem disabling apache2 default configuration")
            writelog ("%s - %s" % (cstdout,cstderr))        
        # Enable SADMIN Configuration
        cmd = "a2ensite sadmin.conf"                                    # Enable Web Site In Apache
        ccode,cstdout,cstderr = oscommand(cmd)                          # Execute Command                       
        if (ccode == 0):
            writelog( "SADMIN Web Site enable")
        else:
            writelog ("Problem enabling SADMIN Web Site")
            writelog ("%s - %s" % (cstdout,cstderr))
        apache2_config = "/etc/apache2/sites-enabled/sadmin.conf"

    # Setup Web configuration for RedHat, CentOS, Fedora (rpm)
    if (spacktype == "rpm") :
        # Updating the httpd configuration file 
        sadm_file="%s/setup/etc/sadmin.conf" % (sroot)                  # Init. Sadmin Web Cfg
        apache2_config="/etc/httpd/conf.d/sadmin.conf"                    # Apache Path to cfg File
        if not os.path.exists(apache2_config):                            # If Web cfg Not Found
            try:
                shutil.copyfile(sadm_file,apache2_config)                 # Copy Initial Web cfg
            except IOError as e:
                writelog("Unable to copy httpd config file. %s" % e)    # Advise user before exiting
                sys.exit(1)                                             # Exit to O/S With Error
            except:
                writelog("Unexpected error:", sys.exc_info())           # Advise Usr Show Error Msg
                sys.exit(1)                                             # Exit to O/S with Error
        update_apache_config(sroot,apache2_config,"{WROOT}",sroot)        # Set WWW Root Document
        update_apache_config(sroot,apache2_config,"{EMAIL}",semail)       # Set WWW Admin Email
        update_apache_config(sroot,apache2_config,"{DOMAIN}",sdomain)     # Set WWW sadmin.{Domain}     

               
    # Update the sadmin.cfg with Web Server User and Group
    writelog('')
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
    cmd = "chmod -R 775 %s/www" % (sroot)                               # chmod 775 on all www dir.
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem changing Web Site permission")
        writelog ("%s - %s" % (cstdout,cstderr))        
    
    # Setting permissions on Website images
    writelog ("  - Setting Permission on SADMIN WebSite images (%s/www/images) ... " % (sroot),'nonl') 
    cmd = "chmod -R 644 %s/www/images" % (sroot)                        # chmod 775 on all www dir.
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Lload DB
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem changing Website images permission")
        writelog ("%s - %s" % (cstdout,cstderr))        
                

    # Restarting Web Server with new configuration
    writelog ("Web Server Restarting ... ",'nonl')
    cmd = "systemctl restart %s" % (sservice) 
    ccode,cstdout,cstderr = oscommand(cmd)                          
    if (ccode == 0):
        writelog( " Done ")
    else:
        writelog ("Problem Starting the Web Server",'bold')
        writelog ("%s - %s" % (cstdout,cstderr))        

    # Enable Web Server Service so it restart upon reboot
    writelog ("Enabling Web Server Service ... ",'nonl')
    cmd = "systemctl enable %s" % (sservice) 
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
    fi.close                                                            # File read now close it
    fo.close                                                            # Close the output file

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
#        Set and/or Validate that SADMIN Environment Variable is set in /etc/environent file
#===================================================================================================
#
def set_sadmin_env(ver):

    # Is SADMIN Environment Variable Defined ? , If not ask user to specify it
    if "SADMIN" in os.environ:                                          # Is SADMIN Env. Var. Exist?
        sadm_base_dir = os.environ.get('SADMIN')                        # Get SADMIN Base Directory
    else:                                                               # If Not Ask User Full Path
        sadm_base_dir = input("Enter directory path where your install SADMIN : ")

    # Does Directory specify exist ?
    if not os.path.exists(sadm_base_dir) :                              # Check if SADMIN Dir. Exist
        print ("Directory %s doesn't exist." % (sadm_base_dir))         # Advise User
        sys.exit(1)                                                     # Exit with Error Code

    # Check if Directory specify contain the Shell SADMIN Library (Indicate Dir. is the good one)
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
    if os.path.exists(SADM_PROFILE)==False:                             # If sadmin.sh Not Found
        try:
            shutil.copyfile(SADM_INIFILE,SADM_PROFILE)                  # Copy Initial sadmin.sh 
        except IOError as e:
            writelog("Unable to copy %s to %s" % (SADM_INIFILE,SADM_PROFILE)) # Advise user 
            sys.exit(1)                                                 # Exit to O/S With Error
        except:
            writelog("Unexpected error:", sys.exc_info())               # Advise Usr Show Error Msg
            sys.exit(1)                                                 # Exit to O/S with Error

    # Open the current /etc/profile.d/sadmin.sh 
    try : 
        fi = open(SADM_PROFILE,'r')                                     # Open SADMIN Env. Setting 
    except FileNotFoundError as e :                                     # If Env file doesn't exist
        fi = open(SADM_PROFILE,'w')                                     # Open in Write Mode 
        fi.close()                                                      # Just to create one
        fi = open(SADM_PROFILE,'r')                                     # Re-open in read mode

    # Open the new sadmin.sh tmp file to ake sure SADMIN variable is set properly
    fo = open(SADM_TMPFILE,'w')                                         # Environment Output File
    fileEmpty=True                                                      # Env. file assume empty
    eline = "export SADMIN=%s\n" % (sadm_base_dir)                      # Line needed in sadmin.sh.
    for line in fi:                                                     # Read Input file until EOF
        if line.startswith( 'export SADMIN=' ) :                        # line Start with 'SADMIN='?
           line = "%s" % (eline)                                        # Replace line with latest
        fo.write (line)                                                 # Write line to output file
        fileEmpty=False                                                 # File was not empty flag
    fi.close                                                            # File read now close it
    if (fileEmpty) :                                                    # If Input file was empty
        line = "%s\n" % (eline)                                         # Add line with needed line
        fo.write (line)                                                 # Write 'export SADMIN=' Line
    fo.close                                                            # Close the output file
    try:                                                                # Will try rename env. file
        os.rename(SADM_PROFILE,SADM_ORGFILE)                            # Rename current to org
        os.rename(SADM_TMPFILE,SADM_PROFILE)                            # Rename tmp to real one
    except:
        print ("Error renaming %s" % (SADM_PROFILE))                    # Show User if error
        sys.exit(1)                                                     # Exit to O/S with Error

    print ("SADMIN Environment variable is now set to %s" % (sadm_base_dir))
    print ("      - The line below is now in %s now" % (SADM_PROFILE)) 
    print ("      - %s" % (eline),end='')                               # SADMIN Line in sadmin.sh
    print ("      - This will make sure it is set upon reboot")         # Under Linux This will work
    return sadm_base_dir                                                # Return SADMIN Root Dir


#===================================================================================================
#           Make sure $SADMIN/cfg/sadmin.cfg exist, if not cp .sadmin.cfg to sadmin.cfg
#===================================================================================================
#
def create_sadmin_config_file(sroot):
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
    writelog ("Initial SADMIN configuration file (%s) is now in place" % (cfgfile)) # Advise User
    writelog (' ')
    

#===================================================================================================
#                     Replacing Value in SADMIN configuration file (sadmin.cfg)
#  1st = Root Dir. of SADMIN, 2nd = Name of setting, 3rd = Value of the setting, 4th = Show Upd. line
# ===================================================================================================
#
def update_sadmin_cfg(sroot,sname,svalue,show=True):
    """
    [Update the SADMIN configuration File.]
    Arguments:
    sroot  {[string]}   --  [SADMIN root install directory]
    sname  {[string]}   --  [Name of variable in sadmin.cfg to change value]
    svalue {[string]}   --  [New value of the variable]
    """    
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
    fi.close                                                            # File read now close it
    if (lineNotFound) :                                                 # SNAME wasn't found in file
        line = "%s\n" % (cline)                                         # Add needed line
        fo.write (line)                                                 # Write 'SNAME = SVALUE Line
    fo.close                                                            # Close the output file

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
    docname = "%s/doc/cfg/%s.txt" % (sroot,sname.lower())               # Set Documentation FileName
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
#           wdata = int(input("%s : " % (eprompt)))                 # Accept an Integer
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
#            Ask Important Info that need to be accurate in the $SADMIN/cfg/sadmin.cfg file
#===================================================================================================
#
def setup_sadmin_config_file(sroot):
    global stype                                                        # C=Client S=Server Install

    # Get OS Type (Linux, Aix, Darwin, OpenBSD)
    ccode, cstdout, cstderr = oscommand("uname -s")                     # Get O/S Type
    wostype=cstdout.upper()                                             # OSTYPE = LINUX or AIX
    if (DEBUG):                                                         # If Debug Activated
        writelog ("Current OStype is: %s" % (wostype))                     # Print the O/S Type

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

    # Accept the Email type to use at the end of each sript execution
    sdefault = 1                                                        # Default value 1
    sprompt  = "Enter default email type"                               # Prompt for Answer
    wcfg_mail_type = accept_field(sroot,"SADM_MAIL_TYPE",sdefault,sprompt,"I",0,3)
    update_sadmin_cfg(sroot,"SADM_MAIL_TYPE",wcfg_mail_type)            # Update Value in sadmin.cfg

    # Accept the Default Domain Name
    sdefault = socket.getfqdn().split('.', 1)[1]                        # Set Current  Default value 
    sprompt  = "Default domain name"                                    # Prompt for Answer
    wcfg_domain = accept_field(sroot,"SADM_DOMAIN",sdefault,sprompt)    # Accept Default Domain Name
    update_sadmin_cfg(sroot,"SADM_DOMAIN",wcfg_domain)                  # Update Value in sadmin.cfg

    # Accept the SADMIN FQDN Server name
    sdefault = ""                                                       # No Default value 
    if (stype == "S"): sdefault = socket.getfqdn()                      # Server Install=Hostname
    sprompt  = "Enter SADMIN (FQDN) server name"                        # Prompt for Answer
    while True:                                                         # Accept until valid server
        wcfg_server = accept_field(sroot,"SADM_SERVER",sdefault,sprompt)# Accept SADMIN Server Name
        writelog ("Validating server name ...")                         # Advise User Validating
        try :
            xip = socket.gethostbyname(wcfg_server)                     # Try to get IP of Server
        except (socket.gaierror) as error :                             # Unable to get Server IP
            writelog("Server Name %s isn't valid" % (wcfg_server),'bold')# Advise Invalid Server
            continue                                                    # Go Re-Accept Server Name
        xarray = socket.gethostbyaddr(xip)                              # Use IP & Get HostName
        yname = repr(xarray[0]).replace("'","")                         # Remove the ' from answer
        if (yname != wcfg_server) :                                     # If HostName != EnteredName
            writelog("The server %s with ip %s is returning %s" % (wcfg_server,xip,yname))
            writelog("FQDN is wrong or the IP doesn't correspond")      # Advise USer 
            continue                                                    # Return Re-Accept SADMIN
        else:
            break                                                       # Ok Name pass the test
    update_sadmin_cfg(sroot,"SADM_SERVER",wcfg_server)                  # Update Value in sadmin.cfg

    # Accept the maximum number of lines we want in every log produce
    sdefault = 1000                                                     # No Default value 
    sprompt  = "Maximum number of lines in LOG file"                    # Prompt for Answer
    wcfg_max_logline = accept_field(sroot,"SADM_MAX_LOGLINE",sdefault,sprompt,"I",1,10000)
    update_sadmin_cfg(sroot,"SADM_MAX_LOGLINE",wcfg_max_logline)        # Update Value in sadmin.cfg

    # Accept the maximum number of lines we want in every RCH file produce
    sdefault = 100                                                      # No Default value 
    sprompt  = "Maximum number of lines in RCH file"                    # Prompt for Answer
    wcfg_max_rchline = accept_field(sroot,"SADM_MAX_RCHLINE",sdefault,sprompt,"I",1,300)
    update_sadmin_cfg(sroot,"SADM_MAX_RCHLINE",wcfg_max_rchline)        # Update Value in sadmin.cfg

    # Accept the Default User Group
    sdefault = "sadmin"                                                 # Set Default value 
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
        writelog ("Creating group %s" % (wcfg_group))                      # Show creating the group
        if wostype == "LINUX" :                                         # Under Linux
            ccode,cstdout,cstderr = oscommand("groupadd %s" % (wcfg_group))   # Add Group on Linux
        if wostype == "AIX" :                                           # Under AIX
            ccode,cstdout,cstderr = oscommand("mkgroup %s" % (wcfg_group))    # Add Group on Aix
        if (DEBUG):                                                     # If Debug Activated
            writelog ("Return code is %d" % (ccode))                    # Show AddGroup Cmd Error No
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
        if (DEBUG):                                                     # If Debug Activated
            writelog ("Return code is %d" % (ccode))                    # Show AddGroup Cmd Error #
    else:
        writelog ("Creating user %s" % (wcfg_user))                     # Create user on system
        if wostype == "LINUX" :                                         # Under Linux
            cmd = "useradd -g %s -s /bin/sh " % (wcfg_group)            # Build Add user Command 
            cmd += " -d %s "    % (os.environ.get('SADMIN'))            # Assign Home Directory
            cmd += " -c'%s' %s" % ("SADMIN Tools User",wcfg_user)       # Add comment and user name
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Create User
        if wostype == "AIX" :                                           # Under AIX
            cmd = "mkuser pgrp='%s' -s /bin/sh " % (wcfg_group)         # Build mkuser command
            cmd += " home='%s' " % (os.environ.get('SADMIN'))           # Set Home Directory
            cmd += " gecos='%s' %s" % ("SADMIN Tools User",wcfg_user)   # Set comment and user name
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Create User
        if (DEBUG):                                                     # If Debug Activated
            writelog ("Return code is %d" % (ccode))                    # Show AddGroup Cmd Error #
    update_sadmin_cfg(sroot,"SADM_USER",wcfg_user)                      # Update Value in sadmin.cfg
    
    # Change owner of all files in $SADMIN
    cmd = "find %s -exec chown %s.%s {} \;" % (sroot,wcfg_user,wcfg_group)
    writelog (" ")                                                      # White Line
    writelog ("Change %s ownership : %s" % (sroot,cmd))                 # Show what we are doing
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
    
    return(wcfg_server,wcfg_domain,wcfg_mail_addr)                      # Return to Caller


#===================================================================================================
#         DETERMINE THE LINUX INSTALLATION PACKAGE TYPE AND OPEN THE SCRIPT LOG FILE 
#===================================================================================================
#
def getpacktype(sroot):

    # Determine type of software package based on command present on system 
    packtype=""                                                         # Set Initial Packaging Type
    if (locate_command('rpm')   != "") : packtype="rpm"                 # Is rpm command on system ?
    if (locate_command('dpkg')  != "") : packtype="deb"                 # is deb command on system ?
    if (locate_command('lslpp') != "") : packtype="aix"                 # Is lslpp cmd on system ?
    if (packtype == ""):                                                # If unknow/unsupported O/S
        writelog ('None of these commands are found (rpm, pkg or lslpp absent)')
        writelog ('No supported package type is detected')
        writelog ('Process aborted')
        sys.exit(1)                                                     # Exit to O/S    
    return (packtype)                                                   # Return Packtype 


#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def end_message(sroot,sdomain):
    writelog ("\n\n--------------------------------------------------")
    writelog ("END OF SADMIN SETUP, YOU CAN NOW USE THE SADMIN TOOLS\n",'bold')
    writelog ("You need to logout and log back in, before using SADM Tools")
    writelog ("or type the following command (The dot and the space are important)")
    writelog (". /etc/profile.d/sadmin.sh")
    writelog ("This will make sure SADMIN environment variable is define with the right content")
    writelog ("\n\nTO CREATE YOUR OWN SCRIPT USING SADMIN LIBRARY",'bold')
    writelog ("To create your own script using SADMIN, you may want to run and view the code of ")
    writelog ("%s/bin/sadm_template.sh and %s/bin/sadm_template.py as a starting point" % (sroot,sroot))
    writelog ("You may also want to run %s/lib/sadmlib_test.sh and %s/lib/sadmlib_test.py." % (sroot,sroot))
    writelog ("They will present all functions available to your shell or Python script")
    writelog ("\n\nUSE THE WEB INTERFACE TO ADMINISTRATE YOUR LINUX SERVER FARM",'bold')
    writelog ("The web Interface is available at http://sadmin.%s" % (sdomain))
    writelog ("\n\n--------------------------------------------------")


#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    global fhlog                                                        # Script Log File Handler

    os.system('clear')                                                  # Clear the screen
    print ("SADMIN Setup V%s\n------------------" % (sver))             # Print Version Number

    # Insure that this script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
       print ("This script must be run by the 'root' user")             # Advise User Message / Log
       print ("Try sudo ./%s" % (pn))                                   # Suggest to use 'sudo'
       print ("Process aborted")                                        # Process Aborted Msg
       sys.exit(1)                                                      # Exit with Error Code

    sroot=set_sadmin_env(sver)                                          # Set SADMIN Var./Return Dir
    (fhlog,logfile) = open_logfile(sroot)                               # OpenLog Return File Handle
    if (DEBUG) : writelog("Directory SADMIN now set to %s" % (sroot))   # Show SADMIN Root Dir.
    create_sadmin_config_file(sroot)                                    # Create Initial sadmin.cfg
    (packtype) = getpacktype(sroot)                                     # Pack Type (rpm,deb,lslpp)
    if (DEBUG) : writelog("Package type on system is %s" % (packtype))  # Debug, Show Packaging Type 
    (userver,udomain,uemail) = setup_sadmin_config_file(sroot)          # Ask Config questions
    satisfy_requirement('C',sroot,packtype,logfile)                     # Verify/Install Client Req.
    rrdtool_path = locate_command("rrdtool")                            # Get rrdtool path
    update_sadmin_cfg(sroot,"SADM_RRDTOOL",rrdtool_path,False)          # Update Value in sadmin.cfg
    special_install(packtype)                                           # pip3 PyMySQL Install
    update_sudo_file(logfile)                                           # Create the sudo file
    update_client_crontab_file(logfile)                                 # Create Client Crontab File 

    # SADMIN Server 
    if (stype == 'S') :                                                 # If install SADMIN Server
        update_host_file(udomain)                                       # Update /etc/hosts file
        satisfy_requirement('S',sroot,packtype,logfile)                 # Verify/Install Server Req.
        setup_mysql(sroot,userver,' ')                                  # Setup/Load MySQL Database
        setup_webserver(sroot,packtype,udomain,uemail)                  # Setup & Start Web Server
        update_server_crontab_file(logfile)                             # Create Server Crontab File 

    # End of Setup
    end_message(sroot,udomain)                                          # Last Message to User
    fhlog.close()                                                       # Close Script Log
    sys.exit(0)                                                         # Exit to Operating System


# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
