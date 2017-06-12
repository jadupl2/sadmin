#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_lib_std.py
#   Synopsis:   This is the Standard SADM Python Library 
#
# V1.1  Jacques Duplessis - June 2017 
#       Added Flush before trimming file
#===================================================================================================
import os, errno, time, sys, pdb, socket, datetime, getpass, subprocess, smtplib, pwd, grp
import glob, fnmatch, psycopg2
from subprocess import Popen, PIPE
#pdb.set_trace() 


#===================================================================================================
#                 Global Variables Shared among all SADM Libraries and Scripts
#===================================================================================================
ver                = "1.1"                                              # Default Program Version
multiple_exec      = "N"                                                # Default Run multiple copy
debug              = 0                                                  # Default Debug Level (0-9)
exit_code          = 0                                                  # Script Error Return Code
log_append         = "Y"                                                # Append to Existing Log ?
log_type           = "B"                                                # 4Logger S=Scr L=Log B=Both

pn                 = os.path.basename(sys.argv[0])                      # Program name
inst               = os.path.basename(sys.argv[0]).split('.')[0]        # Program name without Ext.
tpid               = str(os.getpid())                                   # Get Current Process ID.
hostname           = socket.gethostname().split('.')[0]                 # Get current hostname
dash          = "=" * 80                                                # Line of 80 dash
ten_dash           = "=" * 10                                           # Line of 10 dash
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
pg_dir             = os.path.join(base_dir,'pgsql')                     # SADM PostGres Database Dir
pkg_dir            = os.path.join(base_dir,'pkg')                       # SADM Package Directory
sys_dir            = os.path.join(base_dir,'sys')                       # SADM System Scripts Dir.
dat_dir            = os.path.join(base_dir,'dat')                       # SADM Data Directory
nmon_dir           = os.path.join(dat_dir,'nmon')                       # SADM nmon File Directory
rch_dir            = os.path.join(dat_dir,'rch')                        # SADM Result Code Dir.
dr_dir             = os.path.join(dat_dir,'dr')                         # SADM Disaster Recovery Dir
sar_dir            = os.path.join(dat_dir,'sar')                        # SADM System Activity Rep.
net_dir            = os.path.join(dat_dir,'net')                        # SADM Network/Subnet Dir 
rpt_dir            = os.path.join(dat_dir,'rpt')                        # SADM Sysmon Report Dir.

# SADM Web Site Directories Structure
www_dir            = os.path.join(base_dir,'www')                       # SADM WebSite Dir Structure
www_dat_dir        = os.path.join(www_dir,'dat')                        # SADM Web Site Data Dir
www_cfg_dir        = os.path.join(www_dir,'cfg')                        # SADM Web Site CFG Dir
www_html_dir       = os.path.join(www_dir,'html')                       # SADM Web Site html Dir
www_lib_dir        = os.path.join(www_dir,'lib')                        # SADM Web Site Lib Dir
www_net_dir        = www_dat_dir + '/' + hostname + '/net'              # SADM Web Data Network Dir
www_rch_dir        = www_dat_dir + '/' + hostname + '/rch'              # SADM Web Data RCH Dir
www_sar_dir        = www_dat_dir + '/' + hostname + '/sar'              # SADM Web Data SAR Dir
www_dr_dir         = www_dat_dir + '/' + hostname + '/dr'               # SADM Web Disaster Recovery
www_nmon_dir       = www_dat_dir + '/' + hostname + '/nmon'             # SADM Web NMON Directory
www_tmp_dir        = www_dat_dir + '/' + hostname + '/tmp'              # SADM Web tmp Directory
www_log_dir        = www_dat_dir + '/' + hostname + '/log'              # SADM Web log Directory


# SADM Files Definition
log_file           = log_dir + '/' + hostname + '_' + inst + '.log'     # Log Filename
rch_file           = rch_dir + '/' + hostname + '_' + inst + '.rch'     # RCH Filename
cfg_file           = cfg_dir + '/sadmin.cfg'                            # Configuration Filename
cfg_hidden         = cfg_dir + '/.sadmin.cfg'                           # Hidden Config Filename
crontab_work       = www_cfg_dir + '/.crontab.txt'                      # Work crontab
crontab_file       = '/etc/cron.d/sadmin'                               # Final crontab
rel_file           = cfg_dir + '/.release'                              # SADMIN Release Version No.
pid_file           = "%s/%s.pid" % (tmp_dir, inst)                      # Process ID File
tmp_file_prefix    = tmp_dir + '/' + hostname + '_' + inst              # TMP Prefix
tmp_file1          = "%s_1.%s" % (tmp_file_prefix,tpid)                 # Temp1 Filename
tmp_file2          = "%s_2.%s" % (tmp_file_prefix,tpid)                 # Temp2 Filename
tmp_file3          = "%s_3.%s" % (tmp_file_prefix,tpid)                 # Temp3 Filename

