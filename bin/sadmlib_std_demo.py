#!/usr/bin/env python3
#===================================================================================================
#   Author:     : Jacques Duplessis
#   Title:      : sadmlib_std_demo.py
#   Version     : 1.0
#   Date        : 14 July 2017
#   Requires    : python3 and SADM Library
#   Description : Demonstrate functions & variables available to developers using SADMIN Tools
# 
#    2016-2018 Jacques Duplessis <sadmlinux@gmail.com> - https://sadmin.ca
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
#   If not, see <https://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2017_07_07 lib v1.7 Minor Code enhancement
# 2017_07_31 lib v1.8 Added Log Template to script
# 2017_09_02 lib v1.9 Add Command line switch 
# 2017_09_02 lib v2.0 Rewritten Part of script for performance and flexibDemonstrate functions & variables available to developers using SADMIN Toolsility
# 2017_12_12 lib v2.1 Adapted to use MySQL instead of Postgres Database
# 2017_12_23 lib v2.3 Changes for performance and flexibility
# 2018_01_25 lib v2.4 Added Variable SADM_RRDTOOL to sadmin.cfg display
# 2018_02_21 lib v2.5 Minor Changes 
# 2018_05_26 lib v2.6 Major Rewrite, Better Performance
# 2018_05_28 lib v2.7 Add Backup Parameters now in sadmin.cfg
# 2018_06_04 lib v2.8 Added User Directory Environment Variables in SADMIN Client Section
# 2018_06_05 lib v2.9 Added setup, www/tmp/perf Directory Environment Variables 
# 2018_12_03 lib v3.0 Remove dot before and after the result column and minor changes.
# 2019_01_19 lib v3.1 Added: Added Backup List & Backup Exclude File Name available to User.
# 2019_01_28 lib v3.2 Database info only show when running on SADMIN Server
# 2019_03_18 lib v3.3 Add demo call to function get_packagetype()
# 2019_04_07 lib v3.4 Don't show Database user name if run on client.
# 2019_04_25 lib v3.5 Add Alert_Repeat, Textbelt API Key and URL Variable in Output
# 2019_05_17 lib v3.6 Add option -p(Show DB password),-s(Show Storix Info),-t(Show TextBeltKey)
# 2019_08_19 lib v3.7 Remove printing of sa.alert_seq (not used anymore)
# 2019_10_14 lib v3.8 Add demo for calling sadm_server_arch function & show result.
# 2019_10_18 lib v3.9 Print SADMIN Database Tables and columns at the end of report.
# 2019_10_30 lib v3.10 Remove Utilization of 'facter' (Depreciated).
# 2022_04_09 lib v3.11 Rewrote Overview of the 'sa.start()' and 'sa.stop()' functions.
# 2022_04_10 lib v3.12 Remove 'lsb_release' command dependency (Not avail in RHEL 9)
# 2022_05_15 lib v3.13 Updated to use the new SADMIN Python Library V2.
# 2022_05_18 lib v3.14 Added print of new fields 'sa.sadm_pid_timeout' & 'sa.sadm_lock_timeout'.
# 2022_05_21 lib v3.15 Late Adjustment & Minor changes
# 2022_05_25 lib v3.16 Added fields 'sa.proot_only' & 'sa.psadm_server_only' to output.
# 2022_08_14 lib v3.17 Output updated with all the latest functions & global variables.
# 2023_04_13 lib v3.18 Add 'sadm_rear_dif', 'sadm_rear_interval', 'sadm_backup_interval' to output.
# 2023_04_14 lib v3.19 SADMIN server email account pwd now taken from $SADMIN/cfg/.gmpw.
# 2023_04_14 lib v3.20 SADMIN client email account pwd now taken from encrypted $SADMIN/cfg/.gmpw64. 
# 2023_08_19 lib v3.21 start() function auto connect to DB, if on SADMIN server & db_used=True.
# 2023_12_19 lib v3.22 Fix minor problem
#@2024_05_10 lib v3.23 Add VM export parameters and alert history/archive purge days limit.
#@2024_12_17 lib v3.24 Add new global variable 'sadm_pwd_random' to auto-generate 'sadmin user' pwd.
#@2026_03_06 lib v3.25 Show Database info only on the SADMIN server.
#@2026_05_20 lib v3.26.1 New Variables and functions available.
#@2026_05_30 lib v3.27.0 Complete revision of the demo script to show all the latest functions & Variables.
# ==================================================================================================
#
try :
    import os, time, sys, pdb, socket, pdb, datetime, glob, argparse, pymysql, platform
except ImportError as e:                                            
    print ("Import Error : %s " % e)
    sys.exit(1)

#pdb.set_trace()                                                    # Activate Python Debugging





# --------------------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.56
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your Python code.    
# --------------------------------------------------------------------------------------------------
try:
    SADM = os.environ['SADMIN']                                      # Get SADMIN Env. Variable
except KeyError as e:                                                # If SADMIN is not define
    print("Environment variable 'SADMIN' is not defined.\n%s\nScript aborted.\n" % e) 
    sys.exit(1)                                                      # Go Back to O/S with Error

try: 
    sys.path.insert(0, os.path.join(SADM, 'lib'))                    # Add lib dir to sys.path
    import sadmlib2_std as sa                                        # Import SADMIN Python Library
except ImportError as e:                                             # If Error importing SADMIN
    print("Import error : SADMIN module: %s " % e)                   # Advise User of Error
    print("Please make sure the 'SADMIN' environment variable is defined,\nScript aborted.\n.")
    sys.exit(1)                                                      # Go Back to O/S with Error

