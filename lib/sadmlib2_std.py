#!/usr/bin/env python3
#---------------------------------------------------------------------------------------------------
#   Author:     :   Jacques Duplessis
#   Title:      :   sadmlib2_std.py
#   Synopsis:   :   This is the SADMIN Python Library Version 2
#   Date        :   2021/10/20
#   Requires    :   python3 and SADMIN Python Library
# 
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
#---------------------------------------------------------------------------------------------------
# Change Log
# 2021_09_16 lib v4.00 Initial new version
# 2021_10_21 lib v4.01 If rch is not used (use_rch=False). delete the RCH file if present.
# 2021_10_31 lib v4.02 Added Epoch math function, get_serial and fix chown error creating footer.
# 2021_12_02 lib v4.03 Added help (Docstrings) to each functions and complete code re-structure.
# 2021_12_11 lib v4.04 Fix some typo error.
# 2021_12_18 lib v4.05 Fix error within 'start' function.
# 2021_12_20 lib v4.06 Load additional options fields (SMTP) from the SADMIN configuration file.
# 2022_03_06 lib v4.07 Change message when PID exist and trying to run a second instance of script.
# 2022_04_11 lib v4.08 Use file '/etc/os-release' to get O/S info instead of 'lsb_release'.
# 2022_05_09 lib v4.10 First Production version of new Python Library v4.
# 2022_05_21 lib v4.11 Enhance host lock function & minor changes.
# 2022_05_25 lib v4.12 New variables 'sa.proot_only' & 'sa.psadm_server_only' control pgm env.
# 2022_05_26 lib v4.13 Change message that appear when running not as 'root'.
# 2022_05_27 lib v4.14 Fix for AlmaLinux, problem with blank line in '/etc/os-release' file.
# 2022_05_27 lib v4.15 Use socket.getfqdn() to get fqdn.
# 2022_05_29 lib v4.16 Python socket.getfqdn() don't always return a domain name, use shell method.
# 2022_06_01 lib v4.17 Fix get_domain() function to get proper domain name.
# 2022_06_10 lib v4.18 Fix minor problem within the 'start' function.
# 2022_06_10 lib v4.19 Fix error message at end of execution when script wasn't running as 'root'.
# 2022_06_13 lib v4.20 Add possibility use 'sendmail()' to send multiple attachments.
# 2022_07_13 lib v4.21 If no file attached to email, subject was blank.
# 2022_08_17 lib v4.22 Add possibility to connect to other database than 'sadmin' in db_connect().
# 2022_08_24 lib v4.23 Fix crash when log or error file didn't have the right permission.
# 2022_08_26 lib v4.24 Lock file move from $SADMIN/tmp to $SADMIN so it's not remove upon startup.
# 2022_08_26 lib v4.25 Correct a typo at line 718.
# 2022_11_01 lib v4.26 Minor change for MacOS Ventura.
# 2023_04_10 lib v4.27 Set gmail password global variable 'sadm_gmpw'. 
# 2023_04_13 lib v4.28 Old Python Library 'sadmlib_std.py' is now depreciated use 'sadmlib2_std.py'.
# 2023_04_13 lib v4.29 Load new variables 'SADM_REAR_DIF' & 'SADM_REAR_INTERVAL' from sadmin.cfg.
# 2023_04_13 lib v4.30 Load new variable 'SADM_BACKUP_INTERVAL' from sadmin.cfg use on backup page.
# 2023_04_14 lib v4.31 Email account password now encrypted in $SADMIN/cfg/.gmpw64 (base64)
# 2023_04_14 lib v4.32 Change email password file on SADM server ($SADMIN/cfg/.gmpw) encrypt automatically .gmpw64.
# 2023_05_02 lib v4.33 Fix when dealing with email password on SADMIN sever.
# 2023_05_23 lib v4.34 Distribution name wasn't shown in header in RedHat (lsb_release removed from distr.).
# 2023_05_24 lib v4.35 New function added "getUmask()", returning current umask.
# 2023_05_24 lib v4.36 Umask now shown in script header.
# 2023_05_24 lib v4.37 Fix permission problem with mail password file ($SADMIN/cfg/.gmpw).
# 2023_05_25 lib v4.38 Improve function 'locate_command()' & fix intermittent problem.
# 2023_05_25 lib v4.39 Header now include for kernel version number.
# 2023_06_03 lib v4.40 Change method of getting username, was a problem with 'os.getlogin()'.
# 2023_07_09 lib v4.41 New function 'get_mac_address()': Get mac address of an IP.
# 2023_07_11 lib v4.42 Fix minor bugs.
# 2023_08_01 lib v4.43 Added 'db_name' variable that hold 'SADMIN' database name (or yours).
# 2023_08_19 lib v4.44 start() & stop() functions now connect/close DB automatically (if db_used=True).
# 2023_09_22 lib v4.45 Reduce recommended SADM_*_KEEPDAYS values of  to save disk space.
# 2023_10_23 lib v4.46 Fix crash when running a script that need to be run by 'root' and was not.
# 2023_11_17 lib v4.47 Fix error in db_close(), when trying to close a connection that isn't open.
# 2023_12_14 lib v4.48 'SADM_HOST_TYPE' in 'sadmin.cfg', determine if system is a client or a server.
# 2023_12_14 lib v4.48 Correct some type in the header
# 2023_12_19 lib v4.49 New function 'on_sadmin_server()' Return "Y" if on SADMIN server else "N".
# 2024_01_01 lib v4.50 Correct typo and remove need to use 'psutil' python module.
# --------------------------------------------------------------------------------------------------
#
try :
    import os                                               # Operating System interface
    import sys                                              # System-Specific Module
    import datetime                                         # Date & Time Module
    import shutil                                           # HighLevel File Operations
    import platform                                         # Platform identifying data
    #import psutil                                           # Get all IPs defined on host
    import pwd                                              # Pwd /etc/passwd Database 
    import base64                                           # To Encrypt, decrypt password file
    import inspect                                          # Check Object Type
    import time                                             # Time access & conversions
    import socket                                           # LowLevel network interface
    import subprocess                                       # Subprocess management
    import smtplib,ssl                                      # SMTP/SSL protocol client
    from email.mime.multipart import MIMEMultipart          # Use for sending email
    from email.mime.text import MIMEText                    # Use for sending email
    from email.mime.base import MIMEBase                    # Use for sending email
    from email import encoders                              # Use for sending email
    import grp                                              # Access group database
    import linecache                                        # Text lines Random access 
    import subprocess                                       # Subprocess management
    import multiprocessing                                  # Process-based parallelism
#   import pdb                                              # Python Debugger
    import pymysql 
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                            # Activate Python Debugging

# Global Variables Shared among all SADM Libraries and Scripts
# --------------------------------------------------------------------------------------------------
lib_ver             = "4.50"                                # This Library Version
lib_debug           = 0                                     # Library Debug Level (0-9)
start_time          = ""                                    # Script Start Date & Time
stop_time           = ""                                    # Script Stop Date & Time
start_epoch         = ""                                    # Script Start EPoch Time
delete_pid          = ""                                    # Del pid file from 2nd Inst
dict_alert          = {}                                    # Define empty alert Dict.

# Shared Variables between SADMIN Python Library and this script 
pn                  = os.path.basename(sys.argv[0])         # Script name with extension
pver                = "1.0.0"                               # Script Program Version
pdesc               = "Description of script '%s'" % (pn)   # Program Description
pinst               = pn.split('.')[0]                      # Pgm name without Ext
ppid                = os.getpid()                           # Get Current Process ID.
phostname           = platform.node().split('.')[0].strip() # Get current hostname
pusername           = pwd.getpwuid(os.getuid())[0]          # Get Current User Name
#
#
# Fields used by sa.start(),sa.stop() & DB functions that influence execution of SADMIN library
db_used        = True           # Open/Use DB(True), No DB needed (False), sa.start() auto connect
db_silent      = False          # When DB Error Return(Error), True = NoErrMsg, False = ShowErrMsg
db_conn        = None           # Use this Database Connector when using DB,  set by sa.start()
db_cur         = None           # Use this Database cursor if you use the DB, set by sa.start()
db_name        = ""             # Database Name default to name define in $SADMIN/cfg/sadmin.cfg
db_errno       = 0              # Database Error Number
db_errmsg      = ""             # Database Error Message
#
debug               = 0                                     # Debug Level 0-9
pexit_code          = 0                                     # Script Default Return Code
proot_only          = False                                 # Can run by root only ?
psadm_server_only   = False                                 # Can run on SADMIN server only?

# Start Function Arguments Definitions
log_type            = "B"                                   # S=Screen L=Log B=Both
log_append          = False                                 # Create new log every time
log_header          = True                                  # True = Produce Log Header
log_footer          = True                                  # True = Produce Log Footer
multiple_exec       = False                                 # Allow running multiple Instance ?
use_rch             = True                                  # True = Use RCH File ?
pid_timeout         = 7200                                  # PID File TTL default
lock_timeout        = 3600                                  # Host Lock File TTL 
max_logline         = 500                                   # Max Nb. Lines in LOG
max_rchline         = 35                                    # Max Nb. Lines in RCH file
mail_addr           = ""                                    # Default is in sadmin.cfg


# SADM Configuration file (sadmin.cfg) content loaded from configuration file
sadm_alert_type               = 1                           # 0=No 1=Err 2=Succes 3=All
sadm_alert_group              = "default"                   # Defined in alert_group.cfg
sadm_alert_repeat             = 43200                       # Alarm Repeat Wait Time Sec
sadm_textbelt_key             = "textbelt"                  # Textbelt.com Def. API Key
sadm_textbelt_url             = "https://textbelt.com/text" # Textbelt.com Def. API URL
sadm_host_type                = ""                          # [C or S] Client or Server
sadm_server                   = ""                          # SADMIN Server FQDN 
sadm_domain                   = ""                          # Default Host Domain
sadm_mail_addr                = ""                          # Default is in sadmin.cfg
sadm_cie_name                 = ""                          # Company Name
sadm_user                     = ""                          # sadmin user account
sadm_group                    = ""                          # sadmin user group
sadm_nmon_keepdays            = 20                          # Days to keep old *.nmon
sadm_rch_keepdays             = 35                          # Days to keep old *.rch
sadm_log_keepdays             = 35                          # Days to keep old *.log
sadm_www_user                 = ""                          # Http web user
sadm_www_group                = ""                          # Http web user group
sadm_dbname                   = ""                          # MySQL Database Name
sadm_dbhost                   = ""                          # MySQL Database Host
sadm_dbport                   = 3306                        # MySQL Database Port
sadm_rw_dbuser                = ""                          # MySQL Read Write User
sadm_rw_dbpwd                 = ""                          # MySQL Read Write Pwd
sadm_ro_dbuser                = ""                          # MySQL Read Only User
sadm_ro_dbpwd                 = ""                          # MySQL Read Only Pwd
sadm_ssh_port                 = 22                          # SSH Port used in Farm
sadm_backup_nfs_server        = ""                          # Backup NFS Server
sadm_backup_nfs_mount_point   = ""                          # Backup Mount Point
sadm_daily_backup_to_keep     = 3                           # Nb Daily Backup to keep
sadm_weekly_backup_to_keep    = 3                           # Nb Weekly Backup to keep
sadm_monthly_backup_to_keep   = 3                           # Nb Monthly Backup to keep
sadm_yearly_backup_to_keep    = 3                           # Nb Yearly Backup to keep
sadm_weekly_backup_day        = 5                           # Weekly Backup Day (1=Mon.)
sadm_monthly_backup_date      = 1                           # Monthly Backup Date (1-28)
sadm_yearly_backup_month      = 12                          # Yearly Backup Month (1-12)
sadm_yearly_backup_date       = 31                          # Yearly Backup Date(1-31)
sadm_backup_dif               = 40                          # % Backup Size Diff. Alert
sadm_backup_interval          = 7                           # Days before yellow alert
sadm_rear_nfs_server          = ""                          # Rear NFS Server
sadm_rear_nfs_mount_point     = ""                          # Rear NFS Mount Point
sadm_rear_backup_to_keep      = 3                           # Nb of Rear Backup to keep
sadm_rear_backup_dif          = 25                          # % size diff cur. vs prev.
sadm_rear_backup_interval     = 7                           # Alert when 7 days without
sadm_network1                 = ""                          # Network Subnet 1 to report
sadm_network2                 = ""                          # Network Subnet 2 to report
sadm_network3                 = ""                          # Network Subnet 3 to report
sadm_network4                 = ""                          # Network Subnet 4 to report
sadm_network5                 = ""                          # Network Subnet 5 to report
sadm_monitor_update_interval = 60                           # Sysmon refresh rate
sadm_monitor_recent_count    = 10                           # SysMon Nb Recent Script
sadm_monitor_recent_exclude  = "sadm_nmon_watcher"          # SysMon Recent list Exclude 
sadm_pid_timeout             = 7200                         # PID File TTL default
sadm_lock_timeout            = 3600                         # Host Lock File TTL 
sadm_max_logline             = 500                          # Max Nb. Lines in LOG
sadm_max_rchline             = 100                          # Max Nb. Lines in RCH file
sadm_smtp_server             = "smtp.gmail.com"             # smtp host relay name
sadm_smtp_port               = 587                          # smtp relay host port
sadm_smtp_sender             = "sender@gmail.com"           # smtp sender account
sadm_gmpw                    = ""                           # smtp sender password


# Logic to get O/S Distribution Information into Dictionary os_dict
if platform.system().upper() != "DARWIN":                   # If not on MAc
    osrelease                    = "/etc/os-release"        # Distribution Info file
    os_dict                      = {}                       # Dict. for O/S Info
    with open(osrelease) as f:                              # Open /etc/os-release as f
       for line in f:                                       # Process each line
           if len(line) < 2  : continue                     # Skip empty Line
           if line[0].strip == "#" : continue               # Skip line beginning with #
           k,v = line.rstrip().split("=")                   # Get Key,Value of each line
           os_dict[k] = v.strip('"')                        # Store info in Dictionary
    if lib_debug: 
        for key, value in os_dict.items() :
            print("%-40s : %s" % ("os_dict['"+str(key)+"']",str(value)))


# O/S Path to various commands used by SADM Tools
cmd_which           = "/usr/bin/which"                     # which Path - Required
cmd_locate          = "/usr/bin/locate"                    # Locate command 
cmd_lsb_release     = ""                                    # Command lsb_release Path
cmd_dmidecode       = ""                                    # Command dmidecode Path
cmd_bc              = ""                                    # Command bc (Do Some Math)
cmd_fdisk           = ""                                    # fdisk (Read Disk Capacity)
cmd_perl            = ""                                    # perl Path (for epoch time)
cmd_nmon            = ""                                    # nmon command path
cmd_lscpu           = ""                                    # lscpu command path
cmd_inxi            = ""                                    # inxi command path
cmd_parted          = ""                                    # parted command path
cmd_ethtool         = ""                                    # ethtool command path
cmd_curl            = ""                                    # curl command path
cmd_mutt            = ""                                    # mutt command path
cmd_rrdtool         = ""                                    # rrdtool command path
cmd_ssh             = ""                                    # ssh command path


