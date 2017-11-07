#! /usr/bin/env python3
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_test_mysql.py
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
import os, time, sys, pdb, socket, datetime, glob, fnmatch
#
sys.path.append(os.path.join(os.environ.get('SADMIN'),'lib'))
import sadmlib_mysql as sadmdb

#pdb.set_trace()                                                       # Activate Python Debugging




#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
pgmver             = "1.0"                                              # Program Version
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
#                                   Test Category Table
#===================================================================================================
def test_category(conn,cur):

    dbo = sadmdb.dbtool(dbname='sadmin', dbdebug=3, dbsilent=False)      # Create Instance of DBTool

    # INSERT TEST CATEGORY IN TABLE
    print ("\nINSERTING CATEGORY 'TEST'")
    cdata = ['Test','Test Server',0,'2017-09-01',1]                     # Test Key Data to Add
    dbo.db_insert('server_category',cdata)                              # Insert Data in Cat. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))


    # READ BACK INSERTED ROW
    print ("\nREADING BACK CATEGORY 'TEST'")
    results = dbo.db_readkey('server_category','Test')                           # Read Test Key in Cat.Tab
    if (dbo.enum == 0) :
        print ("After read is : %s" % (repr(results)))
    else:
        print ("After read ERROR %d - %s" % (dbo.enum,dbo.emsg))

    # UPDATE THE INSERTED ROW
    print ("\nUPDATE THE ROW 'TEST'")
    cdata = ['Test','The BatCave Server',1,curdate,0]                   # Data to Update in Cat. Tab
    dbo.db_update('server_category',cdata,'Test')                              # Update Test Key in Cat.Tab
    if (dbo.enum == 0) :
        print ("After Update is : %s" % (cdata))
    else:
        print ("After Update ERROR %d - %s" % (dbo.enum,dbo.emsg))


    # READ BACK INSERTED ROW
    print ("\nREADING BACK CATEGORY 'TEST'")
    results = dbo.db_readkey('server_category','Test')                           # Read Test Key in Cat.Tab
    if (dbo.enum == 0) :
        print ("After read is : %s" % (repr(results)))
    else:
        print ("After read ERROR %d - %s" % (dbo.enum,dbo.emsg))


    # DELETE ROW JUST INSERTED
    print ("\nDELETE CATEGORY 'TEST'")
    dbo.db_delete('server_category' ,'Test')                                    # Delete Test Key in Grp.Tab
    if (dbo.enum == 0) :
        print ("After Delete went OK - Error is 0")
    else:
        print ("After Delete read ERROR %d - %s" % (dbo.enum,dbo.emsg))


    # READ BACK DELETED ROW
    print ("\nREADING BACK DELETED CATEGORY 'TEST'")
    results = dbo.db_readkey('server_category','Test')                           # Read Test Key in Cat.Tab
    if (dbo.enum == 0) :
        print ("After read is : %s" % (repr(results)))
    else:
        print ("After read ERROR %d - %s" % (dbo.enum,dbo.emsg))


    dbo.dbclose()                                                       # Close the Database
    if (dbo.enum !=0) :                                                 # If Error Closing Database
        print ("Error %d Closing DataBase - %s" % (dbo.enum,dbo.emsg))  # Inform User Err# & ErrMsg
    return                                                              # Return to Caller


