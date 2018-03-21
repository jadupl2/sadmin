#!/usr/bin/env python3 

try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch,shutil,getpass  # Import Std Python3 Modules
    import pymysql 
    from subprocess import Popen, PIPE
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                        # Activate Python Debugging

DEBUG = True


def oscommand(command) :
    if DEBUG : print ("In sadm_oscommand function to run command : %s" % (command))
    p = Popen(command, stdout=PIPE, stderr=PIPE, shell=True)
    out = p.stdout.read().strip().decode()
    err = p.stderr.read().strip().decode()
    returncode = p.wait()
    if (DEBUG) :
        print ("In sadm_oscommand function stdout is      : %s" % (out))
        print ("In sadm_oscommand function stderr is      : %s " % (err))
        print ("In sadm_oscommand function returncode is  : %s" % (returncode))
    #if returncode:
    #    raise Exception(returncode,err)
    #else :
    return (returncode,out,err)

def run_sql_file(filename, connection):
    '''
    The function takes a filename and a connection as input
    and will run the SQL query on the given connection  
    '''
    start = time.time()
    
    file = open(filename, 'r')
    sql = s = " ".join(file.readlines())
    print ("Start executing: " + filename + " at " + str(datetime.datetime.now().strftime("%Y-%m-%d %H:%M")) + "\n" + sql )
    cursor = connection.cursor()
    cursor.execute(sql)    
    connection.commit()
    
    end = time.time()
    print ("Time elapsed to run the query:")
    print (str((end - start)*1000) + ' ms')
    
    
 
def main():    
    try:
        connection = pymysql.connect('localhost', 'root', 'jacques', 'sadmin')
    except (pymysql.err.InternalError, pymysql.err.OperationalError) as error :
        enum, emsg = error.args                           # Get Error No. & Message
        print ("Error connecting to Database '%s'" % ('sadmin'))  
        print (">>>>>>>>>>>>>",enum,emsg)                 # Print Error No. & Message
        sys.exit(1)                                                 # Exit Pgm with Error Code 1

    run_sql_file("/opt/sadmin/setup/mysql/adduser.sql", connection)    
    connection.close()
    sys.exit(1)
    

    sroot = "/opt/sadmin"
    dbroot_pwd = "jacques"
    wcfg_rw_dbpwd = "Nimdas17"
    wcfg_ro_dbpwd = "Squery18"


    # Create SQL to create sadmin accounts
    sadmin_users = "/opt/sadmin/setup/mysql/useradd2.sql"
    print (' ')
    print ("Creating SADMIN MySQL user 'sadmin' and 'squery'")

    try:                                                                # In case old file exist
        dbh = open(sadmin_users,'w')                                    # Open File in write mode
    except IOError as e:                                                # Something went wrong 
        writelog("Unable to Open %s" % e)                               # Advise user
    #
    line = "use mysql;\n"
    dbh.write (line)                                                    # Write line to output file
    line = "flush privileges;\n"
    dbh.write (line)                                                    # Write line to output file
    line = "CREATE USER 'sadmin'@'localhost' IDENTIFIED BY '%s';\n" % (wcfg_rw_dbpwd)
    dbh.write (line)                                                    # Write line to output file
    line = "grant all privileges on sadmin.* to 'sadmin'@'localhost';\n"
    dbh.write (line)                                                    # Write line to output file
    line = "CREATE USER 'squery'@'localhost' IDENTIFIED BY '%s';\n" % (wcfg_ro_dbpwd)
    dbh.write (line)                                                    # Write line to output file
    line = "grant select, show view on sadmin.* to 'squery'@'localhost';\n"
    dbh.write (line)                                                    # Write line to output file
    line = "grant all privileges on *.* to 'root'@'localhost' identified by '%s';\n" % (dbroot_pwd)
    dbh.write (line)                                                    # Write line to output file
    line = "flush privileges;\n"
    dbh.write (line)                                                    # Write line to output file
    dbh.close                                                           # Close SQL Commands file



    cmd = "mysql -u root -p%s <'%s'" % ("jacques",sadmin_users)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command 
    if (ccode != 0):                                                    # If problem creating user
        print ("Problem creating users in database ...")             # Advise User
        print ("Return code is %d - %s" % (ccode,cmd))               # Show Return Code No
        print ("Standard out is %s" % (cstdout))                     # Print command stdout
        print ("Standard error is %s" % (cstderr))                   # Print command stderr
    else:                                                               # If user created
        print ("Database users created ...")                         # Advise User ok to proceed
        print ("Return code is %d - %s" % (ccode,cmd))               # Show Return Code No
        print ("Standard out is %s" % (cstdout))                     # Print command stdout
        print ("Standard error is %s" % (cstderr))                   # Print command stderr

    print ("End")

    
if __name__ == "__main__": main()