# SADMIN Main Directories Definitions
dir_base           = os.environ.get('SADMIN')               # SADMIN Base Directory
dir_lib            = os.path.join(dir_base,'lib')           # SADM Lib. Directory
dir_tmp            = os.path.join(dir_base,'tmp')           # SADM Temp. Directory
dir_bin            = os.path.join(dir_base,'bin')           # SADM Scripts Directory
dir_log            = os.path.join(dir_base,'log')           # SADM Log Directory
dir_pkg            = os.path.join(dir_base,'pkg')           # SADM Package Directory
dir_cfg            = os.path.join(dir_base,'cfg')           # SADM Config Directory
dir_sys            = os.path.join(dir_base,'sys')           # SADM System Scripts Dir.
dir_dat            = os.path.join(dir_base,'dat')           # SADM Data Directory
dir_doc            = os.path.join(dir_base,'doc')           # SADM Documentation Dir.
dir_setup          = os.path.join(dir_base,'setup')         # SADM Setup Directory
dir_usr            = os.path.join(dir_base,'usr')           # SADM User Directory
dir_www            = os.path.join(dir_base,'www')           # SADM WebSite Dir Structure

# SADMIN Data Directories Definitions
dir_nmon           = os.path.join(dir_dat,'nmon')           # SADM nmon File Directory
dir_rch            = os.path.join(dir_dat,'rch')            # SADM Result Code Dir.
dir_dr             = os.path.join(dir_dat,'dr')             # SADM Disaster Recovery Dir
dir_net            = os.path.join(dir_dat,'net')            # SADM Network/Subnet Dir
dir_rpt            = os.path.join(dir_dat,'rpt')            # SADM Sysmon Report Dir.
dir_dbb            = os.path.join(dir_dat,'dbb')            # SADM Database Backup Dir.

# SADM User Directories Structure
dir_usr_bin        = os.path.join(dir_usr,'bin')            # SADM User Bin Dir.
dir_usr_lib        = os.path.join(dir_usr,'lib')            # SADM User Lib Dir.
dir_usr_doc        = os.path.join(dir_usr,'doc')            # SADM User Doc Dir.
dir_usr_mon        = os.path.join(dir_usr,'mon')            # SADM Usr SysMon Script Dir

# SADM Web Site Directories Structure
dir_www_dat        = os.path.join(dir_www,'dat')            # SADM Web Site Data Dir
dir_www_arc        = os.path.join(dir_www,'archive')        # SADM WebSite ArchiveDir
dir_www_doc        = os.path.join(dir_www,'doc')            # SADM Web Site Doc Dir
dir_www_lib        = os.path.join(dir_www,'lib')            # SADM dbpass_file
dir_www_tmp        = os.path.join(dir_www,'tmp')            # SADM Web Site Tmp Dir
dir_www_perf       = os.path.join(dir_www_tmp,'perf')       # SADM Web Perf. Graph Dir
dir_www_host       = dir_www_dat + '/' + phostname          # Web Data Per Host .Dir
dir_www_net        = dir_www_host + '/net'                  # Web Data Net Dir
dir_www_log        = dir_www_host + '/log'                  # Web Data Log Dir
dir_www_rch        = dir_www_host + '/rch'                  # Web Data RCH Dir

# SADMIN Files Definition
pid_file           = "%s/%s.pid" % (dir_tmp, pinst)                     # Process ID File
rel_file           = dir_cfg + '/.release'                              # SADMIN Release Version No.
dbpass_file        = dir_cfg + '/.dbpass'                               # SADMIN DB User/Pwd file
dbpass_file_fh     = ""                                                 # SADMIN DB User/Pwd Handler
gmpw_file_txt      = dir_cfg + '/.gmpw'                                 # SMTP old password file
gmpw_file_b64      = dir_cfg + '/.gmpw64'                               # SMTP new password file
gmpw_file_fh       = ""                                                 # SMTP Passwd file Handler
log_file           = dir_log + '/' + phostname + '_' + pinst + '.log'   # Log File Name
log_file_fh        = ""                                                 # Log File Handler
err_file           = dir_log + '/' + phostname + '_' + pinst + '_e.log' # Error log File Name
err_file_fh        = ""                                                 # Error log File Handler
rch_file           = dir_rch + '/' + phostname + '_' + pinst + '.rch'   # Result Code History file
rch_file_fh        = ""                                                 # RCH File Handler
rpt_file           = dir_rpt + '/' + phostname + '.rpt'                 # Sysmon Result Report File
cfg_file           = dir_cfg + '/sadmin.cfg'                            # SADMIN Config Filename
cfg_file_fh        = ""                                                 # Configuration File Handler
cfg_hidden         = dir_cfg + '/.sadmin.cfg'                           # SADMIN Initial CFG File
alert_file         = dir_cfg + '/alert_group.cfg'                       # AlertGroup Definition File
alert_file_fh      = ""                                                 # AlertGroup File Handler
alert_init         = dir_cfg + '/.alert_group.cfg'                      # AlertGroup Initial File
alert_hist         = dir_cfg + '/alert_history.txt'                     # Alert History Text File
alert_hini         = dir_cfg + '/.alert_history.txt'                    # Alert History Initial File
crontab_work       = dir_www_lib + '/.crontab.txt'                      # Work crontab
crontab_file       = '/etc/cron.d/sadmin'                               # Final crontab
rear_newcron       = dir_cfg + '.sadm_rear_backup'                      # Tmp Cron for Rear Backup
rear_crontab       = dir_cfg + '/etc/cron.d/sadm_rear_backup'           # Real Rear Crontab
rear_exclude_init  = dir_cfg + '/.rear_exclude.txt'                     # Rear Init exclude List
backup_list        = dir_cfg + '/backup_list.txt'                       # FileName & Dir. to Backup
backup_list_init   = dir_cfg + '/.backup_list.txt'                      # Initial File/Dir. 2 Backup
backup_exclude     = dir_cfg + '/backup_exclude.txt'                    # Exclude File/Dir 2 Exclude
backup_exclude_init= dir_cfg + '/.backup_exclude.txt'                   # Initial File/Dir 2 Exclude
tmp_file_prefix    = dir_tmp + '/' + pinst                              # TMP Prefix
tmp_file1          = "%s_1.%s" % (tmp_file_prefix,ppid)                 # Temp1 Filename
tmp_file2          = "%s_2.%s" % (tmp_file_prefix,ppid)                 # Temp2 Filename
tmp_file3          = "%s_3.%s" % (tmp_file_prefix,ppid)                 # Temp3 Filename
# The SSH command used to communicate with all the systems.
cmd_ssh_full = "%s -qnp %s " % (cmd_ssh,sadm_ssh_port) 




#---------------------------------------------------------------------------------------------------
def write_log (wline, lf=True ):
    
    """ 
        Write a string in log file and/or the screen.
        Depend on log_type: [B]oth,[L]og,[S]creen.
        
        Args:
            wline (str) : Line to write to log (with time stamp)
                          For log file, all "\n" are replace by " " in wline (Except for EOL)
                          Line write to screen are untouched (with no time stamp)
            lf (boolean): Include or not a line feed at the EOL on screen.
                          True or False (True Default).
        Returns:
            None
    """

    global log_file_fh                                                  # Log file File Handle

    now = datetime.datetime.now()                                       # Get current Time
    logLine = now.strftime("%Y.%m.%d %H:%M:%S") + " - " + wline         # Add Date/Time to Log Line
    if (log_type.upper() == "L") or (log_type.upper() == "B") :         # Output to Log or Both
        logLine=logLine.replace("\n"," ").strip()                       # Replace \n by " " in Log
        log_file_fh.write ("%s\n" % (logLine))                          # Write to Log
    if (log_type.upper() == "S") or (log_type.upper() == "B") :         # Output to Screen
        if (lf) :                                                       # If EOL Line feed requested
            print ("%s" % wline)                                        # Line with LineFeed
        else :                                                          # No LineFeed requested
            print ("%s" % wline, end='')                                # Line without LineFeed
    return(0)



#---------------------------------------------------------------------------------------------------
def write_err (wline, lf=True ):
    
    """ 
        Write a string in error log file and/or the screen.
        Depend on log_type: [B]oth,[L]og,[S]creen.
        
        Args:
            wline (str) : Line to write to log (with time stamp)
                          When writing to error (and log) file, all "\n" are replace by " " in wline 
                          (Except for EOL).
                          Line to write to screen untouched (with no time stamp)
            lf (boolean): Include or not a line feed at EOL on the screen.
                          True or False (True Default).
        Returns:
            None
    """

    global log_file_fh, err_file_fh                                     # Log & Error File Handle
    
    now = datetime.datetime.now()                                       # Get current Time
    logLine = now.strftime("%Y.%m.%d %H:%M:%S") + " - " + wline         # Add Date/Time to Log Line

    if (log_type.upper() == "L") or (log_type.upper() == "B") :         # Output to Log or Both
        logLine=logLine.replace("\n"," ").strip()                       # Replace \n by " " in Log
        log_file_fh.write ("%s\n" % (logLine))                          # Write to log file
        err_file_fh.write ("%s\n" % (logLine))                          # Write to error file
    
    if (log_type.upper() == "S") or (log_type.upper() == "B") :         # Output to Screen
        if (lf) :                                                       # If EOL Line feed requested
            print ("%s" % wline)                                        # Line with LineFeed
        else :                                                          # No LineFeed requested
            print ("%s" % wline, end='')                                # Line without LineFeed
    return(0) 



# --------------------------------------------------------------------------------------------------
def silentremove(filename : str):
    
    """ 
        Silently remove the file received as parameter, without error if file doesn't exist. 
        
        Args:
            filename (str)  :   Full path of the file to delete.

        Returns:
            returncode (int):   0 When command executed with success (even if file doesn't exist)
                                1 When error occurred (Permission Error)
    """

    if os.path.exists(filename):
        try:
            os.remove(filename)
        except OSError as e: 
            pass
    return(0)




# --------------------------------------------------------------------------------------------------
def getUmask():
        
    """ 
        Args:
            No argument needed.
        Returns:
            current_umask (int):    Return the current umask.
    """
    current_umask = os.umask(0)
    os.umask(current_umask)
    return (current_umask )




# --------------------------------------------------------------------------------------------------
def trimfile(filename,nlines=500) :
    
    """ 
    Trim the file received to the number of lines indicated in the second parameter.
        - If 2nd parameter 'nlines' is omitted a value of 500 is use.
        - If 2nd parameter 'nlines' is specified and is 0, then no trim is done on the file.
        
    Arguments:
        filename (str)  :   Full path of the file to trim.
        nlines (int)    :   Keep the last "nlines" lines of the file.
                            No trim is done if nlines equal 0.

    Returns:
        returncode (int):   0 When command executed with success 
                            1 When error occurred (Permission Error)
    """
    
    funcname = sys._getframe().f_code.co_name                           # Get Name current function
    nlines = int(nlines)                                                # Making sure nlines=integer
    if lib_debug > 8 : print ("Trim %s to %d lines." % (filename,nlines))
    if nlines == 0   : return 0                                         # User don't want to trim

    if (not os.path.exists(filename)):                                  # If fileName doesn't exist
        print ("Error in '%s' function, file %s doesn't exist" % (funcname,filename))
        return 1
    tot_lines = len(open(filename).readlines())                         # Count total no. of lines
    stat_info= os.stat(filename)                                        # Get Current File Stat
    file_uid = stat_info.st_uid                                         # Get Current File UID
    file_gid = stat_info.st_gid                                         # Get Current File GID

    # Create temporary file
    tmpfile = "%s/%s.%s" % (dir_tmp,pinst,datetime.datetime.now().strftime("%y%m%d_%H%M%S"))
     
    # Open Temporary file in output mode
    try:
        FN=open(tmpfile,'w')                                            # Open Temp file for output
    except IOError as e:                                                # If Can't open output file
        print ("Error in '%s' function, opening file %s" % (funcname,filename))  
        return 1

    # Use line cache module to read the lines
    for i in range(tot_lines - nlines + 1, tot_lines+1):                # Start Read at desired line
        wline = linecache.getline(filename, i)                          # Get Desired line to keep
        FN.write ("%s" % (wline))                                       # Write line to tmpFile
    FN.flush()                                                          # Got to do it - Missing end
    FN.close()                                                          # Close tempFile

    try:
        os.remove(filename)                                             # Remove Original file
    except OSError as e:
        print ("Error in '%s' function, removing %s" % (funcname,filename))
        return 1

    try:
        shutil.move (tmpfile,filename)                                  # Rename tmp to original
    except OSError as e:
        print ("Error in '%s' function, renaming %s to %s" % (funcname,tmpfile,filename))
        print ("Rename Error: %s - %s." % (e.filename,e.strerror))
        return 1

    # Make Sure Owner/Group and permission of new trimmed file are the same as original file.
    try :
        if os.getuid() == 0: os.chown(filename,file_uid,file_gid)       # User & Group Original ID
        os.chmod(filename,0o0664)                                       # Change Perm on Trim file
    except Exception as e:
        msg = "Error in '%s' function, couldn't change owner or chmod of %s " % (funcname,filename)
        print ("%s to %s.%s" % (msg,sadm_user,sadm_group))
        print ("%s" % (e))
    return 0





