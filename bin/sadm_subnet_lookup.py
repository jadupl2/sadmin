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
# 2017_12_30 - JDuplessis
#       V2.10 Introduction of New Python Library  
# 2017_12_31 - JDuplessis
#       V2.11 Correct problem with copy r5esultant file into web Directory
# 2018_02_21 - JDuplessis
#       V2.12 Adjust to new calling sadmin lib method
# --------------------------------------------------------------------------------------------------
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,glob,pwd,grp,fnmatch     # Import Std Python3 Modules
    SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Root Dir. Name
    sys.path.insert(0,os.path.join(SADM,'lib'))                     # Add SADMIN to sys.path
    import sadmlib_std as sadm                                      # Import SADMIN Python Library
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)

# try :
#     import os, time, sys, pdb, socket, datetime, glob, fnmatch, pymysql
#     import getpass, subprocess, pwd, grp
#     from subprocess import Popen, PIPE   
# except ImportError as e:
#     print ("Import Error : %s " % e)
#     sys.exit(1)
#pdb.set_trace()                                                        # Activate Python Debugging


#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
SUBNET= ['192.168.1', '192.168.0' ]                                    # Subnet to Scan



#===================================================================================================
#                                 Initialize SADM Tools Function
#===================================================================================================
#
def initSADM():
    """
    Start the SADM Tools 
      - Make sure All SADM Directories exist, 
      - Open log in append mode if attribute log_append="Y", otherwise a new Log file is started.
      - Write Log Header
      - Record the start Date/Time and Status Code 2(Running) to RCH file
      - Check if Script is already running (pid_file) 
        - Advise user & Quit if Attribute multiple_exec="N"
    """

    # Making Sure SADMIN Environment Variable is Define and 'sadmlib_std.py' can be found & imported
    if not "SADMIN" in os.environ:                                      # SADMIN Env. Var. Defined ?
        print (('=' * 65))
        print ("SADMIN Environment Variable is not define")
        print ("It indicate the directory where you installed the SADMIN Tools")
        print ("Put this line in your ~/.bash_profile")
        print ("export SADMIN=/INSTALL_DIR")
        print (('=' * 65))
        sys.exit(1)
    try :
        SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Dir. Name
        sys.path.append(os.path.join(SADM,'lib'))                       # Add $SADMIN/lib to PyPath
        import sadmlib_std as sadm                                      # Import SADM Python Library
        #import sadmlib_mysql as sadmdb
    except ImportError as e:
        print ("Import Error : %s " % e)
        sys.exit(1)

    st = sadm.sadmtools()                                               # Create Sadm Tools Instance
    
    # Variables are specific to this program, change them if you want or need to -------------------
    st.ver  = "2.11"                            # Your Script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'B'                           # Log Type  L=LogFileOnly  S=StdOutOnly  B=Both
    st.log_append = True                        # True=Append to Existing Log  False=Start a new log
    st.debug = 5                                # Debug Level (0-9)
    
    # When script ends, send Log by Mail [0]=NoMail [1]=OnlyOnError [2]=OnlyOnSuccess [3]=Allways
    st.cfg_mail_type = 1                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    #st.cfg_mail_addr = ""                      # Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name  = ""                      # Override Company Name specify in sadmin.cfg

    # False = On MySQL Error, return MySQL Error Code & Display MySQL  Error Message
    # True  = On MySQL Error, return MySQL Error Code & Do NOT Display Error Message
    st.dbsilent = False                         # True or False

    # Start the SADM Tools 
    #   - Make sure All SADM Directories exist, 
    #   - Open log in append mode if st_log_append="Y" else create a new Log file.
    #   - Write Log Header
    #   - Write Start Date/Time and Status Code 2(Running) to RCH file
    #   - Check if Script is already running (pid_file) 
    #       - Advise user & Quit if st-multiple_exec="N"
    st.start()                                  # Make SADM Sertup is OK - Initialize SADM Env.

    return(st)                                  # Return Instance Object to caller



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main_process(st) :
    for net in SUBNET:
       SFILE = st.net_dir + '/subnet_' + net + '.txt'                   # Construct Subnet FileName
       st.writelog ("Opening %s" % SFILE)                               # Log File Name been created
       SH=open(SFILE,'w')                                               # Open Output Subnet File
       for host in range(1,255):                                        # Define Range IP in Subnet
          ip = net + '.' + str(host)                                    # Cronstruct IP Address
          rc = os.system("ping -c 1 " + ip + " > /dev/null 2>&1")       # Ping THe IP Address
          if ( rc == 0 ) :                                              # Ping Work
             host_state = 'Yes'                                         # State = Yes = Alive
          else :                                                        # Ping don't work
            host_state = 'No'                                           # State = No = No response
        
          try:
            line = socket.gethostbyaddr(ip)                             # Try to resolve IP Address
            hostname = line[0]                                          # Save DNS Name 
          except:
       	    hostname = ' '                                              # No Name = Clear Name

          WLINE = "%s, %s, %s" % (ip, host_state, hostname)
          st.writelog ("%s" % WLINE)
          print "%s" % WLINE
          SH.write ("%s\n" % (WLINE))
       SH.close()                                                       # Close Subnet File
      
       # Copy the resultant subnet txt file into the SADM Web Data Directory
       st.writelog ("Copy %s into %s" % (SFILE,st.www_net_dir))
       rc = os.system("cp " + SFILE + " " + st.www_net_dir + " >/dev/null 2>&1")       
       if ( rc != 0 ) :                                                  
            st.writelog ("ERROR : Could not copy %s into %s" % (SFILE,st.www_net_dir))
            return (1)
       st.writelog ("Change file owner and group to %s.%s" % (st.cfg_www_user, st.cfg_www_group))
       wuid = pwd.getpwnam(st.cfg_www_user).pw_uid                      # Get UID User of Wev User 
       wgid = grp.getgrnam(st.cfg_www_group).gr_gid                     # Get GID User of Web Group 
       os.chown(st.www_net_dir + '/subnet_' + net + '.txt', wuid, wgid) # Change owner of Subnet 
    return(0)



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    # SADMIN TOOLS - Create SADMIN instance & setup variables specific to your program -------------
    st = sadm.sadmtools()                       # Create SADMIN Tools Instance (Setup Dir.)
    st.ver  = "2.12"                            # Indicate this script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'B'                           # Log Type  (L=Log file only  S=stdout only  B=Both)
    st.log_append = True                        # True=Append existing log  False=start a new log
    st.debug = 0                                # Debug level and verbosity (0-9)
    st.cfg_mail_type = 1                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    st.usedb = False                            # True=Use Database  False=DB Not needed for script
    st.dbsilent = False                         # Return Error Code & False=ShowErrMsg True=NoErrMsg
    #st.cfg_mail_addr = ""                      # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name  = ""                      # This Override Company Name specify in sadmin.cfg
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..
    if st.debug > 4: st.display_env()           # Under Debug - Display All Env. Variables Available 

    # Insure that this script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
       st.writelog ("This script must be run by the 'root' user")       # Advise User Message / Log
       st.writelog ("Try sudo ./%s" % (sadm.pn))                        # Suggest to use 'sudo'
       st.writelog ("Process aborted")                                  # Process Aborted Msg
       st.stop (1)                                                      # Close and Trim Log/Email
       sys.exit(1)                                                      # Exit with Error Code
    
    # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    if st.get_fqdn() != st.cfg_server:                                  # Only run on SADMIN
        st.writelog("This script can only be run on SADMIN server (%s)" % (st.cfg_server))
        st.writelog("Process aborted")                                  # Abort advise message
        st.stop(1)                                                      # Close and Trim Log
        sys.exit(1)                                                     # Exit To O/S
        
    st.exit_code = main_process(st)                                     # Process Subnet
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
