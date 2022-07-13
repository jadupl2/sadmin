#! /usr/bin/env python3
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Script Name :   XXXXXXXX.py
#   Date        :   YYYY/MM/DD
#   Requires    :   python3 and SADMIN Python Library
#   Description :
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
#
# This code was originally written by Jacques Duplessis <sadmlinux@gmail.com>.
# Developer Web Site : https://sadmin.ca
#   
#---------------------------------------------------------------------------------------------------
#   The SADMIN Tool is a free software; you can redistribute it and/or modify it under the terms
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
# 
# Version Change Log 
#
# 2016_05_18 New: v1.0 Initial Version
#@2019_05_19 Refactoring: v2.0 Major revamp, include getopt option, new debug variable.
#@2019_09_03 Update: v2.1 Change default value for max line in rch (35) and log (500) file.
#@2021_05_14 Fix: v2.2 Get DB result as a dict. (connect cursorclass=pymysql.cursors.DictCursor)
#@2021_06_02 Update: v2.3 Bug fixes and Command line option -v, -h and -d are now functional.
# 
# --------------------------------------------------------------------------------------------------
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,argparse,time,sys,pdb,socket,datetime,glob,fnmatch    # Import Std Python3 Modules
except ImportError as e:                                            # Trap Import Error
    print ("Import Error : %s " % e)                                # Print Import Error Message
    sys.exit(1)                                                     # Back to O/S With Error Code 1
#pdb.set_trace()                                                    # Activate Python Debugging



#===================================================================================================
# Scripts Variables 
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
#


# --------------------------------------------------------------------------------------------------
#  Show command line options to user.
# --------------------------------------------------------------------------------------------------
def show_usage():
    print ("\nUsage :",os.path.basename(sys.argv[0]))
    print ("\t-d --debug  <level>       (Debug Level [0-9])")
    print ("\t-h --help                 (Show this help message)")
    print ("\t-v --version              (Show Script Version Info)")
    print ("\n")


# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.49 
# Setup for Global Variables and import SADMIN Python module
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------
def setup_sadmin():

    # Load SADMIN Standard Python Library Module ($SADMIN/lib/sadmlib_std.py).
    try :
        SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Root Dir.
        sys.path.insert(0,os.path.join(SADM,'lib'))                     # Add SADMIN to sys.path
        import sadmlib_std as sadm                                      # Import SADMIN Python Libr.
    except ImportError as e:                                            # If Error importing SADMIN 
        print ("Error importing SADMIN module: %s " % e)                # Advise User of Error
        sys.exit(1)                                                     # Go Back to O/S with Error
    
    # Create [S]ADMIN [T]ools instance (Setup Dir.,Var.)
    st = sadm.sadmtools()                       

    # You can use variable below BUT DON'T CHANGE THEM - They are used by SADMIN Module.
    st.pn               = os.path.basename(sys.argv[0])                 # Script name with extension
    st.inst             = os.path.basename(sys.argv[0]).split('.')[0]   # Script name without Ext
    st.tpid             = str(os.getpid())                              # Get Current Process ID.
    st.exit_code        = 0                                             # Script Exit Code (Use it)
    st.hostname         = socket.gethostname().split('.')[0]            # Get current hostname

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.    
    st.ver              = "2.3"                 # Current Script Version
    st.pdesc            = "SADMIN Python template v%s" % st.ver
    st.log_type         = 'B'                   # Output goes to [S]creen to [L]ogFile or [B]oth
    st.log_append       = False                 # Append Existing Log(True) or Create New One(False)
    st.log_header       = True                  # Show/Generate Header in script log (.log)
    st.log_footer       = True                  # Show/Generate Footer in script log (.log)
    st.multiple_exec    = "N"                   # Allow running multiple copy at same time ?
    st.use_rch          = True                  # Generate entry in Result Code History (.rch) 
    st.debug            = 0                     # Increase Verbose from 0 to 9 
    st.usedb            = True                  # Open/Use Database(True) or Don't Need DB(False)
    st.dbsilent         = False                 # When DB Error, False=ShowErrMsg and True=NoErrMsg 
                                                # But Error Code always returned (0=ok else error)

    # Override Default define in $SADMIN/cfg/sadmin.cfg
    #st.cfg_alert_type   = 1                    # 0=NoMail 1=OnlyOnError 2=OnlyOnSuccess 3=Always
    #st.cfg_alert_group  = "default"            # Valid Alert Group are defined in alert_group.cfg
    #st.cfg_mail_addr    = ""                   # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name     = ""                   # This Override Company Name specify in sadmin.cfg
    #st.cfg_max_logline  = 500                  # When Script End Trim log file to 500 Lines
    #st.cfg_max_rchline  = 35                   # When Script End Trim rch file to 35 Lines
    #st.ssh_cmd = "%s -qnp %s " % (st.ssh,st.cfg_ssh_port) # SSH Command to Access Server 

    # Start SADMIN Tools - Initialize 
    st.start()                                  # Init. SADMIN Env. (Create dir.,Log,RCH, Open DB..)
    return(st)                                  # Return Instance Object To Caller



