#!/usr/bin/env python3
#===================================================================================================
#   Author:     : Jacques Duplessis
#   Title:      : sadmlib_std_demo.py
#   Version     : 1.0
#   Date        : 14 July 2017
#   Requires    : python3 and SADM Library
#   Description : Demonstrate Functions, Variables available to users using SADMIN Tools
# 
#   Copyright (C) 2016-2018 Jacques Duplessis <sadmlinux@gmail.com> - http://www.sadmin.ca
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2017_07_07    V1.7 Minor Code enhancement
# 2017_07_31    V1.8 Added Log Template to script
# 2017_09_02    V1.9 Add Command line switch 
# 2017_09_02    V2.0 Rewritten Part of script for performance and flexibility
# 2017_12_12    V2.1 Adapted to use MySQL instead of Postgres Database
# 2017_12_23    V2.3 Changes for performance and flexibility
# 2018_01_25    V2.4 Added Variable SADM_RRDTOOL to sadmin.cfg display
# 2018_02_21    V2.5 Minor Changes 
# 2018_05_26    V2.6 Major Rewrite, Better Performance
# 2018_05_28    V2.7 Add Backup Parameters now in sadmin.cfg
# 2018_06_04    v2.8 Added User Directory Environment Variables in SADMIN Client Section
# 2018_06_05    v2.9 Added setup, www/tmp/perf Directory Environment Variables 
# 2018_12_03    v3.0 Remove dot before and after the result column and minor changes.
# 2019_01_19    v3.1 Added: Added Backup List & Backup Exclude File Name available to User.
# 2019_01_28 Added: v3.2 Database info only show when running on SADMIN Server
# 2019_03_18 Added: v3.3 Add demo call to function get_packagetype()
# 2019_04_07 Update: v3.4 Don't show Database user name if run on client.
# 2019_04_25 Update: v3.5 Add Alert_Repeat, Textbelt API Key and URL Variable in Output
# 2019_05_17 Update: v3.6 Add option -p(Show DB password),-s(Show Storix Info),-t(Show TextBeltKey)
# 2019_08_19 update: v3.7 Remove printing of st.alert_seq (not used anymore)
# 2019_10_14 Update: v3.8 Add demo for calling sadm_server_arch function & show result.
# 2019_10_18 Update: v3.9 Print SADMIN Database Tables and columns at the end of report.
# 2019_10_30 Update: v3.10 Remove Utilization of 'facter' (Depreciated).
#@2021_05_03 Update: v3.11 Rewrote "Overview of setup_admin(), st.start() & st.stop()" section.
#@2022_04_10 Update: v3.12 Remove lsb_release command dependency
#===================================================================================================
#
try :
    import os, time, sys, pdb, socket, datetime, glob, getopt, fnmatch ,argparse
    import sadmlib_std as sadm
except ImportError as e:                                            
    print ("Import Error : %s " % e)
    sys.exit(1)


#pdb.set_trace()                                                    # Activate Python Debugging


#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
lcount              = 0                                                 # Print Line Counter
#
show_password       = "N"                                               # Don't show DB Password
show_storix         = "N"                                               # Don't show Storix Info
show_textbelt       = "N"                                               # Don't show TextBelt Key




# --------------------------------------------------------------------------------------------------
# SADMIN PYTHON FRAMEWORK SECTION 2.0
# To use SADMIN tools, this section MUST be present near the top of your code.
# --------------------------------------------------------------------------------------------------
try:
    SADM = os.environ.get('SADMIN')                                     # Getting SADMIN Root Dir.
    sys.path.insert(0, os.path.join(SADM, 'lib'))                       # Add lib dir to sys.path
    import sadmlib2_std as sa                                           # Load SADMIN Python Library
except ImportError as e:                                                # If Error importing SADMIN
    print("Import error : SADMIN module: %s " % e)                      # Advise User of Error
    sys.exit(1)                                                         # Go Back to O/S with Error

# Local variables local to this script.
pver = "1.0"                                                            # Script Version
pdesc = "Update 'pdesc' variable & put a description of your script."   # Script Description
phostname = platform.node().split('.')[0].strip()                       # Get current hostname
pdb_conn = None                                                         # Database Connector
pdb_cur = None                                                          # Database Cursor
pdebug = 0                                                              # Debug Level from 0 to 9
pexit_code = 0                                                          # Script Default Exit Code

# The values of fields below, are loaded from sadmin.cfg when you import the SADMIN library.
# Uncomment anyone of them to influence execution of SADMIN standard library.
#
#sa.sadm_alert_type  = 1          # 0=NoAlert 1=AlertOnlyOnError 2=AlertOnlyOnSuccess 3=AlwaysAlert
#sa.sadm_alert_group = "default"  # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
#sa.pid_timeout      = 7200       # PID File Default Time to Live in seconds.
#sa.lock_timeout     = 3600       # A host can be lock for this number of seconds, auto unlock after
#sa.max_logline      = 500        # Max. lines to keep in log (0=No trim) after execution.
#sa.max_rchline      = 40         # Max. lines to keep in rch (0=No trim) after execution.
#sa.log_type         = 'B'        # Output goes to [S]creen to [L]ogFile or [B]oth
#sa.log_append       = False      # Append Existing Log(True) or Create New One(False)
#sa.log_header       = True       # Show/Generate Header in script log (.log)
#sa.log_footer       = True       # Show/Generate Footer in script log (.log)
#sa.multiple_exec    = "Y"        # Allow running multiple copy at same time ?
#sa.db_used          = True       # Open/Use Database(True) or Don't Need DB(False)
#sa.db_silent        = False      # When DB Error, False=ShowErrMsg, True=NoErrMsg
#sa.rch_used         = True       # Generate entry in Result Code History (.rch)
#sa.sadm_mail_addr   = ""         # All mail goes to this email (Default is in sadmin.cfg)
cmd_ssh_full = "%s -qnp %s " % (sa.cmd_ssh, sa.sadm_ssh_port)           # SSH Cmd to access clients
# ==================================================================================================



