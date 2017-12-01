#!/usr/bin/env python3
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadmlib_std.py
#   Synopsis:   This is the Standard SADM Python Library 
#
#===================================================================================================
# Change Log
# 2016_06_13 - JDuplessis
#   V1.1 Added Flush before trimming file
# 2017_09_03 - JDuplessis 
#   V1.2 Rewritten Trimfile function (Caused error if exec in debug mode)
# 2017_09_03 - JDuplessis 
#   V1.3 Added db_dir and db_file for Sqlite3 Database
# 2017_11_23 - JDuplessis
#   V2.0 Major Redesign of the Library and switch to MySQL Database
#
# 
# ==================================================================================================
import os, errno, time, sys, pdb, socket, datetime, getpass, subprocess, smtplib, pwd, grp
import glob, fnmatch, linecache, shutil
from subprocess import Popen, PIPE
#pdb.set_trace() 


#===================================================================================================
#                 Global Variables Shared among all SADM Libraries and Scripts
#===================================================================================================
ver                = "2.1"                                              # Default Program Version
exit_code          = 0                                                  # Script Error Return Code
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




#===================================================================================================
#                                   SADM Python Tools Library 
#===================================================================================================
class sadmtools():

    #-----------------------------------------------------------------------------------------------
    #  INITIALISATION OF SADM TOOLS------------------------------------------------------
    #-----------------------------------------------------------------------------------------------
    def __init__(self, dbname='sadmin', sdebug=0, dbsilent=False):
        """ Class sadmtool: Series of function to that can be used to administer a Linux/Aix Farm.
        """
        # Check if SADMIN Environment variable is defined (MUST be defined)
        if "SADMIN" in os.environ:                                      # SADMIN Env. Var. Defined ?
            self.base_dir = os.environ.get('SADMIN')                         # Set SADM Base Directory
        else:
            print ("Please set environment variable SADMIN.")           # Advise user
            print ("SADMIN indicate the directory name where you unzip the *.tgz file")
            sys.exit(1)                                                 # Exit if not defined 
        self.debug              = sdebug                                # Save Rcv.Debug Level (0-9)
        self.dbsilent           = dbsilent                              # True=Nom Err.Msg
        self.dbname             = dbname                                # Database Name
        
        # SADM Sub Directories Definitions
        self.lib_dir            = os.path.join(self.base_dir,'lib')     # SADM Lib. Directory
        self.tmp_dir            = os.path.join(self.base_dir,'tmp')     # SADM Temp. Directory
        self.bin_dir            = os.path.join(self.base_dir,'bin')     # SADM Scripts Directory
        self.log_dir            = os.path.join(self.base_dir,'log')     # SADM Log Directory
        self.pkg_dir            = os.path.join(self.base_dir,'pkg')     # SADM Package Directory
        self.cfg_dir            = os.path.join(self.base_dir,'cfg')     # SADM Config Directory
        self.sys_dir            = os.path.join(self.base_dir,'sys')     # SADM System Scripts Dir.
        self.dat_dir            = os.path.join(self.base_dir,'dat')     # SADM Data Directory
        self.nmon_dir           = os.path.join(self.dat_dir,'nmon')     # SADM nmon File Directory
        self.rch_dir            = os.path.join(self.dat_dir,'rch')      # SADM Result Code Dir.
        self.dr_dir             = os.path.join(self.dat_dir,'dr')       # SADM Disaster Recovery Dir
        self.sar_dir            = os.path.join(self.dat_dir,'sar')      # SADM System Activity Rep.
        self.net_dir            = os.path.join(self.dat_dir,'net')      # SADM Network/Subnet Dir 
        self.rpt_dir            = os.path.join(self.dat_dir,'rpt')      # SADM Sysmon Report Dir.
        self.www_dir            = os.path.join(self.base_dir,'www')     # SADM WebSite Dir Structure

        # SADM Web Site Directories Structure
        self.www_dat_dir        = os.path.join(self.www_dir,'dat')      # SADM Web Site Data Dir
        self.www_cfg_dir        = os.path.join(self.www_dir,'cfg')      # SADM Web Site CFG Dir
        self.www_html_dir       = os.path.join(self.www_dir,'html')     # SADM Web Site html Dir
        self.www_lib_dir        = os.path.join(self.www_dir,'lib')      # SADM Web Site Lib Dir
        self.www_net_dir        = self.www_dat_dir + '/' + hostname + '/net' # SADM Web Data Network Dir
        self.www_rch_dir        = self.www_dat_dir + '/' + hostname + '/rch' # SADM Web Data RCH Dir
        self.www_sar_dir        = self.www_dat_dir + '/' + hostname + '/sar' # SADM Web Data SAR Dir
        self.www_dr_dir         = self.www_dat_dir + '/' + hostname + '/dr'  # SADM Web Disaster Recovery
        self.www_nmon_dir       = self.www_dat_dir + '/' + hostname + '/nmon'# SADM Web NMON Directory
        self.www_tmp_dir        = self.www_dat_dir + '/' + hostname + '/tmp' # SADM Web tmp Directory
        self.www_log_dir        = self.www_dat_dir + '/' + hostname + '/log' # SADM Web log Directory
        
        # SADM Files Definition
        self.log_file           = self.log_dir + '/' + hostname + '_' + inst + '.log'     # Log Filename
        self.rch_file           = self.rch_dir + '/' + hostname + '_' + inst + '.rch'     # RCH Filename
        self.cfg_file           = self.cfg_dir + '/sadmin.cfg'                            # Configuration Filename
        self.cfg_hidden         = self.cfg_dir + '/.sadmin.cfg'                           # Hidden Config Filename
        self.crontab_work       = self.www_cfg_dir + '/.crontab.txt'                      # Work crontab
        self.crontab_file       = '/etc/cron.d/sadmin'                               # Final crontab
        self.rel_file           = self.cfg_dir + '/.release'                              # SADMIN Release Version No.
        self.pid_file           = "%s/%s.pid" % (self.tmp_dir, inst)                      # Process ID File
        self.tmp_file_prefix    = self.tmp_dir + '/' + hostname + '_' + inst              # TMP Prefix
        self.tmp_file1          = "%s_1.%s" % (self.tmp_file_prefix,tpid)                 # Temp1 Filename
        self.tmp_file2          = "%s_2.%s" % (self.tmp_file_prefix,tpid)                 # Temp2 Filename
        self.tmp_file3          = "%s_3.%s" % (self.tmp_file_prefix,tpid)                 # Temp3 Filename
        
        # SADM Configuration file (sadmin.cfg) content loaded from configuration file 
        self.cfg_mail_type      = 1                                     # 0=No 1=Err 2=Succes 3=All
        self.cfg_mail_addr      = ""                                    # Default is in sadmin.cfg
        self.cfg_cie_name       = ""                                    # Company Name
        self.cfg_user           = ""                                    # sadmin user account
        self.cfg_group          = ""                                    # sadmin group account
        self.cfg_www_user       = ""                                    # sadmin/www user account
        self.cfg_www_group      = ""                                    # sadmin/www group owner
        self.cfg_server         = ""                                    # sadmin FQN Server
        self.cfg_domain         = ""                                    # sadmin Default Domain
        self.cfg_max_logline    = 5000                                  # Max Nb. Lines in LOG )
        self.cfg_max_rchline    = 100                                   # Max Nb. Lines in RCH file
        self.cfg_nmon_keepdays  = 60                                    # Days to keep old *.nmon
        self.cfg_sar_keepdays   = 60                                    # Days to keep old *.sar
        self.cfg_rch_keepdays   = 60                                    # Days to keep old *.rch
        self.cfg_log_keepdays   = 60                                    # Days to keep old *.log
        self.dbname             = ""                                    # PostGres Database Name
        self.cfg_dbhost         = ""                                    # PostGres Database Host
        self.cfg_dbport         = 3306                                  # PostGres Database Port
        self.cfg_rw_dbuser      = ""                                    # PostGres Read Write User
        self.cfg_rw_dbpwd       = ""                                    # PostGres Read Write Pwd
        self.cfg_ro_dbuser      = ""                                    # PostGres Read Only User
        self.cfg_ro_dbpwd       = ""                                    # PostGres Read Only Pwd
        self.cfg_ssh_port       = 22                                    # SSH Port used in Farm

        self.log_type           = "B"                                   # 4Logger S=Scr L=Log B=Both
        self.multiple_exec      = "N"                                   # Default Run multiple copy
        self.log_append         = "Y"                                   # Append to Existing Log ?
        
        # SADM Path to various commands used by SADM Tools
        self.lsb_release        = ""                                    # Command lsb_release Path
        self.which              = ""                                    # whic1h Path - Required
        self.dmidecode          = ""                                    # Command dmidecode Path
        self.bc                 = ""                                    # Command bc (Do Some Math)
        self.fdisk              = ""                                    # fdisk (Read Disk Capacity)
        self.perl               = ""                                    # perl Path (for epoch time)
        self.uname              = ""                                    # uname command path
        self.mail               = ""                                    # mail command path
        
        # O/S Info
        self.os_type            = self.get_ostype().upper()             # linux/aix

        # Load Configuration File ($SADMIN/cfg/sadmin.cfg)
        self.load_config_file(self.cfg_file)                                 # Load cfg var from sadmin.cfg


    def set_log_type(self,wlogtype) :
        wlogtype = wlogtype.upper()
        if ((wlogtype.upper() != 'S') and (wlogtype != "B") and (wlogtype != 'L')): 
           print ("Acceptable log_type are 'S','L','B' - Can't set log_type to %s" % (wlogtype))
           return
        self.log_type = wlogtype.upper()                                # LogType S=Scr L=Log B=Both

    def get_log_type(self) :
        return (self.log_type)

