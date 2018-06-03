#!/usr/bin/env python3
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_database_update.py
#   Synopsis:   Read Hardware/Software/Performance data collected from servers & update database
#===================================================================================================
# Description
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
# Change Log
# March 2017    v2.3 Change field separator in HOSTNAME_sysinfo.txt file from : to = 
# April 2017    v2.4 Change exception Error Message more verbose
# 2017_11_23    v2.6 Move from PostGres to MySQL, New SADM Python Library and Performance Enhanced.
# 2017_12_07    v2.7 Correct Problem dealing with srv_date_update on newly added server.
# 2018_02_08    v2.8 Bug Fix with test for physical/virtual server
# 2018_02_21    v2.9 Adjust to new calling sadmin lib method#
# 2018_06_03    v3.0 Adapt to new SADMIN Python Library
#
#===================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch             # Import Std Python3 Modules
    SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Root Dir. Name
    sys.path.insert(0,os.path.join(SADM,'lib'))                     # Add SADMIN to sys.path
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


#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Python Library
#===================================================================================================
def setup_sadmin():

    # Load SADMIN Standard Python Library
    try :
        SADM = os.environ.get('SADMIN')                     # Getting SADMIN Root Dir.
        sys.path.insert(0,os.path.join(SADM,'lib'))         # Add SADMIN to sys.path
        import sadmlib_std as sadm                          # Import SADMIN Python Libr.
    except ImportError as e:                                # If Error importing SADMIN 
        print ("Error Importing SADMIN Module: %s " % e)    # Advise USer of Error
        sys.exit(1)                                         # Go Back to O/S with Error
    
    # Create Instance of SADMIN Tool
    st = sadm.sadmtools()                       # Create SADMIN Tools Instance (Setup Dir.,Var,...)

    # Change these values to your script needs.
    st.ver              = "3.0"                 # Current Script Version
    st.multiple_exec    = "N"                   # Allow running multiple copy at same time ?
    st.log_type         = 'B'                   # Output goes to [S]creen [L]ogFile [B]oth
    st.log_append       = True                  # Append Existing Log or Create New One
    st.use_rch          = True                  # Generate entry in Return Code History (.rch) 
    st.log_header       = True                  # Show/Generate Header in script log (.log)
    st.log_footer       = True                  # Show/Generate Footer in script log (.log)
    st.usedb            = True                  # True=Open/Use Database,False=Don't Need to Open DB 
    st.dbsilent         = False                 # Return Error Code & False=ShowErrMsg True=NoErrMsg
    st.exit_code        = 0                     # Script Exit Code for you to use

    # Override Default define in $SADMIN/cfg/sadmin.cfg
    #st.cfg_mail_type    = 1                    # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    #st.cfg_mail_addr    = ""                   # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name     = ""                   # This Override Company Name specify in sadmin.cfg
    #st.cfg_max_logline  = 5000                 # When Script End Trim log file to 5000 Lines
    #st.cfg_max_rchline  = 100                  # When Script End Trim rch file to 100 Lines
    #st.ssh_cmd = "%s -qnp %s " % (st.ssh,st.cfg_ssh_port) # SSH Command to Access Server 

    # Start SADMIN Tools - Initialize 
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..
    return(st)                                  # Return Instance Obj. To Caller




