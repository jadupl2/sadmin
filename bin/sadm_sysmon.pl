#!/usr/bin/perl
#===================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_sysmon.pl
#   Synopsis :  sadm System Monitor
#   Version  :  1.5
#   Date     :  15 Janvier 2016
#   Requires :  sh
#===================================================================================================
# 2017_12_30 JDuplessis
#   V2.7 Change Config file extension to .smon & Defaut Virtual Machine presence to 'N'
#===================================================================================================
#
use English;
use DateTime; 
use File::Basename;
use POSIX qw(strftime);
use Time::Local;
use LWP::Simple;
system "export TERM=xterm";


#===================================================================================================
#                                   Global Variables definition
#===================================================================================================
my $VERSION_NUMBER      = "2.7";                                        # Version Number
my @sysmon_array        = ();                                           # Array Contain sysmon.cfg 
my %df_array            = ();                                           # Array Contain FS info
my $OSNAME              = `uname -s`; chomp $OSNAME;                    # Get O/S Name
$OSNAME                 =~ tr/A-Z/a-z/;                                 # OSName in lowercase(linux aix)
my $HOSTNAME            = `hostname -s`; chomp $HOSTNAME;               # HostName of current System
my $SYSMON_DEBUG        = "$ENV{'SYSMON_DEBUG'}" || "5";                # debugging purpose set to 5
#
# SADMIN DIRECTORY STRUCTURE DEFINITION
my $SADM_BASE_DIR       = "$ENV{'SADMIN'}" || "/sadmin";                # SADMIN Root Dir.
my $SADM_BIN_DIR        = "$SADM_BASE_DIR/bin";                         # SADMIN bin Directory
my $SADM_TMP_DIR        = "$SADM_BASE_DIR/tmp";                         # SADMIN Temp Directory
my $SADM_LOG_DIR        = "$SADM_BASE_DIR/log";                         # SADMIN LOG Directory
my $SADM_DAT_DIR        = "$SADM_BASE_DIR/dat";                         # SADMIN Data Directory
my $SADM_RPT_DIR        = "$SADM_DAT_DIR/rpt";                          # SADMIN Aleret Report File
my $SADM_CFG_DIR        = "$SADM_BASE_DIR/cfg";                         # SADMIN Configuration Dir.
my $SADM_RCH_DIR        = "$SADM_DAT_DIR/rch";                          # SADMIN Result Code History
my $SADM_SCR_DIR        = "$SADM_BASE_DIR/mon";                         # SADMIN Monitoring Scripts

# SYSMON FILES DEFINITION
my $PSFILE1             = "$SADM_TMP_DIR/PSFILE1.$$";                   # Result of ps command file1
my $PSFILE2             = "$SADM_TMP_DIR/PSFILE2.$$";                   # Result of ps command file2
my $SADM_TMP_FILE1      = "$SADM_TMP_DIR/${HOSTNAME}_sysmon.tmp1";      # SYSMON Temp work file 1
my $SADM_TMP_FILE2      = "$SADM_TMP_DIR/${HOSTNAME}_sysmon.tmp2";      # SYSMON Temp work file 2
my $SYSMON_CFG_FILE     = "$SADM_CFG_DIR/$HOSTNAME.smon";               # SYSMON Configuration file
my $SYSMON_STD_FILE     = "$SADM_CFG_DIR/sysmon.std";                   # SYSMON Config Std file
my $SYSMON_RPT_FILE     = "$SADM_RPT_DIR/$HOSTNAME.rpt";                # SYSMON Host Report File 
my $SYSMON_LOCK_FILE    = "$SADM_BASE_DIR/sysmon.lock";                 # SYSMON Lock file

# PROGRAMS LOCATION AND COMMAND LINE OPTIONS USED ...
my $CMD_CHMOD           = `which chmod`      ;chomp($CMD_CHMOD);        # Location of chmod command
my $CMD_CP              = `which cp`         ;chomp($CMD_CP);           # Location of cp command
my $CMD_FIND            = `which find`       ;chomp($CMD_FIND);         # Location of find command
my $CMD_MAIL            = `which mail`       ;chomp($CMD_MAIL);         # Location of mail command
my $CMD_TAIL            = `which tail`       ;chomp($CMD_TAIL);         # Location of tail command
my $CMD_HEAD            = `which head`       ;chomp($CMD_HEAD);         # Location of head command
my $CMD_UPTIME          = `which uptime`     ;chomp($CMD_UPTIME);       # Location of uptime command
my $CMD_VMSTAT          = `which vmstat`     ;chomp($CMD_VMSTAT);       # Location of vmstat command
my $CMD_MPATHD          = `which multipathd` ;chomp($CMD_MPATHD);       # Location of multipathd cmd
my $CMD_DMIDECODE       = `which dmidecode`  ;chomp($CMD_DMIDECODE);    # To check if we are in a VM
my $CMD_TOUCH           = `which touch`      ;chomp($CMD_TOUCH);        # Location of touch command 
system ("which systemctl >/dev/null 2>&1");
if ( $? == -1 )  { $CMD_SYSTEMCTL = ""; }else{ $CMD_SYSTEMCTL = `which systemctl 2>/dev/null`; }


# SSH COMMANDS AND VARIABLES
my $CMD_SSH             = `which ssh`                ;chomp($CMD_SSH);  # Get location of ssh 
my $CMD_SCP             = `which scp`                ;chomp($CMD_SCP);  # Get location of scp
my $SSH_OPT             = " -rP 32 ";                                   # SSH Command line Options 
my $SADM_USER           = "sadmin";                                     # Use This User on SADMIN
my $SADM_GROUP          = "sadmin";                                     # Group Assigned to sadmin 
my $SADMIN_SERVER       = "sadmin.maison.ca";                           # SADMIN Server Name
my $SSH_CONNECT         = "$CMD_SSH ${SSH_OPT} ${SADM_USER}\@${SADMIN_SERVER}"; # SSH 2 SADMIN Server
my $SCP_CON             = "$CMD_SCP ${SSH_OPT} ${SADM_USER}\@${SADMIN_SERVER}"; # SCP 2 SADMIN Server



# SERVER.CFG FILE LAYOUT , FIELD SEPARATED BY A SPACE
# --------------------------------------------------------------------------------------------------
$SADM_RECORD = {
   SADM_ID => " ",                              # IDENTIFIER 
   SADM_CURVAL => " ",                          # Last Value calculated by slam
   SADM_TEST =>   " ",                          # Evaluation Operator (=,!=,<,>,=>,=<) 
   SADM_WARVAL => " ",                          # Warning Level (0=not evaluated)
   SADM_ERRVAL => " ",                          # Error Level (0=not evaluated)     
   SADM_MINUTES =>" ",                          # Error must occur over X minutes before trigger
   SADM_STHRS =>  " ",                          # Hours to start evaluate (0=not evaluate)
   SADM_ENDHRS => " ",                          # Hours to stop evaluate (0=not evaluate
   SADM_SUN =>    " ",                          # Test to be done on Sunday (Y/N) 
   SADM_MON =>    " ",                          # Test to be done on Monday (Y/N) 
   SADM_TUE =>    " ",                          # Test to be done on Tuesday (Y/N) 
   SADM_WED =>    " ",                          # Test to be done on Wednesday (Y/N) 
   SADM_THU =>    " ",                          # Test to be done on Thrusday (Y/N) 
   SADM_FRI =>    " ",                          # Test to be done on Friday (Y/N) 
   SADM_SAT =>    " ",                          # Test to be done on Saturday (Y/N) 
   SADM_ACTIVE => " ",                          # Line is Active or not
   SADM_DATE =>   " ",                          # Last Date this line was evaluated
   SADM_TIME =>   " ",                          # Last Time this line was evaluated
   SADM_QPAGE =>  " ",                          # Slam Alias to page
   SADM_EMAIL =>  " ",                          # Slam Alias to send email
   SADM_SCRIPT => " ",                          # Script to execute when an Error occurs
};


# AUTOMATIC FILESYSTEM INCREASE PARAMETERS
my $MINIMUM_SEC=86400;                          # 1 Day=86400 Sec. = Minimum between Filesystem Incr.
my $INCREASE_PER_DAY=2;                         # Number of filesystem increase allowed per Day.
my $SCRIPT_MIN_SEC_BETWEEN_EXEC=86400;          # Restart script didn't run for more than value then ok to run


my $SADMIN_EMAIL="duplessis.jacques\@gmail.com";# Unix Admin Email Address
my $ERROR_FOUND = "N";                          # Set Yes if error written on error file
my $start_time = $end_time = 0;                 # Calc. execution Time written to cfg file
my $WINDEX = 0;                                 # Array Index - For temp usage
my $WORK = 0;                                   # For temp usage
my $SCRIPT_MAX_RUN_PER_DAY=2;                   # Number of time the restart script can be run during one day
my $VM = "N" ;                                  # Are we in a VM (No by Default)

# HTTP match 
my $MATCH_HTTP="perl -ne 'print \"\$1_\$2\n\" if m#-f /usr/http/(.*?)/.*?/(.*?)-httpd.conf# || m#-f /usr/http/(.*?)/instances/(.*?)/httpd.conf#'";





