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
# 2018_02_16 JDuplessis
#   V1.0g WIP Version Now cover pyMySQL Python module installation & sadmin.cfg template
# 2018_02_19 JDuplessis
#   V1.0h WIP Version Dev Testing 
# 2018_02_22 JDuplessis
#   V1.0i WIP Version Dev Testing 
#
#===================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
try :
    import os,time,sys,pdb,socket,datetime,subprocess,glob,fnmatch,shutil # Import Std Python3 Modules
    #from subprocess import Popen, PIPE
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                    # Activate Python Debugging


#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
conn                = ""                                                # MySQL Database Connector
cur                 = ""                                                # MySQL Database Cursor
sadm_base_dir       = ""                                                # SADMIN Install Directory
sver                = "1.0i"
DEBUG               = True                                              # Debug Activated or Not
#
SADMIN_ROOT         = ""                                                # SADMIN Root Directory

# ----------------------------------------------------------------------------------------------
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
# ----------------------------------------------------------------------------------------------
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
    #if returncode:
    #    raise Exception(returncode,err)
    #else :
    return (returncode,out,err)


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
    print ("[OK] SADMIN Environment variable is set to %s" % (sadm_base_dir))
    #print ("\n----------")
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
    return sadm_base_dir                                                # Return SADMIN Root Dir

