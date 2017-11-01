#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadmlib_db.py
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
import os, sys, sqlite3, datetime
import pdb
#pdb.set_trace()                                                       # Activate Python Debugging

#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
conn               = ""                                                 # Database Connector
cur                = ""                                                 # Database Cursor
libver             = "0.0d"                                             # Default Program Version
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
#

sadm_cat_nb_field  = 5                                                  # Nb of fields in Cat Table
sadm_grp_nb_field  = 5                                                  # Nb of fields in Grp Table
sadm_srv_nb_field  = 15                                                 # Nb of fields in Srv Table
tablist = ["sadm_cat","sadm_grp","sadm_srv"]                            # SADM Table List


#===================================================================================================
#                                   SADM Database Access Class 
#===================================================================================================
class dbtool:


    #  INITIALISATION & DATABASE CONNECTION --------------------------------------------------------
    def __init__(self, dbname=os.path.join(sadm_base_dir) + "/www/db/sadm.db", dbdebug=0):
        """ Class dbtool: Series of function to Insert,Read,Update and delete row(s) in
            the selected Sqlite3 Database.
            def __init__(self, dbname, dbdebug) 
                Database Name can by passed to sadm_dbtool or $SADMIN/www/db/sadm.db is used.
        """
        self.dbname = dbname
        self.dbdebug = dbdebug
        if (self.dbdebug > 1) : print ("Connecting to Database %s" % (self.dbname))
        try : 
            self.conn = sqlite3.connect(self.dbname, timeout=10)
            self.cur = self.conn.cursor()
            if (self.dbdebug > 1) : print ("Connected to Database %s" % (self.dbname))
        except Exception as e: 
            print ("Cannot Open Database %s - Error %s" % (self.dbname,e))
            sys.exit(1)                                                 # Exit with Error Code
        #return (self.conn,self.cur)
        return 


    # CLOSE THE DATABASE ---------------------------------------------------------------------------
    def dbclose(self):
        try:
            if self.dbdebug > 2 : print ("Closing Database %s" % (self.dbname)) 
            self.conn.close()
        except Exception as e: 
            print ("Problem Closing Database %s - Error : %s" % (self.dbname,e))
            return 1       



    # CREATE THE RECEIVED SADM TABLE NAME ----------------------------------------------------------
    def dbcreate_table(self,tbname):
        if (self.dbdebug > 3) : print("Creating %s table." % (tbname))  # Show Table Name in Debug
        if tbname not in tablist :                                      # Is Table Name Valid 
            print ("Table %s isn't part of the Database",(tbname))      # If Not Advise User
            dbclose()                                                   # Close DB Before Exiting
            sys.exit(1)                                                 # Exit with Error Code
        try:

            if (tbname == "sadm_cat"):                                  # For Category Table
                try : 
                    self.cur.execute('''DROP TABLE sadm_cat''')         # Try Drop Category Table
                    if (self.dbdebug > 2) :                             # If Lower Debug
                        print("Drop %s table" % (tbname))               # Show Drop Table Name 
                except Exception as e:                                  # Trap if Drop Failed
                    pass                                                # Continue even if failed
                self.cur.execute('''CREATE TABLE IF NOT EXISTS sadm_cat (
                    cat_id          INTEGER PRIMARY KEY ,
                    cat_code        TEXT    NOT NULL CHECK( cat_code != ''),
                    cat_desc        TEXT    NOT NULL CHECK( cat_desc != ''),
                    cat_active      INTEGER DEFAULT 1,
                    cat_date        TEXT,
                    cat_default     INTEGER DEFAULT 0 NOT NULL)
                    ''')
                self.cur.execute('''CREATE UNIQUE INDEX idx_cat_code on sadm_cat (cat_code)''');

            if (tbname == "sadm_grp"):                                  # For Group Table
                try : 
                    self.cur.execute('''DROP TABLE sadm_grp''')         # Try Drop Group Table
                    if (self.dbdebug > 2) :                             # If Lower Debug
                        print("Drop %s table" % (tbname))               # Show Drop Table Name 
                except Exception as e:                                  # Trap if Drop Failed
                    pass                                                # Continue even if failed
                self.cur.execute('''CREATE TABLE IF NOT EXISTS sadm_grp (
                    grp_id          INTEGER PRIMARY KEY ,
                    grp_code        TEXT    NOT NULL CHECK( grp_code != ''),
                    grp_desc        TEXT    NOT NULL CHECK( grp_desc != ''),
                    grp_active      INTEGER DEFAULT 1,
                    grp_date        TEXT,
                    grp_default     INTEGER DEFAULT 0 NOT NULL)
                    ''')
                self.cur.execute('''CREATE UNIQUE INDEX idx_grp_code on sadm_grp (grp_code)''');

            if (tbname == "sadm_srv"):                                  # For Server Table
                try : 
                    self.cur.execute('''DROP TABLE sadm_srv''')         # Try Drop Group Table
                    if (self.dbdebug > 2) :                             # If Lower Debug
                        print("Drop %s table" % (tbname))               # Show Drop Table Name 
                except Exception as e:                                  # Trap if Drop Failed
                    pass                                                # Continue even if failed
                #self.cur.execute('''DROP TABLE sadm_srv''')
                self.cur.execute('''CREATE TABLE IF NOT EXISTS sadm_srv (
                    srv_id                  INTEGER PRIMARY KEY ,
                    srv_name                TEXT    ,
                    srv_domain              TEXT    NOT NULL CHECK( srv_domain != ''),
                    srv_desc                TEXT    NOT NULL CHECK( srv_desc != ''),
                    srv_notes               TEXT    ,
                    srv_ostype              TEXT    ,
                    srv_osname              TEXT    ,
                    srv_oscodename          TEXT    ,
                    srv_osversion           TEXT    ,
                    srv_vm                  INTEGER DEFAULT 0 NOT NULL,
                    srv_active              INTEGER DEFAULT 1 NOT NULL,
                    srv_sporadic            INTEGER DEFAULT 0 NOT NULL,
                    srv_cat                 TEXT    NOT NULL,
                    srv_grp                 TEXT    NOT NULL,
                    srv_tag                 TEXT    NOT NULL,
                    srv_creation_date       TEXT )
                    ''')                    
                self.cur.execute('''CREATE UNIQUE INDEX idx_srv_name on sadm_srv (srv_name)''');
                self.conn.commit()   
        except Exception as e: 
            print("An error occurred trying to create table %s\nError %s",(tbname,e))
            return 1  






    #-----------------------------------------------------------------------------------------------
    # INSERT ROW IN SELECTED TABLE -----------------------------------------------------------------
    # Example : cdata = ['Legacy','Legacy Unsupported Server',1,curdate,0],
    #           dbo.db_insert('sadm_cat',cdata)                     
    #-----------------------------------------------------------------------------------------------
    def db_insert(self,tbname,tbdata):

        # In Debug mode print row we are inserting
        if self.dbdebug > 2: 
            print("Insert (Table=%s,Col=%d,Key=%s): %s" % (tbname,len(tbdata),tbdata[0],tbdata)) 

        # Is the table name part of the Database, if not Error
        if tbname not in tablist :
            print ("The table %s is not part of the Database",(tbname))
            return 1

        # Validate the number of fields for the tablename 
        if (tbname == "sadm_cat") : nbField = sadm_cat_nb_field 
        if (tbname == "sadm_grp") : nbField = sadm_grp_nb_field 
        if (tbname == "sadm_srv") : nbField = sadm_srv_nb_field 
        if (nbField != len(tbdata)):
            print ("ERROR: Wrong nb. of field received (%d) for %s table" % (len(tbdata),tbname))
            print ("       The parameter(s) received are : %s\n" % (tbdata))
            return 1


        # In Debug Level 7-9 Print Each column we are inserting
        if self.dbdebug > 6: 
            for x in range(len(tbdata)): print ("[%s] %s" % (x,tbdata[x]))
        
        # Insert the row received as parameter
        try: 
            if (tbname == "sadm_cat"):
               self.cur.execute('''
                INSERT INTO sadm_cat(cat_code, cat_desc, cat_active, cat_date, cat_default) 
                VALUES(?,?,?,?,?)
                ''',
                (tbdata[0],tbdata[1],tbdata[2],tbdata[3],tbdata[4]))
            if (tbname == "sadm_grp"):
               self.cur.execute('''
                INSERT INTO sadm_grp(grp_code, grp_desc, grp_active, grp_date, grp_default) 
                VALUES(?,?,?,?,?)
                ''',
                (tbdata[0],tbdata[1],tbdata[2],tbdata[3],tbdata[4]))
            if (tbname == "sadm_srv"):
                self.cur.execute('''
                    INSERT INTO sadm_srv(srv_name, srv_domain, srv_desc, srv_notes, srv_ostype,
                    srv_osname,  srv_oscodename, srv_osversion, srv_vm, srv_active, srv_sporadic,
                    srv_cat,     srv_grp,        srv_tag,       srv_creation_date) 
                    VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                    ''',
                    (tbdata[0], tbdata[1], tbdata[2], tbdata[3],  tbdata[4],  tbdata[5],  tbdata[6],
                     tbdata[7], tbdata[8], tbdata[9], tbdata[10], tbdata[11], tbdata[12], tbdata[13],
                    tbdata[14])
                    )
            self.conn.commit()   
        except sqlite3.IntegrityError as e: 
            print("Primary Key '%s' already exist in %s table\nError occurred:%s" % (tbdata[0],tbname,e))
            self.conn.rollback()            
        except Exception as e: 
            print("Table %s Insert Key '%s'\nError occurred: %s" % (tbname,tbdata[0],e))
            self.conn.rollback()
        return




    # UPDATE ROW IN SELECTED TABLE -----------------------------------------------------------------
    def db_update(self,tbname,tbdata,tbkey):

        # In Debug mode print row we are inserting
        if self.dbdebug > 2: 
            print("Update (Table=%s,Col=%d,Key=%s): %s" % (tbname,len(tbdata),tbkey,tbdata)) 

        # Is the table name part of the Database, if not Error
        if tbname not in tablist:
            print ("The table %s isn't part of the Database",(tbname))
            return 1

        # Validate the number of fields for the tablename 
        if (tbname == "sadm_cat") : nbField = sadm_cat_nb_field 
        if (tbname == "sadm_grp") : nbField = sadm_grp_nb_field 
        if (tbname == "sadm_srv") : nbField = sadm_srv_nb_field 
        if (nbField != len(tbdata)):
            print ("Number of field received is incorrect (%d) for %s table",(len(tbdata),tbname))
            return 1

        # In Debug mode print tableName and list of fields received
        if self.dbdebug > 4:
            print("Updating Data in %s table." % (tbname)) 
            print("Fields to update are %s" % (tbdata)) 
            for x in range(len(tbdata)):
                print ("[%s] %s" % (x,tbdata[x]))

        # Update Row
        try: 
            if (tbname == "sadm_cat"):
                sql = 'UPDATE sadm_cat SET cat_code=?, cat_desc=?, cat_active=?, cat_default=? where cat_code=?'
                self.cur.execute(sql,(tbdata[0],tbdata[1],tbdata[2],tbdata[3],tbkey))
            if (tbname == "sadm_grp"):
                sql = 'UPDATE sadm_grp SET grp_code=?, grp_desc=?, grp_active=?, grp_default=? where grp_code=?'
                self.cur.execute(sql,(tbdata[0],tbdata[1],tbdata[2],tbdata[3],tbkey))
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
        if self.dbdebug > 3: print ("Deleting in table %s row with key '%s'" % (tbname,tbkey))

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
        if self.dbdebug > 3: print ("Reading in table %s row with key '%s'" % (tbname,tbkey))

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