#---------------------------------------------------------------------------------------------------
#   LOAD THE CONTENT OF $SADM_BASE_DIR/CFG/`HOSTNAME`.CFG FILE IN AN ARRAY CALLED @sysmon_array.
#---------------------------------------------------------------------------------------------------
sub load_host_config_file {

    # For debug purpose - Display Important Data 
    if ($SYSMON_DEBUG >= 5) {
        print "\nSADMIN - SADM SYStem MONitor Tools - Version ${VERSION_NUMBER}\n";
        print "------------------------------------------------------------------------------\n";
        print "O/S Name                 = ${OSNAME}\n" ;
        print "Debugging Level          = ${SYSMON_DEBUG}\n" ;
        print "SADM_BASE_DIR            = ${SADM_BASE_DIR}\n";      
        print "Hostname                 = ${HOSTNAME}\n" ;
        print "Virtual Server           = ${VM}\n" ;
        print "CMD_SSH                  = ${CMD_SSH}\n";
        print "------------------------------------------------------------------------------\n";
    }


    # CHECK IF HOSTNAME.CFG EXIST, IF NOT COPY SYSMON.STD TO HOSTNAME.CFG
    if ( ! -e "$SYSMON_CFG_FILE"  ) {                                   # If hostname.cfg not exist
        my $mail_message = "File $SYSMON_CFG_FILE not found, File created based on standard.cfg";    
        my $mail_subject = "SADM: WARNING $SYSMON_CFG_FILE not found on $HOSTNAME";
        @cmd = ("echo \"$mail_message\" | $CMD_MAIL -s \"$mail_subject\" $SADMIN_EMAIL");
        $return_code = 0xffff & system @cmd ;                           # Perform Mail Command 
        @cmd = ("$CMD_CP $SYSMON_STD_FILE $SYSMON_CFG_FILE");           # cp sysmon.std 2 hostsname.cfg
        $return_code = 0xffff & system @cmd ;                           # Perform Command cp
        @cmd = ("$CMD_CHMOD 664 $SYSMON_CFG_FILE");                     # Make hostname.cfg 664
        $return_code = 0xffff & system @cmd ;                           # Perform Command chmod
    }

    
    # OPEN SYSMON HOST CONFIGURATION FILE AND LOAD IT IN AN ARRAY CALLED SYSMON_ARRAY
    open (SMONFILE,"<$SYSMON_CFG_FILE") or die "Can't open $SYSMON_CFG_FILE: $!\n";
    $widx = 0;
    while ($line = <SMONFILE>) {                                        # Read while end of file
        next if $line =~ /^#SADMSTAT/ ;                                 # Don't load sysmon statline
        $sysmon_array[$widx++] = $line ;                                # Load Line in Array
        if ($SYSMON_DEBUG >= 6) { print "Line loaded from cfg : $line" ; }
    }
    close SMONFILE;                                                     # Close SysMon Config file


    # IF IN DEBUG MODE DISPLAY NUMBER OF ELEMENT LOADED
    if ($SYSMON_DEBUG >= 5) {                                           # If in debug mode 
        $nbline = @sysmon_array;                                        # Get Nb. of element loaded
        print "File $SYSMON_CFG_FILE loaded in sysmon_array ($nbline lines loaded)\n";
    }
    if ($SYSMON_DEBUG >= 6)  { display_sysmon_array ; }                 # If Debug >=6 Display Array
}




#---------------------------------------------------------------------------------------------------
# THIS FUNCTION IS CALLED AT THE END, TO UNLOAD THE ARRAY BACK TO DISK IN THE `HOSTNAME`.CFG FILE
#---------------------------------------------------------------------------------------------------
sub unload_host_config_file {
   
    # DISPLAY DEBUG INFO
    if ($SYSMON_DEBUG >= 6) {       
        print "\n-----\nUnloading the array \"sysmon_array\" to the file $SYSMON_CFG_FILE\n" ;
    }

    # OPEN (CREATE) AN EMPTY TEMPORARY FILE TO UNLOAD SLAM CONFIG FILE
    open (SADMTMP,">$SADM_TMP_FILE1") or die "Can't create $SADM_TMP_FILE1: $!\n";

    # UNLOAD SYSMON_ARRAY TO DISK
    for ($widx = 0; $widx < @sysmon_array; $widx++) {                   # Loop until end of array
        print (SADMTMP "$sysmon_array[$widx]");                         # Write line to config file
    }

    # GET ENDING TIME & WRITE SLAM STATISTIC LINE AT THE EOF
    $end_time = time;                                                   # Get current time
    printf (SADMTMP "#SADMSTAT $VERSION_NUMBER $HOSTNAME - %s - Execution Time %2.2f seconds\n", scalar localtime(time), $end_time - $start_time); 
    close SADMTMP ;                                                     # Close temporary file

    # DELETE OLD SLAM CONFIG FILE AND RENAME THE TEMP FILE TO SLAM CONFIG FILE
    unlink "$SYSMON_CFG_FILE" ;                                         # Delete Cur. `hostname`.cfg 
    if (!rename "$SADM_TMP_FILE1", "$SYSMON_CFG_FILE")                  # Ren file to `hostname`.cfg 
       { print "Could not rename $SADM_TMP_FILE1 to $SYSMON_CFG_FILE: $!\n" }
    system ("chmod 664 $SYSMON_CFG_FILE");                              # Make file rw for gou
    system ("chown ${SADM_USER}.${SADM_GROUP} ${SYSMON_CFG_FILE}");     # Assign User/Group SADMIN
}



#---------------------------------------------------------------------------------------------------
#           FUNCTION CALLED TO DISPLAY sysmon_array CONTENT (FOR DEBUG PURPOSE)
#---------------------------------------------------------------------------------------------------
sub display_sysmon_array {
    for ($widx = 0; $widx < @sysmon_array; $widx++) { 
        print ("$sysmon_array[$widx]"); 
    }
}






#---------------------------------------------------------------------------------------------------
#           EXTRACT EACH FIELDS FROM THE LINE RECEIVED IN PARAMETER TO WORK FIELDS
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
            $SADM_RECORD->{SADM_QPAGE},
            $SADM_RECORD->{SADM_EMAIL},
            $SADM_RECORD->{SADM_SCRIPT} ) = split ' ',$wline;
}



#---------------------------------------------------------------------------------------------------
#               COMBINE ALL FIELDS BACK TOGETHER INTO A LINE IN SLAM SERVER.CFG FORMAT
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
        $SADM_RECORD->{SADM_DATE},
        $SADM_RECORD->{SADM_TIME},
        $SADM_RECORD->{SADM_QPAGE},
        $SADM_RECORD->{SADM_EMAIL},
        $SADM_RECORD->{SADM_SCRIPT};
    return "$wline";
}



#---------------------------------------------------------------------------------------------------
#                               FILESYSTEM INCREASE FUNCTION
#---------------------------------------------------------------------------------------------------
sub filesystem_increase {
    my ($FILESYSTEM) = @_;                                              # filesystem name to incr.
    print "\nFilesystem $FILESYSTEM selected for increase";             # Entering filesystem funct.

    my $FS_SCRIPT = "${SADM_BIN_DIR}/$SADM_RECORD->{SADM_SCRIPT}";
    $FSCMD = "$FS_SCRIPT $FILESYSTEM >>${SADM_LOG_DIR}/$SADM_RECORD->{SADM_SCRIPT}.log 2>&1" ;
    print "\nThe command that will be executed is $FSCMD";
    @args = ("$FSCMD");
    $src = system(@args) ;
    if ( $src == -1 ) { 
        print "\ncommand failed: $!"; 
    }else{ 
        printf "\ncommand exited with value %d", $? >> 8; 
    }
    return $src ;
}



