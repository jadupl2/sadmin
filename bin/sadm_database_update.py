#!/usr/bin/env python3
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_database_update.py
#   Synopsis:   Update SADMIN database with information collected from each system.
#===================================================================================================
# Description
#
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#   If not, see <https://www.gnu.org/licenses/>.
#===================================================================================================
# Change Log
# March 2017    v2.3 Change field separator in HOSTNAME_sysinfo.txt file from : to =
# April 2017    v2.4 Change exception Error Message more verbose
# 2017_11_23    v2.6 Move from PostGres to MySQL, New SADM Python Library and Performance Enhanced.
# 2017_12_07    v2.7 Correct Problem dealing with srv_date_update on newly added server.
# 2018_02_08    v2.8 Bug Fix with test for physical/virtual server
# 2018_02_21    v2.9 Adjust to new calling sadmin lib method#
# 2018_06_03    v3.0 Adapt to new SADMIN Python Library
# 2018_06_09    v3.1 Last O/S Update Data & Status Taken from sysinfo.txt file in dr Dir.to Upd DB.
# 2018_06_11    v3.2 Change name for sadm_database_update.py
# 2018_10_02    v3.3 Add Debug Variable and verbosity to script
# 2018_11_09    v3.4 Database Connection Error Improve
# 2018_12_19    v3.5 Fix update problem when O/S Update Date was blank.
# 2019_10_13 Update: v3.6 Take Architecture in Sysinfo.txt and store it in server database table.
# 2019_10_14 Update: v3.7 Check if Architecture column is present in server Table, if not add it.
# 2019_10_16 Update: v3.8 Don't update anymore the domain column in the Database (Change with CRUD)
# 2020_01_13 Update: v3.9 'ReaR' backup version is now updated in DB with info collect on systems.
# 2020_12_19 Fix: v3.10 Fix Typo error that cause a crash when updating server database.
# 2021_05_14 server v3.11 Get DB result as a dict. (connect cursorclass=pymysql.cursors.DictCursor)
# 2021_05_30 server v3.12 Enlarge column 'srv_model' & 'srv_kernel_version' column wasn't big enough
# 2021_06_01 server v3.13 Bug fixes and Command line option -v, -h and -d are now functional. 
# 2021_06_10 server v3.14 Enlarge column 'srv_uptime' from 20 to 25 Char 
# 2021_06_11 server v3.15 Add 'srv_boot_date' that contain last boot date & Fix error message.
# 2021_06_17 server v3.16 Fix Duplicate column name 'srv_boot_date'
# 2022_03_28 server v3.17 Give a warning instead of an error when O/S update is not yet run.
# 2022_08_17 server v3.18 Updated to use the new SADMIN Python Library v2.
# 2022_08_25 server v3.19 Fix a 'KeyError' that could cause problem.
# 2023_07_26 server v3.20 Restrict execution on the SADMIN server only.
# 2023_08_18 server v3.21 Update to SADMIN section v2.3 & update database I/O functions.
# 2025_01_25 server v3.22 Update VM Guest version in Database for sysinfo.txt file.
#@2025_08_15 server v3.23 Added restriction to run only on 'SADMIN' server.
#@2025_08_25 server v3.24 Updated to align to change to Python library
#@2025_09_04 server v3.25 Remove the need to import pymysql in the script, now done in SADMIN lib.
#@2026_05_27 server v3.26.0 Added more exception handling to database update function.
# ==================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
#from bin.sadm_template import main_process


try :
    import os,time,sys,argparse,pdb,socket,datetime,glob,fnmatch,platform,pwd,pymysql,inspect # pythonModule
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                    # Activate Python Debugging



# --------------------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.56
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your Python code.    
# --------------------------------------------------------------------------------------------------
try:
    SADM = os.environ['SADMIN']                                      # Get SADMIN Environment Var.
except KeyError as e:                                                # If SADMIN is not define
    print("Environment variable 'SADMIN' is not defined.\n%s\nScript aborted.\n" % e) 
    sys.exit(1)                                                      # Go Back to O/S with Error