# --------------------------------------------------------------------------------------------------
def load_config_file(cfg_file):
    
    """ 
        Load Sadmin Configuration File (sadmin.cfg) in dictionary.
        
        Args:
            cfg_file (str)  :   Full path of the SADMIN configuration file.

        Returns:
            All Global variables are loader with the content of sadmin.cfg
    """

    global \
    sadm_alert_type              ,sadm_alert_group              ,sadm_alert_repeat             ,\
    sadm_textbelt_key            ,sadm_textbelt_url             ,sadm_host_type                ,\
    sadm_server                  ,sadm_domain                   ,sadm_mail_addr                ,\
    sadm_cie_name                ,sadm_user                     ,sadm_group                    ,\
    sadm_nmon_keepdays           ,sadm_rch_keepdays             ,sadm_log_keepdays             ,\
    sadm_www_user                ,sadm_www_group                                               ,\
    sadm_dbname                  ,sadm_dbhost                   ,sadm_dbport                   ,\
    sadm_rw_dbuser               ,sadm_rw_dbpwd                 ,sadm_ro_dbuser                ,\
    sadm_ro_dbpwd                ,sadm_ssh_port                 ,sadm_backup_nfs_server        ,\
    sadm_backup_nfs_mount_point  ,sadm_daily_backup_to_keep     ,sadm_weekly_backup_to_keep    ,\
    sadm_monthly_backup_to_keep  ,sadm_yearly_backup_to_keep    ,sadm_weekly_backup_day        ,\
    sadm_monthly_backup_date     ,sadm_yearly_backup_month      ,sadm_yearly_backup_date       ,\
    sadm_rear_nfs_server         ,sadm_rear_nfs_mount_point     ,sadm_rear_backup_to_keep      ,\
    sadm_rear_backup_dif         ,sadm_rear_backup_interval                                    ,\
    sadm_network1                ,sadm_network2                 ,sadm_network3                 ,\
    sadm_network4                ,sadm_network5                 ,sadm_monitor_update_interval  ,\
    sadm_monitor_recent_count    ,sadm_monitor_recent_exclude   ,sadm_pid_timeout              ,\
    sadm_lock_timeout            ,sadm_max_logline              ,sadm_max_rchline              ,\
    sadm_smtp_server             ,sadm_smtp_port                ,\
    sadm_smtp_sender             ,sadm_gmpw

    if lib_debug > 4 :
        print ("Load Configuration file %s" % (cfg_file))

    # If configuration file can't be found, copy $SADMIN/.sadm_config to $SADMIN/sadmin.cfg
    # If none of these files can be found then exit to O/S.
    if  not os.path.exists(cfg_file) :                                  # If Config file not Exist
        if not os.path.exists(cfg_hidden) :                             # If Std Init Config ! Exist
            print("\nSADMIN Configuration file %s can't be found" % (cfg_file))
            print("Even the template file %s can't be found" % (cfg_hidden))
            print("Copy both files from another system to this server")
            print("Or restore the files from a backup & review the file content.\n")
        else :
            print("\nThe configuration file %s doesn't exist." % (cfg_file))
            print("Will continue using template configuration file %s" % (cfg_hidden))
            print("Please review the configuration file.")
            print("cp %s %s \n" % (cfg_hidden,cfg_file))                # Install Default cfg  file
            cmd =  "cp %s %s " % (cfg_hidden,cfg_file)                  # Copy Default cfg
            ccode, cstdout, cstderr = oscommand(cmd)
            if not ccode == 0 :
                print("\nCould not copy %s to %s" % (cfg_hidden,cfg_file))
                print("Script need a valid %s to run - Script aborted" % (cfg_file))
                print("Restore the file from a backup & review the file content.\n")
                sys.exit(1)
                
    # Open Configuration file
    try:
        cfg_file_fh= open(cfg_file,'r')                                 # Open Config File
    except (IOError, FileNotFoundError) as e:                           # If Can't open cfg file
        print("Error opening file %s" % (cfg_file))                     # write_log Log FileName
        print("Error Line No. : %d" % (inspect.currentframe().f_back.f_lineno)) # Print LineNo
        print("Function Name  : %s" % (sys._getframe().f_code.co_name)) # Get cur function Name
        print("Error Number   : %d" % (e.errno))                        # write_log Error Number
        print("Error Text     : %s" % (e.strerror))                     # write_log Error Message
        sys.exit(1)                                                     # Exit to O/S with Error
    except Exception as e:                                              # If Can't open cfg file
        print(e)                                                        # Print Error Message
        sys.exit(1)                                                     # Exit to O/S with Error

    # Read Configuration file and Save Options values
    for cfg_line in cfg_file_fh:                                        # Loop until on all servers
        wline        = cfg_line.strip()                                 # Strip CR/LF & Trail spaces
        if (wline[0:1] == '#' or len(wline) == 0) :                     # If comment or blank line
            continue                                                    # Go read the next line
        split_line   = wline.split('=')                                 # Split based on equal sign
        CFG_NAME   = split_line[0].upper().strip()                      # Param Name Uppercase Trim
        CFG_VALUE  = str(split_line[1]).strip()                         # Get Param Value Trimmed
        if lib_debug > 1 :                                              # Debug = write_log Line
            print("cfgline = ..." + CFG_NAME + "...  ..." + CFG_VALUE + "...")

        # Save Each Parameter found in Sadmin Configuration File
        if "SADM_MAIL_ADDR"                in CFG_NAME: sadm_mail_addr               = CFG_VALUE
        if "SADM_CIE_NAME"                 in CFG_NAME: sadm_cie_name                = CFG_VALUE
        if "SADM_ALERT_TYPE"               in CFG_NAME: sadm_alert_type              = int(CFG_VALUE)
        if "SADM_ALERT_GROUP"              in CFG_NAME: sadm_alert_group             = CFG_VALUE
        if "SADM_ALERT_REPEAT"             in CFG_NAME: sadm_alert_repeat            = int(CFG_VALUE)
        if "SADM_TEXTBELT_KEY"             in CFG_NAME: sadm_textbelt_key            = CFG_VALUE
        if "SADM_TEXTBELT_URL"             in CFG_NAME: sadm_textbelt_url            = CFG_VALUE
        if "SADM_HOST_TYPE"                in CFG_NAME: sadm_host_type               = CFG_VALUE.upper()
        if "SADM_SERVER"                   in CFG_NAME: sadm_server                  = CFG_VALUE
        if "SADM_DOMAIN"                   in CFG_NAME: sadm_domain                  = CFG_VALUE
        if "SADM_USER"                     in CFG_NAME: sadm_user                    = CFG_VALUE
        if "SADM_GROUP"                    in CFG_NAME: sadm_group                   = CFG_VALUE
        if "SADM_WWW_USER"                 in CFG_NAME: sadm_www_user                = CFG_VALUE
        if "SADM_WWW_GROUP"                in CFG_NAME: sadm_www_group               = CFG_VALUE
        if "SADM_SSH_PORT"                 in CFG_NAME: sadm_ssh_port                = int(CFG_VALUE)
        if "SADM_MAX_LOGLINE"              in CFG_NAME: sadm_max_logline             = int(CFG_VALUE)
        if "SADM_MAX_RCHLINE"              in CFG_NAME: sadm_max_rchline             = int(CFG_VALUE)
        if "SADM_NMON_KEEPDAYS"            in CFG_NAME: sadm_nmon_keepdays           = int(CFG_VALUE)
        if "SADM_RCH_KEEPDAYS"             in CFG_NAME: sadm_rch_keepdays            = int(CFG_VALUE)
        if "SADM_LOG_KEEPDAYS"             in CFG_NAME: sadm_log_keepdays            = int(CFG_VALUE)
        if "SADM_DBNAME"                   in CFG_NAME: sadm_dbname                  = CFG_VALUE
        if "SADM_DBHOST"                   in CFG_NAME: sadm_dbhost                  = CFG_VALUE
        if "SADM_DBPORT"                   in CFG_NAME: sadm_dbport                  = int(CFG_VALUE)
        if "SADM_RW_DBUSER"                in CFG_NAME: sadm_rw_dbuser               = CFG_VALUE
        if "SADM_RO_DBUSER"                in CFG_NAME: sadm_ro_dbuser               = CFG_VALUE
        if "SADM_BACKUP_NFS_SERVER"        in CFG_NAME: sadm_backup_nfs_server       = CFG_VALUE
        if "SADM_BACKUP_NFS_MOUNT_POINT"   in CFG_NAME: sadm_backup_nfs_mount_point  = CFG_VALUE
        if "SADM_BACKUP_DIF"               in CFG_NAME: sadm_backup_dif              = int(CFG_VALUE)
        if "SADM_BACKUP_INTERVAL"          in CFG_NAME: sadm_backup_interval         = int(CFG_VALUE)
        if "SADM_DAILY_BACKUP_TO_KEEP"     in CFG_NAME: sadm_daily_backup_to_keep    = int(CFG_VALUE)
        if "SADM_WEEKLY_BACKUP_TO_KEEP"    in CFG_NAME: sadm_weekly_backup_to_keep   = int(CFG_VALUE)
        if "SADM_MONTHLY_BACKUP_TO_KEEP"   in CFG_NAME: sadm_monthly_backup_to_keep  = int(CFG_VALUE)
        if "SADM_YEARLY_BACKUP_TO_KEEP"    in CFG_NAME: sadm_yearly_backup_to_keep   = int(CFG_VALUE)
        if "SADM_WEEKLY_BACKUP_DAY"        in CFG_NAME: sadm_weekly_backup_day       = int(CFG_VALUE)
        if "SADM_MONTHLY_BACKUP_DATE"      in CFG_NAME: sadm_monthly_backup_date     = int(CFG_VALUE)
        if "SADM_YEARLY_BACKUP_MONTH"      in CFG_NAME: sadm_yearly_backup_month     = int(CFG_VALUE)
        if "SADM_YEARLY_BACKUP_DATE"       in CFG_NAME: sadm_yearly_backup_date      = int(CFG_VALUE)
        if "SADM_REAR_NFS_SERVER"          in CFG_NAME: sadm_rear_nfs_server         = CFG_VALUE
        if "SADM_REAR_NFS_MOUNT_POINT"     in CFG_NAME: sadm_rear_nfs_mount_point    = CFG_VALUE
        if "SADM_REAR_BACKUP_TO_KEEP"      in CFG_NAME: sadm_rear_backup_to_keep     = int(CFG_VALUE)
        if "SADM_REAR_BACKUP_DIFF"         in CFG_NAME: sadm_rear_backup_dif         = int(CFG_VALUE)
        if "SADM_REAR_BACKUP_INTERVAL"     in CFG_NAME: sadm_rear_backup_interval    = int(CFG_VALUE)
        if "SADM_NETWORK1"                 in CFG_NAME: sadm_network1                = CFG_VALUE
        if "SADM_NETWORK2"                 in CFG_NAME: sadm_network2                = CFG_VALUE
        if "SADM_NETWORK3"                 in CFG_NAME: sadm_network3                = CFG_VALUE
        if "SADM_NETWORK4"                 in CFG_NAME: sadm_network4                = CFG_VALUE
        if "SADM_NETWORK5"                 in CFG_NAME: sadm_network5                = CFG_VALUE
        if "SADM_PID_TIMEOUT"              in CFG_NAME: sadm_pid_timeout             = int(CFG_VALUE)
        if "SADM_LOCK_TIMEOUT"             in CFG_NAME: sadm_lock_timeout            = int(CFG_VALUE)
        if "SADM_MONITOR_UPDATE_INTERVAL"  in CFG_NAME: sadm_monitor_update_interval = int(CFG_VALUE)
        if "SADM_MONITOR_RECENT_COUNT"     in CFG_NAME: sadm_monitor_recent_count    = int(CFG_VALUE)
        if "SADM_MONITOR_RECENT_EXCLUDE"   in CFG_NAME: sadm_monitor_recent_exclude  = CFG_VALUE
        if "SADM_SMTP_SERVER"              in CFG_NAME: sadm_smtp_server             = CFG_VALUE
        if "SADM_SMTP_PORT"                in CFG_NAME: sadm_smtp_port               = int(CFG_VALUE)
        if "SADM_SMTP_SENDER"              in CFG_NAME: sadm_smtp_sender             = CFG_VALUE
    cfg_file_fh.close()

    # Get Database User Password from .dbpass file (Read/Write Acc. 'sadmin' and 'squery' Read Only)
    if (sadm_host_type == "S"):         
        try:
            dbpass_file_fh = open(dbpass_file,'r')                      # Open DB Password File
        except (IOError, FileNotFoundError) as e:                       # If Can't open cfg file
            print("Error opening file %s" % (dbpass_file))              # write_log Log FileName
            print("Error Line No. : %d" % (inspect.currentframe().f_back.f_lineno)) # Print LineNo
            print("Function Name  : %s" % (sys._getframe().f_code.co_name)) # Get cur function Name
            print("Error Number   : %d" % (e.errno))                    # write_log Error Number
            print("Error Text     : %s" % (e.strerror))                 # write_log Error Message
            sys.exit(1)                                                 # Exit to O/S with Error
        except Exception as e:                                          # If Can't open cfg file
            print(e)                                                    # Print Error Message
            sys.exit(1)                                                 # Exit to O/S with Error
        for dbline in dbpass_file_fh :                                  # Loop until on all lines
            wline = dbline.strip()                                      # Strip CR/LF & Trail spaces
            if (wline[0:1] == '#' or len(wline) == 0) :                 # If comment or blank line
                continue                                                # Go read the next line
            if wline.startswith(sadm_rw_dbuser) :                       # LineStart with RW UserName
                split_line = wline.split(',')                           # Split Line based on comma
                sadm_rw_dbpwd = split_line[1]                           # Set DB R/W 'sadmin' Passwd
            if wline.startswith(sadm_ro_dbuser) :                       # Line begin with 'squery,'
                split_line = wline.split(',')                           # Split Line based on comma
                sadm_ro_dbpwd = split_line[1]                           # Set DB R/O 'squery' Passwd
        dbpass_file_fh.close()                                          # Close DB Password file
    else :
        sadm_rw_dbpwd  = ''                                             # Set DB R/W 'sadmin' Passwd
        sadm_ro_dbpwd  = ''                                             # Set DB R/O 'squery' Passwd


# If old unencrypted email account password file exist and on a SADMIN client remove the file.
    if os.path.isfile(gmpw_file_txt) and sadm_host_type == "S"  :
       os.remove(gmpw_file_txt)      

# If old unencrypted email account password file exist and on SADMIN server create an encrypted pwd.
    if os.path.isfile(gmpw_file_txt) and sadm_host_type == "S" :
        try: 
            with open(gmpw_file_txt) as f: 
                wpwd = f.readline().strip()
                byte_pw       = wpwd.encode('ascii')
                base64_bytes  = base64.b64encode(byte_pw)
                base64_string = base64_bytes.decode('ascii')
            os.remove(gmpw_file_b64)      
            fpw = open(gmpw_file_b64,'w')                                          
            fpw.write (base64_string)                                               
            fpw.close()                                                        
            os.chmod(gmpw_file_b64, 0o644)
        except (IOError, FileNotFoundError) as e:                       # Can't open SMTP Pwd file
            print("Error creating a new password file %s" % (gmpw_file_b64))
            print("Error Line No. : %d" % (inspect.currentframe().f_back.f_lineno)) # Print LineNo
            print("Function Name  : %s" % (sys._getframe().f_code.co_name)) # Get cur function Name
            print("Error Number   : %d" % (e.errno))                    # write_log Error Number
            print("Error Text     : %s" % (e.strerror))                 # write_log Error Message
            sys.exit(1)    

# Set Email Account password from encrypted email account password file.
    sadm_gmpw=""
    try : 
        if os.path.exists(gmpw_file_b64):
            with open(gmpw_file_b64) as f:
                 wpwd = f.readline().strip()
                 base64_bytes = wpwd.encode('ascii')
                 data_bytes   = base64.b64decode(base64_bytes)
                 sadm_gmpw    = data_bytes.decode('ascii')
    except (IOError, FileNotFoundError) as e:                       # Can't open SMTP Pwd file
        print("Error opening smtp encrypted password file %s" % (gmpw_file_b64)) 
        print("Error Line No. : %d" % (inspect.currentframe().f_back.f_lineno)) # Print LineNo
        print("Function Name  : %s" % (sys._getframe().f_code.co_name)) # Get cur function Name
        print("Error Number   : %d" % (e.errno))                    # write_log Error Number
        print("Error Text     : %s" % (e.strerror))                 # write_log Error Message
        sys.exit(1)    
    return 


# --------------------------------------------------------------------------------------------------
def oscommand (command : str) :
    
    """ 
        Execute the O/S command received.
    
    Args:
        command (str): The command to execute.

    Returns:
        returncode (int) :  0 When command executed with no error.
                            1 When error occurred when executing the command
        out (str)        :  Contain the stdout of the command executed
        err (str)        :  Contain the stderr of the command executed
    """
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out = p.stdout.read().strip().decode()
    err = p.stderr.read().strip().decode()
    returncode = p.wait()

    if lib_debug > 8 :
        write_log ("oscommand: command       : %s" % (command))
        write_log ("oscommand: stdout is     : %s" % (out))
        write_log ("oscommand: stderr is     : %s" % (err))
        write_log ("oscommand: returncode is : %s" % (returncode))
    return (returncode,out,err)



# --------------------------------------------------------------------------------------------------
# Function that return the Mac Address of the received IP address.
def get_mac_address(ip_address):

    """ 
        get_mac_address (ip_address) 
        Return the Mac Address of the IP received.
        
        Args:
            ip_address (str) : IP address to get the mac address.
        Returns:
            The mac address of the IP or blank "" if not found.
    """

    ccode, cstdout, cstderr = oscommand("arp -a %s" % (ip_address))
    if 'no match found' in cstdout : 
        mac_address = ""  
    else :
        mac_address = cstdout.split()[3]
    if mac_address == "<incomplete>" : mac_address = ""
    return mac_address



