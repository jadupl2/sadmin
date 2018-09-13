#!/usr/bin/env perl
#===================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_sysmon.pl
#   Synopsis :  sadm System Monitor
#   Version  :  1.5
#   Date     :  15 Janvier 2016
#   Requires :  sh
#===================================================================================================
# 2017_12_30    V2.7 Change Config file extension to .smon & Defaut Virtual Machine presence to 'N'
# 2017_12_30    V2.8 Change name of template file from sysmon.std to template.smon
# 2017_12_30    V2.9 Change Message Sent to user when host.cfg file not there and using template file
# 2018_05_07    V2.10 Bug Fixes - Code Revamp - Now read SADMIN config file 
# 2018_05_14    V2.11 MacOS/AIX Checking SwapSpac/Load Average/New Filesystem Enhancement 
# 2018_05_27    v2.12 Change Location of SysMon Scripts Directory to $SADMIN/usr/sysmon_scripts
# 2018_06_03    v2.13 Change Location of SysMon Scripts Directory to $SADMIN/usr/mon
# 2018_06_12    v2.14 Correct Problem with fileincrease and Filesystem Warning double error
# 2018_06_14    v2.15 Load $SADMIN/sadmin.cfg before the hostname.smon file (So we know Email Address)
# 2018_07_11    v2.16 Uptime/Load Average take last 5 min. values instead of current.
# 2018_07_12    v2.17 Service Line now execute srestart.sh script to restart it & Alert Insertion
# 2018_07_18    v2.18 Fix when filesystem exceed threshold try increase when no script specified
# 2018_07_19    v2.19 Add Mail Mess when sadmin.cfg not found & Change Mess when host.smon not found
# 2018_07_21    v2.20 Fix When executiong scripts from sysmon the log wasn't at proper place.
#@2018_07_22    v2.21 Added Date and Time in mail messages sent.
#===================================================================================================
#
# curl -X POST -H 'Content-type: application/json' --data '{"text":"Coco"}'
# https://hooks.slack.com/services/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
#
use English;
use DateTime; 
use File::Basename;
use POSIX qw(strftime);
use Time::Local;
#use LWP::Simple;
use LWP::Simple qw($ua get head);
system "export TERM=xterm";


#===================================================================================================
#                                   Global Variables definition
#===================================================================================================
my $VERSION_NUMBER      = "2.21";                                       # Version Number
my @sysmon_array        = ();                                           # Array Contain sysmon.cfg 
my %df_array            = ();                                           # Array Contain FS info
my $OSNAME              = `uname -s`; chomp $OSNAME;                    # Get O/S Name
$OSNAME                 =~ tr/A-Z/a-z/;                                 # Make OSName in lowercase
my $HOSTNAME            = `hostname -s`; chomp $HOSTNAME;               # HostName of current System
my $SYSMON_DEBUG        = "$ENV{'SYSMON_DEBUG'}" || "5";                # debugging purpose set to 5
my $start_time = $end_time = 0;                                         # Use to Calc execution Time
my $WORK                = 0;                                            # For temp usage
my $VM                  = "N" ;                                         # Are we a VM (No Default)
my $SCRIPT_MAX_RUN_PER_DAY=2;                                           # Restart Script Max run/day

# Maximum of second the SysMon Lock file can exist before it get recreated
# Lock is normally created at the beginning of sysmon and deleted at the end.
# It prevent to run multiple instance of SysMon.
# Situation can happen, when the script never end (system reboot, bugs,...).
# So when sysmon start it check if sysmon.lock exist and how many seconds pass since it creation.
# If the lock file was created for more than the number indicate below, it is reset and SysMon 
# can now to run normally.
my $LOCKFILE_MAX_SEC    = 1800 ;                                        # Max Nb Sec. Lockfile 

# SADMIN DIRECTORY STRUCTURE DEFINITION
my $SADM_BASE_DIR       = "$ENV{'SADMIN'}" || "/sadmin";                # SADMIN Root Dir.
my $SADM_BIN_DIR        = "$SADM_BASE_DIR/bin";                         # SADMIN bin Directory
my $SADM_USR_DIR        = "$SADM_BASE_DIR/usr";                         # SADMIN usr Directory
my $SADM_TMP_DIR        = "$SADM_BASE_DIR/tmp";                         # SADMIN Temp Directory
my $SADM_LOG_DIR        = "$SADM_BASE_DIR/log";                         # SADMIN LOG Directory
my $SADM_DAT_DIR        = "$SADM_BASE_DIR/dat";                         # SADMIN Data Directory
my $SADM_RPT_DIR        = "$SADM_DAT_DIR/rpt";                          # SADMIN Aleret Report File
my $SADM_CFG_DIR        = "$SADM_BASE_DIR/cfg";                         # SADMIN Configuration Dir.
my $SADM_RCH_DIR        = "$SADM_DAT_DIR/rch";                          # SADMIN Result Code History
my $SADM_SCR_DIR        = "$SADM_USR_DIR/mon";                          # SADMIN Monitoring Scripts

# SYSMON FILES DEFINITION
my $PSFILE1             = "$SADM_TMP_DIR/PSFILE1.$$";                   # Result of ps command file1
my $PSFILE2             = "$SADM_TMP_DIR/PSFILE2.$$";                   # Result of ps command file2
my $SADM_TMP_FILE1      = "$SADM_TMP_DIR/${HOSTNAME}_sysmon.tmp1";      # SYSMON Temp work file 1
my $SADM_TMP_FILE2      = "$SADM_TMP_DIR/${HOSTNAME}_sysmon.tmp2";      # SYSMON Temp work file 2
my $SYSMON_CFG_FILE     = "$SADM_CFG_DIR/$HOSTNAME.smon";               # SYSMON Configuration file
my $SYSMON_STD_FILE     = "$SADM_CFG_DIR/.template.smon";               # SYSMON Template file 
my $SYSMON_RPT_FILE     = "$SADM_RPT_DIR/$HOSTNAME.rpt";                # SYSMON Host Report File 
my $SYSMON_LOCK_FILE    = "$SADM_BASE_DIR/sysmon.lock";                 # SYSMON Lock file

# SADMIN FILES DEFINITIONS
my $SADMIN_CFG_FILE     = "$SADM_CFG_DIR/sadmin.cfg";                   # SADMIN Configuration file
my $SADMIN_STD_FILE     = "$SADM_CFG_DIR/.sadmin.cfg";                  # SADMIN Config Template 

# PROGRAMS LOCATION AND COMMAND LINE OPTIONS USED ...
my $CMD_CHMOD           = `which chmod`      ;chomp($CMD_CHMOD);        # Location of chmod command
my $CMD_CP              = `which cp`         ;chomp($CMD_CP);           # Location of cp command
my $CMD_FIND            = `which find`       ;chomp($CMD_FIND);         # Location of find command
my $CMD_MAIL            = `which mail`       ;chomp($CMD_MAIL);         # Location of mail command
my $CMD_TAIL            = `which tail`       ;chomp($CMD_TAIL);         # Location of tail command
my $CMD_HEAD            = `which head`       ;chomp($CMD_HEAD);         # Location of head command
my $CMD_UPTIME          = `which uptime`     ;chomp($CMD_UPTIME);       # Location of uptime command
my $CMD_VMSTAT          = `which vmstat`     ;chomp($CMD_VMSTAT);       # Location of vmstat command
my $CMD_IOSTAT          = `which iostat`     ;chomp($CMD_IOSTAT);       # Location of iostat command
my $CMD_MPATHD          = `which multipathd` ;chomp($CMD_MPATHD);       # Location of multipathd cmd
my $CMD_DMIDECODE       = `which dmidecode`  ;chomp($CMD_DMIDECODE);    # To check if we are in a VM
my $CMD_TOUCH           = `which touch`      ;chomp($CMD_TOUCH);        # Location of touch command 
system ("which systemctl >/dev/null 2>&1");
if ( $? == -1 )  { $CMD_SYSTEMCTL = ""; }else{ $CMD_SYSTEMCTL = `which systemctl 2>/dev/null`; }



# `hostname`.smon file layout, fields are separated by space (be carefull)
# --------------------------------------------------------------------------------------------------
$SADM_RECORD = {
   SADM_ID => " ",                                  # IDENTIFIER 
   SADM_CURVAL => " ",                              # Last Value calculated by sysmon
   SADM_TEST =>   " ",                              # Evaluation Operator (=,!=,<,>,=>,=<) 
   SADM_WARVAL => " ",                              # Warning Level (0=not evaluated)
   SADM_ERRVAL => " ",                              # Error Level (0=not evaluated)     
   SADM_MINUTES =>" ",                              # Error must occur over X minutes before trigger
   SADM_STHRS =>  " ",                              # Hours to start evaluate (0=not evaluate)
   SADM_ENDHRS => " ",                              # Hours to stop evaluate (0=not evaluate
   SADM_SUN =>    " ",                              # Test to be done on Sunday (Y/N) 
   SADM_MON =>    " ",                              # Test to be done on Monday (Y/N) 
   SADM_TUE =>    " ",                              # Test to be done on Tuesday (Y/N) 
   SADM_WED =>    " ",                              # Test to be done on Wednesday (Y/N) 
   SADM_THU =>    " ",                              # Test to be done on Thrusday (Y/N) 
   SADM_FRI =>    " ",                              # Test to be done on Friday (Y/N) 
   SADM_SAT =>    " ",                              # Test to be done on Saturday (Y/N) 
   SADM_ACTIVE => " ",                              # Line is Active or not
   SADM_DATE =>   " ",                              # Last Date this line was evaluated
   SADM_TIME =>   " ",                              # Last Time line was evaluated
   SADM_SLACK_CHANNEL =>  " ",                      # Slack Channel Name 
   SADM_MAIL_GROUP =>  " ",                         # Email Group Name to send email
   SADM_SCRIPT => " ",                              # Script 2 execute when Error
};

# SADMIN CONFIGURATION FILE FIELDS
my $SADM_HOST_TYPE  = "C";                                              # SADM Default HostType(S,C)
my $SADM_MAIL_ADDR  = "root\@localhost";                                # Default Sysadmin Email
my $SADM_CIE_NAME   = " ";                                              # SADMIN Company Name
my $SADM_ALERT_TYPE  = "1";                                              # SADMIN MailType 1,2,3,4
my $SADM_SERVER     = "";                                               # SADMIN FQDN Name
my $SADM_SSH_PORT   = "22";                                             # SADMIN Default SSH Port No
my $SADM_USER       = "sadmin";                                         # SADMIN Default User Name
my $SADM_GROUP      = "sadmin";                                         # SADMIN Default User Group

# SSH COMMANDS AND VARIABLES
my $CMD_SSH       = `which ssh`                ;chomp($CMD_SSH);        # Get location of ssh 
my $CMD_SCP       = `which scp`                ;chomp($CMD_SCP);        # Get location of scp
my $SSH_CONNECT   = "$CMD_SSH -rp${SADM_SSH_PORT} ${SADM_USER}\@${SADM_SERVER}"; # SSH 2 SADM Server
my $SCP_CON       = "$CMD_SCP -rP${SADM_SSH_PORT} ${SADM_USER}\@${SADM_SERVER}"; # SCP 2 SADM Server

# AUTOMATIC FILESYSTEM INCREASE PARAMETERS
my $MINIMUM_SEC=86400;                 # 1 Day=86400 Sec. = Minimum between Filesystem Incr.
my $MAX_FS_INCR=2;                     # Number of filesystem increase allowed per Day.
my $SCRIPT_MIN_SEC_BETWEEN_EXEC=86400; # Restart script didn't run for more than value then ok 2 run


