#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadmlib_mysql.py
#   Synopsis:   SADM Module that deal with SADM MySQL Database
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
# 2017_10_06 Jacques Duplessis - V1.0 Initial Version
#
#
#===================================================================================================
import os, sys, pymysql, datetime
#import pdb
#pdb.set_trace()                                                       # Activate Python Debugging

#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
conn               = ""                                                 # Database Connector
cur                = ""                                                 # Database Cursor
libver             = "1.2                                               # Default Program Version
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
#

sadm_cat_nb_field  = 5                                                  # Nb of fields in Cat Table
sadm_grp_nb_field  = 5                                                  # Nb of fields in Grp Table
sadm_srv_nb_field  = 13                                                 # Nb of fields in Srv Table
tablist = ["server_category","server_group","server"]                   # SADM Table List

#NOTES
#except Exception as error: 
#except pymysql.err.DataError as error:             # If Read Row didn't work
#except pymysql.err.ProgrammingError as error :
#except pymysql.err.OperationnalError as error:             # If Read Row didn't work
#except pymysql.err.IntegrityError as error:             # If Read Row didn't work


#===================================================================================================
#                                   SADM Database Access Class 
#===================================================================================================
class dbtool:

    #-----------------------------------------------------------------------------------------------
    #  INITIALISATION & DATABASE CONNECTION --------------------------------------------------------
    #-----------------------------------------------------------------------------------------------
    def __init__(self, dbname='sadmin', dbdebug=0, dbsilent=False):
        """ Class dbtool: Series of function to Insert,Read,Update and delete row(s) in
            the selected MySQL Database.
            Example :
                 dbo = sadmdb.dbtool(dbname='sadmin',dbdebug=4,dbsilent=False) 
                 -  Database Name can by passed as parameter ('sadmin' is the default)
                 -  Debug Level can be from 0 to 9, depending on verbose chosen
                 -  Silent Mode is True and the error message are produce by this class 
                    Silent mode is False and then no error message in produce by this class, user 
                    got to check the value of the return code to know if error occured(1) or not (0)
                    Either mode will return code 0 if no error occured or 1 if any error occured.
        """
        self.dbname    = dbname                                         # Set Database Name
        self.dbdebug   = dbdebug                                        # Set Debug Level [0-9]
        self.dbserver  = 'localhost'                                    # Server where Database is
        self.dbuser    = 'root'                                         # Database User
        self.dbpasswd  = 'Icu@9am!'                                     # Database User Password
        self.dbsilent  = dbsilent                                       # Silent Mode (N=No Err-Msg)
        if (dbsilent)  : self.dbdebug=0                                 # If Silent No Debug Mode
        print ("Debugging Level set to %d" % (self.dbdebug))            # For Testing Only
        print ("Silent Mode is set to %s" % (self.dbsilent))            # For Testing Only

       
        # Open connection to selected Database
        # ------------------------------------------------------------------------------------------
        self.enum = 0                                                   # Reset Error Number
        self.emsg = ""                                                  # Reset Error Message
        if (self.dbdebug > 3) :                                         # Debug Display Conn. Info
            print ("Connect(%s,%s,%s,%s)" % (self.dbserver,self.dbuser,self.dbpasswd,self.dbname))
        try :
            self.conn=pymysql.connect(self.dbserver,self.dbuser,self.dbpasswd,dbname)
        except pymysql.err.OperationalError as error :
            self.enum, self.emsg = error.args                           # Get Error No. & Message
            print ("Error while connection to Database '%s'" % (self.dbname))  
            print (">>>>>>>>>>>>>",self.enum,self.emsg)                 # Print Error No. & Message
            sys.exit(1)                                                 # Exit Pgm with Error Code 1

        # Define a cursor object using cursor() method
        # ------------------------------------------------------------------------------------------
        try :
            self.cursor = self.conn.cursor()                            # Create Database cursor
        except AttributeError as error:
            self.enum, self.emsg = error.args                           # Get Error No. & Message
            if  (not self.dbsilent):                                    # If not in Silent Mode
                print ("Error creating cursor for %s" % (self.dbname))  # Inform User print DB Name 
                print (">>>>>>>>>>>>>",self.enum,self.emsg)             # Print Error No. & Message
        except pymysql.InternalError as error:
            self.enum, self.emsg = error.args                           # Get Error No. & Message
            print ("Error creating cursor for %s" % (self.dbname))      # Inform User print DB Name 
            print (">>>>>>>>>>>>>",self.enum,self.emsg)                 # Print Error No. & Message
            sys.exit(1)                                                 # Exit Pgm with Error Code 1


    #-----------------------------------------------------------------------------------------------
    # CLOSE THE DATABASE ---------------------------------------------------------------------------
    # return (0) if no error - return (1) if error encountered
    #-----------------------------------------------------------------------------------------------
    def dbclose(self):
        self.enum = 0                                                   # Reset Error Number
        self.emsg = ""                                                  # Reset Error Message
        try:
            if self.dbdebug > 2 : print ("Closing Database %s" % (self.dbname)) 
            self.conn.close()
        except Exception as error: 
            self.enum, self.emsg = error.args                           # Get Error No. & Message
            if  (not self.dbsilent):                                    # If not in Silent Mode
                print (">>>>>>>>>>>>>",self.enum,self.emsg)     # Print Error No. & Message
                return (1)                                            # return (1) to indicate Error
        return (0)


    #-----------------------------------------------------------------------------------------------
    #  Validate Parameters received by the method below --------------------------------------------
    #-----------------------------------------------------------------------------------------------
    def db_valid(self, dbcmd,tbname,tbkey,tbdata=""):
        """
            def db_valid (self, dbcmd,tbname,tbkey,tbdata=""):
        """
        self.enum = 0                                                   # Reset Error Number
        self.emsg = ""                                                  # Reset Error Message

        # In Debug Mode - Print Table Name , Number of column, Key Index and Data
        if self.dbdebug > 2: 
            if (dbcmd == "insert") or (dbcmd == "update") :
                print(dbcmd.capitalize(),"(Table=%s,Col=%d,Key=%s)\n%s" % (tbname,len(tbdata),tbkey,tbdata)) 
            if (dbcmd == "delete") or (dbcmd == "readkey") :
                print(dbcmd.capitalize(),"(Table=%s,Key=%s)" % (tbname,tbkey)) 

        # Is the table name part of the Database ?
        if tbname not in tablist:                                       # Part of Valid Table Name ?
            self.enum = 1
            self.emsg = "Invalid table name (%s), not part of Database",(tbname) 
            if  (not self.dbsilent):                                    # If not in Silent Mode
                print (">>>>> Invalid table name (%s), not part of Database",(tbname)) 
            return (1)                                                  # Return Error to Caller

        # Validate the number of column for the tablename 
        if (len(tbdata) != 0) :
            if (tbname == 'server_category'): nbColumn=sadm_cat_nb_field    # Cat Table Nb.Col.
            if (tbname == 'server_group')   : nbColumn=sadm_grp_nb_field    # Grp Table Nb.Col.
            if (tbname == 'server')         : nbColumn=sadm_srv_nb_field    # Srv Table Nb.Col.
            if (nbColumn != len(tbdata)):                                   # Received Correct Nb Column
                self.enum = 1                                               # Set Error Number
                self.emsg = "Wrong Nb. Column - Received %d instead of %d" % (len(tbdata),nbColumn)
                if  (not self.dbsilent):                                    # If not in Silent Mode
                    print (">>>>>",self.emsg,"for %s table",(tbname))       # Advise User
                return (1)                                                  # Return Error to Caller

        # In Debug mode print columns number and values received
        if (self.dbdebug > 6) and ((dbcmd == "update") or (dbcmd == "update")):
            for x in range(len(tbdata)):                                # For each element of list
                print ("Column [%s] = %s" % (x,tbdata[x]))              # Print Col. Nb & Content
        return (0)

    #-----------------------------------------------------------------------------------------------
    # INSERT ROW IN SELECTED TABLE -----------------------------------------------------------------
    # return (0) if no error - return (1) if error encountered
    # Example : cdata = ['Legacy','Legacy Unsupported Server',1,curdate,0],
    #           dbo.db_insert('server_category',cdata)                     
    #-----------------------------------------------------------------------------------------------
    def db_insert(self,tbname,tbdata):

        self.db_valid("insert",tbname,tbdata[0],tbdata)                 # Validate Parameters Recv.
        if (self.enum != 0) :                                           # If Error Found in Param.
            print (self.emsg)                                           # Inform User
            return (1)                                                  # Return Error to Caller

        # Insert the row received as parameter
        try:
            if (tbname == 'server'  ):                                  # If Server Table
                sql = "INSERT INTO server SET \
                    srv_name='%s',      srv_domain='%s',        srv_desc='%s',  srv_notes='%s',\
                    srv_active='%d',    srv_creation_date='%s', srv_sporadic='%d', \
                    srv_monitor='%d',   srv_tag='%s',           srv_cat='%s', \
                    srv_group='%s',     srv_backup='%d',        srv_update='%d' " % \
                    (tbdata[0],  tbdata[1],  tbdata[2],   tbdata[3],   tbdata[4],    tbdata[5],\
                     tbdata[6],  tbdata[7],  tbdata[8],   tbdata[9],   tbdata[10],   tbdata[11],\
                     tbdata[12]);
            if (tbname == 'server_group'  ):                            # If Table is Server Group
                sql = "INSERT INTO server_group SET \
                    grp_code='%s', grp_desc='%s', grp_active='%s', \
                    grp_date='%s', grp_default='%d' " % \
                    (tbdata[0],tbdata[1],tbdata[2],tbdata[3],tbdata[4]);
            if (tbname == 'server_category' ):                          # If Table Server Category
                sql = "INSERT INTO server_category SET \
                    cat_code='%s', cat_desc='%s', cat_active='%s', \
                    cat_date='%s', cat_default='%d' " % \
                    (tbdata[0],tbdata[1],tbdata[2],tbdata[3],tbdata[4]);
        except (TypeError, ValueError, IndexError) as error:            # Mismatch Between Num & Str
            self.enum=1                                                 # Set Class Error Number 
            self.emsg=error                                             # Get Error Message
            if  (not self.dbsilent):                                    # If not in Silent Mode
                print (">>>>>>>>>>>>>",self.enum,error)                 # Print Error No. & Message
            return (1)                                                  # return (1) to indicate Error

        if self.dbdebug > 5:                                            # Debug Higher than 5
            print ("Insert SQL Command is \n%s " % sql);                # Print Insert SQL Statement

        try:
            self.cursor.execute(sql)                                    # Insert new Data 
            self.conn.commit()                                          # Commit the transaction
            return (0)                                                  # return (0) Insert Worked
        except (pymysql.err.InternalError, pymysql.err.IntegrityError) as error:
            self.enum, self.emsg = error.args                           # Get Error No. & Message
            if  (not self.dbsilent):                                    # If not in Silent Mode
                print (">>>>>>>>>>>>>",self.enum,self.emsg)             # Print Error No. & Message
            return (1)                                                  # return (1) to indicate Error


    # ----------------------------------------------------------------------------------------------
    # UPDATE ROW IN SELECTED TABLE -----------------------------------------------------------------
    # return (0) if no error - return (1) if error encountered
    # Example : cdata = ['Test','The BatCave Server',1,curdate,0]
    #           dbo.db_update('server_category',cdata,'Test')
    # ----------------------------------------------------------------------------------------------
    def db_update(self,tbname,tbdata,tbkey):

        self.db_valid ("update",tbname,tbkey,tbdata)                    # Validate Parameters Recv.
        if (self.enum != 0) :                                           # If Error Found in Param.
            print (self.emsg)                                           # Inform User
            return (1)                                                  # Return Error to Caller

        # Construct The SQL Update Statement
        try: 
            if (tbname == 'server_category' ):
                sql = "UPDATE server_category SET \
                       cat_code='%s',cat_desc='%s',cat_active='%s',cat_date='%s',cat_default='%s' \
                       where cat_code='%s' " % \
                       (tbdata[0],tbdata[1],tbdata[2],tbdata[3],tbdata[4],tbkey)
            if (tbname == 'server_group'  ):
                sql = "UPDATE server_group SET \
                       grp_code='%s',grp_desc='%s',grp_active='%s',grp_date='%s',grp_default='%s' \
                       where grp_code='%s' " % \
                       (tbdata[0],tbdata[1],tbdata[2],tbdata[3],tbdata[4],tbkey)
            if (tbname == 'server'  ):
                sql = "UPDATE server SET \
                       srv_name='%s',      srv_domain='%s',        srv_desc='%s',  srv_notes='%s',\
                       srv_active='%d',    srv_creation_date='%s', srv_sporadic='%d',   \
                       srv_monitor='%d',   srv_tag='%s',           srv_cat='%s',        \
                       srv_group='%s',     srv_backup='%d',        srv_update='%d'      \
                       where srv_name='%s' " % \
                       (tbdata[0],  tbdata[1],  tbdata[2],   tbdata[3],   tbdata[4],    tbdata[5],\
                        tbdata[6],  tbdata[7],  tbdata[8],   tbdata[9],   tbdata[10],   tbdata[11],\
                        tbdata[12],tbkey);
        except (TypeError, ValueError, IndexError) as error:            # Mismatch Between Num & Str
            self.enum=1                                                 # Set Class Error Number 
            self.emsg=error                                             # Get Error Message
            if  (not self.dbsilent):                                    # If not in Silent Mode
                print (">>>>>>>>>>>>>",self.enum,error)                 # Print Error No. & Message
            return (1)                                                  # return (1) to indicate Err

        # Execute the SQL Update Statement
        try:
            self.cursor.execute(sql)                                    # Insert new Data 
            self.conn.commit()                                          # Commit the transaction
            return (0)                                                  # return (0) Insert Worked
        except (pymysql.err.InternalError, pymysql.err.IntegrityError) as error:
            self.enum, self.emsg = error.args                           # Get Error No. & Message
            if  (not self.dbsilent):                                    # If not in Silent Mode
                print (">>>>>>>>>>>>>",self.enum,self.emsg)             # Print Error No. & Message
            self.conn.rollback()
            return (1)                                                  # return (1) to indicate Err
        except Exception as error: 
            self.enum=1                                                 # Set Class Error Number 
            self.emsg=error                                             # Get Error Message
            if  (not self.dbsilent):                                    # If not in Silent Mode
                print (">>>>>>>>>>>>>",self.enum,error)                 # Print Error No. & Message
            self.conn.rollback()
            return (1)           


    # ----------------------------------------------------------------------------------------------
    # DELETE ROW IN SELECTED TABLE -----------------------------------------------------------------
    # return (0) if no error - return (1) if error encountered
    # Example : dbo.db_delete('server_category','Test')   
    # ----------------------------------------------------------------------------------------------
    def db_delete(self,tbname,tbkey):
        """
            Delete a row in tbname, identified by the table key (tbkey)
            :tbname is SADM table name
            :tbkey  is the primary key value to delete
            :return:
        """

        self.db_valid ("delete",tbname,tbkey)                           # Validate Parameters Recv.
        if (self.enum != 0) :                                           # If Error Found in Param.
            print (self.emsg)                                           # Inform User
            return (1)                                                  # Return Error to Caller

        try: 
            if (tbname == 'server_category' ):
                sql = 'DELETE FROM ' + tbname + " WHERE cat_code='%s' LIMIT 1" % (tbkey)
            if (tbname == 'server_group'  ):
                sql = 'DELETE FROM ' + tbname + " WHERE grp_code='%s' LIMIT 1" % (tbkey)
            if (tbname == 'server'  ):
                sql = 'DELETE FROM ' + tbname + " WHERE srv_name='%s' LIMIT 1" % (tbkey)
            if self.dbdebug > 2: print ("SQL =",(sql))

            # Execute the Delete SQL Statement
            delcount=self.cursor.execute(sql)
            if (delcount == 0):                                         # If 0 row was deleted ?
                self.enum=1                                             # Set Error number
                self.emsg="Nothing to delete"                           # Construct Error Message
                return (1)                                              # return (1) to indicate Err
            self.conn.commit()                                          # Commit the Delete Stat.

        except (IOError, ValueError) as error:
            self.enum = 1                                               # Set Error Number
            self.emsg = error                                           # Set Error Message
            if  (not self.dbsilent):                                    # If not in Silent Mode
                print (">>>>>>>>>>>>>",self.enum,self.emsg)             # Print Error No. & Message
            self.conn.rollback()
            return (1)                                                  # return (1) to indicate Err
        return (0)

            
    # ----------------------------------------------------------------------------------------------
    # READ ONE ROW OF THE SELECTED TABLE -----------------------------------------------------------
    # return (0) if no error - return (1) if error encountered
    # ----------------------------------------------------------------------------------------------
    def db_readkey(self, tbname, tbkey):
        """
            Read One row in tbname, identified by the table key (tbkey)
            :tbname is SADM table name
            :tbkey  is the primary key value to delete
            :return:
        """

        self.db_valid ("readkey",tbname,tbkey)                          # Validate Parameters Recv.
        if (self.enum != 0) :                                           # If Error Found in Param.
            print (self.emsg)                                           # Inform User
            return (1)                                                  # Return Error to Caller

        if (tbname == 'server_category' ):
            sql = 'SELECT * FROM ' + tbname + " WHERE cat_code='%s'" % (tbkey)
        if (tbname == 'server_group'  ):
            sql = 'SELECT * FROM ' + tbname + " WHERE grp_code='%s'" % (tbkey)
        if (tbname == 'server'  ):
            sql = 'SELECT * FROM ' + tbname + " WHERE srv_name='%s'" % (tbkey)

        try :
            self.cursor.execute(sql)
            dbrow = self.cursor.fetchone()
            if (dbrow == None) :
                self.enum=1 
                self.emsg = "Row not Found for key '%s'" % (tbkey)
                if  (not self.dbsilent):                                # If not in Silent Mode
                    print (">>>>>>>>>>>>>",self.enum,self.emsg)         # Print Error No. & Message
                    return(1)
            return dbrow
        except(pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as error:
            self.enum, self.emsg = error.args                           # Get Error No. & Message
            if  (not self.dbsilent):                                    # If not in Silent Mode
                print (">>>>>>>>>>>>>",self.enum,self.emsg)             # Print Error No. & Message
            return (1)                                                  # return (1) to indicate Error
