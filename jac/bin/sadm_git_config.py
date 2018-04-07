#!/usr/bin/env python3
# ==================================================================================================
#   Author      :   Jacques Duplessis
#   Date        :   2017-09-09
#   Name        :   sadm_git_config.py
#   Synopsis    :
#   Licence     :   Initial Personnal Git Setup Environment
# ==================================================================================================
#   Copyright (C) 2016-2017 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is a free software; you can redistribute it and/or modify it under the terms
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
# 2017_09_06 JDuplessis 
#   V1.0 Initial Version
# 2018_04_06 JDuplessis 
#   V1.1 Rewritten using template 
# 2018_04_07 JDuplessis 
#   V1.2 Simplify code
#===================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,subprocess,datetime                          # Import Std Python3 Modules
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                    # Activate Python Debugging


#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
DEBUG      = False 
exit_code  = 0
hostname   = socket.gethostname().split('.')[0]    # Get current hostname
version    = "1.2"

#===================================================================================================
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
#===================================================================================================
def oscommand(command) :
    if DEBUG : print ("In sadm_oscommand function to run command : %s" % (command))
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out = p.stdout.read().strip().decode()
    err = p.stderr.read().strip().decode()
    returncode = p.wait()
    if (DEBUG) :
        print ("In sadm_oscommand function stdout is      : %s" % (out))
        print ("In sadm_oscommand function stderr is      : %s " % (err))
        print ("In sadm_oscommand function returncode is  : %s" % (returncode))
    return (returncode,out,err)


#===================================================================================================
#                                   Setup Git Personnal Environment
#===================================================================================================
def setup_git(sver):
    print (" ")
    print ("Setup Git Personnal Environment - V%s" % (sver))
    print (" ")
    
    cmd = "git config --global user.name 'Jacques Duplessis - %s'" % (hostname)
    print (cmd)
    oscommand (cmd)

    cmd = "git config --global user.email duplessis.jacques@gmail.com"
    print (cmd)
    oscommand (cmd)
 
    print (" ")
    cmd = "git config --list"
    print (cmd)
    ccode,cstdout,cstderr = oscommand (cmd)
    print (cstdout)

    return (0)                                                       # Return Error Code To Caller



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    os.system('clear')                                                 # Clear the screen
    exit_code = setup_git(version)                # Go Setup Git Environment
    sys.exit(exit_code)

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()