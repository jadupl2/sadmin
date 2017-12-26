#!/usr/bin/env python3
#===================================================================================================
#   Author:     : Jacques Duplessis
#   Title:      : sadmlib_std.py
#   Version     :  1.0
#   Date        :  14 July 2017
#   Requires    :  python3 and SADM Library
#   Description :  SADM Python 3 Standard Library
#
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - http://www.sadmin.ca
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2017_07_07 JDuplessis 
#   V1.7 Minor Code enhancement
# 2017_07_31 JDuplessis 
#   V1.8 Added Log Template to script
# 2017_09_02 JDuplessis 
#   V1.9 Add Command line switch 
# 2017_09_02 JDuplessis
#   V2.0 Rewritten Part of script for performance and flexibility
# 2017_12_12 JDuplessis
#   V2.1 Adapted to use MySQL instead of Postgres Database
# 2017_12_23 JDuplessis
#   V2.3 Changes for performance and flexibility
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
#

#===================================================================================================
#                                 Initialize SADM Tools Function
#===================================================================================================
#
def initSADM():
    """
    Start the SADM Tools 
      - Make sure All SADM Directories exist, 
      - Open log in append mode if attribute log_append="Y", otherwise a new Log file is started.
      - Write Log Header
      - Record the start Date/Time and Status Code 2(Running) to RCH file
      - Check if Script is already running (pid_file) 
        - Advise user & Quit if Attribute multiple_exec="N"
    """

    # Making Sure SADMIN Environment Variable is Define and 'sadmlib_std.py' can be found & imported
    if not "SADMIN" in os.environ:                                      # SADMIN Env. Var. Defined ?
        print (('=' * 65))
        print ("SADMIN Environment Variable is not define")
        print ("It indicate the directory where you installed the SADMIN Tools")
        print ("Put this line in your ~/.bash_profile")
        print ("export SADMIN=/INSTALL_DIR")
        print (('=' * 65))
        sys.exit(1)
    try :
        SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Dir. Name
        sys.path.append(os.path.join(SADM,'lib'))                       # Add $SADMIN/lib to PyPath
        import sadmlib_std as sadm                                      # Import SADM Python Library
        #import sadmlib_mysql as sadmdb
    except ImportError as e:
        print ("Import Error : %s " % e)
        sys.exit(1)

    st = sadm.sadmtools()                                               # Create Sadm Tools Instance
    
    # Variables are specific to this program, change them if you want or need to -------------------
    st.ver  = "2.3"                             # Your Script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'L'                           # Log Type  L=LogFileOnly  S=StdOutOnly  B=Both
    st.log_append = True                        # True=Append to Existing Log  False=Start a new log
    st.debug = 5                                # Debug Level (0-9)
    
    # When script ends, send Log by Mail [0]=NoMail [1]=OnlyOnError [2]=OnlyOnSuccess [3]=Allways
    st.cfg_mail_type = 1                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    #st.cfg_mail_addr = ""                      # Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name  = ""                      # Override Company Name specify in sadmin.cfg

    # False = On MySQL Error, return MySQL Error Code & Display MySQL  Error Message
    # True  = On MySQL Error, return MySQL Error Code & Do NOT Display Error Message
    st.dbsilent = False                         # True or False

    # Start the SADM Tools 
    #   - Make sure All SADM Directories exist, 
    #   - Open log in append mode if st_log_append="Y" else create a new Log file.
    #   - Write Log Header
    #   - Write Start Date/Time and Status Code 2(Running) to RCH file
    #   - Check if Script is already running (pid_file) 
    #       - Advise user & Quit if st-multiple_exec="N"
    st.start()                                  # Make SADM Sertup is OK - Initialize SADM Env.

    return(st)                                  # Return Instance Object to caller


#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    st = initSADM()                                                     # Initialize SADM Tools

    # Insure that this script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
       st.writelog ("This script must be run by the 'root' user")       # Advise User Message / Log
       st.writelog ("Try sudo ./%s" % (sadm.pn))                        # Suggest to use 'sudo'
       st.writelog ("Process aborted")                                  # Process Aborted Msg
       st.stop (1)                                                      # Close and Trim Log/Email
       sys.exit(1)                                                      # Exit with Error Code
    
    # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    if st.get_fqdn() != st.cfg_server:                                  # Only run on SADMIN
        st.writelog("This script can only be run on SADMIN server (%s)" % (st.cfg_server))
        st.writelog("Process aborted")                                  # Abort advise message
        st.stop(1)                                                      # Close and Trim Log
        sys.exit(1)                                                     # Exit To O/S

    st.display_env()                                                    # Display Env. Variables
    if st.get_fqdn() == st.cfg_server:                                  # If Run on SADMIN Server
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database
    if st.get_fqdn() == st.cfg_server:                                  # If Run on SADMIN Server
        st.dbclose()                                                    # Close the Database
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()