#---------------------------------------------------------------------------------------------------
#               ROUTINE TO CHECK THE ACTUAL VALUE VERSUS THE WARNING & ERROR VALUE
#---------------------------------------------------------------------------------------------------
sub check_for_error {

    # Fields received as parameters ;
    #  Actual Value, Warning Value, Error Value, Test to make (=,<,>,...) 
    #  Module Name (AIX, PSSP, ADSM, AUTOSYS, ...) Submodule (Filesystem, ...) and
    #  Value used in the error message.
    my ($ACTVAL, $WARVAL, $ERRVAL, $TEST, $MODULE, $SUBMODULE, $WID) = @_;


    if ($SYSMON_DEBUG >= 6) { printf "\nCheck for Error - WID = $WID";}
    $error_detected="N";                                                # No Error by default

    # IF THE TEST TO PERFORM INVOLVE ">=" OPERATOR.
    if ($TEST eq ">=" ) {
        if (($ACTVAL >= $WARVAL) && ($WARVAL != 0)) {                   # Check actual value against the warning level
            $error_detected="W";                                        # Save type of error encountered
            $value_exceeded=$WARVAL;                                    # Save the warning level value
        }
        if (($ACTVAL >= $ERRVAL) && ($ERRVAL != 0)) {                   # Check the actual value against the error level
            $error_detected="E";                                        # Save type of error encountered
            $value_exceeded=$ERRVAL;                                    # Save the error level value
        }
    }

    # IF THE TEST TO PERFORM INVOLVE "<=" OPERATOR.
    if ($TEST eq "<=" ) {
        # Check the actual value against the warning level
        if (($ACTVAL <= $WARVAL) && ($WARVAL != 0)) {
            $error_detected="W";                                        # Save type of error encountered
            $value_exceeded=$WARVAL;                                    # Save the warning level value
        }
        # Check the actual value against the error level
        if (($ACTVAL <= $ERRVAL) && ($ERRVAL != 0)) {
            $error_detected="E";                                        # Save type of error encountered
            $value_exceeded=$ERRVAL;                                    # Save the error level value
        }
    }

    # IF THE TEST TO PERFORM INVOLVE "!=" OPERATOR.
    if ($TEST eq "!=" ) {
        # Check the actual value against the warning level
        if (($ACTVAL != $WARVAL) && ($WARVAL != 0)) {
            $error_detected="W";                                        # Save type of error encountered
            $value_exceeded=$WARVAL;                                    # Save the warning level value
        }
        # Check the actual value against the error level
        if (($ACTVAL != $ERRVAL) && ($ERRVAL != 0)) {
            $error_detected="E";                                        # Save type of error encountered
            $value_exceeded=$ERRVAL;                                    # Save the error level value
        }
    }

    # IF THE TEST TO PERFORM INVOLVE "=" OPERATOR
    if ($TEST eq "=" ) {
        # Check the actual value against the warning level
        if (($ACTVAL == $WARVAL) && ($WARVAL != 0)) {
            $error_detected="W";                                        # Save type of error encountered
            $value_exceeded=$WARVAL;                                    # Save the warning level value
        }
        # Check the actual value against the error level
        if (($ACTVAL == $ERRVAL) && ($ERRVAL != 0)) {
            $error_detected="E";                                        # Save type of error encountered
            $value_exceeded=$ERRVAL;                                    # Save the error level value
        }
    }

    # IF THE TEST TO PERFORM INVOLVE "<" OPERATOR.
    if ($TEST eq "<" ) {
        # Check the actual value against the warning level
        if (($ACTVAL < $WARVAL) && ($WARVAL != 0)) {
            $error_detected="W";                                        # Save type of error encountered
            $value_exceeded=$WARVAL;                                    # Save the warning level value
        }
        # Check the actual value against the error level
        if (($ACTVAL < $ERRVAL) && ($ERRVAL != 0)) {
            $error_detected="E";                                        # Save type of error encountered
            $value_exceeded=$ERRVAL;                                    # Save the error level value
        }
    }

    # IF THE TEST TO PERFORM INVOLVE ">" OPERATOR.
    if ($TEST eq ">" ) {
        # Check the actual value against the warning level
        if (($ACTVAL > $WARVAL) && ($WARVAL != 0)) {
            $error_detected="W";                                        # Save type of error encountered
            $value_exceeded=$WARVAL;                                    # Save the warning level value
        }
        # Check the actual value against the error level
        if (($ACTVAL > $ERRVAL) && ($ERRVAL != 0)) {
            $error_detected="E";                                        # Save type of error encountered
            $value_exceeded=$ERRVAL;                                    # Save the error level value
        }
    }


    # IF NO ERROR WAS DETECTED - EXIT FUNCTION
    if ($error_detected eq "N") { return ; }                            # Return to caller


    #---------- AIX or LINUX Operating System Error Related portion
    if (($MODULE eq "aix") || ($MODULE eq "linux")) {
           
      #---------- FILESYSTEM ALERT OCCURED
      if (($SUBMODULE eq "FILESYSTEM") && ($MODULE eq "linux")) {       # If error/warning on filesystem
        $ERR_MESS = "Filesystem $WID at $ACTVAL% > $value_exceeded%" ;  # Set up Error Message
        write_error_file($error_detected ,"$OSNAME", "FILESYSTEM",$ERR_MESS); # Write rpt file
      
      #   ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();  # Get current epoch time
      #   if ($SYSMON_DEBUG >= 5) {                                      # If Debug is ON
      #      print "\n\n----- Filesystem Increase: $WID at $ACTVAL%\n";  # FileSystem Entered
      #      print "\nActual Time is $year $month $day $hour $min $sec\n"; # Print current time
      #      print "\nActual epoch time is $epoch\n";                      # Print Epoch time
      #   }
      #   # If it is the first occurence of the Error - Put Date and Time in cfg
      #   if ( $SADM_RECORD->{SADM_DATE} == 0 ) {                        # If current date = 0 in SLAM Array
      #      $SADM_RECORD->{SADM_DATE} = sprintf("%04d%02d%02d",$year,$month,$day); # SADM_DATE=current date
      #      $SADM_RECORD->{SADM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);       # SADM_Time=current time
      #   }
      #            
      #   # Split Date and Time of last file increase to be ready to call get_epoch function
      #   $wyear  =sprintf "%04d",substr($SADM_RECORD->{SADM_DATE},0,4); # Extract Year from SADM_DATE
      #   $wmonth =sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},4,2); # Extract Month from SADM_DATE
      #   $wday   =sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},6,2); # Extract Day from SADM_DATE
      #   $whrs   =sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},0,2); # Extract Hour from SADM_TIME
      #   $wmin   =sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},2,2); # Extract Min from SADM_TIME
      #     
      #   # Calculate Epoch Time of the last filesystem increase
      #   $last_epoch = get_epoch("$wyear","$wmonth","$wday","$whrs","$wmin","0");   
      #   if ($SYSMON_DEBUG >= 5) {                                      # If DEBUG if ON
      #       print "Last series of filesystem increase started at $wyear $wmonth $wday $whrs $wmin 00\n"; 
      #       print "Elapsed time since last series of filesystem increase : $last_epoch\n"; 
      #   }
      #
      #   # Calculate the number of seconds since the last execution 
      #   # Current Epoch - Last Epoch of filesystem increase
      #   $elapse_second = $epoch - $last_epoch;                          # Subs Act.epoch-Last epoch
      #   if ($SYSMON_DEBUG >= 5) {                                       # If DEBUG Activated
      #      print "So $epoch - $last_epoch = $elapse_second seconds\n";  # Print Elapsed seconds
      #   }
      #
      #   # If number of second between the last increase and now is greater than 1 Day = OK RUN
      #   if ( $elapse_second >= $MINIMUM_SEC ) {                         # Elapsed Sec >= 1 Day
      #      ($year,$month,$day,$hour,$min,$sec,$epoch) =Today_and_Now(); # Get current epoch time
      #      $SADM_RECORD->{SADM_DATE} = sprintf("%04d%02d%02d", $year,$month,$day); 
      #      $SADM_RECORD->{SADM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);        
      #      $SADM_RECORD->{SADM_MINUTES} = "001";                        # First one Today
      #      if ($SYSMON_DEBUG >= 5) {                                    # If DEBUG Activated
      #         print "Filesystem increase number $SADM_RECORD->{SADM_MINUTES} ";  
      #      }
      #      filesystem_increase($WID);                                   # Go Increase Filesystem
      #   }else{
      #      #$SADM_RECORD->{SADM_MINUTES} ++ ;                           # Increase filesystem counter 
      #      if (($SADM_RECORD->{SADM_MINUTES} + 1) > $INCREASE_PER_DAY){ # If Counter exceed limit
      #         if ($SYSMON_DEBUG >= 5) {                                 # If DEBUG Activated
      #            print "Filesystem increase for $WID as been done $INCREASE_PER_DAY times within last 24 Hrs.";
      #            print "\nFilesystem increase will not be done.";       # Inform user not done
      #         }
      #         $ERR_MESS = "FS $WID at $ACTVAL% > $value_exceeded%" ;    # Set up Error Message
      #         write_error_file($error_detected ,"$OSNAME", "FILESYSTEM",$ERR_MESS); # Write rpt file
      #      }else{
      #         $WORK = $SADM_RECORD->{SADM_MINUTES} + 1;                 # Incr. FS Counter
      #         $SADM_RECORD->{SADM_MINUTES} = sprintf("%03d",$WORK);     # Insert Cnt in Array
      #         if ($SYSMON_DEBUG >= 5) {                                 # If DEBUG Activated
      #            print "Filesystem increase number $SADM_RECORD->{SADM_MINUTES} ";
      #         }
      #         filesystem_increase($WID);                                # Go Increase Filesystem
      #      }
      #   }
      } # End of Filesystem Module
           
      
      #---------- LOAD AVERAGE ALERT OCCURED
      if ($SUBMODULE eq "LOAD") {
         ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();  # Get Date,Time,Epoch Time
         if ($SYSMON_DEBUG >= 5) {                                      # If DEBUG Activated
            print "\nActual Time : $year $month $day $hour $min $sec\n"; 
            print "Actual Epoch Time : $epoch\n"; 
         }
         #----- If it is the first occurence of the Error - Put Date and Time in cfg
         if ( $SADM_RECORD->{SADM_DATE} == 0 ) {
            $SADM_RECORD->{SADM_DATE} = sprintf ("%04d%02d%02d", $year,$month,$day);
            $SADM_RECORD->{SADM_TIME} = sprintf ("%02d%02d",$hour,$min,$sec); 
         }
         #----- Split Date and Time ready to call get_epoch function
         $wyear  = sprintf "%04d",substr($SADM_RECORD->{SADM_DATE},0,4);
         $wmonth = sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},4,2);
         $wday   = sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},6,2);
         $whrs   = sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},0,2);
         $wmin   = sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},2,2);
         #----- Get Epoch Time of the last time we had a load exceeded
         $last_epoch = get_epoch("$wyear", "$wmonth", "$wday", "$whrs", "$wmin", "0");
         if ($SYSMON_DEBUG >= 5) { 
             print "The load on the cpu started at $wyear $wmonth $wday $whrs $wmin 00\n"; 
             print "The load started time in epoch time $last_epoch\n"; 
         }
         #----- Calculate the number of seconds before SADM report the error (Min * 60 sec)
         $elapse_second = $epoch - $last_epoch;
         $max_second = $SADM_RECORD->{SADM_MINUTES} * 60 ;
         if ($SYSMON_DEBUG >= 5) { 
            print "So $epoch - $last_epoch = $elapse_second seconds\n"; 
            print "You asked to wait $max_second seconds before report an error\n";
         }
         #----- If number of second since the last error is greater than wanted - Issue error
         if ( $elapse_second >= $max_second ) {
            $ERR_MESS = "Load Average is $WID and exceeding $value_exceeded for more than $SADM_RECORD->{SADM_MINUTES} Min.";
            write_error_file($error_detected ,"$OSNAME", "LOAD", $ERR_MESS );
            $SADM_RECORD->{SADM_DATE} = $SADM_RECORD->{SADM_TIME} = 0 ;
         }
      } # End of Load Module
           

      #---------- PAGING ALERT OCCURED     
      if ($SUBMODULE eq "PAGING")   { 
         $ERR_MESS = "Paging space at $ACTVAL% > $value_exceeded%" ;
         write_error_file($error_detected ,"$OSNAME", "PAGING", $ERR_MESS );
      } # End of Paging Module
      
           
      #---------- MULTIPATH ALERT OCCURED     
      if ($SUBMODULE eq "MULTIPATH")   { 
         $ERR_MESS = "MultiPath Error - Status is $WID" ;
         write_error_file($error_detected ,"$OSNAME", "MULTIPATH", $ERR_MESS );
      } # End of Multipath Module
      

      #---------- SCRIPT EXECUTION REQUEST WHEN ERROR OCCURED
      if ($SUBMODULE eq "SCRIPT")   { 
         $ERR_MESS = "$OSNAME - Script ${WID}.sh failed !" ;
         my $smess = "${WID}.txt";
         if ( -e "${SADM_SCR_DIR}/$smess" ) {
            if ($SYSMON_DEBUG >= 5) { print "\nContent of file ${SADM_SCR_DIR}/$smess used for error msg"; }
            open SMESSAGE, "${SADM_SCR_DIR}/$smess" or die $!;
            while ($sline = <SMESSAGE>) { chomp $sline ; $ERR_MESS="$sline "; }
            close SMESSAGE;
         }
         write_error_file($error_detected ,"$OSNAME", "SCRIPT", $ERR_MESS );
      } # End of Script Module


      #---------- CPU ERROR OCCURED   
      if ($SUBMODULE eq "CPU") {
         ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();  # Get Date,Time, Epoch Time
         if ($SYSMON_DEBUG >= 5) { 
            print "\nActual Time is $year $month $day $hour $min $sec";
            print "\nActual epoch time is $epoch";
         }
         #----- If it is the first occurence of the Error - Put Date and Time in cfg
         if ( $SADM_RECORD->{SADM_DATE} == 0 ) {
            $SADM_RECORD->{SADM_DATE} = sprintf ("%04d%02d%02d", $year,$month,$day);
            $SADM_RECORD->{SADM_TIME} = sprintf ("%02d%02d",$hour,$min,$sec);
         }
         #----- Split Date and Time ready to call get_epoch function
         $wyear  = sprintf "%04d",substr($SADM_RECORD->{SADM_DATE},0,4);
         $wmonth = sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},4,2);
         $wday   = sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},6,2);
         $whrs   = sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},0,2);
         $wmin   = sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},2,2);
         #----- Get Epoch Time of the last time we had a load exceeded
         $last_epoch = get_epoch("$wyear", "$wmonth", "$wday", "$whrs", "$wmin", "0");
         if ($SYSMON_DEBUG >= 5) { 
             print "\nLoad on the cpu started at $wyear $wmonth $wday $whrs $wmin 00";
             print "\nLhe load started time in epoch time $last_epoch";
         }
         #----- Calculate the number of seconds before SADM SYSMON report the errors (Min * 60 sec)
         $elapse_second = $epoch - $last_epoch;
         $max_second = $SADM_RECORD->{SADM_MINUTES} * 60 ;
         if ($SYSMON_DEBUG >= 5) { 
            print "\nSo $epoch - $last_epoch = $elapse_second seconds";
            print "\nYou asked to wait $max_second seconds before report an error";
         }
         #-----  Number of second between last error and now is greater than wanted - Issue error
         if ( $elapse_second >= $max_second ) {
            print "\nValue exceeded = $value_exceeded";
            print "\nActual Value   = $ACTVAL";
            print "\nMinutes        = $SADM_RECORD->{SADM_MINUTES}";
            $ERR_MESS = sprintf ("CPU at %-3d pct for more than %-3d min",$ACTVAL,$SADM_RECORD->{SADM_MINUTES}) ;
            write_error_file($error_detected ,"$OSNAME", "CPU", $ERR_MESS );
            $SADM_RECORD->{SADM_DATE} = $SADM_RECORD->{SADM_TIME} = 0 ;
         }
      }  # End of CPU SubModule

   } # End of AIX/LINUX Module 
             

   #---------- Error detected for the Module name "NETWORK" 
   # Error detected for the Module name "Network"
   if ($MODULE eq "NETWORK")   { 
      if ($SUBMODULE eq "PING")   { 
         if ($SYSMON_DEBUG >= 5) { print "\nPing to server $WID Failed"; }
         $ERR_MESS = "Cannot ping server $WID - Server may be down" ;
         write_error_file($error_detected ,"NETWORK", "PING", $ERR_MESS );
      }
   } # End of Network Module


   #---------- Error detected for the Module HTTP
   if ($MODULE eq "HTTP")   { 
      $ERR_MESS = "Web Server $WID isn't responding" ;
      write_error_file($error_detected ,"HTTP", "WEBSITE", $ERR_MESS );
   } # End of HTTP Module


   #---------- Error detected - A Daemon was suppose to be running and it is not
   if ($MODULE eq "DAEMON") {
      if ($SUBMODULE eq "PROCESS") {
         $ERR_MESS = "Daemon $WID not running !";
         write_error_file($error_detected ,"DAEMON", "PROCESS", $ERR_MESS );
      }  
   } # End of Daemon Module


   #---------- Error detected - A service was suppose to be running and it is not
   if ($MODULE eq "SERVICE") {
      if ($SUBMODULE eq "DAEMON") {
         $ERR_MESS = "Service $WID not running !";
         write_error_file($error_detected ,"SERVICE", "DAEMON", $ERR_MESS );
      }  
   } # End of Service Module


} # End of Function






