#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_lib_std.py
#   Synopsis:   This is the Standard SADM Python Library 
#===================================================================================================
import os, errno, time, sys, pdb, socket, datetime, getpass, subprocess, smtplib
from subprocess import Popen, PIPE


#===================================================================================================
# SADM Library Initialisation 
#===================================================================================================
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Base Dir. where appl. is
sadm_lib_dir            = os.path.join(sadm_base_dir,'lib')             # SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add /sadmin/lib to PyPath
import sadm_lib_std    as sadmlib                                       # Import sadm Lib as sadmlib
import sadm_var        as g                                             # Import Global Var sadmglob
#
#pdb.set_trace() 
#===================================================================================================
#                                       Write Log to file 
#===================================================================================================
class log_tools :
    total_write = 0                                                     # For Info - Line written

    def __init__(self) :
        if not os.path.exists(g.log_dir) :                              # If the log dir. not exist
            os.mkdir(g.log_dir,0775)                                    # Create SADM Log Directory
        self.log_fh=open(g.log,'a')                                          # Open Log in append  mode

    def __str__ (self) : 
        return ('The Log type is set to (0)'.format(self.logtype))

    def setlogtype(self,wlogtype) :
        self.logtype = wlogtype
        
    def getlogtype(self) :
        return (self.logtype)
        
    def write(self,sline) :
        now = datetime.datetime.now()
        logLine = now.strftime("%Y.%m.%d %H:%M:%S") + " - %s" % (sline)
        if g.logtype.upper() == "L" :  self.log_fh.write ("%s\n" % (logLine))
        if g.logtype.upper() == "S" :  print ("%s" % logLine)
        if g.logtype.upper() == "B" :  
            self.log_fh.write ("%s\n" % (logLine))
            print ("%s" % logLine) 
        log_tools.total_write += 1
        
    def totalWritten() :
        return '(0) lines were written in log'.format(log_tools.total_write)
     
    def close_log(self) :
        self.log_fh.close()                                                  # Close Log File
        
        
    
# --------------------------------------------------------------------------------------------------
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
# --------------------------------------------------------------------------------------------------
def oscommand(command) :
    if g.debug > 8 : g.sadmlog.write ("In sadm_oscommand function to run command : %s" % (command))
    p = subprocess.Popen(command, stdout=PIPE, stderr=PIPE, shell=True)
    out = p.stdout.read().strip()
    err = p.stderr.read().strip()
    returncode = p.wait()
    if g.debug > 8 :
        g.sadmlog.write ("In sadm_oscommand function stdout is      : %s" % (out))
        g.sadmlog.write ("In sadm_oscommand function stderr is      : %s " % (err))
        g.sadmlog.write ("In sadm_oscommand function returncode is  : %s" % (returncode))
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
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
# --------------------------------------------------------------------------------------------------
def ostype() :
    ccode, cstdout, cstderr = oscommand("uname -s")
    ostype=cstdout.upper()
    return ostype


# --------------------------------------------------------------------------------------------------
#                   RETURN THE OS  NAME (ALWAYS RETURNED IN UPPERCASE)
# --------------------------------------------------------------------------------------------------
def osname() :
    ccode, cstdout, cstderr = oscommand(g.lsb_release + " -si")
    osname=cstdout.upper()
    if osname  == "REDHATENTERPRISESERVER" : osname="REDHAT"
    if osname  == "REDHATENTERPRISEAS"     : osname="REDHAT"
    if ostype() == "AIX" : osname="AIX"
    return osname

        

# --------------------------------------------------------------------------------------------------
#                             RETURN THE OS PROJECT CODE NAME
# --------------------------------------------------------------------------------------------------
def oscodename() :
    ccode, cstdout, cstderr = oscommand(g.lsb_release + " -sc")
    oscodename=cstdout.upper()
    if ostype() == "AIX" : oscodename="IBM AIX"
    return oscodename

        

# --------------------------------------------------------------------------------------------------
#                THIS FUNCTION DETERMINE THE OS (DISTRIBUTION) VERSION NUMBER 
# --------------------------------------------------------------------------------------------------
def osversion() :
    osversion="0.0"                                               # Default Value
    if ostype() == "LINUX" :
        ccode, cstdout, cstderr = oscommand(g.lsb_release + " -sr")
        osversion=cstdout
    if ostype() == "AIX" :
        ccode, cstdout, cstderr = oscommand("uname -v")
        maj_ver=cstdout
        ccode, cstdout, cstderr = oscommand("uname -r")
        min_ver=cstdout
        osversion="%s.%s" % (maj.version,min.version)
    return osversion


