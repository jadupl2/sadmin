#!/usr/bin/env python3
# ==================================================================================================
#   Author      :   Jacques Duplessis
#   Date        :   2017-09-09
#   Name        :   sadm_setup.py
#   Synopsis    :
#   Licence     :   You can redistribute it or modify under the terms of GNU General Public 
#                   License, v.2 or above.
# ==================================================================================================
#   Copyright (C) 2016-2017 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is a free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2018_01_18 JDuplessis 
#   V1.0 Initial Version
#   V1.0b WIP Version
#
#===================================================================================================
try :
    import os, time, sys, pdb, socket, datetime, glob, fnmatch, pymysql
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                        # Activate Python Debugging


#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
sadm_base_dir       = ""                                                # SADMI Install Directory
#

#===================================================================================================
#                                 Initialize SADM Tools Function
#===================================================================================================
#
def initSADM():
    # Making Sure SADMIN Environment Variable is Define & import 'sadmlib_std.py' if can be found.
    if not "SADMIN" in os.environ:                                      # SADMIN Env. Var. Defined ?
        print ("SADMIN Environment Variable isn't define")              # SADMIN Var MUST be defined
        print ("It indicate the directory where you installed the SADMIN Tools")
        print ("Add this line at the end of /etc/environment file.")    # Show Where to Add Env. Var
        print ("# echo 'SADMIN=/[dir-where-you-install-sadmin]'")       # Show What to Add.
        sys.exit(1)                                                     # Exit to O/S with Error 1
    try :
        SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Dir. Name
        sys.path.append(os.path.join(SADM,'lib'))                       # Add $SADMIN/lib to PyPath
        import sadmlib_std as sadm                                      # Import SADM Python Library
    except ImportError as e:                                            # Catch import Error
        print ("Import Error : %s " % e)                                # Advise user about error
        sys.exit(1)                                                     # Exit to O/S with Error 1
    
    # Create SADMIN Instance & setup instance Variables specific to your program
    st = sadm.sadmtools()                       # Create Sadm Tools Instance (Setup Dir.)
    st.ver  = "1.0b"                            # Indicate your Script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'B'                           # Log Type  (L=Log file only  S=stdout only  B=Both)
    st.log_append = True                        # True to Append Existing Log, False=Start a new log
    st.debug = 0                                # Debug Level and Verbosity (0-9)
    st.cfg_mail_type = 1                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    #st.cfg_mail_addr = ""                      # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name  = ""                      # This Override Company Name specify in sadmin.cfg
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..
    return(st)                                  # Return Instance Object to caller


#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():

    if "SADMIN" in os.environ:                                          # Is SADMIN Env. Var. Exist?
        sadm_base_dir = os.environ.get('SADMIN')                        # Set SADMIN Base Directory
    else:
        sadm_base_dir = input("Directory where your install SADMIN ")

    if not os.path.exists(sadm_base_dir) :                              # Check if SADM Dir. Exist
        print ("Directory %s doesn't exist." % (sadm_base_dir))         # Advise User
        sys.exit(1)                                                     # Exit with Error Code
        
    st = initSADM()                                                     # Initialize SADM Tools

    # Insure that this script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
       st.writelog ("This script must be run by the 'root' user")       # Advise User Message / Log
       st.writelog ("Try sudo ./%s" % (st.pn))                          # Suggest to use 'sudo'
       st.writelog ("Process aborted")                                  # Process Aborted Msg
       st.stop (1)                                                      # Close and Trim Log/Email
       sys.exit(1)                                                      # Exit with Error Code
    
    # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    if st.get_fqdn() != st.cfg_server:                                  # Only run on SADMIN
        st.writelog("This script can only be run on SADMIN server (%s)" % (st.cfg_server))
        st.writelog("Process aborted")                                  # Abort advise message
        st.stop(1)                                                      # Close and Trim Log
        sys.exit(1)                                                     # Exit To O/S
        
    if st.debug > 4: st.display_env()                                   # Display Env. Variables
    if st.get_fqdn() == st.cfg_server:                                  # If Run on SADMIN Server
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database
    st.exit_code = process_servers(conn,cur,st)                         # Process Actives Servers 
    #st.exit_code = main_process(conn,cur,st)                           # Process Unrelated 2 server 
    if st.get_fqdn() == st.cfg_server:                                  # If Run on SADMIN Server
        st.dbclose()                                                    # Close the Database
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()