#---------------------------------------------------------------------------------------------------
#                                       CHECK HTTP SERVER
#---------------------------------------------------------------------------------------------------
sub check_http {

    # From the sysmon_array extract the application name
    @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;
    $HTTP = $dummy[1];
    if ($SYSMON_DEBUG >= 5) { print "\n-----\nChecking web server status $HTTP "};

    my $url="http://${HTTP}";
    if (! head($url)) { $http_status=0; }else{ $http_status=1; }

    #----- Put current value in slam array and check for error.
    $SADM_RECORD->{SADM_CURVAL} = $http_status ;
    if ($SYSMON_DEBUG >= 5) { 
        if ($http_status == 0) {
            printf "\nWeb server %s is not responding", $HTTP ;
        }else{
            printf "\nWeb server %s is responding", $HTTP ;

        }
    }
    check_for_error($SADM_RECORD->{SADM_CURVAL},
                    $SADM_RECORD->{SADM_WARVAL},
                    $SADM_RECORD->{SADM_ERRVAL},
                    $SADM_RECORD->{SADM_TEST}, 
                    "HTTP",
                    "WEBSITE",
                    $HTTP);
}




#---------------------------------------------------------------------------------------------------
#  CHECK IF SERVICE IS RUNNING - IF NOT TRY TO START IT UP TO 2 TIMES - IF DON'T START ADVISE USER
#---------------------------------------------------------------------------------------------------
sub check_service {
    @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;
    my $SERVICE = $dummy[1];
    print "\n-----\nChecking service $SERVICE";

    #----- From the sysmon_array extract the service name
    my $service_count = 0 ;
    my @dummy = split ('\|', $SERVICE );
    foreach my $srv (@dummy) {
        if ($SYSMON_DEBUG >= 6) { print "\nChecking the service $srv"; }
        $srv_name = $srv ;
        if ( $CMD_SYSTEMCTL eq "") {                                        # If not using systemctl
            my $CMD = "service $srv status" ;
            if ($SYSMON_DEBUG >= 5) { print "\n${CMD}" ; }
            if ( system("$CMD >/dev/null 2>&1") == 0 ) { 
                $service_ok = 1 ; 
                $srv_name = $srv ; 
                print " - *** Running";
            }else{ 
                $service_ok = 0 ; 
                print " - Not Running";
            }
        }else{
            my $CMD = "systemctl status ${srv}.service" ;
            if ($SYSMON_DEBUG >= 5) { print "\n${CMD}" ; }
            #my $output = `$CMD 2>/dev/null` ;
            #system ($CMD);
            if ( system("$CMD >/dev/null 2>&1") == 0 ) { 
                $service_ok = 1 ; 
                $srv_name = $srv ; 
                print " - *** Running";
            }else{ 
                $service_ok = 0 ; 
                print " - Not Running";
            }
        }
        $service_count = $service_count + $service_ok ;
    }

    #----- Put current value in slam array and check for error.
    $SADM_RECORD->{SADM_CURVAL} = $service_count ;
    if ($service_count >= 1) { 
        printf "\nSERVICE IS RUNNING (%d)",$service_count;
    }else{
        printf "\nSERVICE ISN'T RUNNING (%d)",$service_count;
    }
    check_for_error($SADM_RECORD->{SADM_CURVAL},                        # Current Value
                    $SADM_RECORD->{SADM_WARVAL},                        # Warning Threshold Value
                    $SADM_RECORD->{SADM_ERRVAL},                        # Error Threshold Value
                    $SADM_RECORD->{SADM_TEST},                          # Test Operator 
                    "SERVICE",                                          # Name of Module
                    "DAEMON",                                          # Name of Sub Module
                    $srv_name);                                         # Name of the Service
}




#---------------------------------------------------------------------------------------------------
#                           CHECK IF A PARTICULAR DAEMON IS RUNNING
#---------------------------------------------------------------------------------------------------
sub check_daemon {

    #----- From the sysmon_array extract the daemon name
    @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;
    $daemon_name = $dummy[1];
    if ($SYSMON_DEBUG >= 5) { print "\n-----\nChecking if daemon \"$daemon_name \" is running"};

    #-----  Grep for process in the PSFILE1
    open (DB_FILE, "grep \"$daemon_name\" $PSFILE1 | grep -v grep  | wc -l|");
    $daemon1 = <DB_FILE> ; 
    chop $daemon1 ;
    $daemon1 = int $daemon1;
    close DB_FILE;

    #----- Grep for process in the PSFILE2
    open (DB_FILE, "grep \"$daemon_name\"  $PSFILE2 | grep -v grep | wc -l|");
    $daemon2 = <DB_FILE> ; 
    chop $daemon2 ;
    $daemon2 = int $daemon2;
    close DB_FILE;
    
    #----- Retain only the largest number
    if ( $daemon1 >= $daemon2 ) { $daemon = $daemon1 } else { $daemon = $daemon2 } ; 

    #----- Put current value in slam array and check for error.
    $SADM_RECORD->{SADM_CURVAL} = $daemon ;
    if ($SYSMON_DEBUG >= 5) { printf "\nThe number of %s running is %d",$daemon_name, $daemon };
    check_for_error($SADM_RECORD->{SADM_CURVAL},$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST}, "DAEMON", "PROCESS", $daemon_name);
}





