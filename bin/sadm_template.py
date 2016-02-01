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

# SADM Library Add to Python Path and Import SADM Library and GLOBAL Variables
base_dir                = os.environ.get('SADMIN','/sadmin')            # Base Dir. where appl. is
sadm_lib_dir            = os.path.join(base_dir,'lib')                  # SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add /sadmin/lib to PyPath
import sadm_lib_std    as sadmlib                                       # Import sadm Library 
import sadm_var        as g                                             # Import GLOBAL Var 
#pdb.set_trace() 


#===================================================================================================
#        Global Variables (Defined in sadm_var.py) that could be changed on a script basis
#===================================================================================================
g.ver                = "1.6"                                            # Default Program Version
g.logtype            = "B"                                              # Default S=Scr L=Log B=Both
g.multiple_exec      = "N"                                              # Default Run multiple copy
g.debug              = 8                                                # Default Debug Level (0-9)
g.exit_code          = 0                                                # Default Error Return Code

# SADM Configuration file - Variables were loaded form the configuration file (Can be overridden)
g.cfg_mail_type      = 1                                                # 0=No 1=Err 2=Succes 3=All
#g.cfg_mail_addr      = "your_email@domain.com"                          # Default is in sadmin.cfg
#g.cfg_cie_name       = "Your Company Name"                              # Company Name
#g.cfg_user           = "sadmin"                                         # sadmin user account
#g.cfg_group          = "sadmin"                                         # sadmin group account
#g.cfg_max_logline    = 5000                                             # Max Nb. Lines in LOG )
#g.cfg_max_rcline     = 100                                              # Max Nb. Lines in RCH file
#g.cfg_nmon_keepdays  = 40                                               # Days to keep old *.nmon
#g.cfg_sar_keepdays   = 40                                               # Days to keep old *.nmon
 
#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
cnow               = datetime.datetime.now()                            # Get Current Time
curdate            = cnow.strftime("%Y.%m.%d")                          # Format Current date
curtime            = cnow.strftime("%H:%M:%S")                          # Format Current Time


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
    sadmlib.stop(g.exit_code)                                           # Close log & trim 
    sys.exit(g.exit_code)                                               # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
