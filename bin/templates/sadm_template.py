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
# --------------------------------------------------------------------------------------------------
#

# Modules needed by this script SADMIN Tools and they all come with Standard Python 3.
try:
    import os, sys, argparse, time, datetime, socket, platform, re  # Import Std Python3 Modules
    import pymysql                                                  # Use for MySQL DB
#   import pdb                                                      # Python Debugger (If needed)
except ImportError as e:                                            # Trap Import Error
    print("Import Error : %s " % e)                                 # Print Import Error Message
    sys.exit(1)                                                     # Back to O/S With Error Code 1
#pdb.set_trace()                                                    # Activate Python Debugging

 


# --------------------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.56
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your Python code.    
# --------------------------------------------------------------------------------------------------
try:
    SADM = os.environ['SADMIN']                                      # Get SADMIN Env. Var. Dir.
except KeyError as e:                                                # If SADMIN is not define
    print("Environment variable 'SADMIN' is not defined.\n%s\nScript aborted.\n" % e) 
    sys.exit(1)                                                      # Go Back to O/S with Error

try: 
    sys.path.insert(0, os.path.join(SADM, 'lib'))                    # Add lib dir to sys.path
    import sadmlib2_std as sa                                        # Import SADMIN Python Library
except ImportError as e:                                             # If Error importing SADMIN
    print("Import error : SADMIN module: %s " % e)                   # Advise User of Error
    print("Please make sure the 'SADMIN' environment variable is defined.")
    sys.exit(1)                                                      # Go Back to O/S with Error

# Local variables local to this script.
pver        = "1.3"               # Program version no.
pdesc       = "Put here a description of your script."
phostname   = sa.get_hostname()   # Get current `hostname -s`
pdebug      = 0                   # Debug level from 0 to 9
pexit_code  = 0                   # Script default exit code
db_conn     = None                # Database Connector (if used)
db_cur      = None                # Database Cursor (if used)

# Fields used by sa.start(),sa.stop() & DB functions that influence execution of SADMIN library
sa.db_used           = True      # Open/Use DB(True), No DB needed (False), sa.start() auto connect
sa.db_silent         = False      # True=ReturnErrorNo & No ErrMsg, False=ReturnErrorNo & ShowErrMsg
sa.db_name           = "sadmin"   # Database Name default to name define in $SADMIN/cfg/sadmin.cfg
sa.db_errno          = 0          # Database Error Number
sa.db_errmsg         = ""         # Database Error Message
#
sa.use_rch           = True       # Generate entry in Result Code History (.rch)
sa.log_type          = 'B'        # Output goes to [S]creen to [L]ogFile or [B]oth
sa.log_append        = False      # Append Existing Log(True) or Create New One(False)
sa.log_header        = True       # Show/Generate Header in script log (.log)
sa.log_footer        = True       # Show/Generate Footer in script log (.log)
sa.multiple_exec     = "N"        # Allow running multiple copy at same time ?
sa.proot_only        = False      # Pgm run by root only ?
sa.psadm_server_only = False      # Run only on SADMIN server ?
sa.cmd_ssh_full = "%s -qnp %s -o ConnectTimeout=2 -o ConnectionAttempts=2 " % (sa.cmd_ssh,sa.sadm_ssh_port)

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




# Scripts Global Variables
# --------------------------------------------------------------------------------------------------