# --------------------------------------------------------------------------------------------------
#  Show command line options to user.
# --------------------------------------------------------------------------------------------------
def show_usage():
    print ("\nUsage :",os.path.basename(sys.argv[0]))
    print ("\t-p --password             (Show database password on output)")
    print ("\t-s --storix               (Show Storix Backup information)")
    print ("\t-t --textbelt             (Show TextBelt Key)")        
    print ("\t-d --debug  <level>       (Debug Level [0-9])")
    print ("\t-h --help                 (Show this help message)")
    print ("\t-v --version              (Show Script Version Info)")
    print ("\n")



#===================================================================================================
# Standardize Print Line Function 
#===================================================================================================
def printline(st,col1="",col2="",col3=""):
    global lcount 
    lcount += 1
    print ("[%03d] " % lcount, end='')
    if col1 != "" : print ("%-33s" % (col1), end='')
    if col2 != "" : print ("%-36s" % (col2), end='')
    #if col1 != "" and col2 != "" : print ("%-s%-s%-s" % (": .",col3,"."))
    if col1 != "" and col2 != "" : print ("%-s%-s%-s" % (": ",col3," "))



#===================================================================================================
# Standardize Print Header Function 
#===================================================================================================
def printheader(st,col1,col2,col3=" "):
    global lcount

    lcount = 0 
    print ("\n\n\n%s" % ("=" * 100))
    print ("%s v%s - Library v%s" % (sa.pn,pver,sa.lib_ver))
    print ("%-39s%-36s%-33s" % (col1,col2,col3))
    print ("%s" % ("=" * 100))



#===================================================================================================
# Print SADMIN Function available to Users
#===================================================================================================
def print_functions(st):
    printheader (st,"Calling Functions","Description","  This System Result")

    pexample="sa.get_release()"                                         # Variable Name
    pdesc="SADMIN Release Number (XX.XX)"                               # Function Description
    presult=sa.get_release()                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_ostype()"                                          # Variable Name
    pdesc="OS Type (Uppercase,LINUX,AIX,DARWIN)"                        # Function Description
    presult=st.get_ostype()                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_osversion()"                                       # Variable Name
    pdesc="Return O/S Version (Ex: 7.2, 6.5)"                           # Function Description
    presult=st.get_osversion()                                          # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_osmajorversion()"                                  # Variable Name
    pdesc="Return O/S Major Version (Ex 7, 6)"                          # Function Description
    presult=st.get_osmajorversion()                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_osminorversion()"                                  # Variable Name
    pdesc="Return O/S Minor Version (Ex 2, 3)"                          # Function Description
    presult=st.get_osminorversion()                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_osname()"                                          # Variable Name
    pdesc="O/S Name (REDHAT,CENTOS,UBUNTU,...)"                         # Function Description
    presult=st.get_osname()                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_oscodename()"                                      # Variable Name
    pdesc="O/S Project Code Name"                                       # Function Description
    presult=st.get_oscodename()                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_kernel_version()"                                  # Example Calling Function
    pdesc="O/S Running Kernel Version"                                  # Function Description
    presult=st.get_kernel_version()                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_kernel_bitmode()"                                  # Example Calling Function
    pdesc="O/S Kernel Bit Mode (32 or 64)"                              # Function Description
    presult=st.get_kernel_bitmode()                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.hostname"                                              # Variable Name
    pdesc="Current Host Name"                                           # Function Description
    presult=st.hostname                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_host_ip()"                                         # Example Calling Function
    pdesc="Current Host IP Address"                                     # Function Description
    presult=st.get_host_ip()                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_domainname()"                                      # Example Calling Function
    pdesc="Current Host Domain Name"                                    # Function Description
    presult=st.get_domainname()                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_fqdn()"                                            # Example Calling Function
    pdesc="Fully Qualified Domain Host Name"                            # Function Description
    presult=st.get_fqdn()                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    #pexample="st.get_serial()"                                          # Example Calling Function
    #pdesc="Get System serial Number"                                    # Function Description
    #presult=st.get_serial()                                             # Return Value(s)
    #printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_epoch_time()"                                      # Example Calling Function
    pdesc="Get Current Epoch Time"                                      # Function Description
    presult=st.get_epoch_time()                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    wepoch= st.get_epoch_time()
    pexample="st.epoch_to_date(%d)" % (wepoch)                          # Example Calling Function
    pdesc="Convert epoch time to date"                                  # Function Description
    presult=st.epoch_to_date(wepoch)                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    WDATE=st.epoch_to_date(wepoch)                                      # Set Test Date
    print ("      WDATE=%s" % (WDATE))                                  # Print Test Date    
    pexample="st.date_to_epoch(WDATE)"                                  # Example Calling Function
    pdesc="Convert Date to epoch time"                                  # Function Description
    presult=st.date_to_epoch(WDATE)                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    DATE1="2018.06.30 10:00:44" ; DATE2="2018.06.30 10:00:03"           # Set Date to Calc Elapse
    print ("      DATE1=%s" % (DATE1))                                  # Print Date1 Used for Ex.
    print ("      DATE2=%s" % (DATE2))                                  # Print Date2 Used for Ex.
    pexample="st.elapse_time(DATE1,DATE2)"                              # Example Calling Function
    pdesc="Elapse Time between two timestamps"                          # Function Description
    presult=st.elapse_time(DATE1,DATE2)                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_packagetype()"                                     # Example Calling Function
    pdesc="Get package type (rpm,deb,aix,dmg)"                          # Function Description
    presult=st.get_packagetype()                                        # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.get_arch()"                                            # Example Calling Function
    pdesc="Get system architecture"                                     # Function Description
    presult=st.get_arch()                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line




