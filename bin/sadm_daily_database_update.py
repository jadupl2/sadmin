#!/usr/bin/env python 
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_daily_database_update.py
#   Synopsis:   Read all /sadmin/www/dat/{HOSTNAME}/dr/{HOSTNAME}_sysinfo.txt and update the 
#               Database based on the content of file.
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
# 2.3   March 2017  - Jacques Duplessis
#       To eliminate duplicate field separator with Mac Address 
#           Change field separator in HOSTNAME_sysinfo.txt file from : to = 
#       Add Error Exception when getting Value
#       Add time to Last_Daily_Update Column (Timestamp) in the SADM Database
# 2.4   April 2017  - Jacques Duplessis - Change exception Error Message more verbose
#
#
#===================================================================================================
import os, time, sys, pdb, socket, datetime, glob, fnmatch, psycopg2
#pdb.set_trace()                                                       # Activate Python Debugging



#===================================================================================================
# SADM Library Initialization
#===================================================================================================
# If SADMIN environment variable is defined, use it as the SADM Base Directory else use /sadmin.
sadm_base_dir = os.environ.get('SADMIN', '/sadmin')                     # Set SADM Base Directory
sadm_lib_dir = os.path.join(sadm_base_dir, 'lib')                       # Set SADM Library Dir.
sys.path.append(sadm_lib_dir)                                           # Add Library Dir to PyPath
import sadm_lib_std as sadm                                             # Import SADM Tools Library
sadm.load_config_file()                                                 # Load cfg from sadmin.cfg


# SADM Variables use on a per script basis
#===================================================================================================
sadm.ver = "2.4"                                                        # Default Program Version
sadm.multiple_exec = "N"                                                # Default Run multiple copy
sadm.debug = 4                                                          # Default Debug Level (0-9)
sadm.exit_code = 0                                                      # Script Error Return Code
sadm.log_append = "N"                                                   # Append to Existing Log ?
sadm.log_type = "B"                                                     # 4Logger S=Scr L=Log B=Both

# SADM Configuration file (sadmin.cfg) content loaded from configuration file (Can be overridden)
sadm.cfg_mail_type = 1                                                  # 0=No 1=Err 2=Succes 3=All



#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
conn = ""                                                               # Database Connector
cur = ""                                                                # Database Cursor
#
cnow = datetime.datetime.now()                                          # Get Current Time
curdate = cnow.strftime("%Y.%m.%d")                                     # Format Current date
curtime = cnow.strftime("%H:%M:%S")                                     # Format Current Time
row_list = []


#===================================================================================================
#  Return to the caller a list (colnames) of the column name that are part of the SADM server table
#===================================================================================================
def get_columns_name(wconn, wcur, tbname):
    """Return to the caller a list (colnames) of table column name"""
    if sadm.debug > 4:
        sadm.writelog("Get the columns name of %s table" % (tbname))
    try:
        wcur.execute("SELECT * from sadm.server")
        colnames = [desc[0] for desc in wcur.description]
        wconn.commit()
    except psycopg2.Error as e:
        sadm.writelog("Could not get the columns Name")
        sadm.writelog("%s" % (e))
        sys.exit(1)
    if sadm.debug > 4:
        sadm.writelog("Columns name are : %s" % (colnames))
        sadm.writelog("There are %s columns in server table" % (len(colnames)))
    return colnames


