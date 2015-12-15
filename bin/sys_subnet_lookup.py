#!/usr/bin/python
#############################################################################################
#   Author:     Jacques Duplessis
#   Title:      ping_lookup.py
#   Synopsis:   ping and name lookup of the subnet selected
#               print result for each ip address
#############################################################################################
# Description
#   Run Daily
#
#############################################################################################
import os, time, sys, pdb, socket, datetime

#############################################################################################
#                                      Global Variables
#############################################################################################
CURDIR      = os.getcwd()                           # Get Current Directory
OSTYPE      = os.name                               # Get OS name (nt,dos,posix,...)
PLATFORM    = sys.platform                          # Get current platform (win32,mac,posix)
HOSTNAME    = socket.gethostname()                  # Get current hostname
PGM_VER     = "1.1"                                 # Program Version
PGM_NAME    = os.path.basename(sys.argv[0])         # Program name
PGM_ARGS    = len(sys.argv)                         # Nb. argument receive
CNOW        = datetime.datetime.now()               # Get Current Time
CURDATE     = CNOW.strftime("%Y.%m.%d")             # Format Current date
CURTIME     = CNOW.strftime("%H:%M:%S")             # Format Current Time
BASEDIR     = '/sysinfo/www'                        # Base Dir.
TMP_DIR     = BASEDIR + '/data/net/'                # Where outfile will be
#pdb.set_trace()

# Subnet to Scan
SUBNET= ['192.168.1' ]

#############################################################################################
#                                   M a i n   P r o g r a m   
#############################################################################################
print "Program %s Version %s - Starting %s-%s" % (PGM_NAME, PGM_VER, CURDATE, CURTIME)

for net in SUBNET:
   SFILE = TMP_DIR  + 'subnet_' + net + '.txt'
   print "Opening %s" % SFILE
   SH=open(SFILE,'w')                              # Open Output Subnet File
   for host in range(1,254):
      ip = net + '.' + str(host)
      rc = os.system("ping -c 1 " + ip + " > /dev/null 2>&1")
      if ( rc == 0 ) : 
         host_state = 'Yes'
      else :
        host_state = 'No'
        
      try:
      	line = socket.gethostbyaddr(ip)
        hostname = line[0]
      except:
	    hostname = ' ' 
	  #line = os.popen("host " + ip + " | tail -1").read()
      #aline = line.split(' ')
      #hostname = aline[4].rstrip()
      #if ( hostname == "3(NXDOMAIN)" )
      #   hostname = ' '
      
      WLINE = ""
      WLINE +=  "%s, %s, %s" % (ip, host_state, hostname)
      print "%s" % WLINE
      SH.write ("%s\n" % (WLINE))

   SH.close()                                      # Close Subnet File
print "Program %s Version %s - Ended  %s-%s" % (PGM_NAME, PGM_VER, CURDATE, CURTIME)
exit