try: 
    sys.path.insert(0, os.path.join(SADM, 'lib'))                    # Add lib dir to sys.path
    import sadmlib2_std as sa                                        # Import SADMIN Python Library
except ImportError as e:                                             # If Error importing SADMIN
    print("Import error : SADMIN module: %s " % e)                   # Advise User of Error
    print("Please make sure the 'SADMIN' environment variable is defined.")
    sys.exit(1)                                                      # Go Back to O/S with Error

# Local variables local to this script.
sa.pn                 = os.path.basename(sys.argv[0])         # [P]rogram [N]ame with extension
sa.ver                = "3.26.0"                              # Your Program VERSION number
sa.desc               = "Update SADMIN database with information collected from each system."
sa.inst               = sa.pn.split('.')[0]                   # INSTance Name = Pgm Name Without Ext
sa.pid                = os.getpid()                           # Get Current Process ID.
sa.hostname           = platform.node().split('.')[0].strip() # Get Current hostname
sa.username           = pwd.getpwuid(os.getuid())[0]          # Get Current User Name
sa.root_only          = False                                 # Can Only be run by 'root' (True/False)
sa.server_only        = False                                 # Run Only on SADMIN server (True/False)
sa.use_rch            = True                                  # Write exec info to RCH file(True/False)
sa.debug              = 0                                     # Debug Level 0-9 (Increase Verbose)
sa.quiet              = False                                 # If error in a function & quiet is :
                                                              # False: Show error msg & return Error No 
                                                              # True : Omly returm Error No. but No Msg
sa.exit_code          = 0                                     # Default Return Code (0=Success 1-Error)
sa.log_type           = "B"                                   # S=Screen L=Log B=Both
sa.log_append         = False                                 # Append to previous log (True/False)
sa.log_header         = True                                  # Produce Log Header (True/False)
sa.log_footer         = True                                  # Produce Log Footer (True/False)
sa.multiple_exec      = False                                 # Allow running multiple Instance ?
sa.pid_timeout        = 7200                                  # PID File TimeToLive default
sa.lock_timeout       = 3600                                  # Sec. (TTL) before automatically unlock 
sa.max_logline        = 500                                   # Maximum number of lines in log file.
sa.max_rchline        = 35                                    # Maximum number of lines in rch file.
sa.mail_addr          = ""                                    # Default use email(s) in sadmin.cfg
sa.db_used            = True                # Open/Use auto connect DB(True), No DB needed (False) 

# Fields used by sa.start(),sa.stop() & DB functions that influence execution of SADMIN library
# Thwse are default values, they can be changed by the script that use this library.
db_conn        = None              # Use this Database Connector when using DB,  set by sa.start()
db_cur         = None              # Use this Database cursor if you use the DB, set by sa.start()
sa.db_name        = "sadmin"             # Database Name (sadmin=default) define in $SADMIN/cfg/sadmin.cfg
sa.errno       = 0              # PyMysql Database Error Number
sa.errmsg     = ""             # Database Error Message


# The values of fields below, are loaded automatically from sadmin.cfg when you import sadmlib2_std.
# Change them to fit your need, they are use by start() & stop() functions of SADMIN Python Library.
sa.sadm_alert_type    = 1          # 0=NoAlert 1=AlertOnlyOnError 2=AlertOnlyOnSuccess 3=AlwaysAlert
sa.sadm_alert_group   = "default"  # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
sa.sadm_warning_group = "warning"  # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
sa.sadm_info_group    = "info"     # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
# ==================================================================================================



# Global Variables Definition use on a per script basis
#===================================================================================================
wdict           = {}                                                    # Dict for Server Columns