# Local variables local to this script.
sa.ver               = "3.27.0"                                      # Program version no.
sa.desc              = "Demo of functions & variables available to developers using SADMIN Tools"
sa.pn                = os.path.basename(sys.argv[0])                 # Script name with extension
sa.inst              = sa.pn.split('.')[0]                           # Pgm name without Ext
sa.hostname          = sa.get_hostname()                             # Get current `hostname -s`
sa.proot_only        = False      # True = Script can only be run by 'root' user only else 'N'.
sa.server_only       = False      # True = Script can only be run on SADMIN server else 'N'.
sa.debug             = 0          # Debug level from 0 to 9
sa.exit_code         = 0          # Script default exit code
sa.quiet             = False      # If Error in a function & quiet is 
                                  # False: Show error message & return Error No.
                                  # True : Only return Error No, but No Error Message is shown.
sa.use_rch           = False      # Generate entry in [R]esult [C]ode [H]istory file (.rch)
sa.log_type          = 'B'        # Output goes to [S]creen, [L]ogFile or [B]oth
sa.log_append        = False      # Append Existing Log (True) or Create New Log (False)
sa.log_header        = True       # Show/Generate Header in script log (.log)
sa.log_footer        = True       # Show/Generate Footer in script log (.log)
sa.multiple_exec     = "N"        # Allow multiple copy to run at same time 'Y' else 'N'.
sa.cmd_ssh_full = "%s -qnp %s -o ConnectTimeout=2 -o ConnectionAttempts=2 " % (sa.cmd_ssh,sa.sadm_ssh_port)

# Fields used by sa.start(),sa.stop() & DB functions that influence execution of SADMIN library
sa.db_used           = True       # Open/Use DB(True), No DB needed (False), sa.start() auto connect
sa.db_conn           = None       # Database Connector (if used sa.db_used=True)
sa.db_cur            = None       # Database Cursor (if used sa.db_used=True)
sa.db_name           = "sadmin"   # Database Name default to name define in $SADMIN/cfg/sadmin.cfg
sa.db_errno          = 0          # Database Error Number
sa.db_errmsg         = ""         # Database Error Message
#

# The values of fields below, are loaded from sadmin.cfg when you import the SADMIN library.
# Change them to fit your need, they are use by start() & stop() functions of SADMIN Python Libr.
#
#sa.sadm_alert_type  = 1          # 0=NoAlert 1=AlertOnlyOnError 2=AlertOnlyOnSuccess 3=AlwaysAlert
#sa.sadm_alert_group = "default"  # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
#sa.max_logline      = 500        # Max. lines to keep in log (0=No trim) after execution.
#sa.max_rchline      = 40         # Max. lines to keep in rch (0=No trim) after execution.
#sa.sadm_mail_addr   = ""         # All mail goes to this email (Default is in sadmin.cfg)
#sa.pid_timeout      = 7200       # Default Time to Live in seconds for the PID File
#sa.lock_timeout     = 3600       # A host can be lock for this number of seconds, auto unlock after
# ==================================================================================================



# Local Variables used by this script
# --------------------------------------------------------------------------------------------------
lcount              = 0                                                 # Print Line Counter
show_password       = False                                             # Show DB Password
col1_width          = 30 
col2_width          = 40 
col3_width          = 10 




# Standardize Print Line Function 
#===================================================================================================
def printline(col1="",col2="",col3=""):
    global lcount                                                       # Global line counter

    lcount += 1                                                         # Increase line counter
    print ("[%03d] " % lcount, end='')                                  # Print line counter
    print ("%-36s" % (col1), end='')                                    # If col1 not empty print it
    print ("%-40s" % (col2), end='')                                    # If col2 not empty print it
    print ("%-24s" % (col3))                                            # If col3 not empty print it





# Standardize Print Header Function 
#===================================================================================================
def printheader(col1="",col2="",col3=""):
    global lcount                                                       # Global Line Counter

    lcount = 0                                                          # Reset line counter for section    
    print ("\n\n\n%s" % ("-" * 100))                                    # Print line of 100 "-" 
    if (col2 == "") : 
        print ("%-81s%s" % (col1,col3))                                 # Print Header line
    else: 
        print ("%-35s%-39s%-25s" % (col1,col2,col3))                    # Print Header line
    print ("%s" % ("-" * 100))                                          # Print line of 100 "-" 
    return 0



# Standardize Section name 
#===================================================================================================
def print_section_name(section_name: str):
    print ("\n%s\n" % section_name )





