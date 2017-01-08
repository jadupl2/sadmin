#!/usr/bin/env python
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_database_update.py
#   Synopsis:   The Program need to run once a day.
#               It read all the {FQN}_sysinfo.txt present in /sadmin/www/dat and update the
#               server information table in the sadmin database.
#   Date:       February 2016
#===================================================================================================
import os, time, sys, pdb, socket, datetime, glob, fnmatch, psycopg2
#pdb.set_trace()                                                       # Activate Python Debugging


#===================================================================================================
# SADM Library Initialization
#===================================================================================================
# If SADMIN environment variable is defined, use it as the SADM Base Directory else use /sadmin.
sadm_base_dir           = os.environ.get('SADMIN', '/sadmin')           # Set SADM Base Directory
sadm_lib_dir            = os.path.join(sadm_base_dir,'lib')             # Set SADM Library Directory
sys.path.append(sadm_lib_dir)                                           # Add Library Dir to PyPath
import sadm_lib_std as sadm                                             # Import SADM Tools Library
sadm.load_config_file()                                                 # Load cfg var from sadmin.cfg


# SADM Variables use on a per script basis
#===================================================================================================
sadm.ver                = "5.0"                                         # Default Program Version
sadm.multiple_exec      = "N"                                           # Default Run multiple copy
sadm.debug              = 0                                             # Default Debug Level (0-9)
sadm.exit_code          = 0                                             # Script Error Return Code
sadm.log_append         = "N"                                           # Append to Existing Log ?
sadm.log_type           = "B"                                           # 4Logger S=Scr L=Log B=Both

# SADM Configuration file (sadmin.cfg) content loaded from configuration file (Can be overridden)
cfg_mail_type      = 3                                                  # 0=No 1=Err 2=Succes 3=All
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
row_list           = []
cur                = ""
conn               = ""




#===================================================================================================
#  Return to the caller a list (colnames) of the column name that are part of the SADM server table
#===================================================================================================
#
def get_columns_name(wconn, wcur,tbname):
    if sadm.debug > 4 : sadm.writelog ("Get the columns name of %s table" % (tbname))
    try :
        wcur.execute("SELECT * from sadm.server")
        colnames = [desc[0] for desc in wcur.description]
        wconn.commit()
    except psycopg2.Error as e:
        sadm.writelog ("Could not get the columns Name")
        sadm.writelog ("%s" % (e))
        sys.exit(1)
    if sadm.debug > 4 :
        sadm.writelog ("Columns name are : %s" % (colnames))
        sadm.writelog ("There are %s columns in server table" % (len(colnames)))

    return (colnames)

    
#===================================================================================================
# With column name (key) of the server table received build a dictionnary with default value (value)
# DEFINE DEFAULT VALUES OF SERVER TABLE WHEN WE NEED TO ADD A NEW SERVER INTO THE SERVER TABLE
#===================================================================================================
#
def init_row_dictionnary(colnames):
    srow = {}                                                           # Create empty Dictionnary
    for index in range(1,len(colnames)):                                # Loop from 1 to Nb Columns
        srow[colnames[index]] = ""                                      # Set All fields to Blank
        
    srow['srv_active']           = True                                 # Server Active is True
    srow['srv_vm']               = True                                 # Server is a VM is True
    srow['srv_osupdate']         = True                                 # Update O/S Periodically
    srow['srv_sporadic']         = False                                # Server online sporadically
    srow['srv_monitor']          = True                                 # Monitor Activity of server
    srow['srv_backup']           = 4                                    # 0=None 1=Mon 3=Wed 7=Sat
    srow['srv_osupdate_reboot']  = False                                # Reboot server after update
    
    srow['srv_osver_major']      = int(0)                               # Server OS Major Version
    srow['srv_memory']           = int(0)                               # Server Memory in MB
    srow['srv_kernel_bitmode']   = int(64)                              # Running Kernel 32/64 Bits
    srow['srv_hwd_bitmode']      = int(64)                              # Hardware can run 32/64Bits
    srow['srv_nb_cpu']           = int(0)                               # Number of CPU
    srow['srv_cpu_speed']        = int(0)                               # Server CPU Speed
    srow['srv_nb_socket']        = int(0)                               # Server Nb of CPU Socket
    srow['srv_core_per_socket']  = int(0)                               # Nb. Of Core per Socket 
    srow['srv_osupdate_day']     = int(5)                               # Day of Update 0=Sunday ...

    srow['srv_osupdate_period']  = 'm'                                  # m=mth w=week s=sem.b=bimen
    wdate = datetime.datetime.now()                                     # Get current Date
    srow['srv_last_update'] = wdate.date()                              # Set Last Update Date
    return (srow)


