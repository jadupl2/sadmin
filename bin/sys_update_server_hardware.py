#!/usr/bin/python
#############################################################################################
#   Author:     Jacques Duplessis
#   Title:      update_server_hardware.py
#   Synopsis:   Read hardware file (hwinfo_*) and update server table
#############################################################################################
# Description
#   Run Daily
#
#############################################################################################
#
import MySQLdb, os, sys, pdb, socket, datetime, glob
#pdb.set_trace()
#############################################################################################
#                          Global Variables
#############################################################################################
CURDIR      = os.getcwd()                           # Get Current Directory
OSNAME      = os.name                               # Get OS name (nt,dos,posix,...)
PLATFORM    = sys.platform                          # Get current platform (win32,mac,posix)
HOSTNAME    = socket.gethostname()                  # Get current hostname
PGM_VER     = "1.5"                                 # Program Version
PGM_NAME    = os.path.basename(sys.argv[0])         # Program name
PGM_ARGS    = len(sys.argv)                         # Nb. argument receive
CNOW        = datetime.datetime.now()               # Get Current Time
CURDATE     = CNOW.strftime("%Y.%m.%d")             # Format Current date
CURTIME     = CNOW.strftime("%H:%M:%S")             # Format Current Time

# Base Directory
BASEDIR     = '/sysinfo/www/data/hw'                # Base Dir. where Data is

# Database information
print "%s" % HOSTNAME


db_server   = 'sysinfo.maison.ca'
db_user     = 'root'
db_passwd   = 'holmes'
db_name     = 'sysinfo'

# Debug Flag - Acticate/Deactivate extra output for debugging
#DEBUG      = False
DEBUG       = True

# ------------------------------------------------------------------------------
#                        Open DataBase Connection
# ------------------------------------------------------------------------------
#def open_database(w_server, w_user, w_passwd, w_name ):
#
#
#   #except:
##   #   print "Error: Unable to open database",w_name
#   return