# --------------------------------------------------------------------------------------------------
# Function will Sleep for a number of seconds.
#   - 1st parameter is the time to sleep in seconds.
#   - 2nd Parameter is the interval in seconds, user will be showed the elapse number of seconds.
def sleep(sleep_time=60, sleep_interval=15): 
    
    """ 
        - When sleep time is 60 seconds and sleep_interval is 15 seconds, write a 
          string similar to this "0...15...30...45...60". 
        - Example: 
            Could be used to let user know when server should come back after a reboot.
        
        Args:
            sleep_time (int)        : Number of seconds to sleep.
            sleep_interval (int)    : Interval in seconds to show user sleep time left.
        Returns:
            None
    """

    time_left = sleep_time                                              # Time Sleep in Seconds
    print ("%s" % time_left, end = '', flush=True)                      # Print Time & Flush Output
    while time_left > 1 :                                               # Loop Sleep time Exhaust
        time.sleep(sleep_interval)                                      # Sleep Interval Nb. Seconds
        time_left -= sleep_interval                                     # Decr. interval to timeleft
        print ("...%s" % time_left, end = '', flush=True)               # Print Nb. Sec. Left





# --------------------------------------------------------------------------------------------------
def lock_system(fname, errmsg=True ) :

    """  
        Create a system 'lock_file' for the received system name.
        This function is used to create a 'lock_time' for the requested system.
        When the lock file exist "${SADMIN}/tmp/$(hostname -s).lock" for a system, 
        no error or warning is reported (No alert, No notification) to the user 
        (on monitor screen) until the 'lock_file'is removed, either by calling 
        "unlock_systemfunction or when the lock file time stamp exceed the number of 
        seconds set by 'lock_timeout'. The "check_system_lockockock()" function will automatically 
        remove the 'lock_file' when it is expired.
        
    Args: 
        fname : Name of the system you want to remove the lock file (hostname -s, not FQDN).
                The full path name of the lock file is "$SADMIN/tmp/$(hostname -s).lock"

    Args Optionnal: 
        errmsg: Default value is True
                Use if don't want any message or error message written to log or screen.
                Base your logic only on the return value and built and display your own message.

    """

    fexit_code = True                                                   # Default return value
    lock_file = dir_base + '/' + fname + '.lock'                         # Lock File Name
    if os.path.isfile(lock_file):                                       # If lock file already exist
        if errmsg : write_err("[ WARNING ] System '%s' already lock." % (fname))                                     
        return(True)

    try:
        f = open(lock_file,"w")                                         # Open lock_file for writing
        now = datetime.datetime.now()                                   # Get current Time
        fline = pn,now.strftime("%Y%m%d%H%M%S")                         # Lock file content
        f.write ("%s\n" % str((fline)))                                 # Write Script name and date
    except IOError:
        if errmsg : 
           write_err ("[ ERROR ] Locking system '%s' - Fail to create lock file '%s'" % (fname,lock_file))
        fexit_code = False                                                  # Set Error return code
    finally:
        f.close()                                                       # Close Lock file
    return(fexit_code)                                                  # Return to caller



# --------------------------------------------------------------------------------------------------
def unlock_system(fname ,errmsg=True): 

    """ 
        Remove the lock file for the received system host name.
        When the lock file exist "${SADMIN}/tmp/$(hostname -s).lock" for a system, no error or 
        warning is reported (No alert, No notification) to the user (on monitor screen) until the 
        lock file is remove.
        When the lock file time stamp exceed the number of seconds set by 'lock_timeout' variable
        then 'lock_file' will be automatically by "check_system_lock()" function.
       
        Args: 
            fname : Name of the system you want to remove the lock file (hostname -s, not FQDN).
                    The full path name of the lock file is "$SADMIN/tmp/$(hostname -s).lock"

        Args Optionnal: 
            errmsg: Default value is True
                    Use if don't want any message or error message written to log or screen.
                    Base your logic only on the return value and built and display your own message.

        Return Value : 
            Always return True, even the lock file doesn't exist
    """

    fexit_code = 0    
    lock_file = dir_base + '/' + fname + '.lock'                         # Lock File Name
    if os.path.isfile(lock_file):
        try: 
            os.remove(lock_file)
        except FileNotFoundError:
            if errmsg : write_err("System '%s' already unlock." % fname)       
    return(True)



# --------------------------------------------------------------------------------------------------
def check_system_lock(fname, errmsg=True):

    """ 
        This function is used to check if a 'lock_file' exist for the system name received.
        When the lock file exist "${SADMIN}/tmp/$(hostname -s).lock" for a system, no 
        monitoring error or warning is reported (No alert, No notification) to the user
        until the lock file is deleted.
 
        If the lock file exist, this function check the creation date & time of it.
        When the lock file time stamp exceed the number of seconds set by 'lock_timeout' 
        then 'lock_file' file is automatically remove by this function and exit with a return
        code of 0, as if the lock file didn't exist.
       
        Args: 
            fname : Name of the system you want to remove the lock file (hostname -s, not FQDN).
                    The full path name of the lock file is "$SADMIN/tmp/$(hostname -s).lock"

        Args Optionnal: 
            errmsg: Default value is True
                    Use if don't want any message or error message written to log or screen.
                    Base your logic only on the return value and built and display your own message.

        Return Value : 
            False) System is not lock.
            True)  System is lock.
    """
    
    fexit_code = 0    
    lock_file = dir_base + '/' + fname + '.lock'                        # Lock File Name
    if os.path.isfile(lock_file):                                       # CHeck if lock File Exist
        epoch_creation = int(os.path.getctime(lock_file))               # Get Epoch Creation time
        epoch_now = int(time.time())                                    # Get Current epoch time
        file_age = int(epoch_now - epoch_creation)                      # Nb. Sec. that file exist
        if file_age > lock_timeout :                                    # Greater that Max. TTL
            if lib_debug > 4 :
                if errmsg : write_log("System '%s' is lock for more than %d seconds." % (fname,file_age))
                if lock_timeout != 0 :
                    if errmsg : 
                       write_log("Unlocking system '%s'." % (fname))
                       write_log("We now restart to monitor this system as usual.")
                    unlock_system(fname) 
                else: 
                    if errmsg : 
                       write_log("The 'sa.lock_timeout' is set to 0, meaning system will remain lock.")
                       write_log("System %s will remain lock until the lock file (%s) is remove." % (fname,lock_file))
        else:
            if errmsg : 
                write_log("[ WARNING ] System '%s' is currently lock. "% (fname))
                write_log("System will unlock in %d seconds." % (lock_timeout-file_age))
                write_log("Maximum lock time allowed is %d seconds." % (lock_timeout))
            return True
    return False 




# --------------------------------------------------------------------------------------------------
def get_hostname():
    
    """ 
        Return the current system hostname 

        Args:
            None    

        Returns:
            whostname (str) : Host name of the current system.
    """ 

    #cstdout="unknown"
    #if (get_ostype() == "LINUX" or get_os_type() == "DARWIN") :          
    #    ccode, cstdout, cstderr = oscommand("hostname -s")              # Execute O/S CMD
    #if self.os_type == "AIX" :                                          # Under AIX
    #    ccode, cstdout, cstderr = oscommand("hostname")                 # Execute O/S CMD
    #if self.os_type == "WINDOWS" :                                      # Under Windows
    #    cstdout = platform.node().split('.')[0].strip()                 
    #whostname=cstdout
    whostname = platform.node().split('.')[0].strip()                 
    return(whostname)



# --------------------------------------------------------------------------------------------------
def get_host_ip():
    
    """ 
        Return the current system main ip address (v4)

        Args:
            None    

        Returns:
            wip (str) : The main IP address of the current system.
    """ 

    try: 
        whost = socket.gethostbyname(phostname)
    except (socket.gaierror, NameError) as e:
        print("Couldn't get the IP address of '%s'." % (whost))
        print("\n%s" % (e))
        whost = ""
    return whost




# --------------------------------------------------------------------------------------------------
def get_release() :

    """ 
        Return SADMIN Release Version Number from '$SADMIN/cfg/.release' file.

        Args:
            None    

        Returns:
            wrelease (str) : Release version of SADMIN
    """

    wrelease="00.00"
    if os.path.exists(rel_file):
        with open(rel_file) as f:
            wrelease = f.readline().strip()
    return wrelease




# --------------------------------------------------------------------------------------------------
def touch_file (filename : str) :
    
    """ 
        Create an empty file named using the filename received.
    
        Args:
            filename (str)   :  File to create.

        Returns:
            resultCode (int) :  0 When command executed with no error.
                                1 When error occurred when executing the command
    """

    try: 
        file_obj  = open(filename, "w")
        file_obj.close()
        rc = 0
    except : 
        rc = 1
    return(rc)





# --------------------------------------------------------------------------------------------------
def show_version(pver):
    
    """ 
        Show different information about script environment
            - Version of script & SADMIN library
            - O/S name with is version 
            - Function mainly use for cmdline option [-v]
        Args:
            None
        Return:
            None
    """

    print ("Script Name %s - Version %s" % (os.path.basename(sys.argv[0]),pver))
    print ("SADMIN Shell Library Version %s" % (lib_ver))
    print ("O/S is %s - Version %s"% (get_osname(),get_osversion()))
    print ("Kernel Version %s \n" % (get_kernel_version()))
    return()




# --------------------------------------------------------------------------------------------------
def get_domainname():
    
    """ 
        Return the current system domain name.
    
        Args:
            None
        Return (str):
            Return domain name of the current host.
    """ 

    whostip = socket.gethostbyname(phostname)
    cmd = "host %s  | awk '{print $NF}' | cut -d. -f2-3" % whostip 
    ccode, cstdout, cstderr = oscommand(cmd)
    wdomainname=cstdout
    if wdomainname == "" or wdomainname == phostname : wdomainname = sadm_domain
    return wdomainname






# --------------------------------------------------------------------------------------------------
def get_fqdn():
    
    """ 
        Return the fully qualified domain name of the current host.
    
        Args:
            None

        Return (str):
            Return the fully qualified domain name of the current host.
    """ 
    host_fqdn = "%s.%s" % (phostname,get_domainname())
    return (host_fqdn)






# --------------------------------------------------------------------------------------------------
def get_ostype():
    
    """ 
        Return the O/S type (Linux, Aix, Darwin, Windows) in uppercase.

        Args:
            None
        Return:
            Return The OS Type (LINUX, AIX, DARWIN, WINDOWS)
            Result are always returned in Uppercase. 
            If couldn't determine O/S type, an empty string is returned.
    """
    
    try: 
        wostype=platform.system().upper()   
    except: 
        write_log ("[ ERROR ] Couldn't get the O/S type.")
        wostype="" 
    return(wostype)






# --------------------------------------------------------------------------------------------------
def get_arch():
    
    """ 
        Return the system architecture (i686,armv6l,armv7l,AMD64,x86_64,...)

        Args:
            None
        Return:
            Return the system architecture (i686,armv6l,armv7l,AMD64,x86_64,...)
    """
    
    try: 
        warch=platform.machine() 
    except: 
        funcname = sys._getframe(  ).f_code.co_name                     # Get Function Name
        wlineno = sys._getframe(  ).f_lineno                            # Get Current Line No
        write_log ("[ ERROR ] In function %s line %d." % (funcname,wlineno))
        write_log ("Couldn't get the system architecture.")
        warch="" 
    return(warch)





# --------------------------------------------------------------------------------------------------
def get_kernel_bitmode():
    
    """ 
        Return if running 32 or 64 Bits Kernel/Windows version

        Args:
            None
        Return:
            bits (int) : Return 32 or 64
    """

    ostype=get_ostype()                                                 # AIX,WINDOWS,LINUX,DARWIN
    wbit = 64                                                           # Default return value
    if ostype == "LINUX" :                                              # Under Linux
        ccode, wbit, cstderr = oscommand("getconf LONG_BIT")
    if ostype == "AIX" :                                                # Under AIX
       ccode, wbit, cstderr  = oscommand("getconf KERNEL_BITMODE")
    if ostype == "DARWIN" :                                             # Mac OS
       wbit = 64                                                        # MacOS Now only 64 bits
    if ostype == "WINDOWS" :                                            # Windows
       wbit = platform.architecture()[0][0:2]                           # Return 32 or 64 
    return(wbit)




#---------------------------------------------------------------------------------------------------
def get_osname(): 

    """ 
        Return O/S name in uppercase 

        Args:
            None
        Return: 
            Ex: REDHAT, UBUNTU, AIX, DARWIN, DEBIAN, RASPBIAN, ...
            Result are always Returned In Uppercase 
    """

    ostype=get_ostype()                                              # AIX,WINDOWS,LINUX,DARWIN,JAVA
    if ostype == "DARWIN":
        wcmd = "sw_vers -productName | tr -d ' '"
        ccode, cstdout, cstderr = oscommand(wcmd)
        osname=cstdout
    if ostype == "LINUX":
        if cmd_lsb_release != "" :
            wcmd = "%s %s" % (cmd_lsb_release," -si")
            ccode, cstdout, cstderr = oscommand(wcmd)
            osname=cstdout.upper()
        else:
            osname = os_dict['ID'].upper()
    if osname == "REDHATENTERPRISESERVER" : osname="REDHAT"
    if osname == "RHEL"                   : osname="REDHAT"
    if osname == "REDHATENTERPRISEAS"     : osname="REDHAT"
    if osname == "REDHATENTERPRISE"       : osname="REDHAT"
    if osname == "CENTOSSTREAM"           : osname="CENTOS"
    if osname == "ROCKYLINUX"             : osname="ROCKY"
    if osname == "ALMALINUX"              : osname="ALMA"
    if osname == "LINUXMINT"              : osname="MINT"
    #
    if ostype == "AIX" :
        osname="AIX"
    #
    if ostype == "WINDOWS" :
        osname = "%s %s" % (platform.system(), platform.release())
    # 
    if os.path.exists("/usr/bin/raspi-config") : osname = "RASPBIAN"
    return (osname.upper())





# --------------------------------------------------------------------------------------------------
def get_kernel_version():

    """ 
        Return Kernel Running Version

        Args:
            None
        Return: 
            Return the kernel version as a string
    """
    
    ostype=get_ostype()                                             # Return WINDOWS,LINUX,DARWIN
    cstdout = "unknown"
    if ostype == "LINUX" :                                    # Under Linux
#        ccode, cstdout, cstderr = oscommand("uname -r | cut -d. -f1-3")
        ccode, cstdout, cstderr = oscommand("uname -r")
    if ostype == "AIX" :                                      # Under AIX
        ccode, cstdout, cstderr = oscommand("uname -r")
    if ostype == "DARWIN" :                                   # Under MacOS
        ccode, cstdout, cstderr = oscommand("uname -mrs | awk '{ print $2 }'")
    if ostype == "WINDOWS" :                                   # Under Windows
        cstdout = platform.version()
    wkver=cstdout
    return wkver




# --------------------------------------------------------------------------------------------------
def get_nb_cpu():
    
    """ 
        Return The Number Of usable CPU on the system.

        Args:
            None
        Return: 
            Number of usable CPU on System (Returns None if undetermined).
    """

    #ostype=get_ostype()                                                 # WINDOWS,LINUX,DARWIN,AIX
    #os.cpu_count()
    #if ostype == "LINUX" :                                              # Under Linux
    #    ccode, cstdout, cstderr = oscommand("grep '^physical id' /proc/cpuinfo| wc -l| tr -d ' '")
    #if ostype == "AIX" :                                                # Under AIX
    #    ccode, cstdout, cstderr = oscommand("lsdev -C -c processor | wc -l | tr -d ' '")
    #if ostype == "DARWIN" :                                             # Under MacOS
    #    ccode, cstdout, cstderr = oscommand("sysctl -n hw.ncpu")
    #if ostype == "WINDOWS" :     
    #    cstdout = multiprocessing.cpu_count()                           # Usable Nb. of CPU Windows
    #nbcpu = cstdout
    return(os.cpu_count())
        



