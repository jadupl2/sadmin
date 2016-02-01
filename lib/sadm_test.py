#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_template.py
#   Synopsis:   
#===================================================================================================
# Description
#
#
#===================================================================================================
import os, time, sys, pdb, socket, datetime, getpass, subprocess
from subprocess import Popen, PIPE
#pdb.set_trace()                                                       # Activate Python Debugging


#===================================================================================================
# SADM Library Initialisation 
#===================================================================================================
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Base Dir. where appl. is
sadm_lib_dir            = os.path.join(sadm_base_dir,'lib')             # SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add /sadmin/lib to PyPath
import sadm_lib_std    as sadmlib                                       # Import sadm Lib as sadmlib
import sadm_var        as g                                             # Import Global Var sadmglob
#

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    g.sadmlog = sadmlib.log_tools()                                     # Instantiate SADM Log Tools
    g.sadmlog.setlogtype(g.logtype)                                     # Set the Log Type
    
    sadmlib.check_requirements()                                        # All That is Needed is OK?
    sadmlib.start()                                                     # Open Log/Upd RCH/Make Dir
    if g.debug > 4 : sadmlib.display_env()                              # Display Env. Variables
    sadmlib.load_config_file()                                          # Load configuration file

    #if rc != 0 :
    #    g.sadmlog.write("Email problem mon Jacques")
    
    sadmlib.sendmail("Test email","Ceci est un test") 

    #sadmlib.trimfile("/sadmin/log/nomad_sadm_fs_save_info.log",480)
    sadmlib.stop(g.exit_code)                                           # Close log & trim 
    sys.exit(g.exit_code)                                               # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()


    
#===================================================================================================
# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()



