#!/usr/bin/env python3
#===================================================================================================
#   Author:     : Jacques Duplessis
#   Title:      : sadmlib_std_demo.py
#   Version     : 1.0
#   Date        : 14 July 2017
#   Requires    : python3 and SADM Library
#   Description : Demonstrate Functions, Variables available to users using SADMIN Tools
# 
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - http://www.sadmin.ca
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
# 2017_07_07 JDuplessis 
#   V1.7 Minor Code enhancement
# 2017_07_31 JDuplessis 
#   V1.8 Added Log Template to script
# 2017_09_02 JDuplessis 
#   V1.9 Add Command line switch 
# 2017_09_02 JDuplessis
#   V2.0 Rewritten Part of script for performance and flexibility
# 2017_12_12 JDuplessis
#   V2.1 Adapted to use MySQL instead of Postgres Database
# 2017_12_23 JDuplessis
#   V2.3 Changes for performance and flexibility
# 2018_01_25 JDuplessis
#   V2.4 Added Variable SADM_RRDTOOL to sadmin.cfg display
# 2018_02_21 JDuplessis
#   V2.5 Minor Changes 
#===================================================================================================
#
try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch             # Import Std Python3 Modules
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

#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Python Library
#===================================================================================================
def setup_sadmin():

    # Load SADMIN Standard Python Library
    try :
        SADM = os.environ.get('SADMIN')         # Getting SADMIN Root Dir.
        sys.path.insert(0,os.path.join(SADM,'lib'))         # Add SADMIN to sys.path
        import sadmlib_std as sadm              # Import SADMIN Python Libr.
    except ImportError as e:                    # If Error importing SADMIN 
        print ("Error Importing SADMIN Module: %s " % e)    # Advise USer of Error
        sys.exit(1)                             # Go Back to O/S with Error
    
    # Create Instance of SADMIN Tool
    st = sadm.sadmtools()                       # Create SADMIN Tools Instance (Setup Dir.,Var,...)

    # Change these values to your script needs.
    st.ver              = "2.6"                 # Current Script Version
    st.multiple_exec    = "N"                   # Allow running multiple copy at same time ?
    st.log_type         = 'B'                   # Output goes to [S]creen [L]ogFile [B]oth
    st.log_append       = True                  # Append Existing Log or Create New One
    st.use_rch          = False                 # Generate entry in Return Code History (.rch) 
    st.log_header       = False                 # Show/Generate Header in script log (.log)
    st.log_footer       = False                 # Show/Generate Footer in script log (.log)
    st.debug            = 0                     # Debug level and verbosity (0-9)
    st.usedb            = True                  # True=Open/Use Database,False=Don't Need to Open DB 
    st.dbsilent         = False                 # Return Error Code & False=ShowErrMsg True=NoErrMsg

    # Override Default define in $SADMIN/cfg/sadmin.cfg
    #st.cfg_mail_type    = 1                    # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    #st.cfg_mail_addr    = ""                   # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name     = ""                   # This Override Company Name specify in sadmin.cfg
    #st.cfg_max_logline  = 5000                 # When Script End Trim log file to 5000 Lines
    #st.cfg_max_rchline  = 100                  # When Script End Trim rch file to 100 Lines
    #st.ssh_cmd = "%s -qnp %s " % (st.ssh,st.cfg_ssh_port) # SSH Command to Access Server 

    # Start SADMIN Tools - Initialize 
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..
    return(st)


#===================================================================================================
# Standardize Print Line Function 
#===================================================================================================
def printline(st,col1="",col2="",col3=""):
    global lcount 
    lcount += 1
    print ("[%03d] " % lcount, end='')
    if col1 != "" : print ("%-33s" % (col1), end='')
    if col2 != "" : print ("%-36s" % (col2), end='')
    if col1 != "" and col2 != "" : print ("%-s%-s%-s" % (": .",col3,"."))


#===================================================================================================
# Standardize Print Header Function 
#===================================================================================================
def printheader(st,col1,col2,col3=" "):
    global lcount

    lcount = 0 
    print ("\n\n\n%s" % ("=" * 100))
    print ("%s v%s - Library v%s" % (st.pn,st.ver,st.libver))
    print ("%-39s%-36s%-33s" % (col1,col2,col3))
    print ("%s" % ("=" * 100))

