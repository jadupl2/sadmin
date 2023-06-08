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
# 2018-04-26 v1.7 Show Some Messages only with st.debug Mode ON & Bug fixes
# 2018-06_06 v1.8 Small Corrections
# 2018-06_09 v1.9 Change Script name to sadm_subnet_lookup
# 2018-09_22 v2.0 Fix Problem with Updating Last Ping Date
# 2018-11_09 v2.1 DataBase Connect/Disconnect revised.
# 2019_03_30 Fix: v2.2 Fix problem reading the fping result, database update fix.
# 2019_11_05 Update: v2.3 Restructure code for performance.
# 2019_11_06 Fix: v2.4 Ping response was not recorded properly
# 2020_04_25 New: v3.0 Major update, more portable, No longer use arp-scan.
# 2020_04_27 New: v3.1 Show full Ping and change Date/Time.
# 2020_04_30 Update: v3.2 Install module 'getmac', if it's not installed.
# 2021_05_14 Fix: v3.3 Get DB result as a dict. (connect cursorclass=pymysql.cursors.DictCursor)
# 2021_06_02 server v3.4 Added command line options and major code review
# 2022_06_10 server v3.5 Update to use the new SADMIN Python Library v2
# 2022_07_27 server v3.6 Bug fix when ping were reported when it wasn't.
# 2022_08_17 nolog  v3.7 Remove debug info & update to use the new SADMIN Python Library v2.2.
# 2023_05_19 server v3.8 Correct problem when running at installation time ($SADMIN not set yet).
# --------------------------------------------------------------------------------------------------
#
try :
    import os,time,argparse,sys,pdb,socket,datetime,pwd,grp,pymysql,subprocess,ipaddress,re
    from subprocess import Popen, PIPE   
    from getmac import get_mac_address                                  # For Getting IP Mac Address
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
    #pdb.set_trace()                                                    # Activate Python




# --------------------------------------------------------------------------------------------------
# This script in ran near the end of installation and SADMIN env. variable is not yet define.
# So the code below use the SADMIN variable define in /etc/environment has a plan b.
# For all others python script it is not necessary, because 'SADMIN' env. variable will be defined.
#
# SADMIN CODE SECTION v2.3 ---- DO NOT UPDATE SADMIN SECTION IN THIS SCRIPT
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# --------------------------------------------------------------------------------------------------
# Making sure the 'SADMIN' environment variable is defined, abort if it isn't. 
if (os.getenv("SADMIN",default="X") == "X"):                            # SADMIN Env.Var. Not Define
    print("\nThe 'SADMIN' environment variable isn't defined.")         # SADMIN Var MUST be defined
    print("It must specify the directory where you installed the SADMIN Tools.")
    fenv = "/etc/environment" 
    if os.path.exists(fenv):                                            
        with open(fenv,"r") as file:
            for line in file:
                if re.search('SADMIN', line):
                    split_line = line.split('=')
                    os.environ['SADMIN'] = str(split_line[1]).strip()  
                    print ("For the moment, I took the location of 'SADMIN' from '%s'.\n" % fenv)   
                    break
        if (os.getenv("SADMIN",default="X") == "X"):          
            print ("Variable 'SADMIN' wasn't even found in '%s', script aborted.\n" % fenv) 
            sys.exit(1)  
    else: 
        print ("File '%s' doesn't exist, script aborted.\n" % fenv)
        sys.exit(1)    
try:
    sys.path.insert(0, os.path.join(os.environ.get('SADMIN'), 'lib'))# Add $SADMIN/lib to sys.path
    import sadmlib2_std as sa                                        # Load SADMIN Python Library
except ImportError as e:                                             # If Error importing SADMIN
    print("Import error : SADMIN module: %s " % e)                   # Advise User of Error
    sys.exit(1)  

# Local variables local to this script.
pver        = "3.8"                                                     # Program version
pdesc       = "Produce Web network page that list IP, name and mac usage for subnet you specified."
phostname   = sa.get_hostname()                                         # Get current `hostname -s`
pdb_conn    = None                                                      # Database connector
pdb_cur     = None                                                      # Database cursor
pdebug      = 0                                                         # Debug level from 0 to 9
pexit_code  = 0                                                         # Script default exit code

