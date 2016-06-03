#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_lib_global.py
#   Synopsis:   This Module contain all common variables used by SADM Libraries and Python Scripts.
#===================================================================================================
import os, time, sys, pdb, socket, datetime, getpass, subprocess 
#from subprocess import Popen, PIPE

# SADM Library Add to Python Path and Import SADM Library and GLOBAL Variables
base_dir                = os.environ.get('SADMIN','/sadmin')            # Base Dir. where appl. is
sadm_lib_dir            = os.path.join(base_dir,'lib')                  # SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add /sadmin/lib to PyPath
import sadm_lib_std    as sadmlib                                       # Import sadm Library 
import sadm_var        as g                                             # Import GLOBAL Var 
#pdb.set_trace() 


#===================================================================================================
#                    Global Variables Shared among all SADM Libraries and Scripts
#===================================================================================================
ver                = "1.0"                                              # Default Program Version
logtype            = "B"                                                # Default S=Scr L=Log B=Both
multiple_exec      = "N"                                                # Default Run multiple copy
debug              = 8                                                  # Default Debug Level (0-9)

pn                 = os.path.basename(sys.argv[0])                      # Program name
inst               = os.path.basename(sys.argv[0]).split('.')[0]        # Program name without Ext.
tpid               = str(os.getpid())                                   # Get Current Process ID.
hostname           = socket.gethostname().split('.')[0]                 # Get current hostname
dash               = "=" * 80                                           # Line of 80 dash
exit_code          = 0                                                  # Script Error Return Code
username           = getpass.getuser()                                  # Get Current User Name
args               = len(sys.argv)                                      # Nb. argument receive
osname             = os.name                                            # OS name (nt,dos,posix,...)
platform           = sys.platform                                       # Platform (win32,mac,posix)
start_time         = ""                                                 # Script Start Date & Time
stop_time          = ""                                                 # Script Stop Date & Time
start_epoch        = ""                                                 # Script Start EPoch Time

# SADM Sub Directories Definitions
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
log                = log_dir + '/' + hostname + '_' + inst + '.log'     # Log Filename
rchlog             = rch_dir + '/' + hostname + '_' + inst + '.rch'     # RCH Filename
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
#cfg_smtp_server    = ""                                                 # Taken from sadmin.cfg
#cfg_smtp_port      = ""                                                 # Taken from sadmin.cfg
#cfg_smtp_user_mail = ""                                                 # Taken from sadmin.cfg
#cfg_smtp_user_pwd  = ""                                                 # Taken from sadmin.cfg
 
# SADM Path to various commands used by SADM Tools
lsb_release        = ""                                                 # Command lsb_release Path
which              = ""                                                 # whic1h Path - Required
dmidecode          = ""                                                 # Command dmidecode Path
bc                 = ""                                                 # Command bc (Do Some Math)
fdisk              = ""                                                 # fdisk (Read Disk Capacity)
perl               = ""                                                 # perl Path (for epoch time)
uname              = ""                                                 # uname command path
mail               = ""                                                 # mail command path

# SADM Class Objects Instances
sadmlog            = ""                                                 # Log File Class Instance 
#fh_log             = ""