#---------------------------------------------------------------------------------------------------
#                           RETURN DATE AND TIME OF THE DAY
#           EXAMPLE : ($CYEAR,$CMONTH,$CDAY,$CHOUR,$CMIN,$CSEC,$CEPOCH) = TODAY_AND_NOW();
#---------------------------------------------------------------------------------------------------
sub Today_and_Now {
    $ctyear  = strftime ("%Y", localtime);                              # The year including century
    $ctmonth = strftime ("%m", localtime);                              # The month range 01 to 12
    $ctday   = strftime ("%d", localtime);                              # The day of month 01 to 31
    $cthrs   = strftime ("%H", localtime);                              # The hour (range 00 to 23)
    $ctmin   = strftime ("%M", localtime);                              # The minute range 00 to 59
    $ctsec   = strftime ("%S", localtime);                              # The second range 00 to 60
    $ctepoch = time();
    return ($ctyear,$ctmonth,$ctday,$cthrs,$ctmin,$ctsec,$ctepoch);
}

#---------------------------------------------------------------------------------------------------
#                   FUNCTION YOU GIVE A DATE AND RETURN YOU THE EPOCH TIME
#           EXAMPLE : $WEPOCH = GET_EPOCH($CYEAR,$CMONTH,$CDAY,$CHOUR,$CMIN,$CSEC);
#---------------------------------------------------------------------------------------------------
sub get_epoch {
    my ($eyear, $emonth, $eday, $ehrs, $emin, $esec) = @_;
    $emth=$emonth-1 ;
    $epoch_time = timelocal($esec,$emin,$ehrs,$eday,$emonth,$eyear); 
    return $epoch_time;
}






#---------------------------------------------------------------------------------------------------
#                                       CHECK LOAD AVERAGE
#---------------------------------------------------------------------------------------------------
sub check_load_average {
    if ($SYSMON_DEBUG >= 5) { print "\n-----\nEntering check_load_average\n"; }

    #----- Get Load Average - Via the uptime command
    open (DB_FILE, "$CMD_UPTIME |");
    $load_line = <DB_FILE> ;
    @ligne = split ' ',$load_line;
    @dummy = split ',',$ligne[10];
    $load_average = int $dummy[0];
    if ($SYSMON_DEBUG >= 5) { 
        printf "Uptime line  is $load_line";  
        printf "Load Average in the last 5 minutes is $load_average"; 
    }
    close DB_FILE;
    $SADM_RECORD->{SADM_CURVAL} = sprintf "%d" ,$load_average ;         # Put value in array
    
    
    #----- If load average less than warning value then reset Date & Time of last exceeded to 0
    if ($SADM_RECORD->{SADM_CURVAL} < $SADM_RECORD->{SADM_WARVAL}) {
        $SADM_RECORD->{SADM_DATE} = $SADM_RECORD->{SADM_TIME} = 0 ;
    }
    
    if ($SYSMON_DEBUG >= 5) { 
        printf "\nLoad Average on $HOSTNAME is $load_average - W=$SADM_RECORD->{SADM_WARVAL} E=$SADM_RECORD->{SADM_ERRVAL}";
   }
   check_for_error($SADM_RECORD->{SADM_CURVAL},$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST},"$OSNAME","LOAD",$load_average);
   return;
}





#---------------------------------------------------------------------------------------------------
#                                   CHECK CPU USAGE
#---------------------------------------------------------------------------------------------------
sub check_cpu_usage {
    if ($SYSMON_DEBUG >= 5) { print "\n-----\nEntering check_cpu_usage"; }

    #----- Get CPU Usage
    open (DB_FILE, "$CMD_VMSTAT 1 2 | $CMD_TAIL -1 |");
    $cpu_use = <DB_FILE> ;
    printf "\nvmstat line is %s" , $cpu_use; 
    @ligne = split ' ',$cpu_use;
    if ( $OSNAME eq "linux" ) {
        $cpu_user   = int $ligne[12];
        $cpu_system = int $ligne[13];
    }else{
        $cpu_user   = int $ligne[13];
        $cpu_system = int $ligne[14];
    }
    $cpu_total  = $cpu_user + $cpu_system;
    close DB_FILE;


    #----- Put current value in slam array and check for error.
    $SADM_RECORD->{SADM_CURVAL} = sprintf "%d" ,$cpu_total ;
    
    #----- If CPU Usage is less than warning value then Reset Date/Time of last exceeded value to 0 
    if ( $SADM_RECORD->{SADM_CURVAL} < $SADM_RECORD->{SADM_WARVAL} ) {
        $SADM_RECORD->{SADM_DATE} = $SADM_RECORD->{SADM_TIME} = 0 ;
    }

    #----- If CPU Usage is less then error value then reset to 0 Date & time of last exceeded value
    if ( $SADM_RECORD->{SADM_CURVAL} < $SADM_RECORD->{SADM_ERRVAL} ) {
        $SADM_RECORD->{SADM_DATE} = $SADM_RECORD->{SADM_TIME} = 0 ;
    }

    #----- Print Information for debug mode
    if ($SYSMON_DEBUG >= 5) { 
        printf "CPU User=%3d System=%3d Total=$cpu_total",$cpu_user, $cpu_system, $cpu_total;
        printf "\nWarning Level=%3d  Error Level=%3d",$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL};
    }
   
    #---- Check if value is normal  
    check_for_error($SADM_RECORD->{SADM_CURVAL},$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST},"$OSNAME","CPU",$cpu_total);
}








#---------------------------------------------------------------------------------------------------
#                                   PAGING SPACE CHECKING
#---------------------------------------------------------------------------------------------------
sub check_swap_space  {
    if ($SYSMON_DEBUG >= 5) { print "\n-----\nChecking Swap Space" ;}

    #----- Linux will return line similar to this "Swap: 2097136 0 20971" 
    open (DF_FILE,"free | grep -i swap |");
    $total_size = $total_use = 0;
    while ($paging = <DF_FILE>) {
        @pline = split ' ', $paging;
        $paging_size = $pline[1] ;
        $paging_use  = $pline[2] ;
        if ($SYSMON_DEBUG >= 5) { 
            print "\nSwap size is $paging_size and using $paging_use";
        }
    }
    close DF_FILE;
    if ($paging_use == 0) { $paging_pct = 0 };
    if ($paging_use != 0) { $paging_pct = int (($paging_use / $paging_size) * 100) } ;
    $total_size = $paging_size;
    $total_use = $paging_use;

    #----- Put current value in slam array and check for error.
    $SADM_RECORD->{SADM_CURVAL} = sprintf "%d" ,$paging_pct ;
    if ($SYSMON_DEBUG >= 5) { 
        print "\nTotal size $total_size MB Pct= $paging_pct %"; 
    }
    check_for_error($SADM_RECORD->{SADM_CURVAL},$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST}, "$OSNAME", "PAGING",$paging_pct);
}






#---------------------------------------------------------------------------------------------------
#    CHECK FILESYSTEM USAGE - CURRENT RESULT OF COMMAND "DF"  WAS PLACE IN ARRAY %DF_ARRAY.
#   NOW WE TRY TO FIND A MATCH BETWEEN %DF ARRAY AND THE HOSTNAME.CFG FILE WITCH IS IN ARRAY 
#---------------------------------------------------------------------------------------------------
sub check_filesystems_usage  {
    if ($SYSMON_DEBUG >= 5) { print "\n-----\nChecking Filesystem Usage";};     
    #$SADM_RECORD->{SADM_SCRIPT} = "scom-fs-inc.sh";                    # Make sure autoincr is there
   
    #----- Try to locate the filesystem in SYSMON Array 
    foreach $key (keys %df_array) {
        if ($key eq $SADM_RECORD->{SADM_ID}) {
            @dummy = split /_/, $key ;
            $fname = substr ($key,2,length($key)-1);
            $fpct  = $df_array{$key};
            #----- Put current value in slam array and check for error.
            $SADM_RECORD->{SADM_CURVAL} = sprintf "%d",$fpct; 
            if ($SYSMON_DEBUG >= 5) {
                print "\nFilesystem $fname at $SADM_RECORD->{SADM_CURVAL} % - Warning at $SADM_RECORD->{SADM_WARVAL} % - Error at $SADM_RECORD->{SADM_ERRVAL} %";
            }
            check_for_error($SADM_RECORD->{SADM_CURVAL},$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST}, "$OSNAME" , "FILESYSTEM", $fname);
            last; 
        }
    }
}





#---------------------------------------------------------------------------------------------------
#                               Ping the server specified
#---------------------------------------------------------------------------------------------------
sub ping_ip  {
    @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;                       # Extract Name or IP from ID
    $ipname = $dummy[1];
    if ($SYSMON_DEBUG >= 5) { print "\n\-----\nTest ping to server $ipname";};

    $PCMD = "ping -c2 $ipname >/dev/null 2>&1" ;
    print "\nThe command that will be executed is $PCMD";
    @args = ("$PCMD");
    system(@args) ;
    $src = $? >> 8;
    $SADM_RECORD->{SADM_CURVAL}=$src;
    if ($SYSMON_DEBUG >= 5) { print "\nReturn code is $SADM_RECORD->{SADM_CURVAL}" ;}
    check_for_error($SADM_RECORD->{SADM_CURVAL},$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST},"NETWORK","PING",$ipname);
    return 
}