# --------------------------------------------------------------------------------------------------
#                            RETURN THE OS (DISTRIBUTION) MAJOR VERSION
# --------------------------------------------------------------------------------------------------
def osmajorversion() :
    if ostype() == "LINUX" :
        ccode, cstdout, cstderr = oscommand(g.lsb_release + " -sr")
        osversion=cstdout
        osmajorversion=osversion.split('.')[0]
    if ostype() == "AIX" :
        ccode, cstdout, cstderr = oscommand("uname -v")
        osmajorversion=cstdout
    return osmajorversion

# --------------------------------------------------------------------------------------------------
#            SEND AN EMAIL TO SYSADMIN DEFINE IN SADMIN.CFG WITH SUBJECT AND BODY RECEIVED
# --------------------------------------------------------------------------------------------------
def sendmail(wsub,wbody) :
    wfrom = g.cfg_user + "@" + g.cfg_server
    #pdb.set_trace() 

    try :
        #smtpserver = smtplib.SMTP(g.cfg_smtp_server + ':' + g.cfg_smtp_port)
        smtpserver = smtplib.SMTP(g.cfg_smtp_server, g.cfg_smtp_port)
        smtpserver.ehlo()
        smtpserver.starttls()
        smtpserver.ehlo()
        if g.debug > 4 :
            g.sadmlog.write ("Connect to %s:%s Successfully" % (g.cfg_smtp_server,g.cfg_smtp_port))
        try:
            smtpserver.login (g.cfg_smtp_user_mail, g.cfg_smtp_user_pwd)
        except smtplib.SMTPException :
            g.sadmlog.write ("Authentication for %s Failed %s" % (g.cfg_smtp_user_mail))
            smtpserver.close()
            return 1
        if g.debug > 4 :
            g.sadmlog.write ("Login Successfully using %s" % (g.cfg_smtp_user_mail))
        header = "To: " + g.cfg_smtp_user_mail + '\n' + 'From: ' + wfrom + '\n' + 'Subject: ' + wsub + '\n'
        msg = header + '\n' + wbody + '\n\n'
        try:
            smtpserver.sendmail(wfrom, g.cfg_smtp_user_mail, msg)
        except smtplib.SMTPException:
            g.sadmlog.write ("Email could not be send")
            smtpserver.close()
            return 1
    except (smtplib.SMTPException, socket.error, socket.gaierror, socket.herror), e:
        g.sadmlog.write ("Connection to %s %s Failed" % (g.cfg_smtp_server,g.cfg_smtp_port))
        g.sadmlog.write ("%s" % e)
        return 1
    if g.debug > 4 :
       g.sadmlog.write ("Mail was sent successfully")
    smtpserver.close()
    return 0 
    
    


# --------------------------------------------------------------------------------------------------
#                TRIM THE FILE RECEIVED AS FIRST PARAMETER (MAX LINES IN LOG AS 2ND PARAMATER)
# --------------------------------------------------------------------------------------------------
def trimfile(wfile, maxline=500) :
    #g.sadmlog.write ("Trimming %s to %s lines." %  (wfile, str(maxline)))
    tmpfile = "%s/%s.%s" % (g.tmp_dir,g.inst,datetime.datetime.now().strftime("%y%m%d_%H%M%S"))
    
    cmd = "tail -%s %s > %s" % (maxline, wfile, tmpfile)
    ccode, cstdout, cstderr = oscommand(cmd)
    if not ccode == 0 :
        g.sadmlog.write ("Error occured with command %s" % (cmd))
        g.sadmlog.write ("Command stdout : %s" % (cstdout))
        g.sadmlog.write ("Command stderr : %s" % (cstderr))
        return 1
    
    cmd = "rm -f %s" % (wfile)
    ccode, cstdout, cstderr = oscommand(cmd)
    if not ccode == 0 :
        g.sadmlog.write ("Error occured with command %s" % (cmd))
        g.sadmlog.write ("Command stdout : %s" % (cstdout))
        g.sadmlog.write ("Command stderr : %s" % (cstderr))
        return 1
    
    cmd = "mv %s %s"% (tmpfile, wfile)
    ccode, cstdout, cstderr = oscommand(cmd)
    if not ccode == 0 :
        g.sadmlog.write ("Error occured with command %s" % (cmd))
        g.sadmlog.write ("Command stdout : %s" % (cstdout))
        g.sadmlog.write ("Command stderr : %s" % (cstderr))
        return 1
    
    cmd = "chmod 664 %s" % (wfile)
    ccode, cstdout, cstderr = oscommand(cmd)
    if not ccode == 0 :
        g.sadmlog.write ("Error occured with command %s" % (cmd))
        g.sadmlog.write ("Command stdout : %s" % (cstdout))
        g.sadmlog.write ("Command stderr : %s" % (cstderr))
        return 1
    return 0




