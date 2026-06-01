#! /usr/bin/env python3
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Script Name :   XXXXXXXX.py
#   Date        :   2025/MM/DD
#   Requires    :   python3 and SADMIN Python Library
#   Description :   Your description of what this script is doing.
# ---------------------------------------------------------------------------------------------------
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to
#        have and use a 100 characters per line. Comments in script always begin at column 73.
#        You will have a better experience, if you set screen width to have at least 100 characters.
#
# ---------------------------------------------------------------------------------------------------
#   The SADMIN Tool is a free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <https://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
#
# VERSION CHANGE LOG
# ------------------
# 2025_08_25 lib v1.00 Initial Version
#@2025_09_04 lib v1.1.1 Now ONE template for Python & remove the need of importing pymysql.
#@2026_05_30 lib v1.2.1 Added 'quiet' parameter to 'db_connect()' function in SADMIN Python Library.
# --------------------------------------------------------------------------------------------------
#


# Modules needed by this script and they all come with Standard Python 3.
import pwd


try:
    import os, sys, argparse, time, datetime, socket, platform, re, pymysql  # Import Std Python3 Modules
#   import pdb                                                      # Python Debugger (If needed)
#   pdb.set_trace()                                                 # Activate Python Debugging
except ImportError as e:                                            # Trap Import Error
    print("Import Error : %s " % e)                                 # Print Import Error Message
    sys.exit(1)                                                     # Back to O/S With Error Code 1

 


# --------------------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.56
# Setup for Global Variables and load the SADMIN standard library.
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

# Variables shared with SADNLIB Python Library.
sa.pn            = os.path.basename(sys.argv[0])         # [P]rogram [N]ame with extension
sa.ver           = "1.2.1"                               # Your Program VERSION number
sa.desc          = "Description of program '%s'" % (sa.pn)# Your Program DESCRIPTION 
sa.inst          = sa.pn.split('.')[0]                   # INSTance Name = Pgm Name Without Ext
sa.pid           = os.getpid()                           # Get Current Process ID.
sa.hostname      = sa.get_hostname()                     # Get Current hostname
sa.username      = sa.get_username()                     # Get Current User Name
sa.root_only     = False                                 # Can Only be run by 'root' (True/False)
sa.server_only   = False                                 # Run Only on SADMIN server (True/False)
sa.use_rch       = True                                  # Write exec info to RCH file(True/False)
sa.db_used       = False                                 # Open/Use auto connect DB(True)
sa.db_name       = ""                                    # Database Name (sadmin=default) 
sa.debug         = 0                                     # Debug Level 0-9 (Increase Verbose)
sa.exit_code     = 0                                     # Default Return Code (0=Success 1-Error)
sa.log_type      = "B"                                   # S=Screen L=Log B=Both
sa.log_append    = False                                 # Append to previous log (True/False)
sa.log_header    = True                                  # Produce Log Header (True/False)
sa.log_footer    = True                                  # Produce Log Footer (True/False)
sa.multiple_exec = False                                 # Allow running multiple Instance ?
sa.pid_timeout   = 7200                                  # PID File TimeToLive default
sa.lock_timeout  = 3600                                  # Sec. (TTL) before automatically unlock 
sa.max_logline   = 500                                   # Maximum number of lines in log file.
sa.max_rchline   = 35                                    # Maximum number of lines in rch file.
sa.mail_addr     = ""                                    # Default use email(s) in sadmin.cfg
sa.quiet         = False                                 # If error in a function & quiet is :
                                                         # False: Show error msg & return Error No 
                                                         # True : Omly returm Error No. but No Msg

# You don't have to worry about the fields below, they will be set & used by the SADMIN Python Libr.
# They act like Global Var, but they are actually fields of the SADMIN Python Libr. (sadmlib2_std).
sa.db_conn        = None           # Use this Database Connector when using DB,  set by sa.start()
sa.db_cur         = None           # Use this Database cursor if you use the DB, set by sa.start()
sa.db_errno       = 0              # PyMysql Database Error Number
sa.db_errmsg      = ""             # PyMysql Database Error Message
sa.cmd_ssh_full   = "%s -qnp %s " % (cmd_ssh,sadm_ssh_port)   # SSH Cmd with Port, set by sa.start()

