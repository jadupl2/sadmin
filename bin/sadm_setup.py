#!/usr/bin/env python3
# ==================================================================================================
#   Author      :   Jacques Duplessis
#   Date        :   2017-09-09
#   Name        :   sadm_setup.py
#   Synopsis    :
#   Licence     :   You can redistribute it or modify under the terms of GNU General Public 
#                   License, v.2 or above.
# ==================================================================================================
#   Copyright (C) 2016-2017 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is a free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2018_01_18 JDuplessis 
#   V1.0 Initial Version
#   V1.0b WIP Version#   
# 2018_02_23 JDuplessis
#   V1.1 First Beta Version 
# 2018_02_26 JDuplessis
#   V1.2 Second Beta Version 
#
#===================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,glob,fnmatch,shutil # Import Std Python3 Modules
    from subprocess import Popen, PIPE
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                    # Activate Python Debugging


#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
pn                  = os.path.basename(sys.argv[0])                     # Program name
inst                = os.path.basename(sys.argv[0]).split('.')[0]       # Pgm name without Ext
conn                = ""                                                # MySQL Database Connector
cur                 = ""                                                # MySQL Database Cursor
sadm_base_dir       = ""                                                # SADMIN Install Directory
sver                = "1.2"
DEBUG               = False                                              # Debug Activated or Not
#
sroot               = ""                                                # SADMIN Root Directory
fhlog               = ""

# Command require by SADMIN to be able to work correctly
reqdict = {}                                                            # Requirement Package Dict.
reqdict = { 
    'lsb_release':{ 'rpm':'redhat-lsb-core',                'rrepo':'base',  
                    'deb':'lsb_release',                    'drepo':'base'},
    'nmon'       :{ 'rpm':'nmon',                           'rrepo':'epel',  
                    'deb':'nmon',                           'drepo':'base'},
    'ethtool'    :{ 'rpm':'ethtool',                        'rrepo':'base',  
                    'deb':'ethtool',                        'drepo':'base'},
    'ifconfig'   :{ 'rpm':'net-tools',                      'rrepo':'base',  
                    'deb':'net-tools',                      'drepo':'base'},
    'lshw'       :{ 'rpm':'lshw',                           'rrepo':'base',  
                    'deb':'lshw',                           'drepo':'base'},
    'parted'     :{ 'rpm':'parted',                         'rrepo':'base',  
                    'deb':'parted',                         'drepo':'base'},
    'mail'       :{ 'rpm':'mailx',                          'rrepo':'base',
                    'deb':'mailutils',                      'drepo':'base'},
    'facter'     :{ 'rpm':'facter',                         'rrepo':'epel',  
                    'deb':'facter',                         'drepo':'base'},
    'bc'         :{ 'rpm':'bc',                             'rrepo':'base',  
                    'deb':'bc',                             'drepo':'base'},
    'fdisk'      :{ 'rpm':'util-linux',                     'rrepo':'base',  
                    'deb':'util-linux',                     'drepo':'base'},
    'ssh'        :{ 'rpm':'openssh-clients',                'rrepo':'base',
                    'deb':'openssh-client',                 'drepo':'base'},
    'dmidecode'  :{ 'rpm':'dmidecode',                      'rrepo':'base',
                    'deb':'dmidecode',                      'drepo':'base'},
    'perl'       :{ 'rpm':'perl',                           'rrepo':'base',  
                    'deb':'perl-base',                      'drepo':'base'},
    'lscpu'      :{ 'rpm':'util-linux',                     'rrepo':'base',  
                    'deb':'util-linux',                     'drepo':'base'},
    'httpd'      :{ 'rpm':'httpd httpd-tools',              'rrepo':'base',
                    'deb':'apache2 apache2-utils',          'drepo':'base'},
    'php'        :{ 'rpm':'php php-mysql php-common',       'rrepo':'base', 
                    'deb':'php php-mysql php-common',       'drepo':'base'},
    'mysql'      :{ 'rpm':'mariadb-server MySQL-python',    'rrepo':'base',
                    'deb':'mariadb-server mariadb-client',  'drepo':'base'}, 
    'cfg2html'   :{ 'rpm':'cfg2html',                       'rrepo':'local',
                    'deb':'cfg2html',                       'drepo':'base'},
    'datetime'   :{ 'rpm':'perl-DateTime',                  'rrepo':'base',
                    'deb':'libdatetime-perl libwww-perl',   'drepo':'base'}
}



