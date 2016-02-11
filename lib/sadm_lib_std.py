#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_lib_std.py
#   Synopsis:   This is the Standard SADM Python Library 
#===================================================================================================
import os, errno, time, sys, pdb, socket, datetime, getpass, subprocess, smtplib
from subprocess import Popen, PIPE
#pdb.set_trace() 


#===================================================================================================
#                    Global Variables Shared among all SADM Libraries and Scripts
#===================================================================================================
ver                = "1.0"                                              # Default Program Version
logtype            = "B"                                                # Default S=Scr L=Log B=Both
multiple_exec      = "N"                                                # Default Run multiple copy
debug              = 8                                                  # Default Debug Level (0-9)
exit_code          = 0                                                  # Script Error Return Code

pn                 = os.path.basename(sys.argv[0])                      # Program name
inst               = os.path.basename(sys.argv[0]).split('.')[0]        # Program name without Ext.
tpid               = str(os.getpid())                                   # Get Current Process ID.
hostname           = socket.gethostname().split('.')[0]                 # Get current hostname
dash_line          = "=" * 80                                           # Line of 80 dash
username           = getpass.getuser()                                  # Get Current User Name
args               = len(sys.argv)                                      # Nb. argument receive
osname             = os.name                                            # OS name (nt,dos,posix,...)
platform           = sys.platform                                       # Platform (win32,mac,posix)
start_time         = ""                                                 # Script Start Date & Time
stop_time          = ""                                                 # Script Stop Date & Time
start_epoch        = ""                                                 # Script Start EPoch Time

# SADM Sub Directories Definitions
base_dir           = os.environ.get('SADMIN','/sadmin')                 # Set SADM Base Directory
lib_dir            = os.path.join(base_dir,'lib')                       # SADM Lib. Directory
tmp_dir            = os.path.join(base_dir,'tmp')                       # SADM Temp. Directory
cfg_dir            = os.path.join(base_dir,'cfg')                       # SADM Config Directory
bin_dir            = os.path.join(base_dir,'bin')                       # SADM Scripts Directory
log_dir            = os.path.join(base_dir,'log')                       # SADM Log Directory
www_dir            = os.path.join(base_dir,'www')                       # SADM WebSite Dir Structure
pkg_dir            = os.path.join(base_dir,'pkg')                       # SADM Package Directory
sys_dir            = os.path.join(base_dir,'sys')                       # SADM System Scripts Dir.
dat_dir            = os.path.join(base_dir,'dat')                       # SADM Data Directory
nmon_dir           = os.path.join(dat_dir,'nmon')                       # SADM nmon File Directory
rch_dir            = os.path.join(dat_dir,'rch')                        # SADM Result Code Dir.
dr_dir             = os.path.join(dat_dir,'dr')                         # SADM Disaster Recovery Dir
sar_dir            = os.path.join(dat_dir,'sar')                        # SADM System Activity Rep.
www_dat_dir        = os.path.join(www_dir,'dat')                        # SADM Web Site Data Dir
www_html_dir       = os.path.join(www_dir,'html')                       # SADM Web Site Dir

# SADM Files Definition
log_file           = log_dir + '/' + hostname + '_' + inst + '.log'     # Log Filename
rch_file           = rch_dir + '/' + hostname + '_' + inst + '.rch'     # RCH Filename
cfg_file           = cfg_dir + '/sadmin.cfg'                            # Configuration Filename
cfg_hidden         = cfg_dir + '/.sadmin.cfg'                           # Hidden Config Filename
pid_file           = "%s/%s.pid" % (tmp_dir, inst)                      # Process ID File
tmp_file_prefix    = tmp_dir + '/' + hostname + '_' + inst              # TMP Prefix
tmp_file1          = "%s_1.%s" % (tmp_file_prefix,tpid)                 # Temp1 Filename
tmp_file2          = "%s_2.%s" % (tmp_file_prefix,tpid)                 # Temp2 Filename
tmp_file3          = "%s_3.%s" % (tmp_file_prefix,tpid)                 # Temp3 Filename

# SADM Configuration file - Variables were loaded form the configuration file (Can be overridden)
cfg_mail_type      = 1                                                  # 0=No 1=Err 2=Succes 3=All
cfg_mail_addr      = ""                                                 # Default is in sadmin.cfg
cfg_cie_name       = ""                                                 # Company Name
cfg_user           = ""                                                 # sadmin user account
cfg_server         = ""                                                 # sadmin FQN Server
cfg_group          = ""                                                 # sadmin group account
cfg_max_logline    = 5000                                               # Max Nb. Lines in LOG )
cfg_max_rchline    = 100                                                # Max Nb. Lines in RCH file
cfg_nmon_keepdays  = 60                                                 # Days to keep old *.nmon
cfg_sar_keepdays   = 60                                                 # Days to keep old *.sar
cfg_rch_keepdays   = 60                                                 # Days to keep old *.rch
cfg_log_keepdays   = 60                                                 # Days to keep old *.log


# SADM Path to various commands used by SADM Tools
lsb_release        = ""                                                 # Command lsb_release Path
which              = ""                                                 # whic1h Path - Required
dmidecode          = ""                                                 # Command dmidecode Path
bc                 = ""                                                 # Command bc (Do Some Math)
fdisk              = ""                                                 # fdisk (Read Disk Capacity)
prtconf            = ""                                                 # prtconf  Path - Required
perl               = ""                                                 # perl Path (for epoch time)
uname              = ""                                                 # uname command path
mail               = ""                                                 # mail command path