# Print SADMIN Function available to Users
#===================================================================================================
def print_functions():

    printheader ("Functions in SADMIN Python Library you can use ","","Results")
    
    printline ("sa.get_release()","SADMIN Release Number (XX.XX)",sa.get_release())
    printline ("sa.get_ostype()","OS Type (Always in uppercase,LINUX,AIX)",sa.get_ostype()) 
    printline ("sa.get_osversion()","Return O/S Version (Ex: 7.2, 6.5)",sa.get_osversion())  
    printline ("sa.get_osmajorversion()","Return O/S Major Version (Ex 7, 6)",sa.get_osmajorversion())
    printline ("sa.get_osminorversion()","Return O/S Minor Version (Ex 2, 3)",sa.get_osminorversion())
    printline ("sa.get_osname()","O/S Distribution (Always in uppercase)",sa.get_osname())
    printline ("sa.get_oscodename()","O/S Project Code Name",sa.get_oscodename())
    printline ("sa.get_kernel_version()","O/S Running Kernel Version",sa.get_kernel_version())
    printline ("sa.get_kernel_bitmode()","O/S Kernel Bit Mode (32 or 64)",sa.get_kernel_bitmode()) 
    printline ("sa.phostname","Host Name",sa.hostname)
    printline ("sa.get_host_ip()","Current Host IP Address",sa.get_host_ip())
    printline ("sa.get_domainname()","Current Host Domain Name",sa.get_domainname()) 
    printline ("sa.get_fqdn()","Fully Qualified Domain Host Name",sa.get_fqdn())
    printline ("sa.get_serial()","Get System serial Number",sa.get_serial())
    wepoch=sa.get_epoch_time()
    printline ("sa.get_epoch_time()","Get Current Epoch Time",sa.get_epoch_time())
    printline ("sa.epoch_to_date(%d)" % (wepoch),"Convert epoch time to date",sa.epoch_to_date(wepoch))
    wsdate=sa.epoch_to_date(wepoch) 
    printline ("sa.date_to_epoch(wsdate)", "Convert Date to epoch time", sa.date_to_epoch(wsdate) )

    DATE1="2026.06.30 10:00:44" ; DATE2="2026.06.30 09:50:03"           # Set Date to Calc Elapse
    print ("      DATE1 (End): %s" % (DATE1), "   DATE2 (Start): %s" % (DATE2)) # Print Date2 Used for Ex.
    pexample="sa.elapse_time(DATE1,DATE2)"                              # Example Calling Function
    pdesc="Elapse Time between two timestamps"                          # Function Description
    presult=sa.elapse_time(DATE1,DATE2)                                 # Return Value(s)
    printline ("sa.elapse_time(DATE1,DATE2)","Elapse Time between two timestamps",presult) 

    printline ("sa.get_packagetype()","Get package type (rpm,deb,aix,dmg)",sa.get_packagetype())
    printline ("sa.get_arch()","Get system architecture",sa.get_arch())
    printline ("sa.lock_system(hostname)","Lock the specified hostname (Not FQDN)",sa.lock_system(sa.sadm_server,errmsg=False)) 
    printline ("sa.lock_status(hostname)","Check if host specified is lock",sa.lock_status(sa.sadm_server,errmsg=False)) 
    printline ("sa.unlock_system(hostname)","Unlock host specified, monitoring on",sa.unlock_system(sa.sadm_server))
    printline ("sa.lock_status(hostname)","Check if host specified is lock",sa.lock_status(sa.sadm_server,errmsg=False)) 
    printline ("sa.write_log('message'[,lf=true])","Write message to Screen,Log or Both","message")
    printline ("sa.write_err('message'[,lf=true])","Write message to Error and std","message")
    printline ("sa.sendmail(mail,sub,body,att)","sadm_sendmail(email,\"subject\",\"body\",\"file1,file2\")","")
    printline ("sa.show_version(sa.ver)","Used by -v cmdline to show script info","Ver.+Desc.+LibrVer")
    printline ("sa.sleep(60,15)","Sleep 60 sec & update every 15 sec.","60...45...30...15...0") 
    printline ("sa.trimfile(filename,nlines=500)","Keep last 500 lines of filename.","0=Success  1=Error") 
    #wip=sa.get_host_ip()
    #printline ("sa.get_mac_address(wip)","Get MAC address of the system", sa.get_mac_address(wip))
    printline ("sa.get_nb_cpu","Get number of CPUs",sa.get_nb_cpu())
    printline ("sa.get_nb_core_per_socket()","Get number of core per socket",sa.get_nb_core_per_socket())
    printline ("sa.get_nb_thread_per_core()","Get number of threads per core",sa.get_nb_thread_per_core())
    printline ("sa.get_nb_socket()","Get number of socket",sa.get_nb_socket())
    printline ("sa.silentremove('file')","Silent file delete (no msg, no err)",sa.silentremove('file'))
    printline ("sa.touch_file('filename')","Create an empty file","0=File created 1=Error")

    return 0 




#===================================================================================================
# Print SADMIN Function available to Users
#===================================================================================================
def print_python_function():

    printline ("sa.db_connect('sadmin')","Open connection to database","0=Success 1=Error") 
    printline ("sa.db_close()","Close connection to database","0=Success, 1=Error")
    printline ("sa.db_used","Access to the SADMIN Database ?",sa.db_used)
    return 0 






# Print User Variables that affect SADMIN Tools Behavior
#===================================================================================================
def print_user_variables():

    print ("\n\n\n%s" % ("-" * 100))                                    # Print line of 100 "-" 
    print ("Variables you can change in SADMIN Code Section that influence library behavior")
    print ("  - We recommend, to set these variables prior to calling 'sa.sadm_start()'.")
    print ("%s" % ("-" * 100))                                          # Print line of 100 "-" 

    printline ("sa.ver","Pgm. version number",sa.ver)
    printline ("sa.desc",sa.desc)  
    printline ("sa.pn","Pgm. name with extension",sa.pn)  
    printline ("sa.inst","Pgm name without extension",sa.inst)
    printline ("sa.root_only","Pgm. can only be run by 'root'",sa.root_only)
    printline ("sa.server_only","Pgm can only be run on SADMIN server",sa.server_only)
    printline ("sa.multiple_exec","Can run or not simultaneous execution",sa.multiple_exec)
    printline ("sa.use_rch","Save execution data to '.rch' file",sa.use_rch) 
    printline ("sa.debug","Program Debug Level",sa.debug)  
    printline ("sa.username","Current user name",sa.username)
    printline ("sa.pid","Current Process ID",sa.pid)
    printline ("sa.quiet","Quiet False=ErrNo+Mess True=OnlyErrNo",sa.quiet)  
    printline ("sa.exit_code","Script Exit Return Code",sa.exit_code)
    printline ("sa.log_type","Set Output to [S]creen [L]og [B]oth",sa.log_type)
    printline ("sa.log_append","Append to log(True), New log=(False)",sa.log_append)
    printline ("sa.log_header","Generate header in log",sa.log_header)
    printline ("sa.log_footer","Generate footer in log",sa.log_footer)
    printline ("sa.sadm_alert_type","0=NoMail 1=OnError 3=OnSuccess 4=All",sa.sadm_alert_type)
    return(0)