#===================================================================================================
# With column name (key) of the server table received build a dictionnary with default value (value)
# DEFINE DEFAULT VALUES OF SERVER TABLE WHEN WE NEED TO ADD A NEW SERVER INTO THE SERVER TABLE
#===================================================================================================
def init_row_dictionnary(colnames):
    """DEFINE DEFAULT VALUES OF SERVER TABLE WHEN WE NEED TO ADD A SERVER INTO THE SERVER TABLE"""
    srow = {}                                                           # Create empty Dictionnary
    cnow = datetime.datetime.now()                                      # Get Current Time
    #curdate = cnow.strftime("%Y.%m.%d")                                # Format Current date
    #curtime = cnow.strftime("%H:%M:%S")                                # Format Current Time
    #wdate = datetime.datetime.now()                                    # Get current Date
    wdate = cnow.strftime("%Y-%m-%d %H:%M:%S")
    #for index in range(1, len(colnames)):                              # Loop from 1 to Nb Columns
    #    srow[colnames[index]] = ""                                     # Set All fields to Blank

    srow['srv_domain'] = sadm.cfg_domain                                # Domain in sadmin.cfg
    srow['srv_active'] = True                                           # Server Active is True
    srow['srv_vm'] = True                                               # Server is a VM is True
    srow['srv_sporadic'] = False                                        # Server online sporadically
    srow['srv_monitor'] = True                                          # Monitor Activity of server
    srow['srv_backup'] = 4                                              # 0=None 1=Mon 3=Wed 7=Sat
    srow['srv_maintenance'] = False                                     # Def. Maintenance Mode OFF
    srow['srv_group'] = "Standard"                                      # Default Server Group
    srow['srv_osver_major'] = int(0)                                    # Server OS Major Version
    srow['srv_memory'] = int(0)                                         # Server Memory in MB
    srow['srv_kernel_bitmode'] = int(64)                                # Running Kernel 32/64 Bits
    srow['srv_hwd_bitmode'] = int(64)                                   # Hardware can run 32/64Bits
    srow['srv_nb_cpu'] = int(0)                                         # Number of CPU
    srow['srv_cpu_speed'] = int(0)                                      # Server CPU Speed
    srow['srv_nb_socket'] = int(0)                                      # Server Nb of CPU Socket
    srow['srv_core_per_socket'] = int(0)                                # Nb. Of Core per Socket
    srow['srv_thread_per_core'] = int(0)                                # Nb. Thread per core
    srow['srv_last_edit_date'] = wdate                           # Set Last Edit Date
    srow['srv_creation_date'] = wdate                            # Set Creation Date
    srow['srv_update_month'] = "YYYYYYYYYYYY"                           # Month of Update (1-12 Y/N)
    srow['srv_update_dom'] = "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY"          # Day of Update (1-31 Y/N)
    srow['srv_update_dow'] = "NNNNNNN"                                  # Day of Week (1-7 Y/N)
    srow['srv_update_hour'] = "NNNNNNNNNNNNNNNNNNNNNNNN"                # Hour of Update (0-23 Y/N)
    srow['srv_update_minute'] = "NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" #0-59
    srow['srv_update_reboot'] = False                                   # Reboot server after update
    srow['srv_update_status'] = "N"                                     # Server not update Yet
    srow['srv_update_auto'] = True                                      # O/S Update use Schedule
    srow['srv_update_date'] = wdate                              # Last O/S update date
    srow['srv_last_daily_update'] = wdate                        # Last Daily update date
    return srow


#===================================================================================================
#                                PRINT SERVER TABLE CONTENT
#===================================================================================================
#
def print_table(wconn, wcur):
    """PRINT SERVER TABLE CONTENT"""
    lineno = 1
    sadm.writelog("List Server Table Content")
    try:
        wcur.execute("SELECT * from sadm.server")
        rows = wcur.fetchall()
        wconn.commit()
    except psycopg2.Error as e:
        sadm.writelog("Error Reading Server Table")
        sadm.writelog(e.pgerror)
        sadm.writelog(e.diag.message_det)
        sys.exit(1)
    for row in rows:
        sadm.writelog("%02d %s" % (lineno, row))
        lineno += 1




#===================================================================================================
#  FOR DEBUGGING PURPOSE AND FOR ANALYSIS IN CASE OF ERROR - PRINT CONTENT OF DICTIONNARY SERVER_ROW
#===================================================================================================
#
def print_server_row(wrow):
    """PRINT CONTENT OF DICTIONNARY SERVER_ROW"""
    sadm.writelog(sadm.ten_dash)
    sadm.writelog("Print Server Dictionnary for Analysis")
    lineno = 0
    for k, val in wrow.iteritems():
        sadm.writelog("[%2d] %-25s ...%s..." % (lineno, k, val))
        lineno += 1
    sadm.writelog(sadm.ten_dash)