# The values of fields below, are loaded automatically from sadmin.cfg when you import sadmlib2_std.
# Change them to fit your need, before you call 'start()' functions of SADMIN Python Library.
sa.sadm_alert_type    = 1          # 0=NoAlert 1=AlertOnlyOnError 2=AlertOnlyOnSuccess 3=AlwaysAlert
sa.sadm_alert_group   = "default"  # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
sa.sadm_warning_group = "warning"  # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
sa.sadm_info_group    = "info"     # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
# ==================================================================================================




# Script Global Variables Definition Section
# --------------------------------------------------------------------------------------------------





# Process all your active(s) server(s) in the Database (Used if want to process selected servers)
# Called when 'sa.db_used' is set to 'True'.
# --------------------------------------------------------------------------------------------------
def process_servers():

    sa.write_log("Processing all active system(s)")                     # Enter Servers Processing

    if (not sa.db_used) :                                               # Make sure db_used is True
        sa.write_err ("Variable 'sa.db_used' must be set to 'True' to have access to the database.")
        return(1)                                                       # Return error to caller
    
    # Construct SQL - See columns available in $SADMIN/doc/sadm_database_layout directory.
    sql = "SELECT * FROM server WHERE srv_active = %s order by srv_name;" % ('True')

    try:
        sa.db_cur.execute(sql)                                          # Execute SQL Statement
        rows = sa.db_cur.fetchall()                                     # Retrieve All Rows
    except(pymysql.err.InternalError, pymysql.err.IntegrityError, pymysql.err.DataError) as e:
        (enum,emsg) = e.args                                            # Get Error No. & Message
        sa.write_err ("[ ERROR ] Retrieving active systems rows.")      # Advise user 
        sa.write_err ("Error No:%s - Error Message:%s" % (enum, emsg))  # Print Error No. & Message
        return (1)                                                      # Return error to caller


    # Process Each Active Systems
    lineno      = 1                                                     # System Count Start at 1
    error_count = 0                                                     # Clear Error Counter
    for row in rows:                                                    # Process each system row
        wname       = row['srv_name']                                   # Extract System Name
        wdesc       = row['srv_desc']                                   # Extract System Desc.
        wdomain     = row['srv_domain']                                 # Extract System Domain Name
        wos         = row['srv_osname']                                 # Extract System O/S Name
        wsporadic   = row['srv_sporadic']                               # Extract System Sporadic ?
        wmonitor    = row['srv_monitor']                                # Extract System Monitored ?
        wosversion  = row['srv_osversion']                              # Extract System O/S Version
        wssh_port   = row['srv_ssh_port']                               # Extract System SSH Port
        wfqdn       = "%s.%s" % (wname, wdomain)                        # Construct FQDN
        sa.write_log("  ")                                              # Blank Lime
        sa.write_log("Processing (%d) %-15s - %s %s %s" % (lineno,wfqdn,wos,wosversion,wdesc))  


        # Check If System Name Can Be Resolved,
        try:
            hostip = socket.gethostbyname(wfqdn)                        # Resolve Server Name ?
        except socket.gaierror:                                         # Hostname can't be resolve
            sa.write_err ("[ ERROR ] Can't process '%s', hostname can't be resolved." % (wfqdn))
            error_count += 1                                            # Increase Error Counter
            sa.write_err ("Total error(s) : %s" % (error_count))        # Show Total Error Count
            continue                                                    # Go read Next Server


        # Check If System Is Locked.
        if sa.lock_status(wname) != 0:                                  # Is System Lock ?
            sa.write_err ("[ WARNING ] System '%s' is currently lock." % (wname))
            sa.write_err ("Continuing with next system")                # Advise User
            continue                                                    # Go read Next Server


        # Perform a SSH test to system currently processing
        ssh_command  = "%s -qnp %s -o ConnectTimeout=3 " % (sa.cmd_ssh,wssh_port)
        wcommand = "%s %s %s" % (ssh_command,wfqdn,"date")               # SSH Cmd to Server for date
        if sa.debug > 0 : sa.write_log("[ DEBUG %d ] Command is %s" % (sa.debug,wcommand))

        ccode,cstdout,cstderr = sa.oscommand("%s" % (wcommand))         # Get system date/time
        if (ccode == 0):                                                # If ssh Worked
            sa.write_log("[OK] SSH Succeeded %s" % (cstdout))           # OK + date/Time of system
        else:                                                           # If ssh didn't work
            if wsporadic:                                               # Is it a Sporadic Server
                sa.write_err ("[ WARNING ] Can't SSH to sporadic system '%s'." % (wfqdn))
                sa.write_err ("Continuing with next system")            # Not Error if Sporadic Srv.
                continue                                                # Continue with next system
            else:
                error_count += 1                                        # Increase Error Counter
                sa.write_err("[ ERROR ] SSH Error %d %s" % (ccode, cstderr))  
        if (error_count != 0): sa.write_log ("Total error(s) : %s" % (error_count)) 
        lineno += 1                                                     # Increase Server Counter

    return (error_count)                                                # Return Err.Count to caller






