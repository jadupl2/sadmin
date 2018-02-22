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
# 2018_01_25 JDuplessis
#   V2.4 Added Variable SADM_RRDTOOL to sadmin.cfg display
# 2018_02_21 JDuplessis
#   V2.5 Minor Changes 
#===================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch             # Import Std Python3 Modules
    SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Root Dir. Name
    sys.path.insert(0,os.path.join(SADM,'lib'))                     # Add SADMIN to sys.path
    import sadmlib_std as sadm                                      # Import SADMIN Python Library
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                    # Activate Python Debugging


#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
#


#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
 
    # SADMIN TOOLS - Create SADMIN instance & setup variables specific to your program -------------
    st = sadm.sadmtools()                       # Create SADMIN Tools Instance (Setup Dir.)
    st.ver  = "2.5"                             # Indicate this script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'B'                           # Log Type  (L=Log file only  S=stdout only  B=Both)
    st.log_append = True                        # True=Append existing log  False=start a new log
    st.debug = 0                                # Debug level and verbosity (0-9)
    st.cfg_mail_type = 1                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    st.usedb = True                             # True=Use Database  False=DB Not needed for script
    st.dbsilent = False                         # Return Error Code & False=ShowErrMsg True=NoErrMsg
    #st.cfg_mail_addr = ""                      # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name  = ""                      # This Override Company Name specify in sadmin.cfg
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..
    if st.debug > 4: st.display_env()           # Under Debug - Display All Env. Variables Available

    # Insure that this script can only be run by the user root (Optional Code)
    #if not os.getuid() == 0:                                            # UID of user is not zero
    #    st.log_type = 'B'                                               # Make Sure Show on Scr+Log
    #    st.writelog ("This script must be run by the 'root' user")      # Advise User Message / Log
    #    st.writelog ("Try sudo ./%s" % (st.pn))                         # Suggest to use 'sudo'
    #    st.writelog ("Process aborted")                                 # Process Aborted Msg
    #    st.stop (1)                                                     # Close and Trim Log/Email
    #    sys.exit(1)                                                     # Exit with Error Code
    
    # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    if st.get_fqdn() != st.cfg_server:                                  # Only run on SADMIN
        st.log_type = 'B'                                               # Make Sure Show on Scr+Log
        st.writelog("This script can only be run on SADMIN server (%s)" % (st.cfg_server))
        st.writelog("Process aborted")                                  # Abort advise message
        st.stop(1)                                                      # Close and Trim Log
        sys.exit(1)                                                     # Exit To O/S

    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database
        st.writelog ("Database connection succeeded")
        st.exit_code = st.display_env()                                 # Display Env. Variables
        st.writelog ("Closing Database connection")
        st.dbclose()                                                    # Close the Database
    else:                                                               # Script don't need Database
        st.exit_code = st.display_env()                                 # Display Env. Variables
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()


