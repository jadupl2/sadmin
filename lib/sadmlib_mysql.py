#!/usr/bin/env python3
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadmlib_mysql.py
#   Synopsis:   This is the Standard SADM Python Library 
#
#===================================================================================================
# Change Log
# 2018_03_20 - JDuplessis
#   V1.0 Initial Library Build
# 
# ==================================================================================================
try :
    import os, sys, pymysql, datetime, getpass, errno, time, socket, subprocess, smtplib, pwd, grp
    #import pdb                                                         # Python Debugger
    #pdb.set_trace()                                                    # Activate Python Debugging
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)

print ("I Am in MySQL Lib")
#---------------------------------------------------------------------------------------------------
# CONNECT TO DATABASE ------------------------------------------------------------------------------
# return (0) if no error - return (1) if error encountered
#---------------------------------------------------------------------------------------------------
def dbconnect(st):       
    enum = 0                                                            # Reset Error Number
    emsg = ""                                                           # Reset Error Message
    conn_string  = "'%s', " % (st.cfg_dbhost)                           # Set Host from sadmin.cfg
    conn_string += "'%s', " % (st.cfg_rw_dbuser)                        # Set RW Usr define in cfg
    conn_string += "'%s', " % (st.cfg_rw_dbpwd)                         # Set RW Pwd define in cfg
    conn_string += "'%s'"   % (st.cfg_dbname)                           # Use DBName define in cfg
    if (st.debug > 3) :                                                 # Debug Display Conn. Info
        print ("Connect(%s)" % (conn_string))
    try :
        #st.conn = pymysql.connect(conn_string)
        st.conn=pymysql.connect(st.cfg_dbhost,st.cfg_rw_dbuser,st.cfg_rw_dbpwd,st.cfg_dbname)
    except pymysql.err.OperationalError as error :
        st.enum, st.emsg = error.args                                   # Get Error No. & Message
        print ("Error connecting to Database '%s'" % (st.cfg_dbname))  
        print (">>>>>>>>>>>>>",st.enum,st.emsg)                         # Print Error No. & Message
        sys.exit(1)                                                     # Exit Pgm with Error Code 1

    # Define a cursor object using cursor() method
    # ----------------------------------------------------------------------------------------------
    try :
        st.cursor = st.conn.cursor()                                    # Create Database cursor
    #except AttributeError pymysql.InternalError as error:
    except Exception as error:
        st.enum, st.emsg = error.args                                   # Get Error No. & Message
        print ("Error creating cursor for %s" % (st.dbname))            # Inform User print DB Name 
        print (">>>>>>>>>>>>>",st.enum,st.emsg)                         # Print Error No. & Message
        sys.exit(1)                                                     # Exit Pgm with Error Code 1
    return(st.conn,st.cursor)
 

#---------------------------------------------------------------------------------------------------
# CLOSE THE DATABASE -------------------------------------------------------------------------------
# return (0) if no error - return (1) if error encountered
#---------------------------------------------------------------------------------------------------
def dbclose(st):
    st.enum = 0                                                   # Reset Error Number
    st.emsg = ""                                                  # Reset Error Message
    try:
        if st.debug > 2 : print ("Closing Database %s" % (st.cfg_dbname)) 
        st.conn.close()
    except Exception as e: 
        print ("type e = ",type(e))
        print ("e.args = ",e.args)
        print ("e = ",e)
        st.enum, st.emsg = e.args                               # Get Error No. & Message
        if  (not st.dbsilent):                                    # If not in Silent Mode
            #print (">>>>>>>>>>>>>",e.message,e.args)               # Print Error No. & Message
            print (">>>>>>>>>>>>>",e.args)                          # Print Error No. & Message
            return (1)                                              # return (1) to Show Error
    return (0)