#---------------------------------------------------------------------------------------------------
# Load the content of ${SADMIN}/cfg/sadmin.cfg file into Global Variables
#---------------------------------------------------------------------------------------------------
sub load_sadmin_cfg {
    print "Loading SADMIN configuration file ${SADMIN_CFG_FILE}\n";

    # Check if ${SADMIN}/cfg/sadmin.cfg, if not copy ${SADMIN}/cfg/.sadmin.cfg to sadmin.cfg 
    if ( ! -e "$SADMIN_CFG_FILE"  ) {                                   # If sadmin.cfg not exist
        ($myear,$mmonth,$mday,$mhour,$mmin,$msec,$mepoch) = Today_and_Now(); # Get Date,Time, Epoch
        my $mail_mess0 = sprintf("Today %04d/%02d/%02d at %02d:%02d, ",$myear,$mmonth,$mday,$mhour,$mmin);
        my $mail_mess1 = "SADMIN configuration file $SADMIN_CFG_FILE for ${HOSTNAME} wasn't found.\n";
        my $mail_mess2 = "The file was recreated A new file were created based on the template file ${$SADMIN_STD_FILE}.\n";
        my $mail_mess3 = "You need to review it, to reflect your need.\n";
        my $mail_message = "${mail_mess0}${mail_mess1}${mail_mess2}${mail_mess3}";
        my $mail_subject = "SADM: WARNING $SADMIN_CFG_FILE not found on $HOSTNAME";
        @cmd = ("echo \"$mail_message\" | $CMD_MAIL -s \"$mail_subject\" $SADM_MAIL_ADDR");
        $return_code = 0xffff & system @cmd ;                           # Perform Mail Command 
        @cmd = ("$CMD_CP $SADMIN_STD_FILE $SADMIN_CFG_FILE");           # cp template to sadmin.cfg
        $return_code = 0xffff & system @cmd ;                           # Perform Command cp
        @cmd = ("$CMD_CHMOD 664 $SADMIN_CFG_FILE");                     # Make sadmin.cfg 664
        $return_code = 0xffff & system @cmd ;                           # Perform Command chmod
    }

    # OPEN SYSMON HOST CONFIGURATION FILE AND LOAD IT IN AN ARRAY CALLED SYSMON_ARRAY
    open (SADMFILE,"<$SADMIN_CFG_FILE") or die "Can't open $SADMIN_CFG_FILE: $!\n";
    while ($line = <SADMFILE>) {                                        # Read while end of file
        next if $line =~ /^#/ ;                                         # Don't Process comment line
        ($sname,$svalue) = split /=/, $line ;                           # Split Line (Name & Value)
        if ($SYSMON_DEBUG >= 7) {                                       # If Debeug Level >=7
            print "SADM File - Name: ...${sname}... - Value: ...${svalue}...\n" ; 
        }
        $sname  =~ s/^\s+|\s+$//g;                                      # Remove Leading/Trailing Ch
        $svalue =~ s/^\s+|\s+$//g;                                      # Remove Leading/Trailing Ch
        if ($sname eq "SADM_HOST_TYPE") { $SADM_HOST_TYPE = $svalue; }  # HostType [S]erver [C]lient
        if ($sname eq "SADM_CIE_NAME")  { $SADM_CIE_NAME  = $svalue; }  # Cie name
        if ($sname eq "SADM_ALERT_TYPE") { $SADM_ALERT_TYPE = $svalue; }  # MailType 1=MailOnError
        if ($sname eq "SADM_SERVER")    { $SADM_SERVER    = $svalue; }  # SADM FQDN Name
        if ($sname eq "SADM_SSH_PORT")  { $SADM_SSH_PORT  = $svalue; }  # SSH Port Used
        if ($sname eq "SADM_USER")      { $SADM_USER      = $svalue; }  # sadmin user name
        if ($sname eq "SADM_GROUP")     { $SADM_GROUP     = $svalue; }  # sadmin user group
        if ($sname eq "SADM_MAIL_ADDR") {                               # sadmin Email Adresse
            $SADM_MAIL_ADDR = $svalue ;                                 # Save Email Addr.
            $SADM_MAIL_ADDR =~ s/@/\\@/ig;                              # Precede the @ with a \
        }
    }
    close SADMFILE;                                                     # Close Sadmin Config file

    # For debug purpose - Display SADMIN Variable Gather from sadmin.cfg
    if ($SYSMON_DEBUG >= 6) {
        print "------------------------------------------------------------------------------\n";
        print "SADMIN CONFIGURATION INFORMATION\n";
        print "------------------------------------------------------------------------------\n";
        print "SADM_HOST_TYPE           = ${SADM_HOST_TYPE}\n" ;
        print "SADM_MAIL_ADDR           = ${SADM_MAIL_ADDR}\n" ;
        print "SADM_CIE_NAME            = ${SADM_CIE_NAME}\n"  ;
        print "SADM_ALERT_TYPE           = ${SADM_ALERT_TYPE}\n"  ;
        print "SADM_SERVER              = ${SADM_SERVER}\n"  ;
        print "SADM_SSH_PORT            = ${SADM_SSH_PORT}\n"  ;
        print "SADM_USER                = ${SADM_USER}\n"  ;
        print "SADM_GROUP               = ${SADM_GROUP}\n"  ;
        print "------------------------------------------------------------------------------\n";
    }
}



#---------------------------------------------------------------------------------------------------
# Load the content of ${SADMIN}/cfg/`HOSTNAME`.smon file into an array called @sysmon_array.
#---------------------------------------------------------------------------------------------------
sub load_smon_file {

    # For debug purpose - Display Important Data 
    if ($SYSMON_DEBUG >= 5) {
        print "------------------------------------------------------------------------------\n";
        print "SADMIN SYStem MONitor Tools - Version ${VERSION_NUMBER}\n";
        print "------------------------------------------------------------------------------\n";
        print "O/S Name                 = ${OSNAME}\n" ;
        print "Debugging Level          = ${SYSMON_DEBUG}\n" ;
        print "SADM_BASE_DIR            = ${SADM_BASE_DIR}\n";      
        print "Hostname                 = ${HOSTNAME}\n" ;
        print "Virtual Server           = ${VM}\n" ;
        print "CMD_SSH                  = ${CMD_SSH}\n";
        print "------------------------------------------------------------------------------\n";
    }

    print "\nLoading SysMon configuration file ${SYSMON_CFG_FILE}\n";
    # Check if `hostname`.smon already exist, if not copy .template.smon to `hostname`.smon
    if ( ! -e "$SYSMON_CFG_FILE"  ) {                                   # If hostname.smon not exist
        ($myear,$mmonth,$mday,$mhour,$mmin,$msec,$mepoch) = Today_and_Now(); # Get Date,Time, Epoch
        my $mail_mess0 = sprintf("Today %04d/%02d/%02d at %02d:%02d, ",$myear,$mmonth,$mday,$mhour,$mmin);
        my $mail_mess1 = "SysMon configuration file $SYSMON_CFG_FILE for ${HOSTNAME} wasn't found.\n";
        my $mail_mess2 = "A new one was created based on the template file ${SYSMON_STD_FILE}.\n";    
        my $mail_message = "${mail_mess0}${mail_mess1}${mail_mess2}";
        my $mail_subject = "SADM: INFO $SYSMON_CFG_FILE not found on $HOSTNAME";
        @cmd = ("echo \"$mail_message\" | $CMD_MAIL -s \"$mail_subject\" $SADM_MAIL_ADDR");
        $return_code = 0xffff & system @cmd ;                           # Perform Mail Command 
        @cmd = ("$CMD_CP $SYSMON_STD_FILE $SYSMON_CFG_FILE");           # cp template standard.smon 
        $return_code = 0xffff & system @cmd ;                           # Perform Command cp
        @cmd = ("$CMD_CHMOD 664 $SYSMON_CFG_FILE");                     # Make hostname.smon 664
        $return_code = 0xffff & system @cmd ;                           # Perform Command chmod
    }

    # OPEN SYSMON HOST CONFIGURATION FILE AND LOAD IT IN AN ARRAY CALLED SYSMON_ARRAY
    open (SMONFILE,"<$SYSMON_CFG_FILE") or die "Can't open $SYSMON_CFG_FILE: $!\n";
    $widx = 0;                                                          # Array Index
    while ($line = <SMONFILE>) {                                        # Read while end of file
        next if $line =~ /^#SYSMON/ ;                                 # Don't load sysmon statline
        $sysmon_array[$widx++] = $line ;                                # Load Line in Array
        if ($SYSMON_DEBUG >= 6) { print "Line loaded from cfg : $line" ; }
    }
    close SMONFILE;                                                     # Close SysMon Config file

    # IF IN DEBUG MODE DISPLAY NUMBER OF ELEMENT LOADED
    if ($SYSMON_DEBUG >= 5) {                                           # If in debug mode 
        $nbline = @sysmon_array;                                        # Get Nb. of element loaded
        print "File $SYSMON_CFG_FILE loaded in sysmon_array ($nbline lines loaded)\n";
    }
    if ($SYSMON_DEBUG >= 6)  { show_sysmon_array ; }                 # If Debug >=6 Display Array
}



#---------------------------------------------------------------------------------------------------
# Unload the sysmon array back to `hostname`.smon configuration file with updated values
#---------------------------------------------------------------------------------------------------
sub unload_smon_file {
    if ($SYSMON_DEBUG >= 5) {                                           # Debug Show what we do
        print "\n\n-----\nUpdating SADM Sysmon configuration file ($SYSMON_CFG_FILE)";
    }

    # OPEN (CREATE) AN EMPTY TEMPORARY FILE TO UNLOAD SYSMON CONFIG FILE
    open (SADMTMP,">$SADM_TMP_FILE1") or die "Can't create $SADM_TMP_FILE1: $!\n";

    # UNLOAD SYSMON_ARRAY TO DISK
    for ($widx = 0; $widx < @sysmon_array; $widx++) {                   # Loop until end of array
        print (SADMTMP "$sysmon_array[$widx]");                         # Write line to config file
    }

    # GET ENDING TIME & WRITE SADM STATISTIC LINE AT THE EOF
    $end_time = time;                                                   # Get current time
    $xline1 = sprintf ("#SYSMON $VERSION_NUMBER $HOSTNAME - ");
    $xline2 = sprintf ("%s" , scalar localtime(time));
    $xline3 = sprintf (" - Execution Time %2.2f seconds\n" ,$end_time - $start_time); 
    printf (SADMTMP "${xline1}${xline2}${xline3}");
    close SADMTMP ;                                                     # Close temporary file

    # DELETE OLD SYSMON CONFIG FILE AND RENAME THE TEMP FILE TO SADM SYSMON FILE
    unlink "$SYSMON_CFG_FILE" ;                                         # Delete Cur `hostname`.smon
    if (!rename "$SADM_TMP_FILE1", "$SYSMON_CFG_FILE")                  # Rename to `hostname`.smon
       { print "Could not rename $SADM_TMP_FILE1 to $SYSMON_CFG_FILE: $!\n" }
    system ("chmod 664 $SYSMON_CFG_FILE");                              # Make file rw for gou
    system ("chown ${SADM_USER}:${SADM_GROUP} ${SYSMON_CFG_FILE}");     # Assign User/Group SADMIN
}



#---------------------------------------------------------------------------------------------------
# Called in Debug Mode to display sysmon_array content
#---------------------------------------------------------------------------------------------------
sub show_sysmon_array {
    for ($widx = 0; $widx < @sysmon_array; $widx++) { 
        print ("$sysmon_array[$widx]"); 
    }
}



#---------------------------------------------------------------------------------------------------
# Extract each field from the line (`hostname`.smon file format) received in parameter.
#---------------------------------------------------------------------------------------------------
sub split_fields {
    my $wline = $_[0];
        (   $SADM_RECORD->{SADM_ID},
            $SADM_RECORD->{SADM_CURVAL},
            $SADM_RECORD->{SADM_TEST},
            $SADM_RECORD->{SADM_WARVAL},
            $SADM_RECORD->{SADM_ERRVAL},
            $SADM_RECORD->{SADM_MINUTES},
            $SADM_RECORD->{SADM_STHRS},
            $SADM_RECORD->{SADM_ENDHRS},
            $SADM_RECORD->{SADM_SUN},
            $SADM_RECORD->{SADM_MON},
            $SADM_RECORD->{SADM_TUE},
            $SADM_RECORD->{SADM_WED},
            $SADM_RECORD->{SADM_THU},
            $SADM_RECORD->{SADM_FRI},
            $SADM_RECORD->{SADM_SAT},
            $SADM_RECORD->{SADM_ACTIVE},
            $SADM_RECORD->{SADM_DATE},
            $SADM_RECORD->{SADM_TIME},
            $SADM_RECORD->{SADM_SLACK_CHANNEL},
            $SADM_RECORD->{SADM_MAIL_GROUP},
            $SADM_RECORD->{SADM_SCRIPT} ) = split ' ',$wline;
}



#---------------------------------------------------------------------------------------------------
# Combine all fields from SADM_RECORD back together into a line with `hostname`.smon format.
# --------------------------------------------------------------------------------------------------
sub combine_fields {
    my $wline = sprintf "%-30s %3s %2s %3s %3s %3s %04d %04d %1s %1s %1s %1s %1s %1s %1s %1s %08d %04d %s %s %s\n",
        $SADM_RECORD->{SADM_ID},
        $SADM_RECORD->{SADM_CURVAL},
        $SADM_RECORD->{SADM_TEST},
        $SADM_RECORD->{SADM_WARVAL},
        $SADM_RECORD->{SADM_ERRVAL},
        $SADM_RECORD->{SADM_MINUTES},
        $SADM_RECORD->{SADM_STHRS},
        $SADM_RECORD->{SADM_ENDHRS},
        $SADM_RECORD->{SADM_SUN},
        $SADM_RECORD->{SADM_MON},
        $SADM_RECORD->{SADM_TUE},
        $SADM_RECORD->{SADM_WED},
        $SADM_RECORD->{SADM_THU},
        $SADM_RECORD->{SADM_FRI},
        $SADM_RECORD->{SADM_SAT},
        $SADM_RECORD->{SADM_ACTIVE},
        $SADM_RECORD->{SADM_DATE},                  # Last Time that the error Occured
        $SADM_RECORD->{SADM_TIME},
        $SADM_RECORD->{SADM_SLACK_CHANNEL},               # Alert Type (mail,slac,qpage,...)
        $SADM_RECORD->{SADM_MAIL_GROUP},
        $SADM_RECORD->{SADM_SCRIPT};
    return "$wline";
}



