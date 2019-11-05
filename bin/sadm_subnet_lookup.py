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
# 2018_04_08    v1.0 Initial Beta version
# 2018_04_11    v1.1 Output File include MAC,Manufacturer
# 2018_04_13    v1.3 Manufacturer Info Expanded and use fping to check if host is up
# 2018-04-17    v1.4 Added update to server_network table in Mariadb
# 2018-04-18    v1.5 Fix problem updating Mac Address in Database when it could not be detected on nect run.
# 2018-04-26    v1.7 Show Some Messages only with DEBUG Mode ON & Bug fixes
# 2018-06_06    v1.8 Small Corrections
# 2018-06_09    v1.9 Change Script name to sadm_subnet_lookup
# 2018-09_22    v2.0 Fix Problem with Updating Last Ping Date
# 2018-11_09    v2.1 DataBase Connect/Disconnect revised.
# 2019_03_30 Fix: v2.2 Fix problem reading the fping result, database update fix.
#@2019_11_05 Update: v2.3 Restructure code for performance.
# --------------------------------------------------------------------------------------------------
#
try :
    import os,time,sys,pdb,socket,datetime,pwd,grp,pymysql,subprocess,ipaddress # Import Std Modules
    SADM = os.environ.get('SADMIN')                                     # Get SADMIN Root Dir. Name
    sys.path.insert(0,os.path.join(SADM,'lib'))                         # Add SADMIN to sys.path
    import sadmlib_std as sadm                                          # Import SADMIN Python Libr.
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                        # Activate Python Debugging



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
    st.ver              = "2.3"                 # Current Script Version
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

    # Get Main Network Interface Name of this host (from route table)-------------------------------
    cmd = "netstat -rn |grep '^0.0.0.0' |awk '{ print $NF }'"           # Get Default Route DevName
    ccode,cstdout,cstderr = oscommand(cmd)                              # Run the arp-scan command
    if (ccode != 0):                                                    # If Error running command
        st.writelog ("Problem running : %s" & (cmd))                    # Show Command in Error
        st.writelog ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))   # Write stdout & stderr
    else:                                                               # If netstat succeeded
        netdev=cstdout                                                  # Save Net. Interface Name
        st.writelog ("Current host interface name     : %s" % (netdev)) # Show Interface selected


    # Print Number of IP in Network Subnet----------------------------------------------------------
    NET4 = ipaddress.ip_network(snet)                                   # Create instance of network
    snbip = NET4.num_addresses                                          # Save Number of possible IP
    st.writelog ("Possible IP on %s   : %s " % (snet,snbip))            # Show Nb. Possible IP


    # Print the Network Netmask of Subnet-----------------------------------------------------------
    snetmask = NET4.netmask                                             # Save Network Netmask
    st.writelog ("Network netmask                 : %s" % (snetmask))   # Show User Netmask


    # Open Network Output Result File (Read by Web Interface)
    (wnet,wmask) = snet.split('/')                                      # Split Network & Netmask
    OFILE = 'network_' + wnet + '_' + wmask + '.txt'                    # Output file name
    SFILE = st.net_dir + '/' + OFILE                                    # Build Full Path FileName
    st.writelog ("Output Network Information file : %s" % (SFILE))      # Show Output file name
    try :
        OUT=open(SFILE,'w')                                             # Open Output Subnet File
    except Exception:                                                   # If Error opening file
        st.writelog ("Error creating output file %s" % (SFILE))         # Error Msg if open failed
        sys.exit(1)                                                     # Exit Script with Error


    # Run fping on Subnet and generate a file containing that IP of servers alive.
    # Example of output from fping (After running cmd):
    #   192.168.1.1 is alive
    #   192.168.1.5 is alive
    #   192.168.1.6 is alive
    fpingfile = "%s/fping.txt" % (st.net_dir)                           # fping result file name
    cmd  = "fping -i 1 -g %s 2>/dev/null | grep -i alive | tee %s" % (snet,fpingfile) # fping cmd
    st.writelog ("\nThe fping output file           : %s" % (fpingfile)) # Show fping output filename
    if (DEBUG) :
        st.writelog ("Command : %s" % (cmd))   
    ccode,fpinglist,cstderr = oscommand(cmd)                            # Run the fping command
    if (ccode > 1):                                                     # If Error running command
        st.writelog ("Problem running : %s" % (cmd))                    # Show Command in Error
        st.writelog ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))   # Write stdout & stderr
        sys.exit(1)                                                     # Exit script with Error
    else: 
        st.writelog ("The fping finished with success.")                # Show Command Success


    # Run arp-scan command to create Arp file (MAC Address and Network Interface Manufacturer)
    # The output fields are separated by a single tab character.
    # Example of Output (';'delimited file) after running customized command (cmd) is :
    #   <IP Address>   <Hardware Address>   <Vendor Details>
    #   192.168.1.44;b8:27:eb:9e:77:81;Raspberry Pi Foundation
    #   192.168.1.45;a0:99:9b:08:f5:11;Apple, Inc.
    #   192.168.1.31;b8:27:eb:48:73:c2;Raspberry Pi Foundation
    (ip1,ip2,ip3,ip4) = wnet.split('.')                                 # Split Network IP
    arpfile = "%s/arp-scan.txt" % (st.net_dir)                          # arp result file name
    cmd  = "arp-scan --interface=%s %s | " % (netdev,snet)              # arp-scan command
    cmd += " tr '\\t' ';' | grep '^%s'> %s" % (ip1,arpfile)             # Replace Tab by ; 
    st.writelog ("\nThe arp-scan output file        : %s" % (arpfile))  # Show arp-scan IP+Mac Addr.
    ccode,cstdout,cstderr = oscommand(cmd)                              # Run the arp-scan command
    if (ccode != 0):                                                    # If Error running command
        st.writelog ("Problem running : %s" % (cmd))                    # Show Command in Error
        st.writelog ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))   # Write stdout & stderr
        sys.exit(1)                                                     # Exit script with Error
    else:
        st.writelog ("The arp-scan finished with success.")             # Show Command Success



    # Opening Arp file, read all file into memory
    try:                                                                # Try Opening arp-scan file
        f = open(arpfile, "r")                                          # Open result arp-scan file
    except Exception:                                                   # If Error opening file
        st.writelog("Error opening arp-scan result file %s" % (arpfile))# Error Msg if open failed
        sys.exit(1)                                                     # Exit Script with Error
    arplines = f.readlines()                                            # Read all lines put in list
    f.close()                                                           # Close Arp Result file
    st.writelog(' ')                                                    # Space line
    st.writelog('----------')                                           # Space line


    # Iterating through the usable addresses on a network:
    for ip in NET4.hosts():                                             # Loop through possible IP
        hip = str(ipaddress.ip_address(ip))                             # Save processing IP
        if (DEBUG) :
            st.writelog ("\n----------\nProcessing IP %s" % (hip))
        try :                                                           # Try Get Hostname of the IP
            (hname,halias,hiplist)   = socket.gethostbyaddr(hip)        # Get IP DNS Name
            if (DEBUG) :
                st.writelog ("hname = %s, Alias = %s, IPList = %s" % (hname,halias,hiplist))
        except socket.herror as e:                                      # If IP has no Name
            hname = ""                                                  # Clear IP Hostname
        hmac = ''                                                       # Clear Work Mac Address
        hmanu = ''                                                      # Clear Work Vendor
        for arpline in arplines:                                        # Loop through arp file
            if (arpline.split(';')[0] == hip) :                         # Found Cur. IP in arp file
                hmac  = arpline.split(';')[1]                           # Save Mac Address
                hmanu = arpline.split(';')[2]                           # Save Manufacturer
                hmanu = hmanu.rstrip('\n')                              # Remove NewLine
                hmanu = hmanu.replace(',', '')                          # Remove comma from Vendor
                break                                                   # Break out of loop

        if (DEBUG) :
            st.writelog ("Is ip %s alive in fpinglist ?" % (hip))
        hactive = 0                                                     # Default Card is inactive
        if ("%s is alive" % (hip) in fpinglist) : hactive = 1           # Ip Is Pingable
        if (DEBUG) :
            if (hactive !=0):
                st.writelog ("Yes it is - Responded to ping")
            else:
                st.writelog ("Not it isn't - No ping response")

        (ip1,ip2,ip3,ip4) = hip.split('.')                              # Split IP Address
        zip = "%03d.%03d.%03d.%03d" % (int(ip1),int(ip2),int(ip3),int(ip4)) # Ip with Leading Zero
        WLINE = "%s,%s,%s,%s,%d" % (zip, hname, hmac, hmanu, hactive)   # Format Output file Line
        netdict[hip] = WLINE                                            # Put Line in Dictionary
        if (DEBUG) :
            st.writelog ("Info build from arp-scan & fping for %s is %s" % (hip,WLINE))


        # Verify if IP is in Database Network Table
        if (DEBUG) :
            st.writelog("Verifying if IP '%s' exist in database" % (hip)) # Show IP were looking for
        (dberr,dbrow) = db_readkey(st,wconn,wcur,hip,True)              # Read IP Row if Exist

        # IP was not found in Database
        if (dberr != 0):                                                # If IP Not in Database
            if (DEBUG) : st.writelog("IP %s doesn't exist in database" % (hip)) # Advise Usr of flow
            cdata = [hip,zip,hname,hmac,hmanu,hactive]                  # Data to Insert
            dberr = db_insert(st,wconn,wcur,hip,cdata,False)            # Insert Data in Cat. Table
            if (dberr != 0) :                                           # Did the insert went well ?
                st.writelog("Error %d adding '%s' to database" % (dberr,hip))  # Show Error & Mess.
            continue                                                    # Continue with next IP

        # Record was found - Save actual row information
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

        # Update IP Ping Status
        if (hactive == 1) :                                             # If IP is pingable
            row_pingdate = wdate                                        # Update Last Ping Date
            row_ping = True                                             # Update Row Ping Info
            st.writelog("%-17s - Ping work - Change last ping date." % (hip)) # Advise User
        else:
            row_ping = False                                            # Update Row Ping Info

        # If MAC have changed and new MAC is not blank then update last change date.
        if (row_mac != hmac) :                                          # If MAC Change
            if (hmac == "") :                                           # If No New MAC
                st.writelog("%-17s - Keep old mac at '%s' since new mac is '%s'" % (hip,row_mac,hmac))
            else:
                st.writelog("%-17s - Mac Address changed from '%s' to '%s'" % (hip,row_mac,hmac))
                row_datechg = wdate                                     # MAC Changed Upd. Date Chng
                row_mac = hmac                                          # Update IP Mac Address
    
        # If HostName of the IP have changed, update last change date.
        if (row_hostname != hname):
            st.writelog("%-17s - Host Name changed from '%s' to '%s'" % (hip,row_hostname,hname))
            row_datechg = wdate                                         # Hostname Chg Upd Date Chng
            row_hostname = hname                                        # Update IP new hostname

        # If Manufacturer Changed
        if (row_manu != hmanu):
            if (hmac == "") :                                           # If No New MAC
                st.writelog("%-17s - Keep old Vendor at '%s' since new vendor is '%s'" % (hip,row_manu,hmanu))
            else:
                st.writelog("%-17s - Device vendor changed from '%s' to '%s'" % (hip,row_manu,hmanu))
                row_datechg = wdate                                     # MAC Changed Upd. Date Chng
                row_manu = hmanu                                        # Update IP Mac Address

        # Go Update Database
        if (DEBUG) : st.writelog ("Updating '%s' data" % (hip))
        dberr = db_update(st,wconn,wcur,hip,zip,row_hostname,row_mac,row_manu,row_ping,row_pingdate,row_datechg)
        if (dberr != 0) :                                               # If no Error updating IP
            st.writelog("[ERROR] Updating IP '%s'" % (hip))             # Advise User Update Error


    # Loop through the dictionnary create and write value to output file
    for k, v in netdict.items():                                        # For every line in dict
        if (DEBUG) : st.writelog("Key: {0}, Value: {1}".format(k, v)) # Under Debug print out Line
        OUT.write ("%s,%s\n" % (v,k))                                   # Dict Value to Output File
    OUT.close()                                                         # Close Output File

    # Make Sure $SADMIN/www/dat/`hostname -s`/net Directory exist
    cmd = "mkdir -p %s" % st.www_net_dir
    ccode,cstdout,cstderr = oscommand(cmd)                              # Run the arp-scan command

    # Create Sorted Output file in www/dat/`hostname`/net
    NFILE = st.www_net_dir + '/' + OFILE                                # Sorted Full Path FileName
    st.writelog (" ")                                                   # Blank Line
    st.writelog ("Sort %s to %s" % (SFILE,NFILE))                       # Show what we are doing
    cmd  = "sort %s > %s" % (SFILE,NFILE)                               # Sort file by IP
    ccode,cstdout,cstderr = oscommand(cmd)                              # Run the arp-scan command
    if (ccode != 0):                                                    # If Error running command
        st.writelog ("Problem running : %s" & (cmd))                    # Show Command in Error
        st.writelog ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))   # Write stdout & stderr
        sys.exit(1)                                                     # Exit script with Error

    st.writelog ("Change file owner and group to %s.%s" % (st.cfg_www_user, st.cfg_www_group))
    wuid = pwd.getpwnam(st.cfg_www_user).pw_uid                         # Get UID User of Wev User
    wgid = grp.getgrnam(st.cfg_www_group).gr_gid                        # Get GID User of Web Group
    os.chown(NFILE,wuid,wgid)                                           # Change owner/group of file

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
