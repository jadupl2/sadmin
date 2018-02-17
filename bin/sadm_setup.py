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
#   V1.0f WIP Version Now cover pyMySQL Python module installation & sadmin.cfg template
#
#===================================================================================================
#
# The following modules are needed by SADMIN Tools and they all come with Standard Python 3
# try :
    import os, time, sys, pdb, socket, datetime, glob, fnmatch
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#
# Python MySQL Module is a MUST before continuing the setup 
# try :
    import pymysql
except ImportError as e:
    print ("The Python Module to access MySQL is not installed : %s " % e)
    print ("We need to install it before continuying")
    print ("\nIf you are on Debian,Raspbian,Ubuntu family type the following command to install it:")
    print ("sudo apt-get install python3-pip")
    print ("sudo pip3 install PyMySQL")
    print ("After run sadm_setup.py again, to continue installation of SADMIN Tools")
    print ("\nIf you are on Redhat, CentOS, Fedora family type the following command to install it:")
    print ("sudo yum --enablerepo=epel install python34-pip")
    print ("sudo pip3 install pymysql")
    print ("After run sadm_setup.py again, to continue installation of SADMIN Tools")
    sys.exit(1)
#
#pdb.set_trace()                                                        # Activate Python Debugging


#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
sadm_base_dir       = ""                                                # SADMI Install Directory
sver                = "1.0e"
#

#===================================================================================================
#                                 Initialize SADM Tools Function
#===================================================================================================
#
def initSADM():
    # Making Sure SADMIN Environment Variable is Define & import 'sadmlib_std.py' if can be found.
    if not "SADMIN" in os.environ:                                      # SADMIN Env. Var. Defined ?
        print ("SADMIN Environment Variable isn't define")              # SADMIN Var MUST be defined
        print ("It indicate the directory where you installed the SADMIN Tools")
        print ("Add this line at the end of /etc/environment file.")    # Show Where to Add Env. Var
        print ("# echo 'SADMIN=/[dir-where-you-install-sadmin]'")       # Show What to Add.
        sys.exit(1)                                                     # Exit to O/S with Error 1
    try :
        SADM = os.environ.get('SADMIN')                                 # Getting SADMIN Dir. Name
        sys.path.append(os.path.join(SADM,'lib'))                       # Add $SADMIN/lib to PyPath
        import sadmlib_std as sadm                                      # Import SADM Python Library
    except ImportError as e:                                            # Catch import Error
        print ("Import Error : %s " % e)                                # Advise user about error
        sys.exit(1)                                                     # Exit to O/S with Error 1
    

    # Create SADMIN Instance & setup instance Variables specific to your program
    st = sadm.sadmtools()                       # CREATE SADM TOOLS INSTANCE (Setup Dir.)
    st.ver  = "1.0f"                            # Indicate your Script Version 
    st.multiple_exec = "N"                      # Allow to run Multiple instance of this script ?
    st.log_type = 'L'                           # Log Type  (L=Log file only  S=stdout only  B=Both)
    st.log_append = True                        # True to Append Existing Log, False=Start a new log
    st.debug = 0                                # Debug Level and Verbosity (0-9)
    st.cfg_mail_type = 1                        # 0=NoMail 1=OnlyOnError 2=OnlyOnSucces 3=Allways
    #st.cfg_mail_addr = ""                      # This Override Default Email Address in sadmin.cfg
    #st.cfg_cie_name  = ""                      # This Override Company Name specify in sadmin.cfg
    st.start()                                  # Create dir. if needed, Open Log, Update RCH file..
    return(st)                                  # Return Instance Object to caller