# --------------------------------------------------------------------------------------------------
# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
#
def check_requirements () :
    
#    global g.which, g.lsb_release
    if g.debug > 7 :                                                    # If Debug Run Level 7
        g.sadmlog.write (" ")                                           # Space Line in the LOG
        g.sadmlog.write (g.dash)                                        # 80 = Lines 
        g.sadmlog.write ("Checking Libraries Requirements")             # Inform user in Debug
        g.sadmlog.write (g.dash)                                        # 80 = Lines 
    
    ccode, cstdout, cstderr = oscommand("which which")
    if ccode is not 0 :
       g.sadmlog.write ("Error : The command 'which' could not be found")
       g.sadmlog.write ("        This program is often used by the SADMIN tools")
       g.sadmlog.write ("        Please install it and re-run this script")
       g.sadmlog.write ("        To install it, use the following command depending on your distro")
       g.sadmlog.write ("        Use 'yum install which' or 'apt-get install debianutils'")
       g.sadmlog.write ("Script Aborted")
       sys.exit(1)
    g.which = cstdout
    
    ccode, cstdout, cstderr = oscommand("which lsb_release")
    if ccode is not 0 :
       g.sadmlog.write ("CRITICAL: The 'lsb_release' is needed and is not present")
       g.sadmlog.write ("Please correct the situation and re-execute this script")
       sys.exit(1)
    g.lsb_release = cstdout
    
    ccode, cstdout, cstderr = oscommand("which dmidecode")
    if ccode is not 0 :
       g.sadmlog.write ("CRITICAL: The 'dmidecode' is needed and is not present")
       g.sadmlog.write ("Please correct the situation and re-execute this script")
       sys.exit(1)
    g.dmidecode = cstdout
    
    ccode, cstdout, cstderr = oscommand("which uname")
    if ccode is not 0 :
       g.sadmlog.write ("CRITICAL: The 'uname' is needed and is not present")
       g.sadmlog.write ("Please correct the situation and re-execute this script")
       sys.exit(1)
    g.uname = cstdout
    
    ccode, cstdout, cstderr = oscommand("which fdisk")
    if ccode is not 0 :
       g.sadmlog.write ("CRITICAL: The 'fdisk' is needed and is not present")
       g.sadmlog.write ("Please correct the situation and re-execute this script")
       sys.exit(1)
    g.fdisk = cstdout

    ccode, cstdout, cstderr = oscommand("which mail")
    if ccode is not 0 :
       g.sadmlog.write ("Warning: The 'mail' is needed and is not present")
       g.sadmlog.write ("No Email can be sent until this progra,m is instaled")
    g.mail = cstdout
      
    return 0
            
 