# ------------------------------------------------------------------------------
#             Process each hwinfo* file in $BASEDIR and update Database
# ------------------------------------------------------------------------------
def update_db():
   try :
      db = MySQLdb.connect(db_server, db_user, db_passwd, db_name )
   except MySQLdb.Error, e:
      raise e

   # prepare a cursor object using cursor() method
   cursor = db.cursor()
   # Prepare SQL query to INSERT a record into the database.
   #sql = "SELECT * FROM servers"

   HWINFO = BASEDIR + "/hwinfo_*.txt"
   for filename in glob.glob(HWINFO):

      print "\nProcessing : " + filename
      HW = open(filename,'rU' )                          # Open Hardware file
      for hwline in HW:                                  # Loop until file is process
         print "Processing line : " + hwline.strip()
         hwarray       =  hwline.split(';')              # Split line based on ;
         hw_osname     =  hwarray[0].capitalize()        # Servername OS
         hw_servername =  hwarray[1]                     # Servername

         #pdb.set_trace()
         # OS Version
         try :
            (hw_osver1,hw_osver2,hw_osver3)=hwarray[2].split('.')
            hw_osver1     = int(hw_osver1)
            hw_osver2     = int(hw_osver2)
            hw_osver3     = int(hw_osver3)
         except :
            hw_osver1     = int(0)
            hw_osver2     = int(0)
            hw_osver3     = int(0)

         hw_model      =  hwarray[3]                     # Hardware model
         hw_serial     =  hwarray[4]                     # Hardware serial
         wint          =  hwarray[5].replace('MB','')    # Hardware Memory
         if (wint.strip() == '') :                       # if no Memory specify
            hhw_memory  = 0                              # Default Memory=0
         else:
            hw_memory = int(wint)                        # Use Hardware Memory

         # Number of CPU
         if (hwarray[6].strip() == ''):                  # If Nb CPU not specify
            hw_cpu_nb = 1                                # Assume 1 CPU
         else :
            hw_cpu_nb =  int(hwarray[6])                 # Number of CPU specify

         # CPU Speed
         try :
            wfloat  =  hwarray[7].replace('MHz','')         # Remove MHZ from CPU Speed
            if (wfloat.strip() == '') :                     # If no CPU speed specify
               hw_cpu_speed  = 0                            # Default = 0
            else :
               hw_cpu_speed = int(wfloat)                   # CPU Speed
         except :
            hw_cpu_speed = int(0)

         # Internal Disk
         wint =  hwarray[8].replace('GB','')             # Internal Disk
         if (wint.strip() == '') :                       # No internal disk space
            hw_disk_int   =  0                           # Default = 0 Gb
         else :
            hw_disk_int = int(wint)                      # Use Internal Disk
         wint =  hwarray[9].replace('GB','')             # External Disk
         if (wint.strip() == '') :                       # No Disk space specify
            hw_disk_ext   =  0                           # Default is 0 GB
         else :
            hw_disk_ext = int(wint)                      # External Disk Specify

         # VMware
         try :
            hw_vmware =  int(hwarray[10])                   # VMWare=0
         except :
            hw_vmware = int(0)

         # ETH0
         try :
            if ( len(hwarray[11]) == 0  ):
               hw_ip1a=int(0)
               hw_ip1b=int(0)
               hw_ip1c=int(0)
               hw_ip1d=int(0)
            else:
               (hw_ip1a,hw_ip1b,hw_ip1c,hw_ip1d)=hwarray[11].split('.')
               hw_ip1a = int(hw_ip1a)
               hw_ip1b = int(hw_ip1b)
               hw_ip1c = int(hw_ip1c)
               hw_ip1d = int(hw_ip1d)
         except :
               hw_ip1a=int(0)
               hw_ip1b=int(0)
               hw_ip1c=int(0)
               hw_ip1d=int(0)

         # ETH1
         try :
             if ( len(hwarray[12]) == 0 ):
                hw_ip2a=int(0)
                hw_ip2b=int(0)
                hw_ip2c=int(0)
                hw_ip2d=int(0)
             else:
                (hw_ip2a,hw_ip2b,hw_ip2c,hw_ip2d)=hwarray[12].split('.')   # Split eth1 IP
                hw_ip2a = int(hw_ip2a)
                hw_ip2b = int(hw_ip2b)
                hw_ip2c = int(hw_ip2c)
                hw_ip2d = int(hw_ip2d)
         except :
                hw_ip2a=int(0)
                hw_ip2b=int(0)
                hw_ip2c=int(0)
                hw_ip2d=int(0)

         # ETH2
         try :
             if ( len(hwarray[13]) == 0 ):
                hw_ip3a=int(0)
                hw_ip3b=int(0)
                hw_ip3c=int(0)
                hw_ip3d=int(0)
             else:
                (hw_ip3a,hw_ip3b,hw_ip3c,hw_ip3d)=hwarray[13].split('.')   # Split eth1 IP
                hw_ip3a = int(hw_ip3a)
                hw_ip3b = int(hw_ip3b)
                hw_ip3c = int(hw_ip3c)
                hw_ip3d = int(hw_ip3d)
         except :
                hw_ip3a=int(0)
                hw_ip3b=int(0)
                hw_ip3c=int(0)
                hw_ip3d=int(0)

         # 32 or 64 Bits 0=32 1=64)
         #print "hwarray[14] = %d" % int(hwarray[14])
         try :
             if (int(hwarray[14]) == 64) :
                hw_bits=1
             else :
                hw_bits=0
         except :
                hw_bits=0

         # Use AD 1=Yes 0=No
         try :
            hw_use_ad =  int(hwarray[15])
         except :
            hw_use_ad = int(0)

         # Collect TSM Version
         try :
            hw_tsm_ver =  hwarray[16]
         except :
            hw_tsm_ver =  "N/A"

         # Collect TSM TDP Version
         try :
            hw_tsm_tdp =  hwarray[17]
         except :
            hw_tsm_tdp =  "N/A"

         print "server_name      = %s" % hw_servername
         print "server_os        = %s" % hw_osname
         print "server_vm        = %d" % hw_vmware
         print "server_osver1    = %d" % hw_osver1
         print "server_osver2    = %d" % hw_osver2
         print "server_osver3    = %d" % hw_osver3
         print "server_model     = %s" % hw_model
         print "server_serial    = %s" % hw_serial
         print "server_cpu_nb    = %d" % hw_cpu_nb
         print "server_cpu_speed = %d" % hw_cpu_speed
         print "server_disk_int  = %d" % hw_disk_int
         print "server_disk_ext  = %d" % hw_disk_ext
         print "server_memory    = %s" % hw_memory
         print "server_ip1a      = %d" % hw_ip1a
         print "server_ip1b      = %d" % hw_ip1b
         print "server_ip1c      = %d" % hw_ip1c
         print "server_ip1d      = %d" % hw_ip1d
         print "server_ip2a      = %d" % hw_ip2a
         print "server_ip2b      = %d" % hw_ip2b
         print "server_ip2c      = %d" % hw_ip2c
         print "server_ip2d      = %d" % hw_ip2d
         print "server_ip3a      = %d" % hw_ip3a
         print "server_ip3b      = %d" % hw_ip3b
         print "server_ip3c      = %d" % hw_ip3c
         print "server_ip3d      = %d" % hw_ip3d
         print "server_bits      = %d" % hw_bits
         print "server_use_as    = %d" % hw_use_ad
         print "server_tsm_ver   = %s" % hw_tsm_ver
         print "server_tsm_tdp   = %s" % hw_tsm_tdp