#===================================================================================================
#     READ SERVER TABLE TO CHECK IF A KEY EXIST - SO WE KNOW IF WE WILL INSERT OR UPDATE ROW
#                   RETURN TRUE IF EXIST AND FALSE IF KEY IS NOT FOUND
#===================================================================================================
#
def read_row(wconn, wcur, wkey):
    """RETURN TRUE IF EXIST AND FALSE IF KEY IS NOT FOUND"""
    if sadm.debug > 4:
        print "Try Locate the server %s in server table" % (wkey)
    try:
        wcur.execute("SELECT srv_name FROM sadm.server WHERE srv_name = %s", [wkey])
        wconn.commit()
    except psycopg2.ProgrammingError as e:
        print "Error: Error trying to locate server %s in server table" % (wkey)
        print "%s" % e
    return wcur.fetchone() is not None



#===================================================================================================
#                      INSERT ROW INTO THE SERVER TABLE FROM THE WROW DICTIONNARY
#===================================================================================================
#
def insert_row(wconn, wcur, wrow):
    """INSERT ROW INTO THE SERVER TABLE FROM THE WROW DICTIONNARY"""
    sadm.writelog("Insert information of server %s in server table" % (wrow['srv_name']))
    wdate = datetime.datetime.now()                                     # Get current Date
    wrow['srv_creation_date'] = wdate.date()                            # Set Last Update Date
    try:
        wcur.execute("insert into sadm.server \
        (srv_name, srv_domain, srv_desc, \
         srv_notes, srv_ostype, \
         srv_osname, srv_oscodename, srv_osversion, \
         srv_osver_major, srv_kernel_version, srv_kernel_bitmode, \
         srv_hwd_bitmode, srv_active, srv_creation_date, \
         srv_model, srv_serial, srv_vm, \
         srv_memory, srv_nb_cpu, srv_cpu_speed, \
         srv_nb_socket, srv_core_per_socket, srv_thread_per_core, \
         srv_ip, srv_ips_info, srv_disks_info, \
         srv_vgs_info, srv_sporadic, srv_monitor, \
         srv_last_edit_date, srv_tag, srv_cat, srv_group, \
         srv_backup,  srv_maintenance, srv_update_month, \
         srv_update_dom, srv_update_dow, srv_update_hour \
         srv_update_minute, srv_update_reboot, srv_update_status \
         srv_update_auto, srv_update_date, srv_last_daily_update ) \
        values (%s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s,%s,           \
                %s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s,%s, %s,%s )",                               \
        (wrow['srv_name'], wrow['srv_domain'], wrow['srv_desc'], \
         wrow['srv_notes'], wrow['srv_ostype'], \
         wrow['srv_osname'], wrow['srv_oscodename'], wrow['srv_osversion'], \
         wrow['srv_osver_major'], wrow['srv_kernel_version'], wrow['srv_kernel_bitmode'], \
         wrow['srv_hwd_bitmode'], wrow['srv_active'], wrow['srv_creation_date'], \
         wrow['srv_model'], wrow['srv_serial'], wrow['srv_vm'], \
         wrow['srv_memory'], wrow['srv_nb_cpu'], wrow['srv_cpu_speed'],\
         wrow['srv_nb_socket'], wrow['srv_core_per_socket'], wrow['srv_thread_per_core'], \
         wrow['srv_ip'], wrow['srv_ips_info'], wrow['srv_disks_info'], \
         wrow['srv_vgs_info'], wrow['srv_sporadic'], wrow['srv_monitor'], \
         wrow['srv_last_edit_date'], wrow['srv_tag'], wrow['srv_cat'], wrow['srv_group'], \
         wrow['srv_backup'], wrow['srv_maintenance'], wrow['srv_update_month'], \
         wrow['srv_update_dom'], wrow['srv_update_dow'], wrow['srv_update_hour'], \
         wrow['srv_update_minute'], wrow['srv_update_reboot'], wrow['srv_update_status'], \
         wrow['srv_update_auto'], wrow['srv_update_date'], wrow['srv_last_daily_update'],\
        ))
    except(psycopg2.IntegrityError, psycopg2.ProgrammingError, KeyError, psycopg2.DataError), e:
        sadm.writelog("ERROR: Inserting server %s row into server table" % wrow['srv_name'])
        print "%s" % e
        wconn.rollback()
        print_server_row(wrow)
        return 1
    wconn.commit()
    sadm.writelog("Total number of rows inserted : %s " % (wcur.rowcount))
    sadm.writelog("Insertion of server %s Succeeded" % (wrow['srv_name']))
    return 0