#===================================================================================================
#                                          Initial Setup 
#===================================================================================================
def start () :

    # Write SADM Header to Script Log
    g.sadmlog.write (g.dash)                                            # 80 = Lines 
    wmess = "Starting %s - Version.%s on %s" % (g.pn,g.ver,g.hostname)  # Build Log Starting Line
    g.sadmlog.write (wmess)                                             # Write Start line to Log
    wmess = "%s %s %s %s" % (sadmlib.ostype(),sadmlib.osname(),sadmlib.osversion(),sadmlib.oscodename())
    g.sadmlog.write (wmess)                                             # Write OS Info to Log Head
    g.sadmlog.write (g.dash)                                            # 80 = Lines 
    g.sadmlog.write (" ")                                               # Space Line in the LOG

    # Make sure all SADM Directories structure exist
    if not os.path.exists(g.cfg_dir)      : os.mkdir(g.cfg_dir,2775)    # Create Configuration Dir.
    if not os.path.exists(g.tmp_dir)      : os.mkdir(g.tmp_dir,1777)    # Create SADM Temp Dir.
    if not os.path.exists(g.dat_dir)      : os.mkdir(g.dat_dir,2775)    # Create SADM Data Dir.
    if not os.path.exists(g.bin_dir)      : os.mkdir(g.bin_dir,2775)    # Create SADM Bin Dir.
    if not os.path.exists(g.lib_dir)      : os.mkdir(g.lib_dir,2775)    # Create SADM Lib Dir.
    if not os.path.exists(g.sys_dir)      : os.mkdir(g.sys_dir,2775)    # Create SADM Sys Dir.
    if not os.path.exists(g.www_dir)      : os.mkdir(g.www_dir,2775)    # Create SADM WWW Dir.
    if not os.path.exists(g.www_html_dir) : os.mkdir(g.www_html_dir,2775) # Create SADM HTML Dir.
    if not os.path.exists(g.www_dat_dir)  : os.mkdir(g.www_dat_dir,2775)  # Create Web  DAT  Dir.
    if not os.path.exists(g.nmon_dir)     : os.mkdir(g.nmon_dir,2775)   # Create SADM nmon Dir.
    if not os.path.exists(g.dr_dir)       : os.mkdir(g.dr_dir,2775)     # Create SADM DR Dir.
    if not os.path.exists(g.dr_dir)       : os.mkdir(g.dr_dir,2775)     # Create SADM DR Dir.
    if not os.path.exists(g.sar_dir)      : os.mkdir(g.sar_dir,2775)    # Create SADM System Act Dir
    if not os.path.exists(g.rch_dir)      : os.mkdir(g.rch_dir,2775)    # Create SADM RCH Dir.

    # If the PID file already exist - Script is already Running
    if os.path.exists(g.pid_file) and g.multiple_exec == "N" :          # PID Exist & No MultiRun
       g.sadmlog.write ("Script %s is already running." % g.pn)         # Same script is running
       g.sadmlog.write ("PID File %s exist." % g.pid_file)              # Display PID File Location
       g.sadmlog.write ("Will not run a second copy of this script")    # Advise the user
       g.sadmlog.write ("Script Aborted")                               # Script Aborted
       sys.exit(1)                                                      # Exit with Error
    
    # Record Date & Time the script is starting in the RCH File
    i = datetime.datetime.now()                                         # Get Current Time
    g.start_time=i.strftime('%Y.%m.%d %H:%M:%S')                        # Save Start Date & Time
    g.start_epoch = int(time.time())                                    # Save StartTime in Epoch Time
    rch_fh=open(g.rchlog,'a')                                           # Open RC Log in append mode
    rch_line="%s %s %s %s %s" % (g.hostname,g.start_time,"........",g.inst,"2")  # Build RCH LIne
    rch_fh.write ("%s\n" % (rch_line))                                  # Write Line to RCH Log
    rch_fh.close                                                        # Close RCH File
    
    return 0

        
        