#===================================================================================================
# Print SADMIN Function available to Users
#===================================================================================================
def print_python_function(st):
    printheader (st,"SADMIN PYTHON SPECIFIC FUNCTIONS","Description","  This System Result")

    pexample="st.dbsilent"                                              # Variable Name
    pdesc="When DBerror, No ErrMsg (Just ErrNo)"                        # Function Description
    presult=st.dbsilent                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="st.usedb"                                                 # Variable Name
    pdesc="Script need (Open/Close) Database ?"                         # Function Description
    presult=st.usedb                                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.silentremove('file')"                                  # Example Calling Function
    pdesc="Silent File Del, No Err if not exist"                        # Function Description
    presult=st.silentremove('file')                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.writelog(msg,'nonl'|'bold')"                           # Example Calling Function
    pdesc="Write Log (nonl=NoNewLine)"                                  # Function Description
    st.log_type="L"
    presult=st.writelog('Message','bold')                               # Return Value(s)
    st.log_type="B"
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    #print ('\nccode,cstdout,cstderr = ins.oscommand("%s" % (wcommand))')
    #print ('\nins.trimfile (file, maxline=500)')
    #print ('\npathname = ins.locate_command(wcommand)')

#===================================================================================================
# Print User Variables that affect SADMIN Tools Behavior
#===================================================================================================
def print_user_variables(st):
    printheader (st,"User Var. that affect SADMIN behavior","Description","  This System Result")

    pexample="st.ver"                                                   # Variable Name
    pdesc="Get/Set Script Version Number"                               # Function Description
    presult=st.ver                                                      # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.pn"                                                    # Variable Name
    pdesc="Get script name"                                             # Function Description
    presult=st.pn                                                       # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.inst"                                                  # Variable Name
    pdesc="Get script name without extension"                           # Function Description
    presult=st.inst                                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.username"                                              # Variable Name
    pdesc="Get current user name"                                       # Function Description
    presult=st.username                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.tpid"                                                  # Variable Name
    pdesc="Get Current Process ID"                                      # Function Description
    presult=st.tpid                                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.multiple_exec"                                         # Variable Name
    pdesc="Get/Set Allow running multiple copy"                         # Function Description
    presult=st.multiple_exec                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.use_rch"                                               # Variable Name
    pdesc="Get/Set Gen. entry in .rch file"                             # Function Description
    presult=st.use_rch                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="st.log_type"                                              # Variable Name
    pdesc="Set Output to [S]creen [L]og [B]oth"                         # Function Description
    presult=st.log_type                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="st.log_append"                                            # Variable Name
    pdesc="Get/Set Append Log or Create New One"                        # Function Description
    presult=st.log_append                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="st.log_header"                                            # Variable Name
    pdesc="Get/Set Generate Header in log"                              # Function Description
    presult=st.log_header                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="st.log_footer"                                            # Variable Name
    pdesc="Get/Set Generate Footer in  log"                             # Function Description
    presult=st.log_footer                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                       
    pexample="st.exit_code"                                             # Variable Name
    pdesc="Get/Set Script Exit Return Code"                             # Function Description
    presult=st.exit_code                                                # Current Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                       
    return(0)


#===================================================================================================
# Print Directories Variables Available to Users
#===================================================================================================
def print_client_directory(st):
    printheader (st,"Client Directories Var. Avail.","Description","  This System Result")

    pexample="st.base_dir"                                              # Variable Name
    pdesc="SADMIN Root Directory"                                       # Function Description
    presult=st.base_dir                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.bin_dir"                                               # Variable Name
    pdesc="SADMIN Scripts Directory"                                    # Function Description
    presult=st.bin_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.tmp_dir"                                               # Variable Name
    pdesc="SADMIN Temporary file(s) Directory"                          # Function Description
    presult=st.tmp_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.lib_dir"                                               # Variable Name
    pdesc="SADMIN Shell & Python Library Dir."                          # Function Description
    presult=st.lib_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.log_dir"                                               # Variable Name
    pdesc="SADMIN Script Log Directory"                                 # Function Description
    presult=st.log_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.cfg_dir"                                               # Variable Name
    pdesc="SADMIN Configuration Directory"                              # Function Description
    presult=st.cfg_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.sys_dir"                                               # Variable Name
    pdesc="Server Startup/Shutdown Script Dir."                         # Function Description
    presult=st.sys_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.doc_dir"                                               # Variable Name
    pdesc="SADMIN Documentation Directory"                              # Function Description
    presult=st.doc_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.pkg_dir"                                               # Variable Name
    pdesc="SADMIN Packages Directory"                                   # Function Description
    presult=st.pkg_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.dat_dir"                                               # Variable Name
    pdesc="Server Data Directory"                                       # Function Description
    presult=st.dat_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.nmon_dir"                                              # Variable Name
    pdesc="Server NMON - Data Collected Dir."                           # Function Description
    presult=st.nmon_dir                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.dr_dir"                                                # Variable Name
    pdesc="Server Disaster Recovery Info Dir."                          # Function Description
    presult=st.dr_dir                                                   # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.rch_dir"                                               # Variable Name
    pdesc="Server Return Code History Dir."                             # Function Description
    presult=st.rch_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.net_dir"                                               # Variable Name
    pdesc="Server Network Information Dir."                             # Function Description
    presult=st.net_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.rpt_dir"                                               # Variable Name
    pdesc="SYStem MONitor Report Directory"                             # Function Description
    presult=st.rpt_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.dbb_dir"                                               # Variable Name
    pdesc="Database Backup Directory"                                   # Function Description
    presult=st.dbb_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.setup_dir"                                             # Variable Name
    pdesc="SADMIN Setup Directory."                                     # Function Description
    presult=st.setup_dir                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.usr_dir"                                               # Variable Name
    pdesc="User/System specific directory"                              # Function Description
    presult=st.usr_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.ubin_dir"                                              # Variable Name
    pdesc="User/System specific bin/script Dir."                        # Function Description
    presult=st.ubin_dir                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.ulib_dir"                                              # Variable Name
    pdesc="User/System specific library Dir."                           # Function Description
    presult=st.ulib_dir                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.udoc_dir"                                              # Variable Name
    pdesc="User/System specific documentation"                          # Function Description
    presult=st.udoc_dir                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="st.umon_dir"                                              # Variable Name
    pdesc="User/System specific SysMon Scripts"                         # Function Description
    presult=st.umon_dir                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
 
