#!/usr/bin/env python 
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_pssh_create_file.py
#   Synopsis:   Create *.txt file use by pssh in $SADMIN_BASE/cfg
#===================================================================================================
# Description
#
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
#===================================================================================================
try :
    import os, time, sys, pdb, datetime, datetime, glob, fnmatch, pymysql
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                        # Activate Python Debugging


#===================================================================================================
# SADM Library Initialization
#===================================================================================================
sadm_base_dir           = os.environ.get('SADMIN','/sadmin')            # Set SADM Base Directory
sadm_lib_dir            = os.path.join(sadm_base_dir,'lib')             # Set SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add Library Dir to PyPath
import sadm_lib_std as sadm                                             # Import SADM Tools Library
sadm.load_config_file()                                                 # Load cfg var from sadmin.cfg


# SADM Variables use on a per script basis
#===================================================================================================
sadm.ver                = "1.5"                                         # Default Program Version
sadm.multiple_exec      = "N"                                           # Default Run multiple copy
sadm.debug              = 0                                             # Default Debug Level (0-9)
sadm.exit_code          = 0                                             # Script Error Return Code
sadm.log_append         = "N"                                           # Append to Existing Log ?
sadm.log_type           = "B"                                           # 4Logger S=Scr L=Log B=Both

# SADM Configuration file (sadmin.cfg) content loaded from configuration file (Can be overridden)
sadm.cfg_mail_type      =  1                                            # 0=No 1=Err 2=Succes 3=All



#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
#
cnow               = datetime.datetime.now()                            # Get Current Time
curdate            = cnow.strftime("%Y.%m.%d")                          # Format Current date
curtime            = cnow.strftime("%H:%M:%S")                          # Format Current Time
#
pssh_aix           = sadm.cfg_dir + '/pssh/pssh_aix.txt'                # File List of aix servers  
pssh_linux         = sadm.cfg_dir + '/pssh/pssh_linux.txt'              # File List of linux servers  
pssh_servers       = sadm.cfg_dir + '/pssh/pssh_servers.txt'            # File List of ALL servers



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
    
    # Variables are specific to this program, change them if you need-------------------------------
    st.ver  = "2.7"                             # This Script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'B'                           # Log Type  L=LogFileOnly  S=StdOutOnly  B=Both
    st.log_append = True                        # True=Append to Existing Log  False=Start a new log
    st.debug = 0                                # Debug Level (0-9)
    
    # When script ends, send Log by Mail [0]=NoMail [1]=OnlyOnError [2]=OnlyOnSuccess [3]=Allways
    st.cfg_mail_type = 1                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    #st.cfg_mail_addr = ""                      # Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name  = ""                      # Override Company Name specify in sadmin.cfg

    # False = On Error, return MySQL Error Code & Display MySQL  Error Message
    # True  = On Error, return MySQL Error Code & Do NOT Display Error Message
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
#                               Process All Active servers 
#===================================================================================================

def process_servers(wconn,wcur,st):
    "process_servers function "
    st.writelog (" ")
    st.writelog (" ")
    st.writelog (sadm.dash)

    # Read All Actives Servers
    sql  = "SELECT srv_name,srv_ostype,srv_domain,srv_active "
    sql += " FROM server WHERE srv_active = %s " % ('True')
    sql += " order by srv_name;"
    try :
        wcur.execute(sql)
        rows = wcur.fetchall()
    except(pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as error:
        self.enum, self.emsg = error.args                               # Get Error No. & Message
        print (">>>>>>>>>>>>>",self.enum,self.emsg)                     # Print Error No. & Message
        return (1)
    

    # Open Aix Output file
    try:
        FH_AIX_FILE=open(pssh_aix,'w')                                  # Open Aix Server File
    except IOError as e:                                                # If Can't Create or open
        print ("Error open file %s \r\n" % pssh_aix)                    # Print FileName
        print ("Error Number : {0}\r\n.format(e.errno)")                # Print Error Number    
        print ("Error Text   : {0}\r\n.format(e.strerror)")             # Print Error Message
        return 1                                                        # Return Error To Caller
        

    # Open Linux Output file
    try:
        FH_LINUX_FILE=open(pssh_linux,'w')                              # Open Linux Server File
    except IOError as e:                                                # If Can't Create or open
        print ("Error open file %s \r\n" % pssh_linux)                  # Print FileName
        print ("Error Number : {0}\r\n.format(e.errno)")                # Print Error Number    
        print ("Error Text   : {0}\r\n.format(e.strerror)")             # Print Error Message
        return 1                                                        # Return Error To Caller

    # Open All Servers Output file
    try:
        FH_SERVERS_FILE=open(pssh_servers,'w')                          # Open All Servers File
    except IOError as e:                                                # If Can't Create or open
        print ("Error open file %s \r\n" % pssh_servers)                # Print FileName
        print ("Error Number : {0}\r\n.format(e.errno)")                # Print Error Number    
        print ("Error Text   : {0}\r\n.format(e.strerror)")             # Print Error Message
        return 1                                                        # Return Error To Caller
                    
        
    lineno = 1
    for row in rows:
        st.writelog ("%02d %s" % (lineno, row))
        (wname,wos,wdomain,wactive) = row
        st.writelog (sadm.dash)
        st.writelog ("Processing (%d) %-30s - type:%s" % (lineno,wname+"."+wdomain,wos))
        lineno += 1    
        if (wos == "aix")   : 
            FH_AIX_FILE.write  ("%s:%d root\n" % (wname+"."+wdomain,sadm.cfg_ssh_port)) 
        if (wos == "linux") : 
            FH_LINUX_FILE.write("%s:%d root\n" % (wname+"."+wdomain,sadm.cfg_ssh_port))  
        FH_SERVERS_FILE.write("%s:%d root\n" % (wname+"."+wdomain,sadm.cfg_ssh_port))  

    FH_AIX_FILE.close()  
    FH_LINUX_FILE.close()  
    FH_SERVERS_FILE.close()  
    return 0
   


#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    st = initSADM()                                                     # Initialize SADM Tools

    # Test if script is run by root (Optional Code)
    #if os.geteuid() != 0:                                               # UID of user is not zero
    #    st.writelog("This script must be run by the 'root' user")       # Advise User Message / Log
    #    st.writelog("Process aborted")                                  # Process Aborted Msg
    #    st.stop(1)                                                      # Close and Trim Log/Email
    #    sys.exit(1)                                                     # Exit with Error Code
    
    # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    if st.get_fqdn() != st.cfg_server:                                  # Only run on SADMIN
        st.writelog("This script can only be run on SADMIN server (%s)" % (st.cfg_server))
        st.writelog("Process aborted")                                  # Abort advise message
        st.stop(1)                                                      # Close and Trim Log
        sys.exit(1)                                                     # Exit To O/S
    else:                                                               # If Running on SADMIN Server
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database
    st.exit_code = process_servers(conn,cur,st)                         # Process Actives Servers 
    if st.debug > 4: st.display_env()                                   # Display Env. Variables
    if st.get_fqdn() == st.cfg_server:                                  # If Run on SADMIN Server
        st.dbclose()                                                    # Close the Database
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()