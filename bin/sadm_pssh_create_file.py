#!/usr/bin/env python 
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_pssh_create_file.py
#   Synopsis:   Create *.txt file use by pssh in $SADMIN_BASE/cfg
#===================================================================================================
# Description
#
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
import os, time, sys, pdb, socket, datetime, glob, fnmatch, psycopg2
#pdb.set_trace()                                                       # Activate Python Debugging



#===================================================================================================
# SADM Library Initialization
#===================================================================================================
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
sadm_lib_dir            = os.path.join(sadm_base_dir,'lib')             # Set SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add Library Dir to PyPath
import sadm_lib_std as sadm                                             # Import SADM Tools Library
sadm.load_config_file()                                                 # Load cfg var from sadmin.cfg


# SADM Variables use on a per script basis
#===================================================================================================
sadm.ver                = "1.5"                                         # Default Program Version
sadm.multiple_exec      = "N"                                           # Default Run multiple copy
sadm.debug              = 0                                             # Default Debug Level (0-9)
sadm.exit_code          = 0                                             # Script Error Return Code
sadm.log_append         = "N"                                           # Append to Existing Log ?
sadm.log_type           = "B"                                           # 4Logger S=Scr L=Log B=Both

# SADM Configuration file (sadmin.cfg) content loaded from configuration file (Can be overridden)
sadm.cfg_mail_type      =  1                                            # 0=No 1=Err 2=Succes 3=All



#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
#
cnow               = datetime.datetime.now()                            # Get Current Time
curdate            = cnow.strftime("%Y.%m.%d")                          # Format Current date
curtime            = cnow.strftime("%H:%M:%S")                          # Format Current Time
#
pssh_aix           = sadm.cfg_dir + '/pssh/pssh_aix.txt'                # File List of aix servers  
pssh_linux         = sadm.cfg_dir + '/pssh/pssh_linux.txt'              # File List of linux servers  
pssh_servers       = sadm.cfg_dir + '/pssh/pssh_servers.txt'            # File List of ALL servers

#===================================================================================================
#                               Process All Active servers 
#===================================================================================================

def process_servers(wconn,wcur):
    "process_servers function "
    sadm.writelog (" ")
    sadm.writelog (" ")
    sadm.writelog (sadm.dash)

    # Select All Active Servers
    try :
        wcur.execute(" \
          SELECT srv_name,srv_ostype,srv_domain,srv_active \
            from sadm.server \
            where srv_active = True order by srv_name; \
        ")
        rows = wcur.fetchall()
        wconn.commit()
    except psycopg2.Error as e:
        sadm.writelog ("Error Reading Server Table")
        sadm.writelog (e.pgerror)
        sadm.writelog (e.diag.message_det)
        return 1                                                        # Return Error To Caller


    # Open Aix Output file
    try:
        FH_AIX_FILE=open(pssh_aix,'w')                                  # Open Aix Server File
    except IOError as e:                                                # If Can't Create or open
        print ("Error open file %s \r\n" % pssh_aix)                    # Print FileName
        print ("Error Number : {0}\r\n.format(e.errno)")                # Print Error Number    
        print ("Error Text   : {0}\r\n.format(e.strerror)")             # Print Error Message
        return 1                                                        # Return Error To Caller
        

    # Open Linux Output file
    try:
        FH_LINUX_FILE=open(pssh_linux,'w')                              # Open Linux Server File
    except IOError as e:                                                # If Can't Create or open
        print ("Error open file %s \r\n" % pssh_linux)                  # Print FileName
        print ("Error Number : {0}\r\n.format(e.errno)")                # Print Error Number    
        print ("Error Text   : {0}\r\n.format(e.strerror)")             # Print Error Message
        return 1                                                        # Return Error To Caller

    # Open All Servers Output file
    try:
        FH_SERVERS_FILE=open(pssh_servers,'w')                          # Open All Servers File
    except IOError as e:                                                # If Can't Create or open
        print ("Error open file %s \r\n" % pssh_servers)                # Print FileName
        print ("Error Number : {0}\r\n.format(e.errno)")                # Print Error Number    
        print ("Error Text   : {0}\r\n.format(e.strerror)")             # Print Error Message
        return 1                                                        # Return Error To Caller
                    
        
    lineno = 1
    for row in rows:
        sadm.writelog ("%02d %s" % (lineno, row))
        (wname,wos,wdomain,wactive) = row
        sadm.writelog (sadm.dash)
        sadm.writelog ("Processing (%d) %-30s - type:%s" % (lineno,wname+"."+wdomain,wos))
        lineno += 1    
        if (wos == "aix")   : 
            FH_AIX_FILE.write  ("%s:%d root\n" % (wname+"."+wdomain,sadm.cfg_ssh_port)) 
        if (wos == "linux") : 
            FH_LINUX_FILE.write("%s:%d root\n" % (wname+"."+wdomain,sadm.cfg_ssh_port))  
        FH_SERVERS_FILE.write("%s:%d root\n" % (wname+"."+wdomain,sadm.cfg_ssh_port))  

    FH_AIX_FILE.close()  
    FH_LINUX_FILE.close()  
    FH_SERVERS_FILE.close()  
    return 0
   


#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    sadm.start()                                                        # Open Log, Create Dir ...

#    # Test if script is run by root (Optional Code)
#    if os.geteuid() != 0:                                               # UID of user is not zero
#       sadm.writelog ("This script must be run by the 'root' user")     # Advise User Message / Log
#       sadm.writelog ("Process aborted")                                # Process Aborted Msg 
#       sadm.stop (1)                                                    # Close and Trim Log/Email
#       sys.exit(1)                                                      # Exit with Error Code
        
    # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    if socket.getfqdn() != sadm.cfg_server :                            # Only run on SADMIN
       sadm.writelog ("This script can be run only on the SADMIN server (%s)",(sadm.cfg_server))
       sadm.writelog ("Process aborted")                                # Abort advise message
       sadm.stop (1)                                                    # Close and Trim Log
       sys.exit(1)                                                      # Exit To O/S


    if sadm.debug > 4 : sadm.display_env()                              # Display Env. Variables
    (conn,cur) = sadm.open_sadmin_database()                            # Open Connection 2 Database
    sadm.exit_code=process_servers(conn,cur)                            # Main Script Processing
    sadm.close_sadmin_database(conn,cur)                                # Close Database Connection
    sadm.stop(sadm.exit_code)                                           # Close log & trim
    sys.exit(sadm.exit_code)                                            # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()