# The values of fields below, are loaded from sadmin.cfg when you import the SADMIN library.
# Uncomment anyone to change them and influence execution of SADMIN standard library.
#
sa.proot_only        = True       # Pgm run by root only ?
sa.psadm_server_only = True      # Run only on SADMIN server ?
sa.db_used           = True       # Open/Use Database(True) or Don't Need DB(False)
#sa.db_silent        = False      # When DB Error, False=ShowErrMsg, True=NoErrMsg
#sa.sadm_alert_type  = 1          # 0=NoAlert 1=AlertOnlyOnError 2=AlertOnlyOnSuccess 3=AlwaysAlert
#sa.sadm_alert_group = "default"  # Valid Alert Group defined in $SADMIN/cfg/alert_group.cfg
#sa.pid_timeout      = 7200       # PID File Default Time to Live in seconds.
#sa.lock_timeout     = 3600       # A host can be lock for this number of seconds, auto unlock after
sa.max_logline      = 600        # Max. lines to keep in log (0=No trim) after execution.
#sa.max_rchline      = 40         # Max. lines to keep in rch (0=No trim) after execution.
#sa.log_type         = 'B'        # Output goes to [S]creen to [L]ogFile or [B]oth
#sa.log_append       = False      # Append Existing Log(True) or Create New One(False)
#sa.log_header       = True       # Show/Generate Header in script log (.log)
#sa.log_footer       = True       # Show/Generate Footer in script log (.log)
#sa.multiple_exec    = "Y"        # Allow running multiple copy at same time ?
#sa.use_rch         = True       # Generate entry in Result Code History (.rch)
#sa.sadm_mail_addr   = ""         # All mail goes to this email (Default is in sadmin.cfg)
sa.cmd_ssh_full = "%s -qnp %s " % (sa.cmd_ssh, sa.sadm_ssh_port)           # SSH Cmd to access clients
#
# ==================================================================================================




