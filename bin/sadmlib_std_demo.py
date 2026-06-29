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
# 2018_12_03 lib v03.00.00 Remove dot before and after the result column and minor changes.
# 2019_01_19 lib v03.01.00 Added: Added Backup List & Backup Exclude File Name available to User.
# 2019_01_28 lib v03.02.00 Database info only show when running on SADMIN Server
# 2019_03_18 lib v03.03.00 Add demo call to function get_packagetype()
# 2019_04_07 lib v03.04.00 Don't show Database user name if run on client.
# 2019_04_25 lib v03.05.00 Add Alert_Repeat, Textbelt API Key and URL Variable in Output
# 2019_05_17 lib v03.06.00 Add option -p(Show DB password),-s(Show Storix Info),-t(Show TextBeltKey)
# 2019_08_19 lib v03.07.00 Remove printing of sa.alert_seq (not used anymore)
# 2019_10_14 lib v03.08.00 Add demo for calling sadm_server_arch function & show result.
# 2019_10_18 lib v03.09.00 Print SADMIN Database Tables and columns at the end of report.
# 2019_10_30 lib v03.10.00 Remove Utilization of 'facter' (Depreciated).
# 2022_04_09 lib v03.11.00 Rewrote Overview of the 'sa.start()' and 'sa.stop()' functions.
# 2022_04_10 lib v03.12.00 Remove 'lsb_release' command dependency (Not avail in RHEL 9)
# 2022_05_15 lib v03.13.00 Updated to use the new SADMIN Python Library V2.
# 2022_05_18 lib v03.14.00 Added print of new fields 'sa.sadm_pid_timeout' & 'sa.sadm_lock_timeout'.
# 2022_05_21 lib v03.15.00 Late Adjustment & Minor changes
# 2022_05_25 lib v03.16.00 Added fields 'sa.proot_only' & 'sa.psadm_server_only' to output.
# 2022_08_14 lib v03.17.00 Output updated with all the latest functions & global variables.
# 2023_04_13 lib v03.18.00 Add 'sadm_rear_dif', 'sadm_rear_interval', 'sadm_backup_interval' to output.
# 2023_04_14 lib v03.19.00 SADMIN server email account pwd now taken from $SADMIN/cfg/.gmpw.
# 2023_04_14 lib v03.20.00 SADMIN client email account pwd now taken from encrypted $SADMIN/cfg/.gmpw64. 
# 2023_08_19 lib v03.21.00 start() function auto connect to DB, if on SADMIN server & db_used=True.
# 2023_12_19 lib v03.22.00 Fix minor problem
#@2024_05_10 lib v03.23.00 Add VM export parameters and alert history/archive purge days limit.
#@2024_12_17 lib v03.24.00 Add new global variable 'sadm_pwd_random' to auto-generate 'sadmin user' pwd.
#@2026_03_06 lib v03.25.00 Show Database info only on the SADMIN server.
#@2026_05_20 lib v03.26.01 New Variables and functions available.
#@2026_05_30 lib v03.27.00 Complete revision of the demo script to show all the latest functions & Variables.
#@2026_06_29 lib v03.27.01 Show Database info, if your are on the SADMIN server & db_used set to True.
# ==================================================================================================
#
try :
    import os, time, sys, pdb, socket, pdb, datetime, glob, argparse, pymysql, platform
    #from email_validator import validate_email EmailNotValidError

except ImportError as e:                                            
    print ("Import Error : %s " % e)
    sys.exit(1)

#pdb.set_trace()                                                    # Activate Python Debugging




# --------------------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.58 (Compatible with previous one)
# Setup some Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your Python code.    
# --------------------------------------------------------------------------------------------------
try:
    SADM = os.environ['SADMIN']                                      # Get 'SADMIN' Environment Var.
except KeyError as e:                                                # If 'SADMIN' is not defined
    print("Environment variable 'SADMIN' not defined.\n%s\nScript aborted.\n" % e) 
    sys.exit(1)                                                      # Go Back to O/S with Error

try: 
    sys.path.insert(0, os.path.join(SADM, 'lib'))                    # Add SADMIN libdir to sys.path
    import sadmlib2_std as sa                                        # Import SADMIN Python Library
except ImportError as e:                                             # If Error importing SADMIN
    print("Import error : SADMIN module: %s " % e)                   # Advise User of Error
    print("Please make sure the 'SADMIN' environment variable is defined.")
    sys.exit(1)                                                      # Go Back to O/S with Error