# --------------------------------------------------------------------------------------------------
#            LOAD SADMIN CONFIGURATION FILE AND SET GLOBAL VARIABLES ACCORDINGLY
# --------------------------------------------------------------------------------------------------
#
def load_config_file():
    
    # Debug Level Higher than 4 , inform that entering Load configuration file
    if g.debug > 4 :                                                    # If Debug Run Level 4
        g.sadmlog.write (" ")                                           # Space Line in the LOG
        g.sadmlog.write (g.dash)                                        # 80 = Lines 
        g.sadmlog.write ("Load Configuration file %s" % (g.cfg_file))   # Inform user in Debug
        g.sadmlog.write (g.dash)                                        # 80 = Lines 

    # Configuration file MUST be present - If .sadm_config exist, then create sadm_config from it.
    if  not os.path.exists(g.cfg_file) :
        if not os.path.exists(g.cfg_hidden) :
           g.sadmlog.write ("****************************************************************")
           g.sadmlog.write ("SADMIN Configuration file is not found (%s)" % (g.cfg_file))
           g.sadmlog.write ("Even the config template file cannot be found (%s)" % (g.cfg_hidden))
           g.sadmlog.write ("Copy both files from another system to this server")
           g.sadmlog.write ("Or restore the files from a backup")
           g.sadmlog.write ("Review the file content.")
           g.sadmlog.write ("****************************************************************")
        else :
           g.sadmlog.write ("****************************************************************")
           g.sadmlog.write ("The configuration file %s doesn't exist." % (g.cfg_file))
           g.sadmlog.write ("Will continue using template configuration file %s" & (g.cfg_hidden))
           g.sadmlog.write ("Please review the configuration file.")
           g.sadmlog.write ("cp %s %s " % (g.cfg_hidden, g.cfg_file))   # Install Default cfg  file
           cmd = "cp %s %s"% "cp %s %s " % (g.cfg_hidden, g.cfg_file)   # Install Default cfg  file
           ccode, cstdout, cstderr = oscommand(cmd)
           if not ccode == 0 :
               g.sadmlog.write ("Could not copy the backup file file")
           g.sadmlog.write ("****************************************************************")
        
    # Set Minimum Default Values - in case we could not load the SADMIN Config File
    g.mail_addr         = "root@localhost"                              # Default email address
    g.cie_name          = "Your Company Name"                           # Company Name
    g.mail_type         = 3                                             # Send Email after each run
    g.user              = "sadmin"                                      # sadmin user account
    g.group             = "sadmin"                                      # sadmin group account
    g.max_logline       = 5000                                          # Max Line in each *.log
    g.max_rchline       = 100                                           # Max Line in each *.rch
    g.nmon_keepdays     = 40                                            # Days to keep old *.nmon
    g.sar_keepdays      = 40                                            # Days ro keep old *.sar
    ccode, cstdout, cstderr = oscommand("host sadmin | cut -d' ' -f1")  # Get FQN of admin server
    if ccode is not 0 :                                                 # If sadmin not resolved
       g.sadmlog.write ("Error executing 'host sadmin | cut -d' ' -f1") # Advise User of error
       g.sadmlog.write ("Assuming 'sadmin' as sadmin server")           # Will use sadmin no FQN
       g.sadm_server        = "sadmin"                                  # Default sadmin hostname
    else :                                                              # If sadmin was resolvec
       g.sadm_server        = cstdout                                   # Used FQN obtained
    
    
    # Read Configuration file and Save Options values in Global Shared area (g.)
    fh_cfg_file = open(g.cfg_file,'r')                                  # Open COnfig File
    for cfg_line in fh_cfg_file :                                       # Loop until on all servers
        wline        = cfg_line.rstrip()                                # Strip CR/LF & Trailing spaces
        #wline        = wline.lower()                                    # Put string in lowercase
        if (wline[0:1] == '#' or len(wline) == 0) :                     # If comment or blank line
            continue                                                    # Go read the next line
        split_line   = wline.split('=')                                 # Split based on equal sign 
        CFG_NAME   = split_line[0].upper().rstrip().lstrip()            # Get Param Name - Uppercase 
        CFG_VALUE  = str(split_line[1]).rstrip().lstrip()               # Get Param Value
        #pdb.set_trace()   
        if CFG_NAME ==  "SADM_MAIL_ADDR"            : g.cfg_mail_addr      = CFG_VALUE
        if CFG_NAME ==  "SADM_CIE_NAME"             : g.cfg_cie_name       = CFG_VALUE
        if CFG_NAME ==  "SADM_MAIL_TYPE"            : g.cfg_mail_type      = CFG_VALUE
        if CFG_NAME ==  "SADM_SERVER"               : g.cfg_server         = CFG_VALUE
        if CFG_NAME ==  "SADM_USER"                 : g.cfg_user           = CFG_VALUE
        if CFG_NAME ==  "SADM_GROUP"                : g.cfg_group          = CFG_VALUE
        if CFG_NAME ==  "SADM_MAX_LOGLINE"          : g.cfg_max_logline    = CFG_VALUE
        if CFG_NAME ==  "SADM_MAX_RCHLINE"          : g.cfg_max_rchline    = CFG_VALUE
        if CFG_NAME ==  "SADM_NMON_KEEPDAYS"        : g.cfg_nmon_keepdays  = CFG_VALUE
        if CFG_NAME ==  "SADM_SAR_KEEPDAYS"         : g.cfg_sar_keepdays   = CFG_VALUE
        if CFG_NAME ==  "SADM_SMTP_SERVER"          : g.cfg_smtp_server    = CFG_VALUE
        if CFG_NAME ==  "SADM_SMTP_PORT"            : g.cfg_smtp_port      = CFG_VALUE
        if CFG_NAME ==  "SADM_SMTP_USER_MAIL"       : g.cfg_smtp_user_mail = CFG_VALUE
        if CFG_NAME ==  "SADM_SMTP_USER_PWD"        : g.cfg_smtp_user_pwd  = CFG_VALUE
    fh_cfg_file.close()                                                 # Close Config File


    # For Debugging purpose - Display Content of Global Variables related to Configuration file
    if g.debug > 4 :                                                    # If Debug Run Level 4
        g.sadmlog.write("Global variables setting after reading the SADM Cconfigation file")
        g.sadmlog.write("   g.cfg_mail_addr          = ..." + g.cfg_mail_addr + "...")
        g.sadmlog.write("   g.cfg_cie_name           = ..." + g.cfg_cie_name + "...")
        g.sadmlog.write("   g.cfg_mail_type          = ..." + str(g.cfg_mail_type) + "...")
        g.sadmlog.write("   g.cfg_server             = ..." + g.cfg_server + "...")
        g.sadmlog.write("   g.cfg_user               = ..." + g.cfg_user + "...")
        g.sadmlog.write("   g.cfg_group              = ..." + g.cfg_group + "...")
        g.sadmlog.write("   g.cfg_max_logline        = ..." + str(g.cfg_max_logline) + "...")
        g.sadmlog.write("   g.cfg_max_rchline        = ..." + str(g.cfg_max_rchline) + "...")
        g.sadmlog.write("   g.cfg_nmon_keepdays      = ..." + str(g.cfg_nmon_keepdays) + "...")
        g.sadmlog.write("   g.cfg_sar_keepdays       = ..." + str(g.cfg_sar_keepdays) + "...")
        g.sadmlog.write("   g.cfg_smtp_server        = ..." + (g.cfg_smtp_server) + "...")
        g.sadmlog.write("   g.cfg_smtp_port          = ..." + (g.cfg_smtp_port) + "...")
        g.sadmlog.write("   g.cfg_smtp_user_mail     = ..." + (g.cfg_smtp_user_mail) + "...")
        g.sadmlog.write("   g.cfg_smtp_user_pwd      = ..." + (g.cfg_smtp_user_pwd) + "...")
        
    return        
    

