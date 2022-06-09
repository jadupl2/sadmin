#!/usr/bin/env python3
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_database_update.py
#   Synopsis:   Read Hardware/Software/Performance data collected from servers & update database
#===================================================================================================
# Description
#
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#@2021_05_14 Update: v3.11 Get DB result as a dict. (connect cursorclass=pymysql.cursors.DictCursor)
#@2021_05_30 Fix: v3.12 Enlarge column 'srv_model' & 'srv_kernel_version' column wasn't big enough
#@2021_06_01 Update: v3.13 Bug fixes and Command line option -v, -h and -d are now functional. 
#@2021_06_10 Update: v3.14 Enlarge column 'srv_uptime' from 20 to 25 Char 
#@2021_06_11 Update: v3.15 Add 'srv_boot_date' that contain last boot date & Fix error message.
#@2021_06_17 Fix: v3.16 Fix Duplicate column name 'srv_boot_date'
#@2022_03_28 Update: v3.17 Give a warning instead of error if input file is not created yet.
# 
# ==================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,argparse,pdb,socket,datetime,glob,pymysql,fnmatch 
#    SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Root Dir. Name
#    sys.path.insert(0,os.path.join(SADM,'lib'))                     # Add SADMIN to sys.path
    import sadmlib_std as sadm                                      # Import SADMIN Python Library
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                    # Activate Python Debugging



#===================================================================================================
#                      Global Variables Definition use on a per script basis
#===================================================================================================
#
wdict           = {}                                                    # Dict for Server Columns




# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.49 
# Setup for Global Variables and import SADMIN Python module
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------
def setup_sadmin():

    # Load SADMIN Standard Python Library Module ($SADMIN/lib/sadmlib_std.py).
    try :
        SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Root Dir.
        sys.path.insert(0,os.path.join(SADM,'lib'))                     # Add SADMIN to sys.path
        import sadmlib_std as sadm                                      # Import SADMIN Python Libr.
    except ImportError as e:                                            # If Error importing SADMIN 
        print ("Error Importing SADMIN Module: %s " % e)                # Advise User of Error
        sys.exit(1)                                                     # Go Back to O/S with Error
    
    # Create [S]ADMIN [T]ools instance (Setup Dir.,Var.)
    st = sadm.sadmtools()                       

    # You can use variable below BUT DON'T CHANGE THEM - They are used by SADMIN Module.
    st.pn               = os.path.basename(sys.argv[0])                 # Script name with extension
    st.inst             = os.path.basename(sys.argv[0]).split('.')[0]   # Script name without Ext
    st.tpid             = str(os.getpid())                              # Get Current Process ID.
    st.exit_code        = 0                                             # Script Exit Code (Use it)
    st.hostname         = socket.gethostname().split('.')[0]            # Get current hostname

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.    
    st.ver              = "3.17"                # Current Script Version
    st.pdesc            = "SADMIN Daily database update v%s" % st.ver
    st.log_type         = 'B'                   # Output goes to [S]creen to [L]ogFile or [B]oth
    st.log_append       = False                 # Append Existing Log(True) or Create New One(False)
    st.log_header       = True                  # Show/Generate Header in script log (.log)
    st.log_footer       = True                  # Show/Generate Footer in script log (.log)
    st.multiple_exec    = "N"                   # Allow running multiple copy at same time ?
    st.use_rch          = True                  # Generate entry in Result Code History (.rch) 
    st.debug            = 0                     # Increase Verbose from 0 to 9 
    st.usedb            = True                  # Open/Use Database(True) or Don't Need DB(False)
    st.dbsilent         = False                 # When DB Error, False=ShowErrMsg and True=NoErrMsg 
                                                # But Error Code always returned (0=ok else error)

    # Override Default define in $SADMIN/cfg/sadmin.cfg
    #st.cfg_alert_type   = 1                    # 0=NoMail 1=OnlyOnError 2=OnlyOnSuccess 3=Always
    #st.cfg_alert_group  = "default"            # Valid Alert Group are defined in alert_group.cfg
    #st.cfg_mail_addr    = ""                   # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name     = ""                   # This Override Company Name specify in sadmin.cfg
    #st.cfg_max_logline  = 500                  # When Script End Trim log file to 500 Lines
    #st.cfg_max_rchline  = 35                   # When Script End Trim rch file to 35 Lines
    #st.ssh_cmd = "%s -qnp %s " % (st.ssh,st.cfg_ssh_port) # SSH Command to Access Server 

    # Start SADMIN Tools - Initialize 
    st.start()                                  # Init. SADMIN Env. (Create dir.,Log,RCH, Open DB..)
    return(st)                                  # Return Instance Object To Caller



