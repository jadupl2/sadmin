#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadmdb.py
#   Synopsis:   SADM Module that deal with SADM Database
# ==================================================================================================
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
# 2017_09_15 Jacques Duplessis - V0.0a Initial Version
#
#
#===================================================================================================
#import os, time, sys, pdb, socket, datetime, glob, fnmatch, sqlite3, sadmdb
import os, sys, sqlite3
#pdb.set_trace()                                                       # Activate Python Debugging

#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
conn               = ""                                                 # Database Connector
cur                = ""                                                 # Database Cursor
libver             = "0.0a"                                             # Default Program Version
debug              = 0                                                  # Default Debug Level (0-9)
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
exit_code          = 0                                                  # Library Return Code

#===================================================================================================
#                                   SADM Database Access Class 
#===================================================================================================
class db_tool:

    # DATABASE CONNECTION & INITIALISATION ---------------------------------------------------------
    def __init__(self, dbname=os.path.join(sadm_base_dir) + "/www/db/sadm.db"):
        """ Class db_tool: Series of function to Insert,Read,Update and delete row(s) in
            the selected Sqlite3 Database.
            def __init__(self, dbname) 
                Database Name can by passed to sadm_dbtool or $SADMIN/www/db/sadm.db is used.
        """
        self.dbname = dbname
        print "Connecting to Database %s" % (self.dbname)
        try : 
            self.conn = sqlite3.connect(self.dbname)
            self.cur = self.conn.cursor()
            print "Connected to Database %s" % (self.dbname)
        except Exception as e: 
            print("An error occurred:", e,  '-',  e.args[0])
            sys.exit(exit_code)                                    # Exit with Error Code
        #return (self.conn,self.cur)
        return


    # CLOSE THE DATABASE ---------------------------------------------------------------------------
    def db_close_db(self):
        try:
            print("Closing Database %s" % (self.dbname)) 
            self.conn.close()
        except Exception as e: 
            print("An error occurred:", e,  '-',  e.args[0])
            return 1       


    # CREATE SADM TABLE FUNCTION -------------------------------------------------------------------
    def db_create_table(self,tbname):
        print("Creating %s table." % (tbname)) 
        try:
            if (tbname == "sadm_cat"):
                self.cur.execute('''DROP TABLE sadm_cat''')
                self.cur.execute('''CREATE TABLE IF NOT EXISTS sadm_cat (
                    cat_code    TEXT    PRIMARY KEY ,
                    cat_desc    TEXT    NOT NULL CHECK( cat_desc != ''),
                    cat_active  INTEGER DEFAULT 1,
                    cat_default INTEGER DEFAULT 0 NOT NULL)
                    ''')
            if (tbname == "sadm_grp"):
                self.cur.execute('''DROP TABLE sadm_grp''')
                self.cur.execute('''CREATE TABLE IF NOT EXISTS sadm_grp (
                    grp_code    TEXT    PRIMARY KEY ,
                    grp_desc    TEXT    NOT NULL CHECK( grp_desc != ''),
                    grp_active  INTEGER DEFAULT 1,
                    grp_default INTEGER DEFAULT 0 NOT NULL)
                    ''')
            self.conn.commit()   
        except Exception as e: 
            print("An error occurred:", e)
            return 1  


    # INSERT ROW IN SELECTED TABLE -----------------------------------------------------------------
    def db_insert(self,tbname,fields):
        sadm_cat_nb_field = 4                                           # Nb of fields in Cat Table
        sadm_grp_nb_field = 4                                           # Nb of fields in Grp Table
        tablist = ["sadm_cat","sadm_grp"]                               # SADM Table List

        # Is the table name part of the Database, if not Error
        if tbname not in tablist:
            print ("The table %s isn't part of the Database",(tbname))
            return 1

        # Validate the number of fields for the tablename 
        condition = ( (tbname == "sadm_cat" and len(fields) <> sadm_cat_nb_field)  or 
                      (tbname == "sadm_grp" and len(fields) <> sadm_grp_nb_field) )
        if condition:
            print ("Number of field for %s table should be 4, received %d",(tbname,len(fields)))
            return 1

        # In Debug mode print tableName and list of fields received
        if debug > 4:
            print("Inserting Data in %s table." % (tbname)) 
            print("Fields to insert are %s" % (fields)) 
            for x in range(len(fields)):
                print ("[%s] %s" % (x,fields[x]))
        try: 
            if (tbname == "sadm_cat"):
                sql = ''' INSERT INTO sadm_cat VALUES(?,?,?,?)  '''
                self.cur.execute(sql,(fields[0],fields[1],fields[2],fields[3]))
            if (tbname == "sadm_grp"):
                sql = ''' INSERT INTO sadm_grp VALUES(?,?,?,?)  '''
                self.cur.execute(sql,(fields[0],fields[1],fields[2],fields[3]))
            self.conn.commit()   
        except sqlite3.IntegrityError as e: 
            print("Primary Key '%s' already exist in %s table\nError occurred:%s" % (fields[0],tbname,e))
            self.conn.rollback()            
        except Exception as e: 
            print("Table %s Insert Key %s Error occurred:" % (tbname,fields[0],e))
            self.conn.rollback()
        return


    # INITIAL LOAD OF THE CATEGORY TABLE -----------------------------------------------------------
    def db_load_category(self):
        print ("Loading category table")
        categories = [
            ('Legacy','Legacy Unsupported Server',1,0),
            ("Dev","Development Environment",1,1),
            ("Temp","Temporary Environment",1,0),
            ("Service","Infrastructure Services",1,0),
            ("Poc","Proof Of Concept env.",1,0),
            ("Prod","Production Environment",1,0),
            ("Cluster","Clustered Server",1,0),
            ]
        try:
            self.cur.executemany('INSERT INTO sadm_cat VALUES (?,?,?,?)', categories)     
            self.conn.commit()  
        except sqlite3.IntegrityError as e: 
            print("Error trying to write duplicate key in Category table\nError occurred:%s" % (e))
            self.conn.rollback()   
        except Exception as e:
            print("An error occurred:", e)
            self.conn.rollback()


    # INITIAL LOAD OF THE GROUP TABLE --------------------------------------------------------------
    def db_load_group(self):
        print ("Loading group table")
        groups = [
            ("Group2","Group No.2",1,0),
            ("Group3","Group No.3",1,0),
            ("Group4","Group No.4",1,0),
            ("Group5","Group No.5",1,0),
            ("Service","Infrastructure Services",1,0),
            ("Group1","Group No.1",1,0),
            ("Retired","Retired Servers",1,0),
            ("Raspberry","Raspberry Pi Server",1,0),
            ("Regular","Regular Server",1,0),
            ("Standard","Standard Install Server",1,1),
            ("Laptop","Linux Laptop",1,0),
            ]
        try:
            self.cur.executemany('INSERT INTO sadm_grp VALUES (?,?,?,?)', groups)     
            self.conn.commit()  
        except Exception as e:
            print("An error occurred:", e)
            self.conn.rollback()