#===================================================================================================
# Print Directories Variables Available to Users
#===================================================================================================
def print_server_directory(st):
    printheader (st,"Server Directories Var. Avail.","Description","  This System Result")

    pexample="st.www_dir"                                               # Variable Name
    pdesc="SADMIN Web Site Root Directory"                              # Function Description
    presult=st.www_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
       
    pexample="st.www_doc_dir"                                           # Variable Name
    pdesc="SADMIN Web Site Root Directory"                              # Function Description
    presult=st.www_doc_dir                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
       
    pexample="st.www_dat_dir"                                           # Variable Name
    pdesc="SADMIN Web Site Systems Data Dir."                           # Function Description
    presult=st.www_dat_dir                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
       
    pexample="st.www_lib_dir"                                           # Variable Name
    pdesc="SADMIN Web Site PHP Library Dir."                            # Function Description
    presult=st.www_lib_dir                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
           
    pexample="st.www_tmp_dir"                                           # Variable Name
    pdesc="SADMIN Web Temp Working Directory"                           # Function Description
    presult=st.www_tmp_dir                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
       
    pexample="st.www_perf_dir"                                          # Variable Name
    pdesc="Web Performance Server Graph Dir."                           # Function Description
    presult=st.www_perf_dir                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
       


#===================================================================================================
# Print Files Variables Available to Users
#===================================================================================================
def print_file_variable(st):
    printheader (st,"SADMIN FILES VARIABLES AVAIL.","Description","  This System Result")

    pexample="st.pid_file"                                              # Variable Name
    pdesc="Current script PID file"                                     # Function Description
    presult=st.pid_file                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_file"                                              # Variable Name
    pdesc="SADMIN Configuration File"                                   # Function Description
    presult=st.cfg_file                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_hidden"                                            # Name of Variable
    pdesc="SADMIN Initial Configuration File"                           # Variable Description
    presult=st.cfg_hidden                                               # Actual Content of Variable
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.alert_file"                                            # Name of Variable
    pdesc="Alert Group Definition File Name"                            # Variable Description
    presult=st.alert_file                                               # Actual Content of Variable
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.alert_init"                                            # Name of Variable
    pdesc="Alert Group Initial File (Template)"                         # Variable Description
    presult=st.alert_init                                               # Actual Content of Variable
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.alert_hist"                                            # Name of Variable
    pdesc="Alert - History File"                                        # Variable Description
    presult=st.alert_hist                                               # Actual Content of Variable
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.alert_hini"                                            # Name of Variable
    pdesc="Alert - History Initial File"                                # Variable Description
    presult=st.alert_hini                                               # Actual Content of Variable
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.tmp_file1"                                             # Variable Name
    pdesc="User usable Temp Work File 1"                                # Function Description
    presult=st.tmp_file1                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.tmp_file2"                                             # Variable Name
    pdesc="User usable Temp Work File 2"                                # Function Description
    presult=st.tmp_file2                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.tmp_file3"                                             # Name of Variable
    pdesc="User usable Temp Work File 3"                                # Function Description
    presult=st.tmp_file3                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.log_file"                                              # Name of Variable
    pdesc="Script Log File"                                             # Function Description
    presult=st.log_file                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.rch_file"                                               # Variable Name
    pdesc="Script Return Code History File"                             # Function Description
    presult=st.rch_file                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.dbpass_file"                                            # Variable Name
    pdesc="SADMIN Database User Password File"                          # Function Description
    presult=st.dbpass_file                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.rpt_file"                                               # Variable Name
    pdesc="SYStem MONitor report file"                                  # Function Description
    presult=st.rpt_file                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.backup_list"                                           # Name Of variable
    pdesc="Backup List File Name"                                       # Variable Description
    presult=st.backup_list                                              # Variable Content
    printline (st,pexample,pdesc,presult)                               # Print Variable Line
    
    pexample="st.backup_list_init"                                      # Name Of variable
    pdesc="Initial Backup List (Template)"                              # Variable Description
    presult=st.backup_list_init                                         # Variable Content
    printline (st,pexample,pdesc,presult)                               # Print Variable Line
    
    pexample="st.backup_exclude"                                        # Name Of variable
    pdesc="Backup Exclude List File Name"                               # Variable Description
    presult=st.backup_exclude                                           # Variable Content
    printline (st,pexample,pdesc,presult)                               # Print Variable Line
    
    pexample="st.backup_exclude_init"                                   # Name Of variable
    pdesc="Initial Backup Exclude (Template)"                           # Variable Description
    presult=st.backup_exclude_init                                      # Variable Content
    printline (st,pexample,pdesc,presult)                               # Print Variable Line

