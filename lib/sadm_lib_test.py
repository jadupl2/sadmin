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
#
# If SADMIN environment variable is defined, use it as the SADM Base Directory else use /sadmin.
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
sadm_lib_dir            = os.path.join(sadm_base_dir,'lib')             # Set SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add Library Dir to PyPath
import sadm_lib_std as sadm                                             # Import SADM Tools Library



#===================================================================================================
# SADM Variables use on a per program basis
#===================================================================================================
sadm.ver                = "2.0"                                         # Default Program Version
sadm.logtype            = "B"                                           # Default S=Scr L=Log B=Both
sadm.multiple_exec      = "N"                                           # Default Run multiple copy
sadm.debug              = 8                                             # Default Debug Level (0-9)

# SADM Configuration file - Variables were loaded form the configuration file (Can be overridden)
#sadm.mail_type      = 1                                                # 0=No 1=Err 2=Succes 3=All
#sadm.mail_addr      = ""                                               # Default is in sadmin.cfg
#sadm.cie_name       = ""                                               # Company Name
#sadm.user           = ""                                               # sadmin user account
#sadm.server         = ""                                               # sadmin FQN Server
#sadm.group          = ""                                               # sadmin group account
#sadm.max_logline    = 5000                                             # Max Nb. Lines in LOG )
#sadm.max_rchline    = 100                                              # Max Nb. Lines in RCH file
#sadm.nmon_keepdays  = 60                                               # Days to keep old *.nmon
#sadm.sar_keepdays   = 60                                               # Days to keep old *.sar
#sadm.rch_keepdays   = 60                                               # Days to keep old *.rch
#sadm.log_keepdays   = 60                                               # Days to keep old *.log




#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    pass
    
#    g.sadmlog = sadmlib.log_tools()                                     # Instantiate SADM Log Tools
#    g.sadmlog.setlogtype(g.logtype)                                     # Set the Log Type
    
#    sadmlib.check_requirements()                                        # All That is Needed is OK?
#    sadmlib.start()                                                     # Open Log/Upd RCH/Make Dir
#    if g.debug > 4 : sadmlib.display_env()                              # Display Env. Variables
#    sadmlib.load_config_file()                                          # Load configuration file

    #if rc != 0 :
    #    g.sadmlog.write("Email problem mon Jacques")
    
#    sadmlib.sendmail("Test email","Ceci est un test") 

    #sadmlib.trimfile("/sadmin/log/nomad_sadm_fs_save_info.log",480)
#    sadmlib.stop(g.exit_code)                                           # Close log & trim 
#    sys.exit(g.exit_code)                                               # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()