#pdb.set_trace() 


# --------------------------------------------------------------------------------------------------
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
# --------------------------------------------------------------------------------------------------
def oscommand(command) :
    if debug > 8 : writelog ("In sadm_oscommand function to run command : %s" % (command))
    p = subprocess.Popen(command, stdout=PIPE, stderr=PIPE, shell=True)
    out = p.stdout.read().strip()
    err = p.stderr.read().strip()
    returncode = p.wait()
    if debug > 8 :
        writelog ("In sadm_oscommand function stdout is      : %s" % (out))
        writelog ("In sadm_oscommand function stderr is      : %s " % (err))
        writelog ("In sadm_oscommand function returncode is  : %s" % (returncode))
    #if returncode:
    #    raise Exception(returncode,err)
    #else :
    return (returncode,out,err)


# --------------------------------------------------------------------------------------------------
#               FUNCTION REMOVE THE FILENAME RECEIVED -- IT'S OK IF REMOVE FAILED
# --------------------------------------------------------------------------------------------------
def silentremove(filename):
    try:
        os.remove(filename)                                             # Remove selected file
    except OSError as e:                                                # If OSError
        if e.errno != errno.ENOENT :                                    # errno.no such file or Dir.
            raise                                                       # raise exception if diff.err

            
# --------------------------------------------------------------------------------------------------
#                        CURRENT USER IS "ROOT" (True) OR NOT ? (False)
# --------------------------------------------------------------------------------------------------
#
def is_root() :
    if not os.geteuid() == 0:                                           # If Current User not root
       return False                                                     # Return False
    else :                                                              # If Current user is root
       return True                                                      # Return True




#===================================================================================================
#                                       Write Log to file 
#===================================================================================================
def writelog(sline):
    global FH_LOG_FILE
    
    now = datetime.datetime.now()
    logLine = now.strftime("%Y.%m.%d %H:%M:%S") + " - %s" % (sline)
    if logtype.upper() == "L" :  FH_LOG_FILE.write ("%s\n" % (logLine))
    if logtype.upper() == "S" :  print ("%s" % logLine)
    if logtype.upper() == "B" :  
       FH_LOG_FILE.write ("%s\n" % (logLine))
       print ("%s" % logLine) 

            

# --------------------------------------------------------------------------------------------------
#                                 RETURN THE HOSTNAME (SHORT)
# --------------------------------------------------------------------------------------------------
def get_hostname():
    if sadm_get_ostype() == "LINUX" :                                   # Under Linux
       ccode, cstdout, cstderr = oscommand("hostname -s")               # Execute O/S CMD 
    if sadm_get_ostype() == "AIX" :                                     # Under AIX
       ccode, cstdout, cstderr = oscommand("hostname")                  # Execute O/S CMD 
    whostname=cstdout.upper()
    return whostname


# --------------------------------------------------------------------------------------------------
#                                 RETURN THE DOMAINNAME 
# --------------------------------------------------------------------------------------------------
def get_domainname():
    whostname = get_hostname()
    if sadm_get_ostype() == "LINUX" :                                   # Under Linux
       ccode, cstdout, cstderr = oscommand("host $whostname) |head -1 |awk '{ print $1 }' |cut -d. -f2-3")               # Execute O/S CMD 
    if sadm_get_ostype() == "AIX" :                                     # Under AIX
       ccode, cstdout, cstderr = oscommand("namerslv -s | grep domain | awk '{ print $2 }'")
    wdomainname=cstdout.upper()
    return wdomainname
            

# --------------------------------------------------------------------------------------------------
#                              RETURN THE IP OF THE CURRENT HOSTNAME
# --------------------------------------------------------------------------------------------------
def get_host_ip():
    whostname = get_hostname()
    wdomain = get_domainname()
    if sadm_get_ostype() == "LINUX" :                                   # Under Linux
       ccode, cstdout, cstderr = oscommand("host $whostname |awk '{ print $4 }' |head -1") 
    if sadm_get_ostype() == "AIX" :                                     # Under AIX
       ccode, cstdout, cstderr = oscommand("host $whostname.$wdomain |head -1 |awk '{ print $3 }'")
    whostip=cstdout.upper()
    return whostip


# --------------------------------------------------------------------------------------------------
#                     Return if running 32 or 64 Bits Kernel version
# --------------------------------------------------------------------------------------------------
def get_kernel_bitmode():
    if sadm_get_ostype() == "LINUX" :                                   # Under Linux
       ccode, cstdout, cstderr = oscommand("getconf LONG_BIT") 
    if sadm_get_ostype() == "AIX" :                                     # Under AIX
       ccode, cstdout, cstderr = oscommand("getconf KERNEL_BITMODE")
    wkbits=cstdout.upper()
    return wkbits




# --------------------------------------------------------------------------------------------------
#                                 RETURN KERNEL RUNNING VERSION
# --------------------------------------------------------------------------------------------------
def get_kernel_version():
    if sadm_get_ostype() == "LINUX" :                                   # Under Linux
       ccode, cstdout, cstderr = oscommand("uname -r | cut -d. -f1-3") 
    if sadm_get_ostype() == "AIX" :                                     # Under AIX
       ccode, cstdout, cstderr = oscommand("uname -r")
    wkver=cstdout.upper()
    return wkver

               
            
# --------------------------------------------------------------------------------------------------
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
# --------------------------------------------------------------------------------------------------
def get_ostype():
    ccode, cstdout, cstderr = oscommand("uname -s")
    get_ostype=cstdout.upper()
    return get_ostype


    