#===================================================================================================
# Print Directories Variables Available to Users
#===================================================================================================
def print_directories():

    printheader ("Directories Variables Available to Developper","","Results")

    # Sadmin Directories Aliases Variables.
    printline ("sa.dir_base","SADMIN Root Directory",sa.dir_base)
    printline ("sa.dir_bin","SADMIN Scripts Directory",sa.dir_bin)
    printline ("sa.dir_tmp","SADMIN Temporary file(s) Directory",sa.dir_tmp) 
    printline ("sa.dir_lib","SADMIN Shell & Python Library Dir.",sa.dir_lib)
    printline ("sa.dir_log","SADMIN Script Log Directory",sa.dir_log)       
    printline ("sa.dir_cfg","SADMIN Configuration Directory",sa.dir_cfg)   
    printline ("sa.dir_sys","Server Startup/Shutdown Script Dir.",sa.dir_sys) 
    printline ("sa.dir_doc","SADMIN Documentation Directory",sa.dir_doc) 
    printline ("sa.dir_pkg","SADMIN Packages Directory",sa.dir_pkg)                   
    printline ("sa.dir_dat","Server Data Directory",sa.dir_dat)                       
    printline ("sa.dir_nmon","Server NMON - Data Collected Dir.",sa.dir_nmon)         
    printline ("sa.dir_dr","Server Disaster Recovery Info Dir.",sa.dir_dr)            
    printline ("sa.dir_rch","Server Return Code History Dir.",sa.dir_rch)             
    printline ("sa.dir_net","Server Network Information Dir.",sa.dir_net)             
    printline ("sa.dir_rpt","SYStem MONitor Report Directory",sa.dir_rpt)             
    printline ("sa.dir_dbb","Database Backup Directory",sa.dir_dbb)                   
    printline ("sa.dir_setup","SADMIN Setup Directory.",sa.dir_setup)                 
    printline ("sa.dir_usr","User/System specific directory",sa.dir_usr)              
    printline ("sa.dir_usr_bin","User/System specific bin/script Dir.",sa.dir_usr_bin)
    printline ("sa.dir_usr_lib","User/System specific library Dir.",sa.dir_usr_lib)   
    printline ("sa.dir_usr_doc","User/System specific documentation",sa.dir_usr_doc)  
    printline ("sa.dir_usr_mon","User/System specific SysMon Scripts",sa.dir_usr_mon) 
    printline ("sa.dir_www","SADMIN Web Site Root Directory",sa.dir_www)              
    printline ("sa.dir_www_doc","SADMIN Web Site Root Directory",sa.dir_www_doc)      
    printline ("sa.dir_www_dat","SADMIN Web Site Systems Data Dir.",sa.dir_www_dat)   
    printline ("sa.dir_www_lib","SADMIN Web Site PHP Library Dir.",sa.dir_www_lib)    
    printline ("sa.dir_www_tmp","SADMIN Web Temp Working Directory",sa.dir_www_tmp)   
    printline ("sa.dir_www_perf","Web system performance Graph Dir.",sa.dir_www_perf) 
       



#===================================================================================================
# Print Files Variables Available to Users
#===================================================================================================
def print_file_variable():

    printheader ("SADMIN File Names set in the Library for you to use","","Results")

    print_section_name ("File Name Aliases Variables")
    printline ("sa.pid_file","Current script PID file",sa.pid_file)  
    printline ("sa.cfg_file","SADMIN configuration file",sa.cfg_file)  
    printline ("sa.cfg_hidden","SADMIN configuration template",sa.cfg_hidden)
    printline ("sa.alert_file","Alert group definition file",sa.alert_file)
    printline ("sa.alert_init","Alert group template file",sa.alert_init)
    printline ("sa.alert_hist","Alert History file",sa.alert_hist) 
    printline ("sa.alert_hini","Alert History template file",sa.alert_hini)
    printline ("sa.tmp_file1","User usable Temp Work File 1",sa.tmp_file1)
    printline ("sa.tmp_file2","User usable Temp Work File 2",sa.tmp_file2)
    printline ("sa.tmp_file3","User usable Temp Work File 3",sa.tmp_file3)
    printline ("sa.log_file","Script Log File",sa.log_file)
    printline ("sa.rch_file","Script Return Code History File",sa.rch_file) 
    printline ("sa.dbpass_file","SADMIN Database User Password File",sa.dbpass_file) 
    printline ("sa.rpt_file","[SYS]tem [MON]itor report file",sa.rpt_file)
    printline ("sa.backup_list","Backup list file name",sa.backup_list)
    printline ("sa.backup_list_init","Backup list template file",sa.backup_list_init)
    printline ("sa.backup_exclude","Backup exclude list file name",sa.backup_exclude)           
    printline ("sa.backup_exclude_init","Backup exclude template file",sa.backup_exclude_init)  