# --------------------------------------------------------------------------------------------------
def get_nb_core_per_socket():
    
    """ 
        Return the number of core per socket(s) on the system.

        Args:
            None
        Return: 
            Number of core per socket(s) on the system.
    """

    ostype=get_ostype()                                                 # WINDOWS,LINUX,DARWIN,AIX    
    if ostype == "LINUX" :                                              # Under Linux
       ccode,cstdout,cstderr = oscommand("lscpu |grep '^Core(s) per socket' |awk -F: '{print $2}' |tr -d ' '")
    try : 
        nbcore = int(cstdout)
    except Exception:
        nbcore = 0 
    return(nbcore)
        



# --------------------------------------------------------------------------------------------------
def get_nb_socket():
    
    """ 
        Return the number of CPU socket(s) on the system.

        Args:
            None
        Return: 
            Number of CPU socket(s) on the system.
    """

    ostype=get_ostype()                                                 # WINDOWS,LINUX,DARWIN,AIX    
    if ostype == "LINUX" :                                              # Under Linux
       ccode,cstdout,cstderr = oscommand("lscpu |grep '^Socket(s)' |awk -F: '{print $2}' |tr -d ' '")
    try: 
        nbsocket = int(cstdout)
    except Exception:
        nbsocket = 0 
    return(nbsocket)
        


# --------------------------------------------------------------------------------------------------
def get_nb_thread_per_core():
    
    """ 
        Return the number of CPU thread(s) per core on the system.

        Args:
            None
        Return: 
            Number of CPU threads(s) per core on the system.
    """

    ostype=get_ostype()                                                 # WINDOWS,LINUX,DARWIN,AIX    
    if ostype == "LINUX" :                                              # Under Linux
       ccode,cstdout,cstderr = oscommand("lscpu |grep '^Thread(s) per core' |awk -F: '{print $2}' |tr -d ' '")
    try: 
        nbthread = int(cstdout)
    except Exception:
        nbthread = 0 
    return(nbthread)
        



# --------------------------------------------------------------------------------------------------
def get_osversion() :
    
    """ 
        This Return The O/S (Distribution) Version Number (ex: 8.5 or 11)

        Args:
            None
        Return: the full O/S version number 
    """

    ostype=get_ostype()                                             # Return WINDOWS,LINUX,DARWIN
    osversion="0.0"                                                 # Default Value
    if ostype == "LINUX" :
        if cmd_lsb_release != "" :
            wcmd = "%s %s" % (cmd_lsb_release," -sr")
            ccode, cstdout, cstderr = oscommand(wcmd)
            osversion=cstdout
        else:
            osversion=os_dict['VERSION_ID']
    if ostype == "DARWIN" :
        cmd = "sw_vers -productVersion"
        ccode, cstdout, cstderr = oscommand(cmd)
        osversion=cstdout
    if ostype == "AIX" :
        ccode, cstdout, cstderr = oscommand("uname -v")
        maj_ver=cstdout
        ccode, cstdout, cstderr = oscommand("uname -r")
        min_ver=cstdout
        osversion="%s.%s" % (maj_ver,min_ver)
    return osversion



# --------------------------------------------------------------------------------------------------
def get_osminorversion() :
    
    """ 
        Return The Os (Distribution) Minor Version Number

        Args:
            None
        Return: 
            Ex: REDHAT, UBUNTU, AIX, DARWIN, DEBIAN, RASPBIAN, ...
            Result are always Returned In Uppercase 
    """    

    ostype=get_ostype()                                             # Return WINDOWS,LINUX,DARWIN
    #
    if ostype == "LINUX" :
        if cmd_lsb_release != "" :        
            wcmd = "%s %s" % (cmd_lsb_release," -sr")
            ccode, cstdout, cstderr = oscommand(wcmd)
            osversion=str(cstdout)
            pos=osversion.find(".")
            if pos == -1 :
                osminorversion=""
            else:
                osminorversion=osversion.split('.')[1]
        else: 
            osversion=str(os_dict['VERSION_ID'])
            pos=osversion.find(".")
            if pos == -1 :
                osminorversion=""
            else:
                osminorversion=osversion.split('.')[1]
    #
    if ostype == "AIX" :
        ccode, cstdout, cstderr = oscommand("uname -r")
        osminorversion=cstdout
    #
    if ostype == "DARWIN":
        wcmd = "sw_vers -productVersion | awk -F '.' '{print $2}'"
        ccode, cstdout, cstderr = oscommand(wcmd)
        osminorversion=cstdout
    #
    return osminorversion



# --------------------------------------------------------------------------------------------------
def get_osmajorversion() :
    
    """ 
        Return The Os (Distribution) Major Version number.

        Args:
            None
        Return: 
            str : Contain the major distribution version number.
           
    """ 

    ostype=get_ostype()                                             # Return WINDOWS,LINUX,DARWIN
    if ostype == "LINUX" :
        if cmd_lsb_release != "" :
            wcmd = "%s %s" % (cmd_lsb_release," -sr")
            ccode, cstdout, cstderr = oscommand(wcmd)
            osversion=cstdout
            osmajorversion=osversion.split('.')[0]
        else :
            osversion=os_dict['VERSION_ID']
            osmajorversion=osversion.split('.')[0]
    if ostype == "AIX" :
        ccode, cstdout, cstderr = oscommand("uname -v")
        osmajorversion = cstdout
    if ostype == "DARWIN":
        wcmd = "sw_vers -productVersion | awk -F '.' '{print $1 \".\" $2}'"
        ccode, cstdout, cstderr = oscommand(wcmd)
        osmajorversion=cstdout
    if ostype == "WINDOWS":
        osmajorversion = platform.release()
    return (osmajorversion)




# --------------------------------------------------------------------------------------------------
def get_oscodename() :
    """ 
        Return The Os Project Code Name

        Args:
            None
        Return: 
            str : Contain the major distribution version number.
           
    """   
 
    oscodename=""
    ostype=get_ostype()                                                 # AIX,WINDOWS,LINUX,DARWIN
    #print ("ostype = %s major is ...%s..." % (ostype,get_osmajorversion()))
    if ostype == "DARWIN":
        if (get_osmajorversion() == "10.0")  : oscodename="Cheetah"
        if (get_osmajorversion() == "10.1")  : oscodename="Puma"
        if (get_osmajorversion() == "10.2")  : oscodename="Jaguar"
        if (get_osmajorversion() == "10.3")  : oscodename="Panther"
        if (get_osmajorversion() == "10.4")  : oscodename="Tiger"
        if (get_osmajorversion() == "10.5")  : oscodename="Leopard"
        if (get_osmajorversion() == "10.6")  : oscodename="Snow Leopard"
        if (get_osmajorversion() == "10.7")  : oscodename="Lion"
        if (get_osmajorversion() == "10.8")  : oscodename="Mountain Lion"
        if (get_osmajorversion() == "10.9")  : oscodename="Mavericks"
        if (get_osmajorversion() == "10.10") : oscodename="Yosemite"
        if (get_osmajorversion() == "10.11") : oscodename="El Capitan"
        if (get_osmajorversion() == "10.12") : oscodename="Sierra"
        if (get_osmajorversion() == "10.13") : oscodename="High Sierra"
        if (get_osmajorversion() == "10.14") : oscodename="Mojave"
        if (get_osmajorversion() == "10.15") : oscodename="Catalina"
        if (get_osmajorversion()[0:3] == "11.")  : oscodename="Big Sur"
        if (get_osmajorversion()[0:3] == "12.")  : oscodename="Monterey"
        if (get_osmajorversion()[0:3] == "13.")  : oscodename="Ventura"
        #xstr='SOFTWARE LICENSE AGREEMENT FOR macOS'
        #xfile='/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf'
        #wcmd='grep  "$xstr" "$xfile" | awk -F "macOS "  { print $NF} '
        #ccode, oscodename, cstderr = oscommand(wcmd)
    if ostype == "LINUX":
        if cmd_lsb_release != "" : 
            wcmd = "%s %s" % (cmd_lsb_release," -sc")
            ccode, cstdout, cstderr = oscommand(wcmd)
            oscodename=cstdout.upper()
        else:
            try: 
                oscodename=os_dict['VERSION_CODENAME']
            except KeyError as e:     
                oscodename=""
    #
    if ostype == "AIX" :
        oscodename="IBM AIX"
    #
    if ostype == "WINDOWS" :
        oscodename = "%s %s" % (platform.system(), platform.release())
    #
    return (oscodename)




# --------------------------------------------------------------------------------------------------
def locate_command(cmd) :
    
    """ 
        Return the full path of the O/S command received.
        If command can't be found then an empty string is returned.
        
        Args:
            cmd (str)       :   Name of the command to locate on system.

        Returns:
            cmd_path (str)  :   Full path of the command or "" if not found.
    """

    cmd_path = shutil.which(cmd)
    if cmd_path == None : 
        cmd_path='' 
    return(cmd_path)                                                   





# --------------------------------------------------------------------------------------------------
def get_epoch_time():

    """ 
        Return Current Epoch Time as an integer (no milliseconds)
        
        Args:
            None

        Return:
            time (int) : Return current epoch time
    """

    return int(time.time())





# --------------------------------------------------------------------------------------------------
def epoch_to_date(wepoch : int):
    
    """ 
        Return a string with the format 'YYYY.MM.DD HH:MM:SS' based on the Epoch time received.
        
        Args:
            wepoch (int):   Epoch time to convert to a date and time format. 

        Return:
            wdate (str) :   Return date of the epoch time received 
                            (Example of date returned '2021.10.29 14:37:38')
    """

    ws = time.localtime(int(wepoch))
    wdate = "%04d.%02d.%02d %02d:%02d:%02d" % (ws[0],ws[1],ws[2],ws[3],ws[4],ws[5])
    return(wdate)





# --------------------------------------------------------------------------------------------------
def date_to_epoch(wdate : str) -> int:
    
    """ 
        Return the epoch time of the date received ('YYYY.MM.DD HH:MM:SS')
        
        Args:
            wdate (str) :   Date to convert to a epoch time.
                            Date got to be in format 'YYYY.MM.DD HH:MM:SS'
                            (Example of date to convert '2021.10.29 14:37:38')

        Return:
            wepoch (int):   Epoch time of the date received (with no milliseconds)
    """
    pattern = '%Y.%m.%d %H:%M:%S'
    wepoch = int(time.mktime(time.strptime(wdate, pattern)))
    return wepoch




# --------------------------------------------------------------------------------------------------
def elapse_time(wdate1 : str ,wdate2 : str) -> str:
    
    """ 
        Calculate elapse time between date1 (YYYY.MM.DD HH:MM:SS) and date2 (YYYY.MM.DD HH:MM:SS)
        Date 1 MUST be greater than date 2  (wdate1 = End date/time,  wdate2 = Start date/time )
        
        Args:
            wdate1 (str) :  End date/time of the process.
                            Date got to be in format 'YYYY.MM.DD HH:MM:SS'
            wdate2 (str) :  Start date/time of the process.
                            Date got to be in format 'YYYY.MM.DD HH:MM:SS'

        Return:
            welapse (str):  Return the elapse time in hours, minutes and seconds 'HH:MM:SS'.
                            (Ex : '03:45:54') 
    """

    whour=00 ; wmin=00 ; wsec=00                                        # Initialize return value
    epoch_start = date_to_epoch(wdate2)                                 # Get Epoch for Start Time
    epoch_end   = date_to_epoch(wdate1)                                 # Get Epoch for End Time
    epoch_elapse = epoch_end - epoch_start                              # Substract End - Start time

    # Calculate number of hours (1 hr = 3600 Seconds)
    if epoch_elapse > 3599 :                                            # If nb Sec Greater than 1Hr
        whour = epoch_elapse / 3600                                     # Calculate nb of Hours
        epoch_elapse = epoch_elapse - (whour * 3600)                    # Sub Hr*Sec from elapse

    # Calculate number of minutes 1 Min = 60 Seconds)
    if epoch_elapse > 59 :                                              # If more than 1 min left
        wmin = epoch_elapse / 60                                        # Calc. Nb of minutes
        epoch_elapse = epoch_elapse - (wmin * 60)                       # Sub Min*Sec from elapse

    wsec = epoch_elapse                                                 # left is less than 60 sec
    welapse= "%02d:%02d:%02d" % (whour,wmin,wsec)                       # Format Result
    return(welapse)                                                     # Return Result to caller





# --------------------------------------------------------------------------------------------------
def get_serial():
    
    """ 
        Return system board serial number 
        
        Args:
            None

        Return:
            serial (str):    Return the system board serial number
    """

    ostype = sys.platform.upper()
    if "DARWIN" in ostype:
        command = "ioreg -l | grep IOPlatformSerialNumber"
    elif "WINDOWS" in ostype:
        command = "wmic bios get serialnumber"
    elif "LINUX" in ostype:
        if get_osname() == "RASPBIAN" :
            command = "cat /sys/firmware/devicetree/base/serial-number; echo" 
        else:
            command = "cmd_dmidecode -s baseboard-serial-number"
    try: 
        ccode,cstdout,cstderr = oscommand("%s" % (command)) 
        if ccode == 0 : 
            wserial = cstdout                              # Save command Path when found
        else:
            wserial = ""  
    except Exception: 
        write_err("Error trying to get system board serial number")
        write_err(e)
        wserial = ""
    return(wserial)





# --------------------------------------------------------------------------------------------------
def load_cmd_path(): 

    """ 
        Function tries to locate every command that the SADMIN tools library or scripts may used.  
        If some of them are not present, some of the functions may not report proper information.
        It is recommended to install any missing command.

        Args:
            None

        Returns:
            Boolean :   True if all requirements are met.
                        False if one or more requirements are missing.
    """ 

    global \
        cmd_ssh         ,   cmd_lsb_release ,   cmd_dmidecode   ,   cmd_bc          ,\
        cmd_fdisk       ,   cmd_perl        ,   cmd_locate      ,   cmd_which       ,\
        cmd_nmon        ,   cmd_lscpu       ,   cmd_inxi        ,   cmd_parted      ,\
        cmd_ethtool     ,   cmd_curl        ,   cmd_mutt        ,   cmd_rrdtool     

    requisites_status=True                                              # Assume Requirement all Met
    ostype=get_ostype()                                                 # AIX,WINDOWS,LINUX,DARWIN
    if ostype == "WINDOWS" : return(requisites_status)                  # Not used on Windows
    if not os.path.exists(cmd_which)  :                                 # Command 'which' is present
        write_err("[ERROR] The command 'which' couldn't be found")      # is not available
        write_err("        This command is needed by the SADMIN tools") # If which is not available
        write_err("        Please install it and re-run this script")   # We will ask the user to
        write_err("        Script Aborted")                             # install it & abort script
        requisites_status=False                                         # Requirement not Met
        return(requisites_status)
    
    # Commands available only on Linux
    if (ostype == "LINUX"):                                             # On Linux Only
        cmd_fdisk    = locate_command('fdisk')                          # Locate fdisk command
        if cmd_fdisk       == "" : requisites_status=False              # if blank didn't find it
        cmd_dmidecode       = locate_command('dmidecode')               # Locate dmidecode command
        if cmd_dmidecode   == "" : requisites_status=False              # if blank didn't find it
        cmd_parted          = locate_command('parted')                  # Locate the parted command
        if cmd_parted      == "" : requisites_status=False              # if blank didn't find it
        cmd_lscpu           = locate_command('lscpu')                   # Locate the lscpu command
        if cmd_lscpu       == "" : requisites_status=False              # if blank didn't find it
        cmd_inxi            = locate_command('inxi')                    # Locate the inxi command
        if cmd_inxi        == "" : requisites_status=False              # if blank didn't find it
        cmd_lsb_release     = locate_command('lsb_release')             # Locate lsb_release command
        if cmd_lsb_release == "" : requisites_status=False              # if blank didn't find it

    # Commands that should be on every Unix supported platform
    cmd_bc       = locate_command('bc')                                 # Locate bc command
    if cmd_bc    == "" : requisites_status=False                        # if blank didn't find it
    cmd_ssh      = locate_command('ssh')                                # Locate the SSH command
    if cmd_ssh   == "" : requisites_status=False                        # If blank didn't find it
    cmd_perl     = locate_command('perl')                               # Locate the perl command
    if cmd_perl  == "" : requisites_status=False                        # if blank didn't find it
    cmd_nmon     = locate_command('nmon')                               # Locate the nmon command
    if cmd_nmon  == "" : requisites_status=False                        # if blank didn't find it
    cmd_ethtool  = locate_command('ethtool')                            # Locate the ethtool command
    if cmd_ethtool == "" : requisites_status=False                      # if blank didn't find it
    cmd_mutt     = locate_command('mutt')                               # Locate the mutt command
    if cmd_mutt  == "" : requisites_status=False                        # if blank didn't find it
    cmd_curl     = locate_command('curl')                               # Locate the curl command
    if cmd_curl  == "" : requisites_status=False                        # if blank didn't find it
    cmd_rrdtool  = locate_command('rrdtool')                            # Locate the rrdtool command
    if cmd_rrdtool == "" : requisites_status=False                      # if blank didn't find it

    return(requisites_status)                                           # Requirement Met True/False




