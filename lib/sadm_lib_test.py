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
import os, sys, time, pdb, datetime
#pdb.set_trace()                                                       # Activate Python Debugging



#===================================================================================================
# SADM Library Initialisation 
#===================================================================================================
# If SADMIN environment variable is defined, use it as the SADM Base Directory else use /sadmin.
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
sadm_lib_dir            = os.path.join(sadm_base_dir,'lib')             # Set SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add Library Dir to PyPath
import sadm_lib_std as sadm                                             # Import SADM Tools Library
sadm.load_config_file()                                                 # Load cfg var from sadmin.cfg


# SADM Variables use on a per script basis
#===================================================================================================
sadm.ver                = "5.0"                                         # Default Program Version
sadm.multiple_exec      = "N"                                           # No don't Run multiple copy
sadm.debug              = 2                                             # Default Debug Level (0-9)
sadm.exit_code          = 0                                             # Script Error Return Code
sadm.log_append         = "N"                                           # Append to Existing Log ?
sadm.log_type           = "B"                                           # 4Logger S=Scr L=Log B=Both

# SADM Configuration File Variables - Loaded from configuration file (Can be overridden here)
#===================================================================================================
sadm.cfg_mail_type      = 1                                             # 0=No 1=Err 2=Succes 3=All
#sadm.cfg_mail_addr      = ""                                            # Default is in sadmin.cfg
#sadm.cfg_cie_name       = ""                                            # Company Name
#sadm.cfg_user           = ""                                            # sadmin user account
#sadm.cfg_server         = ""                                            # sadmin FQN Server
#sadm.cfg_group          = ""                                            # sadmin group account
#sadm.cfg_max_logline    = 5000                                          # Max Nb. Lines in LOG )
#sadm.cfg_max_rchline    = 100                                           # Max Nb. Lines in RCH file
#sadm.cfg_nmon_keepdays  = 60                                            # Days to keep old *.nmon
#sadm.cfg_sar_keepdays   = 60                                            # Days to keep old *.sar
#sadm.cfg_rch_keepdays   = 60                                            # Days to keep old *.rch
#sadm.cfg_log_keepdays   = 60                                            # Days to keep old *.log
#sadm.cfg_pguser         = ""                                            # PostGres Database user
#sadm.cfg_pggroup        = ""                                            # PostGres Database Group
#sadm.cfg_pgdb           = ""                                            # PostGres Database Name
#sadm.cfg_pgschema       = ""                                            # PostGres Database Schema
#sadm.cfg_pghost         = ""                                            # PostGres Database Host
#sadm.cfg_pgport         = 5432                                          # PostGres Database Port



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():

    sadm.start()                                                        # Open Log, Create Dir ...
    sadm.display_env()                                                  # Display Libr. Env.
    #age = input("Check LOg")
    #age = raw_input("Check LOg")
    sadm.stop(sadm.exit_code)                                           # Close log & trim 
    sys.exit(sadm.exit_code)                                            # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()


