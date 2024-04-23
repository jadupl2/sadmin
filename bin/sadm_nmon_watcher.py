#! /usr/bin/env python3
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_nmon_watcher.py
#   Date        :   2023_07_07
#   Requires    :   python3 and SADMIN Python Library
#   Description :   Make sure the 'nmon' performance monitor is running.
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
# 2023_07_11 lib v1.2 Complete rewrite, new version in Python (lot more faster).
# 2023_07_26 lib v1.3 Enhance 'nmon' instance detection.
# 2023_08_14 lib v1.4 Make sure only one instance of 'nmon' in running.
# 2023_08_17 lib v1.5 Update to SADMIN section v2.3, fix 'pymysql' error msg & added log verbosity.
# 2023_11_29 lib v1.6 Crash when could not start 'nmon' (performance monitor).
# 2023_12_03 lib v1.7 Fix problem starting 'nmon' at system startup.
# --------------------------------------------------------------------------------------------------
#
# Modules needed by this script SADMIN Tools and they all come with Standard Python 3.
try:
    import os,sys,argparse,datetime,time                             # Import Std Python3 Modules
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
pver        = "1.7"                                                  # Program version no.
pdesc       = "This script ensure that 'nmon' performance monitor is running."
phostname   = sa.get_hostname()                                      # Get current `hostname -s`
pdebug      = 0                                                      # Debug level from 0 to 9
pexit_code  = 0                                                      # Script default exit code

# Fields used by sa.start(), sa.stop() & DB functions to influence execution of SADMIN library
sa.db_used     = False          # Open/Use DB(True), No DB needed (False), sa.start() auto connect
sa.db_silent   = False          # True=ReturnErrorNo & No ErrMsg, False=ReturnErrorNo & ShowErrMsg
sa.db_conn     = None           # Use this Database Connector when using DB,  set by sa.start()
sa.db_cur      = None           # Use this Database cursor if you use the DB, set by sa.start()
sa.db_name     = "sadmin"       # Database Name taken from $SADMIN/cfg/sadmin.cfg 
sa.db_errno    = 0              # Database Error Number
sa.db_errmsg   = ""             # Database Error Message
#
sa.use_rch           = True       # Generate entry in Result Code History (.rch)
sa.log_type          = 'B'        # Output goes to [S]creen to [L]ogFile or [B]oth
sa.log_append        = True       # Append Existing Log(True) or Create New One(False)
sa.log_header        = True       # Show/Generate Header in script log (.log)
sa.log_footer        = True       # Show/Generate Footer in script log (.log)
sa.multiple_exec     = "Y"        # Allow running multiple copy at same time ?
sa.proot_only        = False      # Pgm run by root only ?
sa.psadm_server_only = False      # Run only on SADMIN server ?
sa.cmd_ssh_full = "%s -qnp %s -o ConnectTimeout=2 -o ConnectionAttempts=2 " % (sa.cmd_ssh,sa.sadm_ssh_port)

# The values of fields below, are loaded from sadmin.cfg when you import the SADMIN library.
# Change them to fit your need, they influence execution of SADMIN standard library
#sa.sadm_alert_type  = 1          # 0=NoAlert 1=AlertOnlyOnError 2=AlertOnlyOnSuccess 3=AlwaysAlert
#sa.sadm_alert_group = "default"  # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
sa.max_logline      = 400        # Max. lines to keep in log (0=No trim) after execution.
sa.max_rchline      = 20         # Max. lines to keep in rch (0=No trim) after execution.
#sa.sadm_mail_addr   = ""         # All mail goes to this email (Default is in sadmin.cfg)
#sa.pid_timeout      = 7200       # PID File Default Time to Live in seconds.
#sa.lock_timeout     = 3600       # A host can be lock for this number of seconds, auto unlock after
# ==================================================================================================



# Global Variables Definition
# --------------------------------------------------------------------------------------------------
nmon_name="nmon"                                                        # Nmon process name