# Variables shared with SADMIN Python Library.
sa.ver                = "03.27.01" # Your Program VERSION number
sa.desc               = "Describe '%s' here." % (sa.pn)
sa.root_only          = False      # Can Only be run by 'root'(True/False)
sa.server_only        = False      # Run Only on SADMIN server(True/False) SADM_SERVER in sadmin.cfg
sa.sadmgrp_only       = False      # Run if part of SADMIN Group 'SADM_GROUP' in sadmin.cfg or root
sa.use_rch            = False      # Write exec info to RCH file(True/False)
sa.db_used            = True       # Open/Use auto connect DB(True)
sa.log_type           = "B"        # S=Screen L=Log B=Both
sa.log_append         = False      # Append to previous log (True/False)
sa.log_header         = True       # Produce Log Header (True/False)
sa.log_footer         = True       # Produce Log Footer (True/False)
sa.multiple_exec      = False      # Allow running multiple Instance ?
#
sa.pid_timeout        = 14400       # PID File TimeToLive default is SADM_PID_TIMEOUT in sadmin.cfg
sa.lock_timeout       = 7200       # Sec. before unlock default is SADM_LOCK_TIMEOUT in sadmin.cfg
sa.max_logline        = 500        # Max. number of lines in log file SADM_MAX_LOGLINE in sadmin.cfg
sa.max_rchline        = 50         # Max. number of lines in rch file SADM_MAX_RCLINE in sadmin.cfg
sa.db_name            = "sadmin"   # Database Name (sadmin=default) SADM_DBNAME in sadmin.cfg
sa.sadm_alert_type    = 1          # 0=NoAlert 1=AlertOnlyOnError 2=AlertOnlyOnSuccess 3=AlwaysAlert
sa.sadm_alert_repeat  = 0          # 0=Alert only once per alert. 14400=4hrs between alert repeat
sa.sadm_alert_group   = "default"  # Error Alert   Group defined in $SADMIN/cfg/alert_group.cfg
sa.sadm_warning_group = "warning"  # Warning Alert Group defined in $SADMIN/cfg/alert_group.cfg
sa.sadm_info_group    = "info"     # Info Alert    Group defined in $SADMIN/cfg/alert_group.cfg
sa.quiet              = False      # If error in a function & quiet is: (give you ctrl of message)
                                   # False: Show error message and return the error number. 
                                   # True : Omly returm error number, but don't show error message.

# Variables that are share with the Library available to Developer
sa.pn        = os.path.basename(sys.argv[0])   # [P]rogram [N]ame with extension
sa.inst      = sa.pn.split('.')[0] # INSTance Name = Pgm Name Without Ext
sa.errno     = 0                   # Error No. set by function called (0=OK Else error/warning)
sa.errmsg    = ""                  # Error Mess. set by function you call (blank or error msg)
sa.db_conn   = None                # Database Connector when using DB,  set by sa.start()
sa.db_cur    = None                # Database Cursor if you use the DB, set by sa.start()

# Variable local to this script (not share with the library) you can use at your ease.
exit_code    = 0                   # Default Return Code (0=Success 1-Error)
debug        = 0                   # Debug Level 0-9 (Increase Verbose)
hostname     = sa.get_hostname()   # Get Current hostname
username     = sa.get_username()   # Get Current User Name
pid          = os.getpid()         # Get Current Process ID.
cmd_ssh_full = "%s -qnp %s " % (sa.cmd_ssh,sa.sadm_ssh_port) # /usr/bin/ssh with sadmin.cfg port
current_time = datetime.datetime.now().strftime("%Y.%m.%d %H:%M:%S") # Format current Date and Time 
# --------------------------------------------------------------------------------------------------







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

    lcount = 0                                                          # Reset line counter 
    print ("\n\n%s" % ("-" * 100))                                      # Print line of 100 "-" 
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