# --------------------------------------------------------------------------------------------------
#                   RETURN THE OS  NAME (ALWAYS RETURNED IN UPPERCASE)
# --------------------------------------------------------------------------------------------------
def get_osname() :
    ccode, cstdout, cstderr = oscommand(lsb_release + " -si")
    osname=cstdout.upper()
    if osname  == "REDHATENTERPRISESERVER" : osname="REDHAT"
    if osname  == "REDHATENTERPRISEAS"     : osname="REDHAT"
    if get_ostype() == "AIX" : osname="AIX"
    return osname

        

# --------------------------------------------------------------------------------------------------
#                             RETURN THE OS PROJECT CODE NAME
# --------------------------------------------------------------------------------------------------
def get_oscodename() :
    ccode, cstdout, cstderr = oscommand(lsb_release + " -sc")
    oscodename=cstdout.upper()
    if get_ostype() == "AIX" : oscodename="IBM AIX"
    return oscodename

        

# --------------------------------------------------------------------------------------------------
#                THIS FUNCTION DETERMINE THE OS (DISTRIBUTION) VERSION NUMBER 
# --------------------------------------------------------------------------------------------------
def get_osversion() :
    osversion="0.0"                                               # Default Value
    if get_ostype() == "LINUX" :
        ccode, cstdout, cstderr = oscommand(lsb_release + " -sr")
        osversion=cstdout
    if get_ostype() == "AIX" :
        ccode, cstdout, cstderr = oscommand("uname -v")
        maj_ver=cstdout
        ccode, cstdout, cstderr = oscommand("uname -r")
        min_ver=cstdout
        osversion="%s.%s" % (maj.version,min.version)
    return osversion


# --------------------------------------------------------------------------------------------------
#                            RETURN THE OS (DISTRIBUTION) MAJOR VERSION
# --------------------------------------------------------------------------------------------------
def get_osmajorversion() :
    if get_ostype() == "LINUX" :
        ccode, cstdout, cstderr = oscommand(lsb_release + " -sr")
        osversion=cstdout
        osmajorversion=osversion.split('.')[0]
    if get_ostype() == "AIX" :
        ccode, cstdout, cstderr = oscommand("uname -v")
        osmajorversion=cstdout
    return osmajorversion

    
# --------------------------------------------------------------------------------------------------
#            SEND AN EMAIL TO SYSADMIN DEFINE IN SADMIN.CFG WITH SUBJECT AND BODY RECEIVED
# --------------------------------------------------------------------------------------------------
def sendmail(wserver,wport,wuser,wpwd,wsub,wbody) :
    wfrom = cfg_user + "@" + cfg_server
    #pdb.set_trace() 

    try :
        smtpserver = smtplib.SMTP(wserver, wport)
        smtpserver.ehlo()
        smtpserver.starttls()
        smtpserver.ehlo()
        if debug > 4 :
            writelog ("Connect to %s:%s Successfully" % (wserver,wport))
        try:
            smtpserver.login (wuser, wpwd)
        except smtplib.SMTPException :
            writelog ("Authentication for %s Failed %s" % (wuser))
            smtpserver.close()
            return 1
        if debug > 4 :
            writelog ("Login Successfully using %s" % (wuser))
        header = "To: " + wuser + '\n' + 'From: ' + wfrom + '\n' + 'Subject: ' + wsub + '\n'
        msg = header + '\n' + wbody + '\n\n'
        try:
            smtpserver.sendmail(wfrom, wuser, msg)
        except smtplib.SMTPException:
            writelog ("Email could not be send")
            smtpserver.close()
            return 1
    except (smtplib.SMTPException, socket.error, socket.gaierror, socket.herror), e:
        writelog ("Connection to %s %s Failed" % (wserver,wport))
        writelog ("%s" % e)
        return 1
    if debug > 4 :
       writelog ("Mail was sent successfully")
    smtpserver.close()
    return 0 
    
    


# --------------------------------------------------------------------------------------------------
#                TRIM THE FILE RECEIVED AS FIRST PARAMETER (MAX LINES IN LOG AS 2ND PARAMATER)
# --------------------------------------------------------------------------------------------------
def trimfile(wfile, maxline=500) :
    #writelog ("Trimming %s to %s lines." %  (wfile, str(maxline)))
    tmpfile = "%s/%s.%s" % (tmp_dir,inst,datetime.datetime.now().strftime("%y%m%d_%H%M%S"))
    
    cmd = "tail -%s %s > %s" % (maxline, wfile, tmpfile)
    ccode, cstdout, cstderr = oscommand(cmd)
    if not ccode == 0 :
        writelog ("Error occured with command %s" % (cmd))
        writelog ("Command stdout : %s" % (cstdout))
        writelog ("Command stderr : %s" % (cstderr))
        return 1
    
    cmd = "rm -f %s" % (wfile)
    ccode, cstdout, cstderr = oscommand(cmd)
    if not ccode == 0 :
        writelog ("Error occured with command %s" % (cmd))
        writelog ("Command stdout : %s" % (cstdout))
        writelog ("Command stderr : %s" % (cstderr))
        return 1
    
    cmd = "mv %s %s"% (tmpfile, wfile)
    ccode, cstdout, cstderr = oscommand(cmd)
    if not ccode == 0 :
        writelog ("Error occured with command %s" % (cmd))
        writelog ("Command stdout : %s" % (cstdout))
        writelog ("Command stderr : %s" % (cstderr))
        return 1
    
    cmd = "chmod 664 %s" % (wfile)
    ccode, cstdout, cstderr = oscommand(cmd)
    if not ccode == 0 :
        writelog ("Error occured with command %s" % (cmd))
        writelog ("Command stdout : %s" % (cstdout))
        writelog ("Command stderr : %s" % (cstderr))
        return 1
    return 0


