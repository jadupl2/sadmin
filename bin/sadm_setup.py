#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_setup.py
#   Synopsis:   Setup SADM Environment so it is ready for use.
#===================================================================================================
# Description
# This seup program can be run multiple time and at any time, it will not delete anything that
# has been previously setup.
# Unless you deleted some directory or delete the database, it will be then recreated)
#
#   Step that the setup program will execute in that order
#       1) Database will be created, if it does not exist
#       2) Database tables will be created and populated if they do not exist
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
# 2017_09_10 JDuplessis - V0.1 Beta Initial version
#
#
#===================================================================================================
import os, time, sys, pdb, socket, datetime, glob, fnmatch, sqlite3
# #pdb.set_trace()                                                       # Activate Python Debugging



#===================================================================================================
# SADM Library Initialization (Needed to use the SADM Library)
#===================================================================================================
# If SADMIN environment variable is defined, use it as the SADM Base Directory else use /sadmin.
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
sadm_lib_dir            = os.path.join(sadm_base_dir,'lib')             # Set SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add Library Dir to PyPath
import sadmdb




#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
#
cnow               = datetime.datetime.now()                            # Get Current Time
curdate            = cnow.strftime("%Y.%m.%d")                          # Format Current date
curtime            = cnow.strftime("%H:%M:%S")                          # Format Current Time
pgmver             = "0.1f"                                             # Default Program Version
debug              = 0                                                  # Default Debug Level (0-9)
exit_code          = 0                                                  # Script Error Return Code




#===================================================================================================
#                                   Script Main Process Function
#===================================================================================================
def main_process(conn,cur):
    dbo = sadmdb.db_tool()

    dbo.db_create_table('sadm_cat')
    dbo.db_load_category()
    cdata = ['Test','Test Server',1,0]
    dbo.db_insert('sadm_cat',cdata)
    cdata = ['Test','The BatCave Server',1,0]
    dbo.db_update('sadm_cat',cdata,'Test')

    dbo.db_create_table('sadm_grp')
    dbo.db_load_group()
    cdata = ['Test','Test Group',1,0]
    dbo.db_insert('sadm_grp',cdata)
    cdata = ['Test','The Bat Group',1,0]
    dbo.db_update('sadm_grp',cdata,'Test')
    dbo.db_delete('sadm_grp','Test')

    row=dbo.db_readkey('sadm_grp','Laptop')
    print type(row)
    print(row)

    dbo.db_close_db()
    return

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    
    # Check if SADMIN Environmebnt variable is defined (MUST be defined so that everything work)
    try:  
        os.environ["SADMIN"]                                            # Is Env. SADMIN Defined
    except KeyError: 
        print "Please set environment variable SADMIN to where you install it"
        sys.exit(1)                                                     # Exit if not defined 


    sadm_exit_code=main_process(conn,cur)                               # Main Script Processing
    sys.exit(exit_code)                                                 # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()