# 01) Print SADMIN Functions available to Developers
#===================================================================================================
def print_functions():
    global lcount
    lcount              = 0                                                 # Reset Print Line Count


    print ("%s" % ("-" * 100))                                            # Print line of 100 "-" 
    print ("01) SADMIN Python Library functions available to developer")
    print ("%s" % ("-" * 100))                                              # Print line of 100 "-" 

    printline ("sa.get_release()","SADMIN Release Number (XX.XX)",sa.get_release())
    printline ("sa.get_ostype()","OS Type (In Uppercase,LINUX,AIX,MACOS)",sa.get_ostype()) 
    printline ("sa.get_osversion()","Return O/S Version (Ex: 7.2, 6.5)",sa.get_osversion())  
    printline ("sa.get_osmajorversion()","Return O/S Major Version (Ex 7, 6)",sa.get_osmajorversion())
    printline ("sa.get_osminorversion()","Return O/S Minor Version (Ex 2, 3)",sa.get_osminorversion())
    printline ("sa.get_osname()","O/S Distribution (In uppercase)",sa.get_osname())
    printline ("sa.get_oscodename()","O/S Project Code Name",sa.get_oscodename())
    printline ("sa.get_username()","Current User Name",sa.get_username())
    printline ("sa.get_kernel_version()","Return O/S Running Kernel Version",sa.get_kernel_version())
    printline ("sa.get_kernel_bitmode()","Return O/S Kernel Bit Mode (32 or 64)",sa.get_kernel_bitmode()) 
    printline ("sa.phostname","Return Host Name",sa.hostname)
    printline ("sa.get_host_ip()","Return Host Main IP Address",sa.get_host_ip())
    printline ("sa.get_domainname()","Return Host Domain Name",sa.get_domainname()) 
    printline ("sa.get_fqdn()","Return Fully Qualified Domain Name",sa.get_fqdn())
    printline ("sa.get_serial()","Return System serial Number",sa.get_serial())
    wepoch=sa.get_epoch_time()
    printline ("sa.get_epoch_time()","Return Current Epoch Time",sa.get_epoch_time())
    printline ("sa.epoch_to_date(%d)" % (wepoch),"Convert epoch time to date",sa.epoch_to_date(wepoch))
    wsdate=sa.epoch_to_date(wepoch) 
    printline ("sa.date_to_epoch(wsdate)", "Convert Date to epoch time", sa.date_to_epoch(wsdate) )

    DATE1="2026.06.30 10:00:44" ; DATE2="2026.06.30 09:50:03"           # Set Date to Calc Elapse
    print ("      DATE1 (End): %s" % (DATE1), "   DATE2 (Start): %s" % (DATE2)) # Print Date2 Used for Ex.
    pexample="sa.elapse_time(DATE1,DATE2)"                              # Example Calling Function
    pdesc="Elapse Time between two timestamps"                          # Function Description
    presult=sa.elapse_time(DATE1,DATE2)                                 # Return Value(s)
    printline ("sa.elapse_time(DATE1,DATE2)","Elapse Time between two timestamps",presult) 
    printline ("sa.get_packagetype()","Return package type (rpm,deb,lpp,dmg)",sa.get_packagetype())
    printline ("sa.get_arch()","Get system architecture",sa.get_arch())
    printline ("sa.lock_system(hostname)","Lock the specified hostname (Not FQDN)",sa.lock_system(sa.sadm_server,errmsg=False)) 
    printline ("sa.lock_status(hostname)","Check if host specified is lock",sa.lock_status(sa.sadm_server,errmsg=False)) 
    printline ("sa.unlock_system(hostname)","Unlock host specified, monitoring on",sa.unlock_system(sa.sadm_server))
    printline ("sa.lock_status(hostname)","Check if host specified is lock",sa.lock_status(sa.sadm_server,errmsg=False)) 
    printline ("sa.write_log('message'[,lf=true])","Write message to Screen,Log or Both","message")
    printline ("sa.write_err('message'[,lf=true])","Write message to Error and Std Log","message")
    printline ("sa.sendmail(mail,sub,body,attach)","sadm_sendmail(email,\"subject\",\"body_file\",\"file1,file2\")","")
    printline ("sa.show_version(sa.ver)","Show Program & Library version & Desc.","script -v")
    printline ("sa.sleep(60,15)","Sleep 60 sec & update every 15 sec.","60...45...30...15...0") 
    printline ("sa.trimfile(filename,nlines=500)","Keep last 500 lines of filename.","0=Success  1=Error") 
    #printline ("sa.get_mac_address(wip)","Get MAC address of the system", sa.get_mac_address(wip))
    printline ("sa.get_nb_cpu","Return number of CPUs",sa.get_nb_cpu())
    printline ("sa.get_nb_core_per_socket()","Return number of core per socket",sa.get_nb_core_per_socket())
    printline ("sa.get_nb_thread_per_core()","Return number of threads per core",sa.get_nb_thread_per_core())
    printline ("sa.get_nb_socket()","Return number of socket",sa.get_nb_socket())
    printline ("sa.silentremove('file')","Silent file delete (no msg, no err)",sa.silentremove('file'))
    printline ("sa.touch_file('filename')","Create an empty file","0=Success 1=Error")
    printline ("sa.db_connect('sadmin')","Open connection to database","0=Success 1=Error") 
    printline ("sa.db_close(conn,cur)","Close connection to database","0=Success 1=Error")
    return (0) 






