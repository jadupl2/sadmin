#!/usr/bin/env python3  

# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch,shutil,getpass  # Import Std Python3 Modules
    from subprocess import Popen, PIPE
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)

# Text Colors Attributes Class
class color:
    PURPLE      = '\033[95m'
    CYAN        = '\033[96m'
    DARKCYAN    = '\033[36m'
    BLUE        = '\033[94m'
    GREEN       = '\033[92m'
    YELLOW      = '\033[93m'
    RED         = '\033[91m'
    BOLD        = '\033[1m'
    UNDERLINE   = '\033[4m'
    END         = '\033[0m'

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
def user_exist(uname,dbroot_pwd):
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
#   Test if sadmin database exist
#===================================================================================================
#
def database_exist(dbname,dbroot_pwd):
    dbfound = False
    sql = 'show databases;'
    cmd = "mysql -u root -p%s -e \"%s\"" % (dbroot_pwd,sql)
    ccode,cstdout,cstderr = oscommand(cmd)                              # Execute MySQL Command 
    #print ("Error code returned is %d \n%s" % (ccode,cmd))       # Show Return Code No
    #print ("Standard out is %s" % (cstdout))                     # Print command stdout
    #print ("Standard error is %s" % (cstderr))                   # Print command stderr
    #print ("type is %s " % (type(cstdout)))
    if (ccode == 0):
        listdb = cstdout.splitlines()
        for db in listdb:
             if (db == dbname) : dbfound = True
    return (dbfound)


def askyesno(emsg,sdefault="Y"):
    while True:
        wmsg = emsg + " (" + color.DARKCYAN + color.BOLD + "Y/N" + color.END + ") " 
        wmsg += "[" + sdefault + "] ? "
        wanswer = input(wmsg)
        #print ("Answer is %s len of %d of type %s " % (wanswer,len(wanswer),type(wanswer)))
        if (len(wanswer) == 0) : wanswer=sdefault
        if ((wanswer.upper() == "Y") or (wanswer.upper() == "N")):
            break
        else:
            print ("Please respond by 'Y' or 'N'\n")
    if (wanswer.upper() == "Y") : 
        return True
    else:
        return False


#==================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    answer=askyesno('Want to load initial Database (Will erase actual content of Database)','N')
    if (answer): 
        print ("Respond Yes")
    else:
        print ("Respond No")


    dbroot_pwd = "jacques"
#    wcfg_rw_dbpwd = "Nimdas17"
 
    uname = "sadmin"
    if (user_exist(uname,dbroot_pwd)):
        print ("User %s exist" % (uname))
    else:
        print ("User %s don't exist" % (uname))
        
    uname = "batman"
    if (user_exist(uname,dbroot_pwd)):
        print ("User %s exist" % (uname))
    else:
        print ("User %s don't exist" % (uname))

    print ("\n\n")        
    dbname = "sadmin"
    if not (database_exist(dbname,dbroot_pwd)):
        print ("Database %s don't exist" % (dbname))
    else:
        print ("Database %s exist" % (dbname))
        
    dbname = "batcave"
    if not (database_exist(dbname,dbroot_pwd)):
        print ("Database %s don't exist" % (dbname))
    else:
        print ("Database %s exist" % (dbname))

        
        
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

