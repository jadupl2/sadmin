#!/usr/bin/env python  
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      ping_lookup.py
#   Synopsis:   ping and do a nslookup on all IP in the subnet and produce a report
#               Support Redhat/Centos v3,4,5,6,7 - Ubuntu - Debian V7,8 - Raspbian V7,8 - Fedora
#===================================================================================================
# Description
#  This script ping and do a nslookup for every IP specify in the "SUBNET" Variable.
#  Result of each subnet is recorded in their own file ${SADM_BASE_DIR}/dat/net/subnet_SUBNET.txt
#  These file are used by the Web Interface to inform user what IP is free and what IP is used.
#  On the Web interface the file can be seen by selecting the IP Inventory page.
#  It is run once a day from the crontab.
#
# --------------------------------------------------------------------------------------------------
# Version 2.6 - Nov 2016 
#       Insert Logic to Reboot the server after a successfull update
#        (If Specified in Server information in the Database)
#        The script receive a Y or N (Uppercase) as the first command line parameter to 
#        indicate if a reboot is requested.
# Version 2.7 - Nov 2016
#       Script Return code (SADM_EXIT_CODE) was set to 0 even if Error were detected when checking 
#       if update were available. Now Script return an error (1) when checking for update.
# Version 2.8 - Dec 2016
#       Correction minor bug with shutdown reboot command on Raspberry Pi
#       Now Checking if Script is running of SADMIN server at the beginning
#           - No automatic reboot on the SADMIN server while it is use to start update on client
# Version 2.9 - April 2017
#       Email log only when error for now on
# --------------------------------------------------------------------------------------------------
#
import os, time, sys, pdb, socket, datetime, getpass, subprocess, pwd, grp
from subprocess import Popen, PIPE

#===================================================================================================
# SADM Library Initialization
#===================================================================================================
# If SADMIN environment variable is defined, use it as the SADM Base Directory else use /sadmin.
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
sadm_lib_dir            = os.path.join(sadm_base_dir,'lib')             # Set SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add Library Dir to PyPath
import sadm_lib_std as sadm                                             # Import SADM Tools Library
sadm.load_config_file()                                                 # Load cfg var from sadmin.cfg


# SADM Variables use on a per script basis
#===================================================================================================
sadm.ver                = "2.9"                                         # Default Program Version
sadm.multiple_exec      = "N"                                           # Default Run multiple copy
sadm.debug              = 0                                             # Default Debug Level (0-9)
sadm.exit_code          = 0                                             # Script Error Return Code
sadm.log_append         = "N"                                           # Append to Existing Log ?
sadm.log_type           = "B"                                           # 4Logger S=Scr L=Log B=Both

# SADM Configuration file (sadmin.cfg) content loaded from configuration file (Can be overridden)
cfg_mail_type      = 1                                                  # 0=No 1=Err 2=Succes 3=All
#cfg_mail_addr      = ""                                                 # Default is in sadmin.cfg
#cfg_cie_name       = ""                                                 # Company Name
#cfg_user           = ""                                                 # sadmin user account
#cfg_server         = ""                                                 # sadmin FQN Server
#cfg_domain         = ""                                                 # sadmin Default Domain
#cfg_group          = ""                                                 # sadmin group account
#cfg_max_logline    = 5000                                               # Max Nb. Lines in LOG )
#cfg_max_rchline    = 100                                                # Max Nb. Lines in RCH file
#cfg_nmon_keepdays  = 60                                                 # Days to keep old *.nmon
#cfg_sar_keepdays   = 60                                                 # Days to keep old *.sar
#cfg_rch_keepdays   = 60                                                 # Days to keep old *.rch
#cfg_log_keepdays   = 60                                                 # Days to keep old *.log
#cfg_pguser         = ""                                                 # PostGres Database user
#cfg_pggroup        = ""                                                 # PostGres Database Group
#cfg_pgdb           = ""                                                 # PostGres Database Name
#cfg_pgschema       = ""                                                 # PostGres Database Schema
#cfg_pghost         = ""                                                 # PostGres Database Host
#cfg_pgport         = 5432                                               # PostGres Database Port
#cfg_rw_pguser      = ""                                                 # PostGres Read Write User
#cfg_rw_pgpwd       = ""                                                 # PostGres Read Write Pwd
#cfg_ro_pguser      = ""                                                 # PostGres Read Only User
#cfg_ro_pgpwd       = ""                                                 # PostGres Read Only Pwd