# 02) Print Variables that affect SADMIN Tools Behavior
#===================================================================================================
def print_user_variables():
    global lcount
    lcount              = 0                                                 # Reset Print Line Count

    print ("\n\n\n%s" % ("-" * 100))                                    # Print line of 100 "-" 
    print ("02) Variables that influence library behavior, in SADMIN Code Section of your code ")
    print ("    We recommend, to set these variables prior to calling 'sa.sadm_start()'.")
    print ("%s" % ("-" * 100))                                          # Print line of 100 "-" 

    printline ("sa.ver","Program version number",sa.ver)
    printline ("sa.desc","Program description",sa.desc)
    printline ("sa.root_only","Program can only be run by 'root'",sa.root_only)
    printline ("sa.server_only","Program can only run on SADMIN server",sa.server_only)
    printline ("sa.sadmgrp_only","Run only if part of SADMIN Grp or root",sa.server_only)
    printline ("sa.multiple_exec","Can run more than 1 copy simultaneously",sa.multiple_exec)
    printline ("sa.quiet","Quiet False=ErrNo+Mess True=OnlyErrNo",sa.quiet)  
    printline ("sa.use_rch","Save execution data to '.rch' file",sa.use_rch) 
    printline ("sa.log_type","Set Output to [S]creen [L]og [B]oth",sa.log_type)
    printline ("sa.log_append","True=Append to log, False=New log",sa.log_append)
    printline ("sa.log_header","Generate header in log",sa.log_header)
    printline ("sa.log_footer","Generate footer in log",sa.log_footer)
    printline ("sa.db_used","Need Access to SADMIN Database ?",sa.db_used)
    printline ("sa.db_name","Database Name (Defaut:'sadmin')",sa.db_name)
    printline ("sa.sadm_pid_timeout","PID file default TimeToLive (Sec)",sa.sadm_pid_timeout)
    printline ("sa.sadm_lock_timeout","Maximun nb. sec. a host can be lock",sa.sadm_lock_timeout)
    printline ("sa.sadm_max_rchline","Trim rch file to this max. of lines","%d lines" % sa.sadm_max_rchline)
    printline ("sa.sadm_max_logline","Trim log to this maximum of lines","%d lines" % sa.sadm_max_logline)
    printline ("sa.sadm_mail_addr","SADMIN Administrator Email(s)",sa.sadm_mail_addr)
    printline ("sa.sadm_alert_type","0=NoMail 1=OnError 3=OnSuccess 4=All",sa.sadm_alert_type) 
    printline ("sa.sadm_alert_repeat","0=Alert once, 14400=4hrs before alert repeat",sa.sadm_alert_repeat) 
    printline ("sa.sadm_alert_group","Error Group (Default Group)",sa.sadm_alert_group) 
    printline ("sa.sadm_warning_group","Warning Group Name",sa.sadm_warning_group) 
    printline ("sa.sadm_info_group","Info Group Name",sa.sadm_info_group) 

    print ("\n\n%s" % ("-" * 100))                                    # Print line of 100 "-" 
    print ("02) These variables are set in the Library and are available for you to use.") 
    print ("    But shouldn't have to change.")
    print ("%s" % ("-" * 100))                                          # Print line of 100 "-" 

    printline ("sa.pn","Pgm. name with extension",sa.pn)  
    printline ("sa.inst","Pgm. name without extension",sa.inst)
    printline ("sa.username","Current user name",sa.username)
    printline ("sa.hostname","Current Host Name",sa.hostname)
    printline ("sa.pid","Current Process ID",sa.pid)
    printline ("sa.errno","Error No. returned by function called",sa.errno)
    printline ("sa.errmsg","Error Mess. returned by function called",sa.errmsg)
    printline ("sa.db_conn","Database connector",sa.db_conn)
    printline ("sa.db_cur","Database cursor",sa.db_cur)
    printline ("sa.db_name","Database name",sa.db_name)
    printline ("debug","Debug Level 0-9 (Incr. Verbose)",debug)
    printline ("exit_code","Script Exit Return Code",exit_code)
    printline ("current_time","Current date & Time",current_time)
    printline ("cmd_ssh_full","SSH cmd to client",cmd_ssh_full)
    return(0)






