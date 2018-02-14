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
# 2018_02_13 JDuplessis
#   V1.0d WIP Version
#
#===================================================================================================
try :
    import os, time, sys, pdb, socket, datetime, glob, fnmatch
except ImportError as e:
    print ("Import Error : %s " % e)
    sys.exit(1)
#pdb.set_trace()                                                        # Activate Python Debugging


#===================================================================================================
#                             Local Variables used by this script
#===================================================================================================
conn                = ""                                                # Database Connector
cur                 = ""                                                # Database Cursor
sadm_base_dir       = ""                                                # SADMI Install Directory
sver                = "1.0"
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
    st.ver  = "1.0d"                            # Indicate your Script Version 
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
def define_sadmin_var(ver):
    
    print ("\033[H\033[J")                                              # Clear the Screen
    print ("SADMIN Setup V%s\n------------------" % (ver))              # Print Version Number

    if "SADMIN" in os.environ:                                          # Is SADMIN Env. Var. Exist?
        sadm_base_dir = os.environ.get('SADMIN')                        # Get SADMIN Base Directory
    else:                                                               # If Not Ask User Full Path
        sadm_base_dir = input("Enter directory path where your install SADMIN : ")

    # Does Directory Specify exist ?
    if not os.path.exists(sadm_base_dir) :                              # Check if SADM Dir. Exist
        print ("Directory %s doesn't exist." % (sadm_base_dir))         # Advise User
        sys.exit(1)                                                     # Exit with Error Code

    # Check if Directory specify contain the Shell SADMIN Library (Indicate Dir. is the good one)
    libname="%s/lib/sadmlib_std.sh" % (sadm_base_dir)                   # Set Full Path to Shell Lib
    if os.path.exists(libname)==False:                                  # If SADMIN Lib Not Found
        print ("Directory %s isn't SADMIN directory" % (sadm_base_dir)) # Advise User Dir. Wrong
        print ("It doesn't contains the file %s" % (libname))           # Show Why we Refused
        sys.exit(1)                                                     # Exit with Error Code

    # Ok now we can Set SADMIN Environnement Variable
    os.environ['SADMIN'] = sadm_base_dir                                # Setting SADMIN Env. Dir.

    # Now we need to make sure that 'SADMIN=' line is in /etc/environment (If not add it)
    fi = open('/etc/environment','r')                                   # Environment Input File
    fo = open('/etc/environment.new','w')                               # Environment Output File
    fileEmpty=True                                                      # Env. file assume empty
    eline = "SADMIN=%s\n" % (sadm_base_dir)                             # Line needed in /etc/env...
    for line in fi:                                                     # Read Input file until EOF
        if line.startswith( 'SADMIN=' ) :                               # line Start with 'SADMIN='?
           line = "%s\n" % (eline)                                      # Add line with needed line
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
    print ("SADMIN Environment variable is set and valid")
    print ("SADMIN=%s" % (sadm_base_dir))
    print ("\n----------")
    print ("Good, the line below is in /etc/environment")
    print ("This will make sure it is set upon reboot")
    print (eline)                                                       # SADMIN Line in /etc/env...
    return(0)                                                           # Return to Caller No Error

#===================================================================================================
#                     Replacing Value in SADMIN configuration file (sadmin.cfg)
#               1st parameter = Name of setting    2nd parameter = Value of the setting
#===================================================================================================
#
def update_sadmin_cfg(st,sname,svalue):
    print ("In update_sadmin_cfg - sname = %s - svalue = %s\n" % (sname,svalue))
    print ("cfg_file = %s" % (st.cfg_file))

    fi = open(st.cfg_file,'r')                                          # Current sadmin.cfg File
    fo = open(st.tmp_file1,'w')                                         # Will become new sadmin.cfg
    lineNotFound=True                                                   # Assume String not in file
    cline = "%s = %s\n" % (sname,svalue)                                # Line to Insert in file

    # Replace Line Starting with 'sname' with new 'svalue' 
    for line in fi:                                                     # Read sadmin.cfg until EOF
        if line.startswith("%s" % (sname.upper())) :                    # Line Start with SNAME ?
           line = "%s\n" % (cline)                                      # Change Line with new one
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
#                                  M A I N     P R O G R A M
#===================================================================================================
#
def main_process(st):

    # Enter your Company name
    print ("\n----------")
    sadm_cie_name=""
    while (sadm_cie_name == ""):
        sadm_cie_name = input("Enter your company ou site name : ")
    update_sadmin_cfg(st,"SADM_CIE_NAME","%s" % (sadm_cie_name))
    
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
       st.stop (1)                                                      # Close and Trim Log/Email
       sys.exit(1)                                                      # Exit with Error Code
        
    define_sadmin_var(sver)                                            # Go Set SADMIN Env. Var.
    st = initSADM()                                                     # Initialize SADM Tools
    if st.debug > 4: st.display_env()                                   # Display Env. Variables
    st.exit_code = main_process(st)                                     # Main Program Process 
    st.stop(st.exit_code)                                               # Close SADM Environment

# This idiom means the below code only runs when executed from command line
if __name__ == '__main__':  main()