#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_template_servers.py
#   Synopsis:
#===================================================================================================
# Description
#
#
#   Copyright (C) 2016-2017 Jacques Duplessis <duplessis.jacques@gmail.com>
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
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# V1.1 July 2017 - Adjust Verification of root user and allow to only run on sadmin server
# 2017_09_03 JDuplessis - V1.2 Minors changes
#
#===================================================================================================
import os, time, sys, pdb, socket, datetime, glob, fnmatch, psycopg2
#pdb.set_trace()                                                       # Activate Python Debugging



#===================================================================================================
# SADM Library Initialization (Needed to use the SADM Library)
#===================================================================================================
# If SADMIN environment variable is defined, use it as the SADM Base Directory else use /sadmin.
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
sadm_lib_dir            = os.path.join(sadm_base_dir,'lib')             # Set SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add Library Dir to PyPath
import sadm_lib_std as sadm                                             # Import SADM Tools Library
sadm.load_config_file()                                                 # Load cfg var from sadmin.cfg


# SADM Variables use on a per script basis
#===================================================================================================
sadm.ver                = "1.1"                                         # Default Program Version
sadm.multiple_exec      = "N"                                           # Default Run multiple copy
sadm.debug              = 0                                             # Default Debug Level (0-9)
sadm.exit_code          = 0                                             # Script Error Return Code
sadm.log_append         = "N"                                           # Append to Existing Log ?
sadm.log_type           = "B"                                           # 4Logger S=Scr L=Log B=Both

# SADM Configuration file (sadmin.cfg) content loaded from configuration file (Can be overridden)
sadm.cfg_mail_type      = 1                                             # 0=No 1=Err 2=Succes 3=All
#cfg_mail_addr      = ""                                                 # Default is in sadmin.cfg



#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
#
cnow               = datetime.datetime.now()                            # Get Current Time
curdate            = cnow.strftime("%Y.%m.%d")                          # Format Current date
curtime            = cnow.strftime("%H:%M:%S")                          # Format Current Time


#===================================================================================================
#                               Process Linux servers selected by the SQL
#===================================================================================================

def process_linux_servers(wconn,wcur):
    sadm.writelog (" ")
    sadm.writelog (" ")
    sadm.writelog (sadm.dash)
    sadm.writelog ("PROCESSING LINUX SERVERS")

    # Select All Active Linux Servers
    try :
        wcur.execute(" \
          SELECT srv_name,srv_ostype,srv_domain,srv_active \
            from sadm.server \
            where srv_active = True and srv_ostype = 'linux' order by srv_name; \
        ")
        rows = wcur.fetchall()
        wconn.commit()
    except psycopg2.Error as e:
        sadm.writelog ("Error Reading Server Table")
        sadm.writelog (e.pgerror)
        sadm.writelog (e.diag.message_det)
        sys.exit(1)

    lineno = 1
    for row in rows:
        #sadm.writelog ("%02d %s" % (lineno, row))
        wname,wos,wdomain,wtype,wactive = row
        sadm.writelog (sadm.dash)
        sadm.writelog ("Processing (%d) %-30s - os:%s - type:%s" % (lineno,wname+"."+wdomain,wos,wtype))
        lineno += 1

    return 0


#===================================================================================================
#                               Process Aix servers selected by the SQL
#===================================================================================================

def process_aix_servers(wconn,wcur):
    sadm.writelog (" ")
    sadm.writelog (" ")
    sadm.writelog (sadm.dash)
    sadm.writelog ("PROCESSING LINUX SERVERS")

    # Select All Active Linux Servers
    try :
        wcur.execute(" \
          SELECT srv_name,srv_ostype,srv_domain, srv_active \
            from sadm.server \
            where srv_active = True and srv_ostype = 'aix' order by srv_name; \
        ")
        rows = wcur.fetchall()
        wconn.commit()
    except psycopg2.Error as e:
        sadm.writelog ("Error Reading Server Table")
        sadm.writelog (e.pgerror)
        sadm.writelog (e.diag.message_det)
        sys.exit(1)

    lineno = 1
    for row in rows:
        #sadm.writelog ("%02d %s" % (lineno, row))
        wname,wos,wdomain,wtype,wactive = row
        sadm.writelog (sadm.dash)
        sadm.writelog ("Processing (%d) %-30s - os:%s - type:%s" % (lineno,wname+"."+wdomain,wos,wtype))
        lineno += 1

    return 0


#===================================================================================================
#                                   Script Main Process Function
#===================================================================================================
def main_process(wconn,wcur):

    # Process Linux Servers
    linux_errors=process_linux_servers(wconn,wcur)                      # Process Linux Servers

    # Process Aix Servers
    aix_errors=process_aix_servers(wconn,wcur)                          # Process Aix Servers

    # Display the number of error
    sadm.writelog (sadm.dash)
    sadm.writelog ("Total number of Linux error : %d" % linux_errors)   # Display Nb Linux Error
    sadm.writelog ("Total number of Aix error : %d" % aix_errors)       # Display Nb Aix  Error

    return (aix_errors + linux_errors)                                  # Return Code =Aix+Linux Err




#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    sadm.start()                                                        # Open Log, Create Dir ...

    # Insure that this script only run on the sadmin server (Optional code)
    if socket.getfqdn() != sadm.cfg_server :                            # Only run on SADMIN
       sadm.writelog ("This script can be run only on the SADMIN server (%s)",(sadm.cfg_server))
       sadm.writelog ("Process aborted")                                # Abort advise message
       sadm.stop (1)                                                    # Close and Trim Log
       sys.exit(1)                                                      # Exit To O/S

    # Insure that this script can only be run by the user root (Optional Code)
    if os.geteuid() != 0:                                               # UID of user is not zero
       sadm.writelog ("This script must be run by the 'root' user")     # Advise User Message / Log
       sadm.writelog ("Process aborted")                                # Process Aborted Msg
       sadm.stop (1)                                                    # Close and Trim Log/Email
       sys.exit(1)                                                      # Exit with Error Code

    if sadm.debug > 4 : sadm.display_env()                              # Display Env. Variables
    (conn,cur) = sadm.open_sadmin_database()                            # Open Connection 2 Database
    sadm.exit_code=main_process(conn,cur)                               # Main Script Processing

    sadm.close_sadmin_database(conn,cur)                                # Close Database Connection
    sadm.stop(sadm.exit_code)                                           # Close log & trim
    sys.exit(sadm.exit_code)                                            # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()