#===================================================================================================
#                                PRINT SERVER TABLE CONTENT
#===================================================================================================
#
def print_table(wconn,wcur):
    lineno = 1
    sadm.writelog ("List Server Table Content")
    try :
        wcur.execute("SELECT * from sadm.server")
        rows = wcur.fetchall()
        wconn.commit()
    except psycopg2.Error as e:
        sadm.writelog ("Error Reading Server Table")
        sadm.writelog (e.pgerror)
        sadm.writelog (e.diag.message_det)
        sys.exit(1)
    for row in rows:
        sadm.writelog ("%02d %s" % (lineno, row))
        lineno += 1

        
        
#===================================================================================================
#  FOR DEBUGGING PURPOSE AND FOR ANALYSIS IN CASE OF ERROR - PRINT CONTENT OF DICTIONNARY SERVER_ROW
#===================================================================================================
#
def print_server_row(wrow):
    sadm.writelog (sadm.ten_dash)
    sadm.writelog ("Print Server Dictionnary for Analysis")
    lineno = 0
    for k, v in wrow.iteritems():
        sadm.writelog ("[%2d] %-25s ...%s..." % (lineno, k, v))
        lineno += 1
    sadm.writelog (sadm.ten_dash)



#===================================================================================================
#     READ SERVER TABLE TO CHECK IF A KEY EXIST - SO WE KNOW IF WE WILL INSERT OR UPDATE ROW
#                   RETURN TRUE IF EXIST AND FALSE IF KEY IS NOT FOUND
#===================================================================================================
#
def read_row(wconn,wcur,wkey):
    if sadm.debug > 4 : print ("Try Locate the server %s in server table" % (wkey))
    try :
        wcur.execute("SELECT srv_name FROM sadm.server WHERE srv_name = %s", [wkey])
        wconn.commit()
    except psycopg2.ProgrammingError as e:
        print ("Error: Error trying to locate server %s in server table" % (wkey))
        print ("%s" % e)
    return wcur.fetchone() is not None



