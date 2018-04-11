#!/usr/bin/env python3
# ==================================================================================================
#   Author      :   Jacques Duplessis
#   Date        :   2017-09-09
#   Name        :   sadm_template_servers.py
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
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2018_12_01 JDuplessis 
#   V1.0 Initial Version
#
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

        if (wfqdn != st.cfg_server):
            wcommand = "%s %s %s" % (st.ssh_cmd,wfqdn,"date")               # SSH to Server for date
            st.writelog ("Command is %s" % (wcommand))
            ccode, cstdout, cstderr = st.oscommand("%s" % (wcommand))      # Execute O/S CMD 
            st.writelog ("stdout is %s" % (cstdout))
            st.writelog ("stderr is %s" % (cstderr))
            if (ccode == 0):
                st.writelog ("ssh worked")
            else:
                st.writelog ("ssh error")
        else:
            st.writelog ("No need for SSH on SADMIN server %s" % (st.cfg_server))

        
        lineno += 1                                                     # Increase Server Counter

    return 0


#===================================================================================================
#                                   Script Main Process Function
#===================================================================================================
def main_process(st):
    st.writelog ("Starting Main Process")
    return (0)                                                       # Return Error Code To Caller



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():

    # SADMIN TOOLS - Create SADMIN instance & setup variables specific to your program -------------
    st = sadm.sadmtools()                       # Create SADMIN Tools Instance (Setup Dir.)
    st.ver  = "1.6"                             # Indicate this script Version 
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
        
    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database
        st.exit_code = process_servers(conn,cur,st)                     # Go Process Actives Servers 
        st.dbclose()                                                    # Close the Database
    else:                                                               # Script don't need Database
        st.exit_code = main_process(st)                                 # Process Not Using Database
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()