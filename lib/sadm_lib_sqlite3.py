#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_lib_sqlite.py
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
libver             = "0.0c"                                             # Default Program Version
debug              = 4                                                  # Default Debug Level (0-9)
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
#

sadm_cat_nb_field  = 4                                                  # Nb of fields in Cat Table
sadm_grp_nb_field  = 4                                                  # Nb of fields in Grp Table
sadm_srv_nb_field  = 9                                                  # Nb of fields in Srv Table
tablist = ["sadm_cat","sadm_grp","sadm_srv"]                            # SADM Table List


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
        print ("Connecting to Database %s" % (self.dbname))
        try : 
            self.conn = sqlite3.connect(self.dbname, timeout=10)
            self.cur = self.conn.cursor()
            print ("Connected to Database %s" % (self.dbname))
        except Exception as e: 
            print("An error occurred:", e,  '-',  e.args[0])
            sys.exit(exit_code)                                    # Exit with Error Code
        #return (self.conn,self.cur)
        return


    # CLOSE THE DATABASE ---------------------------------------------------------------------------
    def db_close_db(self):
        try:
            if debug > 3 : print("Closing Database %s" % (self.dbname)) 
            self.conn.close()
        except Exception as e: 
            print("An error occurred:", e,  '-',  e.args[0])
            return 1       


    # CREATE SADM TABLE FUNCTION -------------------------------------------------------------------
    def db_create_table(self,tbname):
        if debug > 3 : print("Creating %s table." % (tbname)) 
        try:
            if (tbname == "sadm_cat"):
                self.cur.execute('''DROP TABLE sadm_cat''')
                self.cur.execute('''CREATE TABLE IF NOT EXISTS sadm_cat (
                    cat_code        TEXT    PRIMARY KEY ,
                    cat_desc        TEXT    NOT NULL CHECK( cat_desc != ''),
                    cat_active      INTEGER DEFAULT 1,
                    cat_default     INTEGER DEFAULT 0 NOT NULL)
                    ''')
            if (tbname == "sadm_grp"):
                self.cur.execute('''DROP TABLE sadm_grp''')
                self.cur.execute('''CREATE TABLE IF NOT EXISTS sadm_grp (
                    grp_code        TEXT    PRIMARY KEY ,
                    grp_desc        TEXT    NOT NULL CHECK( grp_desc != ''),
                    grp_active      INTEGER DEFAULT 1,
                    grp_default     INTEGER DEFAULT 0 NOT NULL)
                    ''')
            if (tbname == "sadm_srv"):
                self.cur.execute('''DROP TABLE sadm_srv''')
                self.cur.execute('''CREATE TABLE IF NOT EXISTS sadm_srv (
                    srv_name                TEXT    PRIMARY KEY ,
                    srv_domain              TEXT    NOT NULL CHECK( srv_domain != ''),
                    srv_desc                TEXT    NOT NULL CHECK( srv_desc != ''),
                    srv_notes               TEXT    ,
                    srv_active              INTEGER DEFAULT 1 NOT NULL,
                    srv_sporadic            INTEGER DEFAULT 0 NOT NULL,
                    srv_cat                 TEXT    NOT NULL,
                    srv_grp                 TEXT    NOT NULL,
                    src_creation_date       TEXT )
                    ''')                    
            self.conn.commit()   
        except Exception as e: 
            print("An error occurred:", e)
            return 1  






    # TEST    
    def dbio(self,tbname,tbkey,tbrecord,tbaction='r',tbmode='m'):
        """ dbio : Tools to read & write to tables in database
                    tbname      Is the name of table in the Database
                    tbkey       Is the value of the primary key to read/write
                    tbrecord    Is a dictionnary that data to write or have been read
                    tbaction    Tell dbio what to do 
                                    'r' for read, 
                                    'i' for insert, 
                                    'u' for update,
                                    'd' for delete,
                    tbmode      If an error occured, what dbio should do ?
                                'm' Display an error message and continue
                                'a' Display an error message and abort
                                'w' Display an error message and for user answer (abort, retry)
                    tbstatus    0 = success
                                1 = error
                                2 = database locked
                                3 = duplicate key error on insert
        """        
        tbstatus = 0                                                    # Set Default of return Val.

         # Is the table name part of the Database, if not Error
        if tbname not in tablist :
            print ("Table %s isn't part of the Database",(tbname))
            return 1
        
        if debug > 3 :                                                  # While in debug mode
            if (tbaction.upper == "R") : print ("Table %s, read key %s" % (tbname,tbkey))
            if (tbaction.upper == "U") : print ("Table %s, update key %s" % (tbname,tbkey))
            if (tbaction.upper == "D") : print ("Table %s, delete key %s" % (tbname,tbkey))
            if (tbaction.upper == "I") : print ("Table %s, insert key %s" % (tbname,tbkey))
            



        #print ("Receive fields = \n%s" % (tbrecord))
        #print ("Receive tbrecord Type is = \n%s" % (type(tbrecord)))
        #for w in tbrecord:
        #    print ("Field : %s" % (w))
        #for num,field in enumerate(tbrecord, start=1):
        #    print ("Field : {}: {}".format(num,field))

        #for k,v in tbrecord.items():
        #    print (k,v)

        collist = []
        collist.append(tbrecord['srv_name'])
        collist.append(tbrecord['srv_domain'])
        collist.append(tbrecord['srv_desc'])
        collist.append(tbrecord['srv_notes'])
        collist.append(tbrecord['srv_active'])
        collist.append(tbrecord['srv_sporadic'])
        collist.append(tbrecord['srv_cat'])
        collist.append(tbrecord['srv_grp'])
        collist.append(tbrecord['srv_creation_date'])
        #print ("collist : %s" % (collist))
        try: 
            sql = ''' INSERT INTO sadm_srv VALUES(?,?,?,?,?,?,?,?,?)  '''
            if debug > 3 :                                                  # While in debug mode
                print ("Insert statement is :\n%s,%s" % (sql,collist))        
            self.cur.execute(sql,(collist))
            self.conn.commit()   
        except sqlite3.IntegrityError as e: 
            print("Duplicate Key Error ('%s') in %s table\nError : %s" % (tbkey,tbname,e))
            self.conn.rollback()            
            return 3
        except sqlite3.OperationalError as e: 
            print("Database Locked - Trying to insert ('%s') in %s table\nError : %s" % (tbkey,tbname,e))
            self.conn.rollback()            
            return 2
        except Exception as e: 
            print("sError Trying to insert ('%s') in %s table\nError : %s" % (tbkey,tbname,e))
            self.conn.rollback()
            return 1
        return







    # INSERT ROW IN SELECTED TABLE -----------------------------------------------------------------
    def db_insert(self,tbname,fields):
        if debug > 3 : 
            print ("Insert row in %s table with key '%s'" % (tbname,fields[0]))

        # Is the table name part of the Database, if not Error
        if tbname not in tablist :
            print ("The table %s is not part of the Database",(tbname))
            return 1

        # Validate the number of fields for the tablename 
        if (tbname == "sadm_cat") : nbField = sadm_cat_nb_field 
        if (tbname == "sadm_grp") : nbField = sadm_grp_nb_field 
        if (tbname == "sadm_srv") : nbField = sadm_srv_nb_field 
        if (nbField != len(fields)):
            print ("Number of field received is incorrect (%d) for %s table",(len(fields),tbname))
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
            if (tbname == "sadm_srv"):
                sql = ''' INSERT INTO sadm_srv VALUES(?,?,?,?,?,?,?,?,?)  '''
                self.cur.execute(sql,(fields[0],fields[1],fields[2],fields[3],fields[4],fields[5],fields[6],fields[7],fields[8]))
            self.conn.commit()   
        except sqlite3.IntegrityError as e: 
            print("Primary Key '%s' already exist in %s table\nError occurred:%s" % (fields[0],tbname,e))
            self.conn.rollback()            
        except Exception as e: 
            print("Table %s Insert Key '%s' Error occurred: %s" % (tbname,fields[0],e))
            self.conn.rollback()
        return


    # UPDATE ROW IN SELECTED TABLE -----------------------------------------------------------------
    def db_update(self,tbname,tbfields,tbkey):
        if debug > 3: print ("Updating %s with key '%s'" % (tbname,tbkey))

        # Is the table name part of the Database, if not Error
        if tbname not in tablist:
            print ("The table %s isn't part of the Database",(tbname))
            return 1

        # Validate the number of fields for the tablename 
        if (tbname == "sadm_cat") : nbField = sadm_cat_nb_field 
        if (tbname == "sadm_grp") : nbField = sadm_grp_nb_field 
        if (tbname == "sadm_srv") : nbField = sadm_srv_nb_field 
        if (nbField != len(fields)):
            print ("Number of field received is incorrect (%d) for %s table",(len(fields),tbname))
            return 1


        # In Debug mode print tableName and list of fields received
        if debug > 4:
            print("Updating Data in %s table." % (tbname)) 
            print("Fields to update are %s" % (tbfields)) 
            for x in range(len(tbfields)):
                print ("[%s] %s" % (x,tbfields[x]))

        # Update Row
        try: 
            if (tbname == "sadm_cat"):
                sql = 'UPDATE sadm_cat SET cat_code=?, cat_desc=?, cat_active=?, cat_default=? where cat_code=?'
                self.cur.execute(sql,(tbfields[0],tbfields[1],tbfields[2],tbfields[3],tbkey))
            if (tbname == "sadm_grp"):
                sql = 'UPDATE sadm_grp SET grp_code=?, grp_desc=?, grp_active=?, grp_default=? where grp_code=?'
                self.cur.execute(sql,(tbfields[0],tbfields[1],tbfields[2],tbfields[3],tbkey))
            self.conn.commit()   
        except sqlite3.IntegrityError as e: 
            print("Primary Key '%s' already exist in %s table\nError occurred:%s" % (tbkey,tbname,e))
            self.conn.rollback()            
        except Exception as e: 
            print("Table %s Update Key '%s' \nError occurred: %s" % (tbname,tbkey,e))
            self.conn.rollback()
        return

        

    # DELETE ROW IN SELECTED TABLE -----------------------------------------------------------------
    def db_delete(self,tbname,tbkey):
        """
            Delete a row in tbname, identified by the table key (tbkey)
            :tbname is SADM table name
            :tbkey  is the primary key value to delete
            :return:
        """
        if debug > 3: print ("Deleting in table %s row with key '%s'" % (tbname,tbkey))

        # Is the table name part of the Database, if not Error
        if tbname not in tablist:
            print ("The table %s isn't part of the Database",(tbname))
            return 1

        try: 
            if (tbname == "sadm_grp"):
                sql = 'DELETE FROM ' + tbname + ' WHERE grp_code=? '
                self.cur.execute(sql,(tbkey,))
            if (tbname == "sadm_cat"):
                sql = 'DELETE FROM ' + tbname + ' WHERE cat_code=? '
                self.cur.execute(sql,(tbkey,))
            self.conn.commit()
        except Exception as e: 
            print("Error on Table %s trying to delete key '%s' \nError message: %s" % (tbname,tbkey,e))
            self.conn.rollback()

            
    # READ ONE ROW OF THE SELECTED TABLE
    def db_readkey(self, tbname, tbkey):
        """
            Read One row in tbname, identified by the table key (tbkey)
            :tbname is SADM table name
            :tbkey  is the primary key value to delete
            :return:
        """
        if debug > 3: print ("Reading in table %s row with key '%s'" % (tbname,tbkey))

        # Is the table name part of the Database, if not Error
        if tbname not in tablist:
            print ("The table %s isn't part of the Database",(tbname))
            return 1

        try: 
            if (tbname == "sadm_grp"):
                sql = 'SELECT * FROM ' + tbname + ' WHERE grp_code=? '
                self.cur.execute(sql,(tbkey,))
                dbrow = self.cur.fetchone()
                return list(dbrow)
            if (tbname == "sadm_cat"):
                sql = 'SELECT * FROM ' + tbname + ' WHERE cat_code=? '
                self.cur.execute(sql,(tbkey,))
                dbrow = self.cur.fetchone()
                return list(dbrow)
        except Exception as e: 
            print("Error on Table %s trying to read key '%s' \nError message: %s" % (tbname,tbkey,e))


            

    # INITIAL LOAD OF THE CATEGORY TABLE -----------------------------------------------------------
    def db_load_category(self):
        if debug > 3 : print ("Loading category table")
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
        if debug > 3 : print ("Loading group table")
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