#---------------------------------------------------------------------------------------------------
# Filesystem Increase Function
#---------------------------------------------------------------------------------------------------
sub filesystem_increase {
    my ($FILESYSTEM) = @_;                                              # Filesystem name to enlarge
    print "\n\nFilesystem $FILESYSTEM selected for increase";           # Show User Filesystem Incr.
    my $FS_SCRIPT = "${SADM_BIN_DIR}/$SADM_RECORD->{SADM_SCRIPT}";      # Get FS Enlarge Script Name
    print "\nName of script is  ..${FS_SCRIPT}..";                      # Show User Filesystem Incr.

    # If no script specified - Return to caller
    if ((length $SADM_RECORD->{SADM_SCRIPT} == 0 ) || ($SADM_RECORD->{SADM_SCRIPT} eq "-") || ($SADM_RECORD->{SADM_SCRIPT} eq " ")) { 
        print "\nNo Script specified for execution in hostname.smon";
        print "\nNo Filesystem increase will happen";
        return 0 ;
    }

    # Make sure script Exist and is executable - If not return to caller
    if (( ! -e "$FS_SCRIPT" ) || ( ! -x "$FS_SCRIPT")) { 
        print "\nScript $FS_SCRIPT doesn't exist or is not executable";
        print "\nNo Filesystem increase will happen";
        return 0 ;
    }

    $FSCMD = "$FS_SCRIPT $FILESYSTEM >>${SADM_LOG_DIR}/$SADM_RECORD->{SADM_SCRIPT}.log 2>&1" ;
    print "\n  - Command executed: $FSCMD";                             # SHow User CMD to Increase
    @args = ("$FSCMD");                                                 # Build System Cmd
    $src = system(@args) ;                                              # Execute FS Increase Script
    if ( $src == -1 ) {                                                 # If FS Enlarge Failed
        print "\n  - [ERROR] Command failed: $!";                       # Advise USer
    }else{                                                              # If FS Enlarge Succeeded
        printf "\n  - [OK] Return Code: %d", $? >> 8; 
    }
    return $src ;                                                       # Return Err. Code to Caller
}



#---------------------------------------------------------------------------------------------------
# Function the check Actual Value against the warning and error value
# Fields received as parameters ;
#   - Actual Value ($ACTVAL), Warning Value ($WARVAL), Error Value ($ERRVAL), 
#   - Test to make (>=, <=, !=, =, <, >)
#   - Name of Module ($MODULE), Name of SubModule ($SUBMODULE)
#   - Precision, Value use in error message
#---------------------------------------------------------------------------------------------------
sub check_for_error {
    my ($ACTVAL,$WARVAL,$ERRVAL,$TEST,$MODULE,$SUBMODULE,$WID)=@_;      # Split Array Received
    if ($SYSMON_DEBUG >= 6) { 
        print "\nCheck_for_error Function";
        print "\nActual Value  = $ACTVAL";
        print "\nWarning Value = $WARVAL";
        print "\nError Value   = $ERRVAL";
        print "\nTest Operator = $TEST";
        print "\nModule        = $MODULE";
        print "\nSub-Module    = $SUBMODULE";
        print "\nWID           = $WID";
    } 
    $alert_type="N";                                                    # No Error by default

    # If the test to perform involve ">=" operator.
    if ($TEST eq ">=" ) {                                               # Operator >= was used 
        if (($ACTVAL >= $WARVAL) && ($WARVAL != 0)) {                   # Act.Value vs Warning Value
            $alert_type="W";                                            # Err. Detected is a warning
            $value_exceeded=$WARVAL;                                    # Save the Warning value
        }
        if (($ACTVAL >= $ERRVAL) && ($ERRVAL != 0)) {                   # Act.Value vs Error Value
            $alert_type="E";                                            # Err. Detected is a Error
            $value_exceeded=$ERRVAL;                                    # Save the Error value
        }
    }

    # If the test to perform involve "<=" operator.
    if ($TEST eq "<=" ) {                                               # Operator <= was used 
        if (($ACTVAL <= $WARVAL) && ($WARVAL != 0)) {                   # Act.Value vs Warning Value
            $alert_type="W";                                            # Err. Detected is a warning
            $value_exceeded=$WARVAL;                                    # Save the Warning value
        }
        if (($ACTVAL <= $ERRVAL) && ($ERRVAL != 0)) {                   # Act.Value vs Error Value
            $alert_type="E";                                            # Err. Detected is a Error
            $value_exceeded=$ERRVAL;                                    # Save the Error value
        }
    }

    # If the test to perform involve "!=" operator.
    if ($TEST eq "!=" ) {                                               # Operator != was used
        if (($ACTVAL != $WARVAL) && ($WARVAL != 0)) {                   # Act.Value vs Warning Value
            $alert_type="W";                                            # Err. Detected is a warning
            $value_exceeded=$WARVAL;                                    # Save the Warning value
        }
        if (($ACTVAL != $ERRVAL) && ($ERRVAL != 0)) {                   # Act.Value vs Error Value
            $alert_type="E";                                            # Err. Detected is a Error
            $value_exceeded=$ERRVAL;                                    # Save the Error value
        }
    }

    # If the test to perform involve "=" operator
    if ($TEST eq "=" ) {                                                # Operator != was used
        if (($ACTVAL == $WARVAL) && ($WARVAL != 0)) {                   # Act.Value vs Warning Value
            $alert_type="W";                                            # Err. Detected is a warning
            $value_exceeded=$WARVAL;                                    # Save the Warning value
        }
        if (($ACTVAL == $ERRVAL) && ($ERRVAL != 0)) {                   # Act.Value vs Error Value
            $alert_type="E";                                            # Err. Detected is a Error
            $value_exceeded=$ERRVAL;                                    # Save the Error value
        }
    }

    # If the test to perform involve "<" operator.
    if ($TEST eq "<" ) {                                                # Operator < was used
        if (($ACTVAL < $WARVAL) && ($WARVAL != 0)) {                    # Act.Value vs Warning Value
            $alert_type="W";                                            # Err. Detected is a warning
            $value_exceeded=$WARVAL;                                    # Save the Warning value
        }
        if (($ACTVAL < $ERRVAL) && ($ERRVAL != 0)) {                    # Act.Value vs Error Value
            $alert_type="E";                                            # Err. Detected is a Error
            $value_exceeded=$ERRVAL;                                    # Save the Error value
        }
    }

    # If the test to perform involve ">" operator.
    if ($TEST eq ">" ) {                                                # Operator > was used
        if (($ACTVAL > $WARVAL) && ($WARVAL != 0)) {                    # Act.Value vs Warning Value
            $alert_type="W";                                            # Err. Detected is a warning
            $value_exceeded=$WARVAL;                                    # Save the Warning value
        }
        if (($ACTVAL > $ERRVAL) && ($ERRVAL != 0)) {                    # Act.Value vs Error Value
            $alert_type="E";                                            # Err. Detected is a Error
            $value_exceeded=$ERRVAL;                                    # Save the Error value
        }
    }

    # If no error was detected - exit function
    if ($alert_type eq "N") { return ; }                                # Return to caller

    ## Operating System Error Related Section
    if (($MODULE eq "aix") || ($MODULE eq "linux")) {                   # If Module is aix or linux

      ## Load average alert occured
      if ($SUBMODULE eq "LOAD") {                                       # Check Uptime Load Average
        ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();   # Get Date,Time,Epoch Time
        if ($SYSMON_DEBUG >= 5) {                                       # If DEBUG Activated
           print "\nActual Time: $year $month $day $hour $min $sec - $epoch"; # Actual Time & Epoch
        }
        # If it is the first occurence of the Error - Save Current Date and Time in RECORD
        if ( $SADM_RECORD->{SADM_DATE} == 0 ) {                                  # No Prev.Date/Time
           $SADM_RECORD->{SADM_DATE}=sprintf ("%04d%02d%02d",$year,$month,$day); # Save Excess Date
           $SADM_RECORD->{SADM_TIME}=sprintf ("%02d%02d",$hour,$min,$sec);       # Save Excess Time
        }
        # Split Date and Time when the load began to exceed warning or error value
        $wyear  =sprintf "%04d",substr($SADM_RECORD->{SADM_DATE},0,4);  # Extract Year Error started
        $wmonth =sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},4,2);  # Extract Mth Error started
        $wday   =sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},6,2);  # Extract Day Error Started
        $whrs   =sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},0,2);  # Extract Hrs Error Started
        $wmin   =sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},2,2);  # Extract Min Error Started
        # Get Epoch Time of the last time we had a load exceeded
        $last_epoch = get_epoch("$wyear", "$wmonth", "$wday", "$whrs", "$wmin", "0"); 
        if ($SYSMON_DEBUG >= 5) { 
            print "\nLoad Average Alert started at $wyear $wmonth $wday $whrs $wmin 00 - $last_epoch"; 
        }
        # Calculate number of seconds before SADM report the error (Min * 60 sec)
        $elapse_second = $epoch - $last_epoch;                          # Cur. Epoch - $last_epoch
        $max_second = $SADM_RECORD->{SADM_MINUTES} * 60 ;               # Min. Before alert in Sec.
        if ($SYSMON_DEBUG >= 5) {                                       # Under Debug Mode
           print "\nSo $epoch - $last_epoch = $elapse_second seconds";  # Sec. Elapse Since Started
           print "\nYou asked to wait $max_second seconds before issuing alert";
        }
        # If number of second since the last error is greater than wanted - Issue Alert
        if ( $elapse_second >= $max_second ) {                          # Problem Exceed Sec. Wait 
           $wmin = $SADM_RECORD->{SADM_MINUTES};                        # min. before issuing alert
           $ERR_MESS = "Load Average at $WID & exceed $value_exceeded for more than $wmin Min";
           write_rpt_file($alert_type,"$OSNAME","LOAD",$ERR_MESS);    # Go Reporting Alert
           $SADM_RECORD->{SADM_DATE} = $SADM_RECORD->{SADM_TIME} = 0 ;  # Reset Last Alert Date/Time
        }
      } 
           
      ## Paging alert occured
      if ($SUBMODULE eq "PAGING") {                                     # When Paging Alert
            $ERR_MESS = "Paging space at $ACTVAL% > $value_exceeded%" ; # Build Error Message
            write_rpt_file($alert_type,"$OSNAME","PAGING",$ERR_MESS );# Go Report Alert
      }
      
      ## Multipath alert occured     
      if ($SUBMODULE eq "MULTIPATH")   {                                # When Multipath Alert 
         $ERR_MESS = "MultiPath Error - Status is $WID" ;               # Build Error Message
         write_rpt_file($alert_type,"$OSNAME","MULTIPATH",$ERR_MESS );# Go Report Alert
      } 
      
      ## Cpu utilization percentage alert 
      if ($SUBMODULE eq "CPU") {                                        # When CPU Utilization Alert
         ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();  # Get Date,Time, Epoch Time
         if ($SYSMON_DEBUG >= 5) {                                      # IF Debug Level >= 5
            print "\nActual Time is $year $month $day $hour $min $sec"; # Show Current Date/Time
            print "\nActual epoch time is $epoch";                      # Show Current Epoch Time
         }
         # If it is the first occurence of the Error - Save Current Date and Time in RECORD
         if ( $SADM_RECORD->{SADM_DATE} == 0 ) {                                  # No Prev.Date/Time
            $SADM_RECORD->{SADM_DATE}=sprintf ("%04d%02d%02d",$year,$month,$day); # Save Excess Date
            $SADM_RECORD->{SADM_TIME}=sprintf ("%02d%02d",$hour,$min,$sec);       # Save Excess Time
         }
         # Split Date and Time when the load began to exceed warning or error value
         $wyear  =sprintf "%04d",substr($SADM_RECORD->{SADM_DATE},0,4);  # Extract Year Error started
         $wmonth =sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},4,2);  # Extract Mth Error started
         $wday   =sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},6,2);  # Extract Day Error Started
         $whrs   =sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},0,2);  # Extract Hrs Error Started
         $wmin   =sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},2,2);  # Extract Min Error Started
         # Get Epoch Time of the last time we started to have an exceeding load
         $last_epoch = get_epoch("$wyear","$wmonth","$wday","$whrs","$wmin","0"); 
         if ($SYSMON_DEBUG >= 5) { 
             print "\nLoad on cpu started at $wyear $wmonth $wday $whrs $wmin 00 - $last_epoch";
         }
         # Calculate number of seconds before SYSMON report the errors (Min * 60 sec)
         $elapse_second = $epoch - $last_epoch;                         # Nb Sec. Since Load Started
         $max_second = $SADM_RECORD->{SADM_MINUTES} * 60 ;
         if ($SYSMON_DEBUG >= 5) { 
            print "\nSo $epoch - $last_epoch = $elapse_second seconds";
            print "\nYou asked to wait $max_second seconds before report an error";
         }
        # If number of second since the last error is greater than wanted - Issue Alert
        if ( $elapse_second >= $max_second ) {                          # Problem Exceed Sec. Wait 
           $wmin = $SADM_RECORD->{SADM_MINUTES};                        # min. before issuing alert
           $ERR_MESS = sprintf("CPU at %-3d pct for more than %-3d min",$ACTVAL,$wmin);
           write_rpt_file($alert_type,"$OSNAME","CPU",$ERR_MESS );      # Go Process Alert
           $SADM_RECORD->{SADM_DATE} = $SADM_RECORD->{SADM_TIME} = 0 ;  # Reset Last Alert Date/Time
        }
      }  

      ## Filesystem alert occured
      if (($SUBMODULE eq "FILESYSTEM") && ($MODULE eq "linux")) {       # If Filesystem SIze Alert
         $ERR_MESS = "Filesystem $WID at $ACTVAL% > $value_exceeded%";  # Set up Error Message
         write_rpt_file($alert_type,"$OSNAME","FILESYSTEM",$ERR_MESS);  # Go Report Alert 
    
         # If no script specified - Return to caller
         if ((length $SADM_RECORD->{SADM_SCRIPT} == 0 ) || ($SADM_RECORD->{SADM_SCRIPT} eq "-") || ($SADM_RECORD->{SADM_SCRIPT} eq " ")) { 
            print "\nNo Script specified for execution in hostname.smon";
            print "\nNo Filesystem increase will happen";
            return 0 ;
         }

         ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();  # Get current epoch time
         if ($SYSMON_DEBUG >= 5) {                                      # If Debug is ON
            print "\n\nFilesystem Increase: $WID at $ACTVAL%";          # FileSystem Incr. Entered
            print "\nActual Date and Time   : $year $month $day $hour $min $sec - $epoch";
         }
         # If it is the first occurence of the Error - Save Current Date and Time in RECORD
         if ( $SADM_RECORD->{SADM_DATE} == 0 ) {                                 # No Prev.Date/Time
            $SADM_RECORD->{SADM_DATE}=sprintf ("%04d%02d%02d",$year,$month,$day);# Save Excess Date
            $SADM_RECORD->{SADM_TIME}=sprintf ("%02d%02d",$hour,$min,$sec);      # Save Excess Time
         }
         # Split Date and Time when the last file increase Happened 
         $wyear  =sprintf "%04d",substr($SADM_RECORD->{SADM_DATE},0,4); # Extract Year Error started
         $wmonth =sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},4,2); # Extract Mth Error started
         $wday   =sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},6,2); # Extract Day Error Started
         $whrs   =sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},0,2); # Extract Hrs Error Started
         $wmin   =sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},2,2); # Extract Min Error Started
         $last_epoch = get_epoch("$wyear","$wmonth","$wday","$whrs","$wmin","0"); 
         if ($SYSMON_DEBUG >= 5) {                                      # If DEBUG if ON
            print "\nLast increase attempt  : $wyear $wmonth $wday $whrs $wmin 00 - $last_epoch";
         }
         # Calculate the number of seconds since the last execution 
         $elapse_second = $epoch - $last_epoch;                          # Subs Act.epoch-Last epoch
         if ($SYSMON_DEBUG >= 5) {                                       # If DEBUG Activated
            print "\nSo $elapse_second seconds since last increase";     # Print Elapsed seconds
         }
         # If nb. of Seconds since last increase is greater than 1 Day (86400 Sec) = OK RUN
         if ( $elapse_second >= $MINIMUM_SEC ) {                         # Elapsed Sec >= 86400 Sec.
            ($year,$month,$day,$hour,$min,$sec,$epoch) =Today_and_Now(); # Get current epoch time
            $SADM_RECORD->{SADM_DATE} = sprintf("%04d%02d%02d", $year,$month,$day); 
            $SADM_RECORD->{SADM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);        
            $SADM_RECORD->{SADM_MINUTES} = "001";                        # First FS Increase Today
            if ($SYSMON_DEBUG >= 5) { print "\nFirst filesystem increase in last 24 Hours"; }
                filesystem_increase($WID);                               # Go Increase Filesystem
         }else{
            if (($SADM_RECORD->{SADM_MINUTES} + 1) > $MAX_FS_INCR){      # If FS Incr Counter > 2
               if ($SYSMON_DEBUG >= 5) {                                 # If DEBUG Activated
                  print "\nDone more than $MAX_FS_INCR Filesystem increase of $WID in last 24 Hrs";
                  print "\nFilesystem increase will not be done.";       # Inform user not done
               }
               #$ERR_MESS = "FS $WID at $ACTVAL% > $value_exceeded%" ;    # Set up Error Message
               #write_rpt_file($alert_type,"$OSNAME","FILESYSTEM",$ERR_MESS); # Go Process Alert
            }else{
               $WORK = $SADM_RECORD->{SADM_MINUTES} + 1;                 # Incr. FS Counter
               $SADM_RECORD->{SADM_MINUTES} = sprintf("%03d",$WORK);     # Insert Cnt in Array
               if ($SYSMON_DEBUG >= 5) {                                 # If DEBUG Activated
                  print "\nFilesystem increase counter: $SADM_RECORD->{SADM_MINUTES} ";
               }
               filesystem_increase($WID);                                # Go Increase Filesystem
            }
         }
      } 
    } # End of AIX/LINUX Module 
             

   ## Error detected for the Module name "NETWORK" 
   if ($MODULE eq "NETWORK")   { 
      if ($SUBMODULE eq "PING")   { 
         if ($SYSMON_DEBUG >= 5) { print "\nPing to server $WID failed"; }
         $ERR_MESS = "Cannot ping server $WID" ;
         write_rpt_file($alert_type,"NETWORK","PING",$ERR_MESS );
      }
   } 

    ## Script execution Alert 
    if ($MODULE eq "SCRIPT")   {                                        # If Script Execution Alert 
        $ERR_MESS = "Script ${WID} failed !" ;                          # Build Error Message
        my $smess = "${WID}.txt";                                       # Custom Message Text File
        if ( -e "${SADM_SCR_DIR}/$smess" ) {                            # Does Custom  Mess Exist ?
            print "\nUsing message in ${SADM_SCR_DIR}/$smess for rpt file";
            open SMESSAGE, "${SADM_SCR_DIR}/$smess" or die $!;          # Open Script Message File
            while ($sline = <SMESSAGE>) {                               # Read Message file
                chomp $sline; $ERR_MESS="$sline ";                      # Get Text Message
            }
            close SMESSAGE;                                             # Close Script Message File
        }
        write_rpt_file($alert_type,"SCRIPT","${WID}",$ERR_MESS );     # Go Report Alert
    } 

   #---------- Error detected for the Module HTTP
   if ($MODULE eq "HTTP")   {                                           # Error WebSite no Response
      $ERR_MESS = "Web Site $WID isn't responding" ;                    # Prepare Mess. to rpt file
      write_rpt_file($alert_type ,"HTTP", "WEBSITE", $ERR_MESS );     # Go write ALert to rpt file
   } # End of HTTP Module

   #---------- Error detected - A Daemon was suppose to be running and it is not
   if ($MODULE eq "DAEMON") {                                           # If Daemon Error
      if ($SUBMODULE eq "PROCESS") {                                    # Process Sub-Module
         $ERR_MESS = "Daemon $WID not running !";                       # Prepare Mess. to rpt file
         write_rpt_file($alert_type,"DAEMON","PROCESS",$ERR_MESS );   # Go write ALert to rpt file
      }  
   } # End of Daemon Module

   #---------- Error detected - A service was suppose to be running and it is not
   if ($MODULE eq "SERVICE") {                                          # If Service not Running
      if ($SUBMODULE eq "DAEMON") {                                     # And Daemon as a Sub-Module
         $ERR_MESS = "Service $WID not running !";                      # Prepare Mess. to rpt file
         write_rpt_file($alert_type,"SERVICE","DAEMON",$ERR_MESS );   # Go write ALert to rpt file
      }  
   } # End of Service Module
} 