# Main Process (Insert here your main process (Called when you don't need any database access)
# --------------------------------------------------------------------------------------------------
def main_process():
    sa.write_log ("In main_process")

    sa.sleep(3,1)                                                       # Sleep 3 sec progress 1 sec
    sa.write_log(" ")                                                   # Blank line on screen & Log

    return(sa.exit_code)                                                  # Result Code to caller





# Analyze Command Line Options
# --------------------------------------------------------------------------------------------------
def cmd_options(argv):

    """ Command line Options Function - Evaluate Command Line Switch Used (if any).

        Args:
            (argv): Arguments pass on the comand line.
              [-d 0-9]      Set Debug (verbose) Level
              [-h]          Show this help message
              [-v]          Show script version information
              [-X]          Delete the script PID file before running the script.

        Returns:
            sa.debug: Debug level set by the user on the command line (Default is 0)
            Your Global variable(s) you will need to set based on the command line options you use.

    """
    parser = argparse.ArgumentParser(description=sa.desc)               # Desc in SADMIN section

    # Declare Arguments
    parser.add_argument("-v",
                        action="store_true",
                        dest='version',
                        help="Show script information")
    parser.add_argument("-X",
                        action="store_true",
                        dest='delpid',
                        help="Delete script PID file prior to running.")
    parser.add_argument("-d",
                        metavar="0-9",
                        type=int,
                        dest='pdebug',
                        help="debug/verbose level from 0 to 9",
                        default=0)
    
    args = parser.parse_args()                                          # Parse the Arguments
    if args.pdebug:                                                     # Debug Level -d specified
        sa.debug = args.pdebug                                          # Save Debug Level
        print("Debug Level is now set at %d" % (sa.debug))              # Show user debug Level

    if args.version:                                                    # If -v specified
        sa.show_version(sa.ver)                                         # Show Script & Lib. Version
        sys.exit(0)                                                     # Exit with code 0
    
    if args.delpid:                                                     # If -X specified
        if os.path.exists(sa.pid_file):                                 # If use -X Delete PID file
            os.remove(sa.pid_file)                                      # Delete the PID file.
            print("The PID File (" + sa.pid_file + ") is now removed.") 
    return()                                             
                                                         





# Main Function
# --------------------------------------------------------------------------------------------------
def main(argv):

    cmd_options(argv)                                                   # Analyze cmdline options
    if (sa.db_used == True):                                            # If Use Db, Process Systems
        (sa.db_conn, sa.db_cur) = sa.start()                            # Return DB connector,cursor
        sa.exit_code = process_servers()                                # Use Db Loop Active Systems
    else: 
        sa.start()                                                      # SADMIN Initialization
        sa.exit_code = main_process()                                   # Main Process, No Db Used
    sa.stop(sa.exit_code)                                               # Exit Gracefully SADMIN Lib
    sys.exit(sa.exit_code)                                              # Back to O/S with Exit Code


# Python assigns the string "__main__" to __name__. 
# If the file is imported elsewhere (import script), __name__ matches the actual filename instead.
# This condition guards your code against accidental execution during imports.
if __name__ == "__main__": main(sys.argv)