# Print SADMIN main configuration file (SADMIN/cfg/sadmin.cfg) variables available to users
#===================================================================================================
def print_sadmin_cfg(show_password=False):

    printheader ("SADMIN CONFIG FILE VARIABLES","Description","  This System Result")

    print_section_name ("SADMIN General Section")
    printline ("sa.sadm_server","SADMIN server name (FQDN)",sa.sadm_server) 
    printline ("sa.sadm_host_type","SADMIN [C]lient or [S]erver",sa.sadm_host_type)   
    printline ("sa.sadm_mail_addr","SADMIN Administrator Email(s)",sa.sadm_mail_addr)
    printline ("sa.sadm_cie_name","Your Company name",sa.sadm_cie_name) 
    printline ("sa.sadm_domain","Server creation default domain",sa.sadm_domain)
    printline ("sa.sadm_user","SADMIN User Name",sa.sadm_user) 
    printline ("sa.sadm_group","SADMIN Group Name",sa.sadm_group)
    printline ("sa.sadm_pwd_random","Auto generation of '$SADM_USER' pwd",sa.sadm_pwd_random) 
    printline ("sa.sadm_pid_timeout","PID file default TimeToLive (Sec)",sa.sadm_pid_timeout)
    printline ("sa.sadm_lock_timeout","Maximun nb. sec. a host can be lock",sa.sadm_lock_timeout)

    print_section_name ("Alerting/Notification Section")
    printline ("sa.sadm_alert_type","0=NoMail 1=OnError 3=OnSuccess 4=All",sa.sadm_alert_type) 
    printline ("sa.sadm_alert_group","Error Group (Default Group)",sa.sadm_alert_group) 
    #printline ("sa.sadm_warning_group","Warning Group Name",sa.sadm_warning_group) 
    #printline ("sa.sadm_info_group","Info Group Name",sa.sadm_info_group) 

    presult="*Hidden*"                                                  # Don't show TextBelt Key
    if show_password : presult=sa.sadm_textbelt_key                     # Unless requested (-p)
    printline ("sa.sadm_textbelt_key","TextBelt.com API Key",presult)   
    printline ("sa.sadm_textbelt_url","TextBelt.com API URL",sa.sadm_textbelt_url) 


    print_section_name ("Database Section")
    printline ("sa.sadm_dbname","SADMIN Database Name",sa.sadm_dbname)  
    printline ("sa.sadm_dbhost","SADMIN Database Host",sa.sadm_dbhost)  
    printline ("sa.sadm_dbport","SADMIN Database Host TCP Port",sa.sadm_dbport)
    printline ("sa.sadm_rw_dbuser","SADMIN Database Read/Write User",sa.sadm_rw_dbuser) 
    presult="*Hidden*"                                                  # Default don't show passwd
    if show_password : presult=sa.sadm_rw_dbpwd                         # Selected to Show DB Passwd
    printline ("sa.sadm_rw_dbpwd","SADMIN Database Read/Write User Pwd",presult)
    printline ("sa.sadm_ro_dbuser","SADMIN Database Read Only User",sa.sadm_ro_dbuser) 
    presult="*Hidden*"                                                  # Default don't show passwd
    if show_password : presult=sa.sadm_ro_dbpwd                         # Selected to Show DB Passwd
    printline ("sa.sadm_ro_dbpwd","SADMIN Database Read Only User Pwd",presult) 

    print_section_name ("Web Interface Section")
    printline ("sa.sadm_www_user","User that Run Apache Web Server",sa.sadm_www_user)   
    printline ("sa.sadm_www_group","Group that Run Apache Web Server",sa.sadm_www_group)

    print_section_name ("Email Section")
    printline ("sa.sadm_mail_addr","SADMIN Administrator Email(s)",sa.sadm_mail_addr)
    printline ("sa.sadm_smtp_server","Your internet smtp server",sa.sadm_smtp_server)  
    printline ("sa.sadm_smtp_port","Your internet smtp server port",sa.sadm_smtp_port) 
    printline ("sa.sadm_smtp_sender","Your internet smtp email address",sa.sadm_smtp_sender)
    presult="*Hidden*"                                                  # Default don't show passwd
    if show_password : presult=sa.sadm_gmpw                             # Selected to Show smtp pwd
    printline ("sa.sadm_gmpw","Your internet smtp email password",presult)  
    printline ("sa.sadm_email_startup","Send email on startup",sa.sadm_email_startup)  
    printline ("sa.sadm_email_shutdown","Send email on shutdown",sa.sadm_email_shutdown)  

    print_section_name ("Monitoring Section")
    printline ("sa.sadm_ssh_port","SSH Port to communicate with client",sa.sadm_ssh_port)
    printline ("sa.sadm_monitor_update_interval","SYSMON web page refresh rate (Sec)",sa.sadm_monitor_update_interval)
    printline ("sa.sadm_monitor_recent_count","SYSMON web page nb. recent scripts",sa.sadm_monitor_recent_count)
    printline ("sa.sadm_monitor_recent_exclude","SYSMON recent scripts excluded",sa.sadm_monitor_recent_exclude)

    print_section_name ("Files/Logs pruning Section")
    printline ("sa.sadm_nmon_keepdays","Nb. of days to keep nmon perf. file",sa.sadm_nmon_keepdays) 
    printline ("sa.sadm_rch_keepdays","Nb. days to keep unmodified rch file",sa.sadm_rch_keepdays)
    printline ("sa.sadm_log_keepdays","Nb. days to keep unmodified log file",sa.sadm_log_keepdays) 
    printline ("sa.sadm_max_rchline","Trim rch file to this max. of lines",sa.sadm_max_rchline)
    printline ("sa.sadm_max_logline","Trim log to this maximum of lines",sa.sadm_max_logline)
    printline ("sa.sadm_days_history","Days to keep alert in History file",sa.sadm_days_history)
    printline ("sa.sadm_max_arc_line","Max lines to keep in alert archive",sa.sadm_max_arc_line) 

    print_section_name ("Subnet Network Scanner Section")
    presult=sa.sadm_network1    
    if presult == "" : presult="None"
    printline ("sa.sadm_network1","Network/Netmask 1 inv. IP/Name/Mac",presult) 
    presult=sa.sadm_network2
    if presult == "" : presult="None"
    printline ("sa.sadm_network2","Network/Netmask 2 inv. IP/Name/Mac",presult) 
    presult=sa.sadm_network3    
    if presult == "" : presult="None"
    printline ("sa.sadm_network3","Network/Netmask 3 inv. IP/Name/Mac",presult) 
    presult=sa.sadm_network4    
    if presult == "" : presult="None"
    printline ("sa.sadm_network4","Network/Netmask 4 inv. IP/Name/Mac",presult) 
    presult=sa.sadm_network5
    if presult == "" : presult="None"
    printline ("sa.sadm_network5","Network/Netmask 5 inv. IP/Name/Mac",presult) 

    print_section_name ("ReaR Backup Section")
    printline ("sa.sadm_rear_nfs_server","ReaR NFS Server IP or Name",sa.sadm_rear_nfs_server)
    printline ("sa.sadm_rear_nfs_server_ver","ReaR NFS Server Version",sa.sadm_rear_nfs_server_ver)
    printline ("sa.sadm_rear_nfs_mount_point","ReaR NFS Mount Point",sa.sadm_rear_nfs_mount_point) 
    printline ("sa.sadm_rear_backup_to_keep","ReaR NFS Backup - Nb. to keep",sa.sadm_rear_backup_to_keep)
    printline ("sa.sadm_rear_backup_dif","ReaR alert cur vs prev size differ",sa.sadm_rear_backup_dif)
    printline ("sa.sadm_rear_backup_interval","ReaR alert if no backup for X days",sa.sadm_rear_backup_interval)
    printline ("sa.sadm_rear_backup_script","ReaR backup script name",sa.sadm_rear_backup_script)
    printline ("sa.sadm_rear_del_failed_backup","Delete failed backup",sa.sadm_rear_del_failed_backup)
    printline ("sa.sadm_rear_batch_mode","Run backup in batch mode",sa.sadm_rear_batch_mode)
    printline ("sa.sadm_rear_batch_startup_time","Batch startup time",sa.sadm_rear_batch_startup_time)  
    printline ("sa.sadm_rear_backup_concurrent","Concurrent rear backup process",sa.sadm_rear_backup_concurrent)

    print_section_name ("Backup Section")
    printline ("sa.sadm_backup_nfs_server","NFS Backup IP or Server Name",sa.sadm_backup_nfs_server)
    printline ("sa.sadm_backup_nfs_server_ver","NFS Backup Server Version",sa.sadm_backup_nfs_server_ver)
    printline ("sa.sadm_backup_nfs_mount_point","NFS Backup Mount Point",sa.sadm_backup_nfs_mount_point) 
    printline ("sa.sadm_backup_dif","Backup alert cur vs prev size differ","%s %%" % (sa.sadm_backup_dif))
    printline ("sa.sadm_backup_interval","Backup alert if older than X days","%s days" % (sa.sadm_backup_interval))
    printline ("sa.sadm_daily_backup_to_keep","Daily Backup to Keep",sa.sadm_daily_backup_to_keep)
    printline ("sa.sadm_weekly_backup_to_keep","Weekly Backup to Keep",sa.sadm_weekly_backup_to_keep)
    printline ("sa.sadm_monthly_backup_to_keep","Monthly Backup to Keep",sa.sadm_monthly_backup_to_keep)
    printline ("sa.sadm_yearly_backup_to_keep","Yearly Backup to keep",sa.sadm_yearly_backup_to_keep)
    printline ("sa.sadm_weekly_backup_day","Weekly Backup Day (1=Mon,7=Sun)",sa.sadm_weekly_backup_day)
    printline ("sa.sadm_monthly_backup_date","Monthly Backup Date (1-28)",sa.sadm_monthly_backup_date)
    printline ("sa.sadm_yearly_backup_month","Yearly Backup Month (1-12)",sa.sadm_yearly_backup_month) 
    printline ("sa.sadm_yearly_backup_date","Yearly Backup Date (1-31)",sa.sadm_yearly_backup_date)
    printline ("sa.sadm_backup_concurrent","Concurrent Backup Processes",sa.sadm_backup_batch_concurrent)
    printline ("sa.sadm_backup_batch_mode","Run backup in batch mode",sa.sadm_backup_batch_mode)
    printline ("sa.sadm_backup_batch_startup_time","Batch startup time",sa.sadm_backup_batch_start_time)  


    print_section_name ("Virtual Machines Export Section")
    printline ("sa.sadm_vm_export_nfs_server","NFS Export Server",sa.sadm_vm_export_nfs_server)
    printline ("sa.sadm_vm_export_nfs_server_ver","NFS Export Server Version",sa.sadm_vm_export_nfs_server_ver)
    printline ("sa.sadm_vm_export_mount_point","NFS Export Mount Point",sa.sadm_vm_export_mount_point)
    printline ("sa.sadm_vm_export_dif","Export alert cur vs prev size differ","%s %%" % (sa.sadm_vm_export_dif))
    printline ("sa.sadm_vm_export_to_keep","Nb. of export to keep",sa.sadm_vm_export_to_keep)
    printline ("sa.sadm_vm_export_interval","Days without export before alert",sa.sadm_vm_export_interval)
    printline ("sa.sadm_vm_export_alert","Issue an alert if interval reached",sa.sadm_vm_export_alert)
    printline ("sa.sadm_vm_user","User part of 'vboxusers' user group",sa.sadm_vm_user)
    printline ("sa.sadm_vm_stop_timeout","Max. seconds given for acpi shutdown",sa.sadm_vm_stop_timeout)
    printline ("sa.sadm_vm_start_interval","Sec. to sleep between each VM start",sa.sadm_vm_start_interval)
    printline ("sa.sadm_vm_export_batch_mode","Run start script in batch mode (Y/N)",sa.sadm_vm_export_batch_mode)
    printline ("sa.sadm_vm_export_batch_start_time","Start time for launch batch export",sa.sadm_vm_export_batch_start_time)
    printline ("sa.sadm_vm_export_concurrent","Concurrent export process",sa.sadm_vm_export_concurrent)


    print_section_name ("System Update Section")
    printline ("sa.sadm_osupdate_interval","System Update Interval",sa.sadm_osupdate_interval)
    printline ("sa.sadm_osupdate_script","System Update Script",sa.sadm_osupdate_script)
    printline ("sa.sadm_osupdate_autoremove","Auto Remove Updates",sa.sadm_osupdate_autoremove)
    printline ("sa.sadm_osupdate_flatpak","Flatpak Updates",sa.sadm_osupdate_flatpak)
    printline ("sa.sadm_osupdate_snap","Snap Updates",sa.sadm_osupdate_snap)
    printline ("sa.sadm_osupdate_reboot_needed","Reboot Needed",sa.sadm_osupdate_reboot_needed)
    printline ("sa.sadm_osupdate_reboot_time","Reboot Time",sa.sadm_osupdate_reboot_time)
    printline ("sa.sadm_osupdate_lock","Lock Updates",sa.sadm_osupdate_lock)
    printline ("sa.sadm_osupdate_batch_mode","Batch Mode",sa.sadm_osupdate_batch_mode)
    printline ("sa.sadm_osupdate_batch_start_time","Batch Start Time",sa.sadm_osupdate_batch_start_time)
    printline ("sa.sadm_osupdate_concurrent","Concurrent Update Process",sa.sadm_osupdate_concurrent)