#===================================================================================================
#        Specify and/or Validate that SADMIN Environment Variable is set in /etc/environent
#===================================================================================================
#
def validate_sadmin_var(ver):
    print ("\033[H\033[J")                                              # Clear the Screen
    print ("SADMIN Setup V%s\n------------------" % (ver))              # Print Version Number

    # Is SADMIN Environment Variable Defined ? , If not ask user to specify it
    if "SADMIN" in os.environ:                                          # Is SADMIN Env. Var. Exist?
        sadm_base_dir = os.environ.get('SADMIN')                        # Get SADMIN Base Directory
    else:                                                               # If Not Ask User Full Path
        sadm_base_dir = input("Enter directory path where your install SADMIN : ")

    # Does Directory specify exist ?
    if not os.path.exists(sadm_base_dir) :                              # Check if SADM Dir. Exist
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
    print ("SADMIN Environment variable is set to %s and it's valid" % (sadm_base_dir))
    print ("\n----------")
    print ("Good, the line below is in /etc/environment") 
    print ("%s" % (eline),end='')                                       # SADMIN Line in /etc/env...
    print ("This will make sure it is set upon reboot")

    # Make sure we have a sadmin.cfg in $SADMIN/cfg, if not cp .sadmin.cfg to sadmin.update_sadmin_cfg
    cfgfile="%s/cfg/sadmin.cfg" % (sadm_base_dir)                       # Set Full Path to cfg File
    cfgfileo="%s/cfg/.sadmin.cfg" % (sadm_base_dir)                     # Set Full Path to cfg File
    if os.path.exists(cfgfile)==False:                                  # If sadmin.cfg Not Found
        try:
            copyfile(cfgfileo,cfgfile)                                  # Copy Template 2 sadmin.cfg
        except IOError as e:
            print("Unable to copy file. %s" % e)                        # Advise user before exiting
            exit(1)                                                     # Exit to O/S With Error
        except:
            print("Unexpected error:", sys.exc_info())                  # Advise Usr Show Error Msg
            exit(1)                                                     # Exit to O/S with Error
        print ("Initial sadmin.cfg file in place.")                     # Advise User ok to proceed
    return(0)                                                           # Return to Caller No Error

#===================================================================================================
#                     Replacing Value in SADMIN configuration file (sadmin.cfg)
#               1st parameter = Name of setting    2nd parameter = Value of the setting
#===================================================================================================
#
def update_sadmin_cfg(st,sname,svalue):
    """[Update the SADMIN configuration File.]

    Arguments:
    st {[type]} -- [Instance of SADMIN]
    sname {[type]} -- [Name of the Variable to replace]
    svalue {[type]} -- [Value of the variable to replace]
    """    

    if (st.debug > 0) :
        print ("In update_sadmin_cfg - sname = %s - svalue = %s\n" % (sname,svalue))
        print ("cfg_file = %s" % (st.cfg_file))

    fi = open(st.cfg_file,'r')                                          # Current sadmin.cfg File
    fo = open(st.tmp_file1,'w')                                         # Will become new sadmin.cfg
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

    try:                                                                # Will try rename env. file
        os.rename(st.cfg_file,"%s/sadmin.tmp" % (st.cfg_dir))           # Rename Current to tmp
        os.rename(st.tmp_file1,st.cfg_file)                             # Rename tmp to sadmin.cfg
    except:
        print ("Error renaming %s" % (st.cfg_file))                     # Advise user of problem
        sys.exit(1)                                                     # Exit to O/S with Error


#===================================================================================================
#             Accept field receive as parameter and update the $SADMIN/cfg/sadmin.cfg file
#   1)Instance of SADMIN Tools   2)Parameter name in sadmin.cfg   3)Default Value   
#   4)Prompt text                5)Type of input ([I]nteger [A]lphanumeric)
#   6)smin & smax = Minimum and Maximum value for integer prompt
#===================================================================================================
#
def accept_field(st,sname,sdefault,sprompt,stype="A",smin=0,smax=3):
    if (stype.upper() != "A" and stype.upper() != "I") :                # Accept Alpha or Integer
        print ("The type of input received is invalid (%s)" % (stype))  # If Not A or I - Advise Usr
        print ("Question skipped")                                      # Question is Skipped
        return 1                                                        # Return Error to caller

    print ("\n----------\n[%s]" % (sname))                              # Dash & Name of Field

    # Open and display documentation file content for field just received 
    docname = "%s/cfg/%s.txt" % (st.doc_dir,sname.lower())              # Set Documentation FileName
    try :                                                               # Try to Open Doc File
        doc = open(docname,'r')                                         # Open Documentation file
    except FileNotFoundError:                                           # If Open File Failed
        print ("Doc file %s not found, question skipped." % (docname))  # Advise User, Question Skip
        return (1)                                                        # Return Error to caller
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
    update_sadmin_cfg(st,sname,"%s" % (wdata))                          # Update Value in sadmin.cfg
    return wdata