#===================================================================================================
#                            Things to do before closing the program
#===================================================================================================
def stop(return_code):
    g.exit_code = return_code                                           # Save Param.Recv Code
    if g.exit_code is not 0 :                                           # If Return code is not 0
        g.exit_code=1                                                   # Making Sure code is 1 or 0
 
    g.sadmlog.write (" ")
    g.sadmlog.write (g.dash)
    g.sadmlog.write ("Script return code is " + str(g.exit_code))
    time.sleep(5)
    g.end_epoch = int(time.time())                                      # Save End Time in Epoch Time
    elapse_seconds = g.end_epoch - g.start_epoch                        # Calculate the Run Time of script
    g.sadmlog.write ("Script took %s seconds to run." % (elapse_seconds))
    g.sadmlog.write ("=====")
    
    ccode, cstdout, cstderr = oscommand("which mail")
    if ccode is not 0 :
        g.sadmlog.write ("WARNING : The command 'mail' was not found")
        g.cfg_mail_type=4
    else :
        SADM_MAIL= cstdout
    
    if g.cfg_mail_type == 0 :
        g.sadmlog.write ("No mail is requested when script end - No Mail Sent")
    if g.cfg_mail_type == 1 :
        if g.exit_code != 0 :
            g.sadmlog.write ("Mail is requested only on Error of the script - Mail Sent")
        else :
            g.sadmlog.write ("Mail is requested only on Error of the script - No Mail Sent")
    if g.cfg_mail_type == 2 :
        if not g.exit_code == 0 :
            g.sadmlog.write ("Mail is requested only on Success of this script - Mail Sent")
        else :
            g.sadmlog.write ("Mail is requested only on Success of this script - No Mail Sent")
    if g.cfg_mail_type == 3 :
        g.sadmlog.write ("Mail is requested either Success or Error of this script - Mail Sent")
    if g.cfg_mail_type == 4 :
        g.sadmlog.write ("No Mail can be send until the mail command is install (yum -y mailx)")
    if g.cfg_mail_type > 4 or g.cfg_mail_type < 0 :
        g.sadmlog.write ("The SADM_MAIL_TYPE is not set properly - Should be between 1 and 4")
        g.sadmlog.write ("It is now set to %s" % (g.cfg_mail_type))
    
    # Record Date & Time the script is starting in the RCH File
    i = datetime.datetime.now()                                         # Get Current Time
    g.stop_time=i.strftime('%Y.%m.%d %H:%M:%S')                         # Save Start Date & Time
    rch_fh=open(g.rchlog,'a')                                           # Open RC Log in append mode
    rch_line="%s %s %s %s %s" % (g.hostname,g.start_time,g.stop_time,g.inst,g.exit_code)
    rch_fh.write ("%s\n" % (rch_line))                                  # Write Line to RCH Log
    rch_fh.close                                                        # Close RCH File

    # Inform UnixAdmin By Email based on his slected choice
    #case $SADM_MAIL_TYPE in
    #    1)  if [ "$SADM_EXIT_CODE" -ne 0 ]
    #           then cat $SADM_LOG | $SADM_MAIL -s "SADM : ERROR of $SADM_PN on $(sadm_hostname)"  $SADM_MAIL_ADDR # On Error
    #        fi
    #        ;;
    #    2)  if [ "$SADM_EXIT_CODE" -eq 0 ]
    #           then cat $SADM_LOG | $SADM_MAIL -s "SADM : SUCCESS of $SADM_PN on $(sadm_hostname)" $SADM_MAIL_ADDR # On Success
    #        fi 
    #        ;;
    #    3)  if [ "$SADM_EXIT_CODE" -eq 0 ]                                              # Always mail
    #            then cat $SADM_LOG | $SADM_MAIL -s "SADM : SUCCESS of $SADM_PN on $(sadm_hostname)" $SADM_MAIL_ADDR
    #            else cat $SADM_LOG | $SADM_MAIL -s "SADM : ERROR of $SADM_PN on $(sadm_hostname)"  $SADM_MAIL_ADDR
    #        fi
    #        ;;
    #esac

    # Advise user the LOg will be trimm
    g.sadmlog.write ("=====")                                           # Footer Seperator
    g.sadmlog.write ("Trimming %s to %s lines." %  (g.log, str(g.cfg_max_logline)))
    g.sadmlog.write ("Trimming %s to %s lines." %  (g.rchlog, str(g.cfg_max_rchline)))

    # Write Script Log Footer
    g.sadmlog.write ("=====")                                           # Footer Seperator
    now = time.strftime("%c")                                           # Get Current Date & Time
    g.sadmlog.write (now + " - End of " + g.pn)                         # Write Final Footer to Log
    g.sadmlog.write (g.dash)                                            # 80 = Lines 
    g.sadmlog.write (" ")                                               # Space Line in the LOG
    g.sadmlog.close_log()                                               # Close the Log File

    # Trimming the Log 
    trimfile (g.log,    g.cfg_max_logline)                              # Trim the Script Log 
    trimfile (g.rchlog, g.cfg_max_rchline)                              # Trim the Script RCH Log 


    # Mail is requested only on Error  (mail_type=1) of the script
    if g.cfg_mail_type == 1 and g.exit_code != 0 :                      # If Error and Mail on error
        sendmail ("SADM : ERROR of %s on %s" % (g.pn, g.hostname), " logfile" )

    # Delete Temproray files used
    silentremove (g.pid_file)                                           # Delete PID File
    silentremove (g.tmp_file1)                                          # Delete Temp file 1
    silentremove (g.tmp_file2)                                          # Delete Temp file 2
    silentremove (g.tmp_file3)                                          # Delete Temp file 3
    return g.exit_code

            
           