# --------------------------------------------------------------------------------------------------
#        THIS FUNCTION VERIFY IF THE COMMAND RECEIVED IN PARAMETER IS AVAILABLE ON THE SERVER 
# --------------------------------------------------------------------------------------------------
#
def check_command_availibility(cmd) :
    global FH_LOG_FILE

    ccode, cstdout, cstderr = oscommand("which " + cmd)                 # Try to Locate Command
    if ccode is not 0 :                                                 # Command was not Found
       writelog ("Warning : Command '%s' could not be found" % (cmd))  # Displat Warning for User
       writelog ("   This program is used by the SADMIN tools")        # Command is needed by SADM
       writelog ("   Please install it and re-run this script")        # May want to install it
       cmd_path=""                                                      # Cmd Path Null when Not fnd
    else :                                                              # If command Path is Found
        cmd_path = cstdout                                              # Save command Path
    if debug > 2 :                                                      # Prt Cmd Location if debug
       if cmd_path != "" :                                              # If Cmd was Found
          writelog ("Command '%s' located at %s" % (cmd,cmd_path))     # Print Cmd Location
       else :                                                           # If Cmd was not Found
          writelog ("Command '%s' could not be located" % (cmd))       # Cmd Not Found to User 
    return (cmd_path)                                                   # Return Cmd Path




# --------------------------------------------------------------------------------------------------
# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
#
def check_requirements():
    global FH_LOG_FILE, which, lsb_release, dmidecode, uname, fdisk, mail
    
    if debug > 2 :                                                      # If Debug Run Level 7
        writelog (" ")                                                 # Space Line in the LOG
        writelog (dash_line)                                           # 80 = Lines 
        writelog ("Checking Libraries Requirements")                   # Inform user in Debug
        writelog (dash_line)                                           # 80 = Lines 
    requisites_status=True                                              # Default Requisite met
    
    # Get the location of the which command
    if debug > 2 : writelog ("Is 'which' command available ...")       # Command Available ?
    ccode, cstdout, cstderr = oscommand("which which")
    if ccode is not 0 :
       writelog ("Error : The command 'which' could not be found")
       writelog ("        This program is often used by the SADMIN tools")
       writelog ("        Please install it and re-run this script")
       writelog ("        To install it, use the following command depending on your distro")
       writelog ("        Use 'yum install which' or 'apt-get install debianutils'")
       writelog ("Script Aborted")
       sys.exit(1)
    which = cstdout
    if debug > 2 :
       if which != "" :
          writelog ("Command 'which' located at %s" % which)           # Print Cmd Location
       else :
          writelog ("Command 'which' could not be located ")           # Cmd Not Found 
          requisites_status=False
 
    
    # Get the location of the lsb_release command
    lsb_release = check_command_availibility('lsb_release')             # location of lsb_release
    if lsb_release == "" :
       writelog ("CRITICAL: The 'lsb_release' is needed and is not present")
       writelog ("Please correct the situation and re-execute this script")
       requisites_status=False
 
    
    uname = check_command_availibility('uname')                         # location of uname 
    if uname == "" :
       writelog ("CRITICAL: The 'uname' is needed and is not present")
       writelog ("Please correct the situation and re-execute this script")
       requisites_status=False
    
    fdisk = check_command_availibility('fdisk')                         # location of fdisk 
    mail = check_command_availibility('mail')                           # location of mail
    dmidecode = check_command_availibility('dmidecode')                 # location of dmidecode   
    return requisites_status
            
 
