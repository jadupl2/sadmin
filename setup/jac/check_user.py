#!/usr/bin/env python3  

# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch,shutil,getpass  # Import Std Python3 Modules
    from subprocess import Popen, PIPE
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)

def oscommand(command) :
    #print ("In sadm_oscommand function to run command : %s\n" % (command))
    p = Popen(command, stdout=PIPE, stderr=PIPE, shell=True)
    out = p.stdout.read().strip().decode()
    err = p.stderr.read().strip().decode()
    returncode = p.wait()
    return (returncode,out,err)

#===================================================================================================
#   Test if user received (uname) exist in the MariaDB, root password must is needed (dbroot_pwd)                                 M A I N     P R O G R A M
#===================================================================================================
#
def user_exit(uname,dbroot_pwd):
    userfound = False
    sql = "select User from mysql.user where User='%s';" % (uname) 
    cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command 
    if (ccode == 0):
        userlist = cstdout.splitlines()
        for user in userlist:
            if (user == uname) : userfound = True
    return (userfound)

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    dbroot_pwd = "jacques"
#    wcfg_rw_dbpwd = "Nimdas17"
 
    uname = "sadmin"
    if (user_exit(uname,dbroot_pwd)):
        print ("User %s exist" % (uname))
    else:
        print ("User %s don't exist" % (uname))
        
    uname = "batman"
    if (user_exit(uname,dbroot_pwd)):
        print ("User %s exist" % (uname))
    else:
        print ("User %s don't exist" % (uname))
        
    # # Create 'sadmin' user and Grant permission 
    # print ("Creating 'sadmin' user ... ")
    # sql  = "CREATE USER 'sadmin'@'localhost' IDENTIFIED BY '%s';" % (wcfg_rw_dbpwd)
    # sql += " grant all privileges on sadmin.* to 'sadmin'@'localhost';"
    # sql += " flush privileges;"
    # sql = "select User from mysql.user;" 
    # cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)
    # ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command 
    # print ("Error code returned is %d \n%s" % (ccode,cmd))       # Show Return Code No
    # print ("Standard out is %s" % (cstdout))                     # Print command stdout
    # print ("Standard error is %s" % (cstderr))                   # Print command stderr
    # #print ("type is %s " % (type(cstdout)))
    # lista = cstdout.splitlines()
    # for user in lista:
    #     if (user == uname) :
    #         print ("%s is winner" % (user))
    #     else:
    #         print ("%s not winner" % (user))
    #print ("end")



# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()

