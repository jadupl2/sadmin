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
# --------------------------------------------------------------------------------------------------
# 
try :
    import os,time,sys,pdb,socket,datetime,subprocess,ipaddress         # Import Std Python3 Modules
    SADM = os.environ.get('SADMIN')                                     # Getting SADMIN Root Dir. Name
    sys.path.insert(0,os.path.join(SADM,'lib'))                         # Add SADMIN to sys.path
    import sadmlib_std as sadm                                          # Import SADMIN Python Library
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
pdb.set_trace()                                                        # Activate Python Debugging


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
    if DEBUG : print ("In 'scan_network', parameter received : %s" % (snet))

    # Print Number of IP in Network
    net4 = ipaddress.ip_network(snet)
    print ("We have %d IP's in Network %s" % (net4.num_addresses,snet))

    # Print the Network Netmask
    print ("The Network Netmask is %s" % (net4.netmask))

    # Open Network Outpur Result File
    (wnet,wmask) = snet.split('/')                                      # Split Network & Netmask
    SFILE = st.net_dir + '/network_' + wnet + '_' + wmask + '.txt'      # Construct Subnet FileName
    if DEBUG : print ("The output network info file is %s" % (SFILE))   # Show Output file name
    OUT=open(SFILE,'w')                                                  # Open Output Subnet File

    # Run arp-scan command to get MAC Address of IP when available 
    (ip1,ip2,ip3,ip4) = wnet.split('.')                                 # Split Network IP
    arpfile = "%s/arp-scan.txt" % (st.net_dir)                          # arp result file name
    cmd  = "arp-scan --interface=em1 %s | " % (snet)                    # arp-scan command
    cmd += "awk '{ print $1,$2,$3 }' | grep '^%s'> %s" % (ip1,arpfile)  # Format Result output
    if DEBUG : print ("The arp-scan output file is %s" % (arpfile))     # Show arp-scan IP+Mac Addr.
    ccode,cstdout,cstderr = oscommand(cmd)                              # Run the arp-scan command
    if (ccode != 0):                                                    # If Error running command
        writelog ("Problem running : %s" & (cmd))                       # Show Command in Error
        writelog ("Stdout : %s \nStdErr : %s" % (cstdout,cstderr))      # Write stdout & stderr
    
    # Opening Arp file, read all file into memory
    try:                                                                # Try Opening arp-scan file
        f = open(arpfile, "r")
    except Exception:                                                   # If Error opening file
        print("Error opening file %s" % (arpfile))                      # Error Msg if open failed
    lines = f.readlines()                                               # Read all lines put in list
    f.close()                                                           # Close Arp Result file

    # Iterating through the “usable” addresses on a network:
    for ip in net4.hosts():
        addr4 = ipaddress.ip_address(ip)
        dip   = str(addr4)

        # Get Mac Address from arp-scan file
        hmac = ''
        hinfo = ''
        hactive = 'N'
        for wip in lines:
            print ("dip = %s wip line = %s" % (dip,wip))
            #print ("wip[0] = ..%s.. ..%s.." % (wip[0],dip)) 
            if (wip[0] == dip) : 
                hmac = wip[1] 
                hinfo = wip[2]
                hactive = 'Y'
                break

        # Get the Hostname of the IP
        try :
            (hname,xalias,iplist)   = socket.gethostbyaddr(dip)  
        except socket.herror as e:
            hname = ""

        # 
        dline = [ ]
        dline = [ hname, hmac, hinfo, hactive ]
        print("dline = %s" % (dline))
        netdict[dip] = dline
        print ("netdict[%s] = " % (dip) + str(netdict[dip]))


    # Print the IP Dictionnary Build from Info collected
    if DEBUG : 
        for ip in net4.hosts():
            addr4 = ipaddress.ip_address(ip)
            dip     = str(addr4)
            print ("netdict[%s] = " % (dip) + str(netdict[dip]))


    OUT.close()                                                         # Close Output File
    return(0)

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main_process(st) :

    if (DEBUG): print("Network1 = _%s_" % (st.cfg_network1))
    if (st.cfg_network1 != "") : scan_network(st,st.cfg_network1)       # Network Subnet 1 to report
        
    if (DEBUG): print("Network2 = _%s_" % (st.cfg_network2))
    if (st.cfg_network2 != "") : scan_network(st,st.cfg_network2)       # Network Subnet 2 to report
        
    if (DEBUG): print("Network3 = _%s_" % (st.cfg_network3))
    if (st.cfg_network3 != "") : scan_network(st,st.cfg_network3)       # Network Subnet 3 to report
        
    if (DEBUG): print("Network4 = _%s_" % (st.cfg_network4))
    if (st.cfg_network4 != "") : scan_network(st,st.cfg_network4)       # Network Subnet 4 to report
        
    if (DEBUG): print("Network5 = _%s_" % (st.cfg_network5))
    if (st.cfg_network5 != "") : scan_network(st,st.cfg_network5)       # Network Subnet 5 to report
        