#===================================================================================================
#                   UPDATE ROW INTO FROM THE WROW DICTIONNARY THE SERVER TABLE
#===================================================================================================
#
def update_row(st,wconn, wcur, wdict):
    st.writelog ("Updating %s.%s data in Database" % (wdict['srv_name'],wdict['srv_domain']))

    # Update Server Row With Info collected from the sysinfo.txt file
    try:
        sql =   "UPDATE server SET \
                srv_ostype='%s',            srv_osname='%s', \
                srv_domain='%s',            srv_vm='%d', \
                srv_ostype='%s',            srv_oscodename='%s', \
                srv_osversion='%s',         srv_osver_major='%s', \
                srv_kernel_version='%s',    srv_kernel_bitmode='%d', \
                srv_hwd_bitmode='%s',       srv_model='%s', \
                srv_serial='%s',            srv_memory='%d', \
                srv_nb_cpu='%d',            srv_cpu_speed='%d', \
                srv_nb_socket='%d',         srv_core_per_socket='%d', \
                srv_thread_per_core='%d',   srv_ip='%s', \
                srv_ips_info='%s',          srv_disks_info='%s', \
                srv_vgs_info='%s',          srv_date_update='%s' \
                where srv_name='%s' " %  \
                (wdict['srv_ostype'],           wdict['srv_osname'], \
                wdict['srv_domain'],            wdict['srv_vm'], \
                wdict['srv_ostype'],            wdict['srv_oscodename'], \
                wdict['srv_osversion'],         wdict['srv_osver_major'], \
                wdict['srv_kernel_version'],    wdict['srv_kernel_bitmode'], \
                wdict['srv_hwd_bitmode'],       wdict['srv_model'], \
                wdict['srv_serial'],            wdict['srv_memory'], \
                wdict['srv_nb_cpu'],            wdict['srv_cpu_speed'], \
                wdict['srv_nb_socket'],         wdict['srv_core_per_socket'],\
                wdict['srv_thread_per_core'],   wdict['srv_ip'], \
                wdict['srv_ips_info'],          wdict['srv_disks_info'], \
                wdict['srv_vgs_info'],          wdict['srv_date_update'], \
                wdict['srv_name'])
    except (TypeError, ValueError, IndexError) as error:                # Mismatch Between Num & Str
        #enum, emsg = error.args                                         # Get Error No. & Message
        enum=1
        emsg=error                                                     # Get Error Message
        st.writelog(">>>>>>>>>>>>> (%s) %s " % (enum,error))            # Print Error No. & Message
        st.writelog("sql=%s" % (sql))
        return(1)                                                      # return (1) to indicate Err

    # Execute the SQL Update Statement
    try:
        wcur.execute(sql)                                               # Update Server Data 
        wconn.commit()                                                  # Commit the transaction
        st.writelog("[OK] %s update Succeeded" % (wdict['srv_name']))   # Advise User Update is OK
        return (0)                                                      # return (0) Insert Worked
    except (pymysql.err.InternalError, pymysql.err.IntegrityError) as error:
        enum, emsg = error.args                                         # Get Error No. & Message
        st.writelog("[ERROR] (%s) %s " % (enum,error))                  # Print Error No. & Message
        if st.debug > 4: st.writelog("sql=%s" % (sql))
        wconn.rollback()                                                # RollBack Transaction
        return (1)                                                      # return (1) to indicate Err
    except Exception as error: 
        enum, emsg = error.args                                         # Get Error No. & Message
        st.writelog("[ERROR] (%s) %s " % (enum,error))                  # Print Error No. & Message
        if st.debug > 4: st.writelog("sql=%s" % (sql))
        wconn.rollback()                                                # RollBack Transaction
        return (1)                                                      # return (1) to indicate Err
    return(0)                                                           # Return 0 = update went OK