#===================================================================================================
# Print Command Path Variables available to users
#===================================================================================================
def print_command_path():
    
    printheader ("Command Path Use By SADMIN Library for more security.","Description","  ")
    printline ("sa.cmd_dmidecode","Cmd. 'dmidecode', Get model & type",sa.cmd_dmidecode) 
    printline ("sa.cmd_bc","Cmd. 'bc', Do some Math.",sa.cmd_bc) 
    printline ("sa.cmd_fdisk","Cmd. 'fdisk', Get Partition Info",sa.cmd_fdisk) 
    printline ("sa.cmd_which","Cmd. 'which', Get Command location",sa.cmd_which) 
    printline ("sa.cmd_locate","Cmd. 'locate', Get Command location",sa.cmd_locate)
    printline ("sa.cmd_perl","Cmd. 'perl', epoch time Calc.",sa.cmd_perl)
    printline ("sa.cmd_mutt","Cmd. 'mutt', Used to Send Email",sa.cmd_mutt)
    printline ("sa.cmd_curl","Cmd. 'curl', To send alert to Slack",sa.cmd_curl)
    printline ("sa.cmd_lscpu","Cmd. 'lscpu', Socket & thread info",sa.cmd_lscpu)
    printline ("sa.cmd_nmon","Cmd. 'nmon', Collect Perf Statistic",sa.cmd_nmon)
    printline ("sa.cmd_parted","Cmd. 'parted', Get Disk Real Size",sa.cmd_parted)
    printline ("sa.cmd_ethtool","Cmd. 'ethtool', Get System IP Info",sa.cmd_ethtool)
    printline ("sa.cmd_rrdtool","Cmd. 'rrdtool' to produce graph",sa.cmd_rrdtool)
    printline ("sa.cmd_lsb_release","Cmd. 'lsb_release' to get dist. info",sa.cmd_lsb_release)
    printline ("sa.cmd_inxi","Cmd. 'inxi' binary location",sa.cmd_inxi)
    printline ("sa.cmd_ssh","Cmd. 'ssh', SSH to SADMIN client",sa.cmd_ssh)
    printline ("sa.cmd_ssh_full","Cmd. 'ssh', SSH to connect to client",sa.cmd_ssh_full)

        