# 3) Print Python sa.start() and sa.stop() function Used by SADMIN Tools
#===================================================================================================
def print_python_start_stop():
    global lcount
    lcount              = 0                                                 # Reset Print Line Count

    print ("\n\n\n%s" % ("-" * 100))                                    # Print line of 100 "-" 
    print ("03) Python Library - Overview of the 'start()' and 'stop()' functions.")
    print ("%s" % ("-" * 100))   

    print ("") 
    print ("Function 'start()'")
    print ("------------------")
    print ("   The 'start()' function basically initialize the SADMIN environment.") 
    print ("   When you call 'start()', it will only come back to caller, only if everything went OK,")   
    print ("   Otherwise, it will advise the user of the error and exit(1).") 
    print ("")     
    print ("   - If 'db_used' is True, it will create a connection to the Database and return ")
    print ("     a connection (db_conn) and cursor (db_cur) objects.")
    print ("        Example: '(db_conn,db_cur) = sa.start()' ")
    print ("   - If 'sa.db_used' is False, then it will return None for both 'sa_conn' and 'sadb_cur'.") 
    print ("") 
    print ("  Here a summary of the different things the 'start()' function does :") 
    print ("    1) Make sure $SADMIN directories and sub-dirrectories exist and have proper permissions.") 
    print ("    2) If 'log_append' is True, it open standard/error log in append mode, else write mode.")
    print ("    3) If 'log_header' is True, write the log header.") 
    print ("    4) If 'root_only' is True and the current user is not root, show error message and exit(1).")
    print ("    5) If 'server_only' is True and you are not on the SADMIN server, show error message and exit(1).")
    print ("    6) If 'sadmgrp_only' is 'True', then current user must be part of the SADMIN group (unless root)")  
    print ("    7) If 'db_used' is True, but you are not on the SADMIN Server, show error message and exit(1).")
    print ("    8) If lock_status() is True and running on the SADMIN server, issue message and exit(1)")
    print ("       If the creation of the lock was done more than 'lock_timeout' seconds, the lock file is remove.")
    print ("    9) If PID file 'pid_file' exist and 'sa.multiple_exec' is True, continue normal execution")
    print ("       If PID file exist and execution time (sec) is less than the 'pid_timeout', show error mess. and exit(1).")
    print ("       If PID file exist and execution time (sec) exceed the 'pid_timeout' a new 'pid_file' is created")
    print ("       and execution is resume.")
    print ("   10) If 'use_rch' is True, add line in 'rch' file with code '2' and starting time of your program.")
    print ("   11) If 'db_used' is True, open connection to database and return connection and cursor objects.")     
    print ("       If not on SADMIN system, show error message and exit(1).")
    print ("") 
    print ("") 
    print ("") 
    print ("Function 'stop()'") 
    print ("--------------------")
    print ("  This function accept one parameter, either a 0 for Success or a 1 for Error.")
    print ("  This should be the one of the last function called at the end of your program.") 
    print ("") 
    print ("  What this function does:") 
    print ("    1) Calculate execution Time.")
    print ("    2) If 'use_rch = True', update the rch file (End Time & Elapse Time ...).") 
    print ("    3) Validate & determine the alert group name (sadm_alert_group) use in rch file.")
    print ("    4) If 'db_used' is True and we are on the SADMIN server, close the database connection.") 
    print ("    5) If the error log file (.elog) is empty, delete it.")
    print ("    6) Delete the PID file of the script (pid_file).") 
    print ("    7) If 'log_footer'is True, write the log footer.") 
    print ("    8) Close log and error log files.") 
    print ("    9) If 'sa.max_logline' is not zero, trim the log according to user choice in 'sa.max_logline'.") 
    print ("   10) If 'sa.max_rchline' is not zero, trim the 'rch' according to user choice in 'sa.max_rchline'.")  
    print ("   11) Set permission and owner/group to log and rch files.") 
    print ("   12) If on the SADMIN server, then rch and log are immediatly web central directory.")






