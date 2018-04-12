#!/usr/bin/env python3  
#===================================================================================================
#   Author:     Jacques Duplessis
#   Title:      sadm_network_inventory.py
#   Synopsis:   ping and do a nslookup on all IP in the subnet and produce a report
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
# --------------------------------------------------------------------------------------------------
# 
try :
    import os,time,sys,pdb,socket,datetime,pwd,grp,subprocess,ipaddress # Import Std Python3 Modules
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
DEBUG = True                                                            # Activate Debug (Verbosity)
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



#===================================================================================================
#                            Scan The Network Received (Example: "192.168.1.0/24")
#===================================================================================================
#
def scan_network(st,snet) :
    if DEBUG : st.writelog ("In 'scan_network', parameter received : %s" % (snet))

    # Get Main Network Interface Name (from route table)
    cmd = "netstat -rn |grep '^0.0.0.0' |awk '{ print $NF }'"           # Get Main Network Interface 
    ccode,cstdout,cstderr = oscommand(cmd)                              # Run the arp-scan command
    if (ccode != 0):                                                    # If Error running command
        st.writelog ("Problem running : %s" & (cmd))                    # Show Command in Error
        st.writelog ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))   # Write stdout & stderr
    else:                                                               # If netstat succeeded
        netdev=cstdout                                                  # Save Net. Interface Name
        st.writelog ("Current host interface name     : %s" % (netdev)) # Show Interface selected

    # Print Number of IP in Network - Based on network and Netmask in sadmin.cfg
    NET4 = ipaddress.ip_network(snet)                                   # Create instance of network
    snbip = NET4.num_addresses                                          # Save Number of possible IP
    st.writelog ("Possible IP on %s   : %s " % (snet,snbip))            # Show Nb. Possible IP

    # Print the Network Netmask
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
        st.writelog ("Problem running : %s" & (cmd))                    # Show Command in Error
        st.writelog ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))   # Write stdout & stderr
        sys.exit(1)                                                     # Exit script with Error
    
    # Opening Arp file, read all file into memory
    try:                                                                # Try Opening arp-scan file
        f = open(arpfile, "r")                                          # Open result arp-scan file
    except Exception:                                                   # If Error opening file
        st.writelog("Error opening arp-scan result file %s" % (arpfile))# Error Msg if open failed
        sys.exit(1)                                                     # Exit Script with Error
    lines = f.readlines()                                               # Read all lines put in list
    f.close()                                                           # Close Arp Result file


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
        hactive = 'N'                                                   # Default Card is inactive
        for arpline in lines:                                           # Loop through arp file
            if (arpline.split(' ')[0] == hip) :                         # Found Cur. IP in arp file
                hmac  = arpline.split(' ')[1]                           # Save Mac Address
                hmanu = arpline.split(' ')[2]                           # Save Card Manufacturer
                hmanu = hmanu.rstrip(',\n')                             # Remove command & NewLine
                hactive = 'Y'                                           # IP Responded .. Active
                break                                                   # Break out of loop
        (ip1,ip2,ip3,ip4) = hip.split('.')                              # Split IP
        zip = "%03d.%03d.%03d.%03d" % (int(ip1),int(ip2),int(ip3),int(ip4)) # Build Ip Addr with ZeroIP
        WLINE = "%s,%s,%s,%s,%s" % (zip, hname, hmac, hmanu, hactive)   # Format Output file Line
        netdict[hip] = WLINE                                            # Put Line in Dictionary

    # Loop through the dictionnary create and write value to output file
    for k, v in netdict.items():                                        # For every line in dict
        if (DEBUG) : st.writelog("Key : {0}, Value : {1}".format(k, v)) # Under Debug print out Line
        OUT.write ("%s,%s\n" % (v,k))                                   # Dict Value to Output File
    OUT.close()                                                         # Close Output File

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
    
    # # Copy the resultant output file into the SADM Web Net Data Directory
    # st.writelog (" ")                                                   # Blank Line
    # st.writelog ("Copy %s to %s" % (SFILE,st.www_net_dir))              # Show what we copy
    # rc = os.system("cp " + SFILE + " " + st.www_net_dir + " >/dev/null 2>&1") # Do Actual Copy      
    # if ( rc != 0 ) :                                                    # If error occurs on copy
    #     st.writelog ("Can't copy %s to %s" % (SFILE,st.www_net_dir))    # Show User Error
    #     return (1)                                                      # Return Error to Caller
    st.writelog ("Change file owner and group to %s.%s" % (st.cfg_www_user, st.cfg_www_group))
    wuid = pwd.getpwnam(st.cfg_www_user).pw_uid                         # Get UID User of Wev User 
    wgid = grp.getgrnam(st.cfg_www_group).gr_gid                        # Get GID User of Web Group 
    os.chown(NFILE,wuid,wgid)                                           # Change owner/group of file

    return(0)                                                           # Return to Caller

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main_process(st) :

    if (DEBUG): st.writelog("Processing Network1 = _%s_" % (st.cfg_network1))
    if (st.cfg_network1 != "") : scan_network(st,st.cfg_network1)       # Network Subnet 1 to report
        
    if (DEBUG): st.writelog("Processing Network2 = _%s_" % (st.cfg_network2))
    if (st.cfg_network2 != "") : scan_network(st,st.cfg_network2)       # Network Subnet 2 to report
        
    if (DEBUG): st.writelog("Processing Network3 = _%s_" % (st.cfg_network3))
    if (st.cfg_network3 != "") : scan_network(st,st.cfg_network3)       # Network Subnet 3 to report
        
    if (DEBUG): st.writelog("Processing Network4 = _%s_" % (st.cfg_network4))
    if (st.cfg_network4 != "") : scan_network(st,st.cfg_network4)       # Network Subnet 4 to report
        
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
    st.ver  = "1.1"                             # Indicate this script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'B'                           # Log Type  (L=Log file only  S=stdout only  B=Both)
    st.log_append = True                        # True=Append existing log  False=start a new log
    st.cfg_mail_type = 1                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    st.usedb = False                            # True=Use Database  False=DB Not needed for script
    st.dbsilent = False                         # Return Error Code & False=ShowErrMsg True=NoErrMsg
    #st.cfg_mail_addr = ""                      # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name  = ""                      # This Override Company Name specify in sadmin.cfg
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..
    if st.debug > 4: st.display_env()           # Under Debug - Display All Env. Variables Available 

    
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
        
        
    st.exit_code = main_process(st)                                     # Process Subnet
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