# ----------------------------------------------------------------------------------------------
#                                     Text Colors Attributes Class
# ----------------------------------------------------------------------------------------------
class color:
    PURPLE      = '\033[95m'
    CYAN        = '\033[96m'
    DARKCYAN    = '\033[36m'
    BLUE        = '\033[94m'
    GREEN       = '\033[92m'
    YELLOW      = '\033[93m'
    RED         = '\033[91m'
    BOLD        = '\033[1m'
    UNDERLINE   = '\033[4m'
    END         = '\033[0m'

#===================================================================================================
#                Display Error Message in Red & Bold to catch user attention
#===================================================================================================
def showerror(emsg):
    print ( color.RED + color.BOLD + emsg + color.END)


#===================================================================================================
#                Display Highlight Message in YELLOW & Bold to catch user attention
#===================================================================================================
def showwarning(emsg):
    print ( color.YELLOW + color.BOLD + emsg + color.END)

# ----------------------------------------------------------------------------------------------
#                         Write Log to Log File, Screen or Both
# ----------------------------------------------------------------------------------------------
def writelog(sline):
    global fhlog                                                        # Log file handler

    now = datetime.datetime.now()
    logLine = now.strftime("%Y.%m.%d %H:%M:%S") + " - %s" % (sline)
    fhlog.write ("%s\n" % (logLine))
    print ("%s" % logLine) 


#===================================================================================================
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
#===================================================================================================
def oscommand(command) :
    if DEBUG : print ("In sadm_oscommand function to run command : %s" % (command))
    p = Popen(command, stdout=PIPE, stderr=PIPE, shell=True)
    out = p.stdout.read().strip().decode()
    err = p.stderr.read().strip().decode()
    returncode = p.wait()
    if (DEBUG) :
        print ("In sadm_oscommand function stdout is      : %s" % (out))
        print ("In sadm_oscommand function stderr is      : %s " % (err))
        print ("In sadm_oscommand function returncode is  : %s" % (returncode))
    #if returncode:
    #    raise Exception(returncode,err)
    #else :
    return (returncode,out,err)



# --------------------------------------------------------------------------------------------------
#       THIS FUNCTION VERIFY IF THE COMMAND RECEIVED IN PARAMETER IS AVAILABLE ON THE SERVER 
# --------------------------------------------------------------------------------------------------
def locate_command(lcmd) :
    COMMAND = "which %s" % (lcmd)                                       # Build the which command
    if (DEBUG): print ("O/S command : %s " % (COMMAND))                 # Under Debug print cmd   
    ccode,cstdout,cstderr = oscommand(COMMAND)                          # Try to Locate Command
    if ccode is not 0 :                                                 # Command was not Found
        cmd_path=""                                                     # Cmd Path Null when Not fnd
    else :                                                              # If command Path is Found
        cmd_path = cstdout                                              # Save command Path
    return (cmd_path)                                                   # Return Cmd Path



# --------------------------------------------------------------------------------------------------
#       This function verify if the Package Received in parameter is available on the server 
# --------------------------------------------------------------------------------------------------
def locate_package(lpackage,lpacktype) :
    if (lostype == "AIX") : return                                      # Not yet implemented

    if (lpacktype == "deb") : 
        COMMAND = "dpkg-query -s %s  >/dev/null 2>&1" % (cmd)
    else:
        if (lpacktype == "rpm"):
            COMMAND = "rpm -qi %s >/dev/null 2>&1" % (cmd)
        else:
            print ("Package type (%s) not supported" % (lpacktype))
            cmd_path=''
            return

    if (DEBUG): print ("O/S command : %s " % (COMMAND))       
    ccode,cstdout,cstderr = oscommand(COMMAND)                          # Try to Locate Command

    # If the package is installed
    if ccode == 0 :                                                     # Command was Found
        print ("Package %s installed" % (lcmd)) 
        COMMAND = "which %s >/dev/null 2>&1"
        if (DEBUG): print ("O/S command : %s " % (COMMAND))       
        ccode,cstdout,cstderr = oscommand(COMMAND)                      # Try to Locate Command
        cmd_path = ''
        if (ccode != 0) :
            cmd_path = cstdout                                          # Save command Path
        return (cmd_path)

    # If package is not install, ask user if want to install it.
    if (lpacktype == "deb") : 
        print ("install debian package")
    else:
        print ("install rpm packages")

    return (cmd_path)                                                   # Return Cmd Path