#===================================================================================================
#                   UPDATE ROW INTO FROM THE WROW DICTIONNARY THE SERVER TABLE
#===================================================================================================
#
def update_row(st,wconn, wcur, wdict):
    st.writelog ("Updating %s.%s data in Database" % (wdict['srv_name'],wdict['srv_domain']))


    # Enlarge col 'srv_kernel_version' to 40char. for '2.6.32-754.35.1.el6.centos.plus.i686'
    # Enlarge column 'srv_model' to 30 Characters to accommodate 'Precision WorkStation T3500'
    # Enlarge column 'srv_uptime' from 20 to 25 Char to accommodate largest runtime string
    # Add Last Boot Date Column 
    if st.get_release() < "1.3.4" :                                         # Change made in 1.3.3
        sql="ALTER TABLE server MODIFY COLUMN srv_kernel_version VARCHAR(40);"
        try:
            wcur.execute(sql);                                              # Execute the Select SQL
        except(pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as error:
            enum, emsg = error.args                                         # Get Error No. & Msg
            print (">>>>>>>>>>>>>",enum,emsg)                               # Print Error No. & Msg
            return (1)                                                      # Return Error to caller
        #
        sql="ALTER TABLE server MODIFY COLUMN srv_model VARCHAR(30);"
        try:
            wcur.execute(sql);                                              # Execute the Select SQL
        except(pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as error:
            enum, emsg = error.args                                         # Get Error No. & Msg
            print (">>>>>>>>>>>>>",enum,emsg)                               # Print Error No. & Msg
            return (1)                                                      # Return Error to caller
        #
        sql="ALTER TABLE server MODIFY COLUMN srv_uptime VARCHAR(25);"      # Modify from 20 to 25Ch
        try:
            wcur.execute(sql);                                              # Execute the Select SQL
        except(pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as error:
            enum, emsg = error.args                                         # Get Error No. & Msg
            print (">>>>>>>>>>>>>",enum,emsg)                               # Print Error No. & Msg
            return (1)                                                      # Return Error to caller
        #
        sql="ALTER TABLE server ADD COLUMN srv_boot_date datetime AFTER srv_rear_ver;"
        try:
            wcur.execute(sql);                                              # Execute the Select SQL
        except(pymysql.err.OperationalError,pymysql.err.InternalError,
            pymysql.err.IntegrityError,pymysql.err.DataError) as error:
            pass                                                            # Skip duplicate error
            #enum, emsg = error.args                                         # Get Error No. & Msg
            #print (">>>>>>>>>>>>>",enum,emsg)                               # Print Error No. & Msg
            #return (1)                                                      # Return Error to caller

    # Update Server Row With Info collected from the sysinfo.txt file
    try:
        sql =   "UPDATE server SET \
                srv_ostype='%s',            srv_osname='%s', \
                srv_vm='%d', \
                srv_ostype='%s',            srv_oscodename='%s', \
                srv_osversion='%s',         srv_osver_major='%s', \
                srv_kernel_version='%s',    srv_kernel_bitmode='%d', \
                srv_hwd_bitmode='%s',       srv_model='%s', \
                srv_serial='%s',            srv_memory='%d', \
                srv_nb_cpu='%d',            srv_cpu_speed='%d', \
                srv_nb_socket='%d',         srv_core_per_socket='%d', \
                srv_thread_per_core='%d',   srv_ip='%s', \
                srv_ips_info='%s',          srv_disks_info='%s', \
                srv_date_osupdate='%s',     srv_update_status='%s', \
                srv_sadmin_dir='%s',        srv_arch='%s', \
                srv_vgs_info='%s',          srv_date_update='%s', \
                srv_rear_ver='%s'  \
                where srv_name='%s' " %  \
                (wdict['srv_ostype'],           wdict['srv_osname'], \
                wdict['srv_vm'], \
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
                wdict['srv_rear_ver'], \
                wdict['srv_name'] )
    except (TypeError, ValueError, IndexError) as error:                # Mismatch Between Num & Str
        #enum, emsg = error.args                                         # Get Error No. & Message
        enum=1
        emsg=error                                                     # Get Error Message
        st.writelog(">>>>>>>>>>>>> (%s) %s " % (enum,error))            # Print Error No. & Message
        st.writelog("sql=%s" % (sql))
        return(1)                                                      # return (1) to indicate Err

    # Execute the SQL Update Statement
    try:
        if st.debug > 4: st.writelog("sql=%s" % (sql))
        wcur.execute(sql)                                               # Update Server Data
        wconn.commit()                                                  # Commit the transaction
        st.writelog("[OK] %s update Succeeded" % (wdict['srv_name']))   # Advise User Update is OK
        return (0)                                                      # return (0) Insert Worked


    except pymysql.DataError as e:
        print("DataError")
        print(e)
    except pymysql.InternalError as e:
        print("InternalError")
        print(e)
    except pymysql.IntegrityError as e:
        print("IntegrityError")
        print(e)
    except pymysql.OperationalError as e:
        print("OperationalError")
        print(e)
    except pymysql.NotSupportedError as e:
        print("NotSupportedError")
        print(e)
    except pymysql.ProgrammingError as e:
        print("ProgrammingError")
        print(e)
    except :
        print("Unknown error occurred")

    #except (pymysql.err.InternalError, pymysql.err.IntegrityError) as error:
    #    enum, emsg = error.args                                         # Get Error No. & Message
    #    st.writelog("[ERROR] (%s) %s " % (enum,error))                  # Print Error No. & Message
    #    if st.debug > 4: st.writelog("sql=%s" % (sql))
    #    wconn.rollback()                                                # RollBack Transaction
    #    return (1)                                                      # return (1) to indicate Err
    #except Exception as error:
    #    enum, emsg = error.args                                         # Get Error No. & Message
    #    st.writelog("[ERROR] (%s) %s " % (enum,error))                  # Print Error No. & Message
    #    if st.debug > 4: st.writelog("sql=%s" % (sql))
    #    wconn.rollback()                                                # RollBack Transaction
    #    return (1)                                                      # return (1) to indicate Err
    return(0)                                                           # Return 0 = update went OK



#===================================================================================================
#                        Process all Actives Servers in the Database
#===================================================================================================
#
def process_servers(wconn,wcur,st):
    st.writelog ("Processing all actives systems")

    # Fetch all actives Systems
    sql  = "SELECT srv_name, srv_desc, srv_domain, srv_osname  "
    sql += " FROM server WHERE srv_active = %s " % ('True')
    sql += " order by srv_name;"
    try :
        wcur.execute(sql)
        rows = wcur.fetchall()
    except(pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as error:
        self.enum, self.emsg = error.args                               # Get Error No. & Message
        print (">>>>>>>>>>>>>",self.enum,self.emsg)                     # Print Error No. & Message
        return (1)
    except:
        print ("Error: unable to fetch data")
        return (1)
    
    # Under debug show all actives systems that was fetch
    if st.debug > 4:
        for row in rows:
            wname = row['srv_name']
            wdesc = row['srv_desc'] 
            wdomain = row['srv_domain']
            wos = row['srv_osname']
            print ("wname = %s,wdesc = %s,wdomain = %s,wos = %s" % (wname, wdesc, wdomain, wos ))

    # Process each server
    lineno = 1
    total_error = 0
    for row in rows:
        if st.debug > 4: st.writelog ("%02d %s" % (lineno, row))
        wname = row['srv_name']
        wdesc = row['srv_desc'] 
        wdomain = row['srv_domain']
        wos = row['srv_osname']
        st.writelog("")                                                 # Insert Blank Line
        st.writelog (('-' * 40))                                        # Insert Dash Line
        st.writelog ("Processing (%d) %-15s - os:%s" % (lineno,wname+"."+wdomain,wos))

        # Construct the name of the sysinfo file for that system
        sysfile = st.www_dat_dir + "/" + wname + "/dr/" + wname + "_sysinfo.txt"
        st.writelog("Reading sysinfo file : " + sysfile)                # Display Sysinfo File

        # Open sysinfo.txt file for the current server ---------------------------------------------
        if st.debug > 4: st.writelog("Opening %s" % (sysfile))          # Opened Sysinfo file Msg
        try:
            FH = open(sysfile, 'r')                                     # Open Sysinfo File
        except FileNotFoundError as e:
            st.writelog("[WARNING] Sysinfo file could not be found %s" % (sysfile))
            #total_error = total_error + 1                           # Add 1 To Total Error
            continue
        except IOError as e:                                            # If Can't open file
            st.writelog ("Error opening file %s \r\n" % sysfile)        # Print FileName
            st.writelog ("Error Number : {0}\r\n.format(e.errno)")      # Print Error Number
            st.writelog ("error({0}):{1}".format(e.errno, e.strerror))
            st.writelog (repr(e))
            st.writelog( "Error Text   : {0}\r\n.format(e.strerror)")   # Print Error Message
            return 1                                                    # Return Error to Caller
        if st.debug > 4: st.writelog ("File %s opened" % sysfile)       # Opened Sysinfo file Msg

        # Process the content of the sysinfo.txt file ----------------------------------------------
        if st.debug > 4: st.writelog("Reading %s" % sysfile)            # Reading Sysinfo file Msg
        wdict = {}                                                      # Create an empty Dictionary
        wdict['srv_date_update']   = "None"                             # Default Value Upd.Date
        wdict['srv_sadmin_dir']    = "/opt/sadmin"                      # Set Def. SADMIN Root Dir
        wdict['srv_date_osupdate'] = "0000-00-00 00:00:00"              # Def. O/S Update Date
        wdict['srv_update_status'] = "U"                                # Def. O/S Update Status
        wdict['srv_arch'] = ""                                          # Def. Server Architecture
        wdict['srv_rear_ver'] = "N/A"                                   # Default for Rear Version
        for cfg_line in FH:                                             # Loop until all lines parse
            wline = cfg_line.strip()                                    # Strip CR/LF/Trailing space
            if '#' in wline or len(wline) == 0:                         # If comment or blank line
                continue                                                # Go read the next line
            if st.debug > 4: print("  Parsing Line : %s" % (wline))     # Debug Info - Parsing Line
            split_line = wline.split('=')                               # Split based on equal sign
            CFG_NAME = split_line[0].strip()                            # Param Name Uppercase Trim
            try:
                CFG_VALUE = str(split_line[1]).strip()                  # Param Value Trimmed
                CFG_NAME = str.upper(CFG_NAME)                          # Make Name in Uppercase
            except LookupError:
                st.writelog(" ")                                        # Print Blank Line
                st.writelog("ERROR GETTING VALUE ON LINE %s" % wline)   # Print IndexError Line
                total_error = total_error + 1                           # Add 1 To Total Error
                NO_ERROR_OCCUR = False                                  # Now No "Error" is False
                st.writelog("CONTINUE WITH THE NEXT SERVER")            # Advise user we continue
                continue                                                # Go Read Next Line

            # Save Information Found in SysInfo file into our row dictionnary (server_row)----------
            try:
                NO_ERROR_OCCUR = True                                   # Assume no error will Occur
                if "SADM_HOSTNAME"          in CFG_NAME: wdict['srv_name']      = CFG_VALUE.lower()
                if "SADM_OS_TYPE"           in CFG_NAME: wdict['srv_ostype']    = CFG_VALUE.lower()
                if "SADM_DOMAINNAME"        in CFG_NAME: wdict['srv_domain']    = CFG_VALUE.lower()
                if "SADM_HOST_IP"           in CFG_NAME: wdict['srv_ip']                = CFG_VALUE
                if "SADM_OS_VERSION"        in CFG_NAME: wdict['srv_osversion']         = CFG_VALUE
                if "SADM_OS_MAJOR_VERSION"  in CFG_NAME: wdict['srv_osver_major']       = CFG_VALUE
                if "SADM_OS_NAME"           in CFG_NAME: wdict['srv_osname']    = CFG_VALUE.lower()
                if "SADM_OS_CODE_NAME"      in CFG_NAME: wdict['srv_oscodename']        = CFG_VALUE
                if "SADM_KERNEL_VERSION"    in CFG_NAME: wdict['srv_kernel_version']    = CFG_VALUE
                if "SADM_SERVER_MODEL"      in CFG_NAME: wdict['srv_model']             = CFG_VALUE
                if "SADM_SERVER_SERIAL"     in CFG_NAME: wdict['srv_serial']            = CFG_VALUE
                if "SADM_SERVER_IPS"        in CFG_NAME: wdict['srv_ips_info']          = CFG_VALUE
                if "SADM_UPDATE_DATE"       in CFG_NAME: wdict['srv_date_update']       = CFG_VALUE
                if "SADM_OSUPDATE_DATE"     in CFG_NAME: wdict['srv_date_osupdate']     = CFG_VALUE
                if "SADM_OSUPDATE_STATUS"   in CFG_NAME: wdict['srv_update_status']     = CFG_VALUE
                if "SADM_ROOT_DIRECTORY"    in CFG_NAME: wdict['srv_sadmin_dir']        = CFG_VALUE
                if "SADM_SERVER_ARCH"       in CFG_NAME: wdict['srv_arch']              = CFG_VALUE
                if "SADM_REAR_VERSION"      in CFG_NAME: wdict['srv_rear_ver']          = CFG_VALUE
                if wdict['srv_date_osupdate'] == '' :
                   wdict['srv_date_osupdate'] = "0000-00-00 00:00:00"   # Def. O/S Update Date

                # PHYSICAL OR VIRTUAL SERVER
                if "SADM_SERVER_TYPE" in CFG_NAME:
                    if CFG_VALUE.upper()  == 'P':
                        wdict['srv_vm'] = 0
                    else:
                        wdict['srv_vm'] = 1

                 # RUNNING KERNEL IS 32 OR 64 BITS                
                try:
                    if "SADM_KERNEL_BITMODE" in CFG_NAME: wdict['srv_kernel_bitmode'] = int(CFG_VALUE)
                except ValueError as e:
                    st.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    wdict['srv_kernel_bitmode'] = int(0)                # Set Kernel Bits to Zero
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # MEMORY AMOUNT IN SERVER IN MB (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_MEMORY" in CFG_NAME: wdict['srv_memory'] = int(CFG_VALUE)
                except ValueError as e:
                    st.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    wdict['srv_memory'] = int(0)                        # Set Memory Amount to 0
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # HARDWARE CAPABILITY RUN 32 OR 64 BITS (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_HARDWARE_BITMODE" in CFG_NAME:
                        wdict['srv_hwd_bitmode'] = int(CFG_VALUE)
                except ValueError as e:
                    st.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    wdict['srv_hwd_bitmode'] = int(0)                   # Set Hard Bits to Zero
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # NUMBER OF CPU ON THE SERVER  (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_NB_CPU"  in CFG_NAME: wdict['srv_nb_cpu'] = int(CFG_VALUE)
                except ValueError as e:
                    st.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    wdict['srv_nb_cpu'] = int(0)                        # Set Nb Cpu to 0
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # CPU SPEED  (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_CPU_SPEED" in CFG_NAME: wdict['srv_cpu_speed'] = int(CFG_VALUE)
                except ValueError as e:
                    st.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    wdict['srv_cpu_speed'] = int(0)                     # Set CPU Speed to 0
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # NUMBER OF SOCKET  (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_NB_SOCKET" in CFG_NAME: wdict['srv_nb_socket'] = int(CFG_VALUE)
                except:
                    st.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    wdict['srv_nb_socket'] = int(0)                     # Set Nb Socket to Zero
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # NUMBER OF CORE PER SOCKET (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_CORE_PER_SOCKET"  in CFG_NAME:
                        wdict['srv_core_per_socket'] = int(CFG_VALUE)
                except:
                    st.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    wdict['srv_core_per_socket'] = int(0)               # Set Nb Core/Socket to Zero
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # NUMBER OF THREAD PER CORE (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
                try:
                    if "SADM_SERVER_THREAD_PER_CORE"  in CFG_NAME:
                        wdict['srv_thread_per_core'] = int(CFG_VALUE)
                except:
                    wdict['srv_thread_per_core'] = int(0)                # Set Nb Threads to zero
                    st.writelog("ERROR: Converting %s to an integer (%s)" % (CFG_NAME, CFG_VALUE))
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # All Disks defined on the servers with Dev, Size
                try:
                    if "SADM_SERVER_DISKS" in CFG_NAME: wdict['srv_disks_info'] = CFG_VALUE
                except:
                    st.writelog("ERROR: Converting %s and value is (%s)" % (CFG_NAME, CFG_VALUE))
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

                # All VGs Information
                try:
                    if "SADM_SERVER_VG" in CFG_NAME: wdict['srv_vgs_info'] = CFG_VALUE
                except:
                    st.writelog("ERROR: Converting %s and value is (%s)" % (CFG_NAME, CFG_VALUE))
                    total_error = total_error + 1                       # Add 1 To Total Error
                    NO_ERROR_OCCUR = False                              # Now No "Error" is False

            except IndexError as e:
                st.writelog("ERROR: Converting %s and value is (%s)" % (CFG_NAME, CFG_VALUE))
                st.writelog("%s" % e)
                total_error = total_error + 1                           # Add 1 To Total Error
                NO_ERROR_OCCUR = False                                  # Now No "Error" is False
        if st.debug > 4: st.writelog("Closing %s" % sysfile)            # Closing Sysinfo file Msg
        FH.close()                                                      # Close the Sysinfo File
        if NO_ERROR_OCCUR:                                              # If No Error Moving Fld
           RC = update_row(st,wconn, wcur, wdict)                       # Go Update Row
           total_error = total_error + RC                               # RC=0=Success RC=1=Error
        if (total_error != 0):                                          # Not SHow if Total Error=0
            st.writelog(" ")                                            # Space line
            st.writelog("Total Error Count at %d now" % (total_error))  # Total Error after each Srv
        lineno += 1

    return(total_error)                                                 # Return Nb Error to caller



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
def cmd_options(st,argv):

    # Evaluate Command Line Switch Options Upfront
    # By Default (-h) Show Help Usage, (-v) Show Script Version,(-d [0-9]) Set Debug Level     
    parser = argparse.ArgumentParser(description=st.pdesc)              # Desc. is the script name
    #
    parser.add_argument("-v", 
        action="store_true", 
        dest='version',
        help="show script version")
    parser.add_argument("-d",
        metavar="0-9",  
        type=int, 
        dest='debuglevel',
        help="debug/verbose level from 0 to 9",
        default=0)
    #
    args=parser.parse_args()                                            # Parse the Arguments

    if args.version:                                                    # If -v specified
        st.show_version()                                               # Show Custom Show Version
        st.stop (0)                                                     # Close/TrimLog/Del tmpfiles
        sys.exit(0)                                                     # Exit with code 0
        
    if args.debuglevel:                                                 # Debug Level -d specified 
        st.debug=args.debuglevel                                        # Save Debug Level
        print ("Debug Level is now set at %d" % (st.debug))             # SHow user debug Level

    return()                                                            # Return To Caller




#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main(argv):

    # Create [S]ADMIN [T]ool Instance and call the start() function.
    st = setup_sadmin()                                                 # Sadm Tools class instance
    cmd_options (st,argv)                                               # Check command-line Options

    # Script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not root
       print ("This script must be run by the 'root' user")             # Advise User Message / Log
       print ("Try sudo %s" % (os.path.basename(sys.argv[0])))          # Suggest to use 'sudo'
       print ("Process aborted")                                        # Process Aborted Msg
       sys.exit(1)                                                      # Exit with Error Code

    # If Script should only be run on the SADMIN Server
    if st.get_fqdn() != st.cfg_server:                                  # Only run on SADMIN
        st.writelog("This script can only be run on SADMIN server (%s)" % (st.cfg_server))
        st.writelog("Process aborted")                                  # Abort advise message
        st.stop(1)                                                      # Close and Trim Log
        sys.exit(1)                                                     # Exit To O/S

    # If we are on SADMIN server & use Database (st.usedb=True), open connection to Server Database
    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database

    st.exit_code = process_servers(conn,cur,st)                         # Process Actives Servers
    
    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        st.dbclose()                                                    # Close the Database
    st.stop(st.exit_code)                                               # Close SADM Environment
    sys.exit(st.exit_code)                                              # Exit To O/S

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)