#         # Setup SQL Update Statement
         sql = "UPDATE servers SET server_os='%s', server_vm='%d', server_osver1='%d', server_osver2='%d', server_osver3='%d', \
                    server_model='%s',  server_serial='%s', server_cpu_nb='%d', server_cpu_speed='%d',\
                    server_disk_int='%d', server_disk_ext='%d', server_memory='%d', server_ip1a='%d', server_ip1b='%d', server_ip1c='%d',\
                    server_ip1d='%d', server_ip2a='%d', server_ip2b='%d', server_ip2c='%d', server_ip2d='%d', server_ip3a='%d', \
                    server_ip3b='%d', server_ip3c='%d', server_ip3d='%d', server_bits='%d', server_use_ad='%d', server_tsm_ver='%s', server_tsm_tdp='%s' \
                where server_name='%s';" % \
                (hw_osname, \
                hw_vmware, \
                hw_osver1, hw_osver2,   hw_osver3, \
                hw_model,  \
                hw_serial, \
                hw_cpu_nb, \
                hw_cpu_speed,\
                hw_disk_int, \
                hw_disk_ext, \
                hw_memory, \
                hw_ip1a, hw_ip1b, hw_ip1c, hw_ip1d, \
                hw_ip2a, hw_ip2b, hw_ip2c, hw_ip2d, \
                hw_ip3a, hw_ip3b, hw_ip3c, hw_ip3d, \
                hw_bits, hw_use_ad, hw_tsm_ver, hw_tsm_tdp, \
                hw_servername);
         print "SQL = %s " % sql;

         try:
            cursor.execute(sql)
            db.commit()
            print "Transaction Submitted with Success for " + hw_servername
         except:
            db.rollback()
            print "Error - Rolling Back transaction for " + hw_servername
      HW.close()                             # Close Hardware info file
   db.close()
   return



# ------------------------------------------------------------------------------
#                     M A I N     P R O G R A M
# ------------------------------------------------------------------------------
#
def main():
   update_db()
   return


# ------------------------------------------------------------------------------
# This idiom means the below code only runs when executed from command line
# ------------------------------------------------------------------------------
if __name__ == '__main__':
    main()