#===================================================================================================
#                   UPDATE ROW INTO FROM THE WROW DICTIONNARY THE SERVER TABLE
#===================================================================================================
#
def update_row(wconn, wcur, wrow):
    """UPDATE ROW INTO FROM THE WROW DICTIONNARY THE SERVER TABLE"""

    sadm.writelog("Update information of server %s in server table" % (wrow['srv_name']))
    wdate = datetime.datetime.now()                                     # Get current Date
    wrow['srv_last_daily_update'] = wdate.strftime('%Y-%m-%d %H:%M:%S') # Last Daily update date
    #sadm.writelog("Last Daily Update TimeStamp is %s" % (wrow['srv_last_daily_update']))
    #sadm.writelog("IPS Info is %s" % (wrow['srv_ips_info']))

    try:
        sql = """ update sadm.server set 
                srv_ostype = %s, srv_osname = %s,
                srv_oscodename  = %s, srv_domain = %s, 
                srv_memory = %s, srv_last_daily_update = %s,
                srv_osversion = %s, srv_osver_major = %s, 
                srv_ip = %s, srv_kernel_version = %s, srv_kernel_bitmode = %s,
                srv_model = %s, srv_serial = %s,
                srv_hwd_bitmode = %s, srv_nb_cpu = %s, 
                srv_cpu_speed = %s, srv_nb_socket = %s,
                srv_core_per_socket = %s, srv_thread_per_core = %s, 
                srv_ips_info = %s, srv_disks_info = %s, srv_vgs_info = %s 
                where srv_name = %s 
              """

        wcur.execute(sql, (wrow['srv_ostype'], wrow['srv_osname'], 
             wrow['srv_oscodename'], wrow['srv_domain'], 
             wrow['srv_memory'], wrow['srv_last_daily_update'],
             wrow['srv_osversion'], wrow['srv_osver_major'], 
             wrow['srv_ip'], wrow['srv_kernel_version'], wrow['srv_kernel_bitmode'], 
             wrow['srv_model'], wrow['srv_serial'],  
             wrow['srv_hwd_bitmode'], wrow['srv_nb_cpu'], 
             wrow['srv_cpu_speed'], wrow['srv_nb_socket'], 
             wrow['srv_core_per_socket'], wrow['srv_thread_per_core'], 
             wrow['srv_ips_info'], wrow['srv_disks_info'], wrow['srv_vgs_info'], 
             wrow['srv_name']))

    except(psycopg2.IntegrityError, psycopg2.ProgrammingError, KeyError, psycopg2.DataError), e:
        sadm.writelog("ERROR: Updating server %s row into server table" % (wrow['srv_name']))
        sadm.writelog("%s" % e)
        wconn.rollback()
        print_server_row(wrow)
        return 1

    wconn.commit()
    sadm.writelog("Total number of rows updated : %s " % (wcur.rowcount))
    sadm.writelog("Update of server %s Succeeded" % (wrow['srv_name']))
    return 0