# --------------------------------------------------------------------------------------------------
def db_close():

    """ 
        Close the Database.
        
        Args:            
            None 
    
        Returns: (db_err)
            db_err (int)    :   Return 0 mean database is closed (Default).
                                Return 1 when error closing connection with database.
    """    
    global db_conn,db_cur
    db_err = 0                                                          # Set default return value

    # Connection.open field will be 1 if the connection is open and 0 otherwise.
    if not db_conn.open :                                               # If no Database connection 
        return(0)                                                       # No need to close

    try:
        db_cur.close()
        db_conn.close()

    except (AttributeError,NameError) as ne:
        if not db_silent :
            write_err("[ ERROR ] Error closing database '%s' - '%s'" % (db_name,ne))
        return(1)
    except Exception as e:
        if not db_silent :
            (enum,emsg) = e.args                                        # Get Error No. & Message
            write_err("[ ERROR ] Error closing database '%s'" % (db_name)) 
            write_err(">>>>>>>>>>>>> '%s' '%s'" % (enum,emsg))          # Error Message
        db_errno=1                                                      # Set DB Error
        db_errmsg=emsg                                                  # Set Error Message
        return(1)                                                       # return (1) to Show Error
    return(0)



# --------------------------------------------------------------------------------------------------
def stop(pexit_code) :
    
    """ 
        The stop() function will update the log and the RCH file, trim them if needed 
        and return to caller.

        What stop() function does  
        - Calculate the execution time.  
        - Write the script footer in the log (script return code, execution time, …)
        - Update the RCH File (Start/End/Elapse Time and the Result Code)
        - Trim The RCH file Based on user choice in sadmin.cfg
        - Write to log the user mail alerting type choose by user (sadmin.cfg)
        - Trim the log based on user selection in sadmin.cfg
        - Send email to sysadmin (if user selected that option in sadmin.cfg)
        - Delete the PID file of the script ($SADM_PID_FILE)
        - If rch file is not in used (use_rch is False), delete script rch file.

        Args:            
            pexit_code (int)    : Can be either 0 (Successfully) if the script terminate 
                                  with success or with a non-zero (Error Encountered) if 
                                  it terminated with error. 
                                  Please call this function just before your script end.

        Return: 
            None
    """

    global pn,log_file_fh,err_file_fh,sadm_alert_type,start_time,start_epoch,delete_pid,dict_alert
           #db_conn,       db_cur
    
 
    # Making sure exit code is either 0 (Success) or 1 (error).
    if pexit_code != 0 : pexit_code =1 


    # Calculate the execution time, format it and write it to the log
    end_epoch = int(time.time())                                        # Save End Time in Epoch Time
    elapse_seconds = end_epoch - start_epoch                            # Calc. Total Seconds Elapse
    hours = elapse_seconds//3600                                        # Calc. Nb. Hours
    elapse_seconds = elapse_seconds - 3600*hours                        # Subs. Hrs*3600 from elapse
    minutes = elapse_seconds//60                                        # Cal. Nb. Minutes
    seconds = elapse_seconds - 60*minutes                               # Subs. Min*60 from elapse
    elapse_time="%02d:%02d:%02d" % (hours,minutes,seconds)              # Format execution time
    if (log_footer) :                                                   # Want to Produce log Footer
        write_log (" ")                                                 # Space Line in the LOG
        write_log ('='*50)                                              # 80 '=' Lines
        wmess = "Script exit code is " + str(pexit_code)                # Log exit code Footer
        if pexit_code == 0 :                                            # If Success
            wmess += " (Success) "                                      # Script Success to Log        
        else :                                                          # Script encountered Error
            wmess += " (Failed) "                                       # Script Failed to Log        
        wmess += "and execution time is %02d:%02d:%02d" % (hours,minutes,seconds)
        write_log (wmess)                                               # Write 1st Footer line

    # Get the userid and groupid chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
    try :
        uid = pwd.getpwnam(sadm_user).pw_uid                            # Get UID User in sadmin.cfg
        gid = grp.getgrnam(sadm_group).gr_gid                           # Get GID User in sadmin.cfg
    except KeyError as e:
        msg = "Invalid or Non-Existant User %s in sadmin.cfg" % (sadm_user)
        write_log (msg)

    # Update the [R]eturn [C]ode [H]istory File and trim it if needed.
    if (use_rch) :                                                      # If User use RCH File
        rch_exists = os.path.isfile(rch_file)                           # Do we have existing rch ?
        if rch_exists :                                                 # If we do, del code2 line?
            with open(rch_file) as xrch:                                # Open rch file
                lastLine = (list(xrch)[-1])                             # Get Last Line of rch file
                rch_code = lastLine.split(' ')[-1].strip()              # Get Last last fld (RCode) 
                if rch_code == "2" :                                    # If Code 2 - want to del it
                    rch_file_fh = open(rch_file,'r')                    # Open RCH File for reading
                    lines = rch_file_fh.readlines()                     # Read all Lines in Memory
                    del lines[-1]                                       # Delete last line (Code 2)
                    rch_file_fh.close()                                 # Write changes to disk
                    rch_file_fh = open(rch_file,'w')                    # Open RCH to rewrite it
                    rch_file_fh.writelines(lines)                       # Write RCH without code2
                    rch_file_fh.close()                                 # Close & Write change 
        i = datetime.datetime.now()                                     # Get Current Stop Time
        stop_time=i.strftime('%Y.%m.%d %H:%M:%S')                       # Format Stop Date & Time
        rch_file_fh=open(rch_file,'a')                                  # Open RCH Log - append mode
        rch_line="%s %s %s %s" % (phostname,start_time,stop_time,elapse_time)
        rch_line="%s %s %s" % (rch_line,pinst,sadm_alert_group)
        rch_line="%s %s %s" % (rch_line,sadm_alert_type,pexit_code)
        rch_file_fh.write ("%s\n" % (rch_line))                         # Write Line to RCH Log
        rch_file_fh.close()                                             # Close RCH File
        if (max_rchline != 0) :                                         # Trim nb. Line != 0 
            trimfile (rch_file,max_rchline)                             # Trim the Script RCH Log
            if log_footer :                                             # Want to Produce log Footer
                write_log ("History file %s trim to %s lines." % (rch_file,str(max_rchline)))
        if os.getuid() == 0 :                                           # If running as root
            os.chown(rch_file,uid,gid)                                  # Change RCH File Owner
            os.chmod(rch_file,0o0660)                                   # Change RCH File Perm.

    # Set the Alert Group Name, Group Type and Group Recipient(s) (Dest).
    if sadm_alert_group in dict_alert :
        wgrp_name = sadm_alert_group.lower().strip()
        wgrp_type = dict_alert[wgrp_name][1].lower().strip()
        wgrp_dest = dict_alert[wgrp_name][2].lower().strip()
        #print('%s - %s - %s ' % (wgrp_name, wgrp_type, wgrp_dest))
    else:
        write_log("Alert group '%s' not defined in %s." % (sadm_alert_group,alert_file))      
        write_log("Alert group now changed to 'default'.")
        wgrp_name = 'default'
        wgrp_type = dict_alert['default'][1].lower().strip()
        wgrp_dest = dict_alert['default'][2].lower().strip()
        #print('%s - %s - %s ' % (wgrp_name, wgrp_type, wgrp_dest))
    if wgrp_name == 'default' : 
        if wgrp_dest in dict_alert :
            wgrp_name = wgrp_dest
            wgrp_type = dict_alert[wgrp_name][1].lower().strip()
            wgrp_dest = dict_alert[wgrp_name][2].lower().strip()
            #print('%s - %s - %s ' % (wgrp_name, wgrp_type, wgrp_dest))
    if wgrp_type == 'm':
        grp_desc = "by email to group '%s'." % (wgrp_name)
    if wgrp_type == 's':
        grp_desc = "using Slack to '%s' channel)" % (wgrp_name) 
    if wgrp_type == 'c':
        grp_desc = "to Cell. group '%s'" % (wgrp_name)
    if wgrp_type == 't':
        grp_desc = "by SMS to group '%s'" % (wgrp_name)
    if wgrp_type != 'm' and wgrp_type != 's' and wgrp_type != 'c' and   wgrp_type != 't': 
        grp_desc = "Group '%s' invalid" % (wgrp_name)

    # Write in Log the email choice the user as requested (via the sadmin.cfg file)
    # 0 = No Mail Sent      1 = On Error Only   2 = On Success Only   3 = Always send email
    MailMess2=""                                                        # Use if invalid alert type
    if sadm_alert_type == 0 :                                           # User don't want any email
        MailMess="Never send an alert, regardless of it termination status." 
        
    if sadm_alert_type == 1 :                                           # Alert on Error Only
        if pexit_code != 0 :                                            # If Script end with error
            MailMess="An alert will be sent %s." % (grp_desc)           # Make Error Message
        else :
            MailMess="Send an alert only when it terminate with error." # No Error Message 

    if sadm_alert_type == 2 :                                           # Alert on Success Only
        if pexit_code != 0 :                                            # If Script end with error
            MailMess="Send alert only on success, none will be send."   # Failed = No Alert Message
        else : 
            MailMess="Alert only send on success %s." % (grp_desc)      # Success Send Alert Message
                    
    if sadm_alert_type == 3 :                                           # User always Want email
        MailMess="Always send an alert %s." % (grp_desc)                # Mess + Group we will send
                     
    if sadm_alert_type > 3 or sadm_alert_type < 0 : # Alert Type is Invalid
        MailMess="Invalid 'sadm_alert_type' value %s",(str(sadm_alert_type))
        MailMess2="It's set to '%s', changing it to 3.\n" % (sadm_alert_type)
        sadm_alert_type=3

    if (log_footer) :                                                   # Want to Produce log Footer
        write_log ("%s" % (MailMess))                                   # User alert choice to log
        if (MailMess2 != "") :  write_log ("%s" % (MailMess2))          # Invalid sadm_alert_type
        write_log ("Trim log file %s to %s lines." %  (log_file, str(max_logline)))
        i = datetime.datetime.now()                                     # Get Current Time
        stop_time=i.strftime('%Y.%m.%d %H:%M:%S')                       # Save Stop Date & Time
        footer_date=i.strftime('%a %d %b %Y %H:%M:%S')                  # Date format for Log footer 
        write_log (footer_date + " - End of " + pn)                     # Write Final Footer to Log
        write_log ('='*80)                                              # 80 '=' Lines
        write_log (" ")                                                 # Space Line in the LOG
  
    log_file_fh.flush()                                                 # Got to do it - Missing end
    log_file_fh.close()                                                 # Close the Log File
    err_file_fh.flush()                                                 # Got to do it - Missing end
    err_file_fh.close()                                                 # Close the Error Log File

    if (os.path.exists(err_file) and os.stat(err_file).st_size == 0):   # Error Log Exist & size > 0
        silentremove (err_file)                                         # Delete Error log File  

    if ((log_footer) and (max_logline != 0)) : 
        trimfile (log_file,max_logline)                                 # Trim the Script Log

    # Get the userid and groupid chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
    try :
        uid = pwd.getpwnam(sadm_user).pw_uid                            # Get UID User in sadmin.cfg
        gid = grp.getgrnam(sadm_group).gr_gid                           # Get GID User in sadmin.cfg
    except KeyError as e:
        msg = "User %s doesn't exist or not define in sadmin.cfg" % (sadm_user)
        write_err (msg)
        write_err ("%s" % (e))

    # Make Sure Owner/Group of Log File are the one chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
    try :
        if os.getuid() == 0: os.chown(log_file, -1, gid)                # -1 leave UID unchange
        if os.getuid() == 0: os.chmod(log_file, 0o0660)                 # Change Log File Permission
    except Exception as e:
        msg = "Warning : Couldn't change owner or chmod of "            # Build Warning Message
        write_err ("%s %s to %s:%s" % (msg,log_file,sadm_user,sadm_group))
        write_err ("%s" % (e))

    # Make Sure Owner/Group of RCH File are the one chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
    if (use_rch) :                                         # If Using a RCH File
        try :
            if os.getuid() == 0: os.chown(rch_file, -1, gid)            # -1 leave UID unchange
            if os.getuid() == 0: os.chmod(rch_file, 0o0660)             # Change RCH File Permission
        except Exception as e:
            msg = "Warning : Couldn't change owner or chmod of "        # Build Warning Message
            write_err ("%s %s to %s.%s" % (msg,rch_file,sadm_user,sadm_group))

    # Normally we Delete the PID File when exiting the script.
    # But when script is already running, then we are the second instance of the script
    # we don't want to delete PID file. 
    # When this situation happend (delete_pid is set to "N") in start() function. 
    if (os.path.isfile(pid_file) and delete_pid == "Y" ) :              # PID Exist & Only Running 1
        silentremove (pid_file)                                         # Delete PID File

    # Copy RCH & LOG files to Server Central Directory to be available to monitor quickly
    if (sadm_host_type == "S" and os.getuid() == 0 ) :                  # If on SADMIN Server
        if (use_rch) :                                                  # Copy Now rch to www
            try:
                woutput = dir_www_host + "/rch"  + '/' + phostname + '_' + pinst + '.rch'      
                if os.getuid() == 0 and os.path.exists(woutput): os.chmod(woutput, 0o0660) 
                shutil.copyfile(rch_file, woutput )                     # Copy Now rch to www
            except Exception as e:
                print ("Couldn't copy %s to %s\n%s\n" % (rch_file,woutput,e)) # Advise user
    else :
        if not use_rch :                                               # If not using RCH File
            silentremove(rch_file)                                      # Then Delete it 

    # If on SADMIN Server, copy immediately rch, log and elog to server central directories.
    if (sadm_host_type == "S" and os.getuid() == 0 ) :              # If on SADMIN Server
        if log_footer :
            try:
                woutput = dir_www_host + "/log"  + '/' + phostname + '_' + pinst + '.log'
                if os.getuid() == 0 and os.path.exists(woutput): os.chmod(woutput, 0o0660) 
                shutil.copyfile(log_file,woutput )                      # Copy Now log to www
            except Exception as e:
                print ("Couldn't copy %s to %s\n%s\n" % (log_file,woutput,e)) # Advise user
            try:
                welog = dir_www_host + '/' + phostname + '_' + pinst + '_e.log'
                if (os.path.exists(err_file)): 
                    shutil.copyfile(err_file,welog)                     # Copy Now log to www
            except Exception as e:
                print ("Couldn't copy %s to %s\n%s\n" % (err_file,welog,e))

    # Close Database if was used
    if sadm_host_type == "S" and db_used :                          # If Database was Used
       db_close()                                                       # Close Database
    return