#===================================================================================================
#                       S A T I S F Y    R E Q U I R E M E N T   F U N C T I O N 
#===================================================================================================
#
def satisfy_requirement(sroot,packtype):

    if (DEBUG) : print ("Package type on this system is %s" % (packtype))
    
    # If apt-file not install, install that command
    if ((packtype == "deb") and (locate_command('apt-file') == "")) :   # Is apt-file installed ?
        writelog ("Installing apt-file ...")
        oscommand("apt-get -y install apt-file >>%s 2>&1" % (logfile))
        
    if (DEBUG):                                                         # Under Debug Show Req Dict.
        for cmd,pkginfo in reqdict.items():
            print("\nTo use command '{0}' we need to install :" .format(cmd))
            print('RPM Repo:{0} - Package: {1} ' .format(pkginfo['rrepo'], pkginfo['rpm']))
            print('DEB Repo:{0} - Package: {1} ' .format(pkginfo['drepo'], pkginfo['deb']))

    # Process Package dictionary and check if command are install - If not install it
    for cmd,pkginfo in reqdict.items():
        needed_cmd = cmd
        if (packtype == "deb"):
            needed_packages = pkginfo['deb'] 
            needed_repo = pkginfo['drepo']
        else:
            needed_packages = pkginfo['rpm']
            needed_repo = pkginfo['rrepo']
        if (locate_command(needed_cmd) != ""):
            print (color.YELLOW + color.BOLD + "[OK] " + color.END,end='')
            print ("Command %s already installed" % (needed_cmd))
            continue
        print (color.YELLOW + color.BOLD + "[WARING] " + color.END,end='')
        print ("'%s' is missing, " % (needed_cmd),end='')
        print ("installation of '%s' package(s) " % (needed_packages),end='')
        print ("from the %s repository needed" % (needed_repo))
        if (packtype == "deb") :
            icmd = "apt-get -y install %s" % (needed_packages)
        if (packtype == "rpm") :
            icmd = "yum install -y install %s" % (needed_packages)
        print ("Command to execute %s" % (icmd))


