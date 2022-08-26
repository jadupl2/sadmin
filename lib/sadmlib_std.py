#!/usr/bin/env python3
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadmlib_std.py
#   Synopsis:   This is the Standard SADMIN Python Library
#
#===================================================================================================
# Change Log
# 2016_06_13    V1.1 Added Flush before trimming file
# 2017_09_03    V1.2 Rewritten Trimfile function (Caused error if exec in debug mode)
# 2017_09_03    V1.3 Added db_dir and db_file for Sqlite3 Database
# 2017_11_23    V2.0 Major Redesign of the Library and switch to MySQL Database
# 2017_12_07    V2.1 Correct problem change group of rch and log file in the stop function
# 2017_12_07    V2.2 Revert Change Cause reading problem with apache
# 2017_12_26    V2.2 Adapted to work on OSX and To Adapt to Python 3
# 2018_01_03    V2.3 Added Check for facter command , if present use it get get hardware info
# 2018_01_03    V2.4 Add New arc Directory in $SADMIN/www for archiving
# 2018_01_25    V2.5 Add SADM_RRDTOOL to sadmin.cfg for php page using it
# 2018_02_14    V2.6 Add Documentation Directory
# 2018_02_17    V2.7 Revision of the command requirements and message when missing
# 2018_02_21    V2.8 Minor Changes
# 2018_02_22    V2.9 Add Field SADM_HOST_TYPE in sadmin.cfg
# 2018_05_04    V2.10 Database User and Password are now read from .dbpass (no longer sadmin.cfg)
# 2018_05_14    V2.11 Add Var. obj.use_rch, to use or not the RCH file (for interactice Pgm)
# 2018_05_15    V2.12 Add Var. obj.log_header & obj.log_footer to produce or not log header/footer
# 2018_05_20    V2.13 Minor correction to make the log like the SADMIN Shell Library
# 2018_05_26    V2.14 Add Param to writelog for Bold Attribute & Remove some unused Variables
# 2018_05_28    V2.15 Added Loading of backup parameters coming from sadmin.cfg
# 2018_06_04    V2.16 Added User Directory creation & Database Backup Directory
# 2018_06_05    v2.17 Added www/tmp/perf Directory (Used to Store Performance Graph)
# 2018_06_25    sadmlib_std.py v2.18 Correct problem trying to open DB on client.
# 2018_07_22 v2.19 When using 'writelog' don't print date/time only in log.
# 2018_09_19 v2.20 Add alert group to RCH file.
# 2018_11_07 v2.21 Was trying to connect to Database, even if was not on SADMIN Server
# 2018_11_09 v2.22 Refine test before connecting to Database
# 2018_11_13 v2.23 Change for support of MacOS Mojave
# 2019_01_19 v2.24 Added: Added Backup List & Exclude List Var. in Class & curl,mutt cmd. path.
# 2019_01_28 v2.25 Fix: DB Password file on read on SADMIN Server.
# 2019_03_08 Change: v2.26 'lsb_release -si' return new string in RHEL/CentOS 8, Change get_osname()
# 2019_03_18 New: v2.27 Function 'get_packagetype()' that return package type (rpm,dev,aix,dmg).
# 2019_04_25 Update: v2.28 Read and Load 3 news sadmin.cfg variable Alert_Repeat, Textbelt Key & URL
# 2019_05_16 Update: v3.00 Only one summary line is now added to RCH file when scripts are executed.
# 2019_05_16 Update: v3.01 New 'st.show_version()' function, libr. debug variable (st.lib_debug), 
#                    script alert not send by script anymore but by SADMIN master.
# 2019_05_20 Fix: v3.02 Was not loading Storix mount point directory info.
# 2019_06_07 Update: v3.03 Create/Update the rch file using the new format (with alarm type).
# 2019_06_19 Update: v3.04 Trap and show error when can't connect to Database, instead of crashing.
# 2019_07_23 Update: v3.05 Remove utilization of history sequence number file.
# 2019_08_19 Update: v3.06 Added rear_exclude_init Global Var. as default Rear Exclude List 
# 2019_08_19 Update: v3.07 Added Global Var. rear_newcron and rear_crontab file location 
# 2019_10_14 Update: v3.08 Added function 'get_arch' - Return system arch. (x86_64,armv7l,i686,...)
# 2019_10_30 Update: v3.09 Remove 'facter' utilization (Depreciated).
# 2020_01_20 Update: v3.10 Better handling & Error message when can't connect to database.
# 2020_01_20 Fix: v3.11 Fix 'get_osminorversion' function. Crash (raspbian) when no os minor version 
# 2020_02_25 Update: v3.12 Add 'export SADMIN=$INSTALLDIR' to /etc/environment, if not there.
# 2020_09_10 Update: v3.13 Minor update to date/time module. 
# 2020_12_24 Update: v3.14 CentOSStream is CENTOS
# 2021_05_02 lib v3.15 Fix typo error in 'locate_command' method.
# 2021_05_11 lib v3.16 Fix Path to which command was not set properly because of defined alias.
# 2021_05_14 lib v3.17 Get DB result as a dict. (connect cursorclass=pymysql.cursors.DictCursor)
# 2021_05_16 lib v3.18 Adjustment for MacOS Big Sur
# 2021_08_17 lib v3.19 Add 'SADM_MONITOR_UPDATE_INTERVAL'variable that control refresh rate. 
# 2021_09_30 lib v3.20 Small bug corrections
# 2021_11_07 lib v3.21 Locate 'rrd_tool' executable, instead of using sadmin.cfg. 
# 2022_04_04 lib v3.22 Change 'get_fqdn' function so it work well on RHEL v9. 
# 2022_04_10 lib v3.23 Use '/etc/os-release' file instead of depreciated 'lsb_release' command.
# 2022_05_27 lib v3.24 Use socket.getfqdn() in 'get_fqdn' function.
# 2022_05_29 lib v3.25 Command 'socket.getfqdn()' don't always return a domain name,use shell method.
# 2022_06_01 lib v3.26 Fix finally 'get_domain()' function to get the domain name.
#  
#==================================================================================================
try :
    import errno, time, socket, subprocess, smtplib, pwd, grp, glob, fnmatch, linecache
    from subprocess import Popen, PIPE
    import os, sys, datetime, getpass, shutil
    #import pdb                                                         # Python Debugger
    #pdb.set_trace()                                                    # Activate Python Debugging
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)

# Python MySQL Module is a MUST before continuing
try :
    import pymysql
except ImportError as e:
    print ("The Python Module PyMySQL is not installed : %s " % e)
    print ("We need to install it before continuing")
    print ("\nIf you are on Debian,Raspbian,Ubuntu family type the following command to install it:")
    print ("sudo apt-get install python3-pip")
    print ("sudo pip3 install PyMySQL")
    print ("After run sadm_setup.py again, to continue installation of SADMIN Tools")
    print ("\nIf you are on Redhat, CentOS, Fedora family type the following command to install it:")
    print ("sudo yum --enablerepo=epel install python34-pip")
    print ("sudo pip3 install pymysql")
    print ("After run sadm_setup.py again, to continue installation of SADMIN Tools")
    sys.exit(1)


#===================================================================================================
#                 Global Variables Shared among all SADM Libraries and Scripts
#===================================================================================================

dash                = "=" * 80                                          # Line of 80 dash
ten_dash            = "=" * 10                                          # Line of 10 dash
fifty_dash          = "=" * 50                                          # Line of 50 dash
args                = len(sys.argv)                                     # Nb. argument receive
osname              = os.name                                           # OS name (nt,dos,posix,...)
platform            = sys.platform                                      # Platform (darwin,linux)

# To calculate execution Time
start_time          = ""                                                # Script Start Date & Time
stop_time           = ""                                                # Script Stop Date & Time
start_epoch         = ""                                                # Script Start EPoch Time

# Logic to get O/S Distribution Information into Dictionnary os_dict
osrelease           = "/etc/os-release"                                 # Distribution Info file
os_dict             = {}                                                # Dict. for O/S Info
with open(osrelease) as f:                                              # Open /etc/os-release as f
    for line in f:                                                      # Process each line
        if len(line) < 2  : continue                                    # Skip empty Line
        if line[0].strip == "#" : continue                              # Skip line beginning with #
        k,v = line.rstrip().split("=")                                  # Get Key,Value of each line
        os_dict[k] = v.strip('"')                                       # Store info in Dictionnary