#===================================================================================================
# For Debugging Purpose - Display all Important Environment Variables used across SADM Libraries
#===================================================================================================
def display_env () :
    g.sadmlog.write(" ")                                                # Space Line in the LOG
    g.sadmlog.write(g.dash)                                             # 80 = Lines 
    g.sadmlog.write("Display Important Environment Variables")          # Introduce Display Below
    g.sadmlog.write(g.dash)                                             # 80 = Lines 
    g.sadmlog.write("g.ver                 = " + g.ver)                 # Program Version
    g.sadmlog.write("g.pn                  = " + g.pn)                  # Program name
    g.sadmlog.write("g.inst                = " + g.inst)                # Program name without Ext.
    g.sadmlog.write("g.hostname            = " + g.hostname)            # Program name without Ext.
    g.sadmlog.write("g.username            = " + g.username)            # Current User Name
    g.sadmlog.write("g.tpid                = " + g.tpid)                # Get Current Process ID.
    g.sadmlog.write("g.multiple_exec       = " + g.multiple_exec)       # Can Script run Multiple
    g.sadmlog.write("g.debug               = " + str(g.debug))          # Debug Level
    g.sadmlog.write("ostype()              = " + ostype())              # OS Type Linux or Aix
    g.sadmlog.write("osname()              = " + osname())              # Distribution of OS
    g.sadmlog.write("osversion()           = " + osversion())           # Distribution Version
    g.sadmlog.write("osmajorversion()      = " + osmajorversion())      # Distribution Major Ver#
    g.sadmlog.write("oscodename()          = " + oscodename())          # Distribution Code Name
    g.sadmlog.write("g.logtype             = " + g.logtype)             # 4Logger S=Scr L=Log B=Both
    g.sadmlog.write("g.base_dir            = " + g.base_dir)            # Base Dir. where appl. is
    g.sadmlog.write("g.tmp_dir             = " + g.tmp_dir)             # SADM Temp. Directory
    g.sadmlog.write("g.cfg_dir             = " + g.cfg_dir)             # SADM Config Directory
    g.sadmlog.write("g.lib_dir             = " + g.lib_dir)             # SADM Library Directory
    g.sadmlog.write("g.bin_dir             = " + g.bin_dir)             # SADM Scripts Directory
    g.sadmlog.write("g.log_dir             = " + g.log_dir)             # SADM Log Directory
    g.sadmlog.write("g.www_dir             = " + g.www_dir)             # SADM WebSite Dir Structure
    g.sadmlog.write("g.pkg_dir             = " + g.pkg_dir)             # SADM Package Directory
    g.sadmlog.write("g.sys_dir             = " + g.sys_dir)             # SADM System Scripts Dir.
    g.sadmlog.write("g.dat_dir             = " + g.dat_dir)             # SADM Data Directory
    g.sadmlog.write("g.nmon_dir            = " + g.nmon_dir)            # SADM nmon File Directory
    g.sadmlog.write("g.rch_dir             = " + g.rch_dir)             # SADM Result Code Dir.
    g.sadmlog.write("g.dr_dir              = " + g.dr_dir)              # SADM Disaster Recovery Dir
    g.sadmlog.write("g.sar_dir             = " + g.sar_dir)             # SADM System Activity Rep.
    g.sadmlog.write("g.www_dat_dir         = " + g.www_dat_dir)         # SADM Web Site Data Dir
    g.sadmlog.write("g.www_html_dir        = " + g.www_html_dir)        # SADM Web Site Dir
    g.sadmlog.write("g.log                 = " + g.log)                 # SADM Log File
    g.sadmlog.write("g.rchlog              = " + g.rchlog)              # SADM RCH File
    g.sadmlog.write("g.cfg_file            = " + g.cfg_file)            # SADM Config File
    g.sadmlog.write("g.pid_file            = " + g.pid_file)            # SADM PID FileName
    g.sadmlog.write("g.tmp_file1           = " + g.tmp_file1)           # SADM Tmp File 1
    g.sadmlog.write("g.tmp_file2           = " + g.tmp_file2)           # SADM Tmp File 2
    g.sadmlog.write("g.tmp_file3           = " + g.tmp_file3)           # SADM Tmp File 3
    g.sadmlog.write("g.which               = " + g.which)               # Location of which
    g.sadmlog.write("g.lsb_release         = " + g.lsb_release)         # Location of lsb_release
    g.sadmlog.write("g.dmidecode           = " + g.dmidecode)           # Location of dmidecode
    g.sadmlog.write("g.fdisk               = " + g.fdisk)               # Location of fdisk
    g.sadmlog.write("g.uname               = " + g.uname)               # Location of uname
    return 0