#---------------------------------------------------------------------------------------------------
# Check if we have a response from the web site
#---------------------------------------------------------------------------------------------------
sub check_http {

    # From the sysmon_array extract the application name
    @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;                       # Split Current line ID
    $HTTP = $dummy[1];                                                  # Get URL from dummy array
    my $url="http://${HTTP}";                                           # Build URL to check
    print "\n\nChecking response from $url ... ";                       # Show User what we check

    # Get document headers. 
    # Returns the following 5 values if successful: 
    #   - ($content_type, $document_length, $modified_time, $expires, $server)
    # Returns an empty list if it fails. In scalar context returns TRUE if successful.
    $ua->timeout(3);                                                    # Timeout if not responding
    if (! head($url)) { $http_status=0; }else{ $http_status=1; }        # Status based on response
    if ($http_status == 0) {                                            # If no response for URL
        printf "\n[ERROR] Web site not responding" ;                    # Show error to user
    }else{                                                              # If URL Response
        printf "\n[OK] Web site is responding";                         # Show URL responded
    }

    #----- Put current value in sadm array and check for error.
    $SADM_RECORD->{SADM_CURVAL} = $http_status ;                        # Put Status in SADM_RECORD
    $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                               # Current Value
    $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                               # Warning Threshold Value
    $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                               # Error Threshold Value
    $TEST = $SADM_RECORD->{SADM_TEST}   ;                               # Test Operator (=,<=,!=,..)
    $MOD  = "HTTP"                      ;                               # Module Category
    $SMOD = "WEBSITE"                   ;                               # Sub-Module Category
    $STAT = $HTTP                       ;                               # URL of Web Site
    check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);          # Go Evaluate Error/Alert 
    return;                                                             # Return to Caller
}



#---------------------------------------------------------------------------------------------------
# Check if the specified service is running 
#   - Service can have different name depending of the version of linux your using.
#       - Can specify multiple name 'service_syslog|rsyslog|syslogd' for same service
#   - If it's not running try to start it 2 times 
#   - If it can't be started then trigger an alert
#slam_master.pl:            if ($alias ne "none" and $alias ne $hostname) 
# launchctl list | grep ssh
#---------------------------------------------------------------------------------------------------
sub check_service {
    if ( $OSNAME eq "darwin" ) { return ; }                             # Not Yet Supported on MacOS
    @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;                       # Split service Line 
    my $SERVICE = $dummy[1];                                            # Get Service name Part
    print "\n\nChecking service $SERVICE";                              # Show Service Name(s)


    #----- From the sysmon_array extract the service name
    my $service_count = 0 ;                                             # Service Running counter
#    my @service = split ('\|', $SERVICE );                              # Put All Srv. name in array
    my @service = split (',', $SERVICE );                               # Put All Srv. name in array
    foreach my $srv (@service) {                                        # For each service in array
        if ($SYSMON_DEBUG >= 6) { print "\nChecking the service $srv"; }
        $srv_name = $srv ;                                              # Save Current Service name
        if ( $CMD_SYSTEMCTL eq "") {                                    # If not using systemctl
            my $CMD = "service $srv status" ;                           # Get SysV Service Status
            print "\n  - ${CMD} ... " ;                                 # Show CMD to be executed
            if ( system("$CMD >/dev/null 2>&1") == 0 ) {                # If Service is running
                $service_ok = 1 ;                                       # Set Service Increment
                $srv_name = $srv ;                                      # Save name of running serv.
                print "[RUNNING]";                                      # Show Service is running
            }else{                                                      # If service not running
                $service_ok = 0 ;                                       # Set Service Increment
                print "[NOT RUNNING]";                                  # Show Service isn't running
            }
        }else{                                                          # If host using systemd
            my $CMD = "systemctl status ${srv}.service" ;               # Cmd to get service status
            print "\n  - ${CMD} ... ";                                  # Show CMD to be executed
            if ( system("$CMD >/dev/null 2>&1") == 0 ) {                # If Service is running
                $service_ok = 1 ;                                       # Set Service Increment
                $srv_name = $srv ;                                      # Save name of running serv.
                print "[RUNNING]";                                      # Show Service is running
            }else{                                                      # If service not running
                $service_ok = 0 ;                                       # Set Service Increment
                print "[NOT RUNNING]";                                  # Show Service isn't running
            }
        }
        $service_count = $service_count + $service_ok ;                 # Upd. Running Service total
    }

    # Show Service Check Result
    if ($service_count >= 1) {                                          # At least 1 service running
        printf "\n[OK] Service is running - Total returned (%d)",$service_count;
    }else{                                                              # No Service are running
        printf "\n[ERROR] Service isn't running - Total returned (%d)",$service_count;
    }

    #----- Put current value in sadm array and check for error.
    $SADM_RECORD->{SADM_CURVAL} = $service_count ;                      # Put cur.val. in sadm_array
    $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                               # Current Value
    $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                               # Warning Threshold Value
    $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                               # Error Threshold Value
    $TEST = $SADM_RECORD->{SADM_TEST}   ;                               # Test Operator (=,<=,!=,..)
    $MOD  = "SERVICE"                   ;                               # Module Category
    $SMOD = "DAEMON"                    ;                               # Sub-Module Category
    $STAT = $srv_name                   ;                               # Running/Not Running Service
    check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);          # Go Evaluate Error/Alert 
    return;                                                             # Return to Caller
}



#---------------------------------------------------------------------------------------------------
# Check if Daemon/Process is running
#---------------------------------------------------------------------------------------------------
sub check_daemon {

    @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;                       # Split Line ID daemon_name
    $pname = $dummy[1];                                                 # Extract Daemon Name
    print "\n\nDaemon/Process named \"$pname \" running ... ";          # Show starting to check 

    # Grep for daemon/process in the PSFILE1
    open (PFILE,"grep \"$pname\" $PSFILE1 |grep -v grep  |wc -l|");     # Grep Name in PS File1
    $daemon1 = <PFILE> ; chop $daemon1 ; $daemon1 = int $daemon1;       # Nb. of Process with name
    close PFILE;                                                        # Close StdOut 

    # Grep for daemon/process in the PSFILE2
    open (PFILE, "grep \"$pname\"  $PSFILE2 | grep -v grep | wc -l|");  # Grep Name in PS File1
    $daemon2 = <PFILE> ; chop $daemon2 ; $daemon2 = int $daemon2;       # Nb. of Process with name
    close PFILE;                                                        # Close StdOut
    
    # Keep only the largest number
    if ( $daemon1 >= $daemon2 ) { $daemon = $daemon1 }else{ $daemon = $daemon2 } ; 

    # Set Parameter of Current Evaluation, ready to be evaluated. 
    $SADM_RECORD->{SADM_CURVAL} = $daemon ;                             # Save Nb.Process in Array
    $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                               # Current Value
    $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                               # Warning Threshold Value
    $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                               # Error Threshold Value
    $TEST = $SADM_RECORD->{SADM_TEST}   ;                               # Test Operator (=,<=,!=,..)
    $MOD  = "DAEMON"                    ;                               # Module Category
    $SMOD = "PROCESS"                   ;                               # Sub-Module Category
    $STAT = $pname                      ;                               # Name of deamon
    if ($CVAL > 0) {                                                    # At least 1 process running
        printf "\n[OK] Number of %s running is %d",$pname, $CVAL;       # Show number of Process
    }else{                                                              # No Process running
        printf "\n[ERROR] No process named %s are running",$pname;      # Show No process are running
    }
    check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);          # Go Evaluate Error/Alert 
    return;                                                             # Return to Caller
}