#===================================================================================================
# Print SADMIN Function available to Users
#===================================================================================================
def print_functions(st):
    printheader (st,"Calling Functions","Description","  Result")

    pexample="ins.get_release()"                                        # Example Calling Function
    pdesc="SADMIN Release Number (XX.XX)"                               # Function Description
    presult=st.get_release()                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_ostype()"                                         # Example Calling Function
    pdesc="OS Type (Uppercase,LINUX,AIX,DARWIN)"                        # Function Description
    presult=st.get_ostype()                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_osversion()"                                      # Example Calling Function
    pdesc="Return O/S Version (Ex: 7.2, 6.5)"                           # Function Description
    presult=st.get_osversion()                                          # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_osmajorversion()"                                 # Example Calling Function
    pdesc="Return O/S Major Version (Ex 7, 6)"                          # Function Description
    presult=st.get_osmajorversion()                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_osminorversion()"                                 # Example Calling Function
    pdesc="Return O/S Minor Version (Ex 2, 3)"                          # Function Description
    presult=st.get_osminorversion()                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_osname()"                                         # Example Calling Function
    pdesc="O/S Name (REDHAT,CENTOS,UBUNTU,...)"                         # Function Description
    presult=st.get_osname()                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_oscodename()"                                     # Example Calling Function
    pdesc="O/S Project Code Name"                                       # Function Description
    presult=st.get_oscodename()                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_kernel_version()"                                 # Example Calling Function
    pdesc="O/S Running Kernel Version"                                  # Function Description
    presult=st.get_kernel_version()                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_kernel_bitmode()"                                 # Example Calling Function
    pdesc="O/S Kernel Bit Mode (32 or 64)"                              # Function Description
    presult=st.get_kernel_bitmode()                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.hostname"                                             # Example Calling Function
    pdesc="Current Host Name"                                           # Function Description
    presult=st.hostname                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_host_ip()"                                        # Example Calling Function
    pdesc="Current Host IP Address"                                     # Function Description
    presult=st.get_host_ip()                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_domainname()"                                     # Example Calling Function
    pdesc="Current Host Domain Name"                                    # Function Description
    presult=st.get_domainname()                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_fqdn()"                                           # Example Calling Function
    pdesc="Fully Qualified Domain Host Name"                            # Function Description
    presult=st.get_fqdn()                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.get_epoch_time()"                                     # Example Calling Function
    pdesc="Get Current Epoch Time"                                      # Function Description
    presult=st.get_epoch_time()                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    wepoch= st.get_epoch_time()
    pexample="ins.epoch_to_date(%d)" % (wepoch)                         # Example Calling Function
    pdesc="Convert epoch time to date"                                  # Function Description
    presult=st.epoch_to_date(wepoch)                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    WDATE=st.epoch_to_date(wepoch)                                      # Set Test Date
    print ("      WDATE=%s" % (WDATE))                                  # Print Test Date    
    pexample="ins.date_to_epoch(WDATE)"                                 # Example Calling Function
    pdesc="Convert Date to epoch time"                                  # Function Description
    presult=st.date_to_epoch(WDATE)                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    DATE1="2018.06.30 10:00:44" ; DATE2="2018.06.30 10:00:03"           # Set Date to Calc Elapse
    print ("      DATE1=%s" % (DATE1))                                  # Print Date1 Used for Ex.
    print ("      DATE2=%s" % (DATE2))                                  # Print Date2 Used for Ex.
    pexample="ins.elapse_time(DATE1,DATE2)"                             # Example Calling Function
    pdesc="Elapse Time between two timestamps"                          # Function Description
    presult=st.elapse_time(DATE1,DATE2)                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.inst"                                                 # Example Calling Function
    pdesc="Get Script without extension"                                # Function Description
    presult=st.inst                                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.username"                                             # Example Calling Function
    pdesc="Current User Name"                                           # Function Description
    presult=st.username                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.tpid"                                                 # Example Calling Function
    pdesc="Get Current Process ID"                                      # Function Description
    presult=st.tpid                                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.multiple_exec"                                        # Example Calling Function
    pdesc="Allow running simultaneous copy"                             # Function Description
    presult=st.multiple_exec                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.use_rch"                                              # Example Calling Function
    pdesc="Generate entry in ReturnCodeHistory"                         # Function Description
    presult=st.use_rch                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
         
    pexample="ins.dbsilent"                                             # Example Calling Function
    pdesc="No DB err.mess. only return error#"                          # Function Description
    presult=st.dbsilent                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="ins.usedb"                                                # Example Calling Function
    pdesc="Script need to use Database ?"                               # Function Description
    presult=st.usedb                                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="ins.log_type"                                             # Example Calling Function
    pdesc="Output to [S]creen [L]ogFile [B]oth"                         # Function Description
    presult=st.log_type                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="ins.log_append"                                           # Example Calling Function
    pdesc="Append Log or Create New One"                                # Function Description
    presult=st.log_append                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="ins.log_header"                                           # Example Calling Function
    pdesc="Show/Generate Header in log "                                # Function Description
    presult=st.log_header                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                 
    pexample="ins.log_footer"                                           # Example Calling Function
    pdesc="Show/Generate Footer in  log"                                # Function Description
    presult=st.log_footer                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
                       
    return(0)