#===================================================================================================
#                        Process all Actives Servers in the Database
#===================================================================================================
#
def process_servers(wconn,wcur,st):
    #st.writelog (" ")
    #st.writelog (" ")
    st.writelog (('-' * 40))
    st.writelog ("PROCESSING ALL ACTIVES SERVERS")
    #st.writelog (" ")

    # Read All Actives Servers
    sql  = "SELECT srv_name, srv_desc, srv_domain, srv_osname "
    sql += " FROM server WHERE srv_active = %s " % ('True')
    sql += " order by srv_name;"
    try :
        wcur.execute(sql)
        rows = wcur.fetchall()
    except(pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as error:
        self.enum, self.emsg = error.args                               # Get Error No. & Message
        print (">>>>>>>>>>>>>",self.enum,self.emsg)                     # Print Error No. & Message
        return (1)
    
    # Process each server
    lineno = 1
    total_error = 0 
    for row in rows:
        #st.writelog ("%02d %s" % (lineno, row))
        wname   = row[0]                                                # Extract Server Name
        wdesc   = row[1]                                                # Extract Server Desc.
        wdomain = row[2]                                                # Extract Server Domain Name
        wos     = row[3]                                                # Extract Server O/S Name
        st.writelog("")                                                 # Insert Blank Line
        st.writelog (('-' * 40))                                        # Insert Dash Line
        st.writelog ("Processing (%d) %-15s - os:%s" % (lineno,wname+"."+wdomain,wos))

        sysfile = st.www_dat_dir + "/" + wname + "/dr/" + wname + "_sysinfo.txt"
        st.writelog("Processing file : " + sysfile)                     # Display Sysinfo File

        # Open sysinfo.txt file for the current server ---------------------------------------------
        if st.debug > 4: st.writelog("Opening %s" % (sysfile))          # Opened Sysinfo file Msg
        try:
            FH = open(sysfile, 'r')                                     # Open Sysinfo File
        except FileNotFoundError as e:
            st.writelog("Sysinfo file not found %s" % (sysfile))
            continue
        except IOError as e:                                            # If Can't open file
            set.writelog("Error opening file %s \r\n" % sysfile)        # Print FileName
            set.writelog("Error Number : {0}\r\n.format(e.errno)")      # Print Error Number
            set.writelog ("error({0}):{1}".format(e.errno, e.strerror))
            set.writelog (repr(e))           
            set.writelog("Error Text   : {0}\r\n.format(e.strerror)")   # Print Error Message
            return 1                                                    # Return Error to Caller
        if st.debug > 4: set.writelog("File %s opened" % sysfile)       # Opened Sysinfo file Msg

        # Process the content of the sysinfo.txt file ----------------------------------------------
        if st.debug > 4: st.writelog("Reading %s" % sysfile)            # Reading Sysinfo file Msg
        wdict = {}                                                      # Create an empty Dictionary
        wdict['srv_date_update'] = "None"                               # Default Value Upd.Date
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

                # PHYSICAL OR VIRTUAL SERVER
                if "SADM_SERVER_TYPE" in CFG_NAME:
                    if CFG_VALUE.upper()  == 'P':
                        wdict['srv_vm'] = 0
                    else:
                        wdict['srv_vm'] = 1

                 # RUNNING KERNEL IS 32 OR 64 BITS (IF ERROR SET VALUE TO ZERO - TO SPOT ERROR)
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



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():

    # Script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not root
       print ("This script must be run by the 'root' user")             # Advise User Message / Log
       print ("Try sudo %s" % (os.path.basename(sys.argv[0])))          # Suggest to use 'sudo'
       print ("Process aborted")                                        # Process Aborted Msg
       sys.exit(1)                                                      # Exit with Error Code

    # Import SADMIN Module, Create SADMIN Tool Instance, Initialize Log and rch file.  
    st = setup_sadmin()                                                 # Setup Var. & Load SADM Lib

    # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    if st.get_fqdn() != st.cfg_server:                                  # Only run on SADMIN
        st.writelog("This script can only be run on SADMIN server (%s)" % (st.cfg_server))
        st.writelog("Process aborted")                                  # Abort advise message
        st.stop(1)                                                      # Close and Trim Log
        sys.exit(1)                                                     # Exit To O/S
        
    (conn,cur) = st.dbconnect()                                         # Connect to SADMIN Database
    st.exit_code = process_servers(conn,cur,st)                         # Process Actives Servers 
    st.dbclose()                                                        # Close the Database
    st.stop(st.exit_code)                                               # Close SADM Environment
    sys.exit(st.exit_code)                                              # Exit To O/S

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
