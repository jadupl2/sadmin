#!/usr/bin/env python3
# ==================================================================================================
#   Author      :   Jacques Duplessis
#   Date        :   2018-02-27
#   Name        :   sadm_git_config.py
#   Synopsis    :
#   Licence     :   You can redistribute it or modify under the terms of GNU General Public 
#                   License, v.2 or above.
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

#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
#
# 2018_02_27 JDuplessis
#   V1.0 Initial Version
#
#===================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch,shutil      # Import Std Python3 Modules
    from subprocess import Popen, PIPE
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                    # Activate Python Debugging


#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
pn                  = os.path.basename(sys.argv[0])                     # Program name
inst                = os.path.basename(sys.argv[0]).split('.')[0]       # Pgm name without Ext
conn                = ""                                                # MySQL Database Connector
cur                 = ""                                                # MySQL Database Cursor
sadm_base_dir       = ""                                                # SADMIN Install Directory
sver                = "1.0"
DEBUG               = False                                             # Debug Activated or Not
DRYRUN              = True                                              # Don't Install, Print Cmd
#
sroot               = ""                                                # SADMIN Root Directory
fhlog               = ""                                                # Log File Handle

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

#===================================================================================================
#                   Print [ERROR] in Red, followed by a the message received
#===================================================================================================
def printError(emsg):
    print ( color.RED + color.BOLD + "[ERROR] " + emsg + color.END)

#===================================================================================================
#                  Print [WARNING] in Red, followed by a the message received
#===================================================================================================
def printWarning(emsg):
    print ( color.YELLOW + color.BOLD + "[WARNING] " + emsg + color.END)

#===================================================================================================
#                   Print [OK] in Yellow, followed by a the message received
#===================================================================================================
def printOk(emsg):
    print ( color.GREEN + color.BOLD + "[OK] " + emsg + color.END)

#===================================================================================================
#                           Print the message received in Bold
#===================================================================================================
def printBold(emsg):
    print ( color.DARKCYAN + color.BOLD + emsg + color.END)


#===================================================================================================
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
#===================================================================================================
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




#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    
    cmd = "git config --global user.name 'Jacques Duplessis - mdebian9'"
    print (cmd)
    oscommand (cmd)

    cmd = "git config --global user.email duplessis.jacques@gmail.com'
    print (cmd)
    oscommand (cmd)

    sys.exit(0)

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
