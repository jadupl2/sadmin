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
    if col1 != "" : print ("%-33s" % (col1), end='')
    if col2 != "" : print ("%-36s" % (col2), end='')
    if col1 != "" and col2 != "" : print ("%-s%-s%-s" % (": .",col3,"."))


#===================================================================================================
# Standardize Print Header Function 
#===================================================================================================
def printheader(st,col1,col2,col3):
    print ("\n\n\n%s" % ("=" * 100))
    print ("%s v%s - Library v%s" % (st.pn,st.ver,st.libver))
    print ("%-33s%-36s%-33s" % (col1,col2,col3))
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
    print ("WDATE=%s" % (WDATE))                                        # Print Test Date    
    pexample="ins.date_to_epoch(WDATE)"                                 # Example Calling Function
    pdesc="Convert Date to epoch time"                                  # Function Description
    presult=st.date_to_epoch(WDATE)                                     # Return Value(s)
    printline (st,pexample,pdesc,presult)                               # Print Example Line

    DATE1="2018.06.30 10:00:44" ; DATE2="2018.06.30 10:00:03"           # Set Date to Calc Elapse
    print ("DATE1=%s" % (DATE1))                                        # Print Date1 Used for Ex.
    print ("DATE2=%s" % (DATE2))                                        # Print Date2 Used for Ex.
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
    presult=st.username                                                     # Return Value(s)
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

