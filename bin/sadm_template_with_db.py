#! /usr/bin/env python3
# --------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Script Name :   XXXXXXXX.py
#   Date        :   2024/MM/DD
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
# 2024_01_19 lib v1.1 New template (replace sadm_template.py), used when you need to access SADMIN DB.
#
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
# SADMIN CODE SECTION v2.3
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
pver        = "1.4"                                                  # Program version no.
pdesc       = "Put here a description of your script."
phostname   = sa.get_hostname()                                      # Get current `hostname -s`
pdebug      = 0                                                      # Debug level from 0 to 9
pexit_code  = 0                                                      # Script default exit code

# Fields used by sa.start(),sa.stop() & DB functions that influence execution of SADMIN library
sa.db_used           = True       # Open/Use DB(True), No DB needed (False), sa.start() auto connect
sa.db_silent         = False      # When DB Error Return(Error), True = NoErrMsg, False = ShowErrMsg
sa.db_conn           = None       # Use this Database Connector when using DB,  set by sa.start()
sa.db_cur            = None       # Use this Database cursor if you use the DB, set by sa.start()
sa.db_name           = ""         # Database Name default to name define in $SADMIN/cfg/sadmin.cfg
sa.db_errno          = 0          # Database Error Number
sa.db_errmsg         = ""         # Database Error Message
#
sa.use_rch           = True       # Generate entry in Result Code History (.rch)
sa.log_type          = 'B'        # Output goes to [S]creen to [L]ogFile or [B]oth
sa.log_append        = False      # Append Existing Log(True) or Create New One(False)
sa.log_header        = True       # Show/Generate Header in script log (.log)
sa.log_footer        = True       # Show/Generate Footer in script log (.log)
sa.multiple_exec     = "Y"        # Allow running multiple copy at same time ?
sa.proot_only        = False      # Pgm run by root only ?
sa.psadm_server_only = True       # Run only on SADMIN server ?
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
# --------------------------------------------------------------------------------------------------
def process_servers():
    global db_conn, db_cur                                              # DB Connection & Cursor

    sa.write_log("Processing All Actives Server(s)")                    # Enter Servers Processing

    if sa.on_sadmin_server() == "N" and sa.psadm_server_only :
        print("You're not on a SADMIN server (%s).")
        return(1)
    
    if (sa.db_used == False) :
        print("The variable 'sa.db_used' must be set to 'True' to have access to the database")
        return(1)
    
    # See columns available in 'table_structure_server.pdf' in $SADMIN/doc/pdf/database directory
    sql = "SELECT * FROM server WHERE srv_active = %s order by srv_name;" % ('True')

    try:
        sa.db_cur.execute(sql)                                            # Execute SQL Statement
        rows = sa.db_cur.fetchall()                                       # Retrieve All Rows
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
        if sa.check_system_lock(wname) != 0:                            # Is System Lock ?
            sa.write_err("[ WARNING ] System '%s' is currently lock." % (wname))
            sa.write_log("Continuing with next system")                 # Not Error if system lock
            continue                                                    # Go read Next Server

        # Perform a SSH to system currently processing
        
        if sa.on_sadmin_server() == "Y" :                                 # SADMIN Server don't use ssh
            #sa.write_log("Valid SADMIN Server.")
            pass            
        else:                                                           # Not SADMIN server use ssh
            #sa.write_log("Not Valid SADMIN Server.")
            wcommand = "%s %s %s" % (sa.cmd_ssh_full, wfqdn, "date")    # SSH Cmd to Server for date
            sa.write_log("Command is %s" % (wcommand))                  # Show User what will do
            ccode, cstdout, cstderr = sa.oscommand("%s" % (wcommand))   # Execute O/S CMD
            if (ccode == 0):                                            # If ssh Worked
                sa.write_log("[OK] SSH Worked")                         # Inform User SSH Worked
            else:                                                       # If ssh didn't work
                if wsporadic:                                           # Is it a Sporadic Server
                    sa.write_err("[ WARNING ] Can't SSH to sporadic system %s" % (wfqdn))
                    sa.write_log("Continuing with next system")         # Not Error if Sporadic Srv.
                    continue                                            # Continue with next system
                else:
                    error_count += 1                                        # Increase Error Counter
                    sa.write_err("[ ERROR ] SSH Error %d %s" % (ccode, cstderr))  
        if (error_count != 0):                                          # If Error count not at zero
            sa.write_log("Total error(s) : %s" % (error_count))         # Show Total Error Count
        lineno += 1                                                     # Increase Server Counter
    return (error_count)                                                # Return Err.Count to caller





# Command line Options
# --------------------------------------------------------------------------------------------------
def cmd_options(argv):
    """ Command line Options functions - Evaluate Command Line Switch Options

        Args:
            (argv): Arguments pass on the command line.
              [-d 0-9]  Set Debug (verbose) Level
              [-h]      Show this help message
              [-v]      Show script version information
        Returns:
            debug_opt (int)          : Set to the debug level [0-9] (Default is 0)
    """

    debug_opt = 0                                                      # Script Debug Level (0-9)
    parser = argparse.ArgumentParser(description=pdesc)                 # Desc. is the script name

    # Declare Arguments
    parser.add_argument("-v",
                        action="store_true",
                        dest='version',
                        help="Show script version")
    parser.add_argument("-d",
                        metavar="0-9",
                        type=int,
                        dest='debug_opt',
                        help="debug/verbose level from 0 to 9",
                        default=0)
    
    args = parser.parse_args()                                          # Parse the Arguments

    # Set return values accordingly.
    if args.debug_opt:                                                  # Debug Level -d specified
        debug_opt = args.debug_opt                                      # Save Debug Level
        print("Debug Level is now set at %d" % (debug_opt))             # Show user debug Level
    if args.version:                                                    # If -v specified
        sa.show_version(pver)                                           # Show Custom Show Version
        sys.exit(0)                                                     # Exit with code 0
    return(debug_opt)                                                   # Return opt values





# Main Function
# --------------------------------------------------------------------------------------------------
def main(argv):
    (pdebug) = cmd_options(argv)                                        # Analyze cmdline options
    sa.start(pver, pdesc)                                               # Initialize SADMIN env.
    pexit_code = process_servers()                                     # Loop All Active systems
    sa.stop(pexit_code)                                                 # Gracefully exit SADMIN
    sys.exit(pexit_code)                                                # Back to O/S with Exit Code

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)