# 4) Print SADMIN main configuration file (SADMIN/cfg/sadmin.cfg) variables available to users
#===================================================================================================
def print_sadmin_cfg(show_password=False):
    global lcount
    lcount              = 0                                                 # Reset Print Line Count

    print ("\n\n\n%s" % ("-" * 100))                                        # Print line of 100 "-" 
    print ("4) SADMIN configuration file - List of variables available to developers.")
    print ("%s" % ("-" * 100))                                              # Print line of 100 "-" 

    print ("\n----- General Section -----")
    printline ("sa.sadm_server","SADMIN server name (FQDN)",sa.sadm_server) 
    printline ("sa.sadm_host_type","SADMIN [C]lient or [S]erver",sa.sadm_host_type)   
    printline ("sa.sadm_cie_name","Your Company name",sa.sadm_cie_name) 
    printline ("sa.sadm_domain","Server creation default domain",sa.sadm_domain)
    printline ("sa.sadm_user","SADMIN User Name",sa.sadm_user) 
    printline ("sa.sadm_group","SADMIN Group Name",sa.sadm_group)
    printline ("sa.sadm_pwd_random","Daily change password of '$SADM_USER'",sa.sadm_pwd_random) 
    printline ("sa.sadm_pid_timeout","PID file default TimeToLive (Sec)",sa.sadm_pid_timeout)
    printline ("sa.sadm_lock_timeout","Maximun nb. sec. a host can be lock",sa.sadm_lock_timeout)


    print ("\n----- Database Section -----")
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


    print ("\n----- Web Interface Section -----")
    printline ("sa.sadm_www_user","User that Run the Web Server",sa.sadm_www_user)   
    printline ("sa.sadm_www_group","Group that Run the Web Server",sa.sadm_www_group)

    print ("\n----- Email Section -----")
    printline ("sa.sadm_mail_addr","SADMIN SysAdmin Email(s)",sa.sadm_mail_addr)
    printline ("sa.sadm_smtp_server","Your internet smtp server",sa.sadm_smtp_server)  
    printline ("sa.sadm_smtp_port","Your internet smtp server port",sa.sadm_smtp_port) 
    printline ("sa.sadm_smtp_sender","Your internet smtp email address",sa.sadm_smtp_sender)
    presult="*Hidden*"                                                  # Default don't show passwd
    if show_password : presult=sa.sadm_gmpw                             # Selected to Show smtp pwd
    printline ("sa.sadm_gmpw","Your internet smtp email password",presult)  

    print ("\n----- Monitoring Section -----")
    printline ("sa.sadm_alert_type","0=NoMail 1=OnError 3=OnSuccess 4=All",sa.sadm_alert_type) 
    printline ("sa.sadm_alert_group","Error Group (Default Group)",sa.sadm_alert_group) 
    printline ("sa.sadm_warning_group","Warning Group Name",sa.sadm_warning_group) 
    printline ("sa.sadm_info_group","Info Group Name",sa.sadm_info_group) 
    printline ("sa.sadm_ssh_port","Default SSH Port to talk with client",sa.sadm_ssh_port)
    printline ("sa.sadm_monitor_update_interval","Monitor web page refresh rate (Sec)","%d Seconds" % sa.sadm_monitor_update_interval)
    printline ("sa.sadm_monitor_recent_count","Monitor web page nb. recent scripts",sa.sadm_monitor_recent_count)
    printline ("sa.sadm_monitor_recent_exclude","Monitor web page exclude list",sa.sadm_monitor_recent_exclude)
    printline ("sa.sadm_email_startup","Send email to SysAdmin on startup",sa.sadm_email_startup)  
    printline ("sa.sadm_email_shutdown","Send email to SysAdmin on shutdown",sa.sadm_email_shutdown)  
    presult="*Hidden*"                                                  # Don't show TextBelt Key
    if show_password : presult=sa.sadm_textbelt_key                     # Unless requested (-p)
    printline ("sa.sadm_textbelt_key","TextBelt.com API Key",presult)   
    printline ("sa.sadm_textbelt_url","TextBelt.com API URL",sa.sadm_textbelt_url) 

    print ("\n----- Files and Logs pruning Section -----")
    printline ("sa.sadm_nmon_keepdays","Nb. of days to keep .nmon perf. file","%d days" % sa.sadm_nmon_keepdays) 
    printline ("sa.sadm_rch_keepdays","Nb. days to keep unmodified .rch file","%d days" % sa.sadm_rch_keepdays)
    printline ("sa.sadm_log_keepdays","Nb. days to keep unmodified .log file","%d days" % sa.sadm_log_keepdays) 
    printline ("sa.sadm_max_rchline","Trim rch file to this max. of lines","%d lines" % sa.sadm_max_rchline)
    printline ("sa.sadm_max_logline","Trim log to this maximum of lines","%d lines" % sa.sadm_max_logline)
    printline ("sa.sadm_days_history","Days to keep alert in History file","%d lines" % sa.sadm_days_history)
    printline ("sa.sadm_max_arc_line","Max. lines in alert in History file","%d lines" % sa.sadm_max_arc_line) 

    print ("\n----- Subnet Network Scanner Section -----")
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

    print ("\n----- ReaR Backup Section -----")
    printline ("sa.sadm_rear_nfs_server","ReaR NFS Server IP or Name",sa.sadm_rear_nfs_server)
    printline ("sa.sadm_rear_nfs_server_ver","ReaR NFS Server Version",sa.sadm_rear_nfs_server_ver)
    printline ("sa.sadm_rear_nfs_mount_point","ReaR NFS Mount Point",sa.sadm_rear_nfs_mount_point) 
    printline ("sa.sadm_rear_backup_to_keep","ReaR NFS Backup - Nb. to keep","%d copies" % sa.sadm_rear_backup_to_keep)
    printline ("sa.sadm_rear_backup_dif","ReaR alert cur vs prev size differ","%s %%" % sa.sadm_rear_backup_dif)
    printline ("sa.sadm_rear_backup_interval","ReaR alert if no backup for X days","%d days" % sa.sadm_rear_backup_interval)
    printline ("sa.sadm_rear_backup_script","ReaR backup script name",sa.sadm_rear_backup_script)
    printline ("sa.sadm_rear_del_failed_backup","Delete failed backup",sa.sadm_rear_del_failed_backup)
    printline ("sa.sadm_rear_batch_mode","Run backup in batch mode",sa.sadm_rear_batch_mode)
    printline ("sa.sadm_rear_batch_startup_time","Batch startup time",sa.sadm_rear_batch_startup_time)  
    printline ("sa.sadm_rear_backup_concurrent","Concurrent rear backup process",sa.sadm_rear_backup_concurrent)

    print ("\n----- Backup Section -----")
    printline ("sa.sadm_backup_nfs_server","NFS Backup IP or Server Name",sa.sadm_backup_nfs_server)
    printline ("sa.sadm_backup_nfs_server_ver","NFS Backup Server Version",sa.sadm_backup_nfs_server_ver)
    printline ("sa.sadm_backup_nfs_mount_point","NFS Backup Mount Point",sa.sadm_backup_nfs_mount_point) 
    printline ("sa.sadm_backup_dif","Backup alert cur vs prev size differ","%s %%" % (sa.sadm_backup_dif))
    printline ("sa.sadm_backup_interval","Backup alert if older than X days","%s days" % (sa.sadm_backup_interval))
    printline ("sa.sadm_daily_backup_to_keep","Daily Backup to Keep","%d copies" % sa.sadm_daily_backup_to_keep)
    printline ("sa.sadm_weekly_backup_to_keep","Weekly Backup to Keep","%d copies" % sa.sadm_weekly_backup_to_keep)
    printline ("sa.sadm_monthly_backup_to_keep","Monthly Backup to Keep","%d copies" % sa.sadm_monthly_backup_to_keep)
    printline ("sa.sadm_yearly_backup_to_keep","Yearly Backup to keep","%d copies" % sa.sadm_yearly_backup_to_keep)
    printline ("sa.sadm_weekly_backup_day","Weekly Backup Day (1=Mon,7=Sun)",sa.sadm_weekly_backup_day)
    printline ("sa.sadm_monthly_backup_date","Monthly Backup Date (1-28)",sa.sadm_monthly_backup_date)
    printline ("sa.sadm_yearly_backup_month","Yearly Backup Month (1-12)",sa.sadm_yearly_backup_month) 
    printline ("sa.sadm_yearly_backup_date","Yearly Backup Date (1-31)",sa.sadm_yearly_backup_date)
    printline ("sa.sadm_backup_concurrent","Concurrent Backup Processes",sa.sadm_backup_batch_concurrent)
    printline ("sa.sadm_backup_batch_mode","Run backup in batch mode",sa.sadm_backup_batch_mode)
    printline ("sa.sadm_backup_batch_startup_time","Batch startup time",sa.sadm_backup_batch_start_time)  


    print ("\n----- Virtual Machines Export Section -----")
    printline ("sa.sadm_vm_export_nfs_server","NFS Export Server",sa.sadm_vm_export_nfs_server)
    printline ("sa.sadm_vm_export_nfs_server_ver","NFS Export Server Version",sa.sadm_vm_export_nfs_server_ver)
    printline ("sa.sadm_vm_export_mount_point","NFS Export Mount Point",sa.sadm_vm_export_mount_point)
    printline ("sa.sadm_vm_export_dif","Export alert cur vs prev size differ","%s %%" % (sa.sadm_vm_export_dif))
    printline ("sa.sadm_vm_export_to_keep","Nb. of export to keep","%d copies" % sa.sadm_vm_export_to_keep)
    printline ("sa.sadm_vm_export_interval","Days without export before alert","%d days" % sa.sadm_vm_export_interval)
    printline ("sa.sadm_vm_export_alert","Issue an alert if interval reached" ,"%s"  % sa.sadm_vm_export_alert)
    printline ("sa.sadm_vm_user","User part of 'vboxusers' user group",sa.sadm_vm_user)
    printline ("sa.sadm_vm_stop_timeout","Max. seconds given for acpi shutdown" ,"%d seconds" % sa.sadm_vm_stop_timeout)
    printline ("sa.sadm_vm_start_interval","Sec. to sleep between each VM start","%d seconds" % sa.sadm_vm_start_interval)
    printline ("sa.sadm_vm_export_batch_mode","Run start script in batch mode (Y/N)",sa.sadm_vm_export_batch_mode)
    printline ("sa.sadm_vm_export_batch_start_time","Start time for launch batch export",sa.sadm_vm_export_batch_start_time)
    printline ("sa.sadm_vm_export_concurrent","Concurrent export process",sa.sadm_vm_export_concurrent)


    print ("\n----- System Update Section -----")
    printline ("sa.sadm_osupdate_interval","System Update Interval","%d days" % sa.sadm_osupdate_interval)
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
# 5) Print Directories Variables Available to Users
#===================================================================================================
def print_directories():
    global lcount
    lcount              = 0                                                 # Reset Print Line Count

    print ("\n\n\n%s" % ("-" * 100))                                        # Print line of 100 "-" 
    print ("5) Directories variables available to Developers")
    print ("%s" % ("-" * 100))                                              # Print line of 100 "-" 

    # SADMIN Directories Aliases Variables.
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
       



