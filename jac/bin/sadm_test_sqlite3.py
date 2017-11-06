#!/usr/bin/env python3
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_sqlite3_test.py
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
import sadmlib_sqlite3 as sadmdb

#pdb.set_trace()                                                       # Activate Python Debugging




#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
pgmver             = "0.1h"                                             # Program Version
debug              = 0                                                  # Default Debug Level (0-9)
exit_code          = 0                                                  # Script Exit Return Code
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
iostatus           = 0                                                  # Status Return code by dbio
#
cnow               = datetime.datetime.now()                            # Get Current Time
curdate            = cnow.strftime("%Y-%m-%d")                          # Format Current date
curtime            = cnow.strftime("%H:%M:%S")                          # Format Current Time




#===================================================================================================
#                                   Script Main Process Function
#===================================================================================================
def main_process(conn,cur):
    dbo = sadmdb.dbtool(dbdebug=3)                                     # Create Instance of DBTool

    # Create if needed the Category Table and load the Initial Data
    print (" ")
    dbo.dbcreate_table('sadm_cat')                                      # Create Cat.Table if needed
    #dbo.db_load_category()                                              # Load Cat.Table Default Col
    cdata = ["Legacy","Legacy Unsupported Server",1,curdate,0]
    dbo.db_insert('sadm_cat',cdata)                                     # Insert Data in Cat. Table
    cdata = ["Dev","Development Environment",1,curdate,1]
    dbo.db_insert('sadm_cat',cdata)                                     # Insert Data in Cat. Table
    cdata = ["Temp","Temporary Environment",1,curdate,0]
    dbo.db_insert('sadm_cat',cdata)                                     # Insert Data in Cat. Table
    cdata = ["Service","Infrastructure Services",1,curdate,0]
    dbo.db_insert('sadm_cat',cdata)                                     # Insert Data in Cat. Table
    cdata = ["Poc","Proof Of Concept env.",1,curdate,0]
    dbo.db_insert('sadm_cat',cdata)                                     # Insert Data in Cat. Table
    cdata = ["Prod","Production Environment",1,curdate,0]
    dbo.db_insert('sadm_cat',cdata)                                     # Insert Data in Cat. Table
    cdata = ["Cluster","Clustered Server",1,curdate,0]
    dbo.db_insert('sadm_cat',cdata)                                     # Insert Data in Cat. Table

    ##### Test Insert 
    print ("\nTesting Datatbase Class for Category Table")
    cdata = ['Test','Test Server',0,'2017-10-30',1]                     # Test Key Data to Add
    dbo.db_insert('sadm_cat',cdata)                                     # Insert Data in Cat. Table
    wdata = dbo.db_readkey('sadm_cat','Test')                           # Read Test Key in Cat.Tab
    print ("Data read is : %s" % (wdata))
    ##### Test Update
    cdata = ['Test','The BatCave Server',1,curdate,0]                   # Data to Update in Cat. Tab
    dbo.db_update('sadm_cat',cdata,'Test')                              # Update Test Key in Cat.Tab
    wdata = dbo.db_readkey('sadm_cat','Test')                           # Read Test Key in Cat.Tab
    print ("Data read is : %s" % (wdata))
    ##### Test Delete
    dbo.db_delete('sadm_cat','Test')                                    # Delete Test Key in Cat.Tab
    wdata = dbo.db_readkey('sadm_cat','Test','y')                       # Read Test Key in Cat.Tab
    if (wdata == 1) :                                                   # If Record wasn't found
        print ("The Category '%s' doesn't exist in table %s" % ("Test",'sadm_cat'))
    else :
        print ("Data read is : %s" % (wdata))                           # Display Row Content


    # Create if needed the Group Table and load the Initial Data
    print (" ")
    dbo.dbcreate_table('sadm_grp')                                      # Create Grp.Table if needed
    cdata = ["Cluster","Clustered Server",1,curdate,0]                  # Server Group to create
    dbo.db_insert('sadm_grp',cdata)                                     # Insert Data in Grp. Table
    cdata = ["Service","Infrastructure Service",1,curdate,0]            # Server Group to create
    dbo.db_insert('sadm_grp',cdata)                                     # Insert Data in Grp. Table
    cdata = ["Retired","Server not in use",1,curdate,0]                 # Server Group to create
    dbo.db_insert('sadm_grp',cdata)                                     # Insert Data in Grp. Table
    cdata = ["Raspberry","Raspberry Pi",1,curdate,0]                    # Server Group to create
    dbo.db_insert('sadm_grp',cdata)                                     # Insert Data in Grp. Table
    cdata = ["Regular","Normal App. Server",1,curdate,0]                # Server Group to create
    dbo.db_insert('sadm_grp',cdata)                                     # Insert Data in Grp. Table
    cdata = ["Temporary","Temporaly in service",1,curdate,0]            # Server Group to create
    dbo.db_insert('sadm_grp',cdata)                                     # Insert Data in Grp. Table
    cdata = ["Laptop","Linux Laptop",1,curdate,0]                       # Server Group to create
    dbo.db_insert('sadm_grp',cdata)                                     # Insert Data in Grp. Table

    ##### Test Insert
    print ("\nTesting Datatbase Class for Group Table")
    cdata = ['Test','Test Group',0,'2017-10-30',1]                      # Test Key Data to Add
    dbo.db_insert('sadm_grp',cdata)                                     # Insert Data in Grp. Table
    wdata = dbo.db_readkey('sadm_grp','Test')                           # Read Test Key in Cat.Tab
    print ("Data read is : %s" % (wdata))
    ##### Test Update
    cdata = ['Test','The Bat Group',1,curdate,0]                        # Data to Update in Grp. Tab
    dbo.db_update('sadm_grp',cdata,'Test')                              # Update Test Key in Grp.Tab
    wdata = dbo.db_readkey('sadm_grp','Test')                           # Read Test Key in Cat.Tab
    print ("Data read is : %s" % (wdata))
    ##### Test delete
    dbo.db_delete('sadm_grp','Test')                                    # Delete Test Key in Grp.Tab
    wdata = dbo.db_readkey('sadm_grp','Test','y')                           # Read Test Key in Cat.Tab
    if (wdata == 1) :                                                   # If Record wasn't found
        print ("The Group '%s' doesn't exist in table %s" % ("Test",'sadm_grp'))
    else :
        print ("Data read is : %s" % (wdata))                           # Display Row Content


    # Create if needed the Server Table and load the Initial Test Server Data
    print (" ")
    dbo.dbcreate_table('sadm_srv')                                     # Create Srv.Table if needed

    cdata1 = ['nomad','maison.ca','Batcave Server','DNS,Web,GoGit,Nagios,Wiki','linux','CENTOS']
    cdata2 = ['Core','7.4.1708',0,1,0,'Service','Regular','MyTag','2017/10/09']
    cdata  = cdata1 + cdata2
    dbo.db_insert('sadm_srv',cdata)                                     # Insert Data in Server Tab
    cdata1 = ['holmes','maison.ca','Main Server','DNS,Web,GoGit,Nagios,Wiki','linux','CENTOS']
    cdata2 = ['Core','7.4.1708',0,1,0,'Service','Regular','MyTag666','2017/10/11']
    cdata  = cdata1 + cdata2
    dbo.db_insert('sadm_srv',cdata)                                     # Insert Data in Server Tab

    # Test Insert
    print ("\nTesting Datatbase Class for Server Table")
    cdata1 = ['Test','maison.ca','Test Server','DNS,Web,GoGit,Nagios,Wiki','linux','CENTOS']
    cdata2 = ['Core','7.4.1708',0,1,0,'Service','Regular','MyTag666','2017/10/11']
    cdata  = cdata1 + cdata2
    dbo.db_insert('sadm_srv',cdata)                                     # Insert Data in Server Tab
    wdata = dbo.db_readkey('sadm_srv','Test')                           # Read Test Key in Cat.Tab
    print ("Data read is : %s" % (wdata))
    
    ##### Test Update
    cdata1 = ['Test','maison.ca','Home Server','Testing Server','linux','CENTOS']
    cdata2 = ['Core','7.4.1709',0,1,0,'Service2','Regular2','MyTag666','2017/11/11']
    cdata  = cdata1 + cdata2
    dbo.db_update('sadm_srv',cdata,'Test')                              # Update Test Key in Grp.Tab
    wdata = dbo.db_readkey('sadm_srv','Test')                           # Read Test Key in Cat.Tab
    print ("Data read is : %s" % (wdata))
    
    ##### Test delete
    dbo.db_delete('sadm_srv','Test')                                    # Delete Test Key in Grp.Tab
    wdata = dbo.db_readkey('sadm_srv','Test','y')                       # Read Test Key in Cat.Tab
    if (wdata == 1) :                                                   # If Record wasn't found
        print ("The Server '%s' doesn't exist in table %s" % ("Test",'sadm_grp'))
    else :
        print ("Data read is : %s" % (wdata))                           # Display Row Content

    # Close Database
    dbo.dbclose()
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
        print ("Please set environment variable SADMIN to where you install it")
        sys.exit(1)                                                     # Exit if not defined 


    sadm_exit_code=main_process(conn,cur)                               # Main Script Processing
    sys.exit(exit_code)                                                 # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