# Update Row From The Dictionary(wdict) To The Server Table
#===================================================================================================
def update_row(wdict,db_conn,db_cur):

    sa.write_log ("[ INFO ] Update '%s.%s' information in database." % (wdict['srv_name'],wdict['srv_domain']))
    if sa.debug > 4: 
       sa.write_log ("We are in function : %s "% (inspect.stack()[0][3])) 
       sa.write_log ("db_conn = " + str(db_conn) + " (type: " + str(type(db_conn)) + ")" )
       sa.write_log ("db_cur = "  + str(db_cur)  + " (type: " + str(type(db_cur))  + ")" )


    # Create SQL statement to update the server table with the information in the wdict dictionary.
    try:
        sql="UPDATE server SET srv_ostype='%s', srv_osname='%s', srv_vm='%d', \
             srv_ostype='%s', srv_oscodename='%s', srv_osversion='%s', srv_osver_major='%s', \
             srv_kernel_version='%s', srv_kernel_bitmode='%d', srv_hwd_bitmode='%s', \
             srv_model='%s', srv_serial='%s', srv_memory='%d', srv_nb_cpu='%d', \
             srv_cpu_speed='%d', srv_nb_socket='%d', srv_core_per_socket='%d', \
             srv_thread_per_core='%d', srv_ip='%s', srv_ips_info='%s', srv_disks_info='%s', \
             srv_date_osupdate='%s', srv_update_status='%s', srv_sadmin_dir='%s', srv_arch='%s', \
             srv_vgs_info='%s', srv_date_update='%s', srv_rear_ver='%s', srv_vm_version='%s'  \
             where srv_name='%s' ;" %  \
             (wdict['srv_ostype'], wdict['srv_osname'], wdict['srv_vm'], \
             wdict['srv_ostype'],            wdict['srv_oscodename'], \
             wdict['srv_osversion'],         wdict['srv_osver_major'], \
             wdict['srv_kernel_version'],    wdict['srv_kernel_bitmode'], \
             wdict['srv_hwd_bitmode'],       wdict['srv_model'], \
             wdict['srv_serial'],            wdict['srv_memory'], \
             wdict['srv_nb_cpu'],            wdict['srv_cpu_speed'], \
             wdict['srv_nb_socket'],         wdict['srv_core_per_socket'],\
             wdict['srv_thread_per_core'],   wdict['srv_ip'], \
             wdict['srv_ips_info'],          wdict['srv_disks_info'], \
             wdict['srv_date_osupdate'],     wdict['srv_update_status'], \
             wdict['srv_sadmin_dir'],        wdict['srv_arch'],   \
             wdict['srv_vgs_info'],          wdict['srv_date_update'], \
             wdict['srv_rear_ver'],          wdict['srv_vm_version'], \
             wdict['srv_name'] )
    except (KeyError, TypeError, ValueError, IndexError) as e:          # Mismatch Between Num & Str
        (enum,emsg) = e.args                                             # Get Error No. & Message
        sa.write_err (f"Error Code   : {e.args[0]}")
        sa.write_err (f"Error Message: {e.args[1]}")
        sa.write_err (f"Function     : {inspect.stack()[0][3]}")        # Show current function name
        sa.write_err (f">>>>>>>>>>>> (%s) %s " % (enum,emsg))           # Print Error No. & Message
        sa.write_err (f"sql          : {sql}")                          # Show SQL That Cause Error
        return(1)                                                       # return (1) to indicate Err


    # Execute the SQL Update Statement & Commit change if no error, otherwise Rollback the 
    # transaction and return an error.
    try:
        if sa.debug > 4: sa.write_log("[ DEBUG %03d ] About to execute, sql='%s'" % (sa.debug, sql))
        with db_conn.cursor() as db_cur:
             db_cur.execute( sql )                                      # Execute the SQL statement

        # No Error, then commit change to database.
        if sa.debug > 4: sa.write_log("[ DEBUG %03d ] Commit change." % (sa.debug))
        try : 
            db_conn.commit()                                            # Commit the transaction
        except Exception as e:
            enum, emsg = e.args                                         # Get Error No. & Message
            sa.write_err("[ ERROR ] Trying to update information of '%s' system.." % (wdict['srv_name']))
            sa.write_err (f"Error Code   : {e.args[0]}")
            sa.write_err (f"Error Message: {e.args[1]}")
            sa.write_err (f"Function     : {inspect.stack()[0][3]}")    # Show current function name
            sa.write_err (f">>>>>>>>>>>> (%s) %s " % (enum,emsg))       # Print Error No. & Message
            sa.write_err (f"sql          : {sql}")                      # Show SQL That Cause Error
            return(1)                                                   # return (1) to indicate Err
        sa.write_log ("[ SUCCESS ] Change committed to '%s' database." % (sa.db_name))
        return(0)                                                       # return (0) Insert Worked

    # If error trying to update system data, try to do a rollback and catch error on rollback if any.
    except Exception as e: 
        sa.write_err("[ ERROR ] Trying to update '%s' information in database." % (wdict['srv_name']))
        sa.write_err (f"Error Code   : {e.args[0]}")
        sa.write_err (f"Error Message: {e.args[1]}")
        sa.write_err (f"Function     : {inspect.stack()[0][3]}")        # Show current function name
        try : 
            db_conn.rollback()                                          # Rollback the transaction
            sa.write_log("[ INFO ] Transaction Rollback succeeded for '%s'." % (wdict['srv_name']))
            return(1)                                                   # return (1) to indicate Err
        except Exception as e:
            sa.write_err ("[ ERROR ] Occur trying to do a database transaction rollback.")
            sa.write_err (f"Error Code   : {e.args[0]}")
            sa.write_err (f"Error Message: {e.args[1]}")
            sa.write_err (f"Function     : {inspect.stack()[0][3]}")    # Show current function name
            sa.write_err (f"sql          : {sql}")                      # Show SQL That Cause Error
            sa.write_err (e)
            return(1)                                                   # Return 1 error on update