#===================================================================================================
# Print Directories Variables Available to Users
#===================================================================================================
def print_client_directory(st):
    printheader (st,"Client Directories Var. Avail.","Description","  Result")

    pexample="ins.base_dir"                                             # Example Calling Function
    pdesc="SADMIN Root Directory"                                       # Function Description
    presult=st.base_dir                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.bin_dir"                                              # Example Calling Function
    pdesc="SADMIN Scripts Directory"                                    # Function Description
    presult=st.bin_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.tmp_dir"                                              # Example Calling Function
    pdesc="SADMIN Temporary file(s) Directory"                          # Function Description
    presult=st.tmp_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.lib_dir"                                              # Example Calling Function
    pdesc="SADMIN Shell & Python Library Dir."                          # Function Description
    presult=st.lib_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.log_dir"                                              # Example Calling Function
    pdesc="SADMIN Script Log Directory"                                 # Function Description
    presult=st.log_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.cfg_dir"                                              # Example Calling Function
    pdesc="SADMIN Configuration Directory"                              # Function Description
    presult=st.cfg_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.sys_dir"                                              # Example Calling Function
    pdesc="Server Startup/Shutdown Script Dir."                         # Function Description
    presult=st.sys_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="ins.dat_dir"                                              # Example Calling Function
    pdesc="Server Data Directory"                                       # Function Description
    presult=st.dat_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.pkg_dir"                                              # Example Calling Function
    pdesc="SADMIN Packages Directory"                                   # Function Description
    presult=st.pkg_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="ins.nmon_dir"                                             # Example Calling Function
    pdesc="Server NMON - Data Collected Dir."                           # Function Description
    presult=st.nmon_dir                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="ins.dr_dir"                                               # Example Calling Function
    pdesc="Server Disaster Recovery Info Dir."                          # Function Description
    presult=st.dr_dir                                                   # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="ins.rch_dir"                                              # Example Calling Function
    pdesc="Server Return Code History Dir."                             # Function Description
    presult=st.rch_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
        
    pexample="ins.net_dir"                                              # Example Calling Function
    pdesc="Server Network Information Dir."                             # Function Description
    presult=st.net_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.doc_dir"                                              # Example Calling Function
    pdesc="SADMIN Documentation Directory"                              # Function Description
    presult=st.doc_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
 