#===================================================================================================
#                          Process All Active Servers selected by the SQL
#===================================================================================================

def process_active_servers(wconn, wcur, wcolnames):
    """Process All Active Servers selected by the SQL"""
    #global sadm.www_dat_dir
    total_error = 0

    sadm.writelog(" ")
    sadm.writelog(" ")
    sadm.writelog(sadm.dash)
    sadm.writelog("PROCESSING ACTIVE SERVERS")

    # SELECT ALL ACTIVE SERVERS
    try:
        wcur.execute(" \
          SELECT srv_name,srv_ostype,srv_domain,srv_active \
            from sadm.server \
            where srv_active = True order by srv_name; \
        ")
        rows = wcur.fetchall()
        wconn.commit()
    except psycopg2.Error as e:
        sadm.writelog("Error Reading Server Table")
        sadm.writelog(e.pgerror)
        sadm.writelog(e.diag.message_det)
        sys.exit(1)

    # PROCESS EACH ACTIVE SERVERS NOW
    lineno = 0
    for row in rows:
        wname, wos, wdomain, wactive = row
        sadm.writelog("")                                               # Display Blank Line
        sadm.writelog(sadm.dash)
        lineno += 1
        if sadm.debug > 4: sadm.writelog("%02d %s" % (lineno, row))
        sadm.writelog("Processing (%d) Server %s [%s]" % (lineno, wname+"."+wdomain, wos))
        sysfile = sadm.www_dat_dir + "/" + wname + "/dr/" + wname + "_sysinfo.txt"
        sadm.writelog("Processing filename : " + sysfile)               # Display Sysinfo File

        # OPEN SYSINFO FILE FOR CURRENT SERVER
        if sadm.debug > 4: sadm.writelog("Opening %s" % (sysfile))      # Opened Sysinfo file Msg
        try:
            FH_SYSINFO = open(sysfile, 'r')                             # Open Sysinfo File
        except IOError as e:                                            # If Can't open file
            sadm.writelog("Error opening file %s \r\n" % sysfile)       # Print FileName
            sadm.writelog("Error Number : {0}\r\n.format(e.errno)")     # Print Error Number
            sadm.writelog ("error({0}):{1}".format(e.errno, e.strerror))
            sadm.writelog (repr(e))           
            sadm.writelog("Error Text   : {0}\r\n.format(e.strerror)")  # Print Error Message
            return 1                                                    # Return Error to Caller
        if sadm.debug > 4: sadm.writelog("File %s opened" % sysfile)    # Opened Sysinfo file Msg

        # PROCESS SYSINFO OF CURRENT SERVER
        if sadm.debug > 4: sadm.writelog("Reading %s" % sysfile)        # Reading Sysinfo file Msg
        srow = init_row_dictionnary(wcolnames)                          # Set Default Value of row
        for cfg_line in FH_SYSINFO:                                     # Loop until all lines parse
            wline = cfg_line.strip()                                    # Strip CR/LF/Trailing space
            if '#' in wline or len(wline) == 0:                         # If comment or blank line
                continue                                                # Go read the next line
            if sadm.debug > 4: print "  Parsing Line : %s" % wline      # Debug Info - Parsing Line
            split_line = wline.split('=')                               # Split based on equal sign
            CFG_NAME = split_line[0].strip()                            # Param Name Uppercase Trim
            try:
                CFG_VALUE = str(split_line[1]).strip()                  # Param Value Trimmed
                CFG_NAME = str.upper(CFG_NAME)                          # Make Name in Uppercase
            except LookupError:
                sadm.writelog(" ")                                      # Print Blank Line
                sadm.writelog("ERROR GETTING VALUE ON LINE %s" % wline) # Print IndexError Line
                total_error = total_error + 1                           # Add 1 To Total Error
                NO_ERROR_OCCUR = False                                  # Now No "Error" is False
                sadm.writelog("CONTINUE WITH THE NEXT SERVER")          # Advise user we continue
                continue                                                # Go Read Next Line

            # Save Information Found in SysInfo file into our row dictionnary (server_row)
            try:
                NO_ERROR_OCCUR = True                                   # Assume no error will Occur
                if "SADM_HOSTNAME"          in CFG_NAME: srow['srv_name'] = CFG_VALUE.lower()
                if "SADM_OS_TYPE"           in CFG_NAME: srow['srv_ostype'] = CFG_VALUE.lower()
                if "SADM_DOMAINNAME"        in CFG_NAME: srow['srv_domain'] = CFG_VALUE.lower()
                if "SADM_HOST_IP"           in CFG_NAME: srow['srv_ip'] = CFG_VALUE
                if "SADM_OS_VERSION"        in CFG_NAME: srow['srv_osversion'] = CFG_VALUE
                if "SADM_OS_MAJOR_VERSION"  in CFG_NAME: srow['srv_osver_major'] = CFG_VALUE
                if "SADM_OS_NAME"           in CFG_NAME: srow['srv_osname'] = CFG_VALUE.lower()
                if "SADM_OS_CODE_NAME"      in CFG_NAME: srow['srv_oscodename'] = CFG_VALUE
                if "SADM_KERNEL_VERSION"    in CFG_NAME: srow['srv_kernel_version'] = CFG_VALUE
                if "SADM_SERVER_MODEL"      in CFG_NAME: srow['srv_model'] = CFG_VALUE
                if "SADM_SERVER_SERIAL"     in CFG_NAME: srow['srv_serial'] = CFG_VALUE
                if "SADM_SERVER_IPS"        in CFG_NAME: srow['srv_ips_info'] = CFG_VALUE
                #if "SADM_SERVER_IPS"        in CFG_NAME: 
                #    sadm.writelog("IPS INFO = %s" % srow['srv_ips_info'])
                #    sadm.writelog("CFG_VALUE = %s" % CFG_VALUE)

                # PHYSICAL OR VIRTUAL SERVER
                if "SADM_SERVER_TYPE" in CFG_NAME:
                    if CFG_VALUE == 'P':
                        srow['srv_vm'] = False
                    else:
                        srow['srv_vm'] = True

                # RUNNING KERNEL IS 32 OR 64 BITS (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_KERNEL_BITMODE" in CFG_NAME: srow['srv_kernel_bitmode'] = int(CFG_VALUE)
                except ValueError as e:
                    sadm.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    srow['srv_kernel_bitmode'] = int(0)                 # Set Kernel Bits to Zero
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # MEMORY AMOUNT IN SERVER IN MB (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_MEMORY" in CFG_NAME: srow['srv_memory'] = int(CFG_VALUE)
                except ValueError as e:
                    sadm.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    srow['srv_memory'] = int(0)                         # Set Memory Amount to 0
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # HARDWARE CAPABILITY RUN 32 OR 64 BITS (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_HARDWARE_BITMODE" in CFG_NAME:
                        srow['srv_hwd_bitmode'] = int(CFG_VALUE)
                except ValueError as e:
                    sadm.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    srow['srv_hwd_bitmode'] = int(0)                    # Set Hard Bits to Zero
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # NUMBER OF CPU ON THE SERVER  (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_NB_CPU"  in CFG_NAME: srow['srv_nb_cpu'] = int(CFG_VALUE)
                except ValueError as e:
                    sadm.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    srow['srv_nb_cpu'] = int(0)                         # Set Nb Cpu to 0
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # CPU SPEED  (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_CPU_SPEED" in CFG_NAME: srow['srv_cpu_speed'] = int(CFG_VALUE)
                except ValueError as e:
                    sadm.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    srow['srv_cpu_speed'] = int(0)                      # Set CPU Speed to 0
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # NUMBER OF SOCKET  (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_NB_SOCKET" in CFG_NAME: srow['srv_nb_socket'] = int(CFG_VALUE)
                except:
                    sadm.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    srow['srv_nb_socket'] = int(0)                      # Set Nb Socket to Zero
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # NUMBER OF CORE PER SOCKET (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_CORE_PER_SOCKET"  in CFG_NAME:
                        srow['srv_core_per_socket'] = int(CFG_VALUE)
                except:
                    sadm.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    srow['srv_core_per_socket'] = int(0)                # Set Nb Core/Socket to Zero
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # NUMBER OF THREAD PER CORE (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_THREAD_PER_CORE"  in CFG_NAME:
                        srow['srv_thread_per_core'] = int(CFG_VALUE)
                except:
                    srow['srv_thread_per_core'] = int(0)                # Set Nb Threads to zero
                    sadm.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # All Disks defined on the servers with Dev, Size
                try:
                    if "SADM_SERVER_DISKS" in CFG_NAME: srow['srv_disks_info'] = CFG_VALUE
                except:
                    sadm.writelog("ERROR: Converting %s and value is (%s)" % (CFG_NAME, CFG_VALUE))
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False


                # All VGs Information
                try:
                    if "SADM_SERVER_VG"      in CFG_NAME: srow['srv_vgs_info'] = CFG_VALUE
                except:
                    sadm.writelog("ERROR: Converting %s and value is (%s)" % (CFG_NAME, CFG_VALUE))
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False


            except IndexError as e:
                sadm.writelog("ERROR: Converting %s and value is (%s)" % (CFG_NAME, CFG_VALUE))
                sadm.writelog("%s" % e)
                total_error = total_error + 1                           # Add 1 To Total Error
                NO_ERROR_OCCUR = False                                  # Now No "Error" is False

        if sadm.debug > 4: sadm.writelog("Closing %s" % sysfile)        # Closing Sysinfo file Msg
        FH_SYSINFO.close()                                              # Close the Sysinfo File

        # Check if the server we are processing in already in the server table of SADMIN Database
        if NO_ERROR_OCCUR:                                              # If No Error Moving Fld
            found_key = read_row(wconn, wcur, srow['srv_name'])         # Try To Read Server from DB
            if found_key:                                               # If Server Found in DB
                RC = update_row(wconn, wcur, srow)                      # Go Update Row
                total_error = total_error + RC                          # RC=0=Success RC=1=Error
            else:                                                       # If Server was not found
                RC = insert_row(wconn, wcur, srow)                        # Go Insert new row
                total_error = total_error + RC                          # RC=0=Success RC=1=Error
        sadm.writelog(" ")
        sadm.writelog("Total Error Count at %d now" % (total_error))    # Total Error after each Srv

    return total_error