# 6) Print Files Variables Available to Users
#===================================================================================================
def print_file_variable():
    global lcount
    lcount              = 0                                                 # Reset Print Line Count

    print ("\n\n\n%s" % ("-" * 100))                                        # Print line of 100 "-" 
    print ("6) SADMIN File names use and set by the Python library, for you to use")
    print ("%s" % ("-" * 100))                                              # Print line of 100 "-" 

    print ("----- File Name Aliases Variables -----")
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







#===================================================================================================
# 7) Print Command Path Variables available to users
#===================================================================================================
def print_command_path():
    global lcount
    lcount              = 0                                                 # Reset Print Line Count

    print ("\n\n\n%s" % ("-" * 100))                                        # Print line of 100 "-" 
    print ("7) Command Path set and use by SADMIN Python Library for more security.")
    print ("%s" % ("-" * 100))                                              # Print line of 100 "-" 

    printline ("sa.cmd_dmidecode","Cmd. 'dmidecode', Get model & type",sa.cmd_dmidecode) 
    printline ("sa.cmd_bc","Cmd. 'bc', Do some Math.",sa.cmd_bc) 
    printline ("sa.cmd_fdisk","Cmd. 'fdisk', Get Partition Info",sa.cmd_fdisk) 
    printline ("sa.cmd_which","Cmd. 'which', Get Command location",sa.cmd_which) 
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

        