# SADM Configuration file (sadmin.cfg) content loaded from configuration file (Can be overridden)
cfg_mail_type      = 1                                                  # 0=No 1=Err 2=Succes 3=All
cfg_mail_addr      = ""                                                 # Default is in sadmin.cfg
cfg_cie_name       = ""                                                 # Company Name
cfg_user           = ""                                                 # sadmin user account
cfg_group          = ""                                                 # sadmin group account
cfg_www_user       = ""                                                 # sadmin/www user account
cfg_www_group      = ""                                                 # sadmin/www group owner
cfg_server         = ""                                                 # sadmin FQN Server
cfg_domain         = ""                                                 # sadmin Default Domain
cfg_max_logline    = 5000                                               # Max Nb. Lines in LOG )
cfg_max_rchline    = 100                                                # Max Nb. Lines in RCH file
cfg_nmon_keepdays  = 60                                                 # Days to keep old *.nmon
cfg_sar_keepdays   = 60                                                 # Days to keep old *.sar
cfg_rch_keepdays   = 60                                                 # Days to keep old *.rch
cfg_log_keepdays   = 60                                                 # Days to keep old *.log
cfg_pguser         = ""                                                 # PostGres Database user
cfg_pggroup        = ""                                                 # PostGres Database Group
cfg_pgdb           = ""                                                 # PostGres Database Name
cfg_pgschema       = ""                                                 # PostGres Database Schema
cfg_pghost         = ""                                                 # PostGres Database Host
cfg_pgport         = 5432                                               # PostGres Database Port
cfg_rw_pguser      = ""                                                 # PostGres Read Write User
cfg_rw_pgpwd       = ""                                                 # PostGres Read Write Pwd
cfg_ro_pguser      = ""                                                 # PostGres Read Only User
cfg_ro_pgpwd       = ""                                                 # PostGres Read Only Pwd
cfg_ssh_port       = 22                                                 # SSH Port used in Farm


# SADM Path to various commands used by SADM Tools
lsb_release        = ""                                                 # Command lsb_release Path
which              = ""                                                 # whic1h Path - Required
dmidecode          = ""                                                 # Command dmidecode Path
bc                 = ""                                                 # Command bc (Do Some Math)
fdisk              = ""                                                 # fdisk (Read Disk Capacity)
perl               = ""                                                 # perl Path (for epoch time)
uname              = ""                                                 # uname command path
mail               = ""                                                 # mail command path




#===================================================================================================
#                           Open Connection to Database SADMIN
#===================================================================================================
#
def open_sadmin_database():
    try:
        if debug > 6 : writelog ("Connecting to '%s' database" % cfg_pgdb)
        conn = psycopg2.connect( database=cfg_pgdb, user=cfg_rw_pguser, \
            password=cfg_rw_pgpwd, host=cfg_pghost, port=cfg_pgport)       
        if debug > 6 : writelog ("Setting Connection Cursor to %s:%s" % (cfg_pghost,cfg_pgport))
        cur = conn.cursor()
    except psycopg2.Error as e:                                         # in case of error
        writelog ("Error: Can't connect to '%s' database with user %s" % (cfg_pgdb,cfg_rw_pguser))
        writelog ("%s" % e)
        sys.exit(1)
    return (conn,cur)

    
    
#===================================================================================================
#                           Close Connection to Database SADMIN 
#===================================================================================================
#
def close_sadmin_database(wconn,wcur):
    try:
        if debug > 6 : writelog ("Closing Connection to '%s' Database" % cfg_pgdb)
        wcur.close()
        wconn.close()
    except psycopg2.Error as e:                                         # in case of error
        writelog ("Error: Can't Close Connection to '%s' database" & cfg_pgdb)
        writelog ("%s" % e)
        return (1)
    return (0)



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
    if log_type.upper() == "L" :  FH_LOG_FILE.write ("%s\n" % (logLine))
    if log_type.upper() == "S" :  print ("%s" % logLine)
    if log_type.upper() == "B" :  
       FH_LOG_FILE.write ("%s\n" % (logLine))
       print ("%s" % logLine) 