#===================================================================================================
# Print Directories Variables Available to Users
#===================================================================================================
def print_server_directory(st):
    printheader (st,"Server Directories Var. Avail.","Description","  Result")

    pexample="ins.www_dir"                                              # Example Calling Function
    pdesc="SADMIN Web Site Root Directory"                              # Function Description
    presult=st.www_dir                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
       
    pexample="ins.www_doc_dir"                                          # Example Calling Function
    pdesc="SADMIN Web Site Root Directory"                              # Function Description
    presult=st.www_doc_dir                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
       
    pexample="ins.www_dat_dir"                                          # Example Calling Function
    pdesc="SADMIN Web Site Systems Data Dir."                           # Function Description
    presult=st.www_dat_dir                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
       
    pexample="ins.www_lib_dir"                                          # Example Calling Function
    pdesc="SADMIN Web Site PHP Library Dir."                            # Function Description
    presult=st.www_lib_dir                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
           
    pexample="ins.www_tmp_dir"                                          # Example Calling Function
    pdesc="SADMIN Web Temp Working Directory"                           # Function Description
    presult=st.www_tmp_dir                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
       


#===================================================================================================
# Print Files Variables Available to Users
#===================================================================================================
def print_file(st):
    printheader (st,"SADMIN FILES VARIABLES AVAIL.","Description","  Result")

    pexample="ins.pid_file"                                             # Example Calling Function
    pdesc="Current script PID file"                                     # Function Description
    presult=st.pid_file                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_file"                                             # Example Calling Function
    pdesc="SADMIN Configuration File"                                   # Function Description
    presult=st.cfg_file                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_hidden"                                           # Example Calling Function
    pdesc="SADMIN Initial Configuration File"                           # Function Description
    presult=st.cfg_hidden                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.tmp_file1"                                            # Example Calling Function
    pdesc="User usable Temp Work File 1"                                # Function Description
    presult=st.tmp_file1                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.tmp_file2"                                            # Example Calling Function
    pdesc="User usable Temp Work File 2"                                # Function Description
    presult=st.tmp_file2                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.tmp_file3"                                            # Example Calling Function
    pdesc="User usable Temp Work File 3"                                # Function Description
    presult=st.tmp_file3                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.log_file"                                             # Example Calling Function
    pdesc="Script Log File"                                             # Function Description
    presult=st.log_file                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.rch_file"                                             # Example Calling Function
    pdesc="Script Return Code History File"                             # Function Description
    presult=st.rch_file                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.dbpass_file"                                          # Example Calling Function
    pdesc="SADMIN Database User Password File"                          # Function Description
    presult=st.dbpass_file                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