#===================================================================================================
#                                 Local Variables used by this script
#===================================================================================================
#
netdict = {}                                                            # Network Work Dictionary





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
def db_readkey(wconn,wcur,tbkey,dbsilent=True):
    global pdebug
    

    sql = "SELECT * FROM server_network WHERE net_ip='%s'" % (tbkey)    # Build select statement
    try :
        number_of_rows = wcur.execute(sql)                              # Execute the Select Stat.
        if (number_of_rows == 0):                                       # If IP Not found
            if not dbsilent :                                           # If not in Silent Mode
                emsg = "Key '%s' not found in table" % (tbkey)          # Build Error Message
                sa.write_log(">>>>>>>>>>>>> %d %s" % (1,emsg))          # Show Error No. & Message
            return(1,None)                                              # Return Error No. & No Data

        dbrow = wcur.fetchone()                                         # Get one row base on key
        if (dbrow == None) :                                            # If not row returned
            if not dbsilent :                                           # If not in Silent Mode
                emsg = "No row found with matching key '%s'" % (tbkey)
                sa.write_log(">>>>>>>>>>>>> %d %s" % (1,emsg))          # Show Error No. & Message
            return(1,None)                                              # Return Error No. & No Data

    except (pymysql.err.InternalError,pymysql.err.IntegrityError,pymysql.err.DataError) as e:
        if not dbsilent :                                               # If not in Silent Mode
            enum, emsg = e.args                                         # Get Error No. & Message
            sa.write_log(">>>>>>>>>>>>> %d %s" % (enum,emsg))           # Show Error No. & Message
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
def db_insert(wconn,wcur,tbkey,tbdata,dbsilent=False):
    global pdebug

    if pdebug > 4 : sa.write_log("Inserting IP: %s " % tbkey);          # Show key to Insert
    wdate = time.strftime('%Y-%m-%d %H:%M:%S')                          # Save Current Date & Time

    # If IP is pingable then update the last ping date
    if (tbdata[5] == True):                                             # If IP Was pingable
        wpingdate = wdate                                               # Pingable Update Ping Date
    else:                                                               # If IP is not pingable
        wpingdate = '0000-00-00 00:00:00'                               # No Ping Date by Default

    # Build the insert statement
    try:
        sql = "INSERT INTO server_network SET \
              net_ip='%s', net_ip_wzero='%s', net_hostname='%s', net_mac='%s', net_man='%s', \
              net_ping='%d', net_date_ping='%s', net_date_update='%s' " % \
              (tbdata[0], tbdata[1], tbdata[2], tbdata[3], tbdata[4], tbdata[5], wpingdate, wdate);
        if pdebug > 4 : sa.write_log("Insert SQL: %s " % sql);          # debug Show SQL Statement
    except (TypeError, ValueError, IndexError) as error:                # Mismatch Between Num & Str
        enum=1                                                          # Set Class Error Number
        emsg=error                                                      # Get Error Message
        if not dbsilent:                                                # If not in Silent Mode
            sa.write_log(">>>>>>>>>>>>>",enum,error)                    # Print Error No. & Message
            return(enum)                                                # return (1) indicate Error

    # Execute the insert statement
    try:
        wcur.execute(sql)                                               # Insert new Data
        wconn.commit()                                                  # Commit the transaction
    except (pymysql.err.InternalError, pymysql.err.IntegrityError) as error:
        if not dbsilent :                                               # If not in Silent Mode
            enum, emsg = error.args                                     # Get Error No. & Message
            sa.write_log(">>>>>>>>>>>>> %d %s" % (enum,emsg))            # Show Error No. & Message
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
def db_update(wconn,wcur,wip,wzero,wname,wmac,wman,wping,wdateping,wdatechange):
    global pdebug

    # Update Server Row With Info collected from the sysinfo.txt file
    try:
        sql = "UPDATE server_network SET net_ip='%s', net_ip_wzero='%s', net_hostname='%s', \
              net_mac='%s', net_man='%s', net_ping='%s', net_date_ping='%s', net_date_update='%s' \
              where net_ip='%s' " % (wip,wzero,wname,wmac,wman,wping,wdateping,wdatechange,wip)
    except (TypeError, ValueError, IndexError) as error:                # Mismatch Between Num & Str
        enum, emsg = error.args                                         # Get Error No. & Message
        #enum=1
        #emsg=error                                                     # Get Error Message
        sa.write_log(">>>>>>>>>>>>> (%s) %s " % (enum,error))           # Print Error No. & Message
        sa.write_log("sql=%s" % (sql))
        return(1)                                                       # return (1) to indicate Err
    if pdebug > 4 : sa.write_log("sql=%s" % (sql))                      # Show SQL in Error

    # Execute the SQL Update Statement
    try:
        wcur.execute(sql)                                               # Update Server Data
        wconn.commit()                                                  # Commit the transaction
    except (pymysql.err.InternalError, pymysql.err.IntegrityError) as error:
        enum, emsg = error.args                                         # Get Error No. & Message
        sa.write_log("[ERROR] (%s) %s " % (enum,error))                 # Print Error No. & Message
        if pdebug > 4 : sa.write_log("sql=%s" % (sql))                  # Show SQL in Error
        wconn.rollback()                                                # RollBack Transaction
        return (1)                                                      # return (1) to indicate Err
    except Exception as error:
        enum, emsg = error.args                                         # Get Error No. & Message
        sa.write_log("[ERROR] (%s) %s " % (enum,error))                 # Print Error No. & Message
        if pdebug > 4 : sa.write_log("sql=%s" % (sql))                  # Show SQL in Error
        wconn.rollback()                                                # RollBack Transaction
        return (1)                                                      # return (1) to indicate Err
    return(0)                                                           # Return 0 = update went OK