#===================================================================================================
#        Specify and/or Validate that SADMIN Environment Variable is set in /etc/environent
#===================================================================================================
#
def set_sadmin_env(ver):
    print(chr(27) + "[2J")                                              # Clear the Screen
    print ("SADMIN Setup V%s\n------------------" % (ver))              # Print Version Number

    # Is SADMIN Environment Variable Defined ? , If not ask user to specify it
    if "SADMIN" in os.environ:                                          # Is SADMIN Env. Var. Exist?
        sadm_base_dir = os.environ.get('SADMIN')                        # Get SADMIN Base Directory
    else:                                                               # If Not Ask User Full Path
        sadm_base_dir = input("Enter directory path where your install SADMIN : ")

    # Does Directory specify exist ?
    if not os.path.exists(sadm_base_dir) :                              # Check if SADMIN Dir. Exist
        print ("Directory %s doesn't exist." % (sadm_base_dir))         # Advise User
        sys.exit(1)                                                     # Exit with Error Code

    # Check if Directory specify contain the Shell SADMIN Library (Indicate Dir. is the good one)
    libname="%s/lib/sadmlib_std.sh" % (sadm_base_dir)                   # Set Full Path to Shell Lib
    if os.path.exists(libname)==False:                                  # If SADMIN Lib Not Found
        print ("Directory %s isn't SADMIN directory" % (sadm_base_dir)) # Advise User Dir. Wrong
        print ("It doesn't contains the file %s" % (libname))           # Show Why we Refused
        sys.exit(1)                                                     # Exit with Error Code

    # Ok now we can Set SADMIN Environnement Variable, for the moment
    os.environ['SADMIN'] = sadm_base_dir                                # Setting SADMIN Env. Dir.

    # Now we need to make sure that 'SADMIN=' line is in /etc/environment (So it survive a reboot)
    fi = open('/etc/environment','r')                                   # Environment Input File
    fo = open('/etc/environment.new','w')                               # Environment Output File
    fileEmpty=True                                                      # Env. file assume empty
    eline = "SADMIN=%s\n" % (sadm_base_dir)                             # Line needed in /etc/env...
    for line in fi:                                                     # Read Input file until EOF
        if line.startswith( 'SADMIN=' ) :                               # line Start with 'SADMIN='?
           line = "%s" % (eline)                                        # Add line with needed line
        fo.write (line)                                                 # Write line to output file
        fileEmpty=False                                                 # File was not empty flag
    fi.close                                                            # File read now close it
    if (fileEmpty) :                                                    # If Input file was empty
        line = "%s\n" % (eline)                                         # Add line with needed line
        fo.write (line)                                                 # Write 'SADMIN=' Line
    fo.close                                                            # Close the output file
    try:                                                                # Will try rename env. file
        os.rename("/etc/environment","/etc/environment.org")            # Rename old to org
        os.rename("/etc/environment.new","/etc/environment")            # Rename new to real one
    except:
        print ("Error renaming /etc/environment")                       # Show User if error
        sys.exit(1)                                                     # Exit to O/S with Error
    print ("\n----------")
    MSG = "SADMIN Environment variable is set to %s" % (sadm_base_dir)
    print (color.YELLOW + color.BOLD + "[OK] " + color.END + MSG)    
    print ("      - The line below is in /etc/environment") 
    print ("      - %s" % (eline),end='')                               # SADMIN Line in /etc/env...
    print ("      - This will make sure it is set upon reboot")

    # Make sure we have a sadmin.cfg in $SADMIN/cfg, if not cp .sadmin.cfg to sadmin.update_sadmin_cfg
    cfgfile="%s/cfg/sadmin.cfg" % (sadm_base_dir)                       # Set Full Path to cfg File
    cfgfileo="%s/cfg/.sadmin.cfg" % (sadm_base_dir)                     # Set Full Path to cfg File
    if os.path.exists(cfgfile)==False:                                  # If sadmin.cfg Not Found
        try:
            shutil.copyfile(cfgfileo,cfgfile)                           # Copy Template 2 sadmin.cfg
        except IOError as e:
            print("Unable to copy file. %s" % e)                        # Advise user before exiting
            exit(1)                                                     # Exit to O/S With Error
        except:
            print("Unexpected error:", sys.exc_info())                  # Advise Usr Show Error Msg
            exit(1)                                                     # Exit to O/S with Error
        print ("Initial sadmin.cfg file in place.")                     # Advise User ok to proceed
    print ("----------")                                                # Dash Line
    return sadm_base_dir                                                # Return SADMIN Root Dir

#===================================================================================================
#                     Replacing Value in SADMIN configuration file (sadmin.cfg)
#               1st parameter = Name of setting    2nd parameter = Value of the setting
#===================================================================================================
#
def update_sadmin_cfg(sroot,sname,svalue):
    """
    [Update the SADMIN configuration File.]
    Arguments:
    sroot  {[string]}   --  [SADMIN root install directory]
    sname  {[string]}   --  [Name of variable in sadmin.cfg to change value]
    svalue {[string]}   --  [New value of the variable]
    """    
    wcfg_file = sroot + "/cfg/sadmin.cfg"                               # Actual sadmin config file
    wtmp_file = "%s/cfg/sadmin.tmp" % (sroot)                           # Tmp sadmin config file
    wbak_file = "%s/cfg/sadmin.bak" % (sroot)                           # Backup sadmin config file
    if (DEBUG) :
        print ("In update_sadmin_cfg - sname = %s - svalue = %s\n" % (sname,svalue))
        print ("\nwcfg_file=%s\nwtmp_file=%s\nwbak_file=%s" % (wcfg_file,wtmp_file,wbak_file))

    fi = open(wcfg_file,'r')                                            # Current sadmin.cfg File
    fo = open(wtmp_file,'w')                                            # Will become new sadmin.cfg
    lineNotFound=True                                                   # Assume String not in file
    cline = "%s = %s\n" % (sname,svalue)                                # Line to Insert in file

    # Replace Line Starting with 'sname' with new 'svalue' 
    for line in fi:                                                     # Read sadmin.cfg until EOF
        if line.startswith("%s" % (sname.upper())) :                    # Line Start with SNAME ?
           line = "%s" % (cline)                                        # Change Line with new one
           lineNotFound=False                                           # Line was found in file
        fo.write (line)                                                 # Write line to output file
    fi.close                                                            # File read now close it
    if (lineNotFound) :                                                 # SNAME wasn't found in file
        line = "%s\n" % (cline)                                         # Add needed line
        fo.write (line)                                                 # Write 'SNAME = SVALUE Line
    fo.close                                                            # Close the output file

    # Rename sadmin.cfg sadmin.bak
    try:                                                                # Will try rename env. file
        os.rename(wcfg_file,wbak_file)                                  # Rename Current to tmp
    except:
        print ("Error renaming %s to %s" % (wcfg_file,wbak_file))       # Advise user of problem
        sys.exit(1)                                                     # Exit to O/S with Error

    # Rename sadmin.tmp sadmin.cfg
    try:                                                                # Will try rename env. file
        os.rename(wtmp_file,wcfg_file)                                  # Rename tmp to sadmin.cfg
    except:
        print ("Error renaming %s to %s" % (wtmp_file,wcfg_file))       # Advise user of problem
        sys.exit(1)                                                     # Exit to O/S with Error