#===================================================================================================
# Print sadmin.cfg Variables available to users
#===================================================================================================
def print_sadmin_cfg(st):

    printheader (st,"SADMIN CONFIG FILE VARIABLES","Description","  Result")

    pexample="ins.cfg_server"                                           # Example Calling Function
    pdesc="SADMIN SERVER NAME (FQDN)"                                   # Function Description
    presult=st.cfg_server                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_host_type"                                        # Example Calling Function
    pdesc="SADMIN [C]lient or [S]erver"                                 # Function Description
    presult=st.cfg_host_type                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_mail_addr"                                        # Example Calling Function
    pdesc="SADMIN Administrator Default Email"                          # Function Description
    presult=st.cfg_mail_addr                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_mail_type"                                        # Example Calling Function
    pdesc="0=NoMail 1=OnError 3=OnSuccess 4=All"                        # Function Description
    presult=st.cfg_mail_type                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_cie_name"                                         # Example Calling Function
    pdesc="Your Company Name"                                           # Function Description
    presult=st.cfg_cie_name                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_domain"                                           # Example Calling Function
    pdesc="Server Creation Default Domain"                              # Function Description
    presult=st.cfg_domain                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_user"                                             # Example Calling Function
    pdesc="SADMIN User Name"                                            # Function Description
    presult=st.cfg_user                                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_group"                                            # Example Calling Function
    pdesc="SADMIN Group Name"                                           # Function Description
    presult=st.cfg_group                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_www_user"                                         # Example Calling Function
    pdesc="User that Run Apache Web Server"                             # Function Description
    presult=st.cfg_www_user                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_www_group"                                        # Example Calling Function
    pdesc="Group that Run Apache Web Server"                            # Function Description
    presult=st.cfg_www_group                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_dbname"                                           # Example Calling Function
    pdesc="SADMIN Database Name"                                        # Function Description
    presult=st.cfg_dbname                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_dbhost"                                           # Example Calling Function
    pdesc="SADMIN Database Host"                                        # Function Description
    presult=st.cfg_dbhost                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_dbport"                                           # Example Calling Function
    pdesc="SADMIN Database Host TCP Port"                               # Function Description
    presult=st.cfg_dbport                                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_rw_dbuser"                                        # Example Calling Function
    pdesc="SADMIN Database Read/Write User"                             # Function Description
    presult=st.cfg_rw_dbuser                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_rw_dbpwd"                                         # Example Calling Function
    pdesc="SADMIN Database Read/Write User Pwd"                         # Function Description
    presult=st.cfg_rw_dbpwd                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_ro_dbuser"                                        # Example Calling Function
    pdesc="SADMIN Database Read Only User"                              # Function Description
    presult=st.cfg_ro_dbuser                                            # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_ro_dbpwd"                                         # Example Calling Function
    pdesc="SADMIN Database Read Only User Pwd"                          # Function Description
    presult=st.cfg_ro_dbpwd                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_rrdtool"                                          # Example Calling Function
    pdesc="RRDTOOL Binary Location"                                     # Function Description
    presult=st.cfg_rrdtool                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_ssh_port"                                         # Example Calling Function
    pdesc="SSH Port to communicate with client"                         # Function Description
    presult=st.cfg_ssh_port                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_nmon_keepdays"                                    # Example Calling Function
    pdesc="Nb. of days to keep nmon perf. file"                         # Function Description
    presult=st.cfg_nmon_keepdays                                        # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_rch_keepdays"                                     # Example Calling Function
    pdesc="Nb. days to keep unmodified rch file"                        # Function Description
    presult=st.cfg_rch_keepdays                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_log_keepdays"                                     # Example Calling Function
    pdesc="Nb. days to keep unmodified log file"                        # Function Description
    presult=st.cfg_log_keepdays                                         # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_max_rchline"                                      # Example Calling Function
    pdesc="Trim rch file to this max. of lines"                         # Function Description
    presult=st.cfg_max_rchline                                          # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_max_logline"                                      # Example Calling Function
    pdesc="Trim log to this maximum of lines"                           # Function Description
    presult=st.cfg_max_logline                                          # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_network1"                                         # Example Calling Function
    pdesc="Network/Netmask 1 inv. IP/Name/Mac"                          # Function Description
    presult=st.cfg_network1                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_network2"                                         # Example Calling Function
    pdesc="Network/Netmask 2 inv. IP/Name/Mac"                          # Function Description
    presult=st.cfg_network2                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_network3"                                         # Example Calling Function
    pdesc="Network/Netmask 3 inv. IP/Name/Mac"                          # Function Description
    presult=st.cfg_network3                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_network4"                                         # Example Calling Function
    pdesc="Network/Netmask 4 inv. IP/Name/Mac"                          # Function Description
    presult=st.cfg_network4                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_network5"                                         # Example Calling Function
    pdesc="Network/Netmask 5 inv. IP/Name/Mac"                          # Function Description
    presult=st.cfg_network5                                             # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_mksysb_nfs_server"                                # Example Calling Function
    pdesc="AIX MKSYSB NFS Server IP or Name"                            # Function Description
    presult=st.cfg_mksysb_nfs_server                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_mksysb_nfs_mount_point"                           # Example Calling Function
    pdesc="AIX MKSYSB NFS Mount Point"                                  # Function Description
    presult=st.cfg_mksysb_nfs_mount_point                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_mksysb_backup_to_keep"                            # Example Calling Function
    pdesc="AIX MKSYSB NFS Backup - Nb .to keep"                         # Function Description
    presult=st.cfg_mksysb_backup_to_keep                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_rear_nfs_server"                                  # Example Calling Function
    pdesc="Rear NFS Server IP or Name"                                  # Function Description
    presult=st.cfg_rear_nfs_server                                      # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_rear_nfs_mount_point"                             # Example Calling Function
    pdesc="Rear NFS Mount Point"                                        # Function Description
    presult=st.cfg_rear_nfs_mount_point                                 # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_rear_backup_to_keep"                              # Example Calling Function
    pdesc="Rear NFS Backup - Nb. to keep"                               # Function Description
    presult=st.cfg_rear_backup_to_keep                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_backup_nfs_server"                                # Example Calling Function
    pdesc="NFS Backup IP or Server Name"                                # Function Description
    presult=st.cfg_backup_nfs_server                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_backup_nfs_mount_point"                           # Example Calling Function
    pdesc="NFS Backup Mount Point"                                      # Function Description
    presult=st.cfg_backup_nfs_mount_point                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_backup_nfs_to_keep"                               # Example Calling Function
    pdesc="NFS Backup - Nb. to keep"                                    # Function Description
    presult=st.cfg_backup_nfs_to_keep                                   # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_storix_nfs_server"                                # Example Calling Function
    pdesc="Storix NFS Server IP or Name"                                # Function Description
    presult=st.cfg_storix_nfs_server                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_storix_nfs_mount_point"                           # Example Calling Function
    pdesc="Storix NFS Mount Point"                                      # Function Description
    presult=st.cfg_storix_nfs_mount_point                               # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    pexample="ins.cfg_storix_backup_to_keep"                            # Example Calling Function
    pdesc="Storix NFS Backup - Nb. to Keep"                             # Function Description
    presult=st.cfg_storix_backup_to_keep                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line