#===================================================================================================
#                            Scan The Network Received (Example: "192.168.1.0/24")
#===================================================================================================
#
def scan_network(snet,wconn,wcur) :
    global pdebug

    # GET MAIN NETWORK INTERFACE NAME 
    cmd = "route -n |grep '^0.0.0.0' |awk '{ print $NF }'"              # Get Default Route DevName
    ccode,cstdout,cstderr = sa.oscommand(cmd)                           # Run the arp-scan command
    if (ccode != 0):                                                    # If Error running command
        sa.write_log ("Problem running : %s" & (cmd))                   # Show Command in Error
        sa.write_log ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))  # Write stdout & stderr
    else:                                                               # If netstat succeeded
        netdev=cstdout                                                  # Save Net. Interface Name
        sa.write_log ("Current host interface name     : %s" % (netdev)) # Show Interface selected

    # SHOW NUMBER OF IP IN NETWORK SUBNET
    NET4 = ipaddress.ip_network(snet)                                   # Create instance of network
    snbip = NET4.num_addresses                                          # Save Number of possible IP
    sa.write_log ("Possible IP on %s   : %s " % (snet,snbip))           # Show Nb. Possible IP

    # SHOW NETWORK NETMASK
    snetmask = NET4.netmask                                             # Save Network Netmask
    sa.write_log ("Network netmask                 : %s" % (snetmask))  # Show User Netmask

    # Run fping on Subnet and generate a file containing that IP of servers alive.
    fpingfile = "%s/fping.txt" % (sa.dir_net)                           # fping result file name
    cmd  = "fping -aq -r1 -g %s 2>/dev/null |tee %s" % (snet,fpingfile) # fping cmd
    sa.write_log ("\nRunning fping and output to %s" % (fpingfile))     # Show fping output filename
    if (pdebug > 4) : sa.write_log ("Command : %s" % (cmd))   
    ccode,fpinglist,cstderr = sa.oscommand(cmd)                         # Run the fping command
    if (ccode > 1):                                                     # If Error running command
        sa.write_log ("Problem running : %s" % (cmd))                   # Show Command in Error
        sa.write_log ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))  # Write stdout & stderr
        sys.exit(1)                                                     # Exit script with Error
    else: 
        sa.write_log ("The fping finished with success.\n")             # Show Command Success
    fp = open(fpingfile,'r')
    ping_array = fp.read()
    #print("The Array is: \n", ping_array) #printing the array
    # ITERATING THROUGH THE USABLE ADDRESSES ON A NETWORK:
    for ip in NET4.hosts():                                             # Loop through possible IP
        hip = str(ipaddress.ip_address(ip))                             # Save processing IP
        try :                                                           # Try Get Hostname of the IP
            (hname,halias,hiplist)   = socket.gethostbyaddr(hip)        # Get IP DNS Name
            if pdebug > 4 : sa.write_log ("hname = %s, Alias = %s, IPList = %s" % (hname,halias,hiplist))
        except socket.herror as e:                                      # If IP has no Name
            hname = ""                                                  # Clear IP Hostname

        # Is the IP is in the ping (fping) active list ?
        search_ip = "%s\n" % hip
        #print("The search ip is : ...%s...\n" % (search_ip)) 
        if search_ip in ping_array:
            hactive = 1                                                 # IP is reachable
            sa.write_log("%-16s fping say it is active" % (hip))   
        else: 
            hactive = 0                                                 # IP is not Reachable
            sa.write_log("%-16s fping say it isn't active" % (hip)) 

        # Get the Mac Address of IP
        hmac = ''                                                       # Clear Work Mac Address
        hmac = get_mac_address(ip=hip, network_request=True)            # Get Mac Address of IP 
        if pdebug > 4 : print ( "get_mac_address returned .%s." % (hmac)) # Show debug info
        if hmac == "00:00:00:00:00:00" : hmac=""                        # If can't get Mac Address
        if pdebug > 4 : print ( "The working Mac is : .%s." % (hmac))     # Print Final hmac Content

        # Create an IP field with leading zero
        (ip1,ip2,ip3,ip4) = hip.split('.')                              # Split IP Address
        zip = "%03d.%03d.%03d.%03d" % (int(ip1),int(ip2),int(ip3),int(ip4)) # Ip with Leading Zero

        # Card manufacturer
        hmanu = ''                                                      # Clear Work Vendor

        # Format info and insert it in the 'netdict' array
        WLINE = "%s,%s,%s,%s,%d" % (zip, hname, hmac, hmanu, hactive)   # Format Output file Line
        netdict[hip] = WLINE                                            # Put Line in Dictionary
        if (pdebug > 4) : sa.write_log ("Put %s info '%s' in array" % (hip,WLINE))

        # Verify if IP is in the SADMIN database
        if (pdebug > 4) : sa.write_log("Checking if IP '%s' exist in database" % (hip))   
        (dberr,dbrow) = db_readkey(wconn,wcur,hip,True)                 # Read IP Row if Exist
        if (dberr != 0):                                                # If IP Not in Database
            if (pdebug > 4) : sa.write_log("IP %s doesn't exist in database" % (hip)) # Advise Usr of flow
            cdata = [hip,zip,hname,hmac,hmanu,hactive]                  # Data to Insert
            dberr = db_insert(wconn,wcur,hip,cdata,False)               # Insert New IP in Table
            if (dberr != 0) :                                           # Did the insert went well ?
                sa.write_log("[ Error ] %d adding '%s' to database" % (dberr,hip))
            else :
                sa.write_log("[ OK ] %s inserted in database" % (hip))
                if (pdebug > 4) :
                    sa.write_log("Data inserted: IP:%s Host:%s Mac:%s Vend:%s Active:%d" 
                    % (hip,hname,hmac,hmanu,hactive))
            continue                                                    # Continue with next IP

        # IP was found - Get existing IP data
        #pdb.set_trace()                                                # Activate Python debugging
        row_hostname = dbrow['net_hostname']                            # Save Hostname
        row_mac      = dbrow['net_mac']                                 # Save DB Mac Adress
        row_manu     = dbrow['net_man']                                 # Save DB Vendor
        row_ping     = dbrow['net_ping']                                # Save Last Ping Result(0,1)
        row_pingdate = dbrow['net_date_ping']                           # Save Last Ping Date
        row_datechg  = dbrow['net_date_update']                         # Save Last Mac/Name Chg Date
        if (pdebug > 4) :
            sa.write_log("Actual data in Database: host:%s, Mac:%s, Ping:%s, DatePing:%s, DateUpdate:%s" 
            % (row_hostname,row_mac,row_ping,row_pingdate,row_datechg))
        wdate = time.strftime('%Y-%m-%d %H:%M:%S')                      # Format Current Date & Time

        # If IP Pingable save ping date and ping status
        if (hactive == 1) :                                             # If IP is pingable now
            row_ping = 1                                                # Update Row Ping Info work
            sa.write_log("%-16s Ping worked, update ping date from %s to %s" % (hip,row_pingdate,wdate))
            row_pingdate = wdate                                        # Update Last Ping Date
        else:
            row_ping = 0                                                # Upd. Row Info not pingable
            sa.write_log("%-16s Ping didn't worked, leave last ping date as it is." % (hip))


        # If MAC have changed, update MAC and last change date/time.
        if row_mac != hmac :                                            # If MAC Changed
            if hmac == "" or hmac is None :                             # If No MAC (No card)
                sa.write_log("%-16s No MAC address for the moment" % (hip))
            else:
                if hmac is not None : 
                    sa.write_log("%-16s >>>> Mac address changed from '%s' to '%s'" % (hip,row_mac,hmac))
                    row_datechg = wdate                                 # MAC Changed Upd. Date Chng
                    row_mac = hmac                                      # Update IP Mac Address
                else :
                    sa.write_log("%-16s Keep old mac at '%s' since new mac is '%s'" % (hip,row_mac,hmac))
        else :
            sa.write_log ("%-16s No MAC address changed ('%s')" % (hip,hmac))
    
        # If actual hostname is different from the last execution, update last change date
        if (row_hostname != hname):
            sa.write_log("%-16s >>>> Host Name changed from '%s' to '%s'" % (hip,row_hostname,hname))
            row_datechg = wdate                                         # Hostname Chg Upd Date Chng
            row_hostname = hname                                        # Update IP new hostname

        # GO UPDATE DATABASE
        if (pdebug > 4) : sa.write_log ("Updating '%s' data" % (hip))
        dberr = db_update(wconn,wcur,hip,zip,row_hostname,row_mac,row_manu,row_ping,row_pingdate,row_datechg)
        if (dberr != 0) :                                               # If no Error updating IP
            sa.write_log("%-16s [ ERROR ] Updating databse" % (hip))    # Advise User Update Error
        else :
            if (pdebug > 4) : 
                sa.write_log("Update: IP:%s Host:%s Mac.%s Vend:%s Active:%d PingDate:%s ChangeDate:%s" 
                % (hip,row_hostname,row_mac,row_manu,row_ping,row_pingdate,row_datechg))
            sa.write_log("%-16s [ OK ] Database updated\n" % (hip))       # Advise User Update Error
    
    #close(fp)
    return(0)                                                           # Return to Caller

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main_process(wconn,wcur):
    global pdb_conn, pdb_cur , pdebug                                 # DB Connection & Cursor
    
    if pdebug > 4 : sa.write_log("Processing Network1 = _%s_" % (sa.sadm_network1))
    if (sa.sadm_network1 != "") :
        scan_network(sa.sadm_network1,wconn,wcur)                     # Network Subnet 1 to report

    if pdebug > 4 : sa.write_log("Processing Network2 = _%s_" % (sa.sadm_network2))
    if (sa.sadm_network2 != "") :
        scan_network(sa.sadm_network2,wconn,wcur)                     # Network Subnet 2 to report

    if pdebug > 4 : sa.write_log("Processing Network3 = _%s_" % (sa.sadm_network3))
    if (sa.sadm_network3 != "") :
        scan_network(sa.sadm_network3,wconn,wcur)                     # Network Subnet 3 to report

    if pdebug > 4 : sa.write_log("Processing Network4 = _%s_" % (sa.sadm_network4))
    if (sa.sadm_network4 != "") :
        scan_network(sa.sadm_network4,wconn,wcur)                     # Network Subnet 4 to report

    if pdebug > 4 : sa.write_log("Processing Network5 = _%s_" % (sa.sadm_network5))
    if (sa.sadm_network5 != "") : scan_network(sa.sadm_network5)       # Network Subnet 5 to report

    return(0)