# Process all your active(s) server(s) in the Database (Used if want to process selected servers)
# --------------------------------------------------------------------------------------------------
def process_servers(db_conn,db_cur):
    sa.write_log ("Processing all actives systems")

    # Build the SQL to retreive all active systems, sorted by hostname.
    sql  = "SELECT srv_name, srv_desc, srv_domain, srv_osname  "
    sql += " FROM server WHERE srv_active = %s " % ('True')
    sql += " order by srv_name;"

    if sa.debug > 4: 
        sa.write_log (f"Function : {inspect.stack()[0][3]}")            # Show current function name
        sa.write_log ("db_conn   : " + str(db_conn) + " (type: " + str(type(db_conn)) + ")" )
        sa.write_log ("db_cur    : " + str(db_cur)  + " (type: " + str(type(db_cur))  + ")" )
        sa.write_log ("SQL       : %s" % (sql))                 

    try :
        with db_conn.cursor() as db_cur:
             db_cur.execute(sql)
             rows = db_cur.fetchall()
    except (pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as e:
        enum,emsg = e.args                                              # Get Error No. & Message
        sa.write_err (f"[ ERROR ] %d: %s" % (enum, emsg))               # Print Error No. & Message
        sa.write_err (f"Error Code   : {e.args[0]}")                    # Should be same as above
        sa.write_err (f"Error Message: {e.args[1]}")
        return (1)
    

    # Under debug show all actives systems that was fetch
    if sa.debug > 4:
        for row in rows:
            wname   = row['srv_name']
            wdesc   = row['srv_desc'] 
            wdomain = row['srv_domain']
            wos     = row['srv_osname']
            print ("wname = %s,wdesc = %s,wdomain = %s,wos = %s" % (wname, wdesc, wdomain, wos ))


    # Process each active systems
    lineno = 1
    total_error = total_warning = 0 
    for row in rows:
        wname   = row['srv_name']
        wdesc   = row['srv_desc'] 
        wdomain = row['srv_domain']
        wos     = row['srv_osname']
        sa.write_log("")                                                # Insert Blank Line
        sa.write_log (('-' * 40))                                       # Insert Dash Line
        sa.write_log ("Processing (%d) %-15s - os:%s" % (lineno,wname+"."+wdomain,wos))

        # Construct the name of the sysinfo file for that system
        sysfile = sa.dir_www_dat + "/" + wname + "/dr/" + wname + "_sysinfo.txt"
        sa.write_log("[ INFO ] Reading sysinfo file : " + sysfile)      # Display Sysinfo File

        # Open sysinfo.txt file for the current server
        try:
            FH = open(sysfile,'r')                                      # Open Sysinfo File
        except FileNotFoundError as e:
            sa.write_err("[ WARNING ] Sysinfo file '%s' could not be found."% (sysfile))
            total_warning += 1                                          # Add 1 To Total Warning
            continue
        except IOError as e:                                            # If Can't open file
            sa.write_err ("[ WARNING ] Trying to open System Information file '%s'." % (sysfile))
            total_warning += 1                                          # Add 1 To Total Warning 
            sa.write_log (f"Error Code   : {e.args[0]}")
            sa.write_log (f"Error Message: {e.args[1]}")           
            sa.write_log ("Error Number : {0}\r\n.format(e.errno)")     # Print Error Number
            sa.write_log ("error({0}):{1}".format(e.errno, e.strerror))
            sa.write_log (repr(e))
            sa.write_log( "Error Text   : {0}\r\n.format(e.strerror)")  # Print Error Message
            continue                                                    # Go read next system data
        if sa.debug > 4: sa.write_log ("[ DEBUG %03d ] SysInfo file '%s' opened" % (sa.debug,sysfile))    

        # Process the content of the sysinfo.txt file ----------------------------------------------
        if sa.debug > 4: sa.write_log("[ DEBUG %03d ] Reading '%s'." % (sa.debug, sysfile))


        # Create Dict. in which we store all the info we want to update in the DB for that server.
        # Set default value for all columns in the database.
        wdict = {}                                                      # Create an empty Dictionary
        wdict['srv_date_update']   = "None"                             # Default Value Upd.Date
        wdict['srv_sadmin_dir']    = "/opt/sadmin"                      # Set Def. SADMIN Root Dir
        wdict['srv_date_osupdate'] = "0000-00-00 00:00:00"              # Def. O/S Update Date
        wdict['srv_update_status'] = "U"                                # Def. O/S Update Status
        wdict['srv_arch']          = ""                                 # Def. Server Architecture
        wdict['srv_rear_ver']      = "N/A"                              # Default for Rear Version
        wdict['srv_vm_version']    = ""                                 # VM Guest Addition Version


        # Read each line of the sysinfo.txt file, parse it and save the information in 
        # the wdict dictionary that we will use to update the database.
        for cfg_line in FH:                                             # Loop until all lines parse
            wline = cfg_line.strip()                                    # Strip CR/LF/Trailing space
            if wline.lstrip()[0] == '#' or len(wline) == 0: continue    # If comment or blank line
            if sa.debug > 5: sa.write_log ("[ DEBUG %03d ] Parsing Line : %s" % (sa.debug, wline))
            split_line = wline.split('=')                               # Split based on equal sign
            CFG_NAME = split_line[0].strip()                            # Get Name of Variable 

            try:
                CFG_VALUE = str(split_line[1]).strip()                  # Get Value of variable
                CFG_NAME  = str.upper(CFG_NAME)                         # Make Var.Name in Uppercase
            except LookupError:
                sa.write_err(" ")                                       # Print Blank Line
                sa.write_err("[ ERROR ] Getting value on this line '%s'." % wline)  
                total_error = total_error + 1                           # Add 1 To Total Error
                NO_ERROR_OCCUR = False                                  # Now No "Error" is False
                sa.write_log("[ INFO ] Continue with the next server.") # Advise user we continue
                continue                                                # Go Read Next Line

            # Save Information Found in SysInfo file into our row dictionary (server_row)----------
            try:
                NO_ERROR_OCCUR = True                                   # Assume no error will Occur
                if "SADM_HOSTNAME"          in CFG_NAME: wdict['srv_name']           = CFG_VALUE.lower()
                if "SADM_OS_TYPE"           in CFG_NAME: wdict['srv_ostype']         = CFG_VALUE.lower()
                if "SADM_DOMAINNAME"        in CFG_NAME: wdict['srv_domain']         = CFG_VALUE.lower()
                if "SADM_HOST_IP"           in CFG_NAME: wdict['srv_ip']             = CFG_VALUE
                if "SADM_OS_VERSION"        in CFG_NAME: wdict['srv_osversion']      = CFG_VALUE
                if "SADM_OS_MAJOR_VERSION"  in CFG_NAME: wdict['srv_osver_major']    = CFG_VALUE
                if "SADM_OS_NAME"           in CFG_NAME: wdict['srv_osname']         = CFG_VALUE.lower()
                if "SADM_OS_CODE_NAME"      in CFG_NAME: wdict['srv_oscodename']     = CFG_VALUE
                if "SADM_KERNEL_VERSION"    in CFG_NAME: wdict['srv_kernel_version'] = CFG_VALUE
                if "SADM_SERVER_MODEL"      in CFG_NAME: wdict['srv_model']          = CFG_VALUE
                if "SADM_SERVER_SERIAL"     in CFG_NAME: wdict['srv_serial']         = CFG_VALUE
                if "SADM_SERVER_IPS"        in CFG_NAME: wdict['srv_ips_info']       = CFG_VALUE
                if "SADM_UPDATE_DATE"       in CFG_NAME: wdict['srv_date_update']    = CFG_VALUE
                if "SADM_OSUPDATE_DATE"     in CFG_NAME: wdict['srv_date_osupdate']  = CFG_VALUE
                if "SADM_OSUPDATE_STATUS"   in CFG_NAME: wdict['srv_update_status']  = CFG_VALUE
                if "SADM_ROOT_DIRECTORY"    in CFG_NAME: wdict['srv_sadmin_dir']     = CFG_VALUE
                if "SADM_SERVER_ARCH"       in CFG_NAME: wdict['srv_arch']           = CFG_VALUE
                if "SADM_REAR_VERSION"      in CFG_NAME: wdict['srv_rear_ver']       = CFG_VALUE
                if "SADM_VMGUEST_VERSION"   in CFG_NAME: wdict['srv_vm_version']     = CFG_VALUE
                if wdict['srv_date_osupdate'] == '' :
                   wdict['srv_date_osupdate'] = "0000-00-00 00:00:00"   # Def. O/S Update Date

                # Physical Or Virtual Server        
                if "SADM_SERVER_TYPE" in CFG_NAME:
                    if CFG_VALUE.upper() == 'P':                        # If Physical Server
                        wdict['srv_vm'] = 0                             # 0= Not a VM
                    else:
                        wdict['srv_vm'] = 1                             # 1= Is a VM

                # Running Kernel Is 32 Or 64 Bits                
                try:
                    if "SADM_KERNEL_BITMODE" in CFG_NAME: wdict['srv_kernel_bitmode'] = int(CFG_VALUE)
                except ValueError as e:
                    sa.write_err ("[ ERROR ] Converting '%s' to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    sa.write_err("%s" % e)                              # Show err# and error msg.
                    wdict['srv_kernel_bitmode'] = int(64)               # Kernel Bit Code 32 or 64
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # Memory Amount In Server In Mb (If Error Set Value To Zero - To Spot Error)
                try:
                    if "SADM_SERVER_MEMORY" in CFG_NAME: wdict['srv_memory'] = int(CFG_VALUE)
                except ValueError as e:
                    sa.write_err ("[ ERROR ] Converting '%s' to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    sa.write_err("%s" % e)                              # Show err# and error msg.
                    wdict['srv_memory'] = int(0)                        # Set Memory Amount to 0
                    total_error += 1                                    # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # Hardware Capability Run 32 Or 64 Bits (If Error Set Value To Zero - To Spot Error)
                try:
                    if "SADM_SERVER_HARDWARE_BITMODE" in CFG_NAME:
                        wdict['srv_hwd_bitmode'] = int(CFG_VALUE)
                except ValueError as e:
                    sa.write_err ("[ ERROR ] Converting '%s' to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    sa.write_err("%s" % e)                              # Show err# and error msg.
                    wdict['srv_hwd_bitmode'] = int(0)                   # Set Hard Bits to Zero
                    total_error += 1                                    # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # Number Of Cpu On The Server  (If Error Set Value To Zero - To Spot Error)
                try:
                    if "SADM_SERVER_NB_CPU"  in CFG_NAME: wdict['srv_nb_cpu'] = int(CFG_VALUE)
                except ValueError as e:
                    sa.write_err ("[ ERROR ] Converting '%s' to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    sa.write_err("%s" % e)                              # Show err# and error msg.
                    wdict['srv_nb_cpu'] = int(0)                        # Set Nb Cpu to 0
                    total_error += 1                                    # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # Cpu Speed  (If Error Set Value To Zero - To Spot Error)
                try:
                    if "SADM_SERVER_CPU_SPEED" in CFG_NAME: wdict['srv_cpu_speed'] = int(CFG_VALUE)
                except ValueError as e:
                    sa.write_err ("[ ERROR ] Converting '%s' to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    sa.write_err("%s" % e)                              # Show err# and error msg.
                    wdict['srv_cpu_speed'] = int(0)                     # Set CPU Speed to 0
                    total_error += 1                                    # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # Number Of Socket  (If Error Set Value To Zero - To Spot Error)
                try:
                    if "SADM_SERVER_NB_SOCKET" in CFG_NAME: wdict['srv_nb_socket'] = int(CFG_VALUE)
                except ValueError as e:
                    sa.write_err ("[ ERROR ] Converting '%s' to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    sa.write_err("%s" % e)                              # Show err# and error msg.
                    wdict['srv_nb_socket'] = int(0)                     # Set Nb Socket to Zero
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # Number Of Core Per Socket (If Error Set Value To Zero - To Spot Error)
                try:
                    if "SADM_SERVER_CORE_PER_SOCKET"  in CFG_NAME:
                        wdict['srv_core_per_socket'] = int(CFG_VALUE)
                except ValueError as e:
                    sa.write_err ("[ ERROR ] Converting '%s' to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    sa.write_err("%s" % e)                              # Show err# and error msg.
                    wdict['srv_core_per_socket'] = int(0)               # Set Nb Core/Socket to Zero
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # Number Of Thread Per Core (If Error Set Value To Zero - To Spot Error)
                try:
                    if "SADM_SERVER_THREAD_PER_CORE"  in CFG_NAME:
                        wdict['srv_thread_per_core'] = int(CFG_VALUE)
                except ValueError as e:
                    wdict['srv_thread_per_core'] = int(0)                # Set Nb Threads to zero
                    sa.write_err ("[ ERROR ] Converting '%s' to an integer (%s)" % (CFG_NAME,CFG_VALUE))
                    sa.write_err("%s" % e)                              # Show err# and error msg.
                    total_error += 1                                    # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # All Disks defined on the servers with Dev, Size
                try:
                    if "SADM_SERVER_DISKS" in CFG_NAME: wdict['srv_disks_info'] = CFG_VALUE
                except ValueError as e:
                    sa.write_err ("[ ERROR ] Converting '%s' to a string (%s)" % (CFG_NAME,CFG_VALUE))
                    sa.write_err("%s" % e)                              # Show err# and error msg.
                    total_error += 1                                    # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # All VGs Information
                try:
                    if "SADM_SERVER_VG" in CFG_NAME: wdict['srv_vgs_info'] = CFG_VALUE
                except ValueError as e:
                    sa.write_err ("[ ERROR ] Converting '%s' to a string (%s)" % (CFG_NAME,CFG_VALUE))
                    sa.write_err("%s" % e)                              # Show err# and error msg.
                    total_error += 1                                    # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

            except IndexError as e:                                     # Missing Name or Value
                sa.write_err("[ ERROR ] Assigning '%s' to a value of '%s'" % (CFG_NAME, CFG_VALUE))
                sa.write_err("%s" % e)                                  # Show err# and error msg.
                total_error += 1                                        # Add 1 To Total Error
                NO_ERROR_OCCUR = False                                  # Now No "Error" is False
        
        if sa.debug > 4: sa.write_log("[ DEBUG %03d ] Closing %s" % (sa.debug, sysfile))
        FH.close()                                                      # Close the Sysinfo File

        if (NO_ERROR_OCCUR) :                                           # No Error assigning value 
            rc = update_row(wdict,db_conn,db_cur)                       # Go Update Row
            total_error += rc                                           # RC=0=Success RC=1=Error
            if (total_error != 0):                                      # Not SHow if Total Error=0
                sa.write_log(" ")                                       # Space line
                sa.write_log("Total Error at %d and Warning at %d" % (total_error,total_warning)) 
        else :
            sa.write_err(" ")                                       # Space line
            sa.write_err("[ ERROR ] A Key is missing in array 'wdict'.") 
            sa.write_err("%s" % e)
            sa.write_err("Probably missing field in '%s'." % (sysfile)) 
            sa.write_err(" ")                                       # Space line
            total_error += 1                                        # Add 1 To Total Error
            continue
        lineno += 1                                                     # Increment system number

    return(total_error)                                                 # Return Nb Error to caller





# Command line Options
# --------------------------------------------------------------------------------------------------
def cmd_options(argv):

    """ Command line Options Function - Evaluate Command Line Switch Used (if any).

        Args:
            (argv): Arguments pass on the comand line.
              [-d 0-9]      Set Debug (verbose) Level
              [-h]          Show this help message
              [-v]          Show script version information
              [-X]          Delete the script PID file before running the script.

        Returns:
            sa.debug: Debug level set by the user on the command line (Default is 0)
            Your variable(s) you will need to set based on the command line options you want to use.

    """
    parser = argparse.ArgumentParser(description=sa.desc)               # Desc in SADMIN section

    # Declare Arguments
    parser.add_argument("-v",
                        action="store_true",
                        dest='version',
                        help="Show script information")
    parser.add_argument("-X",
                        action="store_true",
                        dest='delpid',
                        help="Delete script PID file prior to running.")
    parser.add_argument("-d",
                        metavar="0-9",
                        type=int,
                        dest='pdebug',
                        help="debug/verbose level from 0 to 9",
                        default=0)
    
    args = parser.parse_args()                                          # Parse the Arguments

    # Set return values accordingly.
    if args.pdebug:                                                     # Debug Level -d specified
        sa.debug = args.pdebug                                          # Save Debug Level
        print("Debug Level is now set at %d" % (sa.debug))                # Show user debug Level
    if args.version:                                                    # If -v specified
        sa.show_version(sa.ver)                                         # Show Script & Lib. Version
        sys.exit(0)                                                     # Exit with code 0
    if args.delpid:                                                     # If -X specified
        if os.path.exists(sa.pid_file):                                 # If use -X Delete PID file
            os.remove(sa.pid_file)                                      # Delete the PID file.
            print ("The PID File (" + sa.pid_file + ") is now removed.") 

    return()                                             
                                                         




# Main Function
# --------------------------------------------------------------------------------------------------
def main(argv):
    cmd_options(argv)                                                   # Analyse cmdline options
    (db_conn,db_cur) = sa.start()                                       # Init env. & Connect to DB
    if sa.db_used : sa.exit_code = process_servers(db_conn,db_cur)      # Loop All Active systems
    sa.stop(sa.exit_code)                                               # Exit Gracefully & Close DB
    sys.exit(sa.exit_code)                                              # Back to O/S with Exit Code

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)
