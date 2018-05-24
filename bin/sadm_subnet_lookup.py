#!/usr/bin/env python3  
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_subnet_lookup.py
#   Synopsis:   arp-scan, dns lookup of all IP specify in sadmin.cfg and produce file use by web 
#               interface
#===================================================================================================
# Description
#  This script ping and do a nslookup for every IP specify in the "SUBNET" Variable.
#  Result of each subnet is recorded in their own file ${SADM_BASE_DIR}/dat/net/subnet_SUBNET.txt
#  These file are used by the Web Interface to inform user what IP is free and what IP is used.
#  On the Web interface the file can be seen by selecting the IP Inventory page.
#  It is run once a day from the crontab.
#
# --------------------------------------------------------------------------------------------------
# 8 April 2018
#   V1.0 Initial Beta version
# 11 April 2018
#   V1.1 Output File include MAC,Manufacturer
# 13 April 2018
#   V1.3 Manufacturer Info Expanded and use fping to check if host is up
# 2018-04-17 JDuplessis
#   V1.4 Added update to server_network table in Mariadb
# 2018-04-18 JDuplessis
#   V1.5 Fix problem updating Mac Address in Database when it could not be detected on nect run.
# 2018-04-26 JDuplessis
#   V1.7 Show Some Messages only with DEBUG Mode ON & Bug fixes
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
DEBUG = False                                                            # Activate Debug (Verbosity)
netdict = {}                                                            # Network Work Dictionnary


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
    if (DEBUG) :
        print ("In sadm_oscommand function stdout is      : %s" % (out))
        print ("In sadm_oscommand function stderr is      : %s " % (err))
        print ("In sadm_oscommand function returncode is  : %s" % (returncode))
    return (returncode,out,err)


