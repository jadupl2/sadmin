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
# 2024_01_21 lib v1.56 Python standard template, can be use to create your next scripts.
#                      Need to access SADMIN database ? : Use 'sadm_template_with_db.py' instead.
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
pver        = "1.3"                                                  # Program version no.
pdesc       = "Put here a description of your script."
phostname   = sa.get_hostname()                                      # Get current `hostname -s`
pdebug      = 0                                                      # Debug level from 0 to 9
pexit_code  = 0                                                      # Script default exit code

# Fields used by sa.start(),sa.stop() & DB functions that influence execution of SADMIN library
sa.db_used           = False      # Open/Use DB(True), No DB needed (False), sa.start() auto connect
sa.db_silent         = False      # True=ReturnErrorNo & No ErrMsg, False=ReturnErrorNo & ShowErrMsg
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








# Main Process (Used to run script on current server)
# --------------------------------------------------------------------------------------------------
def main_process():

    # Insert your code HERE !
    sa.sleep(8,2)

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
    pexit_code = main_process()                                         # Main Process without DB
    sa.stop(pexit_code)                                                 # Gracefully exit SADMIN
    sys.exit(pexit_code)                                                # Back to O/S with Exit Code

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)