#===================================================================================================
#                                          Initial Setup 
#===================================================================================================
def start () :
    global FH_LOG_FILE, start_time, start_epoch
    
    # Make sure all SADM Directories structure exist
    if not os.path.exists(cfg_dir)      : os.mkdir(cfg_dir,2775)        # Create Configuration Dir.
    if not os.path.exists(tmp_dir)      : os.mkdir(tmp_dir,1777)        # Create SADM Temp Dir.
    if not os.path.exists(dat_dir)      : os.mkdir(dat_dir,2775)        # Create SADM Data Dir.
    if not os.path.exists(bin_dir)      : os.mkdir(bin_dir,2775)        # Create SADM Bin Dir.
    if not os.path.exists(lib_dir)      : os.mkdir(lib_dir,2775)        # Create SADM Lib Dir.
    if not os.path.exists(sys_dir)      : os.mkdir(sys_dir,2775)        # Create SADM Sys Dir.
    if not os.path.exists(www_dir)      : os.mkdir(www_dir,2775)        # Create SADM WWW Dir.
    if not os.path.exists(www_html_dir) : os.mkdir(www_html_dir,2775)   # Create SADM HTML Dir.
    if not os.path.exists(www_dat_dir)  : os.mkdir(www_dat_dir,2775)    # Create Web  DAT  Dir.
    if not os.path.exists(nmon_dir)     : os.mkdir(nmon_dir,2775)       # Create SADM nmon Dir.
    if not os.path.exists(dr_dir)       : os.mkdir(dr_dir,2775)         # Create SADM DR Dir.
    if not os.path.exists(dr_dir)       : os.mkdir(dr_dir,2775)         # Create SADM DR Dir.
    if not os.path.exists(sar_dir)      : os.mkdir(sar_dir,2775)        # Create SADM System Act Dir
    if not os.path.exists(rch_dir)      : os.mkdir(rch_dir,2775)        # Create SADM RCH Dir.

    try:                                                                # Try to Open/Create Log
        FH_LOG_FILE=open(log_file,'a')                                  # Open Log in append  mode
    except IOError as e:                                                # If Can't Create or open
        print ("Error open file %s \r\n" % log_file)                    # Print Log FileName
        print ("Error Number : {0}\r\n.format(e.errno)")                # Print Error Number    
        print ("Error Text   : {0}\r\n.format(e.strerror)")             # Print Error Message
        sys.exit(1)                                                     # Exit with Error
        
    # Write SADM Header to Script Log
    writelog (dash_line)                                               # 80 = Lines 
    wmess = "Starting %s - Version.%s on %s" % (pn,ver,hostname)        # Build Log Starting Line
    writelog (wmess)                                                   # Write Start line to Log
    wmess = "%s %s %s %s" % (get_ostype(),get_osname(),get_osversion(),get_oscodename())
    writelog (wmess)                                                   # Write OS Info to Log Head
    writelog (dash_line)                                               # 80 = Lines 
    writelog (" ")                                                     # Space Line in the LOG

    # If the PID file already exist - Script is already Running
    if os.path.exists(pid_file) and multiple_exec == "N" :              # PID Exist & No MultiRun
       writelog ("Script %s is already runnin" % pn)                   # Same script is running
       writelog ("PID File %s exist." % pid_file)                      # Display PID File Location
       writelog ("Will not run a second copy of this script")          # Advise the user
       writelog ("Script Aborted")                                     # Script Aborted
       sys.exit(1)                                                      # Exit with Error

    # Check SADM Library Requirements
    check_requirements()
    
    # Load Configuration File
    load_config_file()
        
    # Record Date & Time the script is starting in the RCH File
    i = datetime.datetime.now()                                         # Get Current Time
    start_time=i.strftime('%Y.%m.%d %H:%M:%S')                          # Save Start Date & Time
    start_epoch = int(time.time())                                      # StartTime in Epoch Time
    try:
        FH_RCH_FILE=open(rch_file,'a')                                  # Open RC Log in append mode
    except IOError as e:                                                # If Can't Create or open
        print ("Error open file %s \r\n" % rch_file)                    # Print Log FileName
        print ("Error Number : {0}\r\n.format(e.errno)")                # Print Error Number    
        print ("Error Text   : {0}\r\n.format(e.strerror)")             # Print Error Message
        sys.exit(1)     
    rch_line="%s %s %s %s %s" % (hostname,start_time,".......... ........ ........",inst,"2")
    FH_RCH_FILE.write ("%s\n" % (rch_line))                             # Write Line to RCH Log
    FH_RCH_FILE.close                                                   # Close RCH File
    
    return 0

        

    