# ----------------------------------------------------------------------------------------------
# READ IP KEY IN SERVER_NETWORK TABLE 
# Return 2 parameters :
#   1 = Error Code (0=found 1=NotFound)
#   2 = If Row was found then return row data as a tuple.
#       If Row was not found 'None' is returned as the second parameter
# ----------------------------------------------------------------------------------------------
def db_readkey(st,wconn,wcur,tbkey,dbsilent):


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
# return (0) if no error - return (1) if error encountered
#
# Example of tbdata received
# ['192.168.1.1','192.168.001.001','Router','b8:27:eb:9e:77:81','Y',\
#   '2018-04-18 21:09:58','2018-04-18 21:09:58']
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

    # Run arp-scan command to create Arp file (MAC Address and Network Interface Manufacturer)
    (ip1,ip2,ip3,ip4) = wnet.split('.')                                 # Split Network IP
    arpfile = "%s/arp-scan.txt" % (st.net_dir)                          # arp result file name
    cmd  = "arp-scan --interface=%s %s | " % (netdev,snet)              # arp-scan command
    cmd += "awk -F'\t' '{ print $1,$2,$3 }' | tr -d ',' |grep '^%s'> %s" % (ip1,arpfile)  # Format Result output
    st.writelog ("The arp-scan output file        : %s" % (arpfile))    # Show arp-scan IP+Mac Addr.
    ccode,cstdout,cstderr = oscommand(cmd)                              # Run the arp-scan command
    if (ccode != 0):                                                    # If Error running command
        st.writelog ("Problem running : %s" % (cmd))                    # Show Command in Error
        st.writelog ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))   # Write stdout & stderr
        sys.exit(1)                                                     # Exit script with Error

    # Run fping on Subnet and generate a file containing that IP of servers alive.
    fpingfile = "%s/fping.txt" % (st.net_dir)                           # fping result file name
    cmd  = "fping -g %s 2>/dev/null | grep -i alive "  % (snet)         # fping command
    st.writelog ("The fping output file           : %s" % (fpingfile))  # Show fping output filename 
    ccode,fpinglist,cstderr = oscommand(cmd)                            # Run the fping command
        
    # Opening Arp file, read all file into memory
    try:                                                                # Try Opening arp-scan file
        f = open(arpfile, "r")                                          # Open result arp-scan file
    except Exception:                                                   # If Error opening file
        st.writelog("Error opening arp-scan result file %s" % (arpfile))# Error Msg if open failed
        sys.exit(1)                                                     # Exit Script with Error
    lines = f.readlines()                                               # Read all lines put in list
    f.close()                                                           # Close Arp Result file
    st.writelog(' ')                                                    # Space line
    st.writelog('----------')                                           # Space line

    # Iterating through the “usable” addresses on a network:
    for ip in NET4.hosts():                                             # Loop through possible IP
        hip = str(ipaddress.ip_address(ip))                             # Save processing IP 
        try :                                                           # Try Get Hostname of the IP
            (hname,halias,hiplist)   = socket.gethostbyaddr(hip)        # Get IP DNS Name
            #print ("hname = %s, Alias = %s, IPList = %s" % (hname,halias,hiplist))
        except socket.herror as e:                                      # If IP has no Name
            hname = ""                                                  # Clear IP Hostname
        hmac = ''                                                       # Clear Work Mac Address
        hmanu = ''                                                      # Clear Work Manufacturer
        for arpline in lines:                                           # Loop through arp file
            if (arpline.split(' ')[0] == hip) :                         # Found Cur. IP in arp file
                hmac  = arpline.split(' ')[1]                           # Save Mac Address
                arpline = arpline.replace (hip ,  "%s," % (hip))
                arpline = arpline.replace (hmac , "%s," % (hmac))
                hmanu = arpline.split(',')[2]                           # Save Manufacturer
                hmanu = hmanu.rstrip(',\n')                             # Remove command & NewLine
                break                                                   # Break out of loop
        hactive = 0                                                     # Default Card is inactive
        if (hip in fpinglist) : hactive = 1                             # Ip Is Pingable
        (ip1,ip2,ip3,ip4) = hip.split('.')                              # Split IP
        zip = "%03d.%03d.%03d.%03d" % (int(ip1),int(ip2),int(ip3),int(ip4)) # Build Ip Addr with ZeroIP
        WLINE = "%s,%s,%s,%s,%d" % (zip, hname, hmac, hmanu, hactive)   # Format Output file Line
        netdict[hip] = WLINE                                            # Put Line in Dictionary

        if (DEBUG) :
            st.writelog(' ')                                            # Space line
            st.writelog("Verifying if IP '%s' exist in database" % (hip)) # Show IP were looking for 
        (dberr,dbrow) = db_readkey(st,wconn,wcur,hip,True)              # Read IP Row if Exist
        if (dberr != 0):                                                # If IP Not in Database
            if (DEBUG) : st.writelog("IP %s doesn't exist in database" % (hip)) # Advise Usr of flow
            cdata = [hip,zip,hname,hmac,hmanu,hactive]                  # Data to Insert
            dberr = db_insert(st,wconn,wcur,hip,cdata,False)            # Insert Data in Cat. Table
            if (dberr != 0) :                                           # Did the insert went well ?
                st.writelog("Error %d adding '%s' to database" % (dberr,hip))  # Show Error & Mess.
        else :
            old_hostname    = dbrow[2]
            old_mac         = dbrow[3]
            old_ping        = dbrow[5]
            wdateping       = dbrow[6]
            wdatechange     = dbrow[7]
            if (DEBUG) :
                st.writelog("OLD - hostname %s, Mac %s, Ping %s, DatePing %s, DateUpdate %s" % (old_hostname,old_mac,old_ping,wdateping,wdatechange))
            wdate = time.strftime('%Y-%m-%d %H:%M:%S')                  # Save Current Date & Time
            if ((old_ping != hactive) and (hactive != 0)) : 
                st.writelog("IP %s ping was %s now is %s" % (hip,old_ping,hactive))
                wdateping = wdate
                st.writelog("Ping Date Updated")
                wdatechange = wdate
            if (old_mac != hmac) :
                if (hmac == "") :
                    st.writelog("%s Leave old mac at '%s' since new mac is '%s'" % (hip,old_mac,hmac))
                    hmac = old_mac
                else:
                    st.writelog("%s - Mac Address changed from '%s' to '%s'" % (hip,old_mac,hmac))
                    wdatechange = wdate
            if (old_hostname != hname):
                st.writelog("IP %s Host Name changed from '%s' to '%s'" % (hip,old_hostname,hname))
                wdatechange = wdate
            if (DEBUG) : st.writelog ("Updating '%s' data" % (hip))
            dberr = db_update(st,wconn,wcur,hip,zip,hname,hmac,hmanu,hactive,wdateping,wdatechange) 
            if (dberr != 0) :                                           # If no Error updating IP
                st.writelog("[ERROR] Updating IP '%s'" % (hip))         # Advise User Update Error
                

    # Loop through the dictionnary create and write value to output file
    for k, v in netdict.items():                                        # For every line in dict
        #if (DEBUG) : st.writelog("Key: {0}, Value: {1}".format(k, v)) # Under Debug print out Line
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
    # SADMIN TOOLS - Create SADMIN instance & setup variables specific to your program -------------
    st = sadm.sadmtools()                       # Create SADMIN Tools Instance (Setup Dir.)
    st.ver  = "1.7"                             # Indicate this script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'B'                           # Log Type  (L=Log file only  S=stdout only  B=Both)
    st.log_append = True                        # True=Append existing log  False=start a new log
    st.cfg_mail_type = 1                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    st.usedb = False                            # True=Use Database  False=DB Not needed for script
    st.dbsilent = False                         # Return Error Code & False=ShowErrMsg True=NoErrMsg
    #st.cfg_mail_addr = ""                      # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name  = ""                      # This Override Company Name specify in sadmin.cfg
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..


    
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
        
    (conn,cur) = st.dbconnect()                                         # Connect to SADMIN Database
    st.exit_code = main_process(conn,cur,st)                            # Use Subnet in sadmin.cfg 
    st.dbclose()                                                        # Close the Database
    st.stop(st.exit_code)                                               # Close SADM Environment
    
# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