#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main_process(st):
    st.cfg_file = "/sadmin/jac/cfg/sadmin.cfg"  


    # Accept if current server is a the SADMIN [S]erver or a [C]lient
    #print ("\n----------\n[%s]" % ("Client or Server"))                 # Dash & Name of Field
    #wrep = "X"                                                         # Where answer will be store
    #while ((wrep.upper() != "S") and (wrep.upper() != "C")):          # Accept Only S or C                                   # Input until something 
    #    sprompt="Current host will be the SADMIN [S]erver or a [C]lient (S,C)"
    #    wrep = input("%s : " % (sprompt))                              # Accept user response
    #SERVER_TYPE=wrep.upper()                                           # Store answer in uppercase

    # Accept the Company Name
    #accept_field(st,"SADM_CIE_NAME",st.cfg_cie_name,"Enter your company name")   

    # Accept SysAdmin Email address
    #accept_field(st,"SADM_MAIL_ADDR",st.cfg_mail_addr,"Enter System Administrator Email")

    # Accept the Email type to use at the end of each sript execution
    #accept_field(st,"SADM_MAIL_TYPE",st.cfg_mail_type,"Enter default email type","I",0,3)

    # Accept the SADMIN FQDN Server name
    while True:
        xserver=accept_field(st,"SADM_SERVER",st.cfg_server,"Enter SADMIN (FQDN) server name","A")
        try :
            xip = socket.gethostbyname(xserver)
        except (socket.gaierror) as error : 
            print ("The name %s is not a valid server name" % (xserver))
            continue    
        xarray = socket.gethostbyaddr(xip)
        yname = repr(xarray[0])
        print ("xserver = %s - xip = %s - yname = %s" % (xserver,xip,yname))
        if (yname != xserver) :
            print ("The server %s with ip %s is returning %s" % (xserver,xip,yname))
            print ("The FQDN is wrong or the IP doesn't correspond")
            continue
        else:
            break

    # Accept the maximum number of lines we want in every log produce
    accept_field(st,"SADM_MAX_LOGLINE",st.cfg_max_logline,"Enter maximum number of lines in a log file","I",1,10000)

    # Accept the maximum number of lines we want in every RCH file produce
    accept_field(st,"SADM_MAX_RCHLINE",st.cfg_max_rchline,"Enter maximum number of lines in a rch file","I",1,300)

    # Accept the default SSH port your use
    accept_field(st,"SADM_SSH_PORT",st.cfg_ssh_port,"Enter the SSH port number used to connect to client","I",1,65536)

    # Accept the Default Domain Name
    accept_field(st,"SADM_DOMAIN",st.cfg_domain,"Enter the default domain name","A")

    # Accept the Network IP and Netmask your Network
    accept_field(st,"SADM_NETWORK1",st.cfg_network1,"Enter the network IP and netmask","A")
    
    return(0)                                                           # Return to Caller No Error




#===================================================================================================
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main():

    # Insure that this script can only be run by the user root (Optional Code)
#    if not os.getuid() == 0:                                            # UID of user is not zero
#       print ("This script must be run by the 'root' user")             # Advise User Message / Log
#       print ("Try sudo ./%s" % (st.pn))                                # Suggest to use 'sudo'
#       print ("Process aborted")                                        # Process Aborted Msg
#       st.stop (1)                                                      # Close and Trim Log/Email
#       sys.exit(1)                                                      # Exit with Error Code
        
    validate_sadmin_var(sver)                                           # Go Set SADMIN Env. Var.
    st = initSADM()                                                     # Initialize SADM Tools
    if st.debug > 4: st.display_env()                                   # Display Env. Variables
    st.exit_code = main_process(st)                                     # Main Program Process 
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()