# Command line Options
# --------------------------------------------------------------------------------------------------
def cmd_options(argv):
    """ Command line Options functions - Evaluate Command Line Switch Options

        Args:
            (argv): Arguments pass on the comand line.
              [-d 0-9]  Set Debug (verbose) Level
              [-h]      Show this help message
              [-v]      Show script version information
        Returns:
            sadm_debug (int)          : Set to the debug level [0-9] (Default is 0)
    """

    sadm_debug = 0                                                      # Script Debug Level (0-9)
    parser = argparse.ArgumentParser(description=pdesc)                 # Desc. is the script name

    # Declare Arguments
    parser.add_argument("-v",
                        action="store_true",
                        dest='version',
                        help="Show script version")
    parser.add_argument("-d",
                        metavar="0-9",
                        type=int,
                        dest='sadm_debug',
                        help="debug/verbose level from 0 to 9",
                        default=0)
    
    args = parser.parse_args()                                          # Parse the Arguments

    # Set return values accordingly.
    if args.sadm_debug:                                                 # Debug Level -d specified
        sadm_debug = args.sadm_debug                                    # Save Debug Level
        print("Debug Level is now set at %d" % (sadm_debug))            # Show user debug Level
    if args.version:                                                    # If -v specified
        sa.show_version(pver)                                           # Show Custom Show Version
        sys.exit(0)                                                     # Exit with code 0
    return(sadm_debug)                                                  # Return opt values




#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main(argv):
    global pdb_conn, pdb_cur                                            # DB Connection & Cursor
    pdebug = cmd_options(argv)                                          # Analyse cmdline options

    pexit_code = 0                                                      # Pgm Exit Code Default
    sa.start(pver, pdesc)                                               # Initialize SADMIN env.
    if sa.get_fqdn() == sa.sadm_server and sa.db_used :                 # On SADMIN srv & usedb True
        (pexit_code, pdb_conn, pdb_cur) = sa.db_connect('sadmin')       # Connect to SADMIN Database
        if pexit_code == 0:                                             # If Connection to DB is OK
           pexit_code = main_process(pdb_conn, pdb_cur)                 # Use Subnet in sadmin.cfg
           sa.db_close(pdb_conn, pdb_cur)                               # Close connection to DB
    sa.stop(pexit_code)                                                 # Gracefully exit SADMIN
    sys.exit(pexit_code)                                                # Back to O/S with Exit Code

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)