#---------------------------------------------------------------------------------------------------
# Function tha return date and time of the day
# Example : ($cyear,$cmonth,$cday,$chour,$cmin,$csec,$cepoch) = today_and_now();
#---------------------------------------------------------------------------------------------------
sub Today_and_Now {
    $ctyear  = strftime ("%Y", localtime);                              # The year including century
    $ctmonth = strftime ("%m", localtime);                              # The month range 01 to 12
    $ctday   = strftime ("%d", localtime);                              # The day of month 01 to 31
    $cthrs   = strftime ("%H", localtime);                              # The hour (range 00 to 23)
    $ctmin   = strftime ("%M", localtime);                              # The minute range 00 to 59
    $ctsec   = strftime ("%S", localtime);                              # The second range 00 to 60
    $ctepoch = time();                                                  # Epoch Time
    return ($ctyear,$ctmonth,$ctday,$cthrs,$ctmin,$ctsec,$ctepoch);     # Return Date Info
}



#---------------------------------------------------------------------------------------------------
# Function that accept a date and return the opech time
# Example : $wepoch = get_epoch($cyear,$cmonth,$cday,$chour,$cmin,$csec);
#---------------------------------------------------------------------------------------------------
sub get_epoch {
    my ($eyear, $emonth, $eday, $ehrs, $emin, $esec) = @_;              # Split Array Received
    $emth=$emonth-1 ;                                                   # Substract 1 from month
    if ($SYSMON_DEBUG >= 7) {                                           # Debug Level >= 7
        print "\n$epoch_time = timelocal($esec,$emin,$ehrs,$eday,$emth,$eyear)";
    }
    #$epoch_time = timelocal($esec,$emin,$ehrs,$eday,$emonth,$eyear);    # Calc. Epoch Time
    $epoch_time = timelocal($esec,$emin,$ehrs,$eday,$emth,$eyear);    # Calc. Epoch Time
    if ($SYSMON_DEBUG >= 7) {                                           # Debug Level >= 7
        print "\nepoch_time = $epoch_time";
    }
    return $epoch_time;                                                 # Return Epoch Time
}



#---------------------------------------------------------------------------------------------------
# Check CPU Load Average
#---------------------------------------------------------------------------------------------------
sub check_load_average {
    print "\n\nChecking CPU Load Average ...";                          # Entering Load Average Test

    # Get Load Average - Via the uptime command
    open (DB_FILE, "$CMD_UPTIME |");                                    # 'uptime' output to stdout
    $load_line = <DB_FILE> ;                                            # Save output to load_line
    @ligne = split ' ',$load_line;                                      # Split line based on space
    @dummy = split ',',$ligne[11];                                      # Get 11th Parm/Recent Load
    $load_average = int $dummy[0];                                      # Save Load Average
    if ($SYSMON_DEBUG >= 5) {                                           # Debug Level >= 5
        printf "\nUptime line: $load_line";                            # Print uptime output line
    }
    close DB_FILE;                                                      # Close Output of command
    $SADM_RECORD->{SADM_CURVAL} = sprintf "%d" ,$load_average ;         # Put value in sysmon_array
    
    # If load average less than warning value then Reset Date & Time of last exceeded to 0
    if ($SADM_RECORD->{SADM_CURVAL} < $SADM_RECORD->{SADM_WARVAL}) {    # If CurVal < Warning Value
        $SADM_RECORD->{SADM_DATE} = $SADM_RECORD->{SADM_TIME} = 0 ;     # Rest Last Surplus Date/Time
    }
    
    # Set Parameter of Current Evaluation, ready to be evaluated. 
    $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                               # Current Value
    $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                               # Warning Threshold Value
    $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                               # Error Threshold Value
    $TEST = $SADM_RECORD->{SADM_TEST}   ;                               # Test Operator (=,<=,!=,..)
    $MOD  = "$OSNAME"                   ;                               # Module Category
    $SMOD = "LOAD"                      ;                               # Sub-Module Category
    $STAT = $load_average               ;                               # Current Status Returned
    if ($SYSMON_DEBUG >= 5) {                                           # Debug Level at least 5
        printf "Load Average is at $load_average - W: $WVAL E: $EVAL";  # Actual/Warning/Error Value
    }
    check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);          # Go Evaluate Error/Alert 
    return;                                                             # Return to Caller
}



#---------------------------------------------------------------------------------------------------
# Check CPU (user + system) usage
#---------------------------------------------------------------------------------------------------
sub check_cpu_usage {
    if ($SYSMON_DEBUG >= 5) { print "\n\nChecking CPU Usage ..."; }     # Entering CPU USage Check

    # Get User and System CPU Usage
    if ( $OSNAME eq "darwin" ) {                                        # Under MacOS use 'iostat'
        open (DB_FILE, "$CMD_IOSTAT 1 2 | $CMD_TAIL -1 |");             # Pipe last Line of iostat
    }else{                                                              # Under Linux or Aix 
        open (DB_FILE, "$CMD_VMSTAT 1 2 | $CMD_TAIL -1 |");             # Linux/Aix vmstat last line
    }
    $cpu_use = <DB_FILE> ;                                              # Open Stdout last Line
    printf "\nCPU Usage line:  %s" , $cpu_use;                          # Show User that last Line
    @ligne = split ' ',$cpu_use;                                        # Split Line based on space
    if ( $OSNAME eq "linux" ) {                                         # Under Linux
        $cpu_user   = int $ligne[12];                                   # Linux Get User CPU Usage 
        $cpu_system = int $ligne[13];                                   # Linux Get System CPU Usage
    }
    if ( $OSNAME eq "aix" ) {                                           # Under Aix
        $cpu_user   = int $ligne[13];                                   # Aix Get User CPU Usage 
        $cpu_system = int $ligne[14];                                   # Aix Get User CPU Usage
    }
    if ( $OSNAME eq "darwin" ) {                                        # Under MacOS
        $cpu_user   = int $ligne[3];                                    # MocOS Get User CPU Usage
        $cpu_system = int $ligne[4];                                    # MocOS Get System CPU Usage
    }     
    $cpu_total  = $cpu_user + $cpu_system;                              # Add User+System CPU Usage
    close DB_FILE;

    # Put current value in sadm array and check for error.
    $SADM_RECORD->{SADM_CURVAL} = sprintf "%d" ,$cpu_total ;
    
    # If CPU Usage is less than warning value then Reset Date/Time of last exceeded value to 0 
    if ( $SADM_RECORD->{SADM_CURVAL} < $SADM_RECORD->{SADM_WARVAL} ) {  # Current Load < Warning Val
        $SADM_RECORD->{SADM_DATE} = $SADM_RECORD->{SADM_TIME} = 0 ;     # Reset Date/Time Last War.
    }

    # If CPU Usage is less then error value then reset to 0 Date & time of last exceeded value to 0
    if ( $SADM_RECORD->{SADM_CURVAL} < $SADM_RECORD->{SADM_ERRVAL} ) {  # Current Load < Warning Err
        $SADM_RECORD->{SADM_DATE} = $SADM_RECORD->{SADM_TIME} = 0 ;     # Reset Date/Time Last Err.
    }

    # Set Parameter of Current Evaluation, ready to be evaluated. 
    $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                               # Current Value
    $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                               # Warning Threshold Value
    $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                               # Error Threshold Value
    $TEST = $SADM_RECORD->{SADM_TEST}   ;                               # Test Operator (=,<=,!=,..)
    $MOD  = "$OSNAME"                   ;                               # Module Category
    $SMOD = "CPU"                       ;                               # Sub-Module Category
    $STAT = $CVAL                       ;                               # Current Value Returned
    if ($SYSMON_DEBUG >= 5) {                                           # Debug Level at least 5
        printf "CPU User: %3d - System: %3d  - Total: %3d" ,$cpu_user,$cpu_system,$cpu_total;
        printf " - Warning Level:%3d - Error Level:%3d",$WVAL,$EVAL;
    }
    check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);          # Go Evaluate Error/Alert 
}



#---------------------------------------------------------------------------------------------------
# Check Swap Space Utilization
#---------------------------------------------------------------------------------------------------
sub check_swap_space  {
    if ($SYSMON_DEBUG >= 5) { print "\n\nChecking Swap Space ..." ;}    # Entering Swap Space Check

    # MacOS 
    # Output Example: sysctl vm.swapusage --> 
    # 'vm.swapusage: total = 1024.00M  used = 188.75M  free = 835.25M  (encrypted)'
    if ( $OSNAME eq "darwin" ) {                                            # Under MacOS
        open (DF_FILE,"sysctl vm.swapusage |");                             # Get Swap File Usage 
        while ($paging = <DF_FILE>) {                                       # Read Output of cmd.
            @pline = split ' ', $paging;                                    # Split Line 
            $paging_size = $pline[3] ;                                      # Save Swap Size
            $paging_size =~ tr/M/ /;                                        # Remove Trailing M
            $paging_use  = $pline[6] ;                                      # Save Swap Usage
            $paging_use  =~ tr/M/ /;                                        # Remove Trailing M
            if ($SYSMON_DEBUG >= 5) {                                       # Debug Level 5 and up
                print "\nSwap Info Line: $paging";                          # Output from sysctl
                print "Swap size: $paging_size - Usage: $paging_use";       # Show swap size/usage 
            }
        }
        close DF_FILE;                                                      # Close stdout
        if ($paging_use == 0) {                                             # If usage is 0 
            $paging_pct = 0 ;                                               # Usage=0, percentage=0
        }else{                                                              # if usage not 0
            $paging_pct = int (($paging_use / $paging_size) * 100) ;        # Calc. Usage Percentage
        }        
    }

    # Linux 
    # Output Example: free | grep -i swap --> 'Swap:  3145724 0 3145724'
    if ( $OSNAME eq "linux" ) {                                             # Under Linux
        open (DF_FILE,"free | grep -i swap |");                             # free command swap info
        while ($paging = <DF_FILE>) {                                       # Read Output of cmd.
            @pline = split ' ', $paging;                                    # Split Line 
            $paging_size = $pline[1] ;                                      # Save Swap Size
            $paging_use  = $pline[2] ;                                      # Save Swap Usage
            if ($SYSMON_DEBUG >= 5) {                                       # Debug Level 5 and up
                print "\nSwap Info Line: $paging";                          # Output from free 
                print "Swap size: $paging_size - Usage: $paging_use";       # Show swap size/usage 
            }
        }
        close DF_FILE;                                                      # Close stdout
        if ($paging_use == 0) {                                             # If usage is 0 
            $paging_pct = 0 ;                                               # Usage=0, percentage=0
        }else{                                                              # if usage not 0
            $paging_pct = int (($paging_use / $paging_size) * 100) ;        # Calc. Usage Percentage
        }
    }

    # AIX
    # AIX Will return a line similar to this "512MB  2%"
    if ( $OSNAME eq "aix" ) {                                           # Under Aix
        open (DF_FILE, "/usr/sbin/lsps -s | tail -1 |");                # Use lsps Command
        $total_size = $total_use = 0;                                   # Clear Total Size/Use
        while ($paging = <DF_FILE>) {                                   # Read Output of cmd.
            @pline = split ' ', $paging;
            if ($DEBUG >= 5) { print "Paging line used is @pline\n"; }
            $paging_size = $pline[0] ;                                  # Get Size Of Paging Space
            $paging_size =~ s/MB//;                                     # Remove Unit Specification
            $paging_use  = $pline[1] ;                                  # Get % usage
            $paging_use  =~ s/%//;                                      # Remove Percentage Sign
        }
        close DF_FILE;
        $paging_pct = $paging_use ; 
    }

    # Set Parameter of Current Evaluation, ready to be evaluated. 
    $SADM_RECORD->{SADM_CURVAL} = sprintf "%d" ,$paging_pct ;
    $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                               # Current Value
    $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                               # Warning Threshold Value
    $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                               # Error Threshold Value
    $TEST = $SADM_RECORD->{SADM_TEST}   ;                               # Test Operator (=,<=,!=,..)
    $MOD  = "$OSNAME"                   ;                               # Module Category
    $SMOD = "PAGING"                    ;                               # Sub-Module Category
    $STAT = $CVAL                       ;                               # Current Value Returned
    if ($SYSMON_DEBUG >= 5) {print " - Percentage use: $paging_pct %";} # Debug Level at least 5
    check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);          # Go Evaluate Error/Alert 
}



