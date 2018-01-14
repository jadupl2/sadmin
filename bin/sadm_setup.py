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
    st.ver  = "2.7"                             # Your Script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'B'                           # Log Type  L=LogFileOnly  S=StdOutOnly  B=Both
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
#                                Process All Actives Servers 
#===================================================================================================
def process_servers(wconn,wcur,st):
    st.writelog ("Processing All Actives Server(s)")

    # Construct SQL to Read All Actives Servers
    sql  = "SELECT srv_name, srv_desc, srv_domain, srv_osname, "
    sql += " srv_ostype, srv_sporadic, srv_monitor, srv_osversion "
    sql += " FROM server WHERE srv_active = %s " % ('True')
    sql += " order by srv_name;"
    try :
        wcur.execute(sql)
        rows = wcur.fetchall()
    except(pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as error:
        self.enum, self.emsg = error.args                               # Get Error No. & Message
        print (">>>>>>>>>>>>>",self.enum,self.emsg)                     # Print Error No. & Message
        return (1)
    
    # Process each Actives Servers
    lineno = 1                                                          # Server Counter Start at 1
    total_error = 0                                                     # Total Error Start at 0
    for row in rows:                                                    # Process each server row
        wname       = row[0]                                            # Extract Server Name
        wdesc       = row[1]                                            # Extract Server Desc.
        wdomain     = row[2]                                            # Extract Server Domain Name
        wos         = row[3]                                            # Extract Server O/S Name
        wostype     = row[4]                                            # Extract Server O/S Type
        wsporadic   = row[5]                                            # Extract Server Sporadic ?
        wmonitor    = row[6]                                            # Extract Server Monitored ?
        wosversion  = row[7]                                            # Extract Server O/S Version
        wfqdn   = "%s.%s" % (wname,wdomain)                             # Construct Fully Qualify DN
        st.writelog("")                                                 # Insert Blank Line
        st.writelog (('-' * 40))                                        # Insert Dash Line
        st.writelog ("Processing (%d) %-15s - %s %s" % (lineno,wfqdn,wos,wosversion)) # Server Info

        # If Debug is activated - Display Monitoring & Sporadic Status of Server.
        if st.debug > 0 :                                               # If Debug Activated
            if wmonitor :                                               # Monitor Collumn is at True
                st.writelog ("Monitoring is ON for %s" % (wfqdn))       # Show That Monitoring is ON
            else :
                st.writelog ("Monitoring is OFF for %s" % (wfqdn))      # Show That Monitoring OFF
            if wsporadic :                                              # If a Sporadic Server
                st.writelog ("Sporadic system is ON for %s" % (wfqdn))  # Show Sporadic is ON
            else :
                st.writelog ("Sporadic system is OFF for %s" % (wfqdn)) # Show Sporadic is OFF

        # Test if Server Name can be resolved - If not Signal Error & continue with next system.
        try:
            hostip = socket.gethostbyname(wfqdn)                        # Resolve Server Name ?
        except socket.gaierror:
            st.writelog ("[ ERROR ] Can't process %s, hostname can't be resolved" % (wfqdn))
            ERROR_COUNT += 1                                            # Increase Error Counter
            if (ERROR_COUNT != 0 ):                                     # If Error count not at zero
                st.writelog ("Total error(s) : %s" % (ERROR_COUNT))     # Show Total Error Count
            continue

        wcommand = "%s %s %s" % (st.ssh_cmd,wfqdn,"date")               # SSH to Server for date
        st.writelog ("Command is %s" % (wcommand))
        ccode, cstdout, cstderr = st.oscommand("%s" % (wcommand))      # Execute O/S CMD 
        st.writelog ("stdout is %s" % (cstdout))
        st.writelog ("stderr is %s" % (cstderr))
        if (ccode == 0):
            st.writelog ("ssh worked")
        else:
            st.writelog ("ssh error")
        lineno += 1                                                     # Increase Server Counter

    return 0


#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():

    if "SADMIN" in os.environ:                                          # Is SADMIN Env. Var. Exist?
        sadm_base_dir = os.environ.get('SADMIN')                        # Set SADMIN Base Directory
    else:
        sadm_base_dir = raw_input("Directory where your install SADMIN ")

    if not os.path.exists(sadm_base_dir) :                              # Check if SADM Dir. Exist
        print ("Directory ". sadm_base_dir . " doesn't exist.")         # Advise User
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