#===================================================================================================
#                            Things to do before closing the program
#===================================================================================================
def stop(return_code):
    global FH_LOG_FILE, start_time, start_epoch, cfg_mail_type, cfg_mail_addr

    exit_code = return_code                                             # Save Param.Recv Code
    if exit_code is not 0 :                                             # If Return code is not 0
        exit_code=1                                                     # Making Sure code is 1 or 0
 
    # Write the Script Exit code of the script to the log
    writelog (" ")                                                     # Space Line in the LOG
    writelog (dash_line)                                               # 80 = Lines 
    writelog ("Script return code is " + str(exit_code))               # Script ExitCode to Log
    #time.sleep(1)                                                       # Sleep 1 seconds

    
    # Calculate the execution time, format it and write it to the log
    end_epoch = int(time.time())                                        # Save End Time in Epoch Time
    elapse_seconds = end_epoch - start_epoch                            # Calc. Total Seconds Elapse
    hours = elapse_seconds//3600                                        # Calc. Nb. Hours
    elapse_seconds = elapse_seconds - 3600*hours                        # Subs. Hrs*3600 from elapse
    minutes = elapse_seconds//60                                        # Cal. Nb. Minutes
    seconds = elapse_seconds - 60*minutes                               # Subs. Min*60 from elapse
    elapse_time="%02d:%02d:%02d" % (hours,minutes,seconds)
    writelog ("Script execution time is %02d:%02d:%02d" % (hours,minutes,seconds))

    
    # Update the [R]eturn [C]ode [H]istory File
    i = datetime.datetime.now()                                         # Get Current Stop Time
    stop_time=i.strftime('%Y.%m.%d %H:%M:%S')                           # Format Stop Date & Time
    FH_RCH_FILE=open(rch_file,'a')                                      # Open RCH Log - append mode
    rch_line="%s %s %s %s %s %s" % (hostname,start_time,stop_time,elapse_time,inst,exit_code)
    FH_RCH_FILE.write ("%s\n" % (rch_line))                             # Write Line to RCH Log
    FH_RCH_FILE.close                                                   # Close RCH File
    writelog ("Trimming %s to %s lines." %  (rch_file, str(cfg_max_rchline)))


    # Write in Log the email choice the user as requested (via the sadmin.cfg file)
    # 0 = No Mail Sent      1 = On Error Only   2 = On Success Only   3 = Always send email
    if cfg_mail_type == 0 :                                             # User don't want any email
        MailMess="No mail is requested when script end - No mail sent"  # Message User Email Choice
        
    if cfg_mail_type == 1 :                                             # Want Email on Error Only
        if exit_code != 0 :                                             # If Script Failed = Email
            MailMess="Mail requested if script fail - Mail sent"        # Message User Email Choice
        else :                                                          # Script Success = No Email
            MailMess="Mail requested if script fail - No mail sent"     # Message User Email Choice
            
    if cfg_mail_type == 2 :                                             # Email on Success Only
        if not exit_code == 0 :                                         # If script is a Success
            MailMess="Mail requested on Success only - Mail sent"       # Message User Email Choice
        else :                                                          # If Script not a Success
            MailMess="Mail requested on Success only - No mail sent"    # Message User Email Choice
            
    if cfg_mail_type == 3 :                                             # User always Want email 
        MailMess="Mail requested on Success or Error - Mail sent"       # Message User Email Choice
        
    if cfg_mail_type > 3 or cfg_mail_type < 0 :                         # User Email Choice Invalid
        MailMess="SADM_MAIL_TYPE is not set properly [0-3] Now at %s",(str(cfg_mail_type))

    if mail == "" :                                                     # If Mail Program not found
        MailMess="No Mail can be send - Until mail command is install"  # Message User Email Choice    
    writelog ("%s" % (MailMess))                                       # Write user choice to log
    
    
    # Inform UnixAdmin By Email based on his selected choice
    # Now that the user email choice is written to the log, let's send the email now, if needed
    # 0 = No Mail Sent      1 = On Error Only   2 = On Success Only   3 = Always send email
    wsubject=""                                                         # Clear Email Subject
    wsub_success="SADM : SUCCESS of %s on %s" % (pn,hostname)           # Format Success Subject
    wsub_error="SADM : ERROR of %s on %s" % (pn,hostname)               # Format Failed Subject
    
    if exit_code != 0 and (cfg_mail_type == 1 or cfg_mail_type == 3):   # If Error & User want email
        wsubject=wsub_error                                             # Build the Subject Line
           
    if cfg_mail_type == 2 and exit_code == 0 :                          # Success & User Want Email
        wsubject=wsub_success                                           # Format Subject Line

    if cfg_mail_type == 3 :                                             # USer Always want Email
        if exit_code == 0 :                                             # If Script is a Success
           wsubject=wsub_success                                        # Build the Subject Line
        else :                                                          # If Script Failed                                            
           wsubject=wsub_error                                          # Build the Subject Line

    if wsubject != "" :                                                 # subject = Email Needed
        cmd = "cat %s | %s -s '%s' %s" % (log_file,mail,wsubject,cfg_mail_addr) # Format Email Cmd
        ccode, cstdout, cstderr = oscommand("%s" % (cmd))               # Go send email 
        if ccode != 0 :                                                 # If Cmd Fail
           writelog ("ERROR : Problem sending email to %s" % (cfg_mail_addr)) # Advise USer 
    
          
    # Advise user the Log will be trimm
    writelog ("Trimming %s to %s lines." %  (log_file, str(cfg_max_logline)))
    
    # Write Script Log Footer
    now = time.strftime("%c")                                           # Get Current Date & Time
    writelog (now + " - End of " + pn)                                 # Write Final Footer to Log
    writelog (dash_line)                                               # 80 = Lines 
    writelog (" ")                                                     # Space Line in the LOG
    FH_LOG_FILE.close                                                   # Close the Log File

    # Trimming the Log 
    trimfile (log_file, cfg_max_logline)                                # Trim the Script Log 
    trimfile (rch_file, cfg_max_rchline)                                # Trim the Script RCH Log 

    # Delete Temproray files used
    silentremove (pid_file)                                             # Delete PID File
    silentremove (tmp_file1)                                            # Delete Temp file 1
    silentremove (tmp_file2)                                            # Delete Temp file 2
    silentremove (tmp_file3)                                            # Delete Temp file 3
    return exit_code

    
    
        