#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    sadm.start()                                                        # Open Log, Create Dir ...

    # Test if script is run by root (Optional Code)
    if os.geteuid() != 0:                                               # UID of user is not zero
        sadm.writelog("This script must be run by the 'root' user")     # Advise User Message / Log
        sadm.writelog("Process aborted")                                # Process Aborted Msg
        sadm.stop(1)                                                    # Close and Trim Log/Email
        sys.exit(1)                                                     # Exit with Error Code

    # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    if socket.getfqdn() != sadm.cfg_server:                             # Only run on SADMIN
        sadm.writelog("Script can only be run on SADMIN server (%s)", (sadm.cfg_server))
        sadm.writelog("Process aborted")                                # Abort advise message
        sadm.stop(1)                                                    # Close and Trim Log
        sys.exit(1)                                                     # Exit To O/S

    if sadm.debug > 4: sadm.display_env()                               # Display Env. Variables
    (conn,cur) = sadm.open_sadmin_database()                            # Open Connection 2 Database
    colnames = get_columns_name(conn,cur, "sadm.server")                # Get Server Table Col Name
    sadm.exit_code=process_active_servers(conn, cur, colnames)          # Process Active Servers
    sadm.close_sadmin_database(conn, cur)                               # Close Database Connection
    sadm.stop(sadm.exit_code)                                           # Close log & trim
    sys.exit(sadm.exit_code)                                            # Exit with Error Code

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