#===================================================================================================
# Print sadmin.cfg Variables available to users
#===================================================================================================
def print_sadmin_cfg(st):
    global show_password, show_storix, show_textbelt                    # Command line options

    printheader (st,"SADMIN CONFIG FILE VARIABLES","Description","  This System Result")

    pexample="st.cfg_server"                                            # Variable Name
    pdesc="SADMIN SERVER NAME (FQDN)"                                   # Function Description
    presult=st.cfg_server                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_host_type"                                         # Variable Name
    pdesc="SADMIN [C]lient or [S]erver"                                 # Function Description
    presult=st.cfg_host_type                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_mail_addr"                                         # Variable Name
    pdesc="SADMIN Administrator Default Email"                          # Function Description
    presult=st.cfg_mail_addr                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_alert_type"                                        # Variable Name
    pdesc="0=NoMail 1=OnError 3=OnSuccess 4=All"                        # Function Description
    presult=st.cfg_alert_type                                           # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_alert_group"                                       # Variable Name
    pdesc="Default Alert Group"                                         # Function Description
    presult=st.cfg_alert_group                                          # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_alert_repeat"                                      # Variable Name
    pdesc="Seconds to wait before repeat alert"                         # Function Description
    presult=st.cfg_alert_repeat                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_textbelt_key"                                      # Variable Name
    pdesc="TextBelt.com API Key"                                        # Function Description
    presult=""                                                          # Default Don't show Key
    if show_textbelt == "Y" : presult=st.cfg_textbelt_key               # Selected show TextBelt Key
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_textbelt_url"                                      # Variable Name
    pdesc="TextBelt.com API URL"                                        # Function Description
    presult=st.cfg_textbelt_url                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_cie_name"                                          # Variable Name
    pdesc="Your Company Name"                                           # Function Description
    presult=st.cfg_cie_name                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_domain"                                            # Variable Name
    pdesc="Server Creation Default Domain"                              # Function Description
    presult=st.cfg_domain                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_user"                                              # Variable Name
    pdesc="SADMIN User Name"                                            # Function Description
    presult=st.cfg_user                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_group"                                             # Variable Name
    pdesc="SADMIN Group Name"                                           # Function Description
    presult=st.cfg_group                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_www_user"                                          # Variable Name
    pdesc="User that Run Apache Web Server"                             # Function Description
    presult=st.cfg_www_user                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_www_group"                                         # Variable Name
    pdesc="Group that Run Apache Web Server"                            # Function Description
    presult=st.cfg_www_group                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_dbname"                                            # Variable Name
    pdesc="SADMIN Database Name"                                        # Function Description
    presult=st.cfg_dbname                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_dbhost"                                            # Variable Name
    pdesc="SADMIN Database Host"                                        # Function Description
    presult=st.cfg_dbhost                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_dbport"                                            # Variable Name
    pdesc="SADMIN Database Host TCP Port"                               # Function Description
    presult=st.cfg_dbport                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    if st.cfg_host_type == "S" :
        pexample="st.cfg_rw_dbuser"                                     # Variable Name
        pdesc="SADMIN Database Read/Write User"                         # Function Description
        presult=st.cfg_rw_dbuser                                        # Return Value(s)
        printline (st,pexample,pdesc,presult)                           # Print Example Line

        pexample="st.cfg_rw_dbpwd"                                      # Variable Name
        pdesc="SADMIN Database Read/Write User Pwd"                     # Function Description
        presult=""                                                      # Default don't show passwd
        if show_password == "Y" : presult=st.cfg_rw_dbpwd               # Selected to Show DB Passwd
        printline (st,pexample,pdesc,presult)                           # Print Example Line

        pexample="st.cfg_ro_dbuser"                                     # Variable Name
        pdesc="SADMIN Database Read Only User"                          # Function Description
        presult=st.cfg_ro_dbuser                                        # Return Value(s)
        printline (st,pexample,pdesc,presult)                           # Print Example Line

        pexample="st.cfg_ro_dbpwd"                                      # Variable Name
        pdesc="SADMIN Database Read Only User Pwd"                      # Function Description
        presult=""                                                      # Default don't show passwd
        if show_password == "Y" : presult=st.cfg_ro_dbpwd               # Selected to Show DB Passwd
        printline (st,pexample,pdesc,presult)                           # Print Example Line

    pexample="st.cfg_rrdtool"                                           # Variable Name
    pdesc="RRDTOOL Binary Location"                                     # Function Description
    presult=st.cfg_rrdtool                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_ssh_port"                                          # Variable Name
    pdesc="SSH Port to communicate with client"                         # Function Description
    presult=st.cfg_ssh_port                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_nmon_keepdays"                                     # Variable Name
    pdesc="Nb. of days to keep nmon perf. file"                         # Function Description
    presult=st.cfg_nmon_keepdays                                        # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_rch_keepdays"                                      # Variable Name
    pdesc="Nb. days to keep unmodified rch file"                        # Function Description
    presult=st.cfg_rch_keepdays                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_log_keepdays"                                      # Variable Name
    pdesc="Nb. days to keep unmodified log file"                        # Function Description
    presult=st.cfg_log_keepdays                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_max_rchline"                                       # Variable Name
    pdesc="Trim rch file to this max. of lines"                         # Function Description
    presult=st.cfg_max_rchline                                          # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_max_logline"                                       # Variable Name
    pdesc="Trim log to this maximum of lines"                           # Function Description
    presult=st.cfg_max_logline                                          # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_network1"                                          # Variable Name
    pdesc="Network/Netmask 1 inv. IP/Name/Mac"                          # Function Description
    presult=st.cfg_network1                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_network2"                                          # Variable Name
    pdesc="Network/Netmask 2 inv. IP/Name/Mac"                          # Function Description
    presult=st.cfg_network2                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_network3"                                          # Variable Name
    pdesc="Network/Netmask 3 inv. IP/Name/Mac"                          # Function Description
    presult=st.cfg_network3                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_network4"                                          # Variable Name
    pdesc="Network/Netmask 4 inv. IP/Name/Mac"                          # Function Description
    presult=st.cfg_network4                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_network5"                                          # Variable Name
    pdesc="Network/Netmask 5 inv. IP/Name/Mac"                          # Function Description
    presult=st.cfg_network5                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_mksysb_nfs_server"                                 # Variable Name
    pdesc="AIX MKSYSB NFS Server IP or Name"                            # Function Description
    presult=st.cfg_mksysb_nfs_server                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_mksysb_nfs_mount_point"                            # Variable Name
    pdesc="AIX MKSYSB NFS Mount Point"                                  # Function Description
    presult=st.cfg_mksysb_nfs_mount_point                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_mksysb_backup_to_keep"                             # Variable Name
    pdesc="AIX MKSYSB NFS Backup - Nb .to keep"                         # Function Description
    presult=st.cfg_mksysb_backup_to_keep                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_rear_nfs_server"                                   # Variable Name
    pdesc="Rear NFS Server IP or Name"                                  # Function Description
    presult=st.cfg_rear_nfs_server                                      # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_rear_nfs_mount_point"                              # Variable Name
    pdesc="Rear NFS Mount Point"                                        # Function Description
    presult=st.cfg_rear_nfs_mount_point                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_rear_backup_to_keep"                               # Variable Name
    pdesc="Rear NFS Backup - Nb. to keep"                               # Function Description
    presult=st.cfg_rear_backup_to_keep                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_backup_nfs_server"                                 # Variable Name
    pdesc="NFS Backup IP or Server Name"                                # Function Description
    presult=st.cfg_backup_nfs_server                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_backup_nfs_mount_point"                            # Variable Name
    pdesc="NFS Backup Mount Point"                                      # Function Description
    presult=st.cfg_backup_nfs_mount_point                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_daily_backup_to_keep"                              # Variable Name
    pdesc="Daily Backup to Keep"                                        # Function Description
    presult=st.cfg_daily_backup_to_keep                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_weekly_backup_to_keep"                             # Variable Name
    pdesc="Weekly Backup to Keep"                                       # Function Description
    presult=st.cfg_weekly_backup_to_keep                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_monthly_backup_to_keep"                            # Variable Name
    pdesc="Monthly Backup to Keep"                                      # Function Description
    presult=st.cfg_monthly_backup_to_keep                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_yearly_backup_to_keep"                             # Variable Name
    pdesc="Yearly Backup to keep"                                       # Function Description
    presult=st.cfg_yearly_backup_to_keep                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_weekly_backup_day"                                 # Variable Name
    pdesc="Weekly Backup Day (1=Mon,7=Sun)"                             # Function Description
    presult=st.cfg_weekly_backup_day                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_monthly_backup_date"                               # Variable Name
    pdesc="Monthly Backup Date (1-28)"                                  # Function Description
    presult=st.cfg_monthly_backup_date                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_yearly_backup_month"                               # Variable Name
    pdesc="Yearly Backup Month (1-12)"                                  # Function Description
    presult=st.cfg_yearly_backup_month                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="st.cfg_yearly_backup_date"                                # Variable Name
    pdesc="Yearly Backup Date (1-31)"                                   # Function Description
    presult=st.cfg_yearly_backup_date                                   # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    if show_storix == "Y" :                                             # Selected Show Storix Info
        pexample="st.cfg_storix_nfs_server"                             # Variable Name
        pdesc="Storix NFS Server IP or Name"                            # Function Description
        presult=st.cfg_storix_nfs_server                                # Return Value(s)
        printline (st,pexample,pdesc,presult)                           # Print Example Line

        pexample="st.cfg_storix_mount_point"                            # Variable Name
        pdesc="Storix NFS Mount Point"                                  # Function Description
        presult=st.cfg_storix_mount_point                               # Return Value(s)
        printline (st,pexample,pdesc,presult)                           # Print Example Line

        pexample="st.cfg_storix_backup_to_keep"                         # Variable Name
        pdesc="Storix NFS Backup - Nb. to Keep"                         # Function Description
        presult=st.cfg_storix_backup_to_keep                            # Return Value(s)
        printline (st,pexample,pdesc,presult)                           # Print Example Line