#---------------------------------------------------------------------------------------------------
#               THIS FUNCTION IS CALL WHEN A SCRIPT EXECUTION IS REQUESTED
#---------------------------------------------------------------------------------------------------
sub run_script {
    ($dummy,$sname) = split /:/, $SADM_RECORD->{SADM_ID} ;              # Extract Full script name
    (my $sfile_name, my $dirName, my $sfile_extension) = fileparse($sname, ('\.sh') );
    #(my $sfile_name, my $sfile_extension) = split /./, $sname ;        # Split name & extension
    $sname = "${SADM_SCR_DIR}/${sname}";
    if ( $SYSMON_DEBUG >=5) {
         print "\n-----\nExecution of script $sname is requested";
         print "\nFilename is $sfile_name - Extension is $sfile_extension";
    }
   
    #----- If no script specified - return to caller
    if ((length $sname == 0 ) || ($sname eq "-")) {                     # no script specified Error
        print "Script $sname is not specified ??" ;                     # Inform user no script specified
        $SADM_RECORD->{SADM_CURVAL}=1;                                  # Set actual value to 1
        #check_for_error($src,$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST},"$OSNAME","SCRIPT",$sname);
        check_for_error($src,$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST},"$OSNAME","SCRIPT",$sfile_name);
        return;                                                         # return to caller
    }      

    #----- Make sure script Exist and is executable - if not return to caller
    if (( -e "$sname" ) && ( ! -x "$sname")) {                          # Script !exist or !executable
        print "\nScript $sname exist, but not executable";              # Inform user of error
        $SADM_RECORD->{SADM_CURVAL}=1;                                  # Set Actual Value to 1
        check_for_error($src,$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST},"$OSNAME","SCRIPT",$sfile_name);
        return;                                                         # return to caller
    }

    #----- Create an empty file when no error are reported
    #($script_name, $dirName, $sfile_extension) = fileparse($sname, ('\.sh') );
    #$SCOM_APP_FILE = "$SCOM_APP_DIR" . "/" . "$script_name" . ".txt" ;
    #if ($SYSMON_DEBUG >= 5) { printf "\nCreate an empty file name $SCOM_APP_FILE";} 
    #unlink "$SCOM_APP_FILE" ;  
    #open OUT, ">$SCOM_APP_FILE";
    #close OUT;

    #----- Execute the script   
    @args = ("$sname >> ${sname}.log 2>&1");                            # Command to execute
    system(@args) ;                                                     # Execute the Script
    $src = $? >> 8;                                                     # Return code from script


    #----- Put current value in slam array.
    if ($SYSMON_DEBUG >= 5) { printf "\nScript $sname return code is $src";}    # Print Return Code
    $SADM_RECORD->{SADM_CURVAL}=$src;                                   # Actual Value=Return Code
    check_for_error($src,$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST},"$OSNAME","SCRIPT",$sfile_name);
}











#---------------------------------------------------------------------------------------------------
#           CHECK FOR NEW FILESYSTEM - IF THEY ARE NOT IN sysmon_array THEN INSERT THEM 
#---------------------------------------------------------------------------------------------------
sub check_for_new_filesystems  {
    if ($SYSMON_DEBUG >= 5) { print "\n-----\nChecking for new filesystems.\n" };

    # First Get Actual Filesystem Info
    # Don't check cdrom (/dev/cd0) and NFS Filesystem (:) 
    open (DF_FILE, "/bin/df -hP | grep \"^\/\" | grep -v \"\/mnt\/\"| grep -v \"cdrom\"| grep -v \":\" |");

    # Then Compare Actual value versus Warning & Error Value.
    while ($filesys = <DF_FILE>) {
        # Get Filesystem Name and Percentage Full
        @sysline = split ' ', $filesys;
        $fname = $sysline[5];

        # Try to locate the filesystem in SLAM Array 
        $found="N";
        for ($index = 0; $index < @sysmon_array; $index++) {     
            next if ( $sysmon_array[$index] !~ /^FS/ ) ;
            split_fields($sysmon_array[$index]);
            if ( ($SADM_RECORD->{SADM_ID} eq "FS" . "$fname") ) {
                $found="Y";
                last;
            }
        }

        # If filesystem not in sysmon_array then Insert new filesystem in slam.array
        if ($found eq "N" ) {
            $SADM_RECORD->{SADM_ID}      = "FS" . "$fname" ;
            $SADM_RECORD->{SADM_CURVAL}  = "00" ;
            $SADM_RECORD->{SADM_TEST}    = ">=";
            $SADM_RECORD->{SADM_WARVAL}  = "85" ;
            $SADM_RECORD->{SADM_ERRVAL}  = "90";
            $SADM_RECORD->{SADM_MINUTES} = "000";
            $SADM_RECORD->{SADM_STHRS}   = "0000" ;
            $SADM_RECORD->{SADM_ENDHRS}  = "0000";
            $SADM_RECORD->{SADM_SUN}     = "Y";
            $SADM_RECORD->{SADM_MON}     = "Y";
            $SADM_RECORD->{SADM_TUE}     = "Y";
            $SADM_RECORD->{SADM_WED}     = "Y";
            $SADM_RECORD->{SADM_THU}     = "Y" ;
            $SADM_RECORD->{SADM_FRI}     = "Y";
            $SADM_RECORD->{SADM_SAT}     = "Y" ;
            $SADM_RECORD->{SADM_ACTIVE}  = "Y";
            $SADM_RECORD->{SADM_DATE}    = "00000000";
            $SADM_RECORD->{SADM_TIME}    = "0000";
            $SADM_RECORD->{SADM_QPAGE}   = "sadm"; 
            $SADM_RECORD->{SADM_EMAIL}   = "sadm";
            #$SADM_RECORD->{SADM_SCRIPT}  = "sadm_fs_inc.sh";
            $SADM_RECORD->{SADM_SCRIPT}  = " ";

            if ($SYSMON_DEBUG >= 5) { print "New filesystem Found - $fname\n";}
            $index=@sysmon_array;
            $sysmon_array[$index] = combine_fields() ;
        }
    }
    close DF_FILE;
}





