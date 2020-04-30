#!/usr/bin/env python3
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_server_subnet_lookup.py
#   Synopsis:   Produce Web Network Page That List IP, Name and Mac usage for subnet you specify
#
# #===================================================================================================
# Description
#  This script ping and do a nslookup for every IP specify in the "SUBNET" Variable.
#  Result of each subnet is recorded in their own file ${SADM_BASE_DIR}/dat/net/subnet_SUBNET.txt
#  These file are used by the Web Interface to inform user what IP is free and what IP is used.
#  On the Web interface the file can be seen by selecting the IP Inventory page.
#  It is run once a day from the crontab.
#
# --------------------------------------------------------------------------------------------------
# 2018_04_08 v1.0 Initial Beta version
# 2018_04_11 v1.1 Output File include MAC,Manufacturer
# 2018_04_13 v1.3 Manufacturer Info Expanded and use fping to check if host is up
# 2018-04-17 v1.4 Added update to server_network table in Mariadb
# 2018-04-18 v1.5 Fix problem updating Mac in Database when it could not be detected on next run.
# 2018-04-26 v1.7 Show Some Messages only with DEBUG Mode ON & Bug fixes
# 2018-06_06 v1.8 Small Corrections
# 2018-06_09 v1.9 Change Script name to sadm_subnet_lookup
# 2018-09_22 v2.0 Fix Problem with Updating Last Ping Date
# 2018-11_09 v2.1 DataBase Connect/Disconnect revised.
# 2019_03_30 Fix: v2.2 Fix problem reading the fping result, database update fix.
#@2019_11_05 Update: v2.3 Restructure code for performance.
#@2019_11_06 Fix: v2.4 Ping response was not recorded properly
#@2020_04_25 New: v3.0 Major update, more portable, No longer use arp-scan.
#@2020_04_27 New: v3.1 Show full Ping and change Date/Time.
#@2020_04_30 Update: v3.2 Install module 'getmac', if it's not installed.
# --------------------------------------------------------------------------------------------------
#
try :
    import os,time,sys,pdb,socket,datetime,pwd,grp,pymysql,subprocess,ipaddress # Import Std Modules
    from subprocess import Popen, PIPE    
    SADM = os.environ.get('SADMIN')                                     # Get SADMIN Root Dir. Name
    sys.path.insert(0,os.path.join(SADM,'lib'))                         # Add SADMIN to sys.path
    import sadmlib_std as sadm                                          # Import SADMIN Python Libr.
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
    #pdb.set_trace()                                                        # Activate Python Debugging

try :
    from getmac import get_mac_address                                  # For Getting IP Mac Address
except ImportError as e:
    print ("Import Error : %s " % e)
    print ("Installing 'getmac'")
    command = "pip3 install --user getmac"
    p = subprocess.Popen(command, stdout=PIPE, stderr=PIPE, shell=True)
    out = p.stdout.read().strip().decode()
    err = p.stderr.read().strip().decode()
    returncode = p.wait()
    #print ("In sadm_oscommand function stdout is      : %s" % (out))
    #print ("In sadm_oscommand function stderr is      : %s " % (err))
    if returncode == 0 :
        print ("Module 'getmac' is now install (%s)\n" % (returncode))
        print ("Please re-run this script, everything should be ok now")  
        sys.exit(1)
    else : 
        print ("Module 'getmac' could not be install (%s)\n" % (returncode))
        sys.exit(1)

#try :
#    import getmac                                 # For Getting IP Mac Address
#except ImportError as e:
#    print ("Import Error : %s " % e)
#    sys.exit(1)


