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
#
#===================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime                          # Import Std Python3 Modules
    SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Root Dir. Name
    sys.path.insert(0,os.path.join(SADM,'lib'))                     # Add SADMIN to sys.path
    import sadmlib_std as sadm                                      # Import SADMIN Python Library
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                    # Activate Python Debugging


#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================




#===================================================================================================
#                                   Setup Git Personnal Environment
#===================================================================================================
def setup_git(st):
    st.writelog ("Setup Git Personnal Environment")
    
    cmd = "git config --global user.name 'Jacques Duplessis - %s'" % (st.hostname)
    print (cmd)
    st.oscommand (cmd)

    cmd = "git config --global user.email duplessis.jacques@gmail.com"
    print (cmd)
    st.oscommand (cmd)

    return (0)                                                       # Return Error Code To Caller



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():

    # SADMIN TOOLS - Create SADMIN instance & setup variables specific to your program -------------
    st = sadm.sadmtools()                       # Create SADMIN Tools Instance (Setup Dir.)
    st.ver  = "1.1"                             # Indicate this script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'B'                           # Log Type  (L=Log file only  S=stdout only  B=Both)
    st.log_append = True                        # True=Append existing log  False=start a new log
    st.debug = 0                                # Debug level and verbosity (0-9)
    st.cfg_mail_type = 1                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    st.usedb = True                             # True=Use Database  False=DB Not needed for script
    st.dbsilent = False                         # Return Error Code & False=ShowErrMsg True=NoErrMsg
    #st.cfg_mail_addr = ""                      # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name  = ""                      # This Override Company Name specify in sadmin.cfg
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..
    if st.debug > 4: st.display_env()           # Under Debug - Display All Env. Variables Available
    st.exit_code = setup_git(st)                # Go Setup Git Environment
    st.stop(st.exit_code)                       # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()