#===================================================================================================
#             Accept field receive as parameter and update the $SADMIN/cfg/sadmin.cfg file
#   1) Root Directory of SADMIN    2) Parameter name in sadmin.cfg    3) Default Value    
#   4) Prompt text                 5) Type of input ([I]nteger [A]lphanumeric) 
#   6) smin & smax = Minimum and Maximum value for integer prompt
#===================================================================================================
#
def accept_field(sroot,sname,sdefault,sprompt,stype="A",smin=0,smax=3):
    
    # Validate the type of input received (A for alphanumeric and I for Integer)
    if (stype.upper() != "A" and stype.upper() != "I") :                # Accept Alpha or Integer
        print ("The type of input received is invalid (%s)" % (stype))  # If Not A or I - Advise Usr
        print ("Expecting [I]nteger or [A]lphanumeric")                 # Question is Skipped
        return 1                                                        # Return Error to caller
 
    # Print Field name we will input (name used in sadmin.cfg file)
    print ("\n----------\n")                                            # Dash & Name of Field
    print (color.BOLD + "[%s]" % (sname) + color.END)                   # Attr. Name in sadmin

    # Display field documentation file  
    docname = "%s/doc/cfg/%s.txt" % (sroot,sname.lower())               # Set Documentation FileName
    try :                                                               # Try to Open Doc File
        doc = open(docname,'r')                                         # Open Documentation file
        for line in doc:                                                # Read Doc. file until EOF
            if line.startswith("#"):                                    # Does Line Start with #
               continue                                                 # Skip Line that start with#
            print ("%s" % (line),end='')                                # Print Documentation Line
        doc.close()                                                     # Close Document File
    except FileNotFoundError:                                           # If Open File Failed
        showerror ("Doc file %s not found, question skipped" % (docname)) # Advise User, Question Skip
    print (" ")                                                         # Print blank Line

    # Accept Alphanumeric Value from the user    
    if (stype.upper() == "A"):                                          # If Alphanumeric Input
        wdata=""
        while (wdata == ""):                                            # Input until something 
            wdata = input("%s %s : " % (sprompt,sdefault))              # Accept user response
            wdata = wdata.strip()                                       # Del leading/trailing space
            if (len(wdata) == 0) : wdata = sdefault                     # No Input = Default Value
            return wdata                                                # Return Data to caller

    # Accept Integer Value from the user    
    if (stype.upper() == "I"):                                          # If Numeric Input
        wdata = 0                                                       # Where response is store
        while True:                                                     # Loop until Valid response
            try:
                wdata = int(input("%s : " % (sprompt)))                 # Accept an Integer
            except (ValueError, TypeError) as error:                    # If Value is not an Integer
                showerror ("Not an integer!")                           # Advise User Message
                continue                                                # Continue at start of loop
            else:                                                       # If a Numeric Value Entered
                if (wdata > smax) or (wdata < smin):                    # Must be between min & max
                    showerror ("Value must be between %d and %d" % (smin,smax)) # Input out of Range 
                    continue                                            # Continue at start of loop
                else:                                                   # Input Respect the range
                    break                                               # Break out of the loop
    return wdata