#        
    def get_max_logline(self) :
        return(self.cfg_max_logline)

    def set_max_logline(self,maxline) :
        self.cfg_max_logline = maxline
#        
    def get_max_logline(self) :
        return(self.cfg_max_logline)



        
    # ----------------------------------------------------------------------------------------------
    #            LOAD SADMIN CONFIGURATION FILE AND SET GLOBAL VARIABLES ACCORDINGLY
    # ----------------------------------------------------------------------------------------------
    def load_config_file(self,sadmcfg):
        # global self.cfg_mail_type,      self.cfg_mail_addr,     self.cfg_cie_name
        # global self.cfg_user ,          self.cfg_group,         self.cfg_server
        # global self.cfg_max_logline,    self.cfg_max_rchline,   self.cfg_domain
        # global self.cfg_www_user,       self.cfg_www_group
        # global self.cfg_nmon_keepdays,  self.cfg_sar_keepdays
        # global self.cfg_log_keepdays,   self.cfg_rch_keepdays
        # global self.cfg_pgdb,           self.cfg_dbhost,        self.cfg_dbport
        # global self.cfg_rw_dbuser,      self.cfg_rw_dbpwd, 
        # global self.cfg_ro_dbuser,      self.cfg_ro_dbpwd, 
        # global self.cfg_ssh_port,       self.FH_LOG_FILE
    
        # Debug Level Higher than 4 , inform that entering Load configuration file
        if self.debug > 4 :                                                  # If Debug Run Level 4
            print (" ")                                                 # Space Line in the LOG
            print (dash)                                                # 80 = Lines 
            print ("Load Configuration file %s" % (sadmcfg))      # Inform user in Debug
            print (dash)                                                # 80 = Lines 

        # Configuration file MUST be present :
        # If Not Present, copy $SADMIN/.sadm_config to $SADMIN/sadmin.cfg 
        if  not os.path.exists(sadmcfg) :
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
                print ("cp %s %s " % (self.cfg_hidden, sadmcfg))  # Install Default cfg  file
                cmd = "cp %s %s"% "cp %s %s " % (self.cfg_hidden, sadmcfg) # Copy Default cfg 
                ccode, cstdout, cstderr = self.oscommand(cmd)
                if not ccode == 0 :
                    print ("Could not copy the backup file file")
                print ("****************************************************************")

                   
        # Set Minimum Default Values - in case we could not load the SADMIN Config File
        self.cfg_mail_addr         = "root@localhost"                            # Default email address
        self.cfg_cie_name          = "Your Company Name"                         # Company Name
        self.cfg_mail_type         = 3                                           # Send Email after each run
        self.cfg_user              = "sadmin"                                    # sadmin user account
        self.cfg_group             = "sadmin"                                    # sadmin group account
        self.cfg_www_user          = "apache"                                    # sadmin/www user account
        self.cfg_www_group         = "apache"                                    # sadmin/www group account
        self.cfg_max_logline       = 5000                                        # Max Line in each *.log
        self.cfg_max_rchline       = 100                                         # Max Line in each *.rch
        self.cfg_nmon_keepdays     = 60                                          # Days to keep old *.nmon
        self.cfg_sar_keepdays      = 60                                          # Days ro keep old *.sar
        self.cfg_rch_keepdays      = 60                                          # Days to keep old *.rch
        self.cfg_keepdays          = 60                                          # Days ro keep old *.log
        ccode, cstdout, cstderr = self.oscommand("host sadmin | cut -d' ' -f1")  # Get FQN of admin server
        if ccode is not 0 :                                                 # If sadmin not resolved
            print ("Error executing 'host sadmin | cut -d' ' -f1")        # Advise User of error
            print ("Assuming 'sadmin' as sadmin server")                  # Will use sadmin no FQN
            self.cfg_server        = "sadmin"                                     # Default sadmin hostname
        else :                                                              # If sadmin was resolvec
            self.cfg_server        = cstdout                                      # Used FQN obtained
        self.cfg_domain         = ""                                             # Default Domain Name
        self.cfg_dbname         = ""                                             # PostGres Database Name
        self.cfg_dbhost         = ""                                             # PostGres Database Host
        self.cfg_dbport         = 3306                                           # PostGres Database Port
        self.cfg_rw_dbuser      = ""                                             # PostGres Read/Write User
        self.cfg_rw_dbpwd       = ""                                             # PostGres Read/Write Pwd
        self.cfg_ro_dbuser      = ""                                             # PostGres Read Only User
        self.cfg_ro_dbpwd       = ""                                             # PostGres Read Only Pwd

        # Open Configuration file 
        try:
            FH_CFG_FILE = open(self.cfg_file,'r')                           # Open Config File
        except IOError as e:                                                # If Can't Create or open
            print ("Error open file %s \r\n" % self.cfg_file)               # Print Log FileName
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
            if "SADM_MAIL_ADDR"     in CFG_NAME : self.cfg_mail_addr      = CFG_VALUE
            if "SADM_CIE_NAME"      in CFG_NAME : self.cfg_cie_name       = CFG_VALUE
            if "SADM_MAIL_TYPE"     in CFG_NAME : self.cfg_mail_type      = int(CFG_VALUE)
            if "SADM_SERVER"        in CFG_NAME : self.cfg_server         = CFG_VALUE
            if "SADM_DOMAIN"        in CFG_NAME : self.cfg_domain         = CFG_VALUE
            if "SADM_USER"          in CFG_NAME : self.cfg_user           = CFG_VALUE
            if "SADM_GROUP"         in CFG_NAME : self.cfg_group          = CFG_VALUE
            if "SADM_WWW_USER"      in CFG_NAME : self.cfg_www_user       = CFG_VALUE
            if "SADM_WWW_GROUP"     in CFG_NAME : self.cfg_www_group      = CFG_VALUE
            if "SADM_MAX_LOGLINE"   in CFG_NAME : self.cfg_max_logline    = int(CFG_VALUE)
            if "SADM_MAX_RCHLINE"   in CFG_NAME : self.cfg_max_rchline    = int(CFG_VALUE)
            if "SADM_NMON_KEEPDAYS" in CFG_NAME : self.cfg_nmon_keepdays  = int(CFG_VALUE)
            if "SADM_SAR_KEEPDAYS"  in CFG_NAME : self.cfg_sar_keepdays   = int(CFG_VALUE)
            if "SADM_RCH_KEEPDAYS"  in CFG_NAME : self.cfg_rch_keepdays   = int(CFG_VALUE)
            if "SADM_LOG_KEEPDAYS"  in CFG_NAME : self.cfg_log_keepdays   = int(CFG_VALUE)
            if "SADM_DBNAME"        in CFG_NAME : self.cfg_dbname         = CFG_VALUE
            if "SADM_DBHOST"        in CFG_NAME : self.cfg_dbhost         = CFG_VALUE
            if "SADM_DBPORT"        in CFG_NAME : self.cfg_dbport         = int(CFG_VALUE)
            if "SADM_RW_DBUSER"     in CFG_NAME : self.cfg_rw_dbuser      = CFG_VALUE
            if "SADM_RW_DBPWD"      in CFG_NAME : self.cfg_rw_dbpwd       = CFG_VALUE
            if "SADM_RO_DBUSER"     in CFG_NAME : self.cfg_ro_dbuser      = CFG_VALUE
            if "SADM_RO_DBPWD"      in CFG_NAME : self.cfg_ro_dbpwd       = CFG_VALUE
            if "SADM_SSH_PORT"      in CFG_NAME : self.cfg_ssh_port       = int(CFG_VALUE)

        FH_CFG_FILE.close()                                                 # Close Config File
        return        



    # ----------------------------------------------------------------------------------------------
    #                         Write Log to Log File, Screen or Both
    # ----------------------------------------------------------------------------------------------
    def writelog(self,sline):
        global FH_LOG_FILE
    
        #print ("log_type = %s" % (log_type))
        #print ("self.log_type = %s" % (self.log_type))

        now = datetime.datetime.now()
        logLine = now.strftime("%Y.%m.%d %H:%M:%S") + " - %s" % (sline)
        if self.log_type.upper() == "L" :  FH_LOG_FILE.write ("%s\n" % (logLine))
        if self.log_type.upper() == "S" :  print ("%s" % logLine)
        if self.log_type.upper() == "B" :  
            FH_LOG_FILE.write ("%s\n" % (logLine))
            print ("%s" % logLine) 


    # ----------------------------------------------------------------------------------------------
    #                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
    # ----------------------------------------------------------------------------------------------
    def oscommand(self,command) :
        if self.debug > 8 : self.writelog ("In sadm_oscommand function to run command : %s" % (command))
        p = subprocess.Popen(command, stdout=PIPE, stderr=PIPE, shell=True)
        out = p.stdout.read().strip()
        err = p.stderr.read().strip()
        returncode = p.wait()
        if self.debug > 8 :
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
                raise                                                       # raise exception if diff.err

  
    # ----------------------------------------------------------------------------------------------
    #                        CURRENT USER IS "ROOT" (True) OR NOT ? (False)
    # ----------------------------------------------------------------------------------------------
    def is_root(self) :
        if not os.geteuid() == 0:                                       # If Current User not root
            return False                                                # Return False
        else :                                                          # If Current user is root
            return True                                                 # Return True


    # ----------------------------------------------------------------------------------------------
    #                                 RETURN SADMIN RELEASE VERSION NUMBER
    # ----------------------------------------------------------------------------------------------
    def get_release(self) :
        if os.path.exists(self.rel_file):
            wcommand = "head -1 %s" % (self.rel_file)
            ccode, cstdout, cstderr = self.oscommand("%s" % (wcommand))      # Execute O/S CMD 
            wrelease=cstdout.decode()
        else:
            wrelease="00.00"
        return wrelease


    # ----------------------------------------------------------------------------------------------
    #                                 RETURN THE HOSTNAME (SHORT)
    # ----------------------------------------------------------------------------------------------
    def get_hostname(self):
        cstdout="unknown"
        if self.os_type == "LINUX" :                                         # Under Linux
            ccode, cstdout, cstderr = self.oscommand("hostname -s")          # Execute O/S CMD 
        if self.os_type == "AIX" :                                      # Under AIX
            ccode, cstdout, cstderr = self.oscommand("hostname")             # Execute O/S CMD 
        whostname=cstdout.upper()
        return whostname


    # ----------------------------------------------------------------------------------------------
    #                                 RETURN THE DOMAINNAME 
    # ----------------------------------------------------------------------------------------------
    def get_domainname(self):
        whostname = get_hostname()
        if self.os_type == "LINUX" :                                        # Under Linux
            ccode, cstdout, cstderr = self.oscommand("host $whostname) |head -1 |awk '{ print $1 }' |cut -d. -f2-3")
        if self.os_type == "AIX" :                                          # Under AIX
            ccode, cstdout, cstderr = self.oscommand("namerslv -s | grep domain | awk '{ print $2 }'")
        wdomainname=cstdout.upper()
        return wdomainname
 

    # ----------------------------------------------------------------------------------------------
    #                              RETURN THE IP OF THE CURRENT HOSTNAME
    # ----------------------------------------------------------------------------------------------
    def get_host_ip(self):
        whostname = get_hostname()
        wdomain = get_domainname()
        if self.os_type == "LINUX" :                                    # Under Linux
            ccode, cstdout, cstderr = self.oscommand("host $whostname |awk '{ print $4 }' |head -1") 
        if self.os_type == "AIX" :                                      # Under AIX
            ccode, cstdout, cstderr = self.oscommand("host $whostname.$wdomain |head -1 |awk '{ print $3 }'")
        whostip=cstdout.upper()
        return whostip


    # ----------------------------------------------------------------------------------------------
    #                     Return if running 32 or 64 Bits Kernel version
    # ----------------------------------------------------------------------------------------------
    def get_kernel_bitmode(self):
        if self.os_type == "LINUX" :                                    # Under Linux
            ccode, cstdout, cstderr = self.oscommand("getconf LONG_BIT") 
        if self.os_type == "AIX" :                                      # Under AIX
           ccode, cstdout, cstderr = self.oscommand("getconf KERNEL_BITMODE")
        wkbits=cstdout.upper()
        return wkbits


    # ----------------------------------------------------------------------------------------------
    #                                 RETURN KERNEL RUNNING VERSION
    # ----------------------------------------------------------------------------------------------
    def get_kernel_version(self):
        if self.os_type == "LINUX" :                                    # Under Linux
            ccode, cstdout, cstderr = self.oscommand("uname -r | cut -d. -f1-3") 
        if self.os_type == "AIX" :                                      # Under AIX
            ccode, cstdout, cstderr = self.oscommand("uname -r")
        wkver=cstdout.upper()
        return wkver

 
    # ----------------------------------------------------------------------------------------------
    #                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
    # ----------------------------------------------------------------------------------------------
    def get_ostype(self):
        ccode, cstdout, cstderr = self.oscommand("uname -s")
        wostype=cstdout.upper()
        return wostype.decode()


    
    # ----------------------------------------------------------------------------------------------
    #                   RETURN THE OS  NAME (ALWAYS RETURNED IN UPPERCASE)
    # ----------------------------------------------------------------------------------------------
    def get_osname(self) :
        wcmd = "%s %s" % (lsb_release,"-si")
        ccode, cstdout, cstderr = self.oscommand(wcmd)
        osname=cstdout.upper()
        if osname  == "REDHATENTERPRISESERVER" : osname="REDHAT"
        if osname  == "REDHATENTERPRISEAS"     : osname="REDHAT"
        if self.os_type == "AIX" : osname="AIX"
        return osname.decode()

 
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
        wcmd = "%s %s" % (lsb_release,"-sc")
        ccode, cstdout, cstderr = self.oscommand(wcmd)
        oscodename=cstdout.upper()
        if self.os_type == "AIX" : oscodename="IBM AIX"
        return oscodename.decode()


    # ----------------------------------------------------------------------------------------------
    #                THIS FUNCTION DETERMINE THE OS (DISTRIBUTION) VERSION NUMBER 
    # ----------------------------------------------------------------------------------------------
    def get_osversion(self) :
        osversion="0.0"                                                 # Default Value
        if self.os_type == "LINUX" :
            ccode, cstdout, cstderr = self.oscommand(lsb_release + " -sr")
            osversion=cstdout
        if self.os_type == "AIX" :
            ccode, cstdout, cstderr = self.oscommand("uname -v")
            maj_ver=cstdout
            ccode, cstdout, cstderr = self.oscommand("uname -r")
            min_ver=cstdout
            osversion="%s.%s" % (maj.version,min.version)
        return osversion.decode()


    # ----------------------------------------------------------------------------------------------
    #                        RETURN THE OS (DISTRIBUTION) MAJOR VERSION
    # ----------------------------------------------------------------------------------------------
    def get_osmajorversion(self) :
        if self.os_type == "LINUX" :
            ccode, cstdout, cstderr = self.oscommand(lsb_release + " -sr")
            osversion=cstdout.decode()
            osmajorversion=osversion.split('.')[0]
        if self.os_type == "AIX" :
            ccode, cstdout, cstderr = self.oscommand("uname -v")
            osmajorversion=cstdout.decode()
        return osmajorversion

    
    # ----------------------------------------------------------------------------------------------
    #         SEND AN EMAIL TO SYSADMIN DEFINE IN SADMIN.CFG WITH SUBJECT AND BODY RECEIVED
    # ----------------------------------------------------------------------------------------------
    def sendmail(self,wserver,wport,wuser,wpwd,wsub,wbody) :
        wfrom = cfg_user + "@" + cfg_server
        #pdb.set_trace() 

        try :
            smtpserver = smtplib.SMTP(wserver, wport)
            smtpserver.ehlo()
            smtpserver.starttls()
            smtpserver.ehlo()
            if self.debug > 4 :
                self.writelog ("Connect to %s:%s Successfully" % (wserver,wport))
            try:
                smtpserver.login (wuser, wpwd)
            except smtplib.SMTPException :
                self.writelog ("Authentication for %s Failed %s" % (wuser))
                smtpserver.close()
                return 1
            if self.debug > 4 :
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
        if self.debug > 4 :
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
        if self.debug > 8 : print ("Trimming %s to %s lines." %  (fname, str(nlines)))

        # Check if fileName to trim exist
        if (not os.path.exists(fname)):                                     # If fileName doesn't exist
            print ("[ ERROR ] In '%s' function - File %s doesn't exist" % (fcname,fname))
            return 1
        tot_lines = len(open(fname).readlines())                            # Count total no. of lines

        # Create temporary file
        self.tmpfile = "%s/%s.%s" % (self.tmp_dir,inst,datetime.datetime.now().strftime("%y%m%d_%H%M%S"))

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
        if self.debug > 8 : 
            print ("Original Filename %s" % (fname))
            print ("TmpFileName %s" % (tmpfile))
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
            print ("[ ERROR ] in %s function - Error renaming %s to %s" % (fcname,tmpfile,fname))
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
    def check_command_availibility(self,cmd) :
        global FH_LOG_FILE

        ccode, cstdout, cstderr = self.oscommand("%s %s" % (self.which,cmd))  # Try to Locate Command
        if ccode is not 0 :                                             # Command was not Found
            self.writelog ("Warning : Command '%s' couldn't be found" % (cmd)) # Displat Warning for User
            self.writelog ("   This program is used by the SADMIN tools")    # Command is needed by SADM
            self.writelog ("   Please install it and re-run this script")    # May want to install it
            cmd_path=""                                                 # Cmd Path Null when Not fnd
        else :                                                          # If command Path is Found
            cmd_path = cstdout                                          # Save command Path
        if self.debug > 2 :                                                  # Prt Cmd Location if debug
            if cmd_path != "" :                                         # If Cmd was Found
                self.writelog ("Command '%s' located at %s" % (cmd,cmd_path))# Print Cmd Location
            else :                                                      # If Cmd was not Found
                self.writelog ("Command '%s' could not be located" % (cmd))  # Cmd Not Found to User 
        cmd_path = cmd_path.decode()
        return (cmd_path)                                               # Return Cmd Path


    # ----------------------------------------------------------------------------------------------
    # FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
    # IF REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
    # ----------------------------------------------------------------------------------------------
    def check_requirements(self):
        global FH_LOG_FILE, lsb_release, dmidecode, uname, fdisk, mail
    
        if self.debug > 5 :                                                  # If Debug Run Level 7
            self.writelog (" ")                                              # Space Line in the LOG
            self.writelog (dash)                                             # 80 = Lines 
            self.writelog ("Checking Libraries Requirements")                # Inform user in Debug
            self.writelog (dash)                                             # 80 = Lines 
        requisites_status=True                                          # Default Requisite met
    
        # Get the location of the which command
        if self.debug > 2 : self.writelog ("Is 'which' command available ...")    # Command Available ?
        ccode, cstdout, cstderr = self.oscommand("which which")
        if ccode is not 0 :
            self.writelog ("Error : The command 'which' could not be found")
            self.writelog ("        This program is often used by the SADMIN tools")
            self.writelog ("        Please install it and re-run this script")
            self.writelog ("        To install it, use the following command depending on your distro")
            self.writelog ("        Use 'yum install which' or 'apt-get install debianutils'")
            self.writelog ("Script Aborted")
            sys.exit(1)
        self.which = cstdout.decode()
        if self.debug > 2 :
            if self.which != "" :
                self.writelog ("Command 'which' located at %s" % self.which) # Print Cmd Location
            else :
                self.writelog ("Command 'which' could not be located ") # Cmd Not Found 
        requisites_status=False
 
    
        # Get the location of the lsb_release command
        lsb_release = self.check_command_availibility('lsb_release')    # location of lsb_release
        if lsb_release == "" :
            self.writelog ("CRITICAL: The 'lsb_release' is needed and is not present")
            self.writelog ("Please correct the situation and re-execute this script")
            requisites_status=False
 
    
        uname = self.check_command_availibility('uname')                # location of uname 
        if uname == "" :
            self.writelog ("CRITICAL: The 'uname' is needed and is not present")
            self.writelog ("Please correct the situation and re-execute this script")
            requisites_status=False
    
        fdisk =     self.check_command_availibility('fdisk')            # location of fdisk 
        mail =      self.check_command_availibility('mail')             # location of mail
        dmidecode = self.check_command_availibility('dmidecode')        # location of dmidecode   
        return requisites_status
 

    # ----------------------------------------------------------------------------------------------
    # Method make sure directories needed are created, 
    # Log initialize and Start Time Recorded in RCH File
    # ----------------------------------------------------------------------------------------------
    def start (self) :
        global FH_LOG_FILE, start_time, start_epoch
    
        # First thing Make sure the log file is Open and Log Directory created
        try:                                                            # Try to Open/Create Log
            if not os.path.exists(self.log_dir)  : os.mkdir(self.log_dir,2775) # Create SADM Log Dir
            if self.log_append == "Y" :                                 # User Want to Append to Log
                FH_LOG_FILE=open(self.log_file,'a')                     # Open Log in append  mode
            else:                                                       # User Want Fresh New Log
                FH_LOG_FILE=open(self.log_file,'w')                     # Open Log in a new log
        except IOError as e:                                            # If Can't Create or open
            print ("Error open file %s \r\n" % self.log_file)           # Print Log FileName
            print ("Error Number : {0}\r\n.format(e.errno)")            # Print Error Number    
            print ("Error Text   : {0}\r\n.format(e.strerror)")         # Print Error Message
            sys.exit(1)                                                 # Exit with Error

        # Second thing chack if requirement are met
        self.check_requirements()                                       # Check SADM Requirement Met
    
        # Make sure all SADM Directories structure exist
        if not os.path.exists(self.cfg_dir)  : os.mkdir(self.cfg_dir,0o0775)# Create Configuration Dir
        if not os.path.exists(self.tmp_dir)  : os.mkdir(self.tmp_dir,0o1777)# Create SADM Temp Dir.
        if not os.path.exists(self.dat_dir)  : os.mkdir(self.dat_dir,0o0775)# Create SADM Data Dir.
        if not os.path.exists(self.bin_dir)  : os.mkdir(self.bin_dir,0o0775)# Create SADM Bin Dir.
        if not os.path.exists(self.log_dir)  : os.mkdir(self.log_dir,0o0775)# Create SADM Log Dir.
        if not os.path.exists(self.lib_dir)  : os.mkdir(self.lib_dir,0o0775)# Create SADM Lib Dir.
        if not os.path.exists(self.sys_dir)  : os.mkdir(self.sys_dir,0o0775)# Create SADM Sys Dir.
        if not os.path.exists(self.nmon_dir) : os.mkdir(self.nmon_dir,0o0775) # Create SADM nmon Dir.
        if not os.path.exists(self.dr_dir)   : os.mkdir(self.dr_dir,0o0775) # Create SADM DR Dir.
        if not os.path.exists(self.dr_dir)   : os.mkdir(self.dr_dir,0o0775) # Create SADM DR Dir.
        if not os.path.exists(self.sar_dir)  : os.mkdir(self.sar_dir,0o0775)# Create SADM System Act Dir
        if not os.path.exists(self.rch_dir)  : os.mkdir(self.rch_dir,0o0775)# Create SADM RCH Dir.
        if not os.path.exists(self.net_dir)  : os.mkdir(self.net_dir,0o0775)# Create SADM RCH Dir.
        if not os.path.exists(self.rpt_dir)  : os.mkdir(self.rpt_dir,0o0775)# Create SADM RCH Dir.

        # These Directories are only created on the SADM Server (Data Base and Web Directories)
        if self.get_hostname() == self.cfg_server :
            if not os.path.exists(www_dat_net_dir) : os.mkdir(www_dat_net_dir,0o0775) # Web  Network  Dir.

            # Get the userid and groupid chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
            uid = pwd.getpwnam(cfg_user).pw_uid                         # Get UID User in sadmin.cfg 
            gid = grp.getgrnam(cfg_group).gr_gid                        # Get GID User in sadmin.cfg 

            uid = pwd.getpwnam(cfg_pguser).pw_uid                       # Get UID User in sadmin.cfg 
            gid = grp.getgrnam(cfg_pggroup).gr_gid                      # Get GID User in sadmin.cfg 
            os.chown(pg_dir, uid, gid)                                  # Change owner of rch file

            if not os.path.exists(www_dir)      : os.mkdir(www_dir,0o0775)      # Create SADM WWW Dir.
            if not os.path.exists(www_html_dir) : os.mkdir(www_html_dir,0o0775) # Create SADM HTML Dir.
            if not os.path.exists(www_dat_dir)  : os.mkdir(www_dat_dir,0o0775)  # Create Web  DAT  Dir.
            if not os.path.exists(www_lib_dir)  : os.mkdir(www_lib_dir,0o0775)  # Create Web  DAT  Dir.
            wuid = pwd.getpwnam(cfg_www_user).pw_uid                    # Get UID User of Wev User 
            wgid = grp.getgrnam(cfg_www_group).gr_gid                   # Get GID User of Web Group 
            os.chown(www_dir, wuid, wgid)                               # Change owner of log file
            os.chown(www_dat_net_dir, wuid, wgid)                       # Change owner of Net Dir
            os.chown(www_html_dir, wuid, wgid)                          # Change owner of rch file
            os.chown(www_dat_dir, wuid, wgid)                           # Change owner of dat file
            os.chown(www_lib_dir, wuid, wgid)                           # Change owner of lib file
    
        
        # Write SADM Header to Script Log
        self.writelog (dash)                                            # 80 = Lines 
        wmess = "Starting %s - Version.%s on %s" % (pn,ver,hostname)    # Build Log Starting Line
        self.writelog (wmess)                                           # Write Start line to Log
        wmess = "%s %s %s %s" % (self.os_type,self.get_osname(),self.get_osversion(),self.get_oscodename())
        self.writelog (wmess)                                           # Write OS Info to Log Head
        self.writelog (dash)                                            # 80 = Lines 
        self.writelog (" ")                                             # Space Line in the LOG

        # If the PID file already exist - Script is already Running
        if os.path.exists(self.pid_file) and self.multiple_exec == "N" :# PID Exist & No MultiRun
            self.writelog ("Script %s is already runnin" % pn)          # Same script is running
            self.writelog ("PID File %s exist." % pid_file)             # Display PID File Location
            self.writelog ("Will not run a second copy of this script") # Advise the user
            self.writelog ("Script Aborted")                            # Script Aborted
            sys.exit(1)                                                 # Exit with Error
    
        # Record Date & Time the script is starting in the RCH File
        i = datetime.datetime.now()                                     # Get Current Time
        start_time=i.strftime('%Y.%m.%d %H:%M:%S')                      # Save Start Date & Time
        start_epoch = int(time.time())                                  # StartTime in Epoch Time
        try:
            FH_RCH_FILE=open(self.rch_file,'a')                         # Open RC Log in append mode
        except IOError as e:                                            # If Can't Create or open
            print ("Error open file %s \r\n" % rch_file)                # Print Log FileName
            print ("Error Number : {0}\r\n.format(e.errno)")            # Print Error Number    
            print ("Error Text   : {0}\r\n.format(e.strerror)")         # Print Error Message
            sys.exit(1)     
        rch_line="%s %s %s %s %s" % (hostname,start_time,".......... ........ ........",inst,"2")
        FH_RCH_FILE.write ("%s\n" % (rch_line))                         # Write Line to RCH Log
        FH_RCH_FILE.close()                                             # Close RCH File
        return 0



    # ----------------------------------------------------------------------------------------------
    # Method that write script Footer in the Log, Close the Database
    # Record the End Time in the RCH, close the log amd RCH File , Trim the RCH file and Log
    # ----------------------------------------------------------------------------------------------
    def stop(self,return_code):
        global FH_LOG_FILE, start_time, start_epoch

        exit_code = return_code                                         # Save Param.Recv Code
        if exit_code is not 0 :                                         # If Return code is not 0
            exit_code=1                                                 # Making Sure code is 1 or 0
 
        # Write the Script Exit code of the script to the log
        self.writelog (" ")                                             # Space Line in the LOG
        self.writelog (dash)                                            # 80 = Lines 
        self.writelog ("Script return code is " + str(exit_code))       # Script ExitCode to Log
        #time.sleep(1)                                                  # Sleep 1 seconds

    
        # Calculate the execution time, format it and write it to the log
        end_epoch = int(time.time())                                    # Save End Time in Epoch Time
        elapse_seconds = end_epoch - start_epoch                        # Calc. Total Seconds Elapse
        hours = elapse_seconds//3600                                    # Calc. Nb. Hours
        elapse_seconds = elapse_seconds - 3600*hours                    # Subs. Hrs*3600 from elapse
        minutes = elapse_seconds//60                                    # Cal. Nb. Minutes
        seconds = elapse_seconds - 60*minutes                           # Subs. Min*60 from elapse
        elapse_time="%02d:%02d:%02d" % (hours,minutes,seconds)
        self.writelog ("Script execution time is %02d:%02d:%02d" % (hours,minutes,seconds))

    
        # Update the [R]eturn [C]ode [H]istory File
        i = datetime.datetime.now()                                     # Get Current Stop Time
        stop_time=i.strftime('%Y.%m.%d %H:%M:%S')                       # Format Stop Date & Time
        FH_RCH_FILE=open(self.rch_file,'a')                             # Open RCH Log - append mode
        rch_line="%s %s %s %s %s %s" % (hostname,start_time,stop_time,elapse_time,inst,exit_code)
        FH_RCH_FILE.write ("%s\n" % (rch_line))                         # Write Line to RCH Log
        FH_RCH_FILE.close()                                             # Close RCH File
        self.writelog ("Trimming %s to %s lines." %  (self.rch_file, str(self.cfg_max_rchline)))


        # Write in Log the email choice the user as requested (via the sadmin.cfg file)
        # 0 = No Mail Sent      1 = On Error Only   2 = On Success Only   3 = Always send email
        if self.cfg_mail_type == 0 :                                    # User don't want any email
            MailMess="No mail is requested when script end - No mail sent" # Message User Email Choice

        if self.cfg_mail_type == 1 :                                    # Want Email on Error Only
            if exit_code != 0 :                                         # If Script Failed = Email
                MailMess="Mail requested if script fail - Mail sent"    # Message User Email Choice
            else :                                                      # Script Success = No Email
                MailMess="Mail requested if script fail - No mail sent" # Message User Email Choice

        if self.cfg_mail_type == 2 :                                    # Email on Success Only
            if not exit_code == 0 :                                     # If script is a Success
                MailMess="Mail requested on Success only - Mail sent"   # Message User Email Choice
            else :                                                      # If Script not a Success
                MailMess="Mail requested on Success only - No mail sent"# Message User Email Choice

        if self.cfg_mail_type == 3 :                                    # User always Want email 
            MailMess="Mail requested on Success or Error - Mail sent"   # Message User Email Choice
    
        if self.cfg_mail_type > 3 or self.cfg_mail_type < 0 :                # User Email Choice Invalid
            MailMess="SADM_MAIL_TYPE is not set properly [0-3] Now at %s",(str(cfg_mail_type))

        if mail == "" :                                                 # If Mail Program not found
            MailMess="No Mail can be send - Until mail command is install"  # Message User Email Choice    
        self.writelog ("%s" % (MailMess))                               # Write user choice to log
    
          
        # Advise user the Log will be trimm
        self.writelog ("Trimming %s to %s lines." %  (self.log_file, str(self.cfg_max_logline)))
    
        # Write Script Log Footer
        now = time.strftime("%c")                                       # Get Current Date & Time
        self.writelog (now + " - End of " + pn)                              # Write Final Footer to Log
        self.writelog (dash)                                                 # 80 = Lines 
        self.writelog (" ")                                                  # Space Line in the LOG

        # Inform UnixAdmin By Email based on his selected choice
        # Now that the user email choice is written to the log, let's send the email now, if needed
        # 0 = No Mail Sent      1 = On Error Only   2 = On Success Only   3 = Always send email
        wsubject=""                                                     # Clear Email Subject
        wsub_success="SADM : SUCCESS of %s on %s" % (pn,hostname)       # Format Success Subject
        wsub_error="SADM : ERROR of %s on %s" % (pn,hostname)           # Format Failed Subject
    
        if exit_code != 0 and (self.cfg_mail_type == 1 or self.cfg_mail_type == 3): # If Error & User want email
            wsubject=wsub_error                                         # Build the Subject Line
           
        if self.cfg_mail_type == 2 and exit_code == 0 :                 # Success & User Want Email
            wsubject=wsub_success                                       # Format Subject Line

        if self.cfg_mail_type == 3 :                                    # USer Always want Email
            if exit_code == 0 :                                         # If Script is a Success
                wsubject=wsub_success                                   # Build the Subject Line
            else :                                                      # If Script Failed 
                wsubject=wsub_error                                     # Build the Subject Line

        if wsubject != "" :                                             # subject Then Email Needed
            time.sleep(1)                                               # Sleep 1 seconds
            cmd = "cat %s | %s -s '%s' %s" % (self.log_file,mail,wsubject,self.cfg_mail_addr) 
            ccode, cstdout, cstderr = self.oscommand("%s" % (cmd))      # Go send email 
            if ccode != 0 :                                             # If Cmd Fail
                self.writelog ("ERROR : Problem sending mail to %s" % (self.cfg_mail_addr))
    
        FH_LOG_FILE.flush()                                             # Got to do it - Missing end
        FH_LOG_FILE.close()                                             # Close the Log File

        # Trimming the Log 
        self.trimfile (self.log_file, self.cfg_max_logline)             # Trim the Script Log 
        self.trimfile (self.rch_file, self.cfg_max_rchline)             # Trim the Script RCH Log 
    
        # Get the userid and groupid chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
        uid = pwd.getpwnam(self.cfg_user).pw_uid                        # Get UID User in sadmin.cfg
        gid = grp.getgrnam(self.cfg_group).gr_gid                       # Get GID User in sadmin.cfg

        # Make Sure Owner/Group of Log File are the one chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
        try : 
            os.chown(self.log_file, uid, gid)                           # Change owner of log file
            os.chmod(self.log_file, 0o0644)                             # Change Log File Permission
        except Exception as e: 
            msg = "Warning : Couldn't change owner or chmod of "        # Build Warning Message
            print ("%s %s to %s.%s" % (msg,self.log_file,self.cfg_user,self.cfg_group))

        # Make Sure Owner/Group of RCH File are the one chosen in sadmin.cfg (SADM_USER/SADM_GROUP)
        try : 
            os.chown(self.rch_file, uid, gid)                           # Change owner of rch file
            os.chmod(self.rch_file, 0o0644)                             # Change RCH File Permission
        except Exception as e: 
            msg = "Warning : Couldn't change owner or chmod of "        # Build Warning Message
            print ("%s %s to %s.%s" % (msg,self.rch_file,self.cfg_user,self.cfg_group))

        # Delete Temproray files used
        self.silentremove (self.pid_file)                               # Delete PID File
        self.silentremove (self.tmp_file1)                              # Delete Temp file 1
        self.silentremove (self.tmp_file2)                              # Delete Temp file 2
        self.silentremove (self.tmp_file3)                              # Delete Temp file 3
        return exit_code


    # ----------------------------------------------------------------------------------------------
    # For Debugging Purpose - Display all Important Environment Variables used across SADM Libraries
    # ----------------------------------------------------------------------------------------------
    def display_env(self):
        print(" ")                                                      # Space Line in the LOG
        print(dash)                                                     # 80 = Lines 
        print("Display Important Environment Variables")                # Introduce Display Below
        print(dash)                                                     # 80 = Lines 
        print("SADMIN Release No.  = " + self.get_release())            # Get SADMIN Release Version
        print("sadmlib_std.py      = " + ver)                           # Program Version
        print("pn                  = " + pn)                            # Program name
        print("inst                = " + inst)                          # Program name without Ext.
        print("hostname            = " + hostname)                      # Program name without Ext.
        print("username            = " + username)                      # Current User Name
        print("tpid                = " + tpid)                          # Get Current Process ID.
        print("self.debug          = " + str(self.debug))               # Debug Level
        print("get_ostype()        = " + self.os_type)                  # OS Type Linux or Aix
        print("get_osname()        = " + self.get_osname())             # Distribution of OS
        print("get_osversion()     = " + self.get_osversion())          # Distribution Version
        print("get_osmajorversion()= " + self.get_osmajorversion())     # Distribution Major Ver#
        print("get_oscodename()    = " + self.get_oscodename())         # Distribution Code Name
        print("log_type            = " + self.log_type)                 # 4Logger S=Scr L=Log B=Both
        print("multiple_exec       = " + self.multiple_exec)            # Permit Multiple Execution
        print("log_append          = " + self.log_append)               # Do not overwrite Prev. Log
        print("base_dir            = " + self.base_dir)                 # Base Dir. where appl. is
        print("tmp_dir             = " + self.tmp_dir)                  # SADM Temp. Directory
        print("cfg_dir             = " + self.cfg_dir)                  # SADM Config Directory
        print("lib_dir             = " + self.lib_dir)                  # SADM Library Directory
        print("bin_dir             = " + self.bin_dir)                  # SADM Scripts Directory
        print("log_dir             = " + self.log_dir)                  # SADM Log Directory
        print("www_dir             = " + self.www_dir)                  # SADM WebSite Dir Structure
        print("pkg_dir             = " + self.pkg_dir)                  # SADM Package Directory
        print("sys_dir             = " + self.sys_dir)                  # SADM System Scripts Dir.
        print("dat_dir             = " + self.dat_dir)                  # SADM Data Directory
        print("nmon_dir            = " + self.nmon_dir)                 # SADM nmon File Directory
        print("rch_dir             = " + self.rch_dir)                  # SADM Result Code Dir.
        print("dr_dir              = " + self.dr_dir)                   # SADM Disaster Recovery Dir
        print("sar_dir             = " + self.sar_dir)                  # SADM System Activity Rep.
        print("www_dat_dir         = " + self.www_dat_dir)              # SADM Web Site Data Dir
        print("www_html_dir        = " + self.www_html_dir)             # SADM Web Site Dir
        print("log_file            = " + self.log_file)                 # SADM Log File
        print("rch_file            = " + self.rch_file)                 # SADM RCH File
        print("cfg_file            = " + self.cfg_file)                 # SADM Config File
        print("pid_file            = " + self.pid_file)                 # SADM PID FileName
        print("tmp_file1           = " + self.tmp_file1)                # SADM Tmp File 1
        print("tmp_file2           = " + self.tmp_file2)                # SADM Tmp File 2
        print("tmp_file3           = " + self.tmp_file3)                # SADM Tmp File 3
        print("which               = " + self.which)                    # Location of which
        print("lsb_release         = " + self.lsb_release)              # Location of lsb_release
        print("dmidecode           = " + self.dmidecode)                # Location of dmidecode
        print("fdisk               = " + self.fdisk)                    # Location of fdisk
        print("uname               = " + self.uname)                    # Location of uname
        print(" ")                                                      # Space Line in the LOG
        print(dash)                                                     # 80 = Lines 

        print("Global variables setting after reading the SADM Configuration file")
        print(dash)                                                     # 80 = Lines 
        print("cfg_mail_addr       = ..." + self.cfg_mail_addr + "...")
        print("cfg_cie_name        = ..." + self.cfg_cie_name + "...")
        print("cfg_mail_type       = ..." + str(self.cfg_mail_type) + "...")
        print("cfg_server          = ..." + self.cfg_server + "...")
        print("cfg_domain          = ..." + self.cfg_domain + "...")
        print("cfg_user            = ..." + self.cfg_user + "...")
        print("cfg_group           = ..." + self.cfg_group + "...")
        print("cfg_www_user        = ..." + self.cfg_www_user + "...")
        print("cfg_www_group       = ..." + self.cfg_www_group + "...")
        print("cfg_max_logline     = ..." + str(self.cfg_max_logline) + "...")
        print("cfg_max_rchline     = ..." + str(self.cfg_max_rchline) + "...")
        print("cfg_nmon_keepdays   = ..." + str(self.cfg_nmon_keepdays) + "...")
        print("cfg_sar_keepdays    = ..." + str(self.cfg_sar_keepdays) + "...")
        print("cfg_rch_keepdays    = ..." + str(self.cfg_rch_keepdays) + "...")
        print("cfg_log_keepdays    = ..." + str(self.cfg_log_keepdays) + "...")
        print("cfg_dbname          = ..." + self.cfg_dbname + "...")
        print("cfg_dbhost          = ..." + self.cfg_dbhost + "...")
        print("cfg_dbport          = ..." + str(self.cfg_dbport) + "...")
        print("cfg_rw_dbuser       = ..." + str(self.cfg_rw_dbuser) + "...")
        print("cfg_rw_dbpwd        = ..." + str(self.cfg_rw_dbpwd) + "...")
        print("cfg_ro_dbuser       = ..." + str(self.cfg_ro_dbuser) + "...")
        print("cfg_ro_dbpwd        = ..." + str(self.cfg_ro_dbpwd) + "...")
        print("cfg_ssh_port        = ..." + str(self.cfg_ssh_port) + "...")
        return 0