#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
#
DEBUG = False                                                           # Activate Debug (Verbosity)
netdict = {}                                                            # Network Work Dictionnary



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
    st.ver              = "3.2"                 # Current Script Version
    st.multiple_exec    = "N"                   # Allow running multiple copy at same time ?
    st.log_type         = 'B'                   # Output goes to [S]creen [L]ogFile [B]oth
    st.log_append       = False                 # Append Existing Log or Create New One
    st.use_rch          = True                  # Generate entry in Result Code History (.rch)
    st.log_header       = True                  # Show/Generate Header in script log (.log)
    st.log_footer       = True                  # Show/Generate Footer in script log (.log)
    st.usedb            = True                  # True=Open/Use Database,False=Don't Need to Open DB
    st.dbsilent         = False                 # Return Error Code & False=ShowErrMsg True=NoErrMsg
    st.exit_code        = 0                     # Script Exit Code for you to use

    # Override Default define in $SADMIN/cfg/sadmin.cfg
    #st.cfg_alert_type   = 1                    # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    #st.cfg_alert_group  = "default"            # Valid Alert Group are defined in alert_group.cfg
    #st.cfg_mail_addr    = ""                   # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name     = ""                   # This Override Company Name specify in sadmin.cfg
    st.cfg_max_logline  = 5000                  # When Script End Trim log file to 1000 Lines
    #st.cfg_max_rchline  = 125                  # When Script End Trim rch file to 125 Lines
    #st.ssh_cmd = "%s -qnp %s " % (st.ssh,st.cfg_ssh_port) # SSH Command to Access Server

    # Start SADMIN Tools - Initialize
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..
    return(st)                                  # Return Instance Obj. To Caller



#===================================================================================================
#                                       RUN O/S COMMAND FUNCTION
#===================================================================================================
#
def oscommand(command) :
    if DEBUG : print ("In sadm_oscommand function to run command : %s" % (command))
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out = p.stdout.read().strip().decode()
    err = p.stderr.read().strip().decode()
    returncode = p.wait()
    #if (DEBUG) :
    #    print ("In sadm_oscommand function stdout is      : %s" % (out))
    #    print ("In sadm_oscommand function stderr is      : %s " % (err))
    #    print ("In sadm_oscommand function returncode is  : %s" % (returncode))
    return (returncode,out,err)