# ----------------------------------------------------------------------------------------------
# For Debugging Purpose - Display all Important Environment Variables used across SADM Libraries
# ----------------------------------------------------------------------------------------------
def display_env(st):

        print(" ")                                                      # Space Line in the LOG
        print("SADM Client & Servers Directories Attribute")
        print("-" * 100)                                                   
        print("ins.base_dir             Root Dir. of SADMIN Tools     : %s" % (st.base_dir))
        print("ins.tmp_dir              SADMIN Temp. Directory        : %s" % (st.tmp_dir))
        print("ins.cfg_dir              SADMIN Configuration Dir.     : %s" % (st.cfg_dir))
        print("ins.lib_dir              SADMIN Shell & Python Lib.    : %s" % (st.lib_dir))
        print("ins.bin_dir              SADMIN Shell & Python Scripts : %s" % (st.bin_dir))
        print("ins.log_dir              SADMIN Log Directory          : %s" % (st.log_dir))
        print("ins.pkg_dir              Software Pkg use in SADMIN    : %s" % (st.pkg_dir))
        print("ins.doc_dir              Documentation Directory       : %s" % (st.doc_dir))
        print("ins.sys_dir              Host Scripts(Startup/Shutdown): %s" % (st.sys_dir))
        print("ins.dat_dir              Host system Info Data Dir.    : %s" % (st.dat_dir))
        print("ins.nmon_dir             Host nmon performance files   : %s" % (st.nmon_dir))
        print("ins.rch_dir              Host Result Code History files: %s" % (st.rch_dir))
        print("ins.dr_dir               Host Disaster Recovery files  : %s" % (st.dr_dir))

        print(" ")                                                     
        print("SADM Servers Only Directories Attribute")
        print("-" * 100)                                                   
        print("ins.www_dir              Web Root Dir. (On Server Only): %s" % (st.www_dir))
        print("ins.www_dat_dir          Web Systems Info Dir  (Server): %s" % (st.www_dat_dir))
        print("ins.www_lib_dir          Web Systems Lib Dir   (Server): %s" % (st.www_lib_dir))
        print("ins.www_cfg_dir          Web Systems Config Dir(Server): %s" % (st.www_cfg_dir))
        print("ins.www_net_dir          Web Systems Net Data  (Server): %s" % (st.www_net_dir))
        print("ins.www_doc_dir          Web Documentation Dir.(Server): %s" % (st.www_doc_dir))

        print(" ")                                                      # Space Line in the LOG
        print("SADM Files Variables")                                   # Introduce Display Below
        print("-" * 100)                                                   
        print("ins.log_file             Cur. Script Log File          : %s" % (st.log_file))
        print("ins.rch_file             Cur. Script Result Code File  : %s" % (st.rch_file))
        print("ins.cfg_file             SADMIN Configuration File     : %s" % (st.cfg_file))
        print("ins.pid_file             Current Process ID. File      : %s" % (st.pid_file))
        print("ins.crontab_file         Crontab file for SADMIN       : %s" % (st.crontab_file))
        print("ins.tmp_file1            Cur. Script Avail Tmp File 1  : %s" % (st.tmp_file1))
        print("ins.tmp_file2            Cur. Script Avail Tmp File 2  : %s" % (st.tmp_file2))
        print("ins.tmp_file3            Cur. Script Avail Tmp File 3  : %s" % (st.tmp_file3))

        print(" ")                                                      
        print("SADM O/S Executable Full Path (If they exist on Host)")    
        print("-" * 100)                                                   
        print("ins.which                Location of the executable    : %s" % (st.which))
        print("ins.bc                   Location of the executable    : %s" % (st.bc))
        print("ins.lsb_release          Location of the executable    : %s" % (st.lsb_release))
        print("ins.dmidecode            Location of the executable    : %s" % (st.dmidecode))
        print("ins.fdisk                Location of the executable    : %s" % (st.fdisk))
        print("ins.facter               Location of the executable    : %s" % (st.facter))
        print("ins.uname                Location of the executable    : %s" % (st.uname)) 
        print("ins.perl                 Location of the executable    : %s" % (st.perl)) 
        print("ins.ssh                  Location of the executable    : %s" % (st.ssh)) 
        print("ins.mail                 Location of the executable    : %s" % (st.mail)) 
        print("ins.ssh_cmd              Cmd used to connect client    : %s" % (st.ssh_cmd))

        print(" ")                                                      # Space Line in the LOG
        print("Global variables setting after reading the SADM Configuration file")
        print("-" * 100)                                                   
        print("ins.cfg_mail_addr        Send Mail Address             : %s" % (st.cfg_mail_addr))
        print("ins.cfg_cie_name         Your Company Name             : %s" % (st.cfg_cie_name))
        print("ins.cfg_mail_type        0=No 1=Error 2=Success 3=All  : %s" % (str(st.cfg_mail_type)))
        print("ins.cfg_host_type        SADMIN [S]erver or [C]lient   : %s" % (st.cfg_host_type))
        print("ins.cfg_server           SADMIN Server FQDN Name       : %s" % (st.cfg_server))
        print("ins.cfg_domain           Your Default Domain           : %s" % (st.cfg_domain))
        print("ins.cfg_user             Super User Name (sudo)        : %s" % (st.cfg_user))
        print("ins.cfg_group            Super User Group              : %s" % (st.cfg_group))
        print("ins.cfg_www_user         Web Server User (apache)      : %s" % (st.cfg_www_user))
        print("ins.cfg_www_group        Web Server Group (apache)     : %s" % (st.cfg_www_group))
        print("ins.cfg_max_logline      Max. Nb. of Lines in Log file : %s" % (str(st.cfg_max_logline)))
        print("ins.cfg_max_rchline      Max. Nb. of Line in .rch file : %s" % (str(st.cfg_max_rchline)))
        print("ins.cfg_nmon_keepdays    Nb. Days to keep .nmon files  : %s" % (str(st.cfg_nmon_keepdays)))
        print("ins.cfg_sar_keepdays     Nb. Days to keep .sar files   : %s" % (str(st.cfg_sar_keepdays)))
        print("ins.cfg_rch_keepdays     Nb. Days to keep .rch files   : %s" % (str(st.cfg_rch_keepdays)))
        print("ins.cfg_log_keepdays     Nb. Days to keep .log files   : %s" % (str(st.cfg_log_keepdays)))
        print("ins.cfg_dbname           SADMIN MySQL Database Name    : %s" % (st.cfg_dbname))
        print("ins.cfg_dbhost           SADMIN MySQL Host Name        : %s" % (st.cfg_dbhost))
        print("ins.cfg_dbdir            SADMIN MySQL Data Dir.        : %s" % (st.cfg_dbdir))
        print("ins.cfg_dbport           SADMIN MySQL TCP/IP Port      : %s" % (str(st.cfg_dbport)))
        print("ins.cfg_rw_dbuser        SADMIN MySQL Read/Write User  : %s" % (st.cfg_rw_dbuser))
        print("ins.cfg_rw_dbpwd         SADMIN MySQL Read/Write Pwd   : %s" % (st.cfg_rw_dbpwd))
        print("ins.cfg_ro_dbuser        SADMIN MySQL Read Only User   : %s" % (st.cfg_ro_dbuser))
        print("ins.cfg_ro_dbpwd         SADMIN MySQL Read Only Pwd    : %s" % (st.cfg_ro_dbpwd))
        print("ins.cfg_rrdtool          rrdtool location              : %s" % (st.cfg_rrdtool))
        print("ins.cfg_ssh_port         SSH Port (Default 22)         : %s" % (str(st.cfg_ssh_port)))
        print("ins.cfg_network1         Network 1 Scan for Info       : %s" % (st.cfg_network1))
        print("ins.cfg_network2         Network 2 Scan for Info       : %s" % (st.cfg_network2))
        print("ins.cfg_network3         Network 3 Scan for Info       : %s" % (st.cfg_network3))
        print("ins.cfg_network4         Network 4 Scan for Info       : %s" % (st.cfg_network4))
        print("ins.cfg_network5         Network 5 Scan for Info       : %s" % (st.cfg_network5))

        print(" ")                                                      
        print("SADMIN Backup Server Information (If Used)")    
        print("-" * 100)                                                   
        print("ins.cfg_backup_nfs_server       Backup NFS Server Name        : %s" % (st.cfg_backup_nfs_server))
        print("ins.cfg_backup_nfs_mount_point  Backup NFS Mount Point        : %s" % (st.cfg_backup_nfs_mount_point))
        print("ins.cfg_backup_nfs_to_keep      Nb. Of Backup to Keep         : %s" % (str(st.cfg_backup_nfs_to_keep)))
        print("ins.cfg_rear_nfs_server         Rear NFS Backup Server        : %s" % (st.cfg_rear_nfs_server))
        print("ins.cfg_rear_nfs_mount_point    Rear NFS Mount Point          : %s" % (st.cfg_rear_nfs_mount_point))
        print("ins.cfg_rear_backup_to_keep     Rear Backup to Keep           : %s" % (str(st.cfg_rear_backup_to_keep)))
        print("ins.cfg_storix_nfs_server       Storix NFS Server             : %s" % (st.cfg_storix_nfs_server))
        print("ins.cfg_storix_nfs_mount_point  Storix NFS Mount Point        : %s" % (st.cfg_storix_nfs_mount_point))
        print("ins.cfg_storix_backup_to_keep   Storix NFS Backup to Keep     : %s" % (str(st.cfg_storix_backup_to_keep)))
        print("ins.cfg_mksysb_nfs_server       Aix mksysb NFS Backup Server  : %s" % (st.cfg_mksysb_nfs_server))
        print("ins.cfg_mksysb_nfs_mount_point  Aix mksysb NFS Mount Point    : %s" % (st.cfg_mksysb_nfs_mount_point))
        print("ins.cfg_mksysb_backup_to_keep   Aix mksysb NFS Backup to Keep : %s" % (str(st.cfg_mksysb_backup_to_keep)))

        # When Really Wanted (Level 9) - Print O/S Environnement
        if (st.debug > 8) :                                               
            print(" ")                                                  
            print("This is the O/S Environment")
            print(dash)                                                 
            for a in os.environ:
                print('Var: ', a, 'Value: ', os.getenv(a))
            print(dash)                                                 
        return 0



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
        st.exit_code = print_functions(st)                              # Display Env. Variables
        st.writelog ("Closing Database connection")                     # Show we are closing DB
        st.dbclose()                                                    # Close the Database
    else:                                                               # Script don't need Database
        st.exit_code = print_function(st)                               # Display Env. Variables
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()