#===================================================================================================
#                      INSERT ROW INTO THE SERVER TABLE FROM THE WROW DICTIONNARY
#===================================================================================================
#
def insert_row(wconn, wcur, wrow):
    sadm.writelog ("Insert information of server %s in server table" % (wrow['srv_name']))
    wdate = datetime.datetime.now()                                     # Get current Date
    wrow['srv_creation_date'] = wdate.date()                            # Set Last Update Date
    try:
        wcur.execute("insert into sadm.server                                                   \
        (srv_name,              srv_domain,                 srv_desc,                           \
         srv_notes,                              srv_ostype,                         \
         srv_osname,            srv_oscodename,             srv_osversion,                      \
         srv_osver_major,       srv_kernel_version,         srv_kernel_bitmode,                 \
         srv_hwd_bitmode,       srv_active,                 srv_creation_date,                  \
         srv_last_update,       srv_model,                  srv_serial,                         \
         srv_vm,                srv_memory,                 srv_nb_cpu,                         \
         srv_nb_socket,         srv_core_per_socket,        srv_thread_per_core,                \
         srv_ip,                srv_ips_info,               srv_disks_info,                     \
         srv_vgs_info,          srv_sporadic,               srv_monitor,                        \
         srv_backup,            srv_osupdate,               srv_osupdate_reboot,                \
         srv_osupdate_day,      srv_osupdate_period)            \
        values (%s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s,%s,           \
                %s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s )",                               \
        (wrow['srv_name'],          wrow['srv_domain'],            wrow['srv_desc'],            \
         wrow['srv_notes'],                     wrow['srv_ostype'],          \
         wrow['srv_osname'],        wrow['srv_oscodename'],        wrow['srv_osversion'],       \
         wrow['srv_osver_major'],   wrow['srv_kernel_version'],    wrow['srv_kernel_bitmode'],  \
         wrow['srv_hwd_bitmode'],   wrow['srv_active'],            wrow['srv_creation_date'],   \
         wrow['srv_last_update'],   wrow['srv_model'],             wrow['srv_serial'],          \
         wrow['srv_vm'],            wrow['srv_memory'],            wrow['srv_nb_cpu'],          \
         wrow['srv_nb_socket'],     wrow['srv_core_per_socket'],   wrow['srv_thread_per_core'], \
         wrow['srv_ip'],            wrow['srv_ips_info'],          wrow['srv_disks_info'],      \
         wrow['srv_vgs_info'],      wrow['srv_sporadic'],          wrow['srv_monitor'],         \
         wrow['srv_backup'],        wrow['srv_osupdate'],          wrow['srv_osupdate_reboot'], \
         wrow['srv_osupdate_day'],  wrow['srv_osupdate_period'],                                \
        ))
    except (psycopg2.IntegrityError, psycopg2.ProgrammingError, KeyError, psycopg2.DataError ) , e:
        sadm.writelog ("ERROR: Inserting server %s row into server table" % (wrow['srv_name']))
        print ("%s" % e)
        wconn.rollback()
        print_server_row(wrow)
        return 1
    wconn.commit()
    sadm.writelog ("Total number of rows inserted : %s " % (wcur.rowcount))
    sadm.writelog ("Insertion of server %s Succeeded" % (wrow['srv_name']))
    return 0






#===================================================================================================
#                   UPDATE ROW INTO FROM THE WROW DICTIONNARY THE SERVER TABLE
#===================================================================================================
#
def update_row(wconn, wcur, wrow):
    sadm.writelog ("Update information of server %s in server table" % (wrow['srv_name']))
    
    try:
        wcur.execute("""update sadm.server set                          \
            srv_ostype = %s,                srv_osname = %s,            \
            srv_oscodename  = %s,           srv_domain = %s,            \
            srv_memory = %s,                srv_last_update = %s,       \
            srv_osversion = %s,             srv_osver_major = %s,       \
            srv_ip = %s ,                                 \
            srv_kernel_version = %s ,       srv_kernel_bitmode = %s,    \
            srv_model = %s,                 srv_serial = %s,            \
            srv_hwd_bitmode = %s,           srv_nb_cpu = %s,            \
            srv_cpu_speed = %s,             srv_nb_socket = %s,         \
            srv_core_per_socket = %s,       srv_thread_per_core = %s,   \
            srv_ips_info = %s,              srv_disks_info = %s,        \
            srv_vgs_info = %s                                           \
            where srv_name = %s""",                                     \
            [wrow['srv_ostype'],            wrow['srv_osname'],         \
             wrow['srv_oscodename'],        wrow['srv_domain'],         \
             wrow['srv_memory'],            wrow['srv_last_update'],    \
             wrow['srv_osversion'],         wrow['srv_osver_major'],    \
             wrow['srv_ip'],                           \
             wrow['srv_kernel_version'],    wrow['srv_kernel_bitmode'], \
             wrow['srv_model'],             wrow['srv_serial'],         \
             wrow['srv_hwd_bitmode'],       wrow['srv_nb_cpu'],         \
             wrow['srv_cpu_speed'],         wrow['srv_nb_socket'],      \
             wrow['srv_core_per_socket'],   wrow['srv_thread_per_core'],\
             wrow['srv_ips_info'],          wrow['srv_disks_info'],     \
             wrow['srv_vgs_info'],                                      \
             wrow['srv_name'] ])

    except (psycopg2.IntegrityError, psycopg2.DataError, psycopg2.ProgrammingError, TypeError), e:
        sadm.writelog ("ERROR: Updating server %s row into server table" % (wrow['srv_name']))
        sadm.writelog ("%s" % e)
        wconn.rollback()
        print_server_row(wrow)
        return 1

    wconn.commit()
    sadm.writelog ("Total number of rows updated : %s " % (wcur.rowcount))
    sadm.writelog ("Update of server %s Succeeded" % (wrow['srv_name']))
    return 0