# --------------------------------------------------------------------------------------------------
#            LOAD SADMIN CONFIGURATION FILE AND SET GLOBAL VARIABLES ACCORDINGLY
# --------------------------------------------------------------------------------------------------
#
def load_config_file():
    global cfg_mail_type, cfg_mail_addr, cfg_cie_name, cfg_user , cfg_server
    global cfg_group, cfg_max_logline, cfg_max_rchline
    global cfg_nmon_keepdays, cfg_sar_keepdays, cfg_rch_keepdays, cfg_log_keepdays
           
    # Debug Level Higher than 4 , inform that entering Load configuration file
    if debug > 4 :                                                      # If Debug Run Level 4
        writelog (" ")                                                 # Space Line in the LOG
        writelog (dash_line)                                           # 80 = Lines 
        writelog ("Load Configuration file %s" % (cfg_file))           # Inform user in Debug
        writelog (dash_line)                                           # 80 = Lines 

    # Configuration file MUST be present - If .sadm_config exist, then create sadm_config from it.
    if  not os.path.exists(cfg_file) :
        if not os.path.exists(cfg_hidden) :
           writelog ("****************************************************************")
           writelog ("SADMIN Configuration file cannot be found (%s)" % (cfg_file))
           writelog ("Even the config template file cannot be found (%s)" % (cfg_hidden))
           writelog ("Copy both files from another system to this server")
           writelog ("Or restore the files from a backup & review the file content.")
           writelog ("****************************************************************")
        else :
           writelog ("****************************************************************")
           writelog ("The configuration file %s doesn't exist." % (cfg_file))
           writelog ("Will continue using template configuration file %s" & (cfg_hidden))
           writelog ("Please review the configuration file.")
           writelog ("cp %s %s " % (cfg_hidden, cfg_file))             # Install Default cfg  file
           cmd = "cp %s %s"% "cp %s %s " % (cfg_hidden, cfg_file)       # Install Default cfg  file
           ccode, cstdout, cstderr = oscommand(cmd)
           if not ccode == 0 :
               writelog ("Could not copy the backup file file")
           writelog ("****************************************************************")

                   
    # Set Minimum Default Values - in case we could not load the SADMIN Config File
    mail_addr         = "root@localhost"                                # Default email address
    cie_name          = "Your Company Name"                             # Company Name
    mail_type         = 3                                               # Send Email after each run
    user              = "sadmin"                                        # sadmin user account
    group             = "sadmin"                                        # sadmin group account
    max_logline       = 5000                                            # Max Line in each *.log
    max_rchline       = 100                                             # Max Line in each *.rch
    nmon_keepdays     = 40                                              # Days to keep old *.nmon
    sar_keepdays      = 40                                              # Days ro keep old *.sar
    rch_keepdays      = 40                                              # Days to keep old *.rch
    log_keepdays      = 40                                              # Days ro keep old *.log
    ccode, cstdout, cstderr = oscommand("host sadmin | cut -d' ' -f1")  # Get FQN of admin server
    if ccode is not 0 :                                                 # If sadmin not resolved
       writelog ("Error executing 'host sadmin | cut -d' ' -f1")       # Advise User of error
       writelog ("Assuming 'sadmin' as sadmin server")                 # Will use sadmin no FQN
       sadm_server        = "sadmin"                                    # Default sadmin hostname
    else :                                                              # If sadmin was resolvec
       sadm_server        = cstdout                                     # Used FQN obtained
    
    
    # Open Configuration file 
    try:
        FH_CFG_FILE = open(cfg_file,'r')                                # Open Config File
    except IOError as e:                                                # If Can't Create or open
        print ("Error open file %s \r\n" % cfg_file)                    # Print Log FileName
        print ("Error Number : {0}\r\n.format(e.errno)")                # Print Error Number    
        print ("Error Text   : {0}\r\n.format(e.strerror)")             # Print Error Message
        sys.exit(1) 

    # Read Configuration file and Save Options values 
    for cfg_line in FH_CFG_FILE :                                       # Loop until on all servers
        wline        = cfg_line.strip()                                 # Strip CR/LF & Trailing spaces
        if (wline[0:1] == '#' or len(wline) == 0) :                     # If comment or blank line
            continue                                                    # Go read the next line
        split_line   = wline.split('=')                                 # Split based on equal sign 
        CFG_NAME   = split_line[0].upper().strip()                      # Param Name Uppercase Trim
        CFG_VALUE  = str(split_line[1]).strip()                         # Get Param Value Trimmed
        
        # Save Each Parameter found in Sadmin Configuration File
        if CFG_NAME ==  "SADM_MAIL_ADDR"      : cfg_mail_addr      = CFG_VALUE
        if CFG_NAME ==  "SADM_CIE_NAME"       : cfg_cie_name       = CFG_VALUE
        if CFG_NAME ==  "SADM_MAIL_TYPE"      : cfg_mail_type      = int(CFG_VALUE)
        if CFG_NAME ==  "SADM_SERVER"         : cfg_server         = CFG_VALUE
        if CFG_NAME ==  "SADM_USER"           : cfg_user           = CFG_VALUE
        if CFG_NAME ==  "SADM_GROUP"          : cfg_group          = CFG_VALUE
        if CFG_NAME ==  "SADM_MAX_LOGLINE"    : cfg_max_logline    = int(CFG_VALUE)
        if CFG_NAME ==  "SADM_MAX_RCHLINE"    : cfg_max_rchline    = int(CFG_VALUE)
        if CFG_NAME ==  "SADM_NMON_KEEPDAYS"  : cfg_nmon_keepdays  = int(CFG_VALUE)
        if CFG_NAME ==  "SADM_SAR_KEEPDAYS"   : cfg_sar_keepdays   = int(CFG_VALUE)
        if CFG_NAME ==  "SADM_RCH_KEEPDAYS"   : cfg_rch_keepdays   = int(CFG_VALUE)
        if CFG_NAME ==  "SADM_LOG_KEEPDAYS"   : cfg_log_keepdays   = int(CFG_VALUE)
        
    FH_CFG_FILE.close()                                                 # Close Config File
    return        


    
#===================================================================================================
#                                       Log File Class
#def main():
#    g.sadmlog = sadmlib.log_tools()                                     # Instantiate SADM Log Tools
#    g.sadmlog.setlogtype(g.logtype)                                     # Set the Log Type

#===================================================================================================
#class log_tools :
#    total_write = 0                                                     # For Info - Line written
#
#    def __init__(self) :
#        if not os.path.exists(log_dir) :                              # If the log dir. not exist
#            os.mkdir(log_dir,0775)                                    # Create SADM Log Directory
#        self.log_fh=open(log,'a')                                          # Open Log in append  mode
#
#    def __str__ (self) : 
#        return ('The Log type is set to (0)'.format(self.logtype))
#
#    def setlogtype(self,wlogtype) :
#        self.logtype = wlogtype
#        
#    def getlogtype(self) :
#        return (self.logtype)
#        
#    def write(self,sline) :
#        now = datetime.datetime.now()
#        logLine = now.strftime("%Y.%m.%d %H:%M:%S") + " - %s" % (sline)
#        if logtype.upper() == "L" :  self.log_fh.write ("%s\n" % (logLine))
#        if logtype.upper() == "S" :  print ("%s" % logLine)
#        if logtype.upper() == "B" :  
#            self.log_fh.write ("%s\n" % (logLine))
#            print ("%s" % logLine) 
#        log_tools.total_write += 1
#        
#    def totalWritten() :
#        return '(0) lines were written in log'.format(log_tools.total_write)
#     
#    def close_log(self) :
#        self.log_fh.close()                                                  # Close Log File
#        
        
               
           
