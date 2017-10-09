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
sys.path.append(os.path.join(os.environ.get('SADMIN'),'lib'))
import sadm_lib_sqlite3 as sadmdb

#pdb.set_trace()                                                       # Activate Python Debugging




#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
pgmver             = "0.1g"                                             # Program Version
debug              = 0                                                  # Default Debug Level (0-9)
exit_code          = 0                                                  # Script Exit Return Code
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
#
cnow               = datetime.datetime.now()                            # Get Current Time
curdate            = cnow.strftime("%Y.%m.%d")                          # Format Current date
curtime            = cnow.strftime("%H:%M:%S")                          # Format Current Time




#===================================================================================================
#                                   Script Main Process Function
#===================================================================================================
def main_process(conn,cur):
    dbo = sadmdb.db_tool()                                              # Create Instance of DBTool

    # Create if needed the Category Table and load the Initial Data
    print (" ")
    dbo.db_create_table('sadm_cat')                                     # Create Cat.Table if needed
    dbo.db_load_category()                                              # Load Cat.Table Default Col
    cdata = ['Test','Test Server',1,0]                                  # Test Key Data to Add
    dbo.db_insert('sadm_cat',cdata)                                     # Insert Data in Cat. Table
    cdata = ['Test','The BatCave Server',1,0]                           # Data to Update in Cat. Tab
    dbo.db_update('sadm_cat',cdata,'Test')                              # Update Test Key in Cat.Tab
    dbo.db_delete('sadm_cat','Test')                                    # Delete Test Key in Cat.Tab


    # Create if needed the Group Table and load the Initial Data
    print (" ")
    dbo.db_create_table('sadm_grp')                                     # Create Grp.Table if needed
    dbo.db_load_group()                                                 # Load Grp.Table Default Col
    cdata = ['Test','Test Group',1,0]                                   # Test Key Data to Add
    dbo.db_insert('sadm_grp',cdata)                                     # Insert Data in Grp. Table
    row=dbo.db_readkey('sadm_grp','Test')                               # Read Test Group Collumn
    print type(row)
    print(row)
    cdata = ['Test','The Bat Group',1,0]                                # Data to Update in Grp. Tab
    dbo.db_update('sadm_grp',cdata,'Test')                              # Update Test Key in Grp.Tab
    dbo.db_delete('sadm_grp','Test')                                    # Delete Test Key in Grp.Tab


    # Create if needed the Server Table and load the Initial Test Server Data
    print (" ")
    dbo.db_create_table('sadm_srv')                                     # Create Srv.Table if needed
    cdata = ['holmes','maison.ca','Batcave Server','DNS,Web,GoGit,Nagios,Wiki',1,0,'Service','Regular','2017/10/09']                                   # Test Key Data to Add
    dbo.db_insert('sadm_srv',cdata)                                     # Insert Data in Srv. Table


 
    dbo.db_close_db()
    return

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    
    # Check if SADMIN Environment variable is defined (MUST be defined so that everything work)
    if "SADMIN" in os.environ:   
        sadm_base_dir = os.environ.get('SADMIN')                        # Set SADMIN Base Directory
    else:
        print "Please set environment variable SADMIN to where you install it"
        sys.exit(1)                                                     # Exit if not defined 


    sadm_exit_code=main_process(conn,cur)                               # Main Script Processing
    sys.exit(exit_code)                                                 # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()