#===================================================================================================
# Process all your active(s) server(s) in the Database (Used if want to process selected servers)
#===================================================================================================
def process_servers(wconn,wcur,st):
    st.writelog ("Processing All Actives Server(s)")                    # Enter Servers Processing

    # Construct SQL to Read All Actives Servers , Put Rows you want in the select 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    sql  = "SELECT srv_name, srv_desc, srv_domain, srv_osname, "
    sql += " srv_ostype, srv_sporadic, srv_monitor, srv_osversion "
    sql += " FROM server WHERE srv_active = %s " % ('True')
    sql += " order by srv_name;"

    # Execute the SQL Statement
    try :
        wcur.execute(sql)                                               # Execute SQL Statement
        rows = wcur.fetchall()                                          # Retrieve All Rows 
    except(pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as error:
        self.enum, self.emsg = error.args                               # Get Error No. & Message
        st.writelog (">>>>>>>>>>>>> %s %s" % (self.enum,self.emsg))     # Print Error No. & Message
        return (1)
    
    # Process each Actives Servers
    lineno = 1                                                          # Server Counter Start at 1
    error_count = 0                                                     # Error Counter
    for row in rows:                                                    # Process each server row
        wname       = row['srv_name']                                   # Extract Server Name
        wdesc       = row['srv_desc']                                   # Extract Server Desc.
        wdomain     = row['srv_domain']                                 # Extract Server Domain Name
        wos         = row['srv_osname']                                 # Extract Server O/S Name
        wostype     = row['srv_ostype']                                 # Extract Server O/S Type
        wsporadic   = row['srv_sporadic']                               # Extract Server Sporadic ?
        wmonitor    = row['srv_monitor']                                # Extract Server Monitored ?
        wosversion  = row['srv_osversion']                              # Extract Server O/S Version
        wfqdn   = "%s.%s" % (wname,wdomain)                             # Construct FQDN 
        st.writelog("")                                                 # Insert Blank Line
        st.writelog (('-' * 40))                                        # Insert Dash Line
        st.writelog ("Processing (%d) %-15s - %s %s" % (lineno,wfqdn,wos,wosversion)) # Server Info

        # If Debug is activated - Display Monitoring & Sporadic Status of Server.
        if st.debug > 4 :                                               # If Debug Level > 4 
            if wmonitor :                                               # Monitor Collumn is at True
                st.writelog ("Monitoring is ON for %s" % (wfqdn))       # Show That Monitoring is ON
            else :
                st.writelog ("Monitoring is OFF for %s" % (wfqdn))      # Show That Monitoring OFF
            if wsporadic :                                              # If a Sporadic Server
                st.writelog ("Sporadic system is ON for %s" % (wfqdn))  # Show Sporadic is ON
            else :
                st.writelog ("Sporadic system is OFF for %s" % (wfqdn)) # Show Sporadic is OFF

        # Test if Server Name can be resolved - If not Signal Error & continue with next system.
        try:
            hostip = socket.gethostbyname(wfqdn)                        # Resolve Server Name ?
        except socket.gaierror:                                         # Hostname can't be resolve
            st.writelog ("[ ERROR ] Can't process %s, hostname can't be resolved" % (wfqdn))
            error_count += 1                                            # Increase Error Counter
            if (error_count != 0 ):                                     # If Error count not at zero
                st.writelog ("Total error(s) : %s" % (error_count))     # Show Total Error Count
            continue

        # Perform a SSH to current processing server
        if (wfqdn != st.cfg_server):                                    # If not on SADMIN Server
            wcommand = "%s %s %s" % (st.ssh_cmd,wfqdn,"date")           # SSH Cmd to Server for date
            st.writelog ("Command is %s" % (wcommand))                  # Show User what will do
            ccode, cstdout, cstderr = st.oscommand("%s" % (wcommand))   # Execute O/S CMD 
            if (ccode == 0):                                            # If ssh Worked 
                st.writelog ("[OK] SSH Worked")                         # Inform User SSH Worked
            else:                                                       # If ssh didn't work
                if wsporadic :                                          # If a Sporadic Server
                    st.writelog("[ WARNING ] Can't SSH to sporadic system %s"% (wfqdn))
                    st.writelog("Continuing with next system")          # Not Error if Sporadic Srv. 
                    continue                                            # Continue with next system
                else :
                    if not wmonitor :                                   # Monitor Column is False
                        st.writelog("[ WARNING ] Can't SSH to %s , but Monitoring is Off"% (wfqdn))
                        st.writelog("Continuing with next system")      # Not Error if Sporadic Srv. 
                        continue                                        # Continue with next system
                    else:
                        error_count += 1                                # Increase Error Counter
                        st.writelog("[ERROR] SSH Error %d %s" % (ccode,cstderr)) # Show User Failed
        else:
            st.writelog ("[OK] No need for SSH on SADMIN server %s" % (st.cfg_server)) # On SADM Srv
        if (error_count != 0 ):                                         # If Error count not at zero
            st.writelog ("Total error(s) : %s" % (error_count))         # Show Total Error Count 
        lineno += 1                                                     # Increase Server Counter
    return (error_count)                                                # Return Err.Count to caller



#===================================================================================================
# Main Process (Used to run script on current server)
#===================================================================================================
def main_process(st):
    st.writelog ("Starting Main Process ...")                           # Inform User Starting Main

    return (st.exit_code)                                               # Return Err. Code To Caller





# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
def cmd_options(st,argv):

    # Evaluate Command Line Switch Options Upfront
    # By Default (-h) Show Help Usage, (-v) Show Script Version,(-d [0-9]) Set Debug Level     
    parser = argparse.ArgumentParser(description=st.pdesc)              # Desc. is the script name
    #
    parser.add_argument("-v", 
        action="store_true", 
        dest='version',
        help="show script version")
    parser.add_argument("-d",
        metavar="0-9",  
        type=int, 
        dest='debuglevel',
        help="debug/verbose level from 0 to 9",
        default=0)
    #
    args=parser.parse_args()                                            # Parse the Arguments

    if args.version:                                                    # If -v specified
        st.show_version()                                               # Show Custom Show Version
        st.stop (0)                                                     # Close/TrimLog/Del tmpfiles
        sys.exit(0)                                                     # Exit with code 0
        
    if args.debuglevel:                                                 # Debug Level -d specified 
        st.debug=args.debuglevel                                        # Save Debug Level
        print ("Debug Level is now set at %d" % (st.debug))             # SHow user debug Level

    return()    



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main(argv):

    # Create [S]ADMIN [T]ool Instance and call the start() function.
    st = setup_sadmin()                                                 # Sadm Tools class instance
    cmd_options (st,argv)                                               # Check command-line Options

    # Insure that this script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
        st.writelog ("This script must be run by the 'root' user.")     # Advise User Message / Log
        st.writelog ("Try 'sudo %s'." % (os.path.basename(sys.argv[0])))# Suggest to use 'sudo'
        st.writelog ("Process aborted.")                                # Process Aborted Msg
        st.stop (1)                                                     # Close and Trim Log/Email
        sys.exit(1)                                                     # Exit with Error Code
    
    # (Optional if) - Test if script is running on the SADMIN Server, If not abort script 
    if st.get_fqdn() != st.cfg_server:                                  # Only run on SADMIN
        st.writelog("This script can only be run on SADMIN server (%s)" % (st.cfg_server))
        st.writelog("Process aborted")                                  # Abort advise message
        st.stop(1)                                                      # Close and Trim Log
        sys.exit(1)                                                     # Exit To O/S

    
    # If on SADMIN server & use Database (st.usedb=True), open connection to Database.
    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database

    # Main Processing
    #st.exit_code = process_servers(conn,cur,st)                        # Process All Active Servers 
    # OR 
    st.exit_code = main_process(st)                                     # Process Not Using Database
 
    # If on SADMIN server & use Database (st.usedb=True), close connection to Server Database
    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        st.dbclose()                                                    # Close Database Connection
    st.stop(st.exit_code)                                               # Close SADM Environment
    sys.exit(st.exit_code)                                              # Exit To O/S

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)