#===================================================================================================
# Process each server (FQN}_sysinfo.txt file and update the server table in the 'sadmin' Database.
#===================================================================================================
def update_process(wconn,wcur,wcolnames):
    TOTAL_ERROR = 0
    
    # Build a list of the location of filenames of all *_sysinfo.txt in $SADMIN/www/dat
    fileList = []                                                       # List to store Filename
    for root, dirnames, filenames in os.walk(sadm.www_dat_dir):         # Parse www/dat directory
        for filename in fnmatch.filter(filenames, '*_sysinfo.txt'):     # for *_sysinfo.txt file
            fileList.append(os.path.join(root,filename))                # Add filename into filelist

    # Read Each System Information filename in filelist and update Database 
    for sysfile in fileList:                                            # Loop trough sysinfo list
        sadm.writelog ("")                                              # Display Blank Line
        sadm.writelog (sadm.dash)                                       # Display Dash Line
        sadm.writelog ("Processing filename : " + sysfile)              # Display Sysinfo File
        try:
            FH_SYSINFO = open(sysfile,'r')                              # Open Sysinfo File
        except IOError as e:                                            # If Can't open file
            sadm.writelog ("Error open file %s \r\n" % sysfile)         # Print FileName
            sadm.writelog ("Error Number : {0}\r\n.format(e.errno)")    # Print Error Number
            sadm.writelog ("Error Text   : {0}\r\n.format(e.strerror)") # Print Error Message
            return 1                                                    # Return Error to Caller


        # Read Sysinfo file - Line by Line save collected information about server
        srow = init_row_dictionnary(wcolnames)                          # Set Default Value of row
        for cfg_line in FH_SYSINFO :                                    # Loop until all lines parse
            wline        = cfg_line.strip()                             # Strip CR/LF & Trailing spaces
            if ('#' in wline or len(wline) == 0) :                      # If comment or blank line
                continue                                                # Go read the next line
            if sadm.debug > 4 : print ("  Parsing Line : %s" % wline)   # Debug Info - Parsing Line
            split_line  = wline.split(':')                              # Split based on equal sign
            CFG_NAME   = split_line[0].strip()                          # Param Name Uppercase Trim
            CFG_VALUE  = str(split_line[1]).strip()                     # Get Param Value Trimmed

            # Save Information Found in SysInfo file into our row dictionnary (server_row)
            try:
                NO_ERROR_OCCUR=True

                if "SADM_HOSTNAME" in CFG_NAME :
                    srow['srv_name']           = CFG_VALUE.lower()
                if "SADM_OS_TYPE" in CFG_NAME :
                    srow['srv_ostype']         = CFG_VALUE.lower()
                if "SADM_DOMAINNAME"  in CFG_NAME :
                    srow['srv_domain']         = CFG_VALUE.lower()
                if "SADM_HOST_IP" in CFG_NAME :
                    srow['srv_ip']             = CFG_VALUE
                if "SADM_SERVER_TYPE" in CFG_NAME :
                    if CFG_VALUE == 'P' :
                        srow['srv_vm'] = False
                    else:
                        srow['srv_vm'] = True
                if "SADM_OS_VERSION" in CFG_NAME :
                    srow['srv_osversion']      = CFG_VALUE
                if "SADM_OS_MAJOR_VERSION" in CFG_NAME :
                    srow['srv_osver_major']    = CFG_VALUE
                if "SADM_OS_NAME" in CFG_NAME :
                    srow['srv_osname']         = CFG_VALUE.lower()
                if "SADM_OS_CODE_NAME" in CFG_NAME :
                    srow['srv_oscodename']     = CFG_VALUE
                if "SADM_KERNEL_VERSION" in CFG_NAME :
                    srow['srv_kernel_version'] = CFG_VALUE

                # Running Kernel is 32 or 64 Bits
                try:
                    if "SADM_KERNEL_BITMODE" in CFG_NAME :
                        srow['srv_kernel_bitmode']  = int(CFG_VALUE)
                except ValueError as e:
                    sadm.writelog ("ERROR: Converting %s to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    srow['srv_kernel_bitmode'] = int(0)
                    TOTAL_ERROR = TOTAL_ERROR + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR=False                                # Now No "Error" is False
                
                if "SADM_SERVER_MODEL"            in CFG_NAME :
                    srow['srv_model']           = CFG_VALUE
                if "SADM_SERVER_SERIAL"           in CFG_NAME :
                    srow['srv_serial']          = CFG_VALUE

                # Memory Amount in Server in MB  (If Error Set Value to zero - to Spot Error)
                try :
                    if "SADM_SERVER_MEMORY" in CFG_NAME :
                        srow['srv_memory'] = int(CFG_VALUE)
                except ValueError as e:
                    sadm.writelog ("ERROR: Converting %s to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    srow['srv_memory'] = int(0)
                    TOTAL_ERROR = TOTAL_ERROR + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR=False                                # Now No "Error" is False
                
                # Hardware Capability to run 32 or 64 Bits  
                try :
                    if "SADM_SERVER_HARDWARE_BITMODE" in CFG_NAME :
                        srow['srv_hwd_bitmode'] = int(CFG_VALUE)
                except ValueError as e:
                    sadm.writelog ("ERROR: Converting %s to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    srow['srv_hwd_bitmode'] = int(0)
                    TOTAL_ERROR = TOTAL_ERROR + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR=False                                # Now No "Error" is False

                # Number of CPU on the Server  (If Error Set Value to zero - to Spot Error)
                try :
                    if "SADM_SERVER_NB_CPU"  in CFG_NAME :
                        srow['srv_nb_cpu'] = int(CFG_VALUE)
                except ValueError as e:
                    sadm.writelog ("ERROR: Converting %s to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    srow['srv_nb_cpu'] = int(1)
                    TOTAL_ERROR = TOTAL_ERROR + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR=False                                # Now No "Error" is False
                    
                # CPU SPeed  (If Error Set Value to zero - to Spot Error)
                try :
                    if "SADM_SERVER_CPU_SPEED"    in CFG_NAME :
                        srow['srv_cpu_speed'] = int(CFG_VALUE)
                except ValueError as e:
                    sadm.writelog ("ERROR: Converting %s to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    srow['srv_cpu_speed'] = int(1)  
                    TOTAL_ERROR = TOTAL_ERROR + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR=False                                # Now No "Error" is False

                # Number of Socket  (If Error Set Value to zero - to Spot Error)
                try :
                    if "SADM_SERVER_NB_SOCKET" in CFG_NAME :
                        srow['srv_nb_socket'] = int(CFG_VALUE)
                except :
                    sadm.writelog ("ERROR: Converting %s to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    srow['srv_nb_socket'] = int(0)
                    TOTAL_ERROR = TOTAL_ERROR + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR=False                                # Now No "Error" is False
                
                # Number of core per Socket (If Error Set Value to zero - to Spot Error)
                try:
                    if "SADM_SERVER_CORE_PER_SOCKET"  in CFG_NAME :
                        srow['srv_core_per_socket'] = int(CFG_VALUE)
                except :
                    sadm.writelog ("ERROR: Converting %s to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    srow['srv_core_per_socket'] = int(0)
                    TOTAL_ERROR = TOTAL_ERROR + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR=False                                # Now No "Error" is False
                
                # Number of Thread per core
                try :
                    if "SADM_SERVER_THREAD_PER_CORE"  in CFG_NAME :
                        srow['srv_thread_per_core'] = int(CFG_VALUE)
                except :
                    srow['srv_thread_per_core'] = int(0)
                    sadm.writelog ("ERROR: Converting %s to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    TOTAL_ERROR = TOTAL_ERROR + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR=False                                # Now No "Error" is False

                # All IP(s) defined on the servers with ETH Dev, IP Address, Netmask and MAC Address
                if "SADM_SERVER_IPS"              in CFG_NAME :
                    srow['srv_ips_info']        = CFG_VALUE
                
                # All Disks defined on the servers with Dev, Size
                try :
                    if "SADM_SERVER_DISKS"            in CFG_NAME :
                        srow['srv_disks_info']      = CFG_VALUE
                except :
                    sadm.writelog ("ERROR: Using SADM_SERVER_DISKS - Name %s and value is (%s)" % (CFG_NAME,CFG_VALUE))
                    TOTAL_ERROR = TOTAL_ERROR + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR=False                                # Now No "Error" is False


                # All Volumes Groups defined on the servers with Name, Size, USed, Free
                if "SADM_SERVER_VG(s)"            in CFG_NAME :
                    srow['srv_vgs_info']        = CFG_VALUE
                    
            except IndexError as e:
                sadm.writelog ("Error when moving data to Memory - Data Conversion Error")
                sadm.writelog ("%s" % e)
                TOTAL_ERROR = TOTAL_ERROR + 1                           # Add 1 To Total Error
                NO_ERROR_OCCUR=False                                    # Now No "Error" is False
        FH_SYSINFO.close()                                              # Close the Sysinfo File

        # Check if the server we are processing in already in the server table of SADMIN Database
        if NO_ERROR_OCCUR :                                             # If No Error Moving Fld
            found_key = read_row(wconn,wcur,srow['srv_name'])           # Try To Read Server from DB
            if found_key :                                              # If Server Found in DB
                RC = update_row(wconn,wcur,srow)                        # Go Update Row
                TOTAL_ERROR = TOTAL_ERROR + RC                          # RC=0=Success RC=1=Error
            else :                                                      # If Server was not found
                RC = insert_row(wconn,wcur,srow)                        # Go Insert new row
                TOTAL_ERROR = TOTAL_ERROR + RC                          # RC=0=Success RC=1=Error
        sadm.writelog ("Total Error Count at %d now" % (TOTAL_ERROR))   # Total Error after each Srv 

    return (TOTAL_ERROR)



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    sadm.start()                                                        # Open Log, Create Dir ...
    
    # Test if script is run by root (Optional Code)
    if os.geteuid() != 0:                                               # UID of user is not zero
       sadm.writelog ("This script must be run by the 'root' user")     # Advise User Message / Log
       sadm.writelog ("Process aborted")                                # Process Aborted Msg 
       sadm.stop (1)                                                    # Close and Trim Log/Email
       sys.exit(1)                                                      # Exit with Error Code
        
    # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    if socket.getfqdn() != sadm.cfg_server :                            # Only run on SADMIN
       sadm.writelog ("Script can only be run on SADMIN server (%s)",(sadm.cfg_server))
       sadm.writelog ("Process aborted")                                # Abort advise message
       sadm.stop (1)                                                    # Close and Trim Log
       sys.exit(1)                                                      # Exit To O/S
    
    if sadm.debug > 4 : sadm.display_env()                              # Display Env. Variables
    (conn,cur) = sadm.open_sadmin_database()                            # Open Connection 2 Database
    colnames = get_columns_name(conn,cur,"sadm.server")                 # Get Server Table Col Name
    sadm.exit_code = update_process(conn,cur,colnames)                  # Update SADMIN DB 
    sadm.close_sadmin_database(conn,cur)                                # Close Database Connection
    sadm.stop(sadm.exit_code)                                           # Close log & trim
    sys.exit(sadm.exit_code)                                            # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