# Process all your active(s) server(s) in the Database (Used if want to process selected servers)
# Called when 'sa.db_used' is set to 'True'.
# --------------------------------------------------------------------------------------------------
def process_servers(fconn=db_conn,fcur=db_cur):

    sa.write_log("Processing all actives server(s)")                    # Enter Servers Processing

    if (sa.db_used == False) :                                          # Make sure db_used is True
        sa.write_err ("Variable 'sa.db_used' must be set to 'True' to have access to the database.")
        return(1)                                                       # Return error to caller
    
    # Construct SQL
    # See columns available in 'table_structure_server.pdf' in $SADMIN/doc/pdf/database directory
    sql = "SELECT * FROM server WHERE srv_active = %s order by srv_name;" % ('True')

    try:
        fcur.execute(sql)                                               # Execute SQL Statement
        rows = fcur.fetchall()                                          # Retrieve All Rows
    except(pymysql.err.InternalError, pymysql.err.IntegrityError, pymysql.err.DataError) as e:
        enum, emsg = e.args                                             # Get Error No. & Mee
        sa.write_err("Error: Retrieving all active systems rows.")      # User error message
        sa.write_err("%s %s" % (enum, emsg))                            # Print Error No. & Message
        return (1)                                                      # Return error to caller

    # Process each Active Servers
    lineno      = 1                                                     # System Count Start at 1
    error_count = 0                                                     # Clear Error Counter
    for row in rows:                                                    # Process each server row
        wname       = row['srv_name']                                   # Extract Server Name
        wdesc       = row['srv_desc']                                   # Extract Server Desc.
        wdomain     = row['srv_domain']                                 # Extract Server Domain Name
        wos         = row['srv_osname']                                 # Extract Server O/S Name
        wsporadic   = row['srv_sporadic']                               # Extract Server Sporadic ?
        wmonitor    = row['srv_monitor']                                # Extract Server Monitored ?
        wosversion  = row['srv_osversion']                              # Extract Server O/S Version
        wssh_port   = row['srv_ssh_port']                               # Extract Server SSH Port
        wfqdn       = "%s.%s" % (wname, wdomain)                        # Construct FQDN
        #sa.write_log("\n%s" % ('-' * 40))                               # Insert 40 Dashes Line
        sa.write_log("  ")                                              # Blank Lime
        sa.write_log("Processing (%d) %-15s - %s %s %s" % (lineno,wfqdn,wos,wosversion,wdesc))  

        # Check if system name can be resolved,
        try:
            hostip = socket.gethostbyname(wfqdn)                        # Resolve Server Name ?
        except socket.gaierror:                                         # Hostname can't be resolve
            sa.write_err("[ ERROR ] Can't process %s, hostname can't be resolved" % (wfqdn))
            error_count += 1                                            # Increase Error Counter
            if (error_count != 0):                                      # If Error count not at zero
                sa.write_log("Total error(s) : %s" % (error_count))     # Show Total Error Count
            continue                                                    # Go read Next Server

        # Check if System is Locked.
        if sa.lock_status(wname) != 0:                                  # Is System Lock ?
            sa.write_err("[ WARNING ] System '%s' is currently lock." % (wname))
            sa.write_log("Continuing with next system")                 # Not Error if system lock
            continue                                                    # Go read Next Server

        # Perform a SSH to system currently processing
        #cur_datetime = datetime.datetime.now()                          # Get current Date & Time
        #ws_datetime  = cur_datetime.strftime("%Y/%m/%d %H:%M:%S")       # Format Date and Time
        ssh_command  = "%s -qnp %s -o ConnectTimeout=3 " % (sa.cmd_ssh,wssh_port)
        wcommand = "%s %s %s" % (ssh_command,wfqdn,"date")              # SSH Cmd to Server for date
        if pdebug > 0 : sa.write_log("Command is %s" % (wcommand))      # Show SSH Command in debug

        ccode,cstdout,cstderr = sa.oscommand("%s" % (wcommand))         # Get system date/time
        if (ccode == 0):                                                # If ssh Worked
            sa.write_log("[OK] SSH Succeeded %s" % (cstdout))           # OK + date/Time of system
        else:                                                           # If ssh didn't work
            if wsporadic:                                               # Is it a Sporadic Server
                sa.write_err("[ WARNING ] Can't SSH to sporadic system %s" % (wfqdn))
                sa.write_log("Continuing with next system")             # Not Error if Sporadic Srv.
                continue                                                # Continue with next system
            else:
                error_count += 1                                        # Increase Error Counter
                sa.write_err("[ ERROR ] SSH Error %d %s" % (ccode, cstderr))  
        if (error_count != 0): sa.write_log("Total error(s) : %s" % (error_count)) 
        lineno += 1                                                     # Increase Server Counter

    return (error_count)                                                # Return Err.Count to caller






# Main Process (Insert here your main process (Called when 'sa.db_used' is set to 'False'.)
# --------------------------------------------------------------------------------------------------
def main_process():

    sa.write_log ("Insert your code here.")
    sa.sleep(8,2)
    sa.write_log(" ")

    # Return Result code to caller
    return(pexit_code)





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
            pdebug (int)          : Set to the debug level [0-9] (Default is 0)
    """

    global pdebug                                                       # Script Debug Level (0-9)
    parser = argparse.ArgumentParser(description=pdesc)                 # Desc. is the script name

    # Declare Arguments
    parser.add_argument("-v",
                        action="store_true",
                        dest='version',
                        help="Show script version")
    parser.add_argument("-d",
                        metavar="0-9",
                        type=int,
                        dest='pdebug',
                        help="debug/verbose level from 0 to 9",
                        default=0)
    
    args = parser.parse_args()                                          # Parse the Arguments

    # Set return values accordingly.
    if args.pdebug:                                                  # Debug Level -d specified
        pdebug = args.pdebug                                      # Save Debug Level
        print("Debug Level is now set at %d" % (pdebug))             # Show user debug Level
    if args.version:                                                    # If -v specified
        sa.show_version(pver)                                           # Show Custom Show Version
        sys.exit(0)                                                     # Exit with code 0
    return(pdebug)                                                   # Return opt values





# Main Function
# --------------------------------------------------------------------------------------------------
def main(argv):
    (pdebug) = cmd_options(argv)                                        # Analyze cmdline options

    if sa.db_used : 
        (db_conn,db_cur) = sa.start(pver,pdesc)                         # Initialize SADMIN env.
        pexit_code = process_servers(db_conn,db_cur)                    # Loop All Active systems
        sa.stop(pexit_code,db_conn,db_cur)                              # Exit Gracefully & Close DB
    else: 
        sa.start(pver,pdesc)                                            # Initialize SADMIN env.
        pexit_code = main_process()                                  # Loop All Active systems
        sa.stop(pexit_code)                                             # Exit Gracefully SADMIN Lib
    sys.exit(pexit_code)                                                # Back to O/S with Exit Code

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)