# Obtaining the netmask (i.e. set bits corresponding to the network prefix) or the hostmask (any bits that are not part of the netmask):

# >>>
# >>> net4 = ipaddress.ip_network('192.0.2.0/24')
# >>> net4.netmask
# IPv4Address('255.255.255.0')

# Other modules that use IP addresses (such as socket) usually won’t accept objects from this module directly. Instead, they must be coerced to an integer or string that the other module will accept:

# >>>
# >>> addr4 = ipaddress.ip_address('192.0.2.1')
# >>> str(addr4)
# '192.0.2.1'
# >>> int(addr4)
# 3221225985




#        for host in range(1,255):                                        # Define Range IP in Subnet
#           ip = net + '.' + str(host)                                    # Cronstruct IP Address
#           rc = os.system("ping -c 1 " + ip + " > /dev/null 2>&1")       # Ping THe IP Address
#           if ( rc == 0 ) :                                              # Ping Work
#              host_state = 'Yes'                                         # State = Yes = Alive
#           else :                                                        # Ping don't work
#             host_state = 'No'                                           # State = No = No response
        
#           try:
#             line = socket.gethostbyaddr(ip)                             # Try to resolve IP Address
#             hostname = line[0]                                          # Save DNS Name 
#           except:
#        	    hostname = ' '                                              # No Name = Clear Name

#           WLINE = "%s, %s, %s" % (ip, host_state, hostname)
#           st.writelog ("%s" % WLINE)
#           print ("%s" % WLINE)
#           SH.write ("%s\n" % (WLINE))
       
#        SH.close()                                                       # Close Subnet File
      
#        # Copy the resultant subnet txt file into the SADM Web Data Directory
#        st.writelog ("Copy %s into %s" % (SFILE,st.www_net_dir))
#        rc = os.system("cp " + SFILE + " " + st.www_net_dir + " >/dev/null 2>&1")       
#        if ( rc != 0 ) :                                                  
#             st.writelog ("ERROR : Could not copy %s into %s" % (SFILE,st.www_net_dir))
#             return (1)
#        st.writelog ("Change file owner and group to %s.%s" % (st.cfg_www_user, st.cfg_www_group))
#        wuid = pwd.getpwnam(st.cfg_www_user).pw_uid                      # Get UID User of Wev User 
#        wgid = grp.getgrnam(st.cfg_www_group).gr_gid                     # Get GID User of Web Group 
#        os.chown(st.www_net_dir + '/subnet_' + net + '.txt', wuid, wgid) # Change owner of Subnet 

    return(0)



#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    # SADMIN TOOLS - Create SADMIN instance & setup variables specific to your program -------------
    st = sadm.sadmtools()                       # Create SADMIN Tools Instance (Setup Dir.)
    st.ver  = "1.00"                            # Indicate this script Version 
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