# --------------------------------------------------------------------------------------------------
#                                 RETURN SADMIN RELEASE VERSION NUMBER
# --------------------------------------------------------------------------------------------------
def get_release() :
    if os.path.exists(rel_file):
        wcommand = "head -1 %s" % (rel_file)
        ccode, cstdout, cstderr = oscommand("%s" % (wcommand))           # Execute O/S CMD 
        wrelease=cstdout
    else:
        wrelease="00.00"
    return wrelease

            

# --------------------------------------------------------------------------------------------------
#                                 RETURN THE HOSTNAME (SHORT)
# --------------------------------------------------------------------------------------------------
def get_hostname():
    if get_ostype() == "LINUX" :                                        # Under Linux
       ccode, cstdout, cstderr = oscommand("hostname -s")               # Execute O/S CMD 
    if get_ostype() == "AIX" :                                          # Under AIX
       ccode, cstdout, cstderr = oscommand("hostname")                  # Execute O/S CMD 
    whostname=cstdout.upper()
    return whostname


# --------------------------------------------------------------------------------------------------
#                                 RETURN THE DOMAINNAME 
# --------------------------------------------------------------------------------------------------
def get_domainname():
    whostname = get_hostname()
    if get_ostype() == "LINUX" :                                        # Under Linux
       ccode, cstdout, cstderr = oscommand("host $whostname) |head -1 |awk '{ print $1 }' |cut -d. -f2-3")
    if get_ostype() == "AIX" :                                          # Under AIX
       ccode, cstdout, cstderr = oscommand("namerslv -s | grep domain | awk '{ print $2 }'")
    wdomainname=cstdout.upper()
    return wdomainname
            

# --------------------------------------------------------------------------------------------------
#                              RETURN THE IP OF THE CURRENT HOSTNAME
# --------------------------------------------------------------------------------------------------
def get_host_ip():
    whostname = get_hostname()
    wdomain = get_domainname()
    if get_ostype() == "LINUX" :                                        # Under Linux
       ccode, cstdout, cstderr = oscommand("host $whostname |awk '{ print $4 }' |head -1") 
    if get_ostype() == "AIX" :                                          # Under AIX
       ccode, cstdout, cstderr = oscommand("host $whostname.$wdomain |head -1 |awk '{ print $3 }'")
    whostip=cstdout.upper()
    return whostip


# --------------------------------------------------------------------------------------------------
#                     Return if running 32 or 64 Bits Kernel version
# --------------------------------------------------------------------------------------------------
def get_kernel_bitmode():
    if get_ostype() == "LINUX" :                                        # Under Linux
       ccode, cstdout, cstderr = oscommand("getconf LONG_BIT") 
    if get_ostype() == "AIX" :                                          # Under AIX
       ccode, cstdout, cstderr = oscommand("getconf KERNEL_BITMODE")
    wkbits=cstdout.upper()
    return wkbits




