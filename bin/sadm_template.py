#!/usr/bin/env python3
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Script Name :   XXXXXXXX.py
#   Date        :   YYYY/MM/DD
#   Requires    :   python3 and SADMIN Python Library
#   Description :
#
#   Note        :   All scripts (Shell,Python,php) and screen output are formatted to have and use 
#                   a 100 characters per line. Comments in script always begin at column 73. You 
#                   will have a better experience, if you set screen width to have at least 100 Chr.
# 
# --------------------------------------------------------------------------------------------------
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
# 2017_12_01 V1.0 Initial Version
# 2018_05_14 V1.7 Add USE_RCH Variabe to use or not the [R]eturn [C]ode [H]istory File
# 2018_05_15 V1.8 Add log_header and log_footer to produce or not the log Header and Footer.
# 2018_05_20 V1.9 Restructure the code and added comments
# 2018_05_26 V2.0 Revisited - Align with New Version of SADMIN Library
# 
# --------------------------------------------------------------------------------------------------
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch             # Import Std Python3 Modules
except ImportError as e:                                            # Trap Import Error
    print ("Import Error : %s " % e)                                # Print Import Error Message
    sys.exit(1)                                                     # Back to O/S With Error Code 1
#pdb.set_trace()                                                    # Activate Python Debugging



#===================================================================================================
# Scripts Variables 
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
debug               = 0                                                 # Debug verbosity (0-9)
#

#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Python Library
#===================================================================================================
def setup_sadmin():

    # Load SADMIN Standard Python Library
    try :
        SADM = os.environ.get('SADMIN')                     # Getting SADMIN Root Dir.
        sys.path.insert(0,os.path.join(SADM,'lib'))         # Add SADMIN to sys.path
        import sadmlib_std as sadm                          # Import SADMIN Python Libr.
    except ImportError as e:                                # If Error importing SADMIN 
        print ("Error Importing SADMIN Module: %s " % e)    # Advise USer of Error
        sys.exit(1)                                         # Go Back to O/S with Error
    
    # Create Instance of SADMIN Tool
    st = sadm.sadmtools()                       # Create SADMIN Tools Instance (Setup Dir.,Var,...)

    # Change these values to your script needs.
    st.ver              = "2.0"                 # Current Script Version
    st.multiple_exec    = "N"                   # Allow running multiple copy at same time ?
    st.log_type         = 'B'                   # Output goes to [S]creen [L]ogFile [B]oth
    st.log_append       = True                  # Append Existing Log or Create New One
    st.use_rch          = True                  # Generate entry in Return Code History (.rch) 
    st.log_header       = True                  # Show/Generate Header in script log (.log)
    st.log_footer       = True                  # Show/Generate Footer in script log (.log)
    st.usedb            = True                  # True=Open/Use Database,False=Don't Need to Open DB 
    st.dbsilent         = False                 # Return Error Code & False=ShowErrMsg True=NoErrMsg
    st.exit_code        = 0                     # Script Exit Code for you to use

    # Override Default define in $SADMIN/cfg/sadmin.cfg
    #st.cfg_mail_type    = 1                    # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    #st.cfg_mail_addr    = ""                   # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name     = ""                   # This Override Company Name specify in sadmin.cfg
    #st.cfg_max_logline  = 5000                 # When Script End Trim log file to 5000 Lines
    #st.cfg_max_rchline  = 100                  # When Script End Trim rch file to 100 Lines
    #st.ssh_cmd = "%s -qnp %s " % (st.ssh,st.cfg_ssh_port) # SSH Command to Access Server 

    # Start SADMIN Tools - Initialize 
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..
    return(st)                                  # Return Instance Obj. To Caller



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
        wname       = row[0]                                            # Extract Server Name
        wdesc       = row[1]                                            # Extract Server Desc.
        wdomain     = row[2]                                            # Extract Server Domain Name
        wos         = row[3]                                            # Extract Server O/S Name
        wostype     = row[4]                                            # Extract Server O/S Type
        wsporadic   = row[5]                                            # Extract Server Sporadic ?
        wmonitor    = row[6]                                            # Extract Server Monitored ?
        wosversion  = row[7]                                            # Extract Server O/S Version
        wfqdn   = "%s.%s" % (wname,wdomain)                             # Construct FQDN 
        st.writelog("")                                                 # Insert Blank Line
        st.writelog (('-' * 40))                                        # Insert Dash Line
        st.writelog ("Processing (%d) %-15s - %s %s" % (lineno,wfqdn,wos,wosversion)) # Server Info

        # If Debug is activated - Display Monitoring & Sporadic Status of Server.
        if debug > 4 :                                                  # If Debug Level > 4 
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



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    # Import SADMIN Module, Create SADMIN Tool Instance, Initialize Log and rch file.  
    st = setup_sadmin()                                                 # Setup Var. & Load SADM Lib
    
    # Insure that this script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
       st.writelog ("This script must be run by the 'root' user")       # Advise User Message / Log
       st_writelog ("Try sudo %s" % (os.path.basename(sys.argv[0])))    # Suggest to use 'sudo'
       st.writelog ("Process aborted")                                  # Process Aborted Msg
       st.stop (1)                                                      # Close and Trim Log/Email
       sys.exit(1)                                                      # Exit with Error Code
    
# Test if script is running on the SADMIN Server, If not abort script (Optional code)
#    if st.get_fqdn() != st.cfg_server:                                  # Only run on SADMIN
#        st.writelog("This script can only be run on SADMIN server (%s)" % (st.cfg_server))
#        st.writelog("Process aborted")                                  # Abort advise message
#        st.stop(1)                                                      # Close and Trim Log
#        sys.exit(1)                                                     # Exit To O/S
        
    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database
    
    # Main Processing
    #st.exit_code = process_servers(conn,cur,st)                        # Process All Active Servers 
    # OR 
    st.exit_code = main_process(st)                                     # Process Not Using Database
 
    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        st.dbclose()                                                    # Close the Database
    st.stop(st.exit_code)                                               # Close SADM Environment
    sys.exit(st.exit_code)                                              # Exit To O/S

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