#---------------------------------------------------------------------------------------------------
# Verify filesystem line in $SADM_RECORD->{SADM_ID} against value in @df_array
#---------------------------------------------------------------------------------------------------
sub check_filesystems_usage  {
    #$SADM_RECORD->{SADM_SCRIPT} = "sadm-fs-inc.sh";                    # Make sure FS auto increase 
   
    #----- Try to locate the filesystem in SYSMON Array 
    foreach $key (keys %df_array) {                                     # Process each FS in Array
        if ($key eq $SADM_RECORD->{SADM_ID}) {                          # If Cur FS = FS in Array
            @dummy = split /_/, $key ;                                  # Split FS Key & FS Name
            $fname = substr ($key,2,length($key)-1);                    # Get FS Name from Key
            $fpct  = $df_array{$key};                                   # Get % Used in DF Array
    
    # Set Parameter of Current Evaluation, ready to be evaluated. 
            $SADM_RECORD->{SADM_CURVAL} = sprintf "%d",$fpct;           # Save % Use in sysmon_array
            $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                       # Current Value
            $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                       # Warning Threshold Value
            $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                       # Error Threshold Value
            $TEST = $SADM_RECORD->{SADM_TEST}   ;                       # Test Operator (=,<=,!=,..)
            $MOD  = "$OSNAME"                   ;                       # Module Category
            $SMOD = "FILESYSTEM"                ;                       # Sub-Module Category
            $STAT = $fname                      ;                       # Current Value Returned
            #print "\n\nFilesystem $fname at ${CVAL}% ... ";             # Print current usage
            $FSTAT = "[OK]";                                            # Default Status
            if ($CVAL >= $WVAL) { $FSTAT = "[WARNING]" ;}
            if ($CVAL >= $EVAL) { $FSTAT = "[ERROR]"   ;}
            print "\n\n$FSTAT Filesystem $fname at ${CVAL}% ... Warning: $WVAL - Error: $EVAL";
            check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);  # Go Evaluate Error/Alert 
            last; 
        }
    }
}



#---------------------------------------------------------------------------------------------------
# Ping the specified server 
#---------------------------------------------------------------------------------------------------
sub ping_ip  {
    @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;                       # Extract Name or IP from ID
    $ipname = $dummy[1];                                                # Extract Name/IP to ping
    print "\n\nTest ping to $ipname ... ";                              # Show to User Name/IP

    $PCMD = "ping -c2 $ipname >/dev/null 2>&1" ;                        # Build ping command
    @args = ("$PCMD"); system(@args) ;                                  # Perform the ping operation
    $src = $? >> 8;                                                     # Get Ping Result
    $SADM_RECORD->{SADM_CURVAL}=$src;                                   # Save Result Code to CurVal

    # Set Parameter of Current Evaluation, ready to be evaluated. 
    $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                               # Current Value
    $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                               # Warning Threshold Value
    $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                               # Error Threshold Value
    $TEST = $SADM_RECORD->{SADM_TEST}   ;                               # Test Operator (=,<=,!=,..)
    $MOD  = "NETWORK"                   ;                               # Module Category
    $SMOD = "PING"                      ;                               # Sub-Module Category
    $STAT = $ipname                     ;                               # Current Value Returned
    if ($CVAL == 0) {print " OK ($CVAL)" }else{ print " ERROR ($CVAL)"} # Print ping Result
    check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);          # Go Evaluate Error/Alert 
    return 
}



#---------------------------------------------------------------------------------------------------
# Function called when script execution is required
# Example of smn line entry for execiting a script inside SysMon
# script:sysmon_script_template.sh 1 != 00 01 000 0000 0000 Y Y Y Y Y Y Y Y 20020911 1520 sadm sadm
#---------------------------------------------------------------------------------------------------
sub run_script {
    ($dummy,$sname) = split /:/, $SADM_RECORD->{SADM_ID} ;              # Extract Full script name
    (my $sfile_name, my $dirName, my $sfile_extension) = fileparse($sname, ('\.sh') );
    #(my $sfile_name, my $sfile_extension) = split /./, $sname ;        # Split name & extension
    $sname = "${SADM_SCR_DIR}/${sname}";                                # Full Path to Script
    print "\n\nExecution of script $sname is requested";                # Show User Script Name
    if ($SYSMON_DEBUG >= 5) {                                           # Debug Level 6 Information
        print "\nFilename: $sfile_name - Extension: $sfile_extension";  # Show Splitted Name/Ext.
    }

    # If no script specified - Return to caller
    if ((length $sname == 0 ) || ($sname eq "-")) {                     # If No script specified
        $SADM_RECORD->{SADM_CURVAL}=1       ;                           # Set Return value to 1=Err
        $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                           # Current Value
        $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                           # Warning Threshold Value
        $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                           # Error Threshold Value
        $TEST = $SADM_RECORD->{SADM_TEST}   ;                           # Test Operator (=,<=,!=,..)
        $MOD  = "$OSNAME"                   ;                           # Module Category
        $SMOD = "SCRIPT"                    ;                           # Sub-Module Category
        $STAT = $sfile_name                 ;                           # Current Value Returned
        print "Script $sname is not valid ..." ;                        # Show Usr not script specify
        check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);      # Go Evaluate Error/Alert 
        return;                                                         # return to caller
    }      

    # Make sure script Exist and is executable - If not return to caller
    if (( -e "$sname" ) && ( ! -x "$sname")) {                          # Script !exist or !executable
        $SADM_RECORD->{SADM_CURVAL}=1       ;                           # Set Return value to 1=Err
        $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                           # Current Value
        $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                           # Warning Threshold Value
        $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                           # Error Threshold Value
        $TEST = $SADM_RECORD->{SADM_TEST}   ;                           # Test Operator (=,<=,!=,..)
        $MOD  = "SCRIPT"                    ;                           # Module Category
        $SMOD = "$sfile_name"               ;                           # Sub-Module Category
        $STAT = "$sfile_name"               ;                           # Current Value Returned
        print "\nScript $sname exist, but not executable";              # Inform user of error
        check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);      # Go Evaluate Error/Alert 
        return;                                                         # return to caller
    }

    # Execute the script   
    printf "\nRunning script $sname ... ";                              # Print Script Name
    @args = ("$sname > ${SADM_SCR_DIR}/${sfile_name}.log 2>&1");        # Command to execute
    system(@args) ;                                                     # Execute the Script
    $src = $? >> 8;                                                     # Return code from script
    printf "\nReturn code is $src";                                     # Print Return Code
    $SADM_RECORD->{SADM_CURVAL}=$src;                                   # Actual Value=Return Code

    $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                               # Current Value
    $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                               # Warning Threshold Value
    $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                               # Error Threshold Value
    $TEST = $SADM_RECORD->{SADM_TEST}   ;                               # Test Operator (=,<=,!=,..)
    $MOD  = "$OSNAME"                   ;                               # Module Category
    $SMOD = "SCRIPT"                    ;                               # Sub-Module Category
    $STAT = $sfile_name                 ;                               # Current Value Returned
    check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);          # Go Evaluate Error/Alert 
    return;                                                             # return to caller
}