# ----------------------------------------------------------------------------------------------
# Determine if the key (IP) is present or not in the Network Table.
#
# Function parameters :
#   - st = Object Instance of SADM Tools 
#   - wcon = Connection Object to Database
#   - wcur = Cursor Object on Database
#   - tbkey = IP (Ex: 192.168.1.145) to check existence in Network Table
#   - dbsilent = if True (Default), return error code and no error message.
#                if False return error code and if Error show Error message returned I/O.
#
# Return 2 parameters :
#   1 = Error Code (0=found 1=NotFound)
#   2 = If Row was found then return row data as a tuple.
#       If Row was not found 'None' is returned as the second parameter
# ----------------------------------------------------------------------------------------------
def db_readkey(st,wconn,wcur,tbkey,dbsilent=True):


    sql = "SELECT * FROM server_network WHERE net_ip='%s'" % (tbkey)    # Build select statement
    try :
        number_of_rows = wcur.execute(sql)                              # Execute the Select Stat.
        if (number_of_rows == 0):
            if not dbsilent :                                           # If not in Silent Mode
                emsg = "Key '%s' not found in table" % (tbkey)          # Build Error Message
                st.writelog(">>>>>>>>>>>>> %d %s" % (1,emsg))           # Show Error No. & Message
            return(1,None)                                              # Return Error No. & No Data

        dbrow = wcur.fetchone()                                         # Get one row base on key
        if (dbrow == None) :                                            # If not row returned
            if not dbsilent :                                           # If not in Silent Mode
                emsg = "No row found with matching key '%s'" % (tbkey)
                st.writelog(">>>>>>>>>>>>> %d %s" % (1,emsg))           # Show Error No. & Message
            return(1,None)                                              # Return Error No. & No Data

    except (pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as e:
        if not dbsilent :                                               # If not in Silent Mode
            enum, emsg = e.args                                         # Get Error No. & Message
            st.writelog(">>>>>>>>>>>>> %d %s" % (enum,emsg))            # Show Error No. & Message
            return(1,None)                                              # Return Error No. & No Data

    return(0,dbrow)                                                     # Return no Error & row data



#-----------------------------------------------------------------------------------------------
# INSERT ROW IN SERVER_NETWORK TABLE
#
# Function parameters :
#   - st = Object Instance of SADM Tools 
#   - wcon = Connection Object to Database
#   - wcur = Cursor Object on Database
#   - tbkey = IP (Ex: 192.168.1.145) to update
#   - tbdata = Data collected about IP 
#       Example of tbdata received
#       ['192.168.1.1','192.168.001.001','Router','b8:27:eb:9e:77:81','Y',\
#       '2018-04-18 21:09:58','2018-04-18 21:09:58']
#   - dbsilent = if True, return error code and no error message.
#                if False (Default) return error code and if Error show Error message returned I/O.
#
# Return parameter :
#   0 = Update Succeeded     
#   1 = Update Failed 
#-----------------------------------------------------------------------------------------------
def db_insert(st,wconn,wcur,tbkey,tbdata,dbsilent=False):
    if DEBUG : st.writelog("Insert IP: %s " % tbkey);                   # Show key to Insert
    wdate = time.strftime('%Y-%m-%d %H:%M:%S')                          # Save Current Date & Time

    # If IP is pingable then update the last ping date
    if (tbdata[5] == True):                                             # If IP Was pingable
        wpingdate = wdate                                               # Pingable Update Ping Date
    else:                                                               # If IP is not pingable
        wpingdate = '0000-00-00 00:00:00'                               # No Ping Date by Default

    # BUILD THE INSERT STATEMENT
    try:
        sql = "INSERT INTO server_network SET \
              net_ip='%s', net_ip_wzero='%s', net_hostname='%s', net_mac='%s', net_man='%s', \
              net_ping='%d', net_date_ping='%s', net_date_update='%s' " % \
              (tbdata[0], tbdata[1], tbdata[2], tbdata[3], tbdata[4], tbdata[5], wpingdate, wdate);
        if DEBUG : st.writelog("Insert SQL: %s " % sql);                # Debug Show SQL Statement
    except (TypeError, ValueError, IndexError) as error:                # Mismatch Between Num & Str
        enum=1                                                          # Set Class Error Number
        emsg=error                                                      # Get Error Message
        if not dbsilent:                                                # If not in Silent Mode
            st.writelog(">>>>>>>>>>>>>",enum,error)                     # Print Error No. & Message
            return(enum)                                                # return (1) indicate Error

    # EXECUTE INSERT STATEMENT
    try:
        wcur.execute(sql)                                               # Insert new Data
        wconn.commit()                                                  # Commit the transaction
    except (pymysql.err.InternalError, pymysql.err.IntegrityError) as error:
        if not dbsilent :                                               # If not in Silent Mode
            enum, emsg = error.args                                     # Get Error No. & Message
            st.writelog(">>>>>>>>>>>>> %d %s" % (enum,emsg))            # Show Error No. & Message
        return(enum)                                                    # return Error Number

    return(0)                                                           # return (0) Insert Worked


#===================================================================================================
# UPDATE THE NETWORK IP DATABASE TABLE
#
# Function parameters :
#   - st            = Object Instance of SADM Tools 
#   - wcon          = Connection Object to Database
#   - wcur          = Cursor Object on Database
#   - wip           = IP (Ex: 192.168.1.222)
#   - wzero         = IP with 3 digits (use for sorting) (Ex: 192.168.001.222)
#   - wman          = Manufacturer (Vendor) of network device.
#   - wping         = 1= if responded to ping  
#                     0= Didn't responded to ping  
#   - wdateping     = Date of Last Ping (Ex: 2019-11-05 07:43:52)
#   - wdatechange   = Date if last change of MacAddress or Hostname.
#
# Return parameter :
#   0 = Update Succeeded     
#   1 = Update Failed 
#===================================================================================================
#
def db_update(st,wconn,wcur,wip,wzero,wname,wmac,wman,wping,wdateping,wdatechange):

    # Update Server Row With Info collected from the sysinfo.txt file
    try:
        sql = "UPDATE server_network SET net_ip='%s', net_ip_wzero='%s', net_hostname='%s', \
              net_mac='%s', net_man='%s', net_ping='%s', net_date_ping='%s', net_date_update='%s' \
              where net_ip='%s' " % (wip,wzero,wname,wmac,wman,wping,wdateping,wdatechange,wip)
    except (TypeError, ValueError, IndexError) as error:                # Mismatch Between Num & Str
        enum, emsg = error.args                                         # Get Error No. & Message
        #enum=1
        #emsg=error                                                     # Get Error Message
        st.writelog(">>>>>>>>>>>>> (%s) %s " % (enum,error))            # Print Error No. & Message
        st.writelog("sql=%s" % (sql))
        return(1)                                                       # return (1) to indicate Err
    if (DEBUG) : st.writelog("sql=%s" % (sql))                      # Show SQL in Error

    # Execute the SQL Update Statement
    try:
        wcur.execute(sql)                                               # Update Server Data
        wconn.commit()                                                  # Commit the transaction
    except (pymysql.err.InternalError, pymysql.err.IntegrityError) as error:
        enum, emsg = error.args                                         # Get Error No. & Message
        st.writelog("[ERROR] (%s) %s " % (enum,error))                  # Print Error No. & Message
        if (DEBUG) : st.writelog("sql=%s" % (sql))                      # Show SQL in Error
        wconn.rollback()                                                # RollBack Transaction
        return (1)                                                      # return (1) to indicate Err
    except Exception as error:
        enum, emsg = error.args                                         # Get Error No. & Message
        st.writelog("[ERROR] (%s) %s " % (enum,error))                  # Print Error No. & Message
        if (DEBUG) : st.writelog("sql=%s" % (sql))                      # Show SQL in Error
        wconn.rollback()                                                # RollBack Transaction
        return (1)                                                      # return (1) to indicate Err
    return(0)                                                           # Return 0 = update went OK



#===================================================================================================
#                            Scan The Network Received (Example: "192.168.1.0/24")
#===================================================================================================
#
def scan_network(st,snet,wconn,wcur) :
    if DEBUG : st.writelog ("In 'scan_network', parameter received : %s" % (snet))

    # GET MAIN NETWORK INTERFACE NAME 
    cmd = "netstat -rn |grep '^0.0.0.0' |awk '{ print $NF }'"           # Get Default Route DevName
    ccode,cstdout,cstderr = oscommand(cmd)                              # Run the arp-scan command
    if (ccode != 0):                                                    # If Error running command
        st.writelog ("Problem running : %s" & (cmd))                    # Show Command in Error
        st.writelog ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))   # Write stdout & stderr
    else:                                                               # If netstat succeeded
        netdev=cstdout                                                  # Save Net. Interface Name
        st.writelog ("Current host interface name     : %s" % (netdev)) # Show Interface selected


    # SHOW NUMBER OF IP IN NETWORK SUBNET
    NET4 = ipaddress.ip_network(snet)                                   # Create instance of network
    snbip = NET4.num_addresses                                          # Save Number of possible IP
    st.writelog ("Possible IP on %s   : %s " % (snet,snbip))            # Show Nb. Possible IP


    # SHOW NETWORK NETMASK
    snetmask = NET4.netmask                                             # Save Network Netmask
    st.writelog ("Network netmask                 : %s" % (snetmask))   # Show User Netmask


    # Run fping on Subnet and generate a file containing that IP of servers alive.
    # Example of output from fping (After running cmd):
    # 192.168.1.10
    # 192.168.1.100
    # 192.168.1.101
    fpingfile = "%s/fping.txt" % (st.net_dir)                           # fping result file name
    cmd  = "fping -aq -r1 -g %s 2>/dev/null |tee %s" % (snet,fpingfile) # fping cmd
    st.writelog ("\nRunning fping and output to %s" % (fpingfile))      # Show fping output filename
    if (DEBUG) : st.writelog ("Command : %s" % (cmd))   
    ccode,fpinglist,cstderr = oscommand(cmd)                            # Run the fping command
    if (ccode > 1):                                                     # If Error running command
        st.writelog ("Problem running : %s" % (cmd))                    # Show Command in Error
        st.writelog ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))   # Write stdout & stderr
        sys.exit(1)                                                     # Exit script with Error
    else: 
        st.writelog ("The fping finished with success.\n")              # Show Command Success


    # ITERATING THROUGH THE USABLE ADDRESSES ON A NETWORK:
    for ip in NET4.hosts():                                             # Loop through possible IP
        hip = str(ipaddress.ip_address(ip))                             # Save processing IP
        try :                                                           # Try Get Hostname of the IP
            (hname,halias,hiplist)   = socket.gethostbyaddr(hip)        # Get IP DNS Name
            if DEBUG : st.writelog ("hname = %s, Alias = %s, IPList = %s" % (hname,halias,hiplist))
        except socket.herror as e:                                      # If IP has no Name
            hname = ""                                                  # Clear IP Hostname

        # IS THE IP IN THE FPING ACTIVE LIST ?
        if ("%s" % (hip) in fpinglist) :                                # Is IP is fping active list
            hactive = 1                                                 # IP is reachable
            if (DEBUG) : st.writelog ("Yes it is - Responded to ping")
        else: 
            hactive = 0                                                 # IP is not Reachable
            if (DEBUG) : st.writelog ("No it isn't - No ping response")

        # GET MAC ADDRESS OF IP & SET IP STATUS (ACTIVE/INACTIVE)
        hmac = ''                                                       # Clear Work Mac Address
        hmac = get_mac_address(ip=hip, network_request=True)            # Get Mac Address of IP 
        if DEBUG : print ( "Mac returned by get_mac_address is ...%s..." % (hmac))
        if hmac == "00:00:00:00:00:00" : hmac=""                        # If can't get Mac Address
        if DEBUG : print ( "The working Mac is : ...%s..." % (hmac))    # Print Final hmac Content

        # CREATE IP FIELD WITH LEADING ZERO 
        (ip1,ip2,ip3,ip4) = hip.split('.')                              # Split IP Address
        zip = "%03d.%03d.%03d.%03d" % (int(ip1),int(ip2),int(ip3),int(ip4)) # Ip with Leading Zero

        hmanu = ''                                                      # Clear Work Vendor
        WLINE = "%s,%s,%s,%s,%d" % (zip, hname, hmac, hmanu, hactive)   # Format Output file Line
        netdict[hip] = WLINE                                            # Put Line in Dictionary
        if (DEBUG) : st.writelog ("Put %s info '%s' in array" % (hip,WLINE))

        # VERIFY IF IP IS IN DATABASE NETWORK TABLE
        if (DEBUG) :
            st.writelog("Check if IP '%s' exist in database" % (hip))   # Show IP were looking for
        (dberr,dbrow) = db_readkey(st,wconn,wcur,hip,True)              # Read IP Row if Exist

        # IP WAS NOT FOUND IN DATABASE
        if (dberr != 0):                                                # If IP Not in Database
            if (DEBUG) : st.writelog("IP %s doesn't exist in database" % (hip)) # Advise Usr of flow
            cdata = [hip,zip,hname,hmac,hmanu,hactive]                  # Data to Insert
            dberr = db_insert(st,wconn,wcur,hip,cdata,False)            # Insert Data in Cat. Table
            if (dberr != 0) :                                           # Did the insert went well ?
                st.writelog("[ Error ] %d adding '%s' to database" % (dberr,hip))  # Show Error & Mess.
            else :
                st.writelog("[ OK ] Inserted in DB = IP=%s Hostname:.%s. Mac:.%s. Vendor=.%s. Active=.%d.\n" % (hip,hname,hmac,hmanu,hactive ))
            continue                                                    # Continue with next IP

        # RECORD WAS FOUND - SAVE ACTUAL ROW INFORMATION
        row_hostname    = dbrow[2]                                      # Save DB Hostname
        row_mac         = dbrow[3]                                      # Save DB Mac Adress
        row_manu        = dbrow[4]                                      # Save DB Vendor
        row_ping        = dbrow[5]                                      # Save Last Ping Result(0,1)
        row_pingdate    = dbrow[6]                                      # Save Last Ping Date
        row_datechg     = dbrow[7]                                      # Save Last Mac/Name Chg Date
        if (DEBUG) :
            st.writelog("DB Row Found: hostname %s, Mac %s, Ping %s, DatePing %s, DateUpdate %s" 
            % (row_hostname,row_mac,row_ping,row_pingdate,row_datechg))
        wdate = time.strftime('%Y-%m-%d %H:%M:%S')                      # Save Current Date & Time

        # UPDATE IP PING STATUS AND LAST PING DATE
        if (hactive == 1) :                                             # If IP is pingable
            row_pingdate = wdate                                        # Update Last Ping Date
            row_ping = 1                                                # Update Row Ping Info
            st.writelog("%-16s %-s Ping work, change last ping date." % (hip,row_hostname))
        else:
            row_ping = 0                                                # Update Row Ping Info
            st.writelog("%-16s %-s Ping didn't work, Leave last ping date as it is." % (hip,row_hostname))

        # IF MAC HAVE CHANGED AND NEW MAC IS NOT BLANK THEN UPDATE LAST CHANGE DATE.
        if row_mac != hmac :                                            # If MAC Change
            if hmac == "" or hmac is None :                           # If No New MAC
                st.writelog("%-16s Keep old mac at '%s' since new mac is '%s'" % (hip,row_mac,hmac))
            else:
                if hmac is not None : 
                    st.writelog("%-16s Mac Address changed from '%s' to '%s'" % (hip,row_mac,hmac))
                    row_datechg = wdate                                 # MAC Changed Upd. Date Chng
                    row_mac = hmac                                      # Update IP Mac Address
                else :
                    st.writelog("%-16s Keep old mac at '%s' since new mac is '%s'" % (hip,row_mac,hmac))
        else :
            st.writelog ("%-16s Keep old mac at '%s' since new mac is '%s'" % (hip,row_mac,hmac))
    
        # IF HOSTNAME OF THE IP HAVE CHANGED, UPDATE LAST CHANGE DATE.
        if (row_hostname != hname):
            st.writelog("%-16s - Host Name changed from '%s' to '%s'" % (hip,row_hostname,hname))
            row_datechg = wdate                                         # Hostname Chg Upd Date Chng
            row_hostname = hname                                        # Update IP new hostname

        # GO UPDATE DATABASE
        if (DEBUG) : st.writelog ("Updating '%s' data" % (hip))
        dberr = db_update(st,wconn,wcur,hip,zip,row_hostname,row_mac,row_manu,row_ping,row_pingdate,row_datechg)
        if (dberr != 0) :                                               # If no Error updating IP
            st.writelog("[ ERROR ] Updating IP '%s'" % (hip))             # Advise User Update Error
        else :
            st.writelog("[ OK ] Updated in DB = IP=%s Hostname:.%s. Mac:.%s. Vendor=.%s. Active=.%d. PingDate=%s ChangeDate=%s\n" % (hip,row_hostname,row_mac,row_manu,row_ping,row_pingdate,row_datechg))

    return(0)                                                           # Return to Caller

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main_process(wconn,wcur,st):
    if (DEBUG): st.writelog("Processing Network1 = _%s_" % (st.cfg_network1))
    if (st.cfg_network1 != "") :
        scan_network(st,st.cfg_network1,wconn,wcur)                     # Network Subnet 1 to report

    if (DEBUG): st.writelog("Processing Network2 = _%s_" % (st.cfg_network2))
    if (st.cfg_network2 != "") :
        scan_network(st,st.cfg_network2,wconn,wcur)                     # Network Subnet 2 to report

    if (DEBUG): st.writelog("Processing Network3 = _%s_" % (st.cfg_network3))
    if (st.cfg_network3 != "") :
        scan_network(st,st.cfg_network3,wconn,wcur)                     # Network Subnet 3 to report

    if (DEBUG): st.writelog("Processing Network4 = _%s_" % (st.cfg_network4))
    if (st.cfg_network4 != "") :
        scan_network(st,st.cfg_network4,wconn,wcur)                     # Network Subnet 4 to report

    if (DEBUG): st.writelog("Processing Network5 = _%s_" % (st.cfg_network5))
    if (st.cfg_network5 != "") : scan_network(st,st.cfg_network5)       # Network Subnet 5 to report

    return(0)



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    # Import SADMIN Module, Create SADMIN Tool Instance, Initialize Log and rch file.
    st = setup_sadmin()                                                 # Setup Var. & Load SADM Lib

    # Insure that this script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
       st.writelog ("This script must be run by the 'root' user")       # Advise User Message / Log
       st.writelog ("Try sudo ./%s" % (st.pn))                          # Suggest to use 'sudo'
       st.writelog ("Process aborted")                                  # Process Aborted Msg
       st.stop (1)                                                      # Close and Trim Log/Email
       sys.exit(1)                                                      # Exit with Error Code

    # Test if script is running on the SADMIN Server, If not abort script (Optional code)
    if st.get_fqdn() != st.cfg_server:                                  # Only run on SADMIN
        st.writelog("This script can only be run on SADMIN server (%s)" % (st.cfg_server))
        st.writelog("Process aborted")                                  # Abort advise message
        st.stop(1)                                                      # Close and Trim Log
        sys.exit(1)                                                     # Exit To O/S

    # If we are on SADMIN server & use Database (st.usedb=True), open connection to Server Database
    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        (conn,cur) = st.dbconnect()                                     # Connect to SADMIN Database

    st.exit_code = main_process(conn,cur,st)                            # Use Subnet in sadmin.cfg

    if ((st.get_fqdn() == st.cfg_server) and (st.usedb)):               # On SADMIN srv & usedb True
        st.dbclose()                                                    # Close the Database
    st.stop(st.exit_code)                                               # Close SADM Environment
    sys.exit(st.exit_code)                                              # Exit To O/S

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
