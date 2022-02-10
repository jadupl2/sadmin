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
#        You will have a better experience, if you set screen width to have at least 100 characters.
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
#@2019_05_19 Refactoring: v2.00 Major revamp, include getopt option, new debug variable.
#@2019_09_03 Update: v2.01 Change default value for max line in rch (35) and log (500) file.
#@2021_05_14 Fix: v2.02 Get DB result as a dict. (connect cursorclass=pymysql.cursors.DictCursor)
#@2021_06_02 Update: v2.03 Bug fixes and Command line option -v, -h and -d are now functional.
#@2021_12_21 Update: v2.04 Adapted for new version of SADMIN Python Library 4.X
# 
# --------------------------------------------------------------------------------------------------
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os                                               # Operating System interface
    import sys                                              # System-Specific Module
    import argparse                                         # Command line arguments parsing
    import pymysql                                          # To Connect & Use MySQL DB
    import socket                                           # LowLevel network interface
    import sadmlib2_std as sa                               # SADMIN Python Library

    # Already import in sadmlib2_std
    # import datetime                                       # Date & Time Module
    # import shutil                                         # HighLevel File Operations
    # import platform                                       # Platform identifying data
    # import pwd                                            # Pwd /etc/passwd Database 
    # import inspect                                        # Check Object Type
    # import time                                           # Time access & conversions
    # import subprocess                                     # Subprocess management
    # import smtplib                                        # SMTP protocol client
    # import grp                                            # Access group database
    # import linecache                                      # Text lines Random access 
    # import subprocess                                     # Subprocess management
    # import multiprocessing                                # Process-based parallelism
except ImportError as e:                                    # Trap Import Error
    print ("\nImport Error : %s \n" % e)                    # Print Import Error Message
    sys.exit(1)                                             # Back to O/S With Error Code 1
#pdb.set_trace()                                            # Activate Python Debugging




# Global Variables Definition
# --------------------------------------------------------------------------------------------------
sadm_ver        = "2.04"                                    # This Script Version 
sadm_desc       = "SADMIN template script"                  # This Script Description
sexitcode  = 0                                         # Script Default Return Code
sadm_dict       = {}                                        # SADMIN Config Dictionnary
#
#db_conn         = ""                                        # Database Connector
#db_cur          = ""                                        # Database Cursor 





# Process all your active(s) server(s) in the SADMIN Database 
# This function is presented as an example, if want to process all (or selected) servers info.
# --------------------------------------------------------------------------------------------------
def process_servers(ws_debug, db_conn, db_cur) :
    sa.write_log ("Processing All Actives Server(s)")                   # Enter Servers Processing

    # Construct SQL to Read All Actives Servers , Put Rows you want in the select 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    sql  = "SELECT srv_name, srv_desc, srv_domain, srv_osname, "
    sql += "srv_ostype, srv_sporadic, srv_monitor, srv_osversion "
    sql += "FROM server WHERE srv_active = %s " % ('True') 
    sql += " order by srv_name;"

    # Execute the SQL Statement
    try :
        db_cur.execute(sql)                                             # Execute SQL Statement
        rows = db_cur.fetchall()                                        # Retrieve All Rows 
    except(pymysql.err.InternalError, pymysql.err.IntegrityError, pymysql.err.DataError) as error:
        (enum,emsg) = error.args                                        # Get Error No. & Message
        sa.write_err (">>>>>>>>>>>>> %s %s" % (enum,emsg))               # Print Error No. & Message
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
        sa.write_log("")                                                # Insert Blank Line
        sa.write_log (('-' * 40))                                       # Insert Dash Line
        sa.write_log ("Processing (%d) %-15s - %s %s" % (lineno,wfqdn,wos,wosversion)) # Server Info

        # If Debug is activated - Display Monitoring & Sporadic Status of Server.
        if ws_debug > 4 :                                               # If Debug Level > 4 
            if wmonitor :                                               # Monitor Collumn is at True
                sa.write_log ("Monitoring is ON for %s" % (wfqdn))      # Show That Monitoring is ON
            else :
                sa.write_log ("Monitoring is OFF for %s" % (wfqdn))     # Show That Monitoring OFF
            if wsporadic :                                              # If a Sporadic Server
                sa.write_log ("Sporadic system is ON for %s" % (wfqdn))  # Show Sporadic is ON
            else :
                sa.write_log ("Sporadic system is OFF for %s" % (wfqdn)) # Show Sporadic is OFF

        # Test if Server Name can be resolved - If not Signal Error & continue with next system.
        try:
            hostip = socket.gethostbyname(wfqdn)                        # Resolve Server Name ?
        except socket.gaierror:                                         # Hostname can't be resolve
            sa.write_log ("[ ERROR ] Can't process %s, hostname can't be resolved" % (wfqdn))
            error_count += 1                                            # Increase Error Counter
            if (error_count != 0 ):                                     # If Error count not at zero
                sa.write_log ("Total error(s) : %s" % (error_count))     # Show Total Error Count
            continue

        # Perform a SSH to current processing server
        if (wfqdn != sadm_dict['sadm_server']):                         # If not on SADMIN Server
            wcommand = "%s %s %s" % (sadm_dict['cmd_ssh_full'],wfqdn,"date") # SSH to Server for date
            sa.write_log ("Command is %s" % (wcommand))                  # Show User what will do
            ccode, cstdout, cstderr = sa.oscommand("%s" % (wcommand))   # Execute O/S CMD 
            if (ccode == 0):                                            # If ssh Worked 
                sa.write_log ("[OK] SSH Worked")                         # Inform User SSH Worked
            else:                                                       # If ssh didn't work
                if wsporadic :                                          # If a Sporadic Server
                    sa.write_log("[ WARNING ] Can't SSH to sporadic system %s"% (wfqdn))
                    sa.write_log("Continuing with next system")          # Not Error if Sporadic Srv. 
                    continue                                            # Continue with next system
                else :
                    if not wmonitor :                                   # Monitor Column is False
                        sa.write_log("[ WARNING ] Can't SSH to %s , but Monitoring is Off"% (wfqdn))
                        sa.write_log("Continuing with next system")      # Not Error if Sporadic Srv. 
                        continue                                        # Continue with next system
                    else:
                        error_count += 1                                # Increase Error Counter
                        sa.write_log("[ERROR] SSH Error %d %s" % (ccode,cstderr)) # Show User Failed
        else:
            sa.write_log ("[OK] No need for SSH on SADMIN server %s" % (sadm_dict['sadm_server'])) 
        if (error_count != 0 ):                                         # If Error count not at zero
            sa.write_log ("Total error(s) : %s" % (error_count))         # Show Total Error Count 
        lineno += 1                                                     # Increase Server Counter
    return (error_count)                                                # Return Err.Count to caller