#---------------------------------------------------------------------------------------------------
# Check if there is any new filesystem were created since last run (Not in @sysmon_array)
#---------------------------------------------------------------------------------------------------
sub check_for_new_filesystems  {
    if ($SYSMON_DEBUG >= 5) { print "\nChecking for new filesystems ..." };

    # First Get Actual Filesystem Info - Don't check cdrom (/dev/cd0) and NFS Filesystem (:) 
    open (DF_FILE, "/bin/df -hP | grep \"^\/\" | grep -v \"\/mnt\/\"| grep -v \"cdrom\"| grep -v \":\" |");

    # Then Compare Actual value versus Warning & Error Value.
    $newcount = 0 ;                                                     # New filesystem counter
    while ($filesys = <DF_FILE>) {                                      # While still 'df' result 
        @sysline = split ' ', $filesys;                                 # Split 'df' result in array
        $fname = $sysline[5];                                           # Extract FS Name
        if ( $OSNAME eq "darwin" ) {                                    # Under MacOS        
            next if ( $sysline[0] =~ /^map /  ) ;                       # Skip MacOS map FS Line
            next if ( $sysline[0] =~ /^\/\//  ) ;                       # Skip MacOS Mount Volumes
            next if ( $sysline[0] =~ /ˆdevfs/ ) ;                       # Devices filessystem
        }

        # Try to locate the filesystem name in @sysmon_array 
        $found="N";                                                     # Assume FS Name not found
        for ($index = 0; $index < @sysmon_array; $index++) {            # Process each ine in array
            next if ( $sysmon_array[$index] !~ /^FS/ ) ;                # Skip Line if not FS Line
            split_fields($sysmon_array[$index]);                        # Split FS Line
            if ( ($SADM_RECORD->{SADM_ID} eq "FS" . "$fname") ) {       # if found FS Name in array
                $found="Y";                                             # Set founf flag to [Y]es
                last;                                                   # End of Loop
            }
        }

        # If filesystem was not found in sysmon_array, Insert new filesystem in @sysmon.array
        if ($found eq "N" ) {
            $newcount = $newcount + 1 ;                     # Increment new filesystem counter
            $SADM_RECORD->{SADM_ID}      = "FS" . "$fname"; # FileSystem Name ID
            $SADM_RECORD->{SADM_CURVAL}  = "00" ;           # Set FS Current Usage to 0
            $SADM_RECORD->{SADM_TEST}    = ">=";            # FS Test Greater or Equal
            $SADM_RECORD->{SADM_WARVAL}  = "85" ;           # Warning if usage >= 85%
            $SADM_RECORD->{SADM_ERRVAL}  = "90";            # Error if usage >=90
            $SADM_RECORD->{SADM_MINUTES} = "000";           # Consecutive Min Error before trigger alert
            $SADM_RECORD->{SADM_STHRS}   = "0000" ;         # Hours will start to evaluate (0=not evaluate) 
            $SADM_RECORD->{SADM_ENDHRS}  = "0000";          # Hours will stop to evaluate (0=not evaluate)-
            $SADM_RECORD->{SADM_SUN}     = "Y";             # Check on Sunday Yes
            $SADM_RECORD->{SADM_MON}     = "Y";             # Check on Monday Yes
            $SADM_RECORD->{SADM_TUE}     = "Y";             # Check on Tuesday Yes
            $SADM_RECORD->{SADM_WED}     = "Y";             # Check on Wednesday Yes
            $SADM_RECORD->{SADM_THU}     = "Y" ;            # Check on Thrusday Yes
            $SADM_RECORD->{SADM_FRI}     = "Y";             # Check on Friday Yes
            $SADM_RECORD->{SADM_SAT}     = "Y" ;            # Check on Saturday Yes
            $SADM_RECORD->{SADM_ACTIVE}  = "Y";             # Line Active/Tested,If N will skip line
            $SADM_RECORD->{SADM_DATE}    = "00000000";      # Last Date that the error Occured
            $SADM_RECORD->{SADM_TIME}    = "0000";          # Last Time that the error Occured
            $SADM_RECORD->{SADM_SLACK_CHANNEL} = "sadmin";  # Slack Channel Name
            $SADM_RECORD->{SADM_MAIL_GROUP} = "mailgrp";    # Mail Group (sadmin=std address), ...)
            #$SADM_RECORD->{SADM_SCRIPT} = "sadm_fs_incr.sh"; # Script that execute to increase FS
            $SADM_RECORD->{SADM_SCRIPT}  = "-";             # No Script to auto increase fiesystem
            if ($SYSMON_DEBUG >= 5) { print "\n  - New filesystem Found - $fname";}
            $index=@sysmon_array;                           # Get Nb of Item in Array
            $sysmon_array[$index] = combine_fields() ;      # Combine field and insert in array
        }
    }
    if ( $newcount > 0 ){
        printf "\n%d new filesystem(s) monitored",$newcount;    # Show Nb Filesystems added to user
    }else{
        print "\nNo new filesystem detected";               # Show That no new filesystem were found
    }
    close DF_FILE;                                          # Close df output file
}



#---------------------------------------------------------------------------------------------------
#               ISSUE A DF COMMAND AND LOAD THE RESULT IN AN ARRAY CALLED @DF_ARRAY.
#---------------------------------------------------------------------------------------------------
sub load_df_in_array {

    if ($SYSMON_DEBUG >= 6) { print "\Collecting result of \"df\" in memory.\n" };

    # Execute the 'df -hP' command (Remove heading, cdrom and NFS mount) and pipe the output
    open (DF_FILE, "/bin/df -hP | grep \"^\/\" | grep -v \"cdrom\"| grep -v \":\" |");
    while ($filesys = <DF_FILE>) {                                      # Read 'df' result file
        @sysline = split ' ', $filesys;                                 # Split result base on space
        $fname = "FS" . "$sysline[5]";                                  # Build Ref Name in Array
        $fpct =  substr ($sysline[4],0,length($sysline[4])-1);          # Get Filesystem % Used
        if ($SYSMON_DEBUG >= 6) {                                       # If Debug Level >= 6
            print "Filesystem $fname is currently at $fpct\n" ;         # Print FS Info Collected
        }
        $df_array{"$fname"} = $fpct;                                    # Put Name & Value in array
    }
    close DF_FILE;                                                      # Close 'df' result file

    # For Debugging - Show the Filesystem Array after loading the array
    if ($SYSMON_DEBUG >= 6) {                                           # If Debug Level >= 6
        foreach $key (keys %df_array) {                                 # Process Each FS Line
        print "load_df_in_array : Key=$key Value=$df_array{$key}\n";    # Show FS Name and Used %
        }
    }
}



#---------------------------------------------------------------------------------------------------
# CHECK MULTIPATH STATE 
#---------------------------------------------------------------------------------------------------
# echo 'show paths' | multipathd -k | grep -vi multipath
#   0:0:0:0 sda 8:0   1   [active][ready] XX........ 4/20
#   0:0:0:1 sdb 8:16  1   [active][ready] XX........ 4/20
#   1:0:0:0 sdc 8:32  1   [active][ready] XXXX...... 8/20
#   1:0:0:1 sdd 8:48  1   [active][ready] XXXX...... 8/20
#---------------------------------------------------------------------------------------------------
sub check_multipath {
    if ( $OSNAME eq "aix" )  {return ;}                                 # Multipath Oonly on Linux
    if ( $SYSMON_DEBUG >= 5) {print "\n\nChecking Multipath ...";}      # Show User what were doing
    if ( $CMD_MPATHD eq "" ) {                                          # If multipathd is not host
        print "Status of Multipath skipped - Command multipathd not present on system";
    }

    # Get output of multipathd and analyse it 
    open(FPATH, "echo 'show paths' | $CMD_MPATHD -k 2>/dev/null| grep -vEi 'cciss|multipath' | ") 
        or die "Can't execute $CMD_MPATHD \n";

    $SADM_RECORD->{SADM_CURVAL} = 1 ;                                   # Default Status is OK=1
    $INUSE = 0 ;                                                        # Multipath Not in Use=0
    while ($line = <FPATH>) {                                           # Read multipathd output
        @ligne = split ' ',$line;                                       # Split Line into Array
        ($mhcli,$mdev,$mmajor,$mdum1,$mstatus,$mdum2,$mdum3) = @ligne;  # Split Array in fields
        print "\nMultipath Status = $mstatus";                          # Show User current Status
        if ($mstatus ne "[active][ready]") {                            # Current Status != Active
            $SADM_RECORD->{SADM_CURVAL} = 0;                            # Current Status to Error=0
            print "Multipath Error Detected" ;                          # Signal that Error Detected
        }
        $INUSE = 1;                                                     # Multipath is in use Flag
    }
    close FPATH ;                                                       # Close multipathd output
    if ($INUSE == 0){ $mstatus = "not in use"; }                        # Set Status to 'not is use'

    # Set Parameter of Current Evaluation, ready to be evaluated. 
    $CVAL = $SADM_RECORD->{SADM_CURVAL} ;                               # Current Value
    $WVAL = $SADM_RECORD->{SADM_WARVAL} ;                               # Warning Threshold Value
    $EVAL = $SADM_RECORD->{SADM_ERRVAL} ;                               # Error Threshold Value
    $TEST = $SADM_RECORD->{SADM_TEST}   ;                               # Test Operator (=,<=,!=,..)
    $MOD  = "linux"                     ;                               # Module Category
    $SMOD = "MUTIPATH"                  ;                               # Sub-Module Category
    $STAT = $mstatus                    ;                               # Current Status Returned
    if ($SYSMON_DEBUG >= 5) {                                           # Debug Level at least 5
        printf "\nMultipath status is %s - Code = (%d) (1=ok 0=Error)",$STAT,$CVAL; # Show User 
    }
    check_for_error($CVAL,$WVAL,$EVAL,$TEST,$MOD,$SMOD,$STAT);          # Go Evaluate Error/Alert 
}



#---------------------------------------------------------------------------------------------------
# Function is called every time an error or a warning is detected.
# The error/warning line is then written to the SysMon Report File ($SADMIN/dat/rpt/`hostname`.rpt).
#
# Example of line that could be received by this function
#   write_rpt_file($alert_type ,"SERVICE", "DAEMON", $ERR_MESS );
#
# Example of Layout for SysMon Report file (`hostname`.rpt)
#   Error;holmes;2018.05.11;12:00;SERVICE;DAEMON;Service syslogd not running !;sadm;sadm
#   Error;holmes;2018.05.11;12:09;HTTP;WEBSITE;Web Site sysinfo.maison.ca isn't responding;sadm;sadm
#   Warning;holmes;2018.05.11;12:09;linux;FILESYSTEM;Filesystem /usr at 81% > 80%;sadm;sadm
#---------------------------------------------------------------------------------------------------
sub write_rpt_file {
    my ($ERR_LEVEL,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESSAGE) = @_;         # Split Array Parameter Rcv.
    if ($SYSMON_DEBUG >= 6) {                                           # If Debug Level 6 and Up
        print "\nError Level      = $ERR_LEVEL";                        # Print Alert Type
        print "\nError Soft       = $ERR_SOFT";                         # Print Module
        print "\nError SUBSYSTEM  = $ERR_SUBSYSTEM";                    # Print Sub Module
        print "\nError MEssage    = $ERR_MESSAGE";                      # Print Error Message
    }
    $ERR_DATE = `date +%Y.%m.%d`; chop $ERR_DATE;                       # Setup Date of Error
    $ERR_TIME = `date +%H:%M`   ; chop $ERR_TIME;                       # Setup Time of Error
    if ($ERR_LEVEL eq "W") { $ERROR_TYPE = "Warning" ; }                # Setup Warning Type
    if ($ERR_LEVEL eq "E") { $ERROR_TYPE = "Error"   ; }                # Setup Error Type
   
    # Create Line that we may write to the SysMon Report file (`hostname`.rpt)
    $SADM_LINE = sprintf "%s;%s;%s;%s;%s;%s;%s;%s;%s\n",
                 $ERROR_TYPE,$HOSTNAME,$ERR_DATE,$ERR_TIME,$ERR_SOFT,
                 $ERR_SUBSYSTEM,$ERR_MESSAGE,
                 $SADM_RECORD->{SADM_SLACK_CHANNEL},$SADM_RECORD->{SADM_MAIL_GROUP};

    # If it's a Warning, write SysMon Report FIle Line & return to caller (Nothing more to do)
    if ($ERR_LEVEL eq "W") { print SADMRPT $SADM_LINE; return; }

    # If it's a filesystem size error, it will be taken care - no script to execute
    if ($ERR_SUBSYSTEM eq "FILESYSTEM")  { print SADMRPT $SADM_LINE; return; }

    # At This point we have an error and we may want to run a script that could correct the situation
    my $script_name="$SADM_RECORD->{SADM_SCRIPT}";                      # Get Basename script to run
    if ((length $script_name == 0 ) || ($script_name eq "-")) {         # If no script name given
        printf SADMRPT $SADM_LINE;                                      # Write Error to SysMon rpt
        return;                                                         # Return to caller
    }

    # We now have a script name that we want to run to resolve problem - does script exist on disk?
    $script_name="${SADM_SCR_DIR}/$script_name";                        # Full path to script name
    if (! -e $script_name) {                                            # If script doesn't exist
        print "\nThe requested script doesn't exist ($script_name)";    # Advise user
        printf SADMRPT $SADM_LINE;                                      # Write SysMon Report Line
        return;                                                         # Return to caller
    }

    # Make sure script is executable - if not return to caller
    if (( -e "$script_name" ) && ( ! -x "$script_name")) {              # Script not exist,not exec.
        print "\nScript $script_name exist, but is not executable";     # Inform user of error
        printf SADMRPT $SADM_LINE;
        return;
    }

    # Get current date & time in epoch time
    ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();       # Get current epoch time
    if ($SYSMON_DEBUG >= 5) {                                           # If Debug is ON
        print "\nScript name is : $script_name ";                       # Print Script name
        print "\nCurrent Time   : $year $month $day $hour $min $sec";   # Print current time
        print "\nCurrent Epoch  : $epoch";                              # Print Epoch time
    }

    # Is this the first time the script is run - Update Last Execution Data/Time in Array Line
    if ( $SADM_RECORD->{SADM_DATE} == 0 ) {                             # If current date=0 in Array
         $SADM_RECORD->{SADM_DATE} = sprintf("%04d%02d%02d",$year,$month,$day);  # Update SADM_DATE
         $SADM_RECORD->{SADM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);        # Update SADM_Time
    }
    
    # Break last execution date and time from hostname.smon array - ready for epoch calculation 
    $wyear  = sprintf "%04d",substr($SADM_RECORD->{SADM_DATE},0,4);     # Extract Year from SADM_DATE
    $wmonth = sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},4,2);     # Extract Mth from SADM_DATE
    $wday   = sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},6,2);     # Extract Day from SADM_DATE
    $whrs   = sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},0,2);     # Extract Hrs from SADM_TIME
    $wmin   = sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},2,2);     # Extract Min from SADM_TIME
           
    # Get epoch time of the last time script execution
    $last_epoch = get_epoch("$wyear","$wmonth","$wday","$whrs","$wmin","0"); # Epoch of last Exec.
    if ($SYSMON_DEBUG >= 5) {                                           # If DEBUG if ON
        print "\nLast execution of $script_name: $wyear $wmonth $wday $whrs $wmin 00 - $last_epoch"; 
    }

    # Calculate the number of seconds since the last execution in seconds
    $elapse_second = $epoch - $last_epoch;                              # Elapsed time in sec.
    if ($SYSMON_DEBUG >= 5) {                                           # If DEBUG Activated
        print "\nSo $epoch - $last_epoch = $elapse_second seconds";     # Print Elapsed seconds
    }

    # Get of service Name
    @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;                       # Split smon ID
    $daemon_name = $dummy[1];                                           # Get Daemon Name

    # If Elapse seconds since last run time is greater than (86400Sec=1Day) what we decided
    if ( $elapse_second >= $SCRIPT_MIN_SEC_BETWEEN_EXEC ) {             # Elapsed Sec>= 86400 =  ok
        ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();   # Get current date and time
        $SADM_RECORD->{SADM_DATE} = sprintf("%04d%02d%02d", $year,$month,$day); # Upd Last Exec DATE
        $SADM_RECORD->{SADM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);        # Upd Last Exec Time
        $SADM_RECORD->{SADM_MINUTES} = "001";                           # Reset Exec Counter to 1
        print "\nScript selected for execution $SADM_RECORD->{SADM_SCRIPT}";
        #
        # Mail Message to SysAdmin
        ($myear,$mmonth,$mday,$mhour,$mmin,$msec,$mepoch) = Today_and_Now(); # Get Date,Time, Epoch
        my $mail_mess0 = sprintf("Today %04d/%02d/%02d at %02d:%02d, ",$myear,$mmonth,$mday,$mhour,$mmin);
        my $mail_mess1 = "Daemon $daemon_name wasn't running on ${HOSTNAME}.\n";
        my $mail_mess2 = "SysMon executed the service restart script : $SADM_RECORD->{SADM_SCRIPT} $daemon_name \n";
        my $mail_mess3 = "This is the first time SysMon is restarting it.";
        my $mail_message = "${mail_mess0}${mail_mess1}${mail_mess2}${mail_mess3}";
        my $mail_subject = "SADM: INFO $HOSTNAME daemon $daemon_name restarted";
        @args = ("echo \"$mail_message\" | $CMD_MAIL -s \"$mail_subject\" $SADM_MAIL_ADDR");
        system(@args) ;                                                 # Execute 
        if ( $? == -1 ) {                                               # If Mail Command Fails
            print "\nCommand failed: $!";                               # Show Error to users
        }else{                                                          # If Mail Succeeded
            printf "\nCommand succeeded - Return Code: %d", $? >> 8;    # Show Mail Return Code 
        }
        $COMMAND = "$script_name $daemon_name >>${script_name}.log 2>&1";            # Build Script Exec. Command
        print "\nCommand sent ${COMMAND}";                              # Show User command executed
        @args = ("$COMMAND");                                           # Prepare to Execute
        system(@args) ;                                                 # Execute Restart Script
        if ( $? == -1 ) {                                               # Error Executing the script
            print "\nCommand failed: $!";                               # Show User Error Message 
        }else{                                                          # If Script Execution worked
            printf "\nCommand Succeeded - Return Code :%d", $? >> 8;    # Command Succeeded SHow RC 
        }
    }else{
        if (($SADM_RECORD->{SADM_MINUTES} + 1) > $SCRIPT_MAX_RUN_PER_DAY){ # Ran more than twice today
            print "\nScript $SADM_RECORD->{SADM_SCRIPT} as ran ";       # This script already ran 
            print "$SADM_RECORD->{SADM_MINUTES} times in last 24 Hrs."; # twice in the last 24hrs.
            print "\nWill therefore not be executed.";                  # Inform user will not run
            $ERR_MESS = "Failed to restart daemon $daemon_name " ;      # Set up Error Message
            $alert_type="E";                                            # Now definitly an error now
            print SADMRPT $SADM_LINE;
        }else{
            $WORK = $SADM_RECORD->{SADM_MINUTES} + 1;                   # Incr. Exec. script Counter
            $SADM_RECORD->{SADM_MINUTES} = sprintf("%03d",$WORK);       # Insert Counter in Array
            print "\nScript $SADM_RECORD->{SADM_SCRIPT} ran ";          # This script already ran
            print "$SADM_RECORD->{SADM_MINUTES} time(s) in last 24hrs.";# X times in the last 24hrs.
            $COMMAND = "$script_name $daemon_name >>${script_name}.log 2>&1";        # Build Script Exec. Command
            print "\nCommand sent ${COMMAND}";                          # Show User command executed
            @args = ("$COMMAND");                                       # Prepare to Execute
            system(@args) ;                                             # Execute Restart Script
            if ( $? == -1 ) {                                           # Error Executing the script
                print "\nCommand failed: $!";                           # Show User Error Message 
            }else{                                                      # If Script Execution worked
                printf "\nCommand Succeeded - Return Code :%d",$? >> 8; # Command Succeeded SHow RC 
            }
        }
    } 
}