#===================================================================================================
#                          M A I N     P R O C E S S     F U N C T I O N 
#===================================================================================================
#
def main_process(sroot):
    ccode, cstdout, cstderr = oscommand("uname -s")                     # Get O/S Type
    wostype=cstdout.upper()                                             # OSTYPE = LINUX or AIX
    if (DEBUG):                                                         # If Debug Activated
        print ("main_process: Directory SADMIN is %s" % (sroot))        # Show SADMIN root Dir.
        print ("ostype is: %s" % (wostype))                             # Print the O/S Type

    # Is the current server a SADMIN [S]erver or a [C]lient
    sdefault = "C"                                                      # This is the default value
    sname    = "SADM_HOST_TYPE"                                         # Var. Name in sadmin.cfg
    sprompt  = "Host will be a SADMIN [S]erver or a [C]lient (S,C)"     # Prompt for Answer
    wcfg_host_type = ""                                                 # Define Var. First
    while ((wcfg_host_type.upper() != "S") and (wcfg_host_type.upper() != "C")): # Loop until S or C
        wcfg_host_type = accept_field(sroot,sname,sdefault,sprompt)     # Go Accept Response 
    wcfg_host_type = wcfg_host_type.upper()                             # Make Host Type Uppercase
    update_sadmin_cfg(sroot,"SADM_HOST_TYPE",wcfg_host_type)            # Update Value in sadmin.cfg

    # Accept the Company Name
    sdefault = "Your Company Name"                                      # This is the default value
    sprompt  = "Host will be a SADMIN [S]erver or a [C]lient (S,C)"     # Prompt for Answer
    wcfg_cie_name = ""                                                  # Clear Cie Name
    while (wcfg_cie_name == ""):                                        # Until something entered
        wcfg_cie_name = accept_field(sroot,"SADM_CIE_NAME",sdefault,sprompt)# Accept Cie Name
    update_sadmin_cfg(sroot,"SADM_CIE_NAME",wcfg_cie_name)              # Update Value in sadmin.cfg

    # Accept SysAdmin Email address
    sdefault = ""                                                       # No default value
    sprompt  = "Enter System Administrator Email"                       # Prompt for Answer
    wcfg_mail_addr = ""                                                 # Clear Email Address
    while True :                                                        # Until Valid Email Address
        wcfg_mail_addr = accept_field(sroot,"SADM_MAIL_ADDR",sdefault,sprompt)
        x = wcfg_mail_addr.split('@')                                   # Split Email Entered 
        if (len(x) != 2):                                               # If not 2 fields = Invalid
            showerror ("Invalid email address - no '@' sign")           # Advise user no @ sign
            continue                                                    # Go Back Re-Accept Email
        try :
            xip = socket.gethostbyname(x[1])                            # Try Get IP of Domain
        except (socket.gaierror) as error :                             # If Can't - domain invalid
            showerror ("The domain %s is not valid" % (x[1]))           # Advise User
            continue                                                    # Go Back re-accept email
        break                                                           # Ok Email seem valid enough
    update_sadmin_cfg(sroot,"SADM_MAIL_ADDR",wcfg_mail_addr)            # Update Value in sadmin.cfg

    # Accept the Email type to use at the end of each sript execution
    sdefault = 1                                                        # Default value 1
    sprompt  = "Enter default email type"                               # Prompt for Answer
    wcfg_mail_type = accept_field(sroot,"SADM_MAIL_TYPE",sdefault,sprompt,"I",0,3)
    update_sadmin_cfg(sroot,"SADM_MAIL_TYPE",wcfg_mail_type)            # Update Value in sadmin.cfg

    # Accept the SADMIN FQDN Server name
    sdefault = ""                                                       # No Default value 
    sprompt  = "Enter SADMIN (FQDN) server name"                        # Prompt for Answer
    while True:                                                         # Accept until valid server
        wcfg_server = accept_field(sroot,"SADM_SERVER",sprompt,sprompt) # Accept SADMIN Server Name
        print ("Validating server name")                                # Advise User Validating
        try :
            xip = socket.gethostbyname(wcfg_server)                     # Try to get IP of Server
        except (socket.gaierror) as error :                             # Unable to get Server IP
            showerror ("Server Name %s isn't valid" % (wcfg_server))    # Advise user invalid Server
            continue                                                    # Go Re-Accept Server Name
        xarray = socket.gethostbyaddr(xip)                              # Use IP & Get HostName
        yname = repr(xarray[0]).replace("'","")                         # Remove the ' from answer
        if (yname != wcfg_server) :                                     # If HostName != EnteredName
            showerror ("The server %s with ip %s is returning %s" % (wcfg_server,xip,yname))
            showerror ("FQDN is wrong or the IP doesn't correspond")    # Advise USer 
            continue                                                    # Return Re-Accept SADMIN
        else:
            break                                                       # Ok Name pass the test
    update_sadmin_cfg(sroot,"SADM_SERVER",wcfg_server)                  # Update Value in sadmin.cfg

    # Accept the maximum number of lines we want in every log produce
    sdefault = 1000                                                     # No Default value 
    sprompt  = "Maximum number of lines in LOG file"                    # Prompt for Answer
    wcfg_max_logline = accept_field(sroot,"SADM_MAX_LOGLINE",sdefault,sprompt,"I",1,10000)
    update_sadmin_cfg(sroot,"SADM_MAX_LOGLINE",wcfg_max_logline)        # Update Value in sadmin.cfg

    # Accept the maximum number of lines we want in every RCH file produce
    sdefault = 100                                                      # No Default value 
    sprompt  = "Maximum number of lines in RCH file"                    # Prompt for Answer
    wcfg_max_rchline = accept_field(sroot,"SADM_MAX_RCHLINE",sdefault,sprompt,"I",1,300)
    update_sadmin_cfg(sroot,"SADM_MAX_RCHLINE",wcfg_max_rchline)        # Update Value in sadmin.cfg

    # Accept the Default Domain Name
    sdefault = ""                                                       # No Default value 
    sprompt  = "Default domain name"                                    # Prompt for Answer
    wcfg_domain = accept_field(sroot,"SADM_DOMAIN",sdefault,sprompt)    # Accept Default Domain Name
    update_sadmin_cfg(sroot,"SADM_DOMAIN",wcfg_domain)                  # Update Value in sadmin.cfg

    # Accept the Default User Group
    sdefault = "sadmin"                                                 # Set Default value 
    sprompt  = "Enter the default user Group"                           # Prompt for Answer
    wcfg_group=accept_field(sroot,"SADM_GROUP",sdefault,sprompt)        # Accept Defaut SADMIN Group
    found_grp = False                                                   # Not in group file Default
    with open('/etc/group',mode='r') as f:                              # Open the system group file
        for line in f:                                                  # For every line in Group
            if line.startswith( "%s:" % (wcfg_group) ):                 # If Line start with Group:
                found_grp = True                                        # Found Grp entered in file
    if (found_grp == True):                                             # Group were found in file
        showwarning ("Group %s is an existing group" % (wcfg_group))    # Existing group Advise User 
    else:
        print ("Creating group %s" % (wcfg_group))                      # Show creating the group
        if wostype == "LINUX" :                                         # Under Linux
            ccode,cstdout,cstderr = oscommand("groupadd %s" % (wcfg_group))   # Add Group on Linux
        if wostype == "AIX" :                                           # Under AIX
            ccode,cstdout,cstderr = oscommand("mkgroup %s" % (wcfg_group))    # Add Group on Aix
        if (DEBUG):                                                     # If Debug Activated
            print ("Return code is %d" % (ccode))                       # Show AddGroup Cmd Error No
    update_sadmin_cfg(sroot,"SADM_GROUP",wcfg_group)                    # Update Value in sadmin.cfg

    # Accept the Default User Name
    sdefault = "sadmin"                                                 # Set Default value 
    sprompt  = "Enter the default user name"                            # Prompt for Answer
    wcfg_user = accept_field(sroot,"SADM_USER",sdefault,sprompt)        # Accept default SADMIN User
    found_usr = False                                                   # Not in user file Default
    with open('/etc/passwd',mode='r') as f:                             # Open System user File
        for line in f:                                                  # For every line in passwd
            if line.startswith( "%s:" % (wcfg_user) ):                  # Line Start with user name 
                found_usr = True                                        # Found User in passwd file
    if (found_usr == True):                                             # User Name found in file
        showwarning ("User %s is an existing user" % (wcfg_user))       # Existing user Advise user
    else:
        print ("Creating user %s" % (wcfg_user))                        # Create user on system
        if wostype == "LINUX" :                                         # Under Linux
            cmd = "useradd -g %s -s /bin/sh " % (wcfg_user)             # Build Add user Command 
            cmd += " -d %s "    % (os.environ.get('SADMIN'))            # Assign Home Directory
            cmd += " -c'%s' %s" % ("SADMIN Tools User",wcfg_user)       # Add comment and user name
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Create User
        if wostype == "AIX" :                                           # Under AIX
            cmd = "mkuser pgrp='%s' -s /bin/sh " % (wcfg_user)          # Build mkuser command
            cmd += " home='%s' " % (os.environ.get('SADMIN'))           # Set Home Directory
            cmd += " gecos='%s' %s" % ("SADMIN Tools User",wcfg_user)   # Set comment and user name
            ccode, cstdout, cstderr = oscommand(cmd)                    # Go Create User
        if (DEBUG):                                                     # If Debug Activated
            print ("Return code is %d" % (ccode))                       # Show AddGroup Cmd Error #
    update_sadmin_cfg(sroot,"SADM_USER",wcfg_user)                      # Update Value in sadmin.cfg

    # Questions ask only if on the SADMIN Server
    if (wcfg_host_type == "S"):                                         # If Host is SADMIN Server
        # Accept the default SSH port your use
        sdefault = 22                                                   # SSH Port Default value 
        sprompt  = "SSH port number used to connect to client"          # Prompt for Answer
        wcfg_ssh_port = accept_field(sroot,"SADM_SSH_PORT",sdefault,sprompt,"I",1,65536)
        update_sadmin_cfg(sroot,"SADM_SSH_PORT",wcfg_ssh_port)          # Update Value in sadmin.cfg
        # Accept the Network IP and Netmask your Network
        sdefault = "192.168.1.0/24"                                     # Network Default value 
        sprompt  = "Enter the network IP and netmask"                   # Prompt for Answer
        wcfg_network1 = accept_field(sroot,"SADM_NETWORK1",sdefault,sprompt) # Accept Net to Watch
        update_sadmin_cfg(sroot,"SADM_NETWORK1",wcfg_network1)          # Update Value in sadmin.cfg
    
    return(0)                                                           # Return to Caller No Error