#===================================================================================================
#                                   SADM Python Tools Library
#===================================================================================================
class sadmtools():
    """ Series of method to that can be used to administer a Linux/Aix Farm.

        Requirements : 
            - You MUST have an environment variable named "SADMIN" that contain name of the root
              install directory (SADMIN="/opt/sadmin") of the SADMIN tools.
            - You MUST include the Global variables of the "SADMIN Section" in your script. 
    """

    # SADMIN Tools Initialization
    def __init__(self):
        """ __init__ : Series of method to that can be used to administer a Linux/Aix Farm.

        Requirements : 
            - You MUST have an environment variable named "SADMIN" that contain name of the root
              install directory (SADMIN="/opt/sadmin") of the SADMIN tools.
            - You MUST include the Global variables of the "SADMIN Section" in your script. 
        """

        # Making Sure SADMIN Environment Variable is Define & import 'sadmlib_std.py' if can be found.
        self.base_dir = os.environ.get('SADMIN')                    # Set SADM Base Directory
        if self.base_dir is None:
            print ("'SADMIN' Environment Variable isn't defined.")      # SADMIN Var MUST be defined
            print ("It specify the directory where you installed the SADMIN Tools")
            print ("Add this line at the end of /etc/environment file") # Show Where to Add Env. Var
            print ("export SADMIN='/[dir-where-you-install-sadmin]'")   # Show What to Add.
            print ("Then logout and log back in and run this script again.")
            sys.exit(1)                                                 # Exit to O/S with Error 1

        # Set Default Values for Script Related Variables
        self.libver             = "3.26"                                # This Library Version
        self.log_type           = "B"                                   # 4Logger S=Scr L=Log B=Both
        self.log_append         = True                                  # Append to Existing Log ?
        self.log_header         = True                                  # True = Produce Log Header
        self.log_footer         = True                                  # True = Produce Log Footer
        self.ver                = "1.0"                                 # Default Program Version
        self.multiple_exec      = "N"                                   # Default Run multiple copy
        self.use_rch            = True                                  # True=Use RCH File else No
        self.pn                 = os.path.basename(sys.argv[0])         # Program name
        self.inst               = os.path.basename(sys.argv[0]).split('.')[0] # Pgm name without Ext
        self.tpid               = str(os.getpid())                      # Get Current Process ID.
        self.exit_code          = 0                                     # Set Default Return Code
        self.debug              = 0                                     # Script Debug Level (0-9)
        self.lib_debug          = 0                                     # Library Debug Level (0-9)
        self.dbsilent           = False                                 # True or False Show ErrMsg
        self.usedb              = False                                 # Use or Not MySQL DB

        # O/S Info
        self.hostname           = socket.gethostname().split('.')[0]    # Get current hostname
        self.os_type            = self.get_ostype()                     # Upper O/S LINUX,AIX,DARWIN
        self.username           = getpass.getuser()                     # Get Current User Name

        # SADM Sub Directories Definitions
        self.lib_dir            = os.path.join(self.base_dir,'lib')     # SADM Lib. Directory
        self.tmp_dir            = os.path.join(self.base_dir,'tmp')     # SADM Temp. Directory
        self.bin_dir            = os.path.join(self.base_dir,'bin')     # SADM Scripts Directory
        self.log_dir            = os.path.join(self.base_dir,'log')     # SADM Log Directory
        self.pkg_dir            = os.path.join(self.base_dir,'pkg')     # SADM Package Directory
        self.cfg_dir            = os.path.join(self.base_dir,'cfg')     # SADM Config Directory
        self.sys_dir            = os.path.join(self.base_dir,'sys')     # SADM System Scripts Dir.
        self.dat_dir            = os.path.join(self.base_dir,'dat')     # SADM Data Directory
        self.doc_dir            = os.path.join(self.base_dir,'doc')     # SADM Documentation Dir.
        self.nmon_dir           = os.path.join(self.dat_dir,'nmon')     # SADM nmon File Directory
        self.rch_dir            = os.path.join(self.dat_dir,'rch')      # SADM Result Code Dir.
        self.dr_dir             = os.path.join(self.dat_dir,'dr')       # SADM Disaster Recovery Dir
        self.net_dir            = os.path.join(self.dat_dir,'net')      # SADM Network/Subnet Dir
        self.rpt_dir            = os.path.join(self.dat_dir,'rpt')      # SADM Sysmon Report Dir.
        self.dbb_dir            = os.path.join(self.dat_dir,'dbb')      # SADM Database Backup Dir.
        self.setup_dir          = os.path.join(self.base_dir,'setup')   # SADM Setup Directory

        # SADM User Directories Structure
        self.usr_dir            = os.path.join(self.base_dir,'usr')     # SADM User Directory
        self.ubin_dir           = os.path.join(self.usr_dir,'bin')      # SADM User Bin Dir.
        self.ulib_dir           = os.path.join(self.usr_dir,'lib')      # SADM User Lib Dir.
        self.udoc_dir           = os.path.join(self.usr_dir,'doc')      # SADM User Doc Dir.
        self.umon_dir           = os.path.join(self.usr_dir,'mon')      # SADM Usr SysMon Script Dir

        # SADM Web Site Directories Structure
        self.www_dir            = os.path.join(self.base_dir,'www')     # SADM WebSite Dir Structure
        self.www_dat_dir        = os.path.join(self.www_dir,'dat')      # SADM Web Site Data Dir
        self.www_arc_dir        = os.path.join(self.www_dat_dir,'archive') # SADM WebSite ArchiveDir
        self.www_doc_dir        = os.path.join(self.www_dir,'doc')      # SADM Web Site Doc Dir
        self.www_lib_dir        = os.path.join(self.www_dir,'lib')      # SADM Web Site Lib Dir
        self.www_tmp_dir        = os.path.join(self.www_dir,'tmp')      # SADM Web Site Tmp Dir
        self.www_perf_dir       = os.path.join(self.www_tmp_dir,'perf') # SADM Web Perf. Graph Dir
        self.www_net_dir        = self.www_dat_dir + '/' + self.hostname + '/net' # Web Data Net.Dir

        # SADM Files Definition
        self.log_file           = self.log_dir + '/' + self.hostname + '_' + self.inst + '.log'
        self.rch_file           = self.rch_dir + '/' + self.hostname + '_' + self.inst + '.rch'
        self.rpt_file           = self.rpt_dir + '/' + self.hostname + '.rpt'
        self.cfg_file           = self.cfg_dir + '/sadmin.cfg'          # Configuration Filename
        self.cfg_hidden         = self.cfg_dir + '/.sadmin.cfg'         # Hidden Config Filename
        self.alert_file         = self.cfg_dir + '/alert_group.cfg'     # AlertGroup Definition File
        self.alert_init         = self.cfg_dir + '/.alert_group.cfg'    # AlertGroup Initial File
        self.alert_hist         = self.cfg_dir + '/alert_history.txt'   # Alert History Text File
        self.alert_hini         = self.cfg_dir + '/.alert_history.txt'  # Alert History Initial File
        #self.crontab_work       = self.www_lib_dir + '/.crontab.txt'   # Work crontab
        #self.crontab_file       = '/etc/cron.d/sadmin'                 # Final crontab
        self.rear_newcron       = self.cfg_dir + '.sadm_rear_backup'    # Tmp Cron for Rear Backup
        self.rear_crontab       = self.cfg_dir + '/etc/cron.d/sadm_rear_backup' # Real Rear Crontab
        self.rear_exclude_init  = self.cfg_dir + '/.rear_exclude.txt'   # Rear Init exclude List
        self.backup_list        = self.cfg_dir + '/backup_list.txt'     # FileName & Dir. to Backup
        self.backup_list_init   = self.cfg_dir + '/.backup_list.txt'    # Initial File/Dir. 2 Backup
        self.backup_exclude     = self.cfg_dir + '/backup_exclude.txt'  # Exclude File/Dir 2 Exclude
        self.backup_exclude_init= self.cfg_dir + '/.backup_exclude.txt' # Initial File/Dir 2 Exclude
        self.rel_file           = self.cfg_dir + '/.release'            # SADMIN Release Version No.
        self.dbpass_file        = self.cfg_dir + '/.dbpass'             # SADMIN DB User/Pwd file
        self.pid_file           = "%s/%s.pid" % (self.tmp_dir, self.inst) # Process ID File
        #self.tmp_file_prefix    = self.tmp_dir + '/' + self.hostname + '_' + self.inst # TMP Prefix
        self.tmp_file_prefix    = self.tmp_dir + '/' + self.inst        # TMP Prefix
        self.tmp_file1          = "%s_1.%s" % (self.tmp_file_prefix,self.tpid)  # Temp1 Filename
        self.tmp_file2          = "%s_2.%s" % (self.tmp_file_prefix,self.tpid)  # Temp2 Filename
        self.tmp_file3          = "%s_3.%s" % (self.tmp_file_prefix,self.tpid)  # Temp3 Filename

        # SADM Configuration file (sadmin.cfg) content loaded from configuration file
        self.cfg_alert_type             = 1                             # 0=No 1=Err 2=Succes 3=All
        self.cfg_alert_group            = "default"                     # Defined in alert_group.cfg
        self.cfg_alert_repeat           = 43200                         # Alarm Repeat Wait Time Sec
        self.cfg_textbelt_key           = "textbelt"                    # Textbelt.com Def. API Key
        self.cfg_textbelt_url           = "https://textbelt.com/text"   # Textbelt.com Def. API URL
        self.cfg_host_type              = ""                            # [C or S] Client or Server
        self.cfg_mail_addr              = ""                            # Default is in sadmin.cfg
        self.cfg_cie_name               = ""                            # Company Name
        self.cfg_user                   = ""                            # sadmin user account
        self.cfg_group                  = ""                            # sadmin group account
        self.cfg_www_user               = ""                            # sadmin/www user account
        self.cfg_www_group              = ""                            # sadmin/www group owner
        self.cfg_server                 = ""                            # sadmin FQN Server
        self.cfg_domain                 = ""                            # sadmin Default Domain
        self.cfg_max_logline            = 5000                          # Max Nb. Lines in LOG )
        self.cfg_max_rchline            = 100                           # Max Nb. Lines in RCH file
        self.cfg_nmon_keepdays          = 60                            # Days to keep old *.nmon
        self.cfg_rch_keepdays           = 60                            # Days to keep old *.rch
        self.cfg_log_keepdays           = 60                            # Days to keep old *.log
        self.cfg_dbname                 = ""                            # MySQL Database Name
        self.cfg_dbhost                 = ""                            # MySQL Database Host
        self.cfg_dbport                 = 3306                          # MySQL Database Port
        self.cfg_rw_dbuser              = ""                            # MySQL Read Write User
        self.cfg_rw_dbpwd               = ""                            # MySQL Read Write Pwd
        self.cfg_ro_dbuser              = ""                            # MySQL Read Only User
        self.cfg_ro_dbpwd               = ""                            # MySQL Read Only Pwd
        self.cfg_ssh_port               = 22                            # SSH Port used in Farm
        self.cfg_rrdtool                = ""                            # RRDTool location
        self.cfg_backup_nfs_server      = ""                            # Backup NFS Server
        self.cfg_backup_nfs_mount_point = ""                            # Backup Mount Point
        self.cfg_daily_backup_to_keep   = 3                             # Nb Daily Backup to keep
        self.cfg_weekly_backup_to_keep  = 3                             # Nb Weekly Backup to keep
        self.cfg_monthly_backup_to_keep = 3                             # Nb Monthly Backup to keep
        self.cfg_yearly_backup_to_keep  = 3                             # Nb Yearly Backup to keep
        self.cfg_weekly_backup_day      = 5                             # Weekly Backup Day (1=Mon.)
        self.cfg_monthly_backup_date    = 1                             # Monthly Backup Date (1-28)
        self.cfg_yearly_backup_month    = 12                            # Yearly Backup Month (1-12)
        self.cfg_yearly_backup_date     = 31                            # Yearly Backup Date(1-31)
        self.cfg_rear_nfs_server        = ""                            # Rear NFS Server
        self.cfg_rear_nfs_mount_point   = ""                            # Rear NFS Mount Point
        self.cfg_rear_backup_to_keep    = 3                             # Nb of Rear Backup to keep
        self.cfg_storix_nfs_server      = ""                            # Storix Nfs Server
        self.cfg_storix_mount_point     = ""                            # Storix NFS Mount Point
        self.cfg_storix_backup_to_keep  = 3                             # Nb Storix Backup to Keep
        self.cfg_mksysb_nfs_server      = ""                            # Aix Mksysb Nfs Server
        self.cfg_mksysb_mount_point     = ""                            # Aix Mksysb NFS Mount Point
        self.cfg_mksysb_backup_to_keep  = 3                             # Aix Mksysb Backup to Keep
        self.cfg_network1               = ""                            # Network Subnet 1 to report
        self.cfg_network2               = ""                            # Network Subnet 2 to report
        self.cfg_network3               = ""                            # Network Subnet 3 to report
        self.cfg_network4               = ""                            # Network Subnet 4 to report
        self.cfg_network5               = ""                            # Network Subnet 5 to report
        self.cfg_monitor_update_interval = 60                           # Monitor Page Upd Interval

        # O/S Path to various commands used by SADM Tools
        self.which              = "/usr/bin/which"                      # which Path - Required
        self.dmidecode          = ""                                    # Command dmidecode Path
        self.bc                 = ""                                    # Command bc (Do Some Math)
        self.fdisk              = ""                                    # fdisk (Read Disk Capacity)
        self.perl               = ""                                    # perl Path (for epoch time)
        self.uname              = ""                                    # uname command path
        self.mail               = ""                                    # mail command path
        self.ssh                = ""                                    # ssh command path
        self.nmon               = ""                                    # nmon command path
        self.lscpu              = ""                                    # lscpu command path
        self.parted             = ""                                    # parted command path
        self.ethtool            = ""                                    # ethtool command path
        self.curl               = ""                                    # curl command path
        self.mutt               = ""                                    # mutt command path
        self.rrdtool            = ""                                    # rrdtool command path

        self.load_config_file(self.cfg_file)                            # Load sadmin.cfg in cfg var
        self.check_requirements()                                       # Check SADM Requirement Met
        self.ssh_cmd = "%s -qnp %s " % (self.ssh,self.cfg_ssh_port)     # Build SSH Command we use



    #-----------------------------------------------------------------------------------------------
    # Function called when the '-v --version' command line argument are used.
    #-----------------------------------------------------------------------------------------------
    def show_version(self):
        print ("Script Name",os.path.basename(sys.argv[0]),"- Version",self.ver)
        print ("SADMIN Shell Library Version",self.libver)
        print ("O/S is",self.get_osname(),"- Version ",self.get_osversion())
        print ("Kernel Version ",self.get_kernel_version())
        #print ("\n")


    #-----------------------------------------------------------------------------------------------
    # CONNECT TO THE DATABASE ----------------------------------------------------------------------
    # return (0) if no error - return (1) if error encountered
    #-----------------------------------------------------------------------------------------------
    def dbconnect(self):
        self.enum = 0                                                   # Reset Error Number
        self.emsg = ""                                                  # Reset Error Message

        # No Connection to Database is possible if not on the SADMIN Server
        if self.get_fqdn() != self.cfg_server :                         # Only on SADMIN
           print ("Can't connect to database if you aren't on SADMIN Server %s " % (self.cfg_server))
           sys.exit(1)                                                 # Exit Pgm with Error Code 1

        # No Connection to DAtabase if user decided not to use it.
        if not self.usedb :                                             # Only User Want to use DB
           print ("Attribute st.usedb is set to False, Should not be calling Method dbconnect")
           sys.exit(1)                                                  # Exit Pgm with Error Code 1

        # Setup Database Connection
        conn_string  = "'%s', " % (self.cfg_dbhost)
        conn_string += "'%s', " % (self.cfg_rw_dbuser)
        conn_string += "'%s', " % (self.cfg_rw_dbpwd)
        conn_string += "'%s'"   % (self.cfg_dbname)
        if (self.lib_debug > 3) :                                       # Debug Display Conn. Info
            print ("Connect(%s)" % (conn_string))

        # Try to connect to Database
        try :
            self.conn = pymysql.connect(host=self.cfg_dbhost,
                             user=self.cfg_rw_dbuser,
                             password=self.cfg_rw_dbpwd,
                             database=self.cfg_dbname,
#                             charset='utf8mb4',
                             cursorclass=pymysql.cursors.DictCursor)

            #self.conn=pymysql.connect(self.cfg_dbhost,self.cfg_rw_dbuser,self.cfg_rw_dbpwd,self.cfg_dbname)
        except pymysql.err.OperationalError as error : 
            self.enum, self.emsg = error.args                           # Get Error No. & Message
            self.writelog("Error connecting to database '%s'" % (self.cfg_dbname))
            errmsg  = ">>>>>>>>>>>>>"                                   # Error Message Part 1    
            errmsg += "'%s' " % (self.enum)                             # Error Message Part 2
            errmsg += "'%s' " % (self.emsg)                             # Error Message Part 3
            self.writelog(errmsg)                                       # Print Error No. & Message
            self.stop (1)                                               # Close and Trim Log/Email
            sys.exit(1)                                                 # Exit Pgm with Error Code 1
        except pymysql.err.InternalError as error :
            self.enum, self.emsg = error.args                           # Get Error No. & Message
            self.writelog("Error connecting to Database '%s'" % (self.cfg_dbname))
            errmsg  = ">>>>>>>>>>>>>"                                   # Error Message Part 1    
            errmsg += "'%s' " % (self.enum)                             # Error Message Part 2
            errmsg += "'%s' " % (self.emsg)                             # Error Message Part 3
            self.writelog(errmsg)                                       # Print Error No. & Message
            self.stop (1)                                               # Close and Trim Log/Email
            sys.exit(1)                                                 # Exit Pgm with Error Code 1

        # Define a cursor object using cursor() method
        try :
            self.cursor = self.conn.cursor()                            # Create Database cursor
        #except AttributeError pymysql.InternalError as error:
        except Exception as error:
            self.enum, self.emsg = error.args                           # Get Error No. & Message
            print ("Error creating cursor for %s" % (self.dbname))      # Inform User print DB Name
            print (">>>>>>>>>>>>>",self.enum,self.emsg)                 # Print Error No. & Message
            sys.exit(1)                                                 # Exit Pgm with Error Code 1

        return(self.conn,self.cursor)



    #-----------------------------------------------------------------------------------------------
    # CLOSE THE DATABASE ---------------------------------------------------------------------------
    # return (0) if no error - return (1) if error encountered
    #-----------------------------------------------------------------------------------------------
    def dbclose(self):
        self.enum = 0                                                   # Reset Error Number
        self.emsg = ""                                                  # Reset Error Message
        try:
            if self.lib_debug > 4 : print ("Closing Cursor & Database %s" % (self.cfg_dbname))
            self.cursor.close()
            self.conn.close()
        except Exception as e:
            print ("type e = ",type(e))
            print ("e.args = ",e.args)
            print ("e = ",e)
            self.enum, self.emsg = e.args                               # Get Error No. & Message
            if  (not self.dbsilent):                                    # If not in Silent Mode
                #print (">>>>>>>>>>>>>",e.message,e.args)               # Print Error No. & Message
                print (">>>>>>>>>>>>>",e.args)                          # Print Error No. & Message
                return (1)                                              # return (1) to Show Error
        return(0)


    # ----------------------------------------------------------------------------------------------
    #            LOAD SADMIN CONFIGURATION FILE AND SET GLOBAL VARIABLES ACCORDINGLY
    # ----------------------------------------------------------------------------------------------
    def load_config_file(self,sadmcfg):

        # Debug Level Higher than 4 , inform that entering Load configuration file
        if self.lib_debug > 4 :                                         # If Debug Run Level 4
            print ("Load Configuration file %s" % (self.cfg_file))      # Inform user in Debug

        # Configuration file MUST be present :
        # If Not Present, copy $SADMIN/.sadm_config to $SADMIN/sadmin.cfg
        if  not os.path.exists(self.cfg_file) :                         # If Config file not Exist
            if not os.path.exists(self.cfg_hidden) :                    # If Std Init Config ! Exist
                print ("****************************************************************")
                print ("SADMIN Configuration file %s cannot be found" % (self.cfg_file))
                print ("Even the config template file %s cannot be found" % (self.cfg_hidden))
                print ("Copy both files from another system to this server")
                print ("Or restore the files from a backup & review the file content.")
                print ("****************************************************************")
            else :
                print ("****************************************************************")
                print ("The configuration file %s doesn't exist." % (self.cfg_file))
                print ("Will continue using template configuration file %s" & (self.cfg_hidden))
                print ("Please review the configuration file.")
                print ("cp %s %s " % (self.cfg_hidden, self.cfg_file))  # Install Default cfg  file
                cmd = "cp %s %s"% "cp %s %s " % (self.cfg_hidden, self.cfg_file) # Copy Default cfg
                ccode, cstdout, cstderr = self.oscommand(cmd)
                print ("****************************************************************")
                if not ccode == 0 :
                    print ("Could not copy %s to %s" % (self.cfg_hidden, self.cfg_file))
                    print ("Script need a valid %s to run - Script aborted" % (self.cfg_file))
                    print ("Restore the file from a backup & review the file content.")
                    sys.exit(1)

        # Open Configuration file
        try:
            FH_CFG_FILE = open(self.cfg_file,'r')                       # Open Config File
        except IOError as e:                                            # If Can't open cfg file
            print ("Error opening file %s \r\n" % self.cfg_file)        # Print Config FileName
            print ("Error Number : {0}\r\n.format(e.errno)")            # Print Error Number
            print ("Error Text   : {0}\r\n.format(e.strerror)")         # Print Error Message
            sys.exit(1)

        # Read Configuration file and Save Options values
        for cfg_line in FH_CFG_FILE :                                   # Loop until on all servers
            wline        = cfg_line.strip()                             # Strip CR/LF & Trail spaces
            if (wline[0:1] == '#' or len(wline) == 0) :                 # If comment or blank line
                continue                                                # Go read the next line
            split_line   = wline.split('=')                             # Split based on equal sign
            CFG_NAME   = split_line[0].upper().strip()                  # Param Name Uppercase Trim
            CFG_VALUE  = str(split_line[1]).strip()                     # Get Param Value Trimmed

            if (self.lib_debug) :                                       # Debug = Print Line
                print("cfgline = ..." + CFG_NAME + "...  ..." + CFG_VALUE + "...")

            # Save Each Parameter found in Sadmin Configuration File
            if "SADM_MAIL_ADDR"              in CFG_NAME:  self.cfg_mail_addr      = CFG_VALUE
            if "SADM_CIE_NAME"               in CFG_NAME:  self.cfg_cie_name       = CFG_VALUE
            if "SADM_ALERT_TYPE"             in CFG_NAME:  self.cfg_alert_type     = int(CFG_VALUE)
            if "SADM_ALERT_GROUP"            in CFG_NAME:  self.cfg_alert_group    = CFG_VALUE
            if "SADM_ALERT_REPEAT"           in CFG_NAME:  self.cfg_alert_repeat   = int(CFG_VALUE)
            if "SADM_TEXTBELT_KEY"           in CFG_NAME:  self.cfg_textbelt_key   = CFG_VALUE
            if "SADM_TEXTBELT_URL"           in CFG_NAME:  self.cfg_textbelt_url   = CFG_VALUE
            if "SADM_HOST_TYPE"              in CFG_NAME:  self.cfg_host_type      = CFG_VALUE
            if "SADM_SERVER"                 in CFG_NAME:  self.cfg_server         = CFG_VALUE
            if "SADM_DOMAIN"                 in CFG_NAME:  self.cfg_domain         = CFG_VALUE
            if "SADM_USER"                   in CFG_NAME:  self.cfg_user           = CFG_VALUE
            if "SADM_GROUP"                  in CFG_NAME:  self.cfg_group          = CFG_VALUE
            if "SADM_WWW_USER"               in CFG_NAME:  self.cfg_www_user       = CFG_VALUE
            if "SADM_WWW_GROUP"              in CFG_NAME:  self.cfg_www_group      = CFG_VALUE
            if "SADM_SSH_PORT"               in CFG_NAME:  self.cfg_ssh_port       = int(CFG_VALUE)
            if "SADM_MAX_LOGLINE"            in CFG_NAME:  self.cfg_max_logline    = int(CFG_VALUE)
            if "SADM_MAX_RCHLINE"            in CFG_NAME:  self.cfg_max_rchline    = int(CFG_VALUE)
            #
            if "SADM_NMON_KEEPDAYS"          in CFG_NAME:  self.cfg_nmon_keepdays  = int(CFG_VALUE)
            if "SADM_RCH_KEEPDAYS"           in CFG_NAME:  self.cfg_rch_keepdays   = int(CFG_VALUE)
            if "SADM_LOG_KEEPDAYS"           in CFG_NAME:  self.cfg_log_keepdays   = int(CFG_VALUE)
            #
            if "SADM_DBNAME"                 in CFG_NAME:  self.cfg_dbname         = CFG_VALUE
            if "SADM_DBHOST"                 in CFG_NAME:  self.cfg_dbhost         = CFG_VALUE
            if "SADM_DBPORT"                 in CFG_NAME:  self.cfg_dbport         = int(CFG_VALUE)
            if "SADM_RW_DBUSER"              in CFG_NAME:  self.cfg_rw_dbuser      = CFG_VALUE
            if "SADM_RO_DBUSER"              in CFG_NAME:  self.cfg_ro_dbuser      = CFG_VALUE
            #
            if "SADM_BACKUP_NFS_SERVER"      in CFG_NAME: self.cfg_backup_nfs_server     = CFG_VALUE
            if "SADM_BACKUP_NFS_MOUNT_POINT" in CFG_NAME: self.cfg_backup_nfs_mount_point= CFG_VALUE
            if "SADM_DAILY_BACKUP_TO_KEEP"   in CFG_NAME: self.cfg_daily_backup_to_keep  = int(CFG_VALUE)
            if "SADM_WEEKLY_BACKUP_TO_KEEP"  in CFG_NAME: self.cfg_weekly_backup_to_keep = int(CFG_VALUE)
            if "SADM_MONTHLY_BACKUP_TO_KEEP" in CFG_NAME: self.cfg_monthly_backup_to_keep= int(CFG_VALUE)
            if "SADM_YEARLY_BACKUP_TO_KEEP"  in CFG_NAME: self.cfg_yearly_backup_to_keep = int(CFG_VALUE)
            if "SADM_WEEKLY_BACKUP_DAY"      in CFG_NAME: self.cfg_weekly_backup_day     = int(CFG_VALUE)
            if "SADM_MONTHLY_BACKUP_DATE"    in CFG_NAME: self.cfg_monthly_backup_date   = int(CFG_VALUE)
            if "SADM_YEARLY_BACKUP_MONTH"    in CFG_NAME: self.cfg_yearly_backup_month   = int(CFG_VALUE)
            if "SADM_YEARLY_BACKUP_DATE"     in CFG_NAME: self.cfg_yearly_backup_date    = int(CFG_VALUE)
            #
            if "SADM_REAR_NFS_SERVER"        in CFG_NAME: self.cfg_rear_nfs_server       = CFG_VALUE
            if "SADM_REAR_NFS_MOUNT_POINT"   in CFG_NAME: self.cfg_rear_nfs_mount_point  = CFG_VALUE
            if "SADM_REAR_BACKUP_TO_KEEP"    in CFG_NAME: self.cfg_rear_backup_to_keep   = int(CFG_VALUE)
            #
            if "SADM_STORIX_NFS_SERVER"      in CFG_NAME: self.cfg_storix_nfs_server     = CFG_VALUE
            if "SADM_STORIX_NFS_MOUNT_POINT" in CFG_NAME: self.cfg_storix_mount_point    = CFG_VALUE
            if "SADM_STORIX_BACKUP_TO_KEEP"  in CFG_NAME: self.cfg_storix_backup_to_keep = int(CFG_VALUE)
            #
            if "SADM_MKSYSB_NFS_SERVER"      in CFG_NAME: self.cfg_mksysb_nfs_server     = CFG_VALUE
            if "SADM_MKSYSB_NFS_MOUNT_POINT" in CFG_NAME: self.cfg_mksysb_nfs_mount_point= CFG_VALUE
            if "SADM_MKSYSB_BACKUP_TO_KEEP"  in CFG_NAME: self.cfg_mksysb_backup_to_keep = int(CFG_VALUE)
            #
            if "SADM_NETWORK1"               in CFG_NAME: self.cfg_network1        = CFG_VALUE
            if "SADM_NETWORK2"               in CFG_NAME: self.cfg_network2        = CFG_VALUE
            if "SADM_NETWORK3"               in CFG_NAME: self.cfg_network3        = CFG_VALUE
            if "SADM_NETWORK4"               in CFG_NAME: self.cfg_network4        = CFG_VALUE
            if "SADM_NETWORK5"               in CFG_NAME: self.cfg_network5        = CFG_VALUE
            if "SADM_MONITOR_UPDATE_INTERVAL" in CFG_NAME: self.cfg_monitor_update_interval = CFG_VALUE
        FH_CFG_FILE.close()                                                 # Close Config File

        # Get Database User Password get .dbpass file (Read 'sadmin' and 'squery' user pwd)
        if ((self.get_fqdn() == self.cfg_server) and (self.cfg_host_type == "S")): # Only on SADMIN & Use DB
            try:
                FH_DBPWD = open(self.dbpass_file,'r')                   # Open DB Password File
            except IOError as e:                                        # If Can't open DB Pwd  file
                print ("Error opening file %s \r\n" % self.dbpass_file) # Print DBPass FileName
                sys.exit(1)
            for dbline in FH_DBPWD :                                    # Loop until on all lines
                wline = dbline.strip()                                  # Strip CR/LF & Trail spaces
                if (wline[0:1] == '#' or len(wline) == 0) :             # If comment or blank line
                    continue                                            # Go read the next line
                if wline.startswith(self.cfg_rw_dbuser) :               # LineStart with RW UserName
                    split_line = wline.split(',')                       # Split Line based on comma
                    self.cfg_rw_dbpwd  = split_line[1]                  # Set DB R/W 'sadmin' Passwd
                if wline.startswith(self.cfg_ro_dbuser) :               # Line begin with 'squery,'
                    split_line = wline.split(',')                       # Split Line based on comma
                    self.cfg_ro_dbpwd  = split_line[1]                  # Set DB R/O 'squery' Passwd
            FH_DBPWD.close()                                            # Close DB Password file
        else :
            self.cfg_rw_dbpwd  = ''                                     # Set DB R/W 'sadmin' Passwd
            self.cfg_ro_dbpwd  = ''                                     # Set DB R/O 'squery' Passwd
        return



    # ----------------------------------------------------------------------------------------------
    #                         Write Log to Log File, Screen or Both
  
    def writelog(self,sline,stype="normal"):
    
        global FH_LOG_FILE
        now = datetime.datetime.now()
        part1 = now.strftime("%Y.%m.%d %H:%M:%S") + " - "
        part2 = "%s" % (sline)
        logLine = part1 + part2

        # Record Line in Log
        if (self.log_type.upper() == "L") or (self.log_type.upper() == "B") :
            FH_LOG_FILE.write ("%s\n" % (logLine))

        # Display Line on Screen
        if (self.log_type.upper() == "S") or (self.log_type.upper() == "B") :
            if (stype == "normal") :
                print ("%s" % sline)
            if (stype == "nonl") :
                print ("%s" % sline, end='')
            if (stype == "bold") :
                class color:
                    DARKCYAN    = '\033[36m'
                    BOLD        = '\033[1m'
                    END         = '\033[0m'
                print (color.DARKCYAN + color.BOLD + sline + color.END)


    # ----------------------------------------------------------------------------------------------
    #  EXECUTE the command received 
    # ----------------------------------------------------------------------------------------------
    def oscommand(self,command) :

        if self.lib_debug > 8 : self.writelog ("In sadm_oscommand function to run command : %s" % (command))
        p = subprocess.Popen(command, stdout=PIPE, stderr=PIPE, shell=True)
        out = p.stdout.read().strip().decode()
        err = p.stderr.read().strip().decode()
        returncode = p.wait()
        if self.lib_debug > 8 :
            self.writelog ("In sadm_oscommand function stdout is      : %s" % (out))
            self.writelog ("In sadm_oscommand function stderr is      : %s " % (err))
            self.writelog ("In sadm_oscommand function returncode is  : %s" % (returncode))
        #if returncode:
        #    raise Exception(returncode,err)
        #else :
        return (returncode,out,err)


    # ----------------------------------------------------------------------------------------------
    #               FUNCTION REMOVE THE FILENAME RECEIVED -- IT'S OK IF REMOVE FAILED
    # ----------------------------------------------------------------------------------------------
    def silentremove(self,filename):
        try:
            os.remove(filename)                                         # Remove selected file
        except OSError as e:                                            # If OSError
            if e.errno != errno.ENOENT :                                # errno.no such file or Dir.
                raise                                                   # raise exception if diff.err



    # ----------------------------------------------------------------------------------------------
    #                                 RETURN SADMIN RELEASE VERSION NUMBER
    # ----------------------------------------------------------------------------------------------
    def get_release(self) :
        if os.path.exists(self.rel_file):
            wcommand = "head -1 %s" % (self.rel_file)
            ccode, cstdout, cstderr = self.oscommand("%s" % (wcommand)) # Execute O/S CMD
            wrelease=cstdout
        else:
            wrelease="00.00"
        return wrelease


    # ----------------------------------------------------------------------------------------------
    # DETERMINE THE INSTALLATION PACKAGE TYPE OF CURRENT O/S 
    # ----------------------------------------------------------------------------------------------
    def get_packagetype(self):
        packtype=""                                                     # Initial Packaging is None
        if (self.locate_command('rpm')   != "") : packtype="rpm"        # Is rpm command on system ?
        if (self.locate_command('dpkg')  != "") : packtype="deb"        # is deb command on system ?
        if (self.locate_command('lslpp') != "") : packtype="lpp"        # Is lslpp cmd on system ?
        if (self.locate_command('launchctl') != "") : packtype="dmg"    # launchctl MacOS on system?
        if (packtype == ""):                                            # If unknow/unsupported O/S
            self.writelog ('None of these commands are found (rpm, pkg, dmg or lslpp absent)')
            self.writelog ('No supported package type is detected')
            self.writelog ('Process aborted')
            sys.exit(1)                                                     # Exit to O/S  
        return packtype


    # # ----------------------------------------------------------------------------------------------
    # #                                 RETURN THE HOSTNAME (SHORT)
    # # ----------------------------------------------------------------------------------------------
    # def get_hostname(self):
    #     cstdout="unknown"
    #     if self.os_type == "LINUX" :                                  # Under Linux
    #         ccode, cstdout, cstderr = self.oscommand("hostname -s")   # Execute O/S CMD
    #     if self.os_type == "AIX" :                                    # Under AIX
    #         ccode, cstdout, cstderr = self.oscommand("hostname")      # Execute O/S CMD
    #     whostname=cstdout.upper()
    #     return whostname


    # ----------------------------------------------------------------------------------------------
    #                                 RETURN THE DOMAINNAME
    # ----------------------------------------------------------------------------------------------
    def get_domainname(self):
        whostip = socket.gethostbyname(self.hostname)

        cmd = "host %s  | awk '{print $NF}' | cut -d. -f2-3" % whostip 
        ccode, cstdout, cstderr = self.oscommand(cmd)
        wdomainname=cstdout
        if wdomainname == "" or wdomainname == self.hostname : wdomainname = self.cfg_domain
        return wdomainname


    # ----------------------------------------------------------------------------------------------
    #                                 RETURN THE SERVER FQDN
    # ----------------------------------------------------------------------------------------------
    def get_fqdn(self):
        host_fqdn = "%s.%s" % (self.hostname,self.get_domainname())
        return (host_fqdn)


    # ----------------------------------------------------------------------------------------------
    #                              RETURN THE IP OF THE CURRENT HOSTNAME
    # ----------------------------------------------------------------------------------------------
    def get_host_ip(self):
        whostname = self.get_fqdn()
        whostip = socket.gethostbyname(whostname)
        return whostip


    # ----------------------------------------------------------------------------------------------
    # Return Current Epoch Time as an integer
    # ----------------------------------------------------------------------------------------------
    def get_epoch_time(self):
        return int(time.time())


    # ----------------------------------------------------------------------------------------------
    # Return a string with the format 'YYYY.MM.DD HH:MM:SS' based on the Epoch time received.
    # ----------------------------------------------------------------------------------------------
    def epoch_to_date(self,wepoch):
        ws = time.localtime(wepoch)
        wdate = "%04d.%02d.%02d %02d:%02d:%02d" % (ws[0],ws[1],ws[2],ws[3],ws[4],ws[5])
        return wdate


    # ----------------------------------------------------------------------------------------------
    # Return the epoch time of the date received ('YYYY.MM.DD HH:MM:SS')
    # ----------------------------------------------------------------------------------------------
    def date_to_epoch(self,wd):
        pattern = '%Y.%m.%d %H:%M:%S'
        we = int(time.mktime(time.strptime(wd, pattern)))
        return we


    # ----------------------------------------------------------------------------------------------
    # Calculate elapse time between date1 (YYYY.MM.DD HH:MM:SS) and date2 (YYYY.MM.DD HH:MM:SS)
    # Date 1 MUST be greater than date 2  (Date 1 = Like End time,  Date 2 = Start Time )
    # Return the elapse time in a string format 'HH:MM:SS'.
    # ----------------------------------------------------------------------------------------------
    def elapse_time(self,wend,wstart):
        whour=00 ; wmin=00 ; wsec=00                                    # Initialize return value
        epoch_start = self.date_to_epoch(wstart)                        # Get Epoch for Start Time
        epoch_end   = self.date_to_epoch(wend)                          # Get Epoch for End Time
        epoch_elapse = epoch_end - epoch_start                          # Substract End - Start time
        # Calculate number of hours (1 hr = 3600 Seconds)
        if epoch_elapse > 3599 :                                        # If nb Sec Greater than 1Hr
            whour = epoch_elapse / 3600                                 # Calculate nb of Hours
            epoch_elapse = epoch_elapse - (whour * 3600)                # Sub Hr*Sec from elapse

        # Calculate number of minutes 1 Min = 60 Seconds)
        if epoch_elapse > 59 :                                          # If more than 1 min left
            wmin = epoch_elapse / 60                                    # Calc. Nb of minutes
            epoch_elapse = epoch_elapse - (wmin * 60)                   # Sub Min*Sec from elapse

        wsec = epoch_elapse                                             # left is less than 60 sec
        sadm_elapse= "%02d:%02d:%02d" % (whour,wmin,wsec)               # Format Result
        return(sadm_elapse)                                             # Return Result to caller

    # ----------------------------------------------------------------------------------------------
    #                     Return if running 32 or 64 Bits Kernel version
    # ----------------------------------------------------------------------------------------------
    def get_kernel_bitmode(self):
        cstdout = 64
        if self.os_type == "LINUX" :                                    # Under Linux
            ccode, cstdout, cstderr = self.oscommand("getconf LONG_BIT")
        if self.os_type == "AIX" :                                      # Under AIX
           ccode, cstdout, cstderr = self.oscommand("getconf KERNEL_BITMODE")
        wkbits=cstdout
        return wkbits


    # ----------------------------------------------------------------------------------------------
    #                                 RETURN KERNEL RUNNING VERSION
    # ----------------------------------------------------------------------------------------------
    def get_kernel_version(self):
        cstdout = "unknown"
        if self.os_type == "LINUX" :                                    # Under Linux
            ccode, cstdout, cstderr = self.oscommand("uname -r | cut -d. -f1-3")
        if self.os_type == "AIX" :                                      # Under AIX
            ccode, cstdout, cstderr = self.oscommand("uname -r")
        if self.os_type == "DARWIN" :                                   # Under MacOS
            ccode, cstdout, cstderr = self.oscommand("uname -mrs | awk '{ print $2 }'")
        wkver=cstdout
        return wkver


    # ----------------------------------------------------------------------------------------------
    #                                 RETURN SYSTEM ARCHITECTURE
    # ----------------------------------------------------------------------------------------------
    def get_arch(self):
        cstdout = "unknown"
        if self.os_type == "LINUX" :                                    # Under Linux
            ccode, cstdout, cstderr = self.oscommand("uname -m")
        if self.os_type == "AIX" :                                      # Under AIX
            ccode, cstdout, cstderr = self.oscommand("uname -p")
        if self.os_type == "DARWIN" :                                   # Under MacOS
            ccode, cstdout, cstderr = self.oscommand("uname -m")
        warch=cstdout
        return cstdout


    # ----------------------------------------------------------------------------------------------
    #                RETURN THE OS TYPE LINUX, AIX, DARWIN ) -- ALWAYS RETURNED IN UPPERCASE
    # ----------------------------------------------------------------------------------------------
    def get_ostype(self):
        ccode, cstdout, cstderr = self.oscommand("uname -s")
        wostype=cstdout.upper()
        return wostype



    # ----------------------------------------------------------------------------------------------
    #                   RETURN THE OS  NAME (ALWAYS RETURNED IN UPPERCASE)
    # ----------------------------------------------------------------------------------------------
    def get_osname(self) :
        if self.os_type == "DARWIN":
            wcmd = "sw_vers -productName | tr -d ' '"
            ccode, cstdout, cstderr = self.oscommand(wcmd)
            osname=cstdout.upper()
        if self.os_type == "LINUX":
            osname=os_dict['ID'].upper()
            if osname == "REDHATENTERPRISESERVER" : osname="REDHAT"
            if osname == "REDHATENTERPRISEAS"     : osname="REDHAT"
            if osname == "REDHATENTERPRISE"       : osname="REDHAT"
            if osname == "CENTOSSTREAM"           : osname="CENTOS"
        if self.os_type == "AIX" :
            osname="AIX"
        return osname


    # ----------------------------------------------------------------------------------------------
    #          RETURN CPU SERIAL Number (For the Raspberry - need to be check on other server)
    # ----------------------------------------------------------------------------------------------
    def get_serial(self):
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


    # ----------------------------------------------------------------------------------------------
    #                             RETURN THE OS PROJECT CODE NAME
    # ----------------------------------------------------------------------------------------------
    def get_oscodename(self) :
        oscodename=""
        #print ("self.os_type = %s major is ...%s..." % (self.os_type,self.get_osmajorversion()))
        if self.os_type == "DARWIN":
            if (self.get_osmajorversion() == "10.0")  : oscodename="Cheetah"
            if (self.get_osmajorversion() == "10.1")  : oscodename="Puma"
            if (self.get_osmajorversion() == "10.2")  : oscodename="Jaguar"
            if (self.get_osmajorversion() == "10.3")  : oscodename="Panther"
            if (self.get_osmajorversion() == "10.4")  : oscodename="Tiger"
            if (self.get_osmajorversion() == "10.5")  : oscodename="Leopard"
            if (self.get_osmajorversion() == "10.6")  : oscodename="Snow Leopard"
            if (self.get_osmajorversion() == "10.7")  : oscodename="Lion"
            if (self.get_osmajorversion() == "10.8")  : oscodename="Mountain Lion"
            if (self.get_osmajorversion() == "10.9")  : oscodename="Mavericks"
            if (self.get_osmajorversion() == "10.10") : oscodename="Yosemite"
            if (self.get_osmajorversion() == "10.11") : oscodename="El Capitan"
            if (self.get_osmajorversion() == "10.12") : oscodename="Sierra"
            if (self.get_osmajorversion() == "10.13") : oscodename="High Sierra"
            if (self.get_osmajorversion() == "10.14") : oscodename="Mojave"
            if (self.get_osmajorversion() == "10.15") : oscodename="Catalina"
            if (self.get_osmajorversion() == "11.2")  : oscodename="Big Sur"
            #xstr='SOFTWARE LICENSE AGREEMENT FOR macOS'
            #xfile='/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf'
            #wcmd='grep  "$xstr" "$xfile" | awk -F "macOS "  { print $NF} '
            #ccode, oscodename, cstderr = self.oscommand(wcmd)
        if self.os_type == "LINUX":
            try: 
                oscodename=os_dict['VERSION_CODENAME']
            except KeyError as e:     
                oscodename=""
        if self.os_type == "AIX" :
            oscodename="IBM AIX"
        return (oscodename)


    # ----------------------------------------------------------------------------------------------
    #                THIS FUNCTION DETERMINE THE OS (DISTRIBUTION) VERSION NUMBER
    # ----------------------------------------------------------------------------------------------
    def get_osversion(self) :
        osversion="0.0"                                                 # Default Value
        if self.os_type == "LINUX" :
            osversion=os_dict['VERSION_ID']
        if self.os_type == "DARWIN" :
            cmd = "sw_vers -productVersion"
            ccode, cstdout, cstderr = self.oscommand(cmd)
            osversion=cstdout
        if self.os_type == "AIX" :
            ccode, cstdout, cstderr = self.oscommand("uname -v")
            maj_ver=cstdout
            ccode, cstdout, cstderr = self.oscommand("uname -r")
            min_ver=cstdout
            osversion="%s.%s" % (maj_ver,min_ver)
        return osversion


    # ----------------------------------------------------------------------------------------------
    #                        RETURN THE OS (DISTRIBUTION) MAJOR VERSION
    # ----------------------------------------------------------------------------------------------
    def get_osmajorversion(self) :
        if self.os_type == "LINUX" :
            osversion=os_dict['VERSION_ID']
            osmajorversion=osversion.split('.')[0]
        if self.os_type == "AIX" :
            ccode, cstdout, cstderr = self.oscommand("uname -v")
            osmajorversion=cstdout
        if self.os_type == "DARWIN":
            wcmd = "sw_vers -productVersion | awk -F '.' '{print $1 \".\" $2}'"
            ccode, cstdout, cstderr = self.oscommand(wcmd)
            osmajorversion=cstdout
        return osmajorversion


    # ----------------------------------------------------------------------------------------------
    #                     RETURN THE OS (DISTRIBUTION) MINOR VERSION NUMBER
    # ----------------------------------------------------------------------------------------------
    def get_osminorversion(self) :
        if self.os_type == "LINUX" :
            osversion=os_dict['VERSION_ID']
            osversion=str(osversion)
            pos=osversion.find(".")
            if pos == -1 :
                osminorversion=""
            else:
                osminorversion=osversion.split('.')[1]
        if self.os_type == "AIX" :
            ccode, cstdout, cstderr = self.oscommand("uname -r")
            osminorversion=cstdout
        if self.os_type == "DARWIN":
            wcmd = "sw_vers -productVersion | awk -F '.' '{print $2}'"
            ccode, cstdout, cstderr = self.oscommand(wcmd)
            osminorversion=cstdout
        return osminorversion


    # ----------------------------------------------------------------------------------------------
    #         SEND AN EMAIL TO SYSADMIN DEFINE IN SADMIN.CFG WITH SUBJECT AND BODY RECEIVED
    # ----------------------------------------------------------------------------------------------
    def sendmail(self,wserver,wport,wuser,wpwd,wsub,wbody) :
        wfrom = self.cfg_user + "@" + self.cfg_server
        #pdb.set_trace()

        try :
            smtpserver = smtplib.SMTP(wserver, wport)
            smtpserver.ehlo()
            smtpserver.starttls()
            smtpserver.ehlo()
            if self.lib_debug > 4 :
                self.writelog ("Connect to %s:%s Successfully" % (wserver,wport))
            try:
                smtpserver.login (wuser, wpwd)
            except smtplib.SMTPException :
                self.writelog ("Authentication for %s Failed %s" % (wuser))
                smtpserver.close()
                return 1
            if self.lib_debug > 4 :
                self.writelog ("Login Successfully using %s" % (wuser))
            header = "To: " + wuser + '\n' + 'From: ' + wfrom + '\n' + 'Subject: ' + wsub + '\n'
            msg = header + '\n' + wbody + '\n\n'
            try:
                smtpserver.sendmail(wfrom, wuser, msg)
            except smtplib.SMTPException:
                self.writelog ("Email could not be send")
                smtpserver.close()
                return 1
        except (smtplib.SMTPException, socket.error, socket.gaierror, socket.herror) as e:
            self.writelog ("Connection to %s %s Failed" % (wserver,wport))
            self.writelog ("%s" % e)
            return 1
        if self.lib_debug > 4 :
            self.writelog ("Mail was sent successfully")
            smtpserver.close()
        return 0


    # ----------------------------------------------------------------------------------------------
    #         TRIM THE FILE RECEIVED AS FIRST PARAMETER (MAX LINES IN LOG AS 2ND PARAMATER)
    # ----------------------------------------------------------------------------------------------
    def trimfile(self,fname, nlines=500) :

        fcname = sys._getframe().f_code.co_name                             # Get Name current function
        nlines = int(nlines)                                                # Making sure nlines=integer

        # Debug Information
        if self.lib_debug > 8 : print ("Trim %s to %s lines." %  (fname, str(nlines)))

        # Check if fileName to trim exist
        if (not os.path.exists(fname)):                                     # If fileName doesn't exist
            print ("[ ERROR ] In '%s' function - File %s doesn't exist" % (fcname,fname))
            return 1
        tot_lines = len(open(fname).readlines())                            # Count total no. of lines

        # Create temporary file
        self.tmpfile = "%s/%s.%s" % (self.tmp_dir,self.inst,datetime.datetime.now().strftime("%y%m%d_%H%M%S"))

        # Open Temporary file in output mode
        try:
            FN=open(self.tmpfile,'w')                                       # Open Temp file for output
        except IOError as e:                                                # If Can't open output file
            print ("Error opening file %s" % fname)                         # Print FileName
            return 1

        # Use line cache module to read the lines
        for i in range(tot_lines - nlines + 1, tot_lines+1):                # Start Read at deisred line
            wline = linecache.getline(fname, i)                             # Get Desired line to keep
            FN.write ("%s" % (wline))                                       # Write line to tmpFile
        FN.flush()                                                          # Got to do it - Missing end
        FN.close()                                                          # Close tempFile

        # Debug Information
        if self.lib_debug > 8 :
            print ("Original Filename %s" % (fname))
            print ("TmpFileName %s" % (self.tmpfile))
            print ("Removing file %s" % (fname))


        # Remove original file
        try:
            os.remove(fname)                                                # Remove Original file
        except OSError as e:
            print ("[ ERROR ] in %s function - removing %s" % (fcname,fname))
            return 1

        # Rename tempFile to original file
        try:
            shutil.move (self.tmpfile,fname)                                # Rename tmp to original
        except OSError as e:
            print ("[ ERROR ] in %s function - Error renaming %s to %s" % (fcname,self.tmpfile,fname))
            print ("Rename Error: %s - %s." % (e.fname,e.strerror))
            return 1

        #cmd = "chmod 664 %s" % (fname)
        #ccode, cstdout, cstderr = self.oscommand(cmd)
        #if not ccode == 0 :
        #    print ("Error occured with command %s" % (cmd))
        #    print ("Command stdout : %s" % (cstdout))
        #    print ("Command stderr : %s" % (cstderr))
        #    return 1
        return 0


    # ----------------------------------------------------------------------------------------------
    #   THIS FUNCTION VERIFY IF THE COMMAND RECEIVED IN PARAMETER IS AVAILABLE ON THE SERVER
    # ----------------------------------------------------------------------------------------------
    def locate_command(self,cmd) :
        ccode,cstdout,cstderr = self.oscommand("%s %s" % (self.which,cmd))  # Try to Locate Command
        if ccode != 0 :                                                 # Command was not Found
            cmd_path=""                                                 # Cmd Path Null when Not fnd
        else :                                                          # If command Path is Found
            cmd_path = cstdout                                          # Save command Path
        return (cmd_path)                                               # Return Cmd Path


    # ----------------------------------------------------------------------------------------------
    # This function tries to locate every command that the SADMIN tools library or scripts may need.
    # Theses commands are use to supply the user of SADMIN with the right information.
    # If some of them are not present, some of the function may not report the proper information.
    # It is recommended to install any missing command.
    # ----------------------------------------------------------------------------------------------
    def check_requirements(self):
        global which,uname,bc,fdisk,mail,ssh,dmidecode,perl
        global nmon,lscpu,ethtool,parted,curl,mutt,rrdtool

        requisites_status=True                                          # Assume Requirement all Met

        # Get the location of the which command
        #ccode,cstdout,cstderr = self.oscommand("which which")           # We will use which cmd
        #if ccode != 0 :                                                 # to determine if a command
        #    print("[ERROR] The command 'which' couldn't be found")      # is available
        #    print("        This command is needed by the SADMIN tools") # If which is not available
        #    print("        Please install it and re-run this script")   # We will ask the user to
        #    print("        Script Aborted")                             # install it & abort script
        #    sys.exit(1)                                                 # Exit Script with error
        #self.which = cstdout                                            # If found, Save Path to it

        # Get the location of the uname command
        self.uname = self.locate_command('uname')                       # Locate uname command
        if self.uname == "" : requisites_status=False                   # if blank didn't find it

        self.bc = self.locate_command('bc')                             # Locate bc command
        if self.bc == "" : requisites_status=False                      # if blank didn't find it

        # Get the Location of fdisk
        if (self.os_type == "LINUX"):                                   # On Linux
            self.fdisk = self.locate_command('fdisk')                   # Locate fdisk command
            if self.fdisk == "" : requisites_status=False               # if blank didn't find it

        # Get the location of mail command
        self.mail = self.locate_command('mail')                         # Locate mail command
        if self.mail == "" : requisites_status=False                    # if blank didn't find it

        # Get the location of ssh command
        self.ssh = self.locate_command('ssh')                           # Locate the SSH command
        if self.ssh == "" : requisites_status=False                     # if blank didn't find it

        # Get the location of dmidecode command
        if (self.os_type == "LINUX"):                                   # On Linux
            self.dmidecode =self.locate_command('dmidecode')            # Locate dmidecode command
            if self.dmidecode == "" : requisites_status=False           # if blank didn't find it

        # Get the location of perl command
        self.perl =self.locate_command('perl')                          # Locate the perl command
        if self.perl == "" : requisites_status=False                    # if blank didn't find it

        # Get the location of nmon command
        if (self.os_type == "LINUX"):                                   # On Linux
            self.nmon =self.locate_command('nmon')                      # Locate the nmon command
            if self.nmon == "" : requisites_status=False                # if blank didn't find it

        # Get the location of parted command
        if (self.os_type == "LINUX"):                                   # On Linux
            self.parted =self.locate_command('parted')                  # Locate the nmon command
            if self.parted == "" : requisites_status=False              # if blank didn't find it

        # Get the location of lscpu command
        if (self.os_type == "LINUX"):                                   # On Linux
            self.lscpu =self.locate_command('lscpu')                    # Locate the lscpu command
            if self.lscpu == "" : requisites_status=False               # if blank didn't find it

        # Get the location of ethtool command
        if (self.os_type == "LINUX"):                                   # On Linux
            self.ethtool =self.locate_command('ethtool')                # Locate the ethtool command
            if self.ethtool == "" : requisites_status=False             # if blank didn't find it

        # Get the location of mutt command
        if (self.os_type == "LINUX"):                                   # On Linux
            self.mutt =self.locate_command('mutt')                      # Locate the mutt command
            if self.mutt == "" : requisites_status=False                # if blank didn't find it

        # Get the location of rrdtool command
        if (self.os_type == "LINUX"):                                   # On Linux
            self.rrdtool =self.locate_command('rrdtool')                # Locate the rrdtool command
            if self.rrdtool == "" : requisites_status=False             # if blank didn't find it

        # Get the location of curl command
        if (self.os_type == "LINUX"):                                   # On Linux
            self.curl =self.locate_command('curl')                      # Locate the curl command
            if self.curl == "" : requisites_status=False                # if blank didn't find it

        return requisites_status                                        # Requirement Met True/False


    # ----------------------------------------------------------------------------------------------
    # Method make sure directories needed are created,
    # Log initialize and Start Time Recorded in RCH File
    # ----------------------------------------------------------------------------------------------
    def start (self) :
        """Start method of the SADM Tools

        - Make sure All SADM Directories exist,
        - Open log in append mode if attribute log_append="Y", otherwise a new Log file is started.
        - Write Log Header.
        - Record the start Date/Time and Status Code 2(Running) to RCH file.
        - Check if Script is already running (pid_file).
        - Advise user & Quit if Attribute multiple_exec="N".
        """

        global FH_LOG_FILE, start_time, start_epoch

        # Validate the Log Type
        self.log_type = self.log_type.upper()
        if ((self.log_type != 'S') and (self.log_type != "B") and (self.log_type != 'L')):
            print ("Acceptable log_type are 'S','L','B' - Can't set log_type to %s" % (self.log_type))
            sys.exit(1)                                                 # Exit with Error

        # Validate Log Append (True or False)
        if ( (self.log_append != True) and (self.log_append != False) ):
            print ("Invalid self.log.append attribute can be True or False (%s)" % (self.log_append))
            sys.exit(1)                                                 # Exit with Error


        # First thing Make sure the log file is Open and Log Directory created
        try:                                                            # Try to Open/Create Log
            if not os.path.exists(self.log_dir)  : os.mkdir(self.log_dir,2775) # Create SADM Log Dir
            if (self.log_append):                                       # User Want to Append to Log
                FH_LOG_FILE=open(self.log_file,'a')                     # Open Log in append  mode
            else:                                                       # User Want Fresh New Log
                FH_LOG_FILE=open(self.log_file,'w')                     # Open Log in a new log
        except IOError as e:                                            # If Can't Create or open
            print ("Error opening file %s" % self.log_file)             # Print Log FileName
            print ("Error Number : %d" % (e.errno))                     # Print Error Number
            print ("Error Text   : %s" % (e.strerror))                  # Print Error Message
            sys.exit(1)                                                 # Exit with Error


        # Get the userid and groupid chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
        uid = pwd.getpwnam(self.cfg_user).pw_uid                        # Get UID User in sadmin.cfg
        gid = grp.getgrnam(self.cfg_group).gr_gid                       # Get GID User in sadmin.cfg

        # Make sure all SADM Directories structure exist
        if not os.path.exists(self.bin_dir)  : os.mkdir(self.bin_dir,0o0775)    # bin Dir.
        if not os.path.exists(self.cfg_dir)  : os.mkdir(self.cfg_dir,0o0775)    # cfg Dir
        if not os.path.exists(self.dat_dir)  : os.mkdir(self.dat_dir,0o0775)    # dat Dir.
        if not os.path.exists(self.doc_dir)  : os.mkdir(self.doc_dir,0o0775)    # doc Dir.
        if not os.path.exists(self.lib_dir)  : os.mkdir(self.lib_dir,0o0775)    # lib Dir.
        if not os.path.exists(self.log_dir)  : os.mkdir(self.log_dir,0o0775)    # log Dir.
        if not os.path.exists(self.pkg_dir)  : os.mkdir(self.pkg_dir,0o0775)    # pkg Dir.
        if not os.path.exists(self.setup_dir): os.mkdir(self.setup_dir,0o0775)  # setup Dir.
        if not os.path.exists(self.sys_dir)  : os.mkdir(self.sys_dir,0o0775)    # sys Dir.
        if not os.path.exists(self.tmp_dir)  : os.mkdir(self.tmp_dir,0o1777)    # tmp Dir.
        if not os.path.exists(self.nmon_dir) : os.mkdir(self.nmon_dir,0o0775)   # dat/nmon Dir.
        if not os.path.exists(self.dr_dir)   : os.mkdir(self.dr_dir,0o0775)     # dat/dr Dir.
        if not os.path.exists(self.rch_dir)  : os.mkdir(self.rch_dir,0o0775)    # dat/rch Dir.
        if not os.path.exists(self.net_dir)  : os.mkdir(self.net_dir,0o0775)    # dat/net Dir.
        if not os.path.exists(self.rpt_dir)  : os.mkdir(self.rpt_dir,0o0775)    # dat/rpt Dir.
        if not os.path.exists(self.dbb_dir)  : os.mkdir(self.dbb_dir,0o0775)    # dat/dbb Dir.

        # Make sure all SADM User Directories Exist
        if not os.path.exists(self.usr_dir)  : os.mkdir(self.usr_dir,0o0775)    # User Dir.
        if os.getuid() == 0: os.chown(self.usr_dir, uid, gid)                   # Change owner/group
        if not os.path.exists(self.ubin_dir) : os.mkdir(self.ubin_dir,0o0775)   # User Bin Dir.
        if os.getuid() == 0: os.chown(self.ubin_dir,uid,gid)                    # Change owner/group
        if not os.path.exists(self.ulib_dir) : os.mkdir(self.ulib_dir,0o0775)   # User Libr Dir.
        if os.getuid() == 0: os.chown(self.ulib_dir,uid,gid)                    # Change owner/group
        if not os.path.exists(self.udoc_dir) : os.mkdir(self.udoc_dir,0o0775)   # User Doc. Dir.
        if os.getuid() == 0: os.chown(self.udoc_dir, uid, gid)                  # Change owner/group
        if not os.path.exists(self.umon_dir) : os.mkdir(self.umon_dir,0o0775)   # SysMon Scripts Dir
        if os.getuid() == 0: os.chown(self.umon_dir, uid, gid)                  # Change owner/group

        # These Directories are only created on the SADM Server (Web Directories)
        if self.hostname == self.cfg_server :
            wgid = grp.getgrnam(self.cfg_www_group).gr_gid              # Get GID User of Web Group
            wuid = pwd.getpwnam(self.cfg_www_user).pw_uid               # Get UID User of Web User
            #
            if not os.path.exists(self.www_net_dir) : os.mkdir(self.www_net_dir,0o0775) # Web Net Dir.
            os.chown(self.www_net_dir, wuid, wgid)                  # Change owner of Net Dir
            #
            if not os.path.exists(self.www_dir)      : os.mkdir(self.www_dir,0o0775)     # WWW  Dir.
            os.chown(self.www_dir, wuid, wgid)                          # Change owner of log file
            #
            if not os.path.exists(self.www_doc_dir)  : os.mkdir(self.www_doc_dir,0o0775) # HTML Dir.
            os.chown(self.www_doc_dir, wuid, wgid)                      # Change owner of rch file
            #
            if not os.path.exists(self.www_dat_dir)  : os.mkdir(self.www_dat_dir,0o0775) # DAT  Dir.
            os.chown(self.www_dat_dir, wuid, wgid)                      # Change owner of dat file
            #
            if not os.path.exists(self.www_arc_dir)  : os.mkdir(self.www_arc_dir,0o0775) # DAT  Dir.
            os.chown(self.www_arc_dir, wuid, wgid)                      # Change owner of dat file
            #
            if not os.path.exists(self.www_lib_dir)  : os.mkdir(self.www_lib_dir,0o0775) # Lib  Dir.
            os.chown(self.www_lib_dir, wuid, wgid)                      # Change owner of lib file
            #
            if not os.path.exists(self.www_tmp_dir)  : os.mkdir(self.www_tmp_dir,0o0775) # Tmp  Dir.
            os.chown(self.www_tmp_dir, wuid, wgid)                      # Change owner of tmp file
            #
            if not os.path.exists(self.www_perf_dir)  : os.mkdir(self.www_perf_dir,0o0775) # Tmp  Dir.
            os.chown(self.www_perf_dir, wuid, wgid)                     # Owner/Group for Perf.Graph


        # Write SADM Header to Script Log
        if (self.log_header) :                                          # Want to Produce log Header
            self.writelog (dash)                                        # 80 = Lines
            wmess = "Starting %s " % (self.pn)                          # Script Name
            wmess += "V%s " % (self.ver)                                # Script Version
            wmess += "- SADM Lib. V%s" % (self.libver)                  # SADMIN Library Version
            self.writelog (wmess,'bold')                                # Write Start line to Log
            wmess = "Server Name: %s" % (self.get_fqdn())               # FQDN Server Name
            wmess += " - Type: %s" % (self.os_type.capitalize())        # O/S Type Linux/Aix
            self.writelog (wmess)                                       # Write OS Info to Log Head
            wmess  = "O/S: %s " % (self.get_osname().capitalize())      # O/S Distribution Name
            wmess += " %s - Code Name:" % (self.get_osversion())        # O/S Distribution Version
            wmess += " %s" % (self.get_oscodename().capitalize())       # O/S Dist. Code Name Alias
            self.writelog (wmess)                                       # Write OS Info to Log Head
            self.writelog (fifty_dash)                                  # 50 '=' Lines
            self.writelog (" ")                                         # Space Line in the LOG

        # If the PID file already exist - Script is already Running
        if os.path.exists(self.pid_file) and self.multiple_exec == "N" :# PID Exist & No MultiRun
            self.writelog ("Script %s is already running" % self.pn)    # Same script is running
            self.writelog ("PID File %s exist." % self.pid_file)        # Display PID File Location
            self.writelog ("Will not run a second copy of this script") # Advise the user
            self.writelog ("Script Aborted")                            # Script Aborted
            sys.exit(1)                                                 # Exit with Error

        # Record Date & Time the script is starting in the RCH File
        start_epoch = int(time.time())                                  # StartTime in Epoch Time
        if (self.use_rch) :                                             # If want to Create/Upd RCH
            i = datetime.datetime.now()                                 # Get Current Time
            start_time=i.strftime('%Y.%m.%d %H:%M:%S')                  # Save Start Date & Time
            try:
                FH_RCH_FILE=open(self.rch_file,'a')                     # Open RC Log in append mode
            except IOError as e:                                        # If Can't Create or open
                print ("Error open file %s \r\n" % self.rch_file)            # Print Log FileName
                print ("Error Number : {0}\r\n.format(e.errno)")        # Print Error Number
                print ("Error Text   : {0}\r\n.format(e.strerror)")     # Print Error Message
                sys.exit(1)
            rch_line="%s %s %s %s %s %s %s" % (self.hostname,start_time,".......... ........ ........",self.inst,self.cfg_alert_group,self.cfg_alert_type,"2")
            FH_RCH_FILE.write ("%s\n" % (rch_line))                     # Write Line to RCH Log
            FH_RCH_FILE.close()                                         # Close RCH File
        return 0



    # ----------------------------------------------------------------------------------------------
    # Method that write script Footer in the Log, Close the Database
    # Record the End Time in the RCH, close the log amd RCH File , Trim the RCH file and Log
    # ----------------------------------------------------------------------------------------------
    def stop(self,return_code):
        global FH_LOG_FILE, start_time, start_epoch

        self.exit_code = return_code                                    # Save Param.Recv Code
        if self.exit_code != 0 :                                        # If Return code is not 0
            self.exit_code=1                                            # Making Sure code is 1 or 0

        # Write the Script Exit code of the script to the log
        if (self.log_footer) :                                          # Want to Produce log Footer
            self.writelog (" ")                                         # Space Line in the LOG
            self.writelog (fifty_dash)                                  # 50 = Lines
            self.writelog ("Script return code: " + str(self.exit_code))# Script ExitCode to Log


        # Calculate the execution time, format it and write it to the log
        end_epoch = int(time.time())                                    # Save End Time in Epoch Time
        elapse_seconds = end_epoch - start_epoch                        # Calc. Total Seconds Elapse
        hours = elapse_seconds//3600                                    # Calc. Nb. Hours
        elapse_seconds = elapse_seconds - 3600*hours                    # Subs. Hrs*3600 from elapse
        minutes = elapse_seconds//60                                    # Cal. Nb. Minutes
        seconds = elapse_seconds - 60*minutes                           # Subs. Min*60 from elapse
        elapse_time="%02d:%02d:%02d" % (hours,minutes,seconds)
        if (self.log_footer) :                                          # Want to Produce log Footer
            self.writelog ("Script execution time is %02d:%02d:%02d" % (hours,minutes,seconds))


        # Update the [R]eturn [C]ode [H]istory File
        if (self.use_rch) :                                             # If Want to use RCH File
            rch_exists = os.path.isfile(self.rch_file)                  # Do we have existing rch ?
            if rch_exists :                                             # If we do, del code2 line?
                with open(self.rch_file) as xrch:                       # Open rch file
                    lastLine = (list(xrch)[-1])                         # Get Last Line of rch file
                    rch_code = lastLine.split(' ')[9].strip()           # Get Last Line return Code
                    if rch_code == "2" :                                # If Code 2 - want to del it
                        rch_file = open(self.rch_file,'r')              # Open RCH File for reading
                        lines = rch_file.readlines()                    # Read all Lines in Memory
                        del lines[-1]                                   # Delete code 2 last line
                        rch_file.close()                                # Write changes to disk
                        rch_file = open(self.rch_file,'w')              # Open RCH to rewrite it
                        rch_file.writelines(lines)                      # Write RCH without code2
                        rch_file.close()                                # Close & Write change 
            i = datetime.datetime.now()                                 # Get Current Stop Time
            stop_time=i.strftime('%Y.%m.%d %H:%M:%S')                   # Format Stop Date & Time
            FH_RCH_FILE=open(self.rch_file,'a')                         # Open RCH Log - append mode
            rch_line="%s %s %s %s %s %s %s %s" % (self.hostname,start_time,stop_time,elapse_time,self.inst,self.cfg_alert_group,self.cfg_alert_type,self.exit_code)
            FH_RCH_FILE.write ("%s\n" % (rch_line))                     # Write Line to RCH Log
            FH_RCH_FILE.close()                                         # Close RCH File
            if (self.log_footer) :                                      # Want to Produce log Footer
                self.writelog ("Trim %s to %s lines." %  (self.rch_file, str(self.cfg_max_rchline)))


        # Write in Log the email choice the user as requested (via the sadmin.cfg file)
        # 0 = No Mail Sent      1 = On Error Only   2 = On Success Only   3 = Always send email
        if self.cfg_alert_type == 0 :                                   # User don't want any email
            MailMess="No alert is requested when script end."           # Message User Email Choice

        if self.cfg_alert_type == 1 :                                   # Want Email on Error Only
                MailMess="Alert requested if script fail."              # Message User Email Choice

        if self.cfg_alert_type == 2 :                                   # Email on Success Only
                MailMess="Alert requested on success only."             # Message User Email Choice

        if self.cfg_alert_type == 3 :                                   # User always Want email
            MailMess="Alert requested on Success or Error."             # Message User Email Choice

        if self.cfg_alert_type > 3 or self.cfg_alert_type < 0 :         # User Email Choice Invalid
            MailMess="SADM_ALERT_TYPE is not set properly [0-3] Now at %s",(str(self.cfg_alert_type))

