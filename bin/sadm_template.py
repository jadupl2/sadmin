#! /usr/bin/env python3
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Script Name :   XXXXXXXX.py
#   Date        :   YYYY/MM/DD
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
# 2022_05_09 lib v1.0 New Python template using V2 of SADMIN python library.
# 2022_05_25 lib v1.1 Two new variables 'sa.proot_only' & 'sa.psadm_server_only' control pgm env.
#
# --------------------------------------------------------------------------------------------------
#
# Modules needed by this script SADMIN Tools and they all come with Standard Python 3.
try:
    import os, sys, argparse, time, datetime, socket, platform      # Import Std Python3 Modules
    import pymysql                                                  # Use for MySQL DB
#   import pdb                                                      # Python Debugger (If needed)
except ImportError as e:                                            # Trap Import Error
    print("Import Error : %s " % e)                                 # Print Import Error Message
    sys.exit(1)                                                     # Back to O/S With Error Code 1
#pdb.set_trace()                                                    # Activate Python Debugging




# --------------------------------------------------------------------------------------------------
# SADMIN CODE SECTION v2.2a
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your Python code.    
# --------------------------------------------------------------------------------------------------
try:
    SADM = os.environ.get('SADMIN')                                  # Get SADMIN Env. Var. Dir.
    sys.path.insert(0, os.path.join(SADM, 'lib'))                    # Add $SADMIN/lib to sys.path
    import sadmlib2_std as sa                                        # Load SADMIN Python Library
except ImportError as e:                                             # If Error importing SADMIN
    print("Import error : SADMIN module: %s " % e)                   # Advise User of Error
    sys.exit(1)                                                      # Go Back to O/S with Error

# Local variables local to this script.
pver        = "1.1"                                                  # Program version no.
pdesc       = "Update 'pdesc' variable & put a description of your script."
phostname   = sa.get_hostname()                                      # Get current `hostname -s`
pdb_conn    = None                                                   # Database connector
pdb_cur     = None                                                   # Database cursor
pdebug      = 0                                                      # Debug level from 0 to 9
pexit_code  = 0                                                      # Script default exit code

# Uncomment anyone to change them to influence execution of SADMIN standard library.
sa.proot_only        = True       # Pgm run by root only ?
sa.psadm_server_only = True       # Run only on SADMIN server ?
sa.db_used           = True       # Open/Use Database(True) or Don't Need DB(False)
sa.use_rch           = True       # Generate entry in Result Code History (.rch)
sa.log_type          = 'B'        # Output goes to [S]creen to [L]ogFile or [B]oth
sa.log_append        = False      # Append Existing Log(True) or Create New One(False)
sa.log_header        = True       # Show/Generate Header in script log (.log)
sa.log_footer        = True       # Show/Generate Footer in script log (.log)
sa.multiple_exec     = "Y"        # Allow running multiple copy at same time ?
sa.db_silent         = False      # When DB Error, False=ShowErrMsg, True=NoErrMsg
sa.cmd_ssh_full      = "%s -qnp %s " % (sa.cmd_ssh, sa.sadm_ssh_port) # SSH Cmd to access clients

# The values of fields below, are loaded from sadmin.cfg when you import the SADMIN library.
# You can change them to fit your need
#sa.sadm_alert_type  = 1          # 0=NoAlert 1=AlertOnlyOnError 2=AlertOnlyOnSuccess 3=AlwaysAlert
#sa.sadm_alert_group = "default"  # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
#sa.max_logline      = 500        # Max. lines to keep in log (0=No trim) after execution.
#sa.max_rchline      = 40         # Max. lines to keep in rch (0=No trim) after execution.
#sa.sadm_mail_addr   = ""         # All mail goes to this email (Default is in sadmin.cfg)
#sa.pid_timeout      = 7200       # PID File Default Time to Live in seconds.
#sa.lock_timeout     = 3600       # A host can be lock for this number of seconds, auto unlock after
# ==================================================================================================




# Scripts Global Variables
# --------------------------------------------------------------------------------------------------