#===================================================================================================
# Print Command Path Variables available to users
#===================================================================================================
def print_command_path(st):
    
    printheader (st,"COMMAND PATH USE BY SADMIN STD. LIBR.","Description","  Result")

    pexample="ins.lsb_release"                                          # Example Calling Function
    pdesc="Cmd. 'lsb_release', Get O/S Version"                         # Function Description
    presult=st.lsb_release                                              # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.dmidecode"                                            # Example Calling Function
    pdesc="Cmd. 'dmidecode', Get model & type"                          # Function Description
    presult=st.dmidecode                                                # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.facter"                                               # Example Calling Function
    pdesc="Cmd. 'facter', Get System Info"                              # Function Description
    presult=st.facter                                                   # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.bc"                                                   # Example Calling Function
    pdesc="Cmd. 'bc', Do some Math."                                    # Function Description
    presult=st.bc                                                       # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.fdisk"                                                # Example Calling Function
    pdesc="Cmd. 'fdisk', Get Partition Info"                            # Function Description
    presult=st.fdisk                                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.which"                                                # Example Calling Function
    pdesc="Cmd. 'which', Get Command location"                          # Function Description
    presult=st.which                                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.perl"                                                 # Example Calling Function
    pdesc="Cmd. 'perl', epoch time Calc."                               # Function Description
    presult=st.perl                                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.mail"                                                 # Example Calling Function
    pdesc="Cmd. 'mail', Send SysAdmin Email"                            # Function Description
    presult=st.mail                                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.lscpu"                                                # Example Calling Function
    pdesc="Cmd. 'lscpu', Socket & thread info"                          # Function Description
    presult=st.lscpu                                                    # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.nmon"                                                 # Example Calling Function
    pdesc="Cmd. 'nmon', Collect Perf Statistic"                         # Function Description
    presult=st.nmon                                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.parted"                                               # Example Calling Function
    pdesc="Cmd. 'parted', Get Disk Real Size"                           # Function Description
    presult=st.parted                                                   # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.ethtool"                                              # Example Calling Function
    pdesc="Cmd. 'ethtool', Get System IP Info"                          # Function Description
    presult=st.ethtool                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.ssh"                                                  # Example Calling Function
    pdesc="Cmd. 'ssh', SSH to SADMIN client"                            # Function Description
    presult=st.ssh                                                      # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    
    pexample="ins.ssh_cmd"                                              # Example Calling Function
    pdesc="Cmd. 'ssh', SSH to Connect to client"                        # Function Description
    presult=st.ssh_cmd                                                  # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line
    