#===================================================================================================
#                                   Test Group Table
#===================================================================================================
def test_group(conn,cur):

    dbo = sadmdb.dbtool(dbname='sadmin', dbdebug=3, dbsilent=False)     # Create Instance of DBTool

    # INSERT TEST GROUP IN TABLE
    print ("\nINSERTING GROUP 'TEST'")
    cdata = ['Test','Test Server',0,'2017-09-01',1]                     # Test Key Data to Add
    dbo.db_insert('server_group',cdata)                                 # Insert Data in Grp. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))


    # READ BACK INSERTED ROW
    print ("\nREADING BACK GROUP 'TEST'")
    results = dbo.db_readkey('server_group','Test')                     # Read Test Key in Grp.Tab
    if (dbo.enum == 0) :
        print ("After read is : %s" % (repr(results)))
    else:
        print ("After read ERROR %d - %s" % (dbo.enum,dbo.emsg))

    # UPDATE THE INSERTED ROW
    print ("\nUPDATE THE ROW 'TEST'")
    cdata = ['Test','The BatCave Server',1,curdate,0]                   # Data to Update in Cat. Tab
    dbo.db_update('server_group',cdata,'Test')                              # Update Test Key in Cat.Tab
    if (dbo.enum == 0) :
        print ("After Update is : %s" % (cdata))
    else:
        print ("After Update ERROR %d - %s" % (dbo.enum,dbo.emsg))


    # READ BACK INSERTED ROW
    print ("\nREADING BACK GROUP 'TEST'")
    results = dbo.db_readkey('server_group','Test')                           # Read Test Key in Cat.Tab
    if (dbo.enum == 0) :
        print ("After read is : %s" % (repr(results)))
    else:
        print ("After read ERROR %d - %s" % (dbo.enum,dbo.emsg))


    # DELETE ROW JUST INSERTED
    print ("\nDELETE GROUP 'TEST'")
    dbo.db_delete('server_group' ,'Test')                                    # Delete Test Key in Grp.Tab
    if (dbo.enum == 0) :
        print ("After Delete went OK - Error is 0")
    else:
        print ("After Delete read ERROR %d - %s" % (dbo.enum,dbo.emsg))


    # READ BACK DELETED ROW
    print ("\nREADING BACK DELETED GROUP 'TEST'")
    results = dbo.db_readkey('server_group','Test')                           # Read Test Key in Cat.Tab
    if (dbo.enum == 0) :
        print ("After read is : %s" % (repr(results)))
    else:
        print ("After read ERROR %d - %s" % (dbo.enum,dbo.emsg))


    dbo.dbclose()                                                       # Close the Database
    if (dbo.enum !=0) :                                                 # If Error Closing Database
        print ("Error %d Closing DataBase - %s" % (dbo.enum,dbo.emsg))  # Inform User Err# & ErrMsg
    return                                                              # Return to Caller


#===================================================================================================
#                                   Test Server Table
#===================================================================================================
def test_server(conn,cur):

    dbo = sadmdb.dbtool(dbname='sadmin', dbdebug=3, dbsilent=False)     # Create Instance of DBTool

    # Test Insert
    print ("\nTesting Datatbase Class for Server Table")
    cdata1 = ['Test','maison.ca','Test Server','DNS,Web,GoGit,Nagios,Wiki',1,'2017/10/11',0,]
    cdata2 = [1,'MyTag','Service','Regular',1,1]
    cdata  = cdata1 + cdata2
    dbo.db_insert('server' ,cdata)                                      # Insert Data in Server Tab
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))
    

    # READ BACK INSERTED ROW
    print ("\nREADING BACK SERVER 'TEST'")
    results = dbo.db_readkey('server','Test')                           # Read Test Key in Srv.Tab
    if (dbo.enum == 0) :
        print ("After read is : %s" % (repr(results)))
    else:
        print ("After read ERROR %d - %s" % (dbo.enum,dbo.emsg))

    # UPDATE THE INSERTED ROW
    print ("\nUPDATE THE ROW 'TEST'")
    cdata1 = ['Test','maison.ca','Batcave Server','Bat Service',1,'2017/10/11',0,]
    cdata2 = [1,'BatTag','BatService','BatRegular',1,1]
    cdata  = cdata1 + cdata2
    dbo.db_update('server',cdata,'Test')                                # Update Test Key in Srv.Tab
    if (dbo.enum == 0) :
        print ("After Update is : %s" % (cdata))
    else:
        print ("After Update ERROR %d - %s" % (dbo.enum,dbo.emsg))


    # READ BACK INSERTED ROW
    print ("\nREADING BACK SERVER 'TEST'")
    results = dbo.db_readkey('server','Test')                           # Read Test Key in Srv.Tab
    if (dbo.enum == 0) :
        print ("After read is : %s" % (repr(results)))
    else:
        print ("After read ERROR %d - %s" % (dbo.enum,dbo.emsg))


    # DELETE ROW JUST INSERTED
    print ("\nDELETE SERVER 'TEST'")
    dbo.db_delete('server' ,'Test')                                     # Delete Test Key in Srv.Tab
    if (dbo.enum == 0) :
        print ("After Delete went OK - Error is 0")
    else:
        print ("After Delete read ERROR %d - %s" % (dbo.enum,dbo.emsg))


    # READ BACK DELETED ROW
    print ("\nREADING BACK DELETED SERVER 'TEST'")
    results = dbo.db_readkey('server','Test')                           # Read Test Key in Srv.Tab
    if (dbo.enum == 0) :
        print ("After read is : %s" % (repr(results)))
    else:
        print ("After read ERROR %d - %s" % (dbo.enum,dbo.emsg))

    dbo.dbclose()                                                       # Close the Database
    if (dbo.enum !=0) :                                                 # If Error Closing Database
        print ("Error %d Closing DataBase - %s" % (dbo.enum,dbo.emsg))  # Inform User Err# & ErrMsg
    return     