#===================================================================================================
# Print Command Path Variables available to users
#===================================================================================================
def print_command_path(st):
    
    printheader (st,"COMMAND PATH USE BY SADMIN STD. LIBR.","Description","  This System Result")

  
    pexample="st.dmidecode"                                             # Variable Name
    pdesc="Cmd. 'dmidecode', Get model & type"                          # Variable Description
    presult=st.dmidecode                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.bc"                                                    # Variable Name
    pdesc="Cmd. 'bc', Do some Math."                                    # Variable Description
    presult=st.bc                                                       # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.fdisk"                                                 # Variable Name
    pdesc="Cmd. 'fdisk', Get Partition Info"                            # Variable Description
    presult=st.fdisk                                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.which"                                                 # Variable Name
    pdesc="Cmd. 'which', Get Command location"                          # Variable Description
    presult=st.which                                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.perl"                                                  # Variable Name
    pdesc="Cmd. 'perl', epoch time Calc."                               # Variable Description
    presult=st.perl                                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.mail"                                                  # Variable Name
    pdesc="Cmd. 'mail', Send SysAdmin Email"                            # Variable Description
    presult=st.mail                                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.mutt"                                                  # Variable Name
    pdesc="Cmd. 'mutt', Used to Send Email"                             # Variable Description
    presult=st.mutt                                                     # Variable Content
    printline (st,pexample,pdesc,presult)                               # Print Variable Line
    
    pexample="st.curl"                                                  # Variable Name
    pdesc="Cmd. 'curl', To send alert to Slack"                         # Variable Description
    presult=st.curl                                                     # Variable Content
    printline (st,pexample,pdesc,presult)                               # Print Variable Line

    pexample="st.lscpu"                                                 # Variable Name
    pdesc="Cmd. 'lscpu', Socket & thread info"                          # Variable Description
    presult=st.lscpu                                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.nmon"                                                  # Variable Name
    pdesc="Cmd. 'nmon', Collect Perf Statistic"                         # Variable Description
    presult=st.nmon                                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.parted"                                                # Variable Name
    pdesc="Cmd. 'parted', Get Disk Real Size"                           # Variable Description
    presult=st.parted                                                   # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.ethtool"                                               # Variable Name
    pdesc="Cmd. 'ethtool', Get System IP Info"                          # Variable Description
    presult=st.ethtool                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.ssh"                                                   # Variable Name
    pdesc="Cmd. 'ssh', SSH to SADMIN client"                            # Variable Description
    presult=st.ssh                                                      # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="st.ssh_cmd"                                               # Variable Name
    pdesc="Cmd. 'ssh', SSH to Connect to client"                        # Variable Description
    presult=st.ssh_cmd                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    