# Check if process name received is running and return number of process running it.
# --------------------------------------------------------------------------------------------------
def count_process(pname): 

    """
    Check if the name of the process received is running.
        
    Argument:
        pname (str) :  Name of process to verify.

    Return:
        pcount (Int): Is the number of 'pname' running (0 if none).
    """ 
    ccode,cstdout,cstderr = sa.oscommand("pgrep -c %s" % pname)  
    pcount=int(cstdout)
    #sa.write_log ("There is %d '%s' process running." % (pcount,pname))
    if ccode != 0 : return(0)
    return(pcount)





# Main Process (Used to run script on current server)
# --------------------------------------------------------------------------------------------------
def main_process():
    pexit_code = 0 

    # If we are on MacOS (nmon not available), don't watch the nmon daemon and exit to O/S.
    if sa.get_ostype() == "DARWIN"  :                                   # nmon not available on OSX
        sa.write_err("Command 'nmon' isn't available on MacOS.")        # Advise user that won't run
        sa.write_err("Script terminating.")                             # Process can't continue
        return(0)                                                       # Return to caller, no error

    # If 'nmon' package is not installed 
    if sa.cmd_nmon == "" :
        sa.write_err("The 'nmon' package isn't installed on this system.")
        sa.write_err("Script aborted.")
        return(1)                                                       # Return error to caller

    # If nmon is started by cron within /etc/cron.d/nmon-script - Put crontab line in comment
    # Want to make sure that only one 'nmon' is running and it's the one controlled by SADMIN.
    nmon_cron='/etc/cron.d/nmon-script'                                 # Name of the nmon cron file
    if os.path.exists(nmon_cron) :                                      # Does nmon cron file exist
        f = open(nmon_cron, "r")                                        # Open the nmon cron file
        lines = f.readlines()                                           # Put all lines in memory
        f.close()                                                       # Close the nmon cron file
        output_lines = []                                               # Create empty cron array
        for line in lines:
            #line = line.strip()                                        # Strip CR/LF & Trail spaces
            if line.strip()[0:1] == '#' :                               # If comment or blank line
                output_lines.append(line)
            else:
                output_lines.append("#" + line)
        f = open(nmon_cron, "w")                                        # Open nmon cron file 
        f.write("\n".join(output_lines))                                # Write output array to it
        f.close()                                                       # Close new nmon cron file.

    # Check how many 'nmon' process are running
    pcount = count_process(nmon_name)
    if pcount == 1 :
        sa.write_log("There is %d process of '%s' running." % (pcount,nmon_name))
        ccode, cstdout, cstderr = sa.oscommand("ps -ef | grep '/nmon ' | grep -v grep") 
        sa.write_log(cstdout)
        return(0)

    # If more than one process: Kill them for now and will return it later on
    if pcount > 1: 
        sa.write_log("There should be only 1 '%s' process running, we now have %d." % (nmon_name,pcount))
        ccode, cstdout, cstderr = sa.oscommand("ps -ef | grep '/nmon ' | grep -v grep") 
        sa.write_log(cstdout)
        sa.write_log("We will stop them all and restart a fresh copy of '%s' daemon." % (nmon_name))
        ccode = cstdout = cstderr = "" 
        ccode,cstdout,cstderr = sa.oscommand("pkill -9 nmon")
        if pdebug > 0 : 
            sa.write_log ("oscommand function stdout is     : %s" % (cstdout))
            sa.write_log ("oscommand function stderr is     : %s" % (cstderr))
            sa.write_log ("oscommand function returncode is : %s" % (ccode))
        if ccode != 0 : 
            sa.write_err ("Wasn't able to kill all 'nmon' instance.")
            ccode, cstdout, cstderr = sa.oscommand("ps -ef | grep '/nmon ' | grep -v grep") 
            sa.write_err(cstdout)
            return(1)


    # Current date/time and epoch time
    current_epoch = sa.get_epoch_time()                                 # Cur. epoch time
    current_date  = sa.epoch_to_date(current_epoch)                     # Cur. 'YYYY.MM.DD HH:MM:SS'

    # End of day date/Time (Today at 23:59:00) to close and restart nmon 
    i = datetime.datetime.now()                                         # Get Current Date/Time
    end_of_day_date = i.strftime('%Y.%m.%d') + " 23:58:00"              # Today at 23:58:00
    end_of_day_epoch = sa.date_to_epoch(end_of_day_date)                # End of day epoch 

    # Calculated number of snapshot from now to end of day at 23:59¨20)
    total_seconds = int(end_of_day_epoch - current_epoch)               # Nb Sec. between now & 23:59
    total_minutes = int(total_seconds / 60)                             # Nb of Minutes till 23:59
    total_snapshots = int(total_minutes / 2)                            # Nb. of 2 Min till 23:59

    if pdebug > 0 : 
        sa.write_log ("----------------------")
        sa.write_log ("current_epoch                  = %d" % current_epoch)
        sa.write_log ("current_date                   = %s" % current_date)
        sa.write_log ("end_of_day_date                = %s" % end_of_day_date)
        sa.write_log ("end_of_day_epoch               = %d" % end_of_day_epoch)
        sa.write_log ("total_seconds till 23:58:00    = %d" % total_seconds)
        sa.write_log ("total_minutes 23:58:00         = %d" % total_minutes)
        sa.write_log ("total_snapshots till 23:58:00  = %d" % total_snapshots)
        sa.write_log ("----------------------")
        sa.write_log (" ")


    sa.write_log ("The 'nmon' daemon is not running.")
    sa.write_log ("We will start a fresh one that will terminate at 23:58.")
    sa.write_log ("We calculated that there will be %d snapshots till then." % (total_snapshots))

    CMD = "%s -f -s120 -c%d -t -m %s " % (sa.cmd_nmon,total_snapshots,sa.dir_nmon)
    sa.write_log ("Starting 'nmon' daemon ...")
    sa.write_log ("Running : %s" % (CMD))
    ccode, std_out, std_err = sa.oscommand(CMD)                    
    time.sleep(5)               # Time to come up
    pcount = count_process(nmon_name)
    ccode, cstdout, cstderr = sa.oscommand("ps -ef | grep '/nmon ' | grep -v grep") 
    sa.write_log("pcount=%d before starting it %s" % (pcount,cstdout))
    if pcount == 1 :
        sa.write_log("[ OK ] Process named '%s' is now running." % (nmon_name))
        ccode, cstdout, cstderr = sa.oscommand("ps -ef | grep '/nmon ' | grep -v grep") 
        sa.write_log(cstdout)
        pexit_code = 0
    else : 
        sa.write_err("[ ERROR ] The 'nmon' daemon (%d), could not be started." % (pcount))
        ccode, cstdout, cstderr = sa.oscommand("ps -ef | grep '/nmon ' | grep -v grep") 
        sa.write_log(cstdout)
        sa.write_err("%s - %s" % (std_out,std_err))
        pexit_code = 1 
    return(pexit_code)





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

    debug_opt = 0                                                       # Script Debug Level (0-9)
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
    if args.debug_opt:                                                 # Debug Level -d specified
        debug_opt = args.debug_opt                                    # Save Debug Level
        print("Debug Level is now set at %d" % (debug_opt))            # Show user debug Level
    if args.version:                                                    # If -v specified
        sa.show_version(pver)                                           # Show Custom Show Version
        sys.exit(0)                                                     # Exit with code 0
    return(debug_opt)                                                  # Return opt values





# Main Function
# --------------------------------------------------------------------------------------------------
def main(argv):
    pdebug = cmd_options(argv)                                          # Analyze cmdline options
    sa.start(pver, pdesc)                                               # Initialize SADMIN env.
    pexit_code = main_process()                                         # Main Process
    sa.stop(pexit_code)                                                 # Gracefully exit SADMIN
    sys.exit(pexit_code)                                                # Back to O/S with Exit Code

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)