# --------------------------------------------------------------------------------------------------
def start(pver,pdesc) : 
    
    global log_file_fh, err_file_fh, start_time, start_epoch, delete_pid, dict_alert

    """
    Initialize the SADMIN environment

        - Make sure all Directories require exist
        - Open script log in append mode (log_append=True) or new log.
        - Write Log Header, record startup Date/Time and update RCH file.
        - Check if script is already running (pid_file).
        - Advise user & Quit if Attribute multiple_exec="N".
        *** If nay error occurs while executing the function script is aborted. ***        

        Arguments required:
            - pver (str)  : Script version number.
            - pdesc (str) : Script brief description.

        Return: 
            - db_conn   : Return Database connector if 'db_used' is True else return blank.
            - db_cur    : Return Database cursor if 'db_used' is True else return blank.

    """

    # Get the SADMIN userproot_onlyid and groupid chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
    rcode = 0                                                           # Set return code to 0 
    uid = pwd.getpwnam(sadm_user).pw_uid                                # Get UID User in sadmin.cfg
    gid = grp.getgrnam(sadm_group).gr_gid                               # Get GID User in sadmin.cfg

    # Open LOG file.
    try:                                                                # Try to Open/Create Log
        if not os.path.exists(dir_log)  : os.mkdir(dir_log,2775)        # Create SADM Log Dir
        if (log_append):                                                # User Want to Append to Log
            log_file_fh=open(log_file,'a')                              # Open Log in append  mode
        else:                                                           # User Want Fresh New Log
            log_file_fh=open(log_file,'w')                              # Open Log in a new log
    except PermissionError as e:                                        
        print("\nPermission error when trying to open the log '%s'." % (log_file))
        print("Check & change permission on the file or run this script with 'sudo'.\n")
        sys.exit(1)                                                     # Back to O/S 
    except IOError as e:                                                # If Can't Create or open
        print("Error opening log file : %s" % (log_file))               # write_log Log FileName
        print("Error Line No.: %d" % (inspect.currentframe().f_back.f_lineno)) 
        print("Function Name : %s" % (sys._getframe().f_code.co_name))  # Current function Name
        print("Error No. %d - %s" % (e.errno,e.strerror))               # Print Error Number
        sys.exit(1)               
    if os.getuid() == 0: 
        os.chown(log_file,uid,gid)                                      # Set Owner of log file
        os.chmod(log_file,0o664)                                        # Chg log file Perm.

    # Open script ERROR log file. 
    try: 
        if (log_append):                                                # User Want to Append to Log
            err_file_fh=open(err_file,'a')                              # Open ErrLog append  mode
        else:                                                           # User Want Fresh New Log
            err_file_fh=open(err_file,'w')                              # Open New Error Log 
    except PermissionError as e:                                        
        print("\nPermission error when trying to open the error log '%s'." % (err_file))
        print("Check & change permission on the file or run this script with 'sudo'.\n")
        sys.exit(1)                                                     # Back to O/S 
    except IOError as e:                                                # If Can't Create or open
        print("Error opening error log file %s" % (err_file))           # write_log Error Log File
        print("Error Line No.: %d" % (inspect.currentframe().f_back.f_lineno)) # Line Number
        print("Function Name : %s" % (sys._getframe().f_code.co_name))  # Current function Name
        print("Error No. %d - %s" % (e.errno,e.strerror))               # Print Error Number
        sys.exit(1)                                                     # Back to O/S 
    if os.getuid() == 0: 
        os.chown(err_file,uid,gid)                                      # Set Owner, error log file
        os.chmod(err_file,0o664)                                        # Chg error log file Perm.

    # Validate Log Type (S=Screen L=Log B=Both)
    if ((log_type.upper() != 'S') and (log_type.upper() != "B") and (log_type.upper() != 'L')):
        write_err ("Valid log_type are 'S','L','B' - Can't set log_type to %s" % (log_type.upper()))
        stop(1)                                                         # Close SADMIN 
        sys.exit(1)                                                     # Back to O/S 

    # Validate Log open move - Append (True or False)
    if ( (log_append != True) and (log_append != False) ):
        write_err ("Invalid log.append attribute can be True or False (%s)" % (log_append))
        stop(1)                                                         # Close SADMIN 
        sys.exit(1)                                                     # Back to O/S 

    # Set & Save Starting Date/Time
    start_epoch = int(time.time())                                      # StartTime in Epoch Time
    i = datetime.datetime.now()                                         # Get Current Time
    start_time=i.strftime('%Y.%m.%d %H:%M:%S')                          # Save Start Date & Time    
    header_date=i.strftime('%a %d %b %Y %H:%M:%S')                      # Date format for Log Header 

    # Make sure all SADM Directories structure exist
    if not os.path.exists(dir_bin)  : os.mkdir(dir_bin,0o0775)          # bin Dir.
    if not os.path.exists(dir_cfg)  : os.mkdir(dir_cfg,0o0775)          # cfg Dir
    if not os.path.exists(dir_dat)  : os.mkdir(dir_dat,0o0775)          # dat Dir.
    if not os.path.exists(dir_doc)  : os.mkdir(dir_doc,0o0775)          # doc Dir.
    if not os.path.exists(dir_lib)  : os.mkdir(dir_lib,0o0775)          # lib Dir.
    if not os.path.exists(dir_log)  : os.mkdir(dir_log,0o0775)          # log Dir.
    if not os.path.exists(dir_pkg)  : os.mkdir(dir_pkg,0o0775)          # pkg Dir.
    if not os.path.exists(dir_setup): os.mkdir(dir_setup,0o0775)        # setup Dir.
    if not os.path.exists(dir_sys)  : os.mkdir(dir_sys,0o0775)          # sys Dir.
    if not os.path.exists(dir_tmp)  : os.mkdir(dir_tmp,0o1777)          # tmp Dir.
    if not os.path.exists(dir_nmon) : os.mkdir(dir_nmon,0o0775)         # dat/nmon Dir.
    if not os.path.exists(dir_dr)   : os.mkdir(dir_dr,0o0775)           # dat/dr Dir.
    if not os.path.exists(dir_rch)  : os.mkdir(dir_rch,0o0775)          # dat/rch Dir.
    if not os.path.exists(dir_net)  : os.mkdir(dir_net,0o0775)          # dat/net Dir.
    if not os.path.exists(dir_rpt)  : os.mkdir(dir_rpt,0o0775)          # dat/rpt Dir.
    if not os.path.exists(dir_dbb)  : os.mkdir(dir_dbb,0o0775)          # dat/dbb Dir.

    # Make sure all SADM User directories exist
    if not os.path.exists(dir_usr)  : os.mkdir(dir_usr,0o0775)          # User Dir.
    if os.getuid() == 0: os.chown(dir_usr, uid, gid)                    # Change owner/group
    
    if not os.path.exists(dir_usr_bin) : os.mkdir(dir_usr_bin,0o0775)   # User Bin Dir.
    if os.getuid() == 0: os.chown(dir_usr_bin,uid,gid)                  # Change owner/group
    
    if not os.path.exists(dir_usr_lib) : os.mkdir(dir_usr_lib,0o0775)   # User Library Dir.
    if os.getuid() == 0: os.chown(dir_usr_lib,uid,gid)                  # Change owner/group
    
    if not os.path.exists(dir_usr_doc) : os.mkdir(dir_usr_doc,0o0775)   # User Doc. Dir.
    if os.getuid() == 0: os.chown(dir_usr_doc, uid, gid)                # Change owner/group
    
    if not os.path.exists(dir_usr_mon) : os.mkdir(dir_usr_mon,0o0775)   # SysMon Scripts Dir
    if os.getuid() == 0: os.chown(dir_usr_mon, uid, gid)                # Change owner/group

    # Web Directories
    if (sadm_host_type == "S") :
        wgid = grp.getgrnam(sadm_www_group).gr_gid                      # Get GID User of Web Group
        wuid = pwd.getpwnam(sadm_www_user).pw_uid                       # Get UID User of Web User
        list1 = [ dir_www, dir_www_net, dir_www_doc, dir_www_dat ]      # List #1 Dir. to create
        list2 = [ dir_www_arc, dir_www_lib, dir_www_tmp, dir_www_log ]  # List #2 Dir. to create
        list3 = [ dir_www_perf, dir_www_rch ]                           # List #3 Dir. to create
        web_dir = list1 + list2 + list3                                 # Combine the 3 lists
        for wdir in web_dir :               
            if not os.path.isdir(wdir)  : 
                try: 
                    os.makedirs(wdir,mode = 0o775,exist_ok = True)
                except OSError as e:
                    print("Directory '%s' can't be created.\n%s" % (wdir,e))
            if os.getuid() == 0: os.chown(wdir, wuid, wgid)             # Web Server Network Dir.


    # Write SADM Header to Script Log
    if (log_header) :                                                   # User Want a log Header
        write_log ('='*80)                                              # 80 '=' Lines
        wmess = "%s - %s " % (header_date,pn)                           # 1st line Date/Time & Name
        wmess += "v%s " % (pver)                                        # 1st line Script Version
        wmess += "- Library v%s" % (lib_ver)                            # 1st line SADM Library Ver.
        write_log (wmess)                                               # Write 1st Header Line
        # 
        if (pdesc != "") :                                              # If script Desc. not blank
            write_log ("%s" % (pdesc))                                  # 2nd line Write Desc to Log
        #
        wmess = "%s - User: %s - Umask: %04d - " % (get_fqdn(),pusername,getUmask()) # 3th line part 1 
        wmess += "Arch: %s " % (get_arch())        # 3th line part 2
        write_log (wmess)                                               # Write 3th Line to log
        #
        wmess  = "%s "  % (get_osname().capitalize())                   # 4th Line O/S Distr. Name
        #wmess += "%s "  % (get_oscodename().capitalize())               # 4th Line O/S Code Name 
        wmess += "%s "  % (get_ostype().capitalize())                   # 4th Line O/S Type Linux/Aix
        wmess += "v%s " % (get_osversion())                             # 4th Line O/S Version
        wmess += "- Kernel %s - SADMIN(%s): %s" % (get_kernel_version(),sadm_host_type,dir_base)
        write_log (wmess)                                               # Write 4th Line to Log
        write_log ('='*50)                                              # 50 '=' Lines
        write_log (" ")                                                 # Space Line in the LOG

    # If this script can only be run by 'root' 
    if proot_only and os.getuid() != 0:                                 # UID of user is not 'root'
        print("This script can only be run by the 'root' user.")        # Advise User Message / Log
        print("Try 'sudo %s'" % (os.path.basename(sys.argv[0])))        # Suggest to use 'sudo'
        print ("Or change the value of 'sa.proot_only' to 'False'.")    # Choice of user
        print("Process aborted.")                                       # Process Aborted Msg
        stop(1)                                                         # Close SADMIN 
        sys.exit(1)                                                     # Back to O/S 

    # If this script can only be run on the SADMIN server
    if on_sadmin_server() == "N" and psadm_server_only : 
        print("Script can only run on a SADMIN server.")
        print("Must met these conditions :")
        print(" - Variable 'SADM_HOST_TYPE' in $SADMIN/cfg/sadmin.cfg must be 'S'.")
        print(" - The IP of the host 'sadmin' must refer to an ip define on this host.")
        print(" - The 'sadmin' MySQL database must be present on this host.") 
        print("Process aborted.")                                       # Abort advise message
        stop(1)                                                         # Close SADMIN 
        sys.exit(1)                                                     # Back to O/S 
    
    # Check Files that should be present ONLY ON SADMIN SERVER
    # Make sure the alert History file exist , if not use the history template to create it.
    if (sadm_host_type == "S") :
        if check_system_lock(phostname) :                               # System is Lock on SADMIN
           stop(1)                                                      # Close SADMIN
           sys.exit(1)                                                  # Exit back to O/S,Abort
        if not os.path.exists(alert_hist):                              # AlertHistory Missing
            if not os.path.exists(alert_hini):                          # AlertHistoryTemplate
                touch_file(alert_hini)                                  # Create HistoryTemplate
            write_log ("cp %s %s " % (alert_hini,alert_hist))           # History File=Template
            try:
                shutil.copy(alert_hini,alert_hist)                      # cp Template in History
            except:
                write_err ("Couldn't copy %s to %s" % (alert_hini,alert_hist))  # Advise user
                stop(1)                                                 # Close SADMIN
                sys.exit(1)                                             # Exit back to O/S,Abort
        if os.getuid() == 0:                                            # If running as root
            os.chown(alert_hist,uid,gid)                                # Chg History File Owner
            os.chmod(alert_hist,0o0664)                                 # Chg History File Perm.

    # If the PID file already exist - Script is already Running, check for how long it's running
    if os.path.exists(pid_file) and not multiple_exec  :                # PID Exist & NoMultiRun
        pepoch = int(os.path.getmtime(pid_file))                        # pid file mod EpochTime
        pelapse = int(start_epoch - pepoch)                             # seconds since creation
        write_log ("PID file %s exist, created %d seconds ago." % (pid_file,pelapse))
        write_log ("%s may be already running ..." % (pn))              # Script already running
        write_log ("Not allowed to run a second copy of this script (multiple_exec=False)")
        write_log (" ")
        write_log ("Script can't execute unless one of the following things happen :")
        write_log ("  - Remove the PID File (%s)." % (pid_file))
        write_log ("  - Set parameter 'multiple_exec=True' when calling the 'sa.start()' function.")
        try : 
            pid_timeout                                                 # Is variable defined ? 
        except NameError:
            pid_timeout=7200                                            # If not define set default
        write_log ("  - Waiting till the PID timeout (%d sec.) is reached." % int((pid_timeout)))
        write_log(" ")
        if (pelapse >= int(pid_timeout)) :                              # PID Timeout reached
            write_err ("PID File exceeded it time to live.")            # Advise user of PID Timeout
            write_err ("Assuming script was aborted abnormally.")       # Assume reason for that
            write_err ("Script execution re-enable, PID file updated.")
            write_log(" ")
            touch_file (pid_file)                                       # Create empty PID File
            delete_pid="Y"                                              # Del PID Since running
        else: 
            delete_pid="N"                                              # Don't delete PID in stop()
   ######         #stop(1)                                              # Call SADM Stop Function
            sys.exit(1)                                                 # Exit with Error
    else:
        touch_file (pid_file)                                           # Create empty PID File
        delete_pid="Y"                                                  # Del PID in stop() function

    # Record Date & Time the script is starting in the RCH File
    if (use_rch) :                                                     # If want to Create/Upd RCH
        try:
            rch_file_fh=open(rch_file,'a')                              # Open RCH file append mode
        except IOError as e:                                            # If Can't Create or open
            write_err ("Error opening file %s" % (rch_file))            # Print Log FileName
            write_err ("Error Line No. : %d" % (inspect.currentframe().f_back.f_lineno)) # Print LineNo
            write_err ("Function Name  : %s" % (sys._getframe().f_code.co_name)) # Get function Name
            write_err ("Error Number   : %d" % (e.errno))               # write_log Error Number
            write_err ("Error Text     : %s" % (e.strerror))            # Print Error Message
            sys.exit(1)                                                 # Back to O/S
        rch_dot=".......... ........ ........"                          # No Date/Time Elapse Yet
        rch_line="%s %s %s %s" % (phostname,start_time,rch_dot,pinst)
        rch_line="%s %s %s %s" % (rch_line,sadm_alert_group,sadm_alert_type,"2")
        rch_file_fh.write ("%s\n" % (rch_line))                         # Write Line to RCH Log
        rch_file_fh.close()                                             # Close RCH File
        if os.getuid() == 0:                                            # If running as root
            os.chown(rch_file,uid,gid)                                  # Chg History File Owner
            os.chmod(rch_file,0o0664)                                   # Chg History File Perm.  

    # If user specified he want to use the Database and we are on the SADMIN server, connect to DB.
    if db_used and sadm_host_type == "S" : 
        db_connect(db_name) 
    return(0)