#---------------------------------------------------------------------------------------------------
# This function try to create the sysmon.lock file
#   - If lock file exist, get timestamp of file and if were created more than 15 minutes ago,
#     then it is deleted and a new one is created.
#   - The sysmon lock file is used to make sure that only one instance of sysmon is running.
#
# This function also issue a 'export COLUMNS=4096 ; ps -efwww' and store the output in $PSFILE1
#   - It issue the same command again and store it $PSFILE2.
#   - It happen sometime that some process weren't recorded in the first and present in the second.
# --------------------------------------------------------------------------------------------------
# IF YOU REALLY WANT TO PREVENT SYSMON FROM RUNNING FOR A LONG PERIOD OF TIME (During server update)
# YOU CAN CREATED AN EMPTY FILE CALLED '/tmp/sadmlock.txt'. 
# SYSMON WILL CONTINUE TO RUN, BUT IT WILL EXIT IMMEDIATELY. WITH AN ERROR CODE 1.
# DON'T FORGET TO REMOVE THAT FILE AFTER YOUR UPDATE, CAUSE SYSMON WON'T REPORT ANYTHING UNTIL 
# THAT FILE EXIST.
#---------------------------------------------------------------------------------------------------
sub init_process {
  
    # If you really want to prevent sysmon from running create this file /tmp/sadmlock.txt
    if ( -e "/tmp/sadmlock.txt") {                                      # If /tmp/sadmlock.txt exist
        print "/tmp/sadmlock.txt exist - SYSMON not executed";          # Advise User - Show Message
        exit 1;                                                         # Exit with Error
    } 

    # GET THE ALL THE VALUES FOR CURRENT TIME
    #($SECOND, $MINUTE, $HOUR, $DAY, $MONTH, $YEAR, $WEEKDAY, $DAYOFYEAR, $ISDST) = LOCALTIME(TIME);
    # IF LOCK FILE EXIST, CHECK IF IT IS THERE FOR MORE THAN 15 MINUTES, IF SO DELETE IT
    if ( -e "$SYSMON_LOCK_FILE"  ) {                                    # If sysmon.lock exist

        # Get sysmon.lock file information - Creation time of the lock file in epoch time
        ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat ($SYSMON_LOCK_FILE);
        if ($SYSMON_DEBUG >= 6) {                                       # If DEBUG Activated       
            print "\nLockfile creation time in epoch time is : $ctime"; # Show Creation Epoch time 
        }
        $creation_date = localtime($ctime);                             # Convert Epoch to HumanDate
        print "\nLockfile was created on $creation_date";               # Show Lock Creation Date

        my $actual_epoch_time = time();                                 # Get Current Epoch Time
        $actual_date = localtime($actual_epoch_time);                   # COnvert Epoch to HumanDate
        if ($SYSMON_DEBUG >= 6) {                                       # If DEBUG Activated       
            print "\nActual time in epoch time is $actual_epoch_time";  # Show Current Epoch Time
            print "\nActual time is $actual_date";                      # Show Current Human Date
        }
        my $elapse_time = ($actual_epoch_time - $ctime) ;               # Calc. Sec. Since Creation
        print "\nLock file $SYSMON_LOCK_FILE was create $elapse_time seconds ago";

        # If lock file exist for more than (Default 30 Minutes) 1800 seconds, creation time is reset
        if ( $elapse_time >= $LOCKFILE_MAX_SEC ) {                      # Lockfile created > 30Min.
            if ($SYSMON_DEBUG >= 5) {                                   # In Debug Mode Level >=5
                print "\nUpdating TimeStamp of Lock File $SYSMON_LOCK_FILE" ; } # Show User Message
            #unlink "$SYSMON_LOCK_FILE" ;
            #print "\nCreating lock file $SYSMON_LOCK_FILE\n";
            @args = ("$CMD_TOUCH", "$SYSMON_LOCK_FILE");                # Touch Lockfile Reset date
            system(@args) == 0   or die "system @args failed: $?";      # Execute touch on lockfile
        }else{                                                          # Waiting LockFile to Expire
            my $wait_time = ($LOCKFILE_MAX_SEC - $elapse_time) ;        # Calc. Sec. Remaining 
            printf("\nLock file TTL - %04d seconds.",$LOCKFILE_MAX_SEC);# Show Current Time to Live
            printf"\n%4d seconds remaining before reset.\n", $wait_time;# Seconds before rm lockfile
            exit 1;                                                     # Exit with error
        }    
    }else{
        print "\nCreating lock file $SYSMON_LOCK_FILE\n";               # Show user want we do
        @args = ("$CMD_TOUCH", "$SYSMON_LOCK_FILE");                    # Cmd to Create Lock File
        system(@args) == 0   or die "system @args failed: $?";          # Execute the Touch Command
    }

    # Execute the 'ps' command twice and save result to files
    @args = ("export COLUMNS=4096 ; ps -efwww  > $PSFILE1 ; export COLUMNS=80");
    system(@args) == 0   or print "ps 1 command Failed ! : $?";         # Execute 'ps' Command No.1
    sleep(1);                                                           # One Second between Exec.
    @args = ("export COLUMNS=4096 ; ps -efwww > $PSFILE2 ; export COLUMNS=80");
    system(@args) == 0   or print "ps 2 command Failed ! : $?";         # Execute 'ps' Command No.2
    if ($SYSMON_DEBUG >= 8) {                                           # Debug >5 Print PS Result
        print "\n\n-----\nContent of PSFILE1\n" ;                       # Show Result 1 Heading
        @args = ("cat $PSFILE1");                                       # Cat CMD to execute
        system(@args) == 0   or print "Printing PSFILE1 failed ! : $?"; # Execute the 'cat' command
        print "\n\n-----\nContent of PSFILE2\n" ;                       # Show Result 12 Heading
        @args = ("cat $PSFILE2");                                       # Cat CMD to execute
        system(@args) == 0   or print "Printing PSFILE2 failed ! : $?"; # Execute the 'cat' command
    }
   
    # Under Linux, Check if we are running under a VM or not.
    $VM = "N" ;                                                         # By Default not a VM
    if ( $OSNAME eq "linux" ) {                                         # Under Linux Only (Not Aix)
        $COMMAND = "$CMD_DMIDECODE | grep -i vmware >/dev/null 2>&1" ;  # Cmd to Check if a VM
         @args = ("$COMMAND");                                          # Form the O/S Command
        system(@args) ;                                                 # Execute dmidecode command
        if (($? >> 8) == 0 ) { $VM = "Y"; }else{ $VM = "N"; }           # Set VM to Yes or No
    }
}   




#---------------------------------------------------------------------------------------------------
# Loop through everyline in @sysmon_array (loaded from `hostname`.smon) and evaluate each of them
#---------------------------------------------------------------------------------------------------
sub loop_through_array {

    # Lopop through @sysmon_array to process each active lines
    for ($index = 0; $index < @sysmon_array; $index++) {                # Process one line at a time  
        next if $sysmon_array[$index] =~ /^#/ ;                         # Don't process comment line
        next if $sysmon_array[$index] =~ /^$/ ;                         # Don't process blank line
        split_fields($sysmon_array[$index]);                            # Split line into fields
        next if $SADM_RECORD->{SADM_ACTIVE} eq "N";                     # Skip Inactive line

        next if `date +%a` =~ /Sun/ && $SADM_RECORD->{SADM_SUN} =~ /N/; # If Sunday & Sun.  Inactive
        next if `date +%a` =~ /Mon/ && $SADM_RECORD->{SADM_MON} =~ /N/; # If Monday & Mon.  Inactive
        next if `date +%a` =~ /Tue/ && $SADM_RECORD->{SADM_TUE} =~ /N/; # If Tuesday & Tue. Inactive
        next if `date +%a` =~ /Wed/ && $SADM_RECORD->{SADM_WED} =~ /N/; # If Wed. & Wed. inactive
        next if `date +%a` =~ /Thu/ && $SADM_RECORD->{SADM_THU} =~ /N/; # If Thu. & Thu. inactive
        next if `date +%a` =~ /Fri/ && $SADM_RECORD->{SADM_FRI} =~ /N/; # If Fri. & Friday inactive
        next if `date +%a` =~ /Sat/ && $SADM_RECORD->{SADM_SAT} =~ /N/; # If Sat. & Sat. inactivate

        # If Start and End Time Specified, Verify if line is active at current time
        $evaluate_line="yes" ;                                          # Default to evaluate line
        if ($SADM_RECORD->{SADM_STHRS} != 0 and $SADM_RECORD->{SADM_ENDHRS} != 0) {
            $current_time = `date +%H%M` ;                              # Get current Time
            if ($SADM_RECORD->{SADM_ENDHRS} < $SADM_RECORD->{SADM_STHRS}) {
                if (($current_time > $SADM_RECORD->{SADM_STHRS})  || 
                    ($current_time < $SADM_RECORD->{SADM_ENDHRS})) { 
                    $evaluate_line="yes";                               # Yes Line Active
                }else{
                    $SADM_RECORD->{SADM_DATE} = 0;                      # Reset Last Error Date
                    $SADM_RECORD->{SADM_TIME} = 0;                      # Reset Last Error Time
                    $evaluate_line="no";                                # No - Line is Inactive
                    $sysmon_array[$index] = combine_fields();           # Combine field/put in array  
                }   
            }else{
                if (($current_time >= $SADM_RECORD->{SADM_STHRS}) && 
                    ($current_time <= $SADM_RECORD->{SADM_ENDHRS})) { 
                    $evaluate_line="yes"; 
                }else{ 
                    $SADM_RECORD->{SADM_DATE} = 0;                      # Reset Last Error Date
                    $SADM_RECORD->{SADM_TIME} = 0;                      # Reset Last Error Time
                    $evaluate_line="no";                                # No - Line is Inactive
                    $sysmon_array[$index] = combine_fields();           # Combine field/put in array 
                }
            }
        }  
        
        # If not within Time Range, is line active (should we evaluate line), if not next line
        next if $evaluate_line eq "no" ;
                  
        # Check Linux Multipath State
        if ($SADM_RECORD->{SADM_ID} =~ /^check_multipath/  ) {check_multipath ;}
        
        # Load Average
        #if ($SYSMON_DEBUG >= 5) { print "\nBefore Processing line $sysmon_array[$index]"; }
        if ($SADM_RECORD->{SADM_ID} =~ /^load_average/ ) {check_load_average ; }
        #if ($SYSMON_DEBUG >= 5) { print "\nAfter Processing line $sysmon_array[$index]"; }
        
        # Check CPU Usage
        if ($SADM_RECORD->{SADM_ID} =~ /^cpu_level/ ) {check_cpu_usage ;  }

        # Check Swap Space
        if ($SADM_RECORD->{SADM_ID} eq "swap_space") {check_swap_space ; }
        
        # Check filesystem usage
        if ($SADM_RECORD->{SADM_ID} =~ /^FS/ ) {check_filesystems_usage ; }

        # Check Ping an IP
        if ($SADM_RECORD->{SADM_ID} =~ /^ping_/ ) {ping_ip; }

        # Check if specified service is running
        if ($SADM_RECORD->{SADM_ID} =~ /^service_/ ) {check_service; }

        # Check if specified daemon is running
        if ($SADM_RECORD->{SADM_ID} =~ /^daemon_/ ) {check_daemon; }
        
        # Check HTTP
        if ($SADM_RECORD->{SADM_ID} =~ /^http/ ) {check_http;    }
        
        # Check Running Script
        if ($SADM_RECORD->{SADM_ID} =~ /^script/  ) {run_script ;}
        
        # Combine all the fields into a line and put it back into the array
        $sysmon_array[$index] = combine_fields() ;
    }
} 




#---------------------------------------------------------------------------------------------------
# Executed just before exiting sysmon 
#---------------------------------------------------------------------------------------------------
sub end_of_sysmon {

    # Delete PSFILE (contain ps command results, creating at the beginning of script)
    unlink "$PSFILE1" or die "Cannnot delete $PSFILE1: $!\n" ;
    unlink "$PSFILE2" or die "Cannnot delete $PSFILE2: $!\n" ;
    
    # Remove sysmon.lock file
    print "\nDeleting SYStem MONitor lock file $SYSMON_LOCK_FILE";
    unlink "$SYSMON_LOCK_FILE" or die "Cannnot delete $SYSMON_LOCK_FILE: $!\n" ;

    # Print Execution time
    if ($SYSMON_DEBUG >= 5) { 
        $end_time = time;                                                   # Get current time
        $xline1 = sprintf ("#SYSMON $VERSION_NUMBER $HOSTNAME - ");         # Version & Hostname
        $xline2 = sprintf ("%s" , scalar localtime(time));                  # Print Current Time
        $xline3 = sprintf (" - Execution Time %2.2f seconds", ($end_time - $start_time)); 
        printf ("\n${xline1}${xline2}${xline3}\n\n");                       # SADM Stat Line
    }
}
  

#---------------------------------------------------------------------------------------------------
# Main Program Start HERE
#---------------------------------------------------------------------------------------------------

    # Initializing SysMon
    init_process;                                   # Create lock file & do 'ps' commands to files
    $start_time = time;                             # Store Starting time - To calculate elapse time
    load_sadmin_cfg;                                # Load SADMIN Config file sadmin.cfg in Glob.Var
    load_smon_file;                                 # Load SysMon Config file hostname.smon in Array 
    load_df_in_array;                               # Execute "df" command & store result in a array
    open (SADMRPT," >$SYSMON_RPT_FILE")  or die "Can't open $SYSMON_RPT_FILE: $!\n"; 

    # Main Process
    check_for_new_filesystems;                      # Check for new filesystem first
    loop_through_array;                             # Loop through Sadm Array line by line
    
    # Ending SysMon
    close SADMRPT;                                  # Close SysMon report file 
    system ("chmod 664 $SYSMON_RPT_FILE");          # Make SysMon Report file readable by everyone
    unload_smon_file;                               # Unload Update Array to hostname.smon file
    end_of_sysmon;                                  # Delete lock file - Print Elapse time