#---------------------------------------------------------------------------------------------------
#               ISSUE A DF COMMAND AND LOAD THE RESULT IN AN ARRAY CALLED @DF_ARRAY.
#---------------------------------------------------------------------------------------------------
sub load_df_in_array {
    if ($SYSMON_DEBUG >= 6) { print "\nPutting result of \"df\" command in memory." };

    #----- First Get Actual Filesystem Info
    open (DF_FILE, "/bin/df -hP | grep \"^\/\" | grep -v \"cdrom\"| grep -v \":\" |");

    #-----  Read every line of the df result and store name & percentage use
    while ($filesys = <DF_FILE>) {
        #----- Get Filesystem Name and Percentage Full
        @sysline = split ' ', $filesys;
        $fname = "FS" . "$sysline[5]";
        $fpct =  substr ($sysline[4],0,length($sysline[4])-1);
        if ($SYSMON_DEBUG >= 6) { print "Filesystem $fname is currently at $fpct\n" ;}
        $df_array{"$fname"} = $fpct;
    }
    close DF_FILE;

    #----- Debug info
    if ($SYSMON_DEBUG >= 6) { 
        foreach $key (keys %df_array) {
        print "load_df_in_array : Key=$key Value=$df_array{$key}\n";
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
    if ( $OSNAME eq "aix" ) { return ; } 
    if ($SYSMON_DEBUG >= 5) { print "\n----\nChecking Linux Multipath"; }

    #----- Get output of command and analyse it 
    open (FPATH, "echo 'show paths' | $CMD_MULTIPATHD -k | grep -vEi 'cciss|multipath' | ") or die "Can't execute $CMD_MULTIPATHD \n";
    $WINDEX = 0 ;
    $SADM_RECORD->{SADM_CURVAL} = 1 ; 
   
    while ($line = <FPATH>) {
        $WINDEX ++;
        @ligne = split ' ',$line;
        ($mhcli,$mdev,$mmajor,$mdummy1,$mstatus,$mdumm2,$mdummy3) = @ligne;
        print "\nMultipath Status = $mstatus";
        if ($mstatus ne "[active][ready]") {
            $SADM_RECORD->{SADM_CURVAL} = 0;
            print "Multipath Error Detected" ; 
        }
    }
    close FPATH ;
    if ($SYSMON_DEBUG >= 5) { 
        printf "\nThe Multipath status is %s - Code is (%d) (1=ok 0=Error)",$mstatus, $SADM_RECORD->{SADM_CURVAL};
    }
    check_for_error($SADM_RECORD->{SADM_CURVAL},$SADM_RECORD->{SADM_WARVAL},$SADM_RECORD->{SADM_ERRVAL},$SADM_RECORD->{SADM_TEST}, "linux","MULTIPATH",$mstatus);
}






#---------------------------------------------------------------------------------------------------
#    THIS FUNCTION IS CALLED EVERY TIME AN ERROR IS DETECTED, IT WRITE A LINE TO THE ERROR FILE.
#---------------------------------------------------------------------------------------------------
sub write_error_file {

    #----- Save variables received as parameter
    my ($ERR_LEVEL,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESSAGE) = @_;
    if ($SYSMON_DEBUG >= 6) {                                                   # If Debug is ON
        print "\nError Soft       = $ERR_SOFT";
        print "\nError SUBSYSTEM  = $ERR_SUBSYSTEM";
        print "\nError MEssage    = $ERR_MESSAGE";
    }
   
    #----- Set Error/Warning Date and Time
    $ERR_DATE = `date +%Y.%m.%d`; chop $ERR_DATE;
    $ERR_TIME = `date +%H:%M`   ; chop $ERR_TIME;

    #----- Set Error Type 
   if ($ERR_LEVEL eq "W") { $ERROR_TYPE = "Warning" ; }
   if ($ERR_LEVEL eq "E") { $ERROR_TYPE = "Error"   ; }
   
    #----- Create Line that we may write to the rpt file later
    $SADM_LINE = sprintf "%s;%s;%s;%s;%s;%s;%s;%s;%s\n",$ERROR_TYPE,$HOSTNAME,$ERR_DATE,$ERR_TIME,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESSAGE,$SADM_RECORD->{SADM_QPAGE},$SADM_RECORD->{SADM_EMAIL};
   
    #----- This global variable is set to "Y", so we know that at least one error were found 
    $ERROR_FOUND = "Y";

    #----- If it is a warning write rpt file and return to caller (No script to run for sure)
    if ($ERR_LEVEL eq "W") { print SLAMRPT $SADM_LINE; return; }


    #----- From here it is an error - If filesystem error will be taken care - no script to execute
    if ($ERR_SUBSYSTEM eq "FILESYSTEM")  { print SLAMRPT $SADM_LINE; return; }


    # So error were discovered - But have no script to correct the situation - return to caller
    my $script_name="$SADM_RECORD->{SADM_SCRIPT}";                      # Get Basename script to run
    if ((length $script_name == 0 ) || ($script_name eq "-")) {         # If no script name given
        printf SLAMRPT $SADM_LINE;                                      # Write Error to rpt
        return;                                                         # Return to caller
    }

    #---- Make sure script exist - if not return to caller
    $script_name="${SADM_SCR_DIR}/$script_name";                        # Full path to script name added
    if (! -e $script_name) {                                            # If script doesn't exist
        print "\nThe requested script doesn't exist ($script_name)";    # Advise user
        printf SLAMRPT $SADM_LINE;
        return;
    }

    #----- Make sure script is executable - if not return to caller
    if (( -e "$script_name" ) && ( ! -x "$script_name")) {              # Script not exist,not exec.
        print "\nScript $script_name exist, but is not executable";     # Inform user of error
        printf SLAMRPT $SADM_LINE;
        return;
    }

    #----- Get current date & time in epoch time
    ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();       # Get current epoch time
    if ($SYSMON_DEBUG >= 5) {                                           # If Debug is ON
        print "\nScript name is : $script_name ";                       # Print Script name
        print "\nCurrent Time: $year $month $day $hour $min $sec";      # Print current time
        print "\nThe Actual epoch time is $epoch";                      # Print Epoch time
    }
         
    #----- If first time the script is run - put current date and time in hostname.cfg array
    if ( $SADM_RECORD->{SADM_DATE} == 0 ) {                             # If current date=0 in Array
        $SADM_RECORD->{SADM_DATE} = sprintf("%04d%02d%02d",$year,$month,$day);  # Update SADM_DATE
        $SADM_RECORD->{SADM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);        # Update SADM_Time
    }
                  
    #----- Break last execution date and time from hostname.cfg array - ready for epoch calculation 
    $wyear  = sprintf "%04d",substr($SADM_RECORD->{SADM_DATE},0,4);     # Extract Year from SADM_DATE
    $wmonth = sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},4,2);     # Extract Mth from SADM_DATE
    $wday   = sprintf "%02d",substr($SADM_RECORD->{SADM_DATE},6,2);     # Extract Day from SADM_DATE
    $whrs   = sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},0,2);     # Extract Hrs from SADM_TIME
    $wmin   = sprintf "%02d",substr($SADM_RECORD->{SADM_TIME},2,2);     # Extract Min from SADM_TIME
           
    #----- Get epoch time of the last time script execution
    $last_epoch = get_epoch("$wyear","$wmonth","$wday","$whrs","$wmin","0"); # Epoch of last Exec.
    if ($SYSMON_DEBUG >= 5) {                                           # If DEBUG if ON
        print "\nLast time that $script_name script was executed : $wyear $wmonth $wday $whrs $wmin 00"; 
        print "\nEpoch time of last execution : $last_epoch";           # Last execution epoch time
    }

    #----- Calculate the number of seconds since the last execution in seconds
    $elapse_second = $epoch - $last_epoch;                              # Elapsed time in sec.
    if ($SYSMON_DEBUG >= 5) {                                           # If DEBUG Activated
        print "\nSo $epoch - $last_epoch = $elapse_second seconds";     # Print Elapsed seconds
    }

    #----- Get Process Name
    @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;
    $daemon_name = $dummy[1];

    #----- If number of seconds since last run time is greater than wanted - issue error
    if ( $elapse_second >= $SCRIPT_MIN_SEC_BETWEEN_EXEC ) {             # Elapsed Sec>= 86400 =  ok
        ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();   # Get current date and time
        $SADM_RECORD->{SADM_DATE} = sprintf("%04d%02d%02d", $year,$month,$day); # Update SADM_DATE
        $SADM_RECORD->{SADM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);        # Update SADM_Time
        $SADM_RECORD->{SADM_MINUTES} = "001";                           # Reset since first run today
        if ($SYSMON_DEBUG >= 5) {                                       # If DEBUG Activated
            print "\nScript selected for execution $SADM_RECORD->{SADM_SCRIPT}";
        }
        my $mail_message1 = "Daemon $daemon_name was not running on $HOSTNAME\n";
        my $mail_message2 = "SADM Automatically executed restart script : $SADM_RECORD->{SADM_SCRIPT}";
        my $mail_message3 = " to restart the service. \nThis is the first time I am restarting it.";
        my $mail_message  = "$mail_message1 $mail_message2 $mail_message3";
        my $mail_subject = "SADM: INFO $HOSTNAME daemon $daemon_name restarted";
        @args = ("echo \"$mail_message\" | $CMD_MAIL -s \"$mail_subject\" $SADMIN_EMAIL");
        system(@args) ;
        if ( $? == -1 ) { print "\ncommand failed: $!"; }else{ printf "\ncommand exited with value %d", $? >> 8; }
        $COMMAND = "$script_name >>${script_name}.log 2>&1";
        print "\nCommand sent ${COMMAND}"; 
        @args = ("$COMMAND");
        system(@args) ;
        if ( $? == -1 ) { print "\ncommand failed: $!"; }else{ printf "\ncommand exited with value %d", $? >> 8; }
    }else{
        if (($SADM_RECORD->{SADM_MINUTES} + 1) > $SCRIPT_MAX_RUN_PER_DAY){  # Exceed daily run limit
            if ($SYSMON_DEBUG >= 5) {                                   # If DEBUG Activated
                print "\nScript $SADM_RECORD->{SADM_SCRIPT} as ran $SADM_RECORD->{SADM_MINUTES} times in last 24 Hrs.";
                print "\nWill therefore not be executed.";              # Inform user not done
            }
            @dummy = split /_/, $SADM_RECORD->{SADM_ID} ;
            $daemon_name = $dummy[1];
            $ERR_MESS = "Failed to restart daemon $daemon_name " ;      # Set up Error Message
            $error_detected="E";
            print SLAMRPT $SADM_LINE;
        }else{
            $WORK = $SADM_RECORD->{SADM_MINUTES} + 1;                   # Incr. Run script Counter
            $SADM_RECORD->{SADM_MINUTES} = sprintf("%03d",$WORK);       # Insert Cnt in Array
            if ($SYSMON_DEBUG >= 5) {                                   # If DEBUG Activated
                print "\nThe script $SADM_RECORD->{SADM_SCRIPT} ran $SADM_RECORD->{SADM_MINUTES} time(s) in last 24hrs.";
            }
            $COMMAND = "$script_name >>${script_name}.log 2>&1";
            print "\nCommand sent ${COMMAND}"; 
            @args = ("$COMMAND");
            system(@args) ;
            if ( $? == -1 ) { print "\ncommand failed: $!"; }else{ printf "\ncommand exited with value %d", $? >> 8; }
        }
    }

} # End of write_error_file