#===================================================================================================
# Print sadm_start and sadm_stop Function Used by SADMIN Tools
#===================================================================================================
def print_start_stop(st):
    printheader (st,"Overview of setup_admin(), st.start() & st.stop() functions"," "," ")
     
    print ("") 
    print ("Extract of SADMIN Section") 
    print ("def setup_sadmin():") 
    print ("    # Create SADMIN Tools Instance (Create Directories,Load sadmin.cfg,Assign Variables)") 
    print ("    st = sadm.sadmtools()      ") 
    print ("    # Start SADMIN Tools - Initialize SADMIN Env. (Create dir.,Log,RCH, Open DB..)") 
    print ("    st.start()                                  # Init. ") 
    print ("") 
    print ("- The function 'setup_sadmin()', need to be called  when your script is starting.") 
    print ("    1) It make sure the SADMIN environment variable is set to the proper directory.") 
    print ("    2) Setup global variables, load modules, create instance.") 
    print ("    3) Load SADMIN configuration file ($SADMIN/cfg/sadmin.cfg).") 
    print ("    4) Check Library requirements") 
    print ("    5) Call the 'st.start()' function below.") 
    print ("    6) And finally it return an object of the instance.") 
    print ("") 
    print ("- Function 'st.start()' (Included in the 'setup_sadmin()')") 
    print ("  What this function does:") 
    print ("    1) Make sure all directories & sub-directories exist and have proper permissions.") 
    print ("    2) Make sure log file exist with proper permission (st.log_file)") 
    print ("       Write the log header (if 'st.log_header = True').") 
    print ("    3) Record the start Date/Time and Status Code 2(Running) to RCH file.") 
    print ("    4) If PID file exist, show error message and abort.") 
    print ("       Unless user allow more than one copy to run simultaneously (st.multiple_exec = 'Y').") 
    print ("    5) Add line in the [R]eturn [C]ode [H]istory file stating script is started (Code 2).") 
    print ("") 
    print ("- Function 'st.stop()'") 
    print ("  This function should be called near the end of your script.") 
    print ("    Example : st.stop(st.exit_code)   # Close SADMIN Environment") 
    print ("              sys.exit(st.exit_code)  # Exit To O/S") 
    print ("  It accept one parameter - Either 0 (Successful) or non-zero (Error Encountered).") 
    print ("  What this function does:") 
    print ("    1) Get Actual Time and Calculate the Execution Time.") 
    print ("    2) It check if the Exit Code is not zero, change it to 1.") 
    print ("    3) If 'st.log_footer = True', write the log footer.") 
    print ("    4) If 'st.use_rch = True', append (Start/End/Elapse Time ...) in RCH File.") 
    print ("    5) Trim The RCH File according to user choice in sadmin.cfg (SADM_MAX_RCHLINE).") 
    print ("    6) Trim the log according to user choice in sadmin.cfg (SADM_MAX_LOGLINE).") 
    print ("    7) Delete the PID File of the script (st.pid_file).") 
    print ("    8) Delete the user 3 TMP Files (st.tmp_file1, st.tmp_file2, st.tmp_file3).") 
    print (" ")


#===================================================================================================
# Show Environment Variables Defined
#===================================================================================================
def print_env(st):
    printheader (st,"Environment Variables.","Description","  This System Result")
    for a in os.environ:
        pexample=a                                                          # Env. Var. Name
        pdesc="Env.Var. %s" % (a)                                           # Env. Var. Name
        presult=os.getenv(a)                                                # Return Value(s)
        printline (st,pexample,pdesc,presult)                               # Print Env. Line


#===================================================================================================
# Print Database Information
#===================================================================================================
def print_db_variables(st):
    printheader (st,"Database Information","Description","  This System Result")
         
    pexample="st.dbsilent"                                              # Variable Name
    pdesc="When DBerror, No ErrMsg (Just ErrNo)"                        # Function Description
    presult=st.dbsilent                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="st.usedb"                                                 # Variable Name
    pdesc="Script need (Open/Close) Database ?"                         # Function Description
    presult=st.usedb                                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    # Test Database Connection
    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database
        st.writelog ("Database connection succeeded")                   # Show COnnect to DB Worked
        
        print ("\n\nShow SADMIN Tables:")
        sql="show tables;" 
        cmd =  "mysql -t -u%s -p%s -h%s" % (st.cfg_ro_dbuser, st.cfg_ro_dbpwd, st.cfg_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, st.cfg_dbname, sql)
        (returncode,stdout,stderr)=st.oscommand(cmd)
        print (stdout);

        print ("\n\nCategory Table:")
        sql="describe server_category; "                                    # Show Table Format/colums
        cmd =  "mysql -t -u%s -p%s -h%s" % (st.cfg_ro_dbuser, st.cfg_ro_dbpwd, st.cfg_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, st.cfg_dbname, sql)
        (returncode,stdout,stderr)=st.oscommand(cmd)
        print (stdout);
        sql="select * from server_category; "                              # Show Table Format/columns
        cmd =  "mysql -t -u%s -p%s -h%s" % (st.cfg_ro_dbuser, st.cfg_ro_dbpwd, st.cfg_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, st.cfg_dbname, sql)
        (returncode,stdout,stderr)=st.oscommand(cmd)
        print (stdout);

        print ("\n\nGroup Table:")
        sql="show columns from server_group; "                              # Show Table Format/columns
        cmd =  "mysql -t -u%s -p%s -h%s" % (st.cfg_ro_dbuser, st.cfg_ro_dbpwd, st.cfg_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, st.cfg_dbname, sql)
        (returncode,stdout,stderr)=st.oscommand(cmd)
        print (stdout);
        sql="select * from server_group; "                              # Show Table Format/columns
        cmd =  "mysql -t -u%s -p%s -h%s" % (st.cfg_ro_dbuser, st.cfg_ro_dbpwd, st.cfg_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, st.cfg_dbname, sql)
        (returncode,stdout,stderr)=st.oscommand(cmd)
        print (stdout);

        print ("\n\nServer Table:")
        sql="describe server; "
        cmd =  "mysql -t -u%s -p%s -h%s" % (st.cfg_ro_dbuser, st.cfg_ro_dbpwd, st.cfg_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, st.cfg_dbname, sql)
        (returncode,stdout,stderr)=st.oscommand(cmd)
        print (stdout);

        st.writelog ("Closing Database connection")                     # Show we are closing DB
        st.dbclose()                                                    # Close the Database
        st.writelog (" ")                                               # Blank Line