#===================================================================================================
#                     Replacing Value in SADMIN configuration file (sadmin.cfg)
#               1st parameter = Name of setting    2nd parameter = Value of the setting
#===================================================================================================
#
def update_sadmin_cfg(sroot,sname,svalue):
    """[Update the SADMIN configuration File.]

    Arguments:
    st {[type]} -- [Instance of SADMIN]
    sname {[type]} -- [Name of the Variable to replace]
    svalue {[type]} -- [Value of the variable to replace]
    """    
    wcfg_file = sroot + "/cfg/sadmin.cfg"                            # Actual sadmin config file
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
    
    if (stype.upper() != "A" and stype.upper() != "I") :                # Accept Alpha or Integer
        print ("The type of input received is invalid (%s)" % (stype))  # If Not A or I - Advise Usr
        print ("Expecting [I]nteger or [A]lphanumeric")                 # Question is Skipped
        return 1                                                        # Return Error to caller
    if (DEBUG):
        print ("accept_field: Directory SADMIN is %s" % (sroot))                # Show SADMIN root Dir.
        
    print ("\n----------\n[%s]" % (sname))                              # Dash & Name of Field

    # Open and display documentation file content for field just received 
    docname = "%s/doc/cfg/%s.txt" % (sroot,sname.lower())               # Set Documentation FileName
    try :                                                               # Try to Open Doc File
        doc = open(docname,'r')                                         # Open Documentation file
    except FileNotFoundError:                                           # If Open File Failed
        print ("Doc file %s not found, question skipped." % (docname))  # Advise User, Question Skip
        return (1)                                                      # Return Error to caller
    for line in doc:                                                    # Read Doc. file until EOF
        if line.startswith("#"):                                        # Line Start #
           continue                                                     # Skip Line that start with#
        print ("%s" % (line),end='')                                    # Print Documentation Line
    doc.close()                                                         # Close Document File
    print (" ")                                                         # Print blank Line

    # Accept the Value from the user    
    if (stype.upper() == "A"):                                          # If Alphanumeric Input
        wdata=""
        while (wdata == ""):                                            # Input until something 
            wdata = input("%s : " % (sprompt))                          # Accept user response
    if (stype.upper() == "I"):                                          # If Numeric Input
        wdata = 0                                                       # Where response is store
        while True:                                                     # Loop until Valid response
            try:
                wdata = int(input("%s : " % (sprompt)))                 # Accept an Integer
            except (ValueError, TypeError) as error:                    # If Value is not an Integer
                print("Not an integer!")                                # Advise User Message
                continue                                                # Continue at start of loop
            else:                                                       # If a Numeric Value Entered
                if (wdata > smax) or (wdata < smin):                    # Must be between min & max
                    print ("Value must be between %d and %d" % (smin,smax)) # Input out of Range 
                    continue                                            # Continue at start of loop
                else:                                                   # Input Respect the range
                    break                                               # Break out of the loop

    # Go Update Field in sadmin.cfg
    update_sadmin_cfg(sroot,sname,"%s" % (wdata))                          # Update Value in sadmin.cfg
    return wdata

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main_process(SADMIN_ROOT):

    ccode, cstdout, cstderr = oscommand("uname -s")
    wostype=cstdout.upper()

    #wcfg_file = "/sadmin/jac/cfg/sadmin.cfg"  
    if (DEBUG):                                                         # If Debug Activated
        print ("main_process: Directory SADMIN is %s" % (SADMIN_ROOT)) # Show SADMIN root Dir.
        print ("ostype is: %s" % (wostype))

    # Accept if current server is a the SADMIN [S]erver or a [C]lient
    print ("\n----------\n[%s]" % ("Client or Server"))                 # Dash & Name of Field
    wrep = "X"                                                          # Where answer will be store
    while ((wrep.upper() != "S") and (wrep.upper() != "C")):            # Accept Only S or C                 
        sprompt="Current host will be the SADMIN [S]erver or a [C]lient (S,C)"
        wrep = input("%s : " % (sprompt))                               # Accept user response
    SERVER_TYPE=wrep.upper()                                            # Store answer in uppercase

    # Accept the Company Name
    wcfg_cie_name = accept_field(SADMIN_ROOT,"SADM_CIE_NAME","","Enter your company name")   

    # Accept SysAdmin Email address
    wcfg_mail_addr = accept_field(SADMIN_ROOT,"SADM_MAIL_ADDR","","Enter System Administrator Email")

    # Accept the Email type to use at the end of each sript execution
    wcfg_mail_type = accept_field(SADMIN_ROOT,"SADM_MAIL_TYPE",1,"Enter default email type","I",0,3)

    # Accept the SADMIN FQDN Server name
    while True:
        wcfg_server = accept_field(SADMIN_ROOT,"SADM_SERVER","","Enter SADMIN (FQDN) server name","A")
        try :
            xip = socket.gethostbyname(wcfg_server)
        except (socket.gaierror) as error : 
            print ("The name %s is not a valid server name" % (wcfg_server))
            continue    
        xarray = socket.gethostbyaddr(xip)
        yname = repr(xarray[0]).replace("'","")
        #print ("wcfg_server = %s - xip = %s - yname = %s" % (wcfg_server,xip,yname))
        if (yname != wcfg_server) :
            print ("The server %s with ip %s is returning %s" % (wcfg_server,xip,yname))
            print ("The FQDN is wrong or the IP doesn't correspond")
            continue
        else:
            break

    # Accept the maximum number of lines we want in every log produce
    wcfg_max_logline = accept_field(SADMIN_ROOT,"SADM_MAX_LOGLINE",1000,"Maximum number of lines in *.log file","I",1,10000)

    # Accept the maximum number of lines we want in every RCH file produce
    wcfg_max_rchline = accept_field(SADMIN_ROOT,"SADM_MAX_RCHLINE",100,"Maximum number of lines in *.rch file","I",1,300)

    # Accept the default SSH port your use
    wcfg_ssh_port = accept_field(SADMIN_ROOT,"SADM_SSH_PORT",22,"SSH port number used to connect to client","I",1,65536)

    # Accept the Default Domain Name
    wcfg_domain = accept_field(SADMIN_ROOT,"SADM_DOMAIN","","Default domain name","A")

    # Accept the Default User Group
    wcfg_group=accept_field(SADMIN_ROOT,"SADM_GROUP","sadmin","Enter the default user Group","A")
    found_grp = False                                                       # Not Found by Default
    with open('/etc/group') as f:
        for line in f:
            if line.startswith( "%s:" % (wcfg_group) ):
                found_grp = True                                                    # Fould Line
    if (found_grp == True):
        print ("[OK] the group %s is an existing group" % (wcfg_group))
    else:
        print ("Creating group %s" % (wcfg_group))
        if wostype == "LINUX" :                                    # Under Linux
            ccode, cstdout, cstderr = oscommand("groupadd %s" % (wcfg_group)) 
        if wostype == "AIX" :                                      # Under AIX
            ccode, cstdout, cstderr = oscommand("mkgroup %s" % (wcfg_group))
        print ("Return code is %d" % (ccode))


    # Accept the Default User Name
    wcfg_user = accept_field(SADMIN_ROOT,"SADM_USER","sadmin","Enter the default user name","A")
    found_usr = False                                                       # Not Found by Default
    with open('/etc/passwd') as f:
        for line in f:
            if line.startswith( "%s:" % (wcfg_user) ):
                found_usr = True                                                    # Fould Line
    if (found_usr == True):
        print ("[OK] the user %s is an existing user" % (wcfg_user))
    else:
        print ("Creating user %s" % (wcfg_user))
        if wostype == "LINUX" :                                    # Under Linux
            cmd = "useradd -g %s -s /bin/sh " % (wcfg_user)
            cmd += " -d %s "    % (os.environ.get('SADMIN'))
            cmd += " -c'%s' %s" % ("SADMIN Tools User",wcfg_user)
            ccode, cstdout, cstderr = oscommand(cmd)
        if wostype == "AIX" :                                      # Under AIX
            cmd = "mkuser pgrp='%s' -s /bin/sh " % (wcfg_user)
            cmd += " home='%s' " % (os.environ.get('SADMIN'))
            cmd += " gecos='%s' %s" % ("SADMIN Tools User",wcfg_user)
            ccode, cstdout, cstderr = oscommand(cmd)           
        print ("Return code is %d" % (ccode))

    # Accept the Network IP and Netmask your Network
    wcfg_network1 = accept_field(SADMIN_ROOT,"SADM_NETWORK1","192.168.1.0/24","Enter the network IP and netmask","A")
    
    return(0)                                                           # Return to Caller No Error




#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():

    # Insure that this script can only be run by the user root (Optional Code)
    if not os.getuid() == 0:                                            # UID of user is not zero
       print ("This script must be run by the 'root' user")             # Advise User Message / Log
       print ("Try sudo ./%s" % (st.pn))                                # Suggest to use 'sudo'
       print ("Process aborted")                                        # Process Aborted Msg
       sys.exit(1)                                                      # Exit with Error Code

    SADMIN_ROOT = set_sadmin_env(sver)                                  # Go Set SADMIN Env. Var.
    if (DEBUG):                                                         # If Debug is activated
        print ("main: Directory SADMIN is %s" % (SADMIN_ROOT))                # Show SADMIN root Dir.
    main_process(SADMIN_ROOT)                                           # Main Program Process 

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()