#---------------------------------------------------------------------------------------------------
# THIS FUNCTION IS CALLED AT THE BEGINNING TO CREATE A LOCK FILE IN $SADM_BASE_DIR/SADM.LOCK
# IF THE FILE ALREADY EXIST - WE GET THE TIMESTAMP OF THE FILE.
# IF IT WAS CREATED MORE THAN 15 MINUTES AGO, IT IS DELETED AND A NEW ONE IS CREATED.
# THE LOCK IS USED TO MAKE SURE THAT ONLY ONE INSTANCE OF SLAM IS RUNNING AT THE SMAE TIME.
# - ISSUE THE PS COMMAND ONCE THAT WILL BE USED FOR THE REST OF THE SCRIPT
#---------------------------------------------------------------------------------------------------
sub init_process {
  
    # IF YOU REALLY WANT TO PREVENT SADM SYSMON FROM RUNNING CREATE THIS FILE /TMP/SADMLOCK.TXT
    if ( -e "/tmp/sadmlock.txt") { print "/tmp/sadmlock.txt exist - SADM SYSMON not executed";exit 1;} 

    # GET THE ALL THE VALUES FOR CURRENT TIME
    #($SECOND, $MINUTE, $HOUR, $DAY, $MONTH, $YEAR, $WEEKDAY, $DAYOFYEAR, $ISDST) = LOCALTIME(TIME);
    # IF LOCK FILE EXIST, CHECK IF IT IS THERE FOR MORE THAN 15 MINUTES, IF SO DELETE IT
    if ( -e "$SYSMON_LOCK_FILE"  ) { 
        # Get the creation time of the lock file in epoch time
        ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat ($SYSMON_LOCK_FILE);
        print "\nThe lockfile creation time in epoch time = $ctime";
        $creation_date = localtime($ctime);
        #$creation_date = Date::EzDate->new($ctime);
        print "\nThe lockfile creation time is $creation_date";

        my $actual_epoch_time = time();      
        $actual_date = localtime($actual_epoch_time);
        print "\nThe actual time in epoch time = $actual_epoch_time";
        print "\nThe actual time is $actual_date";
        my $elapse_time = ($actual_epoch_time - $ctime) ; 
        print "\nThe lock file was created $elapse_time seconds ago";
        # 30 MINUTES X 60 SECONDS = 1800 SECONDS       
        # IF LOCK FILE IS THERE FOR MORE THAN 1800 SECOND DELETE IT
        if ( $elapse_time >= 1800 ) {
            if ($SYSMON_DEBUG >= 5) { print "\nUpdating TimeStamp of Lock File $SYSMON_LOCK_FILE" ; }
            #unlink "$SYSMON_LOCK_FILE" ;
            #print "\nCreating lock file $SYSMON_LOCK_FILE\n";
            @args = ("$CMD_TOUCH", "$SYSMON_LOCK_FILE");
            system(@args) == 0   or die "system @args failed: $?";
        }else{
            print "\nLock file $SYSMON_LOCK_FILE was create $elapse_time seconds ago - Slam maybe running ?\n";
            print "I will wait until the lock file is 1800 seconds old before deleting it.\n";
            exit 1;
        }    
    }else{
        #print "\nCreating lock file $SYSMON_LOCK_FILE\n";
        @args = ("$CMD_TOUCH", "$SYSMON_LOCK_FILE");
        system(@args) == 0   or die "system @args failed: $?";
    }

    # EXECUTE THE "PS" COMMAND AND OUTPUT THE RESULT TO A FILE
    @args = ("export COLUMNS=4096 ; ps -efwww  > $PSFILE1 ; export COLUMNS=80");
    system(@args) == 0   or print "ps 1 command Failed ! : $?";
    sleep(1);
    @args = ("export COLUMNS=4096 ; ps -efwww > $PSFILE2 ; export COLUMNS=80");
    system(@args) == 0   or print "ps 2 command Failed ! : $?";
    if ($SYSMON_DEBUG >= 6) {
        print "\n\n-----\nContent of PSFILE1\n" ;
        @args = ("cat $PSFILE1");
        system(@args) == 0   or print "Printing PSFILE1 failed ! : $?";
        print "\n\n-----\nContent of PSFILE2\n" ;
        @args = ("cat $PSFILE2");
        system(@args) == 0   or print "Printing PSFILE2 failed ! : $?";
    }
   
    # UNDER LINUX CHECK TO SEE IF WE ARE RUNNING IN A VM (DO NOT CHECK FOR HP ERROR IF IN VM)
    $VM = "N" ;
    if ( $OSNAME eq "linux" ) {
        $COMMAND = "$CMD_DMIDECODE | grep -i vmware >/dev/null 2>&1" ;
        #print "Command sent ${COMMAND}\n"; 
         @args = ("$COMMAND");
        system(@args) ;
        if (($? >> 8) == 0 ) {
             $VM = "Y" ;
        }else{
            $VM = "N" ;
        }
    }
}   




#---------------------------------------------------------------------------------------------------
# UNLOAD THE UPDATED VERSION OF sysmon_array TO SLAM.CFG FILE
#---------------------------------------------------------------------------------------------------
sub loop_through_array {

    # LOOP THROUGH ALL HOSTNAME.CFG FILE IN MEMORY IN SYSMON ARRAY
    for ($index = 0; $index < @sysmon_array; $index++) {                # Process one line at a time  
        next if $sysmon_array[$index] =~ /^#/ ;                         # Don't process comment line
        next if $sysmon_array[$index] =~ /^$/ ;                         # Don't process blank line
        split_fields($sysmon_array[$index]);                            # Split line into fields
        next if $SADM_RECORD->{SADM_ACTIVE} eq "N";                     # If line inactive skip line

        next if `date +%a` =~ /Sun/ && $SADM_RECORD->{SADM_SUN} =~ /N/; # Skip if today=Sunday & Sunday inactivate
        next if `date +%a` =~ /Mon/ && $SADM_RECORD->{SADM_MON} =~ /N/; # Skip if today=Monday & Monday inactivate
        next if `date +%a` =~ /Tue/ && $SADM_RECORD->{SADM_TUE} =~ /N/; # Skip if today=Tuesday & Tuesday inactivate
        next if `date +%a` =~ /Wed/ && $SADM_RECORD->{SADM_WED} =~ /N/; # Skip if today=Wednesday & Wednesday inactivate
        next if `date +%a` =~ /Thu/ && $SADM_RECORD->{SADM_THU} =~ /N/; # Skip if today=Thursday & Thursday inactivate
        next if `date +%a` =~ /Fri/ && $SADM_RECORD->{SADM_FRI} =~ /N/; # Skip if today=Friday & Friday inactivate
        next if `date +%a` =~ /Sat/ && $SADM_RECORD->{SADM_SAT} =~ /N/; # Skip if today=Sat & Sat inactivate

        # IF A START OR AN END TIME WAS SPECIFIED , WE NEED TO VERIFY IF THE LINE IS ACTIVE AT CURRENT TIME
        $evaluate_line="yes" ;                                          # Need to evaluate line ? Default = yes
        if ($SADM_RECORD->{SADM_STHRS} != 0 and $SADM_RECORD->{SADM_ENDHRS} != 0) {
            $current_time = `date +%H%M` ;                                 # Get current Time
            if ($SADM_RECORD->{SADM_ENDHRS} < $SADM_RECORD->{SADM_STHRS}) {
                if (($current_time > $SADM_RECORD->{SADM_STHRS})  || ($current_time < $SADM_RECORD->{SADM_ENDHRS})) { 
                    $evaluate_line="yes"; 
                }else{
                    $SADM_RECORD->{SADM_DATE} = 0; 
                    $SADM_RECORD->{SADM_TIME} = 0; 
                    $evaluate_line="no"; 
                    $sysmon_array[$index] = combine_fields(); # Combine all fields & put it back into array 
                }   
            }else{
                if (($current_time >= $SADM_RECORD->{SADM_STHRS}) && ($current_time <= $SADM_RECORD->{SADM_ENDHRS})) { 
                    $evaluate_line="yes"; 
                }else{ 
                    $SADM_RECORD->{SADM_DATE} = 0; 
                    $SADM_RECORD->{SADM_TIME} = 0; 
                    $evaluate_line="no"; 
                    $sysmon_array[$index] = combine_fields(); # Combine all fields & put it back into array 
                }
            }
        }  
        next if $evaluate_line eq "no" ;
                  
        if ($SADM_RECORD->{SADM_ID} =~ /^check_multipath/  )  {check_multipath ;}           # Check Linux Multipath State
        if ($SADM_RECORD->{SADM_ID} =~ /^load_average/ )      {check_load_average ; }       # Load Average
        if ($SADM_RECORD->{SADM_ID} =~ /^cpu_level/ )         {check_cpu_usage ;  }         # Check CPU Usage
        if ($SADM_RECORD->{SADM_ID} eq "swap_space")          {check_swap_space ; }         # Check Swap Space
        if ($SADM_RECORD->{SADM_ID} =~ /^FS/ )                {check_filesystems_usage ;}   # Check filesystem usage
        if ($SADM_RECORD->{SADM_ID} =~ /^script/  )           {run_script ;}                # Check Running Script
        if ($SADM_RECORD->{SADM_ID} =~ /^daemon_/ )           {check_daemon; }              # Check if specified daemon is running
        if ($SADM_RECORD->{SADM_ID} =~ /^service_/ )          {check_service; }             # Check if specified service is running
        if ($SADM_RECORD->{SADM_ID} =~ /^http/ )              {check_http;    }             # Check HTTP
        if ($SADM_RECORD->{SADM_ID} =~ /^ping_/ )             {ping_ip; }                   # Check Ping an IP
        $sysmon_array[$index] = combine_fields() ;              # Combine all the fields into a line and put it back into the array 
    
    } # End of for loop
} # End of loop_through_array




#---------------------------------------------------------------------------------------------------
#                           E N D    O F    P R O C E S S I N G   
#---------------------------------------------------------------------------------------------------
sub end_of_process {

    # Remove slam.lock file
    print "\n------------ \nDeleting lock file $SYSMON_LOCK_FILE";
    unlink "$SYSMON_LOCK_FILE" or die "Cannnot delete $SYSMON_LOCK_FILE: $!\n" ;

    # Delete PSFILE (contain ps command results)
    unlink "$PSFILE1" or die "Cannnot delete $PSFILE1: $!\n" ;
    unlink "$PSFILE2" or die "Cannnot delete $PSFILE2: $!\n" ;


    # Print Ececution time
    if ($SYSMON_DEBUG >= 5) { 
        printf ("\n#SLAMSTAT $VERSION_NUMBER $HOSTNAME - %s - Execution Time %2.2f seconds\n", scalar localtime(time),$end_time - $start_time); 
    }
}






#---------------------------------------------------------------------------------------------------
#                        M A I N    P R O G R A M    S T A R T   H E R E  !
#---------------------------------------------------------------------------------------------------
#
    init_process;                                   # Create lock file & do ps command to file
    $start_time = time;                             # Store Starting time - To calculate elapse time
    load_host_config_file;                          # Load `hostname`.cfg file in memory into array
    load_df_in_array;                               # Load the "df"  result in a array
    open (SLAMRPT," >$SYSMON_RPT_FILE")  or die "Can't open $SYSMON_RPT_FILE: $!\n"; 
    check_for_new_filesystems;                      # Check for new filesystem first
    loop_through_array;                             # Loop through Slam Array line by line
    close SLAMRPT;                                  # Close report file 
    system ("chmod 664 $SYSMON_RPT_FILE");          # Make file readable by everyone
    unload_host_config_file;                        # Unload Update Array to hostname.cfg file
    end_of_process;                                 # Delete lock file - Print Elapse time