#===================================================================================================
# 8) Print Database Information
#===================================================================================================
def print_db_variables():
    global lcount
    lcount              = 0                                             # Reset Print Line Count

    print ("\n\n\n%s" % ("-" * 100))                                    # Print line of 100 "-" 
    print ("8) Database Information")   
    print ("%s" % ("-" * 100))                                          # Print line of 100 "-" 

    printline ("sa.db_used","Program need to access Database ?",sa.db_used)
    if (sa.sadm_host_type != "S") : return(0)                           # If not on a SADMIN server
    if ( not sa.db_used ) :                                             # If db_used is set to False
        sa.write_err ("'db_used'is False, no Database information will be shown.") 
        return (1)

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




#===================================================================================================
# 9) Show Environment Variables Defined
#===================================================================================================
def print_env():

    print ("\n\n\n%s" % ("-" * 100))                                        # Print line of 100 "-" 
    print ("9) Environment Variables.")
    print ("%s" % ("-" * 100))                                              # Print line of 100 "-" 

    for a in os.environ:
        pexample=a                                                          # Env. Var. Name
        pdesc="Env.Var. %s" % (a)                                           # Env. Var. Name
        presult=os.getenv(a)                                                # Return Value(s)
        printline (pexample,pdesc,presult)                                  # Print Env. Line





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

        Returns:
            pdebug (int)          : Set to the debug level [0-9] (Default is 0)
    """

    global debug, show_password

    debug = 0                                                           # Default Debug Level
    show_password = False                                               # Don't show pwd default
    parser = argparse.ArgumentParser(description=sa.desc)               # Desc. is the script name

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
    parser.add_argument("-X",
                        action="store_true",
                        dest='delpid',
                        help="Delete the PID file.")
        
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
   
    if args.delpid:                                                     # If -X specified
        if os.path.exists(sa.pid_file):                                 # If PID file exist
            os.remove(sa.pid_file)                                      # Delete the PID file.
            print("The PID File (" + sa.pid_file + ") is now removed.") 

    return()                                                            # Return cmdline choices





#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main(argv):
    cmd_options(argv)                                                   # Analyse cmdline options
    sa.start()                                                          # Initialize SADMIN env.
    print_functions()                                                   # 1) Functions Available
    print_user_variables()                                              # 2) User Avail. Variables
    print_python_start_stop()                                           # 3) Show Stop/Start Funct.
    print_sadmin_cfg(show_password)                                     # 4) Show sadmin.cfg Var.
    print_directories()                                                 # 5) Show Client Dir. Variables
    print_file_variable()                                               # 6) Show Files Variables
    print_command_path()                                                # 7) Show Command Path
    if (sa.sadm_host_type == "S") : print_db_variables()                # 8) Show Database Info
    if (debug > 4) : print_env()                                        # 9) Show Env. Variables

    sa.stop(sa.exit_code)                                               # Close SADM Environment
    sys.exit(sa.exit_code)                                              # Exit To O/S


# Python assigns the string "__main__" to __name__. 
# If the file is imported elsewhere (import script), __name__ matches the actual filename instead.
# This condition guards your code against accidental execution during imports.
if __name__ == "__main__": 
    try:
        main(sys.argv)
    except KeyboardInterrupt as e: 
        print(f"[ ERROR ] A Keyboard interrupt as occurred: {e}")
        sa.stop(1)                                                      # Exit Gracefully & Close DB
        sys.exit(1)
    
    except Exception as e:
        print(f"[ ERROR ] An unexpected error occurred: {e}")
        sa.stop(1)                                                      # Exit Gracefully & Close DB
        sys.exit(1)
        