#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
SUBNET= ['192.168.1', '192.168.0' ]                                    # Subnet to Scan




#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main_process() :
   for net in SUBNET:
      SFILE = sadm.net_dir  + '/subnet_' + net + '.txt'                 # Construct Subnet FileName
      sadm.writelog ("Opening %s" % SFILE)                              # Log File Name been created
      SH=open(SFILE,'w')                                                # Open Output Subnet File
      for host in range(1,255):                                         # Define Range IP in Subnet
         ip = net + '.' + str(host)                                     # Cronstruct IP Address
         rc = os.system("ping -c 1 " + ip + " > /dev/null 2>&1")        # Ping THe IP Address
         if ( rc == 0 ) :                                               # Ping Work
            host_state = 'Yes'                                          # State = Yes = Alive
         else :                                                         # Ping don't work
           host_state = 'No'                                            # State = No = No response
        
         try:
            line = socket.gethostbyaddr(ip)                             # Try to resolve IP Address
            hostname = line[0]                                          # Save DNS Name 
         except:
      	    hostname = ' '                                              # No Name = Clear Name

         WLINE = "%s, %s, %s" % (ip, host_state, hostname)
         sadm.writelog ("%s" % WLINE)
         #print "%s" % WLINE
         SH.write ("%s\n" % (WLINE))
      SH.close()                                                           # Close Subnet File
      
      # Copy the resutant subnet txt file into the SADM Web Data Directory
      sadm.writelog ("Copy %s into %s" % (SFILE,sadm.www_net_dir))
      rc = os.system("cp " + SFILE + " " + sadm.www_net_dir + " >/dev/null 2>&1")       
      if ( rc != 0 ) :                                                  
         sadm.writelog ("ERROR : Could not copy %s into %s" % (SFILE,sadm.www_net_dir))
         return (1)
      sadm.writelog ("Change file owner and group to %s.%s" % (sadm.cfg_www_user, sadm.cfg_www_group))
      wuid = pwd.getpwnam(sadm.cfg_www_user).pw_uid                     # Get UID User of Wev User 
      wgid = grp.getgrnam(sadm.cfg_www_group).gr_gid                    # Get GID User of Web Group 
      os.chown(sadm.www_net_dir + '/subnet_' + net + '.txt', wuid, wgid) # Change owner of Subnet 
   return(0)

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    sadm.start()                                                        # Open Log, Create Dir ...

    # Script run by root only
    if os.geteuid() != 0:                                               # UID of user is not zero
       sadm.writelog ("This script must be run by the 'root' user")     # Advise User Message / Log
       sadm.writelog ("Process aborted")                                # Process Aborted Msg 
       sadm.stop (1)                                                    # Close and Trim Log/Email
       sys.exit(1)                                                      # Exit with Error Code
  
    # Script is run only on the SADMIN Server, If not abort script
    if socket.getfqdn() != sadm.cfg_server :                            # Only run on SADMIN
       sadm.writelog ("This script can be run only on the SADMIN server (%s)",(sadm.cfg_server))
       sadm.writelog ("Process aborted")                                # Abort advise message
       sadm.stop (1)                                                    # Close and Trim Log
       sys.exit(1)                                                      # Exit To O/S

    if sadm.debug > 4 : sadm.display_env()                              # Display Env. Variables
    sadm.exit_code=main_process()                                       # Go Scan the Subnet(s)
    sadm.stop(sadm.exit_code)                                           # Close log & trim
    sys.exit(sadm.exit_code)                                            # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()