# Main Process (Used to run script on current server)
# --------------------------------------------------------------------------------------------------
def main_process(ws_debug : int):
    sa.write_log ("Starting Main Process ...")                          # Inform User Starting Main

    return (sexitcode)                                             # Return Err. Code To Caller




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
            ws_debug (int)          : Set to the debug level [0-9] (Default is 0)
    """    

    # Defined Command line default values 
    ws_debug = 0                                                        # Script Debug Level (0-9)
    parser = argparse.ArgumentParser(description=sadm_desc)                 # Desc. is the script name
    
    # Declare Arguments
    parser.add_argument("-v", 
        action="store_true", 
        dest='version',
        help="Show script version")
    parser.add_argument("-d",
        metavar="0-9",  
        type=int, 
        dest='debuglevel',
        help="debug/verbose level from 0 to 9",
        default=0)
    args=parser.parse_args()                                            # Parse the Arguments

    # Set return values accordingly.
    if args.debuglevel:                                                 # Debug Level -d specified 
        ws_debug=args.debuglevel                                        # Save Debug Level
        print("Debug Level is now set at %d" % (ws_debug))              # Show user debug Level
    if args.version:                                                    # If -v specified
        sa.show_version(sadm_ver)                                           # Show Custom Show Version
        sys.exit(0)                                                     # Exit with code 0
    return(ws_debug)      






# Start of the Script - Main Function 
# --------------------------------------------------------------------------------------------------
def main(argv):
    
    # Make sure only root can run this script (Optional Code).
    if os.getuid() != 0 :                                               # UID of user is not zero
        print("\nThis script must be run by 'root' user.")              # Advise User Message / Log
        print("Or use 'sudo %s'." % (os.path.basename(sys.argv[0])))    # Suggest to use 'sudo'
        print("Script aborted.\n")                                      # Process Aborted Msg
        sys.exit(1)                                                     # Exit with Error Code

    # Evaluate command line options & Return option(s) used.
    (ws_debug) = cmd_options(argv)   

    # Make sure script can only be run on SADMIN server (Optional).
    if sa.get_fqdn() != sa.dict_cfg['sadm_server']:                      # If Not on SADMIN Server
        print("\nThis script can only be run on SADMIN server (%s)" % (sadm_dict['sadm_server']))
        print("Script aborted.\n")                                      # Abort advise message
        sa.stop(sexitcode)                                              # Close SADMIN Env. 
        sys.exit(1)                                                     # Exit To O/S

    # Execute Script Main Process (Without SADMIN Database Access)
    #(sexitcode,sadm_dict) = sa.start(sadm_ver,sadm_desc)           # Init. SADMIN Env.
    #if sexitcode != 0 :                                            # If Error while Init SADMIN
    #    sa.stop(sexitcode)                                         # Close SADMIN Env.     
    #    sys.exit(sexitcode)                                        # Return to O/S with error
    #if ws_debug > 0 :  sa.print_dict_cfg()                              # Show SADM cfg Dictionnary
    #sexitcode = main_process(ws_debug)                             # Pass Cmdline Options
    # OR 

    # Execute Script Main Process (With SADMIN Database Access)
    (sexitcode,sadm_dict,db_conn,db_cur) = sa.start(sadm_ver,sadm_desc,db_used=True) 
    if sexitcode != 0 :                                            # If Error while Init SADMIN
        sa.stop(sexitcode)                                         # Close SADMIN Env.     
        sys.exit(sexitcode)                                        # Return to O/S with error
    if ws_debug > 0 :  sa.print_dict_cfg()                              # Show SADM cfg Dictionnary
    print ("\nValues")
    print ("db_cur = %s" % (type(db_cur)))
    type(db_conn)
    sexitcode = process_servers(ws_debug,db_conn,db_cur)           # Process All Active Servers 

    # Gracefully exit SADMIN and back to O/S
    sa.stop(sexitcode)                                                 
    sys.exit(sexitcode)                                                

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)