#===================================================================================================
#                                   Initial Server Load
#===================================================================================================
def load_tables(conn,cur):

    dbo = sadmdb.dbtool(dbname='sadmin', dbdebug=3, dbsilent=False)     # Create Instance of DBTool

    cdata = ["Legacy","Legacy Unsupported Server",1,curdate,0]
    dbo.db_insert('server_category',cdata)                                     # Insert Data in Cat. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata = ["Dev","Development Environment",1,curdate,1]
    dbo.db_insert('server_category',cdata)                                     # Insert Data in Cat. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata = ["Service","Infrastructure Services",1,curdate,0]
    dbo.db_insert('server_category',cdata)                                     # Insert Data in Cat. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata = ["Poc","Proof Of Concept env.",1,curdate,0]
    dbo.db_insert('server_category',cdata)                                     # Insert Data in Cat. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata = ["Prod","Production Environment",1,curdate,0]
    dbo.db_insert('server_category',cdata)                                     # Insert Data in Cat. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata = ["Cluster","Clustered Server",1,curdate,0]
    dbo.db_insert('server_category',cdata)                                     # Insert Data in Cat. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    # Create if needed the Group Table and load the Initial Data
    print (" ")
    #dbo.dbcreate_table('server_group')                                      # Create Grp.Table if needed
    cdata = ["Cluster","Clustered Server",1,curdate,0]                  # Server Group to create
    dbo.db_insert('server_group',cdata)                                     # Insert Data in Grp. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata = ["Service","Infrastructure Service",1,curdate,0]            # Server Group to create
    dbo.db_insert('server_group',cdata)                                     # Insert Data in Grp. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata = ["Retired","Server not in use",1,curdate,0]                 # Server Group to create
    dbo.db_insert('server_group',cdata)                                     # Insert Data in Grp. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata = ["Raspberry","Raspberry Pi",1,curdate,0]                    # Server Group to create
    dbo.db_insert('server_group',cdata)                                     # Insert Data in Grp. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))


    cdata = ["Regular","Normal App. Server",1,curdate,0]                # Server Group to create
    dbo.db_insert('server_group',cdata)                                     # Insert Data in Grp. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata = ["Temporary","Temporaly in service",1,curdate,0]            # Server Group to create
    dbo.db_insert('server_group',cdata)                                     # Insert Data in Grp. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata = ["Laptop","Linux Laptop",1,curdate,0]                       # Server Group to create
    dbo.db_insert('server_group',cdata)                                     # Insert Data in Grp. Table
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))


    cdata1 = ['Test1','maison.ca','Test Server 1','DNS,Web,GoGit,Nagios,Wiki',1,'2017/10/11',0,]
    cdata2 = [1,'MyTag','Service','Regular',1,1]
    cdata  = cdata1 + cdata2
    dbo.db_insert('server' ,cdata)                                     # Insert Data in Server Tab
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))

    cdata1 = ['Test2','maison.ca','Test Server 2','DNS,Web,GoGit,Nagios,Wiki',1,'2017/10/11',0,]
    cdata2 = [1,'MyTag','Service','Regular',1,1]
    cdata  = cdata1 + cdata2
    dbo.db_insert('server' ,cdata)                                     # Insert Data in Server Tab
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))


    # Test Insert
    print ("\nTesting Datatbase Class for Server Table")
    cdata1 = ['Test3','maison.ca','Test Server 3','DNS,Web,GoGit,Nagios,Wiki',1,'2017/10/11',0,]
    cdata2 = [1,'MyTag','Service','Regular',1,1]
    cdata  = cdata1 + cdata2
    dbo.db_insert('server' ,cdata)                                     # Insert Data in Server Tab
    if (dbo.enum ==0) :
        print ("After Insert Insert OK")
    else:
        print ("After Insert Error number %d - %s" % (dbo.enum,dbo.emsg))
    
    dbo.dbclose()                                                       # Close the Database
    if (dbo.enum !=0) :                                                 # If Error Closing Database
        print ("Error %d Closing DataBase - %s" % (dbo.enum,dbo.emsg))  # Inform User Err# & ErrMsg
    return     


#===================================================================================================
#                                   Script Main Process Function
#===================================================================================================
def main_process(conn,cur):
    print ("=" * 80)
    dummy = input("Press [ENTER] to begin testing table 'server_category' I/O")
    test_category(conn,cur)

    print ("=" * 80)
    dummy = input("Press [ENTER] to begin testing table 'server_group' I/O")
    test_group(conn,cur)

    print ("=" * 80)
    dummy = input("Press [ENTER] to begin testing table 'server' I/O")
    test_server(conn,cur)

    print ("=" * 80)
    dummy = input("Press [ENTER] to load initial data in tables")
    load_tables(conn,cur)

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