# Command line Options
# --------------------------------------------------------------------------------------------------
def cmd_options(argv):
    """ Command line Options functions - Evaluate Command Line Switch Options

        Args:
            (argv): Arguments pass on the comand line.
              [-d 0-9]  Set Debug (verbose) Level
              [-h]      Show this help message
              [-v]      Show script version information
        Returns:
            sadm_debug (int)          : Set to the debug level [0-9] (Default is 0)
    """
    
    # Evaluate Command Line Switch Options Upfront
    # By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level     

    try:
        opts, args = getopt.getopt(argv,"hptsvd:",["debug=","help","version","storix","textbelt","password"])
    except getopt.GetoptError as err:                                   # If Invalid Option or Error
        print (str(err))                                                # Show option not recognized     
        show_usage()                                                    # Show Command line Usage
        st.stop (2)                                                     # Close log,db,...,Trim Log
        sys.exit(2)                                                     # Exit with Error Code 2
    for opt, arg in opts:
        if opt in ("-h","--help"):                                      # 'help' Command line option
            show_usage()                                                # Show Command Line Usage
            st.stop (0)                                                 # Close log,db,...,Trim Log
            sys.exit(0)                                                 # Exit Script with no Error
        elif opt in ("-d","--debug"):                                   # 'debug' Cmd. line option
            st.debug = int(arg)                                         # Save Debug Level chosen
        elif opt in ("-p","--password"):                                # 'password' Cmdline option
            show_password = "Y"                                         # Show Database Password
        elif opt in ("-t","--textbelt"):                                # 'textbelt' Cmdline option
            show_textbelt="Y"                                           # Show TextBelt API Key
            print ("textbelt selected")
        elif opt in ("-s","--storix"):                                  # 'storix' Cmdline option
            show_storix="Y"                                             # Show Storix NFS Backup 
        elif opt in ("-v","--version"):                                 # 'version' Cmd. line option
            st.show_version()                                           # Show Script,Lib,Kernel Ver
            st.stop (0)                                                 # Close log,db,...,Trim Log
            sys.exit(0)                                                 # Exit Script with no Error
    if st.debug > 0 : st.writelog("Debug Level %d activated" % (st.debug)) # Debug: Show debug level

    sadm_debug = 0                                                      # Script Debug Level (0-9)
    parser = argparse.ArgumentParser(description=pdesc)                 # Desc. is the script name

    # Declare Arguments
    parser.add_argument("-v",
                        action="store_true",
                        dest='version',
                        help="Show script version")
    parser.add_argument("-d",
                        metavar="0-9",
                        type=int,
                        dest='sadm_debug',
                        help="debug/verbose level from 0 to 9",
                        default=0)
    
    args = parser.parse_args()                                          # Parse the Arguments

    # Set return values accordingly.
    if args.sadm_debug:                                                 # Debug Level -d specified
        sadm_debug = args.sadm_debug                                    # Save Debug Level
        print("Debug Level is now set at %d" % (sadm_debug))            # Show user debug Level
    if args.version:                                                    # If -v specified
        sa.show_version(pver)                                           # Show Custom Show Version
        sys.exit(0)                                                     # Exit with code 0
    return(sadm_debug)                                                  # Return opt values


#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main(argv):
    global show_password,show_storix,show_textbelt,pdb_conn,pdb_cur     # Command line options
    (pdebug) = cmd_options(argv)                                        # Analyse cmdline options

    # If you need this script to be run by 'root' only (If not remove the if))
    if not os.getuid() == 0:                                            # UID of user is not 'root'
        print("This script must be run by the 'root' user.")            # Advise User Message / Log
        print("Try 'sudo %s'" % (os.path.basename(sys.argv[0])))        # Suggest to use 'sudo'
        print("Process aborted.")                                       # Process Aborted Msg
        sys.exit(1)                                                     # Exit with Error Code

    # If you need this script to run only on the SADMIN server, uncomment lines below.
    # if sa.get_fqdn() != sa.sadm_server:                                # Only run on SADMIN
    #    print("This script can only be run on SADMIN server (%s)" % (sa.sadm_server))
    #    print("Process aborted")                                        # Abort advise message
    #    sys.exit(1)                                                     # Exit To O/S

    pexit_code = 0                                                      # Pgm Exit Code Default
    sa.start(pver, pdesc)                                               # Initialize SADMIN env.


    # Print All Demo Informations
    print_user_variables(st)                                            # Show User Avail. Variables
    print_functions(st)                                                 # Display Env. Variables
    print_python_function(st)                                           # Show Python Specific func.
    print_start_stop(st)                                                # Show Stop/Start Function
    print_sadmin_cfg(st)                                                # Show sadmin.cfg Variables
    print_client_directory(st)                                          # Show Client Dir. Variables
    print_server_directory(st)                                          # Show Server Dir. Variables
    print_file_variable(st)                                             # Show Files Variables
    print_command_path(st)                                              # Show Command Path
    if ((st.get_fqdn() == st.cfg_server) and (st.cfg_host_type == "S")): # Only on SADMIN & Use DB
        print_db_variables(st)                                          # Show Database Information
    #print_env(st)                                                      # Show Env. Variables
    st.stop(st.exit_code)                                               # Close SADM Environment
    sys.exit(st.exit_code)                                              # Exit To O/S

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv[1:])