#===================================================================================================
# Print sadm_start and sadm_stop Function Used by SADMIN Tools
#===================================================================================================
def print_start_stop():
    printheader ("Overview of the 'sa.start()' and 'sa.stop()' functions"," "," ")
     
    print ("") 
    print ("Function 'sa.start(pver,pdesc)'")
    print ("    - 'pver' variable in SADMIN section, indicate the script version.") 
    print ("    - 'pdesc' variable in SADMIN section, is a short description of the script.") 
    print ("") 
    print ("  What this function does:") 
    print ("    1) Make sure all $SADMIN directories & sub-dir. exist and have proper permissions.") 
    print ("    2) Make sure log files exist with proper permission.") 
    print ("    3) Write the log header (if 'sa.log_header = True').") 
    print ("    4) If script run on the SADMIN server, check if the system is lock")
    print ("    5) If PID file exist, show error message and abort.") 
    print ("       Unless user allow to run simultaneously more than one copy (sa.multiple_exec=True).") 
    print ("    6) Record the start Date/Time.") 
    print ("    7) Add line in the [R]eturn [C]ode [H]istory file stating script is started (Code 2).") 
    print ("") 
    print ("") 
    print ("Function 'sa.stop(pexit_code)'") 
    print ("    - 'pexit_code' variable defined in SADMIN section, is the script exit code (0=OK 1=Error).") 
    print ("") 
    print ("  This should be the last function called at the end of your script.") 
    print ("  It accept one parameter - Either 0 (Successful) or non-zero (Error Encountered).") 
    print ("  Example : sa.stop(pexit_code)   # Close SADMIN Environment") 
    print ("") 
    print ("  What this function does:") 
    print ("    1) Get actual time and calculate the execution time.") 
    print ("    2) If the exit code is not zero, change it to 1.") 
    print ("    3) If 'sa.log_footer = True', write the log footer.") 
    print ("    4) If 'sa.use_rch = True', append (Start/End/Elapse Time ...) in the RCH File.") 
    print ("    5) Trim The RCH File according to user choice in 'sa.sadm_max_rchline'.")  
    print ("       No trim is done if 'sa.sadm_max_rchline = 0'.") 
    print ("    6) Trim the log according to user choice in 'sa.sadm_max_logline'.") 
    print ("       No trim is done if 'sa.sadm_max_logline = 0'.") 
    print ("    7) Delete the PID file of the script (sa.pid_file).") 
    print (" ")