#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():
    global fhlog

    # Insure that this script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
       print ("This script must be run by the 'root' user")             # Advise User Message / Log
       print ("Try sudo ./%s" % (pn))                                   # Suggest to use 'sudo'
       print ("Process aborted")                                        # Process Aborted Msg
       sys.exit(1)                                                      # Exit with Error Code

    # Ask for location of SADMIN Tools Root Directory & Set Env.Variable SADMIN 
    sroot=set_sadmin_env(sver)                                          # Go Set SADMIN Env. Var.
    if (DEBUG): print ("main: Directory SADMIN is %s" % (sroot))        # Show SADMIN root Dir.

    # Determine type of software package based on command present on system 
    packtype=""                                                         # Set Initial Packaging Type
    if (locate_command('rpm')   != "") : packtype="rpm"                 # Is rpm command on system ?
    if (locate_command('dpkg')  != "") : packtype="deb"                 # is deb command on system ?
    if (locate_command('lslpp') != "") : packtype="aix"                 # Is lslpp cmd on system ?
    if (packtype == ""):                                                # If unknow/unsupported O/S
        print ('Package type not supported - Command rpm,spkg or lslpp absent')
        sys.exit(1)                                                     # Exit to O/S
    if (DEBUG) : print ("Package type on system is %s" % (packtype))    # Debug, Show Packaging Type 
    
    # Make log directory and Open the log file
    try:                                                                # Catch mkdir error
        os.mkdir ("%s/log" % (sroot),mode=0o777)                        # Make ${SADMIN}/log dir.
    except FileExistsError as e :                                       # If Dir. already exists                    
        pass                                                            # It's ok if it exist
    logfile = "%s/log/%s.log" % (sroot,'sadm_setup')                    # Set Log file name
    if (DEBUG) : print ("Open the log file %s" % (logfile))             # Debug, Show Log file
    try:                                                                # Try to Open/Create Log
        fhlog=open(logfile,'w')                                         # Open Log File 
    except IOError as e:                                                # If Can't Create Log
        print ("Error creating log file %s" % (logfile))                # Print Log FileName
        print ("Error Number : {0}".format(e.errno))                    # Print Error Number    
        print ("Error Text   : {0}".format(e.strerror))                 # Print Error Message
        sys.exit(1)                                                     # Exit with Error

    # Check if all commands, packages needed are installed, if not install them
    satisfy_requirement(sroot,packtype)
    sys.exit(1)
        
    main_process(sroot)                                                 # Main Program Process 

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