#        if self.mail == "" :                                            # If Mail Program not found
#            MailMess="No Mail can be send - Until mail command is install"  # Msg User Email Choice
        if (self.log_footer) :                                          # Want to Produce log Footer
            self.writelog ("%s" % (MailMess))                           # User alert choice to log


        # Advise user the Log will be trimm
        if (self.log_footer) :                                          # Want to Produce log Footer
            self.writelog ("Trim %s to %s lines." %  (self.log_file, str(self.cfg_max_logline)))

        # Write Script Log Footer
        now = time.strftime("%c")                                       # Get Current Date & Time
        if (self.log_footer) :                                          # Want to Produce log Footer
            self.writelog (now + " - End of " + self.pn)                # Write Final Footer to Log
            self.writelog (dash)                                        # 80 = Lines
            self.writelog (" ")                                         # Space Line in the LOG

        # Inform UnixAdmin By Email based on his selected choice
        # Now that the user email choice is written to the log, let's send the email now, if needed
        # 0 = No Mail Sent      1 = On Error Only   2 = On Success Only   3 = Always send email
        #wsubject=""                                                     # Clear Email Subject
        #wsub_success="SADM : SUCCESS of %s on %s" % (self.pn,self.hostname) # Format Success Subject
        #wsub_error="SADM : ERROR of %s on %s" % (self.pn,self.hostname) # Format Failed Subject

        # If Error & User want email
        #if self.exit_code != 0 and (self.cfg_alert_type == 1 or self.cfg_alert_type == 3):
        #    wsubject=wsub_error                                         # Build the Subject Line

        #if self.cfg_alert_type == 2 and self.exit_code == 0 :            # Success & User Want Email
        #    wsubject=wsub_success                                       # Format Subject Line

        #if self.cfg_alert_type == 3 :                                    # USer Always want Email
        #    if self.exit_code == 0 :                                    # If Script is a Success
        #        wsubject=wsub_success                                   # Build the Subject Line
        #    else :                                                      # If Script Failed
        #        wsubject=wsub_error                                     # Build the Subject Line

        #if wsubject != "" :                                             # subject Then Email Needed
        #    time.sleep(1)                                               # Sleep 1 seconds
        #    cmd = "cat %s | %s -s '%s' %s" % (self.log_file,self.mail,wsubject,self.cfg_mail_addr)
        #    ccode, cstdout, cstderr = self.oscommand("%s" % (cmd))      # Go send email
        #    if ccode != 0 :                                             # If Cmd Fail
        #        self.writelog ("ERROR : Problem sending mail to %s" % (self.cfg_mail_addr))

        FH_LOG_FILE.flush()                                             # Got to do it - Missing end
        FH_LOG_FILE.close()                                             # Close the Log File

        # Trimming the Log
        self.trimfile (self.log_file, self.cfg_max_logline)             # Trim the Script Log
        if (self.use_rch) :                                             # If Using a RCH File
            self.trimfile (self.rch_file, self.cfg_max_rchline)         # Trim the Script RCH Log

        # Get the userid and groupid chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
        try :
            uid = pwd.getpwnam(self.cfg_user).pw_uid                    # Get UID User in sadmin.cfg
            gid = grp.getgrnam(self.cfg_group).gr_gid                   # Get GID User in sadmin.cfg
        except KeyError as e:
            msg = "User %s doesn't exist or not define in sadmin.cfg" % (self.cfg_user)
            print (msg)

        # Make Sure Owner/Group of Log File are the one chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
        try :
            os.chown(self.log_file, -1, gid)                            # -1 leave UID unchange
            os.chmod(self.log_file, 0o0660)                             # Change Log File Permission
        except Exception as e:
            msg = "Warning : Couldn't change owner or chmod of "        # Build Warning Message
            print ("%s %s to %s.%s" % (msg,self.log_file,self.cfg_user,self.cfg_group))
            print ("%s" % (e))

        # Make Sure Owner/Group of RCH File are the one chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
        if (self.use_rch) :                                             # If Using a RCH File
            try :
                #os.chown(self.rch_file, uid, gid)                      # Change owner of rch file
                os.chown(self.rch_file, -1, gid)                        # -1 leave UID unchange
                os.chmod(self.rch_file, 0o0660)                         # Change RCH File Permission
            except Exception as e:
                msg = "Warning : Couldn't change owner or chmod of "    # Build Warning Message
                print ("%s %s to %s.%s" % (msg,self.rch_file,self.cfg_user,self.cfg_group))

        # Delete Temproray files used
        self.silentremove (self.pid_file)                               # Delete PID File
        self.silentremove (self.tmp_file1)                              # Delete Temp file 1
        self.silentremove (self.tmp_file2)                              # Delete Temp file 2
        self.silentremove (self.tmp_file3)                              # Delete Temp file 3
        return self.exit_code