#===================================================================================================
# Show Environment Variables Defined
#===================================================================================================
def print_env():
    printheader ("Environment Variables.","Description","  This System Result")
    for a in os.environ:
        pexample=a                                                          # Env. Var. Name
        pdesc="Env.Var. %s" % (a)                                           # Env. Var. Name
        presult=os.getenv(a)                                                # Return Value(s)
        printline (pexample,pdesc,presult)                               # Print Env. Line



#===================================================================================================
# Print Database Information
#===================================================================================================
def print_db_variables():
    printheader ("Database Information","Description","  This System Result")
         
    pexample="sa.db_used"                                               # Variable Name
    pdesc="Script using Database ?"                                     # Function Description
    presult=sa.db_used                                                  # Return Value(s)
    printline (pexample,pdesc,presult)                                  # Print Example Line

    # Test Database Connection
    if ((sa.on_sadmin_server == "Y") and (sa.db_used)):                 # On SADMIN srv & usedb True
        print ("\n\nShow SADMIN Tables:")
        sql="show tables;" 
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser,sa.sadm_ro_dbpwd,sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);

        print ("\n\nCategory Table:")
        sql="describe server_category; "                                    # Show Table Format/colums
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout)
        
        sql="SHOW keys FROM server_category FROM sadmin; "
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);

        sql="select * from server_category; "                              # Show Table Format/columns
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);

        print ("\n\nGroup Table:")
        sql="show columns from server_group; "                              # Show Table Format/columns
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);
        
        sql="SHOW keys FROM server_group FROM sadmin; "
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);
        
        sql="select * from server_group; "                              # Show Table Format/columns
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);

        print ("\n\nServer Table:")
        sql="describe server; "
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);
        
        sql="SHOW keys FROM server FROM sadmin; "
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);

        print ("\n\nScript table:")
        sql="describe script; "
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);
        
        sql="SHOW keys FROM script FROM sadmin; "
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);
        
        sql="select scr_name, scr_desc,scr_version,scr_root_exec,scr_run_sadmin from script; "
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);

        print ("\n\nScript_rch:")
        sql="describe script_rch; "
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);
        
        sql="SHOW keys FROM script_rch FROM sadmin; "
        cmd =  "mysql -t -u%s -p%s -h%s" % (sa.sadm_ro_dbuser, sa.sadm_ro_dbpwd, sa.sadm_dbhost)
        cmd = "%s %s -e '%s'" % (cmd, sa.sadm_dbname, sql)
        (returncode,stdout,stderr)=sa.oscommand(cmd)
        print (stdout);
        
        sa.write_log ("Closing Database db_connection")
        sa.write_log (" ")
        return (0)



# Command line Options
# --------------------------------------------------------------------------------------------------
def cmd_options(argv):
    """ Command line Options functions - Evaluate Command Line Switch Options

        Args:
            (argv): Arguments pass on the comand line.
              [-d 0-9]  Set Debug (verbose) Level
              [-h]      Show this help message
              [-v]      Show script version information
              [-p]      Show Database, TextBelt & Mail passwd in output
              [-t]      Show TextBelt Key
        Returns:
            pdebug (int)          : Set to the debug level [0-9] (Default is 0)
    """

    debug = 0                                                          # Default Debug Level
    show_password = False                                               # Show Password Default
    parser = argparse.ArgumentParser(description=sa.desc)                 # Desc. is the script name

    # Declare Arguments
    parser.add_argument("-v","--version", 
                        action="store_true",
                        dest='version',
                        help="Show script version")
    parser.add_argument("-d","--debug",
                        metavar="0-9",
                        type=int,
                        dest='debug',
                        help="debug/verbose level from 0 to 9",
                        default=0)
    parser.add_argument("-p","--password",
                        action="store_true",
                        dest='show_password',
                        help="Show database password in output")
        
    args = parser.parse_args()                                          # Parse the Arguments

    # Set return values accordingly.
    if args.debug:                                                     # Debug Level -d specified
        debug = args.debug                                            # Save Debug Level
        print("Debug Level is now set at %d" % (sa.debug))                # Show user debug Level
    if args.show_password:                                              # Show Password -p
        show_password = args.show_password                              # Show DB, Mail Password
    if args.version:                                                    # If -v specified
        sa.show_version(sa.ver)                                           # Show Custom Show Version
        sys.exit(0)                                                     # Exit with code 0

    return(sa.debug,show_password)                                        # Return cmdline choices





#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main(argv):
    global show_password                                                # Global Variables
    (pdebug,show_password) = cmd_options(argv)                          # Analyse cmdline options
    pexit_code = 0                                                      # Pgm Exit Code Default
    #sa.start(sa.ver, sa.desc)                                               # Initialize SADMIN env.
    sa.start()                                                          # Initialize SADMIN env.
    print_functions()                                                   # Display Env. Variables
    print_user_variables()                                              # Show User Avail. Variables

    
    print_python_function()                                             # Show Python Specific func.
    print_start_stop()                                                  # Show Stop/Start Function
    print_sadmin_cfg(show_password)                                                  # Show sadmin.cfg Variables
    print_directories()                                                 # Show Client Dir. Variables
    print_file_variable()                                               # Show Files Variables
    print_command_path()                                                # Show Command Path
    if (sa.sadm_host_type == "S") :                                     # If on a SADMIN server
       print_db_variables()                                             # Show Database Information

    #print_env()                                                        # Show Env. Variables
    sa.stop(sa.exit_code)                                               # Close SADM Environment
    sys.exit(sa.exit_code)                                              # Exit To O/S

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv[1:])