# --------------------------------------------------------------------------------------------------
def load_alert_file():
    
    """ Load alert_group file into dict_alert dictionnary
        
        Args: None
    
        Returns:
            dict_alert (dict) : Contain the alert group data.
                                Key is the Group name as defined in 
                                $SADMIN/cfg/alert_group.cfg file.
                                Ex: Key (str) = 'mail_support'
                                    Value (list) = ('mail_support', 'm', 'batman@batcave.com', '')
    """
    
    if lib_debug > 4 : write_log ("Load Alert Group Configuration file %s" % (cfg_file))

    # Make sure the Alert Group File exist ($SADMIN/cfg/alert_group.cfg).
    # If it doesn't exist, create one using alert initial file ($SADMIN/cfg/.alert_group.cfg)
    if not os.path.exists(alert_file):                                  # alert_group.cfg not Exist
        if not os.path.exists(alert_init):                              # .alert_group.cfg not Exist
          write_log ("SADMIN Alert Group file not found - " + alert_file)
          write_log ("Even Alert Group Template file is missing - " + alert_init)
          write_log ("Copy both files from another system to this server")
          write_log ("Or restore them from a backup")
          stop(1)                                                       
          sys.exit(1)                                                   # Exit to O/S with Error
        else:
            write_log ("cp %s %s " % (alert_init,alert_file))           # Install Default alert file
            try:
                shutil.copy(alert_init,alert_file)
            except:
                write_log ("Could not copy %s to %s" % (alert_init,alert_file))
                stop(1)   
                sys.exit(1)                                             # Exit to O/S with Error
    if os.getuid() == 0:                                                # If running as root
        uid = pwd.getpwnam(sadm_user).pw_uid                            # Get UID User in sadmin.cfg
        gid = grp.getgrnam(sadm_group).gr_gid                           # Get GID User in sadmin.cfg
        os.chown(alert_file,uid,gid)                                    # Change alert File Owner
        os.chmod(alert_file,0o0664)                                     # Change alert File Perm.

    # Open Alert Group file
    try:
        alert_file_fh= open(alert_file,'r')                             # Open Config File
    except IOError as e:                                                # If Can't open cfg file
        write_log ("Error opening file %s" % (alert_file))              # Print Log FileName
        write_log ("Error Line No.: %d" % (inspect.currentframe().f_back.f_lineno)) # Print Line No.
        write_log ("Function Name : %s" % (sys._getframe().f_code.co_name)) # Get function Name
        write_log ("Error Number  : %d" % (e.errno))                    # write_log Error Number
        write_log ("Error Text    : %s" % (e.strerror))                 # Print Error Message
        sys.exit(1)                     

    # Read Configuration file and Save Options values
    for aline in alert_file_fh:                                         # Loop until on all servers
        wline        = aline.strip()                                    # Strip CR/LF & Trail spaces
        if (wline[0:1] == '#' or len(wline) == 0) :                     # If comment or blank line
            continue                                                    # Go read the next line
        split_line = wline.split()                                      # Split based on space
        grp_name   = str(split_line[0]).lower().strip()                 # Group Name Lowercase Trim
        grp_type   = str(split_line[1]).lower().strip()                 # Group Type Lowercase Trim
        grp_dest   = str(split_line[2]).lower().strip()                 # Grp Destination Lowercase
        try:                                                            # May have 4th, Slack Hook
            grp_slhook = str(split_line[3]).strip()                     # Group Slack Hook
        except IndexError:                                              # If no Slack Hook on Line
            grp_slhook = ""                                             # Blank Hook if no 4th field
        dict_alert[grp_name] = (grp_name,grp_type,grp_dest,grp_slhook)  # Insert Grp Data in Dict
    return (dict_alert)











# --------------------------------------------------------------------------------------------------
def get_packagetype():
    
    """ Determine The Installation Package Type Of Current O/S.
        Value is returned in lowercase (rpm,deb,lpp,dmg).
        
        Args:            
            None
    
        Returns:
            package_type (str)  :   Return package type use on the system (in lowercase).
                                    rpm (Fedora,RedHat,CentOS,Alma,Rocky,...)  
                                    deb (Ubuntu,Debian,Raspbian,Mint,...)  
                                    dmg (MacOS)  
                                    lpp (Aix)  
    """      
    
    packtype=""                                                         # Initial Packaging is None
    if (locate_command('rpm')   != "")      : packtype="rpm"            # Is rpm command on system ?
    if (locate_command('dpkg')  != "")      : packtype="deb"            # is deb command on system ?
    if (locate_command('lslpp') != "")      : packtype="lpp"            # Is lslpp cmd on system ?
    if (locate_command('launchctl') != "")  : packtype="dmg"            # launchctl MacOS on system?
    if (packtype == ""):                                                # If unknow/unsupported O/S
        write_err ('None of these commands are found (rpm, pkg, dmg or lslpp absent)')
        write_err ('No supported package type is detected')
    return(packtype)





# Send an email to sysadmin define in sadmin.cfg with subject and body received
# ----------------------------------------------------------------------------------------------
def sendmail(mail_addr, mail_subject, mail_body, mail_attach="") :
    
    """ Send email to email address received.
        
        Args:            
            mail_addr (str)     : Email Address to which you want to send it
            mail_subject (str)  : Subject of your email
            mail_body (str)     : Body of your email
            mail_attach (str)   : Name of the file (MUST exist) to attach to the email.
                                  (If no attachment, leave blank)
    
        Returns:
            Return Code (Int)   : 0 Successfully sent the email
                                  1 Error while sending the email (Parameters may be wrong)
    """

    data = MIMEMultipart()                                              # instance of MIMEMultipart
    data['From '] = sadm_smtp_sender                                     # store sender email address  
    data['To '] = mail_addr                                              # store receiver email 
    data['Subject '] = mail_subject                                      # storing the subject 
    data.attach(MIMEText(mail_body, 'plain'))                           # attach body with msg inst

    if mail_attach != "" :
        filenames = mail_attach.split(',')
        for filename in filenames :
            if os.path.exists(filename): 
                attachment = open(filename, "rb")                       # Read file into memory
                p = MIMEBase('application', 'octet-stream')             # MIMEBase inst & named as p
                p.set_payload((attachment).read())                      # Payload into encoded form
                encoders.encode_base64(p)                               # encode into base64
                p.add_header('Content-Disposition', "attachment; filename= %s" % filename)
                data.attach(p)                                          # attach inst p to inst msg
    text = data.as_string()                                             # Conv. Multipart msg 2 str

    try : 
        context = ssl.create_default_context()
        with smtplib.SMTP(sadm_smtp_server, sadm_smtp_port) as server:
            server.ehlo()  # Can be omitted
            server.starttls(context=context)
            server.ehlo()  # Can be omitted
            try:
                server.login(sadm_smtp_sender, sadm_gmpw)
            except smtplib.SMTPException :
                write_err("Authentication for %s at %s:%d failed (%s)." % (sadm_smtp_sender,sadm_smtp_server,sadm_smtp_port,sadm_gmpw))
                return (1)
            try : 
                server.sendmail(sadm_smtp_sender, mail_addr, text)
            except Exception as e: 
                write_err("[ ERROR ] Trying to send email to %s" % (mail_addr))
                write_err("%s" % e)
                return (1)
            finally:
                server.close()
    except (smtplib.SMTPException, socket.error, socket.gaierror, socket.herror) as e:
            write_err("[ ERROR ] Connection to %s port %s failed" % (sadm_smtp_server,sadm_smtp_port))
            write_err("%s" % e)
            return(1)
    return (0)





# --------------------------------------------------------------------------------------------------
def print_dict_alert():
    
    """ Print Of Alert Group Dictionnary
        
        Args: (none)
    
        Returns:
            dict_alert (dict) : Contain the alert group data.
                Key (str): Alert group Name (Ex: slack_sprod,sms_sysadmin)    
                Value (list):
                    Examples:
                    ('slack_sprod','s','sadm_prod','https://hooks.slack.com...')    
                    ('mail_support', 'm', 'batman@batcave.com,robin@batcave.com', '') 
    """

    print ("\n\n-----Print Of Alert Group Dictionnary (dict_alert)-----\n")
    sorted_dict_alert = dict(sorted(dict_alert.items(),key=lambda item: item[0]))
    for key, value in sorted_dict_alert.items() :
        print("%-40s : %s" % ("dict_alert['"+str(key)+"']",str(value)))



# --------------------------------------------------------------------------------------------------
def db_connect(DB):
    
    """ Open a connection to the Database (sadmin).
        
        Args: Name of the Database to connect to..
              If not specified, 'sadmin' is the assume.
    
        Returns: (db_err, db_conn, db_cur)
            db_err (int)    :   Return 0 when connected to database
                                Return 1 when error connecting to database
            db_conn (obj)   :   Connector to database.
            db_cur (obj)    :   Database cursor.
    """
    global db_name, db_conn, db_cur, db_errno, db_errmsg

    if db_name == "" : db_name = "sadmin"
    db_conn     = None                                                  # Database connector Obj
    db_cur      = None                                                  # Database cursor Obj
    db_errno    = 0                                                     # Error No to return
    db_errmsg   = ""                                                    # Error Mess. to return

    # No Connection to Database is possible if not on the SADMIN Server
    if sadm_host_type != "S" :                                          # Use only on SADMIN server
       db_errmsg = "[ ERROR ] This system is a SADMIN client, DB can't be used on this system."
       if not db_silent :                                               # Want to show error Msg.
           write_err(db_errmsg)
       db_errno = 1                                                     # Error number
       return(1)

    # User decided not to use Database, No Connection to Database
    if not db_used :                                                    # User Want to use DB
       if not db_silent :
          write_err("[ ERROR ] Connection to database only possible when 'sa.db_used' is set to True")
       db_errno = 1                                                     # Error number
       db_errmsg = "[ ERROR ] Connection to database only possible when 'sa.db_used' is set to True"
       return(1)

    # Open a connection to Database
    try :
        #write_log("host=%s - user=%s - password=%s - database=%s" % (sadm_dbhost,sadm_rw_dbuser,sadm_rw_dbpwd,db_name))
        db_conn = pymysql.connect( 
            host=sadm_dbhost, 
            user=sadm_rw_dbuser,  
            password=sadm_rw_dbpwd, 
            db=db_name,
            cursorclass=pymysql.cursors.DictCursor
        )
    except Exception as e:
        if not db_silent :
            #(enum,emsg) = e.args                                        # Get Error No. & Message
            emsg = e                                        # Get Error No. & Message
            write_err("Connection error to database '%s'" % (db_name))
            write_err("[ ERROR ] '%s' " % (e))                # Error Message 
            #write_err("[ ERROR ] '%s' '%s'" % (enum,emsg))                 # Error Message 
        #db_errno = enum
        db_errno = 1
        db_errmsg = emsg
        return(1)

    # Define a cursor object using cursor() method
    try :
        db_cur = db_conn.cursor()                                     # Create Database cursor
    except Exception as e:
        if not db_silent :
            enum, emsg = e.args                                         # Get Error No. & Message
            write_err("[ ERROR ] Problem creating database cursor for '%s'" % (db_name)) 
            write_err("[ ERROR ] '%s' '%s'" % (enum,emsg))                 # Error Message 
        db_errno = enum
        db_errmsg = emsg
        return(1)

    return (0)


# --------------------------------------------------------------------------------------------------
def get_ip_addresses(family):
    """
        Return a list with all defined IP on the current host
    
        Args    : Constant AF_INET (IPv4) or AF_INET6 (IPv6).

        Returns : A List of IP defined on host.
    """

    for interface, snics in psutil.net_if_addrs().items():
        for snic in snics:
            if snic.family == family:
                yield (interface, snic.address)



# --------------------------------------------------------------------------------------------------
def on_sadmin_server():
    
    """ 
        Check if the IP assigned to 'sadmin' is defined on the current system.
        
        Return True or False
    
            "Y"     : System is a valid SADMIN server,
                        - System have "SADM_HOST_TYPE" equal to "S" in $SADMIN/cfg/sadmin.cfg.
                        - The 'sadmin' host resolved to an IP present on the current system.
                          This permit to use an IP other than the main system IP address.
            "N"     : Mean that current is not a SADMIN server.
                      
    """
    valid_server="N"                                                    # Default, Not SADMIN server
    if (sadm_host_type != "S") : return(valid_server)                   # Not 'S' type in sadmin.cfg

    # Get all IPs defined on this system in 'ips_on_system'. 
    cmd =  "ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{ print $2 }' | awk -F/ '{ print $1 }'"
    ccode, ips_on_system, cstderr = oscommand(cmd)

    # Get Ip of 'sadmin' server 
    try : 
        sadmin_ip = socket.gethostbyname("sadmin")                      # get 'sadmin' IP
    except Exception as e:
        print("\nCould not determine IP of 'sadmin'.")
        print("\nYou may want to add it to /etc/hosts or in your DNS.")
        print ("\n%s" % (e))
        return(valid_server)
    
    # 'sadmin' server IP is define on this system ?
    if sadmin_ip in ips_on_system : return('Y')

    # Get IP of the current IP 
    try: 
        hostname_ip = socket.gethostbyname(sadm_server) 
    except Exception as e:
        print("\nCould not determine IP of '%s'." % sadm_server)
        print("\nYou may want to add it to /etc/hosts or in your DNS.")
        print ("\n%s" % (e))
        return(valid_server)

    # Is SADM_SERVER var. that is define in sadmin.cfg is define on this host.                
    if sadmin_ip in ips_on_system : return('Y')

    return(valid_server)


# --------------------------------------------------------------------------------------------------
# Things to do when the module is loaded
# --------------------------------------------------------------------------------------------------

# Making sure the 'SADMIN' environment variable is defined, abort if it isn't.
if (os.getenv("SADMIN",default="X") == "X"):                            # SADMIN Env.Var. Not Define
    print("\n'SADMIN' environment variable isn't defined.")             # SADMIN Var MUST be defined
    print("\nIt specify the directory where you installed the SADMIN Tools.")
    print("\nAdd this line at the end of /etc/environment file")        # Show Where to Add Env. Var
    print("\nSADMIN='/[dir-where-you-install-sadmin]'")                 # Show What to Add.
    print("\nThen logout and log back in and run the script again.")    # Show what to do 
    sys.exit(1)  

load_config_file(cfg_file)                                              # Load sadmin.cfg in Dict.
load_cmd_path()                                                         # Load Cmd Path Variables
dict_alert = load_alert_file()                                          # Load Alert group in dict
if (lib_debug > 0) :                                                    # Under debugging
    print_dict_alert()                                                  # Print Alert Group Dict