#===================================================================================================
# For Debugging Purpose - Display all Important Environment Variables used across SADM Libraries
#===================================================================================================
def display_env () :
    writelog(" ")                                                      # Space Line in the LOG
    writelog(dash_line)                                                # 80 = Lines 
    writelog("Display Important Environment Variables")                # Introduce Display Below
    writelog(dash_line)                                                # 80 = Lines 
    writelog("ver                 = " + ver)                           # Program Version
    writelog("pn                  = " + pn)                            # Program name
    writelog("inst                = " + inst)                          # Program name without Ext.
    writelog("hostname            = " + hostname)                      # Program name without Ext.
    writelog("username            = " + username)                      # Current User Name
    writelog("tpid                = " + tpid)                          # Get Current Process ID.
    writelog("multiple_exec       = " + multiple_exec)                 # Can Script run Multiple
    writelog("debug               = " + str(debug))                    # Debug Level
    writelog("get_ostype()        = " + get_ostype())                  # OS Type Linux or Aix
    writelog("get_osname()        = " + get_osname())                  # Distribution of OS
    writelog("get_osversion()     = " + get_osversion())               # Distribution Version
    writelog("get_osmajorversion()= " + get_osmajorversion())          # Distribution Major Ver#
    writelog("get_oscodename()    = " + get_oscodename())              # Distribution Code Name
    writelog("logtype             = " + logtype)                       # 4Logger S=Scr L=Log B=Both
    writelog("base_dir            = " + base_dir)                      # Base Dir. where appl. is
    writelog("tmp_dir             = " + tmp_dir)                       # SADM Temp. Directory
    writelog("cfg_dir             = " + cfg_dir)                       # SADM Config Directory
    writelog("lib_dir             = " + lib_dir)                       # SADM Library Directory
    writelog("bin_dir             = " + bin_dir)                       # SADM Scripts Directory
    writelog("log_dir             = " + log_dir)                       # SADM Log Directory
    writelog("www_dir             = " + www_dir)                       # SADM WebSite Dir Structure
    writelog("pkg_dir             = " + pkg_dir)                       # SADM Package Directory
    writelog("sys_dir             = " + sys_dir)                       # SADM System Scripts Dir.
    writelog("dat_dir             = " + dat_dir)                       # SADM Data Directory
    writelog("nmon_dir            = " + nmon_dir)                      # SADM nmon File Directory
    writelog("rch_dir             = " + rch_dir)                       # SADM Result Code Dir.
    writelog("dr_dir              = " + dr_dir)                        # SADM Disaster Recovery Dir
    writelog("sar_dir             = " + sar_dir)                       # SADM System Activity Rep.
    writelog("www_dat_dir         = " + www_dat_dir)                   # SADM Web Site Data Dir
    writelog("www_html_dir        = " + www_html_dir)                  # SADM Web Site Dir
    writelog("log_file            = " + log_file)                      # SADM Log File
    writelog("rch_file            = " + rch_file)                      # SADM RCH File
    writelog("cfg_file            = " + cfg_file)                      # SADM Config File
    writelog("pid_file            = " + pid_file)                      # SADM PID FileName
    writelog("tmp_file1           = " + tmp_file1)                     # SADM Tmp File 1
    writelog("tmp_file2           = " + tmp_file2)                     # SADM Tmp File 2
    writelog("tmp_file3           = " + tmp_file3)                     # SADM Tmp File 3
    writelog("which               = " + which)                         # Location of which
    writelog("lsb_release         = " + lsb_release)                   # Location of lsb_release
    writelog("dmidecode           = " + dmidecode)                     # Location of dmidecode
    writelog("fdisk               = " + fdisk)                         # Location of fdisk
    writelog("uname               = " + uname)                         # Location of uname

    writelog(" ")                                                      # Space Line in the LOG
    writelog(dash_line)                                                # 80 = Lines 
    writelog("Global variables setting after reading the SADM Cconfigation file")
    writelog(dash_line)                                                # 80 = Lines 
    writelog("cfg_mail_addr       = ..." + cfg_mail_addr + "...")
    writelog("cfg_cie_name        = ..." + cfg_cie_name + "...")
    writelog("cfg_mail_type       = ..." + str(cfg_mail_type) + "...")
    writelog("cfg_server          = ..." + cfg_server + "...")
    writelog("cfg_user            = ..." + cfg_user + "...")
    writelog("cfg_group           = ..." + cfg_group + "...")
    writelog("cfg_max_logline     = ..." + str(cfg_max_logline) + "...")
    writelog("cfg_max_rchline     = ..." + str(cfg_max_rchline) + "...")
    writelog("cfg_nmon_keepdays   = ..." + str(cfg_nmon_keepdays) + "...")
    writelog("cfg_sar_keepdays    = ..." + str(cfg_sar_keepdays) + "...")
    writelog("cfg_rch_keepdays    = ..." + str(cfg_rch_keepdays) + "...")
    writelog("cfg_log_keepdays    = ..." + str(cfg_log_keepdays) + "...")
    return 0