# --------------------------------------------------------------------------------------------------
#                                 RETURN KERNEL RUNNING VERSION
# --------------------------------------------------------------------------------------------------
def get_kernel_version():
    if get_ostype() == "LINUX" :                                        # Under Linux
       ccode, cstdout, cstderr = oscommand("uname -r | cut -d. -f1-3") 
    if get_ostype() == "AIX" :                                          # Under AIX
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
#          RETURN CPU SERIAL Number (For the Raspberry - need to be check on other server)
# --------------------------------------------------------------------------------------------------
def get_serial():
  # Extract serial from cpuinfo file
  cpuserial = "0000000000000000"
  try:
    f = open('/proc/cpuinfo','r')
    for line in f:
      if line[0:6]=='Serial':
        cpuserial = line[10:26]
    f.close()
  except:
    cpuserial = "ERROR000000000"

  return cpuserial


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
    
    if debug > 5 :                                                      # If Debug Run Level 7
        writelog (" ")                                                  # Space Line in the LOG
        writelog (dash)                                            # 80 = Lines 
        writelog ("Checking Libraries Requirements")                    # Inform user in Debug
        writelog (dash)                                            # 80 = Lines 
    requisites_status=True                                              # Default Requisite met
    
    # Get the location of the which command
    if debug > 2 : writelog ("Is 'which' command available ...")        # Command Available ?
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
    
    # First thing Make sure the log file is Open and Log Directory created
    try:                                                                # Try to Open/Create Log
        if not os.path.exists(log_dir)  : os.mkdir(log_dir,2775)        # Create SADM Log Dir.
        if log_append == "Y" :                                          # User Want to Append to Log
            FH_LOG_FILE=open(log_file,'a')                              # Open Log in append  mode
        else:                                                           # User Want Fresh New Log
            FH_LOG_FILE=open(log_file,'w')                              # Open Log in a new log
    except IOError as e:                                                # If Can't Create or open
        print ("Error open file %s \r\n" % log_file)                    # Print Log FileName
        print ("Error Number : {0}\r\n.format(e.errno)")                # Print Error Number    
        print ("Error Text   : {0}\r\n.format(e.strerror)")             # Print Error Message
        sys.exit(1)                                                     # Exit with Error

    # Second thing chack if requirement are met
    check_requirements()                                                # Check SADM Requirement Met
    
    # Make sure all SADM Directories structure exist
    if not os.path.exists(cfg_dir)      : os.mkdir(cfg_dir,0775)        # Create Configuration Dir.
    if not os.path.exists(tmp_dir)      : os.mkdir(tmp_dir,1777)        # Create SADM Temp Dir.
    if not os.path.exists(dat_dir)      : os.mkdir(dat_dir,0775)        # Create SADM Data Dir.
    if not os.path.exists(bin_dir)      : os.mkdir(bin_dir,0775)        # Create SADM Bin Dir.
    if not os.path.exists(log_dir)      : os.mkdir(log_dir,0775)        # Create SADM Log Dir.
    if not os.path.exists(lib_dir)      : os.mkdir(lib_dir,0775)        # Create SADM Lib Dir.
    if not os.path.exists(sys_dir)      : os.mkdir(sys_dir,0775)        # Create SADM Sys Dir.
    if not os.path.exists(nmon_dir)     : os.mkdir(nmon_dir,0775)       # Create SADM nmon Dir.
    if not os.path.exists(dr_dir)       : os.mkdir(dr_dir,0775)         # Create SADM DR Dir.
    if not os.path.exists(dr_dir)       : os.mkdir(dr_dir,0775)         # Create SADM DR Dir.
    if not os.path.exists(sar_dir)      : os.mkdir(sar_dir,0775)        # Create SADM System Act Dir
    if not os.path.exists(rch_dir)      : os.mkdir(rch_dir,0775)        # Create SADM RCH Dir.
    if not os.path.exists(net_dir)      : os.mkdir(net_dir,0775)        # Create SADM RCH Dir.
    if not os.path.exists(rpt_dir)      : os.mkdir(rpt_dir,0775)        # Create SADM RCH Dir.

    # These Directories are only created on the SADM Server (Data Base and Web Directories)
    if get_hostname() == cfg_server :
        if not os.path.exists(pg_dir)       : os.mkdir(pg_dir,0700)     # Create SADM Database Dir.
        if not os.path.exists(www_dat_net_dir) : os.mkdir(www_dat_net_dir,0775) # Web  Network  Dir.

        uid = pwd.getpwnam(cfg_user).pw_uid                             # Get UID User in sadmin.cfg 
        gid = grp.getgrnam(cfg_group).gr_gid                            # Get GID User in sadmin.cfg 

        uid = pwd.getpwnam(cfg_pguser).pw_uid                           # Get UID User in sadmin.cfg 
        gid = grp.getgrnam(cfg_pggroup).gr_gid                          # Get GID User in sadmin.cfg 
        os.chown(pg_dir, uid, gid)                                      # Change owner of rch file

        if not os.path.exists(www_dir)      : os.mkdir(www_dir,0775)    # Create SADM WWW Dir.
        if not os.path.exists(www_html_dir) : os.mkdir(www_html_dir,0775) # Create SADM HTML Dir.
        if not os.path.exists(www_dat_dir)  : os.mkdir(www_dat_dir,0775)  # Create Web  DAT  Dir.
        if not os.path.exists(www_lib_dir)  : os.mkdir(www_lib_dir,0775)  # Create Web  DAT  Dir.
        wuid = pwd.getpwnam(cfg_www_user).pw_uid                        # Get UID User of Wev User 
        wgid = grp.getgrnam(cfg_www_group).gr_gid                       # Get GID User of Web Group 
        os.chown(www_dir, wuid, wgid)                                   # Change owner of log file
        os.chown(www_dat_net_dir, wuid, wgid)                           # Change owner of Net Dir
        os.chown(www_html_dir, wuid, wgid)                              # Change owner of rch file
        os.chown(www_dat_dir, wuid, wgid)                               # Change owner of dat file
        os.chown(www_lib_dir, wuid, wgid)                               # Change owner of lib file
    
        
    # Write SADM Header to Script Log
    writelog (dash)                                               # 80 = Lines 
    wmess = "Starting %s - Version.%s on %s" % (pn,ver,hostname)        # Build Log Starting Line
    writelog (wmess)                                                   # Write Start line to Log
    wmess = "%s %s %s %s" % (get_ostype(),get_osname(),get_osversion(),get_oscodename())
    writelog (wmess)                                                   # Write OS Info to Log Head
    writelog (dash)                                               # 80 = Lines 
    writelog (" ")                                                     # Space Line in the LOG

    # If the PID file already exist - Script is already Running
    if os.path.exists(pid_file) and multiple_exec == "N" :              # PID Exist & No MultiRun
       writelog ("Script %s is already runnin" % pn)                   # Same script is running
       writelog ("PID File %s exist." % pid_file)                      # Display PID File Location
       writelog ("Will not run a second copy of this script")          # Advise the user
       writelog ("Script Aborted")                                     # Script Aborted
       sys.exit(1)                                                      # Exit with Error
    
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
    FH_RCH_FILE.close()                                                 # Close RCH File
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
    writelog (" ")                                                      # Space Line in the LOG
    writelog (dash)                                                     # 80 = Lines 
    writelog ("Script return code is " + str(exit_code))                # Script ExitCode to Log
    #time.sleep(1)                                                      # Sleep 1 seconds

    
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
    FH_RCH_FILE.close()                                                 # Close RCH File
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
    
          
    # Advise user the Log will be trimm
    writelog ("Trimming %s to %s lines." %  (log_file, str(cfg_max_logline)))
    
    # Write Script Log Footer
    now = time.strftime("%c")                                           # Get Current Date & Time
    writelog (now + " - End of " + pn)                                  # Write Final Footer to Log
    writelog (dash)                                                     # 80 = Lines 
    writelog (" ")                                                      # Space Line in the LOG

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
        time.sleep(1)                                                   # Sleep 1 seconds
        
        cmd = "cat %s | %s -s '%s' %s" % (log_file,mail,wsubject,cfg_mail_addr) # Format Email Cmd
        ccode, cstdout, cstderr = oscommand("%s" % (cmd))               # Go send email 
        if ccode != 0 :                                                 # If Cmd Fail
           writelog ("ERROR : Problem sending email to %s" % (cfg_mail_addr)) # Advise USer 
    
    FH_LOG_FILE.flush()                                                 # Got to do it - Missing end
    FH_LOG_FILE.close()                                                 # Close the Log File

    # Trimming the Log 
    trimfile (log_file, cfg_max_logline)                                # Trim the Script Log 
    trimfile (rch_file, cfg_max_rchline)                                # Trim the Script RCH Log 
    
    # Make sure the RCH File and the Script log belong to sadmin.cfg user/group
    uid = pwd.getpwnam(cfg_user).pw_uid                                 # Get UID User in sadmin.cfg 
    gid = grp.getgrnam(cfg_group).gr_gid                                # Get GID User in sadmin.cfg 
    os.chown(log_file, uid, gid)                                        # Change owner of log file
    os.chown(rch_file, uid, gid)                                        # Change owner of rch file
    os.chmod(log_file, 0644)                                            # Change Log File Permission
    os.chmod(rch_file, 0644)                                            # Change RCH File Permission
    
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
    global cfg_mail_type, cfg_mail_addr, cfg_cie_name, cfg_user , cfg_group, cfg_server, cfg_domain
    global cfg_max_logline, cfg_max_rchline, cfg_www_user, cfg_www_group
    global cfg_nmon_keepdays, cfg_sar_keepdays, cfg_rch_keepdays, cfg_log_keepdays
    global cfg_pguser, cfg_pggroup, cfg_pgdb, cfg_pgschema, cfg_pghost,  cfg_pgport
    global cfg_rw_pguser, cfg_rw_pgpwd, cfg_ro_pguser, cfg_ro_pgpwd, cfg_ssh_port
    global FH_LOG_FILE
    
    # Debug Level Higher than 4 , inform that entering Load configuration file
    if debug > 4 :                                                      # If Debug Run Level 4
        print (" ")                                                 # Space Line in the LOG
        print (dash)                                           # 80 = Lines 
        print ("Load Configuration file %s" % (cfg_file))           # Inform user in Debug
        print (dash)                                           # 80 = Lines 

    # Configuration file MUST be present - If .sadm_config exist, then create sadm_config from it.
    if  not os.path.exists(cfg_file) :
        if not os.path.exists(cfg_hidden) :
           print ("****************************************************************")
           print ("SADMIN Configuration file cannot be found (%s)" % (cfg_file))
           print ("Even the config template file cannot be found (%s)" % (cfg_hidden))
           print ("Copy both files from another system to this server")
           print ("Or restore the files from a backup & review the file content.")
           print ("****************************************************************")
        else :
           print ("****************************************************************")
           print ("The configuration file %s doesn't exist." % (cfg_file))
           print ("Will continue using template configuration file %s" & (cfg_hidden))
           print ("Please review the configuration file.")
           print ("cp %s %s " % (cfg_hidden, cfg_file))             # Install Default cfg  file
           cmd = "cp %s %s"% "cp %s %s " % (cfg_hidden, cfg_file)       # Install Default cfg  file
           ccode, cstdout, cstderr = oscommand(cmd)
           if not ccode == 0 :
               print ("Could not copy the backup file file")
           print ("****************************************************************")

                   
    # Set Minimum Default Values - in case we could not load the SADMIN Config File
    cfg_mail_addr         = "root@localhost"                            # Default email address
    cfg_cie_name          = "Your Company Name"                         # Company Name
    cfg_mail_type         = 3                                           # Send Email after each run
    cfg_user              = "sadmin"                                    # sadmin user account
    cfg_group             = "sadmin"                                    # sadmin group account
    cfg_www_user          = "apache"                                    # sadmin/www user account
    cfg_www_group         = "apache"                                    # sadmin/www group account
    cfg_max_logline       = 5000                                        # Max Line in each *.log
    cfg_max_rchline       = 100                                         # Max Line in each *.rch
    cfg_nmon_keepdays     = 60                                          # Days to keep old *.nmon
    cfg_sar_keepdays      = 60                                          # Days ro keep old *.sar
    cfg_rch_keepdays      = 60                                          # Days to keep old *.rch
    cfg_keepdays          = 60                                          # Days ro keep old *.log
    ccode, cstdout, cstderr = oscommand("host sadmin | cut -d' ' -f1")  # Get FQN of admin server
    if ccode is not 0 :                                                 # If sadmin not resolved
       print ("Error executing 'host sadmin | cut -d' ' -f1")        # Advise User of error
       print ("Assuming 'sadmin' as sadmin server")                  # Will use sadmin no FQN
       cfg_server        = "sadmin"                                     # Default sadmin hostname
    else :                                                              # If sadmin was resolvec
       cfg_server        = cstdout                                      # Used FQN obtained
    cfg_domain         = ""                                             # Default Domain Name
    cfg_pguser         = ""                                             # PostGres Database user
    cfg_pggroup        = ""                                             # PostGres Database Group
    cfg_pgdb           = ""                                             # PostGres Database Name
    cfg_pgschema       = ""                                             # PostGres Database Schema
    cfg_pghost         = ""                                             # PostGres Database Host
    cfg_pgport         = 5432                                           # PostGres Database Port
    cfg_rw_pguser      = ""                                             # PostGres Read/Write User
    cfg_rw_pgpwd       = ""                                             # PostGres Read/Write Pwd
    cfg_ro_pguser      = ""                                             # PostGres Read Only User
    cfg_ro_pgpwd       = ""                                             # PostGres Read Only Pwd
    
    
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

        #print("cfgline = ..." + CFG_NAME + "...  ..." + CFG_VALUE + "...")

     
        # Save Each Parameter found in Sadmin Configuration File
        if "SADM_MAIL_ADDR"     in CFG_NAME : cfg_mail_addr      = CFG_VALUE
        if "SADM_CIE_NAME"      in CFG_NAME : cfg_cie_name       = CFG_VALUE
        if "SADM_MAIL_TYPE"     in CFG_NAME : cfg_mail_type      = int(CFG_VALUE)
        if "SADM_SERVER"        in CFG_NAME : cfg_server         = CFG_VALUE
        if "SADM_DOMAIN"        in CFG_NAME : cfg_domain         = CFG_VALUE
        if "SADM_USER"          in CFG_NAME : cfg_user           = CFG_VALUE
        if "SADM_GROUP"         in CFG_NAME : cfg_group          = CFG_VALUE
        if "SADM_WWW_USER"      in CFG_NAME : cfg_www_user       = CFG_VALUE
        if "SADM_WWW_GROUP"     in CFG_NAME : cfg_www_group      = CFG_VALUE
        if "SADM_MAX_LOGLINE"   in CFG_NAME : cfg_max_logline    = int(CFG_VALUE)
        if "SADM_MAX_RCHLINE"   in CFG_NAME : cfg_max_rchline    = int(CFG_VALUE)
        if "SADM_NMON_KEEPDAYS" in CFG_NAME : cfg_nmon_keepdays  = int(CFG_VALUE)
        if "SADM_SAR_KEEPDAYS"  in CFG_NAME : cfg_sar_keepdays   = int(CFG_VALUE)
        if "SADM_RCH_KEEPDAYS"  in CFG_NAME : cfg_rch_keepdays   = int(CFG_VALUE)
        if "SADM_LOG_KEEPDAYS"  in CFG_NAME : cfg_log_keepdays   = int(CFG_VALUE)
        if "SADM_PGUSER"        in CFG_NAME : cfg_pguser         = CFG_VALUE
        if "SADM_PGGROUP"       in CFG_NAME : cfg_pggroup        = CFG_VALUE
        if "SADM_PGDB"          in CFG_NAME : cfg_pgdb           = CFG_VALUE
        if "SADM_PGSCHEMA"      in CFG_NAME : cfg_pgschema       = CFG_VALUE 
        if "SADM_PGHOST"        in CFG_NAME : cfg_pghost         = CFG_VALUE 
        if "SADM_PGPORT"        in CFG_NAME : cfg_pgport         = int(CFG_VALUE)
        if "SADM_RW_PGUSER"     in CFG_NAME : cfg_rw_pguser      = CFG_VALUE
        if "SADM_RW_PGPWD"      in CFG_NAME : cfg_rw_pgpwd       = CFG_VALUE
        if "SADM_RO_PGUSER"     in CFG_NAME : cfg_ro_pguser      = CFG_VALUE
        if "SADM_RO_PGPWD"      in CFG_NAME : cfg_ro_pgpwd       = CFG_VALUE
        if "SADM_SSH_PORT"      in CFG_NAME : cfg_ssh_port       = int(CFG_VALUE)
        
    FH_CFG_FILE.close()                                                 # Close Config File
    return        


    
