#!/usr/bin/env python3
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_database_update.py
#   Synopsis:   Read all /sadmin/www/dat/{HOSTNAME}/dr/{HOSTNAME}&  update the Database based 
#               on the content of these files.
#===================================================================================================
# Description
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
#===================================================================================================
#  March 2017 - Jacques Duplessis
#       V2.3 -  To eliminate duplicate field separator with Mac Address 
#               Change field separator in HOSTNAME_sysinfo.txt file from : to = 
#               Add Error Exception when getting Value
#               Add time to Last_Daily_Update Column (Timestamp) in the SADM Database
#
# April 2017 -  Jacques Duplessis 
#       V2.4 -  Change exception Error Message more verbose
#
# 2017_11_23 -  Jacques Duplessis
#       V2.5 -  Move from PostGres to MySQL, New SADM Python Library and Performance Enhanced.
#
#
#===================================================================================================
import os, time, sys, pdb, socket, datetime, glob, fnmatch
#pdb.set_trace()                                                        # Activate Python Debugging

# Add SADM Library Path to Python Path and Import SADM Python Library
if (os.environ.get('SADMIN')):                                          # Is SADMIN Env.Var. Defined
    sys.path.append(os.path.join(os.environ.get('SADMIN'),'lib'))       # Add $SADMIN/lib to PyPath
else:
    print ("SADMIN Environment variable need to be define")
    print ("It indicate the directory where you installed SADMIN")
    print ("Put this line in your ~/.bash_profile")
    print ("export SADMIN=/INSTALL_DIR")
import sadmlib_std as sadm                                              # Import SADM Python Library
#import sadmlib_mysql as sadmdb

#===================================================================================================
#                                 Initialize SADM Tools Function
#===================================================================================================
#
def initSADM():
    st = sadm.sadmtools()                       # create Sadm Tools instance
    st.set_max_logline(5000)                    # Maximum Nb of line in log
    st.cfg_max_rchline(100)                     # Maximum Nb Lines in RCH (Return Code History) file
    st.log_type = 'S'                           # LogType L=LogFileOnly S=StdOutOnly B=Both
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script
    st.log_append = "Y"                         # Append Existing Log ? (Or allways start a new one)
    st.cfg_mail_type = 0                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    st.cfg_mail_addr = ""                       # Override Default Email Address is in sadmin.cfg
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='3.2'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time


    st.cfg_cie_name       = ""                                    # Company Name
    st.cfg_nmon_keepdays  = 60                  # Delete *.nmon files older than 60 days
    st.cfg_sar_keepdays   = 60                  # Delete *.sar  files older than 60 days
    st.cfg_rch_keepdays   = 60                  # Delete *.rch  files older than 60 days
    st.cfg_log_keepdays   = 60                  # Delete *.log  files older than 60 days

    print ("st.cfg_mail_type = %d" % st.cfg_mail_type)
    print ("Get Log Type = %s" % st.get_log_type())
    print ("Max Log Line %s" % st.get_max_logline())
    st.start()


#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    initSADM()
    print ("Max Log Line %s" % st.get_max_logline())
    print ("Get Log Type = %s" % st.get_log_type())
    print ("Log Directory is %s" % st.log_dir)
    print ("st.cfg_mail_type = %d" % st.cfg_mail_type)
    print ("Configuration File is %s" % st.cfg_file)
    st.writelog("test writelog")
    print ("Release File is %s" % st.rel_file)
    st.display_env();

    st.stop(0)


#    st.writelog('Test Message')

        #sadm.start()                                                        # Open Log, Create Dir ...

    # # Test if script is run by root (Optional Code)
    # if os.geteuid() != 0:                                               # UID of user is not zero
    #     sadm.writelog("This script must be run by the 'root' user")     # Advise User Message / Log
    #     sadm.writelog("Process aborted")                                # Process Aborted Msg
    #     sadm.stop(1)                                                    # Close and Trim Log/Email
    #     sys.exit(1)                                                     # Exit with Error Code

    # # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    # if socket.getfqdn() != sadm.cfg_server:                             # Only run on SADMIN
    #     sadm.writelog("Script can only be run on SADMIN server (%s)", (sadm.cfg_server))
    #     sadm.writelog("Process aborted")                                # Abort advise message
    #     sadm.stop(1)                                                    # Close and Trim Log
    #     sys.exit(1)                                                     # Exit To O/S

    # if sadm.debug > 4: sadm.display_env()                               # Display Env. Variables
    # (conn,cur) = sadm.open_sadmin_database()                            # Open Connection 2 Database
    # colnames = get_columns_name(conn,cur, "sadm.server")                # Get Server Table Col Name
    # sadm.exit_code=process_active_servers(conn, cur, colnames)          # Process Active Servers
    # sadm.close_sadmin_database(conn, cur)                               # Close Database Connection
    # sadm.stop(sadm.exit_code)                                           # Close log & trim
    # sys.exit(sadm.exit_code)                                            # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
