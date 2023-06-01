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
# SADMIN PYTHON CODE SECTION v2.2a
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
sa.proot_only        = True       # Program run by root only ?
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











# Main Process (Used to run script on current server)
# --------------------------------------------------------------------------------------------------
def main_process():

    if sa.get_osname() == "DARWIN" :                                    # nmon not available on OSX
        sa.write_log ("Command 'nmon' isn't available on MacOS")        # Advise user that won't run
        sa.write_log ("Script can't continue, terminating.")            # Process can't continue
        return(0)                                                       # Return to caller


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

    (pdebug) = cmd_options(argv)                                        # Analyze cmdline options
    sa.start(pver, pdesc)                                               # Initialize SADMIN env.
    pexit_code = main_process()                                         # Main Process without DB
    sa.stop(pexit_code)                                                 # Gracefully exit SADMIN
    sys.exit(pexit_code)                                                # Back to O/S with Exit Code

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)