#===================================================================================================
# Print sadm_start and sadm_stop Function Used by SADMIN Tools
#===================================================================================================
def print_start_stop(st):
    printheader (st,"Overview of ins.start() & ins.stop() function"," "," ")
     
    print ("")
    print ("Setup SADMIN")
    print ("Example: st = setup_sadmin()          # Setup Var. & Load SADM Lib\n")
    print ("    Start and initialize sadm environment - (No Parameter, Return the instance object")
    print ("    If SADMIN root directory is not /sadmin, make sure the SADMIN Env. variable is set to proper dir.")
    print ("    Please call this function when your script is starting")
    print ("    What this function will do for us :") 
    print ("        1) Make sure all directories & sub-directories exist and have proper permissions.")
    print ("        2) Make sure log file exist with proper permission ($SADM_LOG)")
    print ("        3) Make sure Return Code History (.rch) exist and have the right permission")
    print ("        4) If PID file exist, show error message and abort.") 
    print ("           Unless user allow more than one copy to run simultaniously (SADM_MULTIPLE_EXEC='Y')")
    print ("        5) Add line in the [R]eturn [C]ode [H]istory file stating script is started (Code 2)")
    print ("        6) Write HostName - Script name and version - O/S Name and version to the Log file (SADM_LOG)")
    print ("")
    print ("ins.stop()")
    print ("Example : st.stop(st.exit_code)        # Close SADM Environment\n")
    print ("          sys.exit(st.exit_code)       # Exit To O/S\n")
    print ("")
    print ("    Accept one parameter - Either 0 (Successfull) or non-zero (Error Encountered)")
    print ("    Please call this function just before your script end")
    print ("    What this function do.")
    print ("        1) If Exit Code is not zero, change it to 1.")
    print ("        2) Get Actual Time and Calculate the Execution Time.")
    print ("        3) Writing the Script Footer in the Log (Script Return code, Execution Time, ...)")
    print ("        4) Update the RCH File (Start/End/Elapse Time and the Result Code)")
    print ("        5) Trim The RCH File Based on User choice in sadmin.cfg")
    print ("        6) Write to Log the user mail alerting type choose by user (sadmin.cfg)")
    print ("        7) Trim the Log based on user selection in sadmin.cfg")
    print ("        8) Send Email to sysadmin (if user selected that option in sadmin.cfg)")
    print ("        9) Delete the PID File of the script (SADM_PID_FILE)")
    print ("       10) Delete the User 3 TMP Files (SADM_TMP_FILE1, SADM_TMP_FILE2, SADM_TMP_FILE3)")
    print (" ")


#===================================================================================================
# Show Environment Variables Defined
#===================================================================================================
def print_env(st):
    printheader (st,"Environment Variables.","Description","  Result")
    for a in os.environ:
        pexample=a                                                          # Env. Var. Name
        pdesc="Env.Var. %s" % (a)                                           # Env. Var. Name
        presult=os.getenv(a)                                                # Return Value(s)
        printline (st,pexample,pdesc,presult)                               # Print Env. Line



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    
    # Script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not root
       print ("This script must be run by the 'root' user")             # Advise User Message / Log
       print ("Try sudo %s" % (os.path.basename(sys.argv[0])))          # Suggest to use 'sudo'
       print ("Process aborted")                                        # Process Aborted Msg
       sys.exit(1)                                                      # Exit with Error Code

    st = setup_sadmin()                                                 # Setup SADMIN Tool Instance
    
    # If on SADMIN Server and decided to use Database
    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database
        st.writelog ("Database connection succeeded")                   # Show COnnect to DB Worked
    
    print_functions(st)                                                 # Display Env. Variables
    print_start_stop(st)                                                # Show Stop/Start Function
    print_sadmin_cfg(st)                                                # Show sadmin.cfg Variables
    print_client_directory(st)                                          # Show Client Dir. Variables
    print_server_directory(st)                                          # Show Server Dir. Variables
    print_file(st)                                                      # Show Files Variables
    print_command_path(st)                                              # Show Command Path
    print_env(st)                                                       # Show Env. Variables

    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        st.writelog ("Closing Database connection")                     # Show we are closing DB
        st.dbclose()                                                    # Close the Database
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()