# Process all your active(s) server(s) in the Database (Used if want to process selected servers)
# --------------------------------------------------------------------------------------------------
def process_servers():
    global pdb_conn, pdb_cur                                            # DB Connection & Cursor

    sa.write_log("Processing All Actives Server(s)")                    # Enter Servers Processing
    if (sa.get_fqdn() != sa.sadm_server) or (sa.db_used == False):      # Not SADMIN srv,usedb False
        print("Can't use function 'process_servers' : ")    
        print("   1) If 'sa.db_used' is set to 'False'.")
        print("   2) If you're not on the SADMIN server (%s)." % (sa.sadm_server))
        return(1)
    
    # See columns available in 'table_structure_server.pdf' in $SADMIN/doc/pdf/database directory
    sql = "SELECT * FROM server WHERE srv_active = %s order by srv_name;" % ('True')

    try:
        pdb_cur.execute(sql)                                            # Execute SQL Statement
        rows = pdb_cur.fetchall()                                       # Retrieve All Rows
    except(pymysql.err.InternalError, pymysql.err.IntegrityError, pymysql.err.DataError) as error:
        enum, emsg = error.args                                         # Get Error No. & Message
        sa.write_err("Error: Retrieving all active systems rows.")      # User error message
        sa.write_err("%s %s" % (enum, emsg))                            # Print Error No. & Message
        return (1)                                                      # Return error to caller

    # Process each Active Servers
    lineno = 1                                                          # System Counter Start at 1
    error_count = 0                                                     # Error Counter
    for row in rows:                                                    # Process each server row
        wname = row['srv_name']                                         # Extract Server Name
        wdesc = row['srv_desc']                                         # Extract Server Desc.
        wdomain = row['srv_domain']                                     # Extract Server Domain Name
        wos = row['srv_osname']                                         # Extract Server O/S Name
        wsporadic = row['srv_sporadic']                                 # Extract Server Sporadic ?
        wmonitor = row['srv_monitor']                                   # Extract Server Monitored ?
        wosversion = row['srv_osversion']                               # Extract Server O/S Version
        wfqdn = "%s.%s" % (wname, wdomain)                              # Construct FQDN
        sa.write_log("\n%s" % ('-' * 40))                               # Insert 40 Dashes Line
        sa.write_log("Processing (%d) %-15s - %s %s" % (lineno, wfqdn, wos, wosversion))  
        sa.write_log(wdesc)                                             # Host Desciption

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
        if sa.check_system_lock(wname) != 0:                               # If System is Lock
            sa.write_err("[ WARNING ] System '%s' is currently lock." % (wname))
            sa.write_log("Continuing with next system")                 # Not Error if system lock
            continue                                                    # Go read Next Server

        # Perform a SSH to system currently processing
        wcommand = "%s %s %s" % (sa.cmd_ssh_full, wfqdn, "date")           # SSH Cmd to Server for date
        sa.write_log("Command is %s" % (wcommand))                      # Show User what will do
        ccode, cstdout, cstderr = sa.oscommand("%s" % (wcommand))       # Execute O/S CMD
        if (ccode == 0):                                                # If ssh Worked
            sa.write_log("[OK] SSH Worked")                             # Inform User SSH Worked
        else:                                                           # If ssh didn't work
            if wsporadic:                                               # Is it a Sporadic Server
                sa.write_err("[ WARNING ] Can't SSH to sporadic system %s" % (wfqdn))
                sa.write_log("Continuing with next system")             # Not Error if Sporadic Srv.
                continue                                                # Continue with next system
            else:
                error_count += 1                                        # Increase Error Counter
                sa.write_err("[ ERROR ] SSH Error %d %s" % (ccode, cstderr))  
        if (error_count != 0):                                          # If Error count not at zero
            sa.write_log("Total error(s) : %s" % (error_count))         # Show Total Error Count
        lineno += 1                                                     # Increase Server Counter
    return (error_count)                                                # Return Err.Count to caller





# Main Process (Used to run script on current server)
# --------------------------------------------------------------------------------------------------
def main_process():

    # Insert your code HERE !
    sa.sleep(10,2)

    # Return Err. Code To Caller
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
            sadm_debug (int)          : Set to the debug level [0-9] (Default is 0)
    """

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





# Main Function
# --------------------------------------------------------------------------------------------------
def main(argv):
    global pdb_conn, pdb_cur                                            # DB Connection & Cursor
    (pdebug) = cmd_options(argv)                                        # Analyse cmdline options

    pexit_code = 0                                                      # Pgm Exit Code Default
    sa.start(pver, pdesc)                                               # Initialize SADMIN env.

    # Execute script main function (Choose one of the two functions to execute)
    # (1) 'process_servers' : Loop through your actives systems and do a 'ssh date' on each of them.
    #      Uncomment 'sa.db_used = True' in SADMIN section at the begiing of this script.
    # (2) 'main_Process'    : Process not related to DB, you decide what you put in there.
    if sa.get_fqdn() == sa.sadm_server and sa.db_used :                 # On SADMIN srv & usedb True
        (pexit_code, pdb_conn, pdb_cur) = sa.db_connect('sadmin')       # Connect to SADMIN Database
        if pexit_code == 0:                                             # If Connection to DB is OK
            pexit_code = process_servers()                              # Loop All Active systems
            sa.db_close(pdb_conn, pdb_cur)                              # Close connection to DB
    else: 
        pexit_code = main_process()                                     # Main Process without DB

    sa.stop(pexit_code)                                                 # Gracefully exit SADMIN
    sys.exit(pexit_code)                                                # Back to O/S with Exit Code

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)