#===================================================================================================
#                                       Log File Class
#def main():
#    g.sadmlog = sadmlib.log_tools()                                     # Instantiate SADM Log Tools
#    g.sadmlog.setlog_type(g.log_type)                                     # Set the Log Type

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
#        return ('The Log type is set to (0)'.format(self.log_type))
#
#    def setlog_type(self,wlog_type) :
#        self.log_type = wlog_type
#        
#    def getlog_type(self) :
#        return (self.log_type)
#        
#    def write(self,sline) :
#        now = datetime.datetime.now()
#        logLine = now.strftime("%Y.%m.%d %H:%M:%S") + " - %s" % (sline)
#        if log_type.upper() == "L" :  self.log_fh.write ("%s\n" % (logLine))
#        if log_type.upper() == "S" :  print ("%s" % logLine)
#        if log_type.upper() == "B" :  
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

    print(" ")                                                      # Space Line in the LOG
    print(dash)                                                     # 80 = Lines 
    print("Display Important Environment Variables")                # Introduce Display Below
    print(dash)                                                     # 80 = Lines 
    print("SADMIN Release No.  = " + get_release())                 # Get SADMIN Release Version
    print("This Script Ver No. = " + ver)                           # Program Version
    print("pn                  = " + pn)                            # Program name
    print("inst                = " + inst)                          # Program name without Ext.
    print("hostname            = " + hostname)                      # Program name without Ext.
    print("username            = " + username)                      # Current User Name
    print("tpid                = " + tpid)                          # Get Current Process ID.
    print("multiple_exec       = " + multiple_exec)                 # Can Script run Multiple
    print("debug               = " + str(debug))                    # Debug Level
    print("get_ostype()        = " + get_ostype())                  # OS Type Linux or Aix
    print("get_osname()        = " + get_osname())                  # Distribution of OS
    print("get_osversion()     = " + get_osversion())               # Distribution Version
    print("get_osmajorversion()= " + get_osmajorversion())          # Distribution Major Ver#
    print("get_oscodename()    = " + get_oscodename())              # Distribution Code Name
    print("log_type            = " + log_type)                      # 4Logger S=Scr L=Log B=Both
    print("log_append          = " + log_append)                    # Append to existing  Log 
    print("base_dir            = " + base_dir)                      # Base Dir. where appl. is
    print("tmp_dir             = " + tmp_dir)                       # SADM Temp. Directory
    print("cfg_dir             = " + cfg_dir)                       # SADM Config Directory
    print("lib_dir             = " + lib_dir)                       # SADM Library Directory
    print("bin_dir             = " + bin_dir)                       # SADM Scripts Directory

    print("log_dir             = " + log_dir)                       # SADM Log Directory
    print("www_dir             = " + www_dir)                       # SADM WebSite Dir Structure
    print("pkg_dir             = " + pkg_dir)                       # SADM Package Directory
    print("sys_dir             = " + sys_dir)                       # SADM System Scripts Dir.
    print("dat_dir             = " + dat_dir)                       # SADM Data Directory
    print("nmon_dir            = " + nmon_dir)                      # SADM nmon File Directory
    print("rch_dir             = " + rch_dir)                       # SADM Result Code Dir.
    print("dr_dir              = " + dr_dir)                        # SADM Disaster Recovery Dir
    print("sar_dir             = " + sar_dir)                       # SADM System Activity Rep.
    print("www_dat_dir         = " + www_dat_dir)                   # SADM Web Site Data Dir
    print("www_html_dir        = " + www_html_dir)                  # SADM Web Site Dir
    print("log_file            = " + log_file)                      # SADM Log File
    print("rch_file            = " + rch_file)                      # SADM RCH File
    print("cfg_file            = " + cfg_file)                      # SADM Config File
    print("pid_file            = " + pid_file)                      # SADM PID FileName
    print("tmp_file1           = " + tmp_file1)                     # SADM Tmp File 1
    print("tmp_file2           = " + tmp_file2)                     # SADM Tmp File 2
    print("tmp_file3           = " + tmp_file3)                     # SADM Tmp File 3
    print("which               = " + which)                         # Location of which
    print("lsb_release         = " + lsb_release)                   # Location of lsb_release
    print("dmidecode           = " + dmidecode)                     # Location of dmidecode
    print("fdisk               = " + fdisk)                         # Location of fdisk
    print("uname               = " + uname)                         # Location of uname

    print(" ")                                                      # Space Line in the LOG
    print(dash)                                                # 80 = Lines 
    print("Global variables setting after reading the SADM Configuration file")
    print(dash)                                                # 80 = Lines 
    print("cfg_mail_addr       = ..." + cfg_mail_addr + "...")
    print("cfg_cie_name        = ..." + cfg_cie_name + "...")
    print("cfg_mail_type       = ..." + str(cfg_mail_type) + "...")
    print("cfg_server          = ..." + cfg_server + "...")
    print("cfg_domain          = ..." + cfg_domain + "...")
    print("cfg_user            = ..." + cfg_user + "...")
    print("cfg_group           = ..." + cfg_group + "...")
    print("cfg_www_user        = ..." + cfg_www_user + "...")
    print("cfg_www_group       = ..." + cfg_www_group + "...")
    print("cfg_max_logline     = ..." + str(cfg_max_logline) + "...")
    print("cfg_max_rchline     = ..." + str(cfg_max_rchline) + "...")
    print("cfg_nmon_keepdays   = ..." + str(cfg_nmon_keepdays) + "...")
    print("cfg_sar_keepdays    = ..." + str(cfg_sar_keepdays) + "...")
    print("cfg_rch_keepdays    = ..." + str(cfg_rch_keepdays) + "...")
    print("cfg_log_keepdays    = ..." + str(cfg_log_keepdays) + "...")
    print("cfg_pguser          = ..." + cfg_pguser + "...")
    print("cfg_pggroup         = ..." + cfg_pggroup + "...")
    print("cfg_pgdb            = ..." + cfg_pgdb + "...")
    print("cfg_pgschema        = ..." + cfg_pgschema + "...")
    print("cfg_pghost          = ..." + cfg_pghost + "...")
    print("cfg_pgport          = ..." + str(cfg_pgport) + "...")
    print("cfg_rw_pguser       = ..." + str(cfg_rw_pguser) + "...")
    print("cfg_rw_pgpwd        = ..." + str(cfg_rw_pgpwd) + "...")
    print("cfg_ro_pguser       = ..." + str(cfg_ro_pguser) + "...")
    print("cfg_ro_pgpwd        = ..." + str(cfg_ro_pgpwd) + "...")
    print("cfg_ssh_port        = ..." + str(cfg_ssh_port) + "...")
    return 0

 #load_config_file                                                # Load cfg var from sadmin.cfg