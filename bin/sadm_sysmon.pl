#!/usr/bin/perl
#! /usr/bin/env sh
#===================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_sysmon.pl
#   Synopsis :  sadm System Monitor
#   Version  :  1.5
#   Date     :  15 Janvier 2016
#   Requires :  sh
#===================================================================================================
use English;
use Date::EzDate;
use File::Basename;

system "export TERM=xterm";


#===================================================================================================
#                                   Global Variables definition
#===================================================================================================
my $VERSION_NUMBER = "2.5";                                             # Version Number
my @sysmon_array = ();                                                  # Array Contain sysmon.cfg 
my %df_array   = ();                                                    # Array Contain FS info
my $OSNAME     = `uname -s`; chomp $OSNAME;                             # Get O/S Name
$OSNAME        =~ tr/A-Z/a-z/;                                          # OS name in lowercase (linux aix)
my $HOSTNAME   = `hostname -s`; chomp $HOSTNAME;                        # HostName of current System
my $DEBUG      = "$ENV{'SLAM_DEBUG'}" || "5";                           # debugging purpose set to 5
my $DSM_DIR    = "$ENV{'DSM_DIR'}" || "/opt/tivoli/tsm/client/ba/bin64"; # TSM Client Executable Dir.
#
my $SADM_BASE_DIR="/sadmin";                                            # Directory where slam file reside
my $SADM_BIN_DIR  = "$SADM_BASE_DIR/bin";                               # Slam bin Directory
my $SLAMTMP_DIR  = "$SADM_BASE_DIR/tmp";                          # Slam temp Directory
my $SLAMLOG_DIR  = "$SADM_BASE_DIR/log";                          # Slam LOG Directory
my $SLAMRPT_DIR  = "$SADM_BASE_DIR/rpt";                          # Slam result files 
my $SLAMCFG_DIR  = "$SADM_BASE_DIR/cfg";                          # Slam Configuration Directory
my $ADSMLOG_DIR = "/var/adsmlog";                           # Where we create the ADSM & Backtrack Backup Log
my $SLAMSCR_DIR  = "$SADM_BASE_DIR/scripts";                      # Slam Script Directory
my $SLAMSCR_DBA  = "$SLAMSCR_DIR/db_test_connect_master.sh";# Slam DB2 SCRIPT
my $SLAMTXT_DIR  = "$SADM_BASE_DIR/txt";                          # SCOM Result text file directory
my $SFTPCMD = "/tmp/slamsftp.txt";                          # Temp Command file for sftp
my $DB2TAB = "/etc/db2tab";                                 # DB2 Instance Listing file
my $PSFILE1 = "$SLAMTMP_DIR/PSFILE1.$$";                    # File that will contains result of ps command
my $PSFILE2 = "$SLAMTMP_DIR/PSFILE2.$$";                    # File that will contains result of ps command
my $SLAMSCP_FILE = "$SLAMCFG_DIR/use_scp.txt";              # If this file exist use scp instead of rcp
my $SLAMRCP_FILE = "$SLAMCFG_DIR/use_rcp.txt";              # If this file exist use rcp instead of scp
my $SLAMTMP_FILE = "$SADM_BASE_DIR/tmp/$HOSTNAME.tmp";            # Slam temp work file
my $SLAMCFG_FILE = "$SLAMCFG_DIR/$HOSTNAME.cfg";            # Slam configuration file
my $SLAMRPT_FILE = "$SLAMRPT_DIR/$HOSTNAME.rpt";            # Slam Single Report File for AIX/Linux
my $SLAMLCK_FILE = "$SADM_BASE_DIR/scom.lock";                    # Slam Lock file
my $ALIAS_FILE = "$SLAMCFG_DIR/slam_alias.cfg";             # Slam Alias file
my $SLAMHOST = "$SLAMCFG_DIR/slam.hosts";                   # Slam report file
my $ERROR_FOUND = "N";                                      # Set Yes if error written on error file
my $start_time = $end_time = 0;                             # Calc. execution Time written to cfg file
my $WINDEX = 0;                                             # Array Index - For temp usage
my $WORK = 0;                                               # For temp usage
my $MINIMUM_SEC=86400;                                      # 1 Day=86400 Sec. = Minimum between 1st & 3thd filesystem incr.
my $INCREASE_PER_DAY=2;                                     # Number of filesystem increase allowed per Day.
my $SCRIPT_MIN_SEC_BETWEEN_EXEC=86400;                      # Restart script did not run for more than this value then ok to run
my $SCRIPT_MAX_RUN_PER_DAY=2;                               # Number of time the restart script can be run during one day
#
my $ADSMUSR = "-id=query -password=query";                  # User/Password Used to query ADSM
my $TSMTMP  = "$SADM_BASE_DIR/tmp/tsmsched.tmp";                  # Output of TSM command will in this file
my $TSMTMP1 = "$SADM_BASE_DIR/tmp/tsmsched1.tmp";                 # Output of TSM command will in this file
my $TSMTMP2 = "$SADM_BASE_DIR/tmp/tsmsched2.tmp";                 # Output of TSM command will in this file
#
# HTTP match 
my $MATCH_SUN_HTTP="perl -ne 'print \$1.\"\n\" if m#webservd-wdog.*/iplanet7/https-(.*?)/#'";
my $MATCH_HTTP="perl -ne 'print \"\$1_\$2\n\" if m#-f /usr/http/(.*?)/.*?/(.*?)-httpd.conf# || m#-f /usr/http/(.*?)/instances/(.*?)/httpd.conf#'";
#
# RedHat Cluster Data
my $CLUSTER_CFG = "/etc/cluster/cluster.conf" ;             # Location of RedHat Cluster Config file
my $CLUSTAT     = "/usr/sbin/clustat" ;                     # Location of clustat command
my $CMAN_TOOL   = "/usr/sbin/cman_tool" ;                   # Location of cman_tool command
my $CLUSTER     = "Y"    ;                                  # Cluster active by default
if ( ! -e "$CLUSTER_CFG"  ) { $CLUSTER = "N" };             # If no cluster.cfg no cluster then
if ( ! -e "$CLUSTAT"  )     { $CLUSTER = "N" };             # If no clustat binary no cluster then
#print "Is this server part of a cluster ? $CLUSTER \n";     # Display if server is part of a cluster
       
# Determine the location of the TSM include-exclude file
my $DSM_INCL_FILE = "/usr/tivoli/tsm/client/ba/bin/include-exclude-list" ;    # Aix Location 
if ( $OSNAME eq "linux" ) { $DSM_INCL_FILE = "$DSM_DIR/include-exclude-list" ;}
   
   
# TSM Development Data (TSMNovell)
my $NOV_DSMSERV_CONFIG = "/tdb2tsm2/dsmserv.opt";           # Novell TSM Server Novell option file
my $NOV_DSM_CONFIG = "/usr/tivoli/tsm/client/ba/bin64/nov_dsm.opt";  # Novell TSM Client option file
my $NOV_DSMADMC = "export DSMSERV_CONFIG=$NOV_DSMSERV_CONFIG; export DSM_CONFIG=$NOV_DSM_CONFIG; dsmadmc $ADSMUSR" ;

# TSM Production Data (AdsmServ)
my $AIX_DSMSERV_CONFIG = "/pdb2tsm1/dsmserv.opt" ;          # Location of AIX TSM server Novell Instance
my $AIX_DSM_CONFIG = "/usr/tivoli/tsm/client/ba/bin64/dsm.opt";       # Location of AIX TSM client option file
my $AIX_DSMADMC = "export DSMSERV_CONFIG=$AIX_DSMSERV_CONFIG; export DSM_CONFIG=$AIX_DSM_CONFIG; dsmadmc $ADSMUSR" ;
my $AIX_RCFILE = "$SLAMRPT_DIR/aix_missed.rpt";             # Contain AIX Schedule missed file
my $WIN_RCFILE = "$SLAMRPT_DIR/win_missed.rpt";             # Contain Windows Schedule missed file
my $DBA_RCFILE = "$SLAMRPT_DIR/dba_missed.rpt";             # Contain DBA     Schedule missed file
my $TSMMISSED_FLAG = 0 ;                                    # Will be set to 1 if schedule missed are checked
#
#
# Programs Location and Command Line Options used ...
my $CMD_CHMOD  = `which chmod`; chomp($CMD_CHMOD);          # Location of the unix chmod command
my $CMD_CP     = "/bin/cp" ;                                # Location of the unix cp command
my $CMD_RCP    = "/usr/bin/rcp" ;                           # Location of the unix rcp command
my $CMD_FIND   = "/usr/bin/find" ;                          # Location of the unix find command
my $CMD_MAIL   = "/usr/bin/mail" ;                          # Location of the unix mail command
my $CMD_TAIL   = "/usr/bin/tail" ;                          # Location of the unix tail command
my $CMD_HEAD   = "/usr/bin/head" ;                          # Location of the unix tail command
my $CMD_UPTIME = "/usr/bin/uptime" ;                        # Location of the unix uptime command
my $CMD_VMSTAT = "/usr/bin/vmstat" ;                        # Location of the unix vmstat command
my $CMD_MULTIPATHD = "/sbin/multipathd";                    # Location of the unix multipathd command
my $DMIDECODE  = "/usr/sbin/dmidecode";                     # DMIDECODE used to check if we are in a VM
my $SSH_BIN    = `which ssh`; chomp($SSH_BIN);              # Get location of ssh (Aix/Linux)
my $SCP_BIN    = `which scp`; chomp($SCP_BIN);              # Get location of scp (Aix/Linux)

# Exception for 2 Servers that have OpenSSH and SSH Running - Use OpenSSH CLient Version
if (($HOSTNAME eq "wonhyo") ||  ($HOSTNAME eq "yulgok")) { $SSH_BIN = "/usr/bin/ssh"; }

my $SSH_VER    = 0 ;

# Will be set to 1 if on this server if we need to monitor Oracle Instance
my $DO_NOT_MONITOR_ORACLE=0;                                # Will be set to 1 if no Oracle Monitor

   
   
# SCOM and SADM Related Variables
my $SCOM_DSERVER = "nmmq1d27.slacdev.ca" ;                  # Scom Dev Server - Host Name 
my $SCOM_DUSER   = "dsccsrv";                               # SCOM Dev. UserName
my $SCOM_PSERVER = "nmmq1p70.slac.ca" ;                     # Scom Prod. Server - Host Name 
my $SCOM_PUSER   = "psccsrv";                               # SCOM Prod. UserName
my $HEALTHY = "healthy";                                    # Healthy litteral written to txt file
my $WARNING = "warning";                                    # Warning litteral written to txt file
my $CRITICAL= "critical";                                   # Critical litteral written to txt file
my $SCOM_STATUS = "";                                       # Actual SCOM status
my $SCOM_RDIR = "D:\\UNIX";                                 # SCOM Remote Directory
my $SCOM_CFG_FILE = "${SLAMCFG_DIR}/sadm_sysmon.cfg";             # SADM Configuration File
my $SSH_OPTS  = "-x -p32 " ;                                 # SCOM SSH Tectia/OpenSSH Client Options

my $SCOM_DSSH  = "$SSH_BIN $SSH_OPTS ${SCOM_DUSER}\@${SCOM_DSERVER}"; # SSH to SCOM Dev. Server
my $SCOM_PSSH  = "$SSH_BIN $SSH_OPTS ${SCOM_PUSER}\@${SCOM_PSERVER}"; # SSH to SCOM Prod. Server
my $SCOM_SCP   = "$SCP_BIN -rP 32 ";  #
if (($HOSTNAME eq "wonhyo") ||  ($HOSTNAME eq "yulgok")) { $SCOM_SCP = "$SCP_BIN -r -P 32 "; }
my $SSH_COMMAND  = "";                                      # Variable to hold to Final SSH command

# SCOM DataConfig File fields
my $SERVER_TYPE = 'P' ;                                     # Server Type - Default to [P]rod ([D]ev)
my $MKDIR_REMOTE = "Y" ;                                    # Issue mkdir for all dir on remote scom
my $USE_SSH = "N";                                          # USE_SSH (SCP) or rcp to copy file
my $OPENSSH = "Y";                                          # Use openssh by Default, except some Aix


my $VM = "N" ;                                              # Are we in a VM (No by Default)
#
my $SCOM_MVS_FILE= "$SLAMTXT_DIR/mvs/mvs.txt";              # SCOM MVS Status File
my $SCOM_DBA_FILE= "$SLAMTXT_DIR/dba/dba.txt";              # SCOM DBA Status File
my $SCOM_OS_FILE = "$SLAMTXT_DIR/os/os.txt";                # SCOM O/S Status File
my $SCOM_WAS_FILE= "$SLAMTXT_DIR/was/was.txt";              # SCOM Was Monitor Status File
my $SCOM_WAS_TMP = "$SLAMTMP_DIR/was.tmp";                  # SCOM Was Monitor Temp File
my $SCOM_WASMON_FILE= "$SLAMTMP_DIR/wasmon_p.txt";          # Was2SCOM status file
my $SCOM_PA_FILE = "$SLAMTXT_DIR/pa/pa.txt";                # SCOM Production Analyst Status File
my $SCOM_APP_DIR = "$SLAMTXT_DIR/app";                      # SCOM Application Directory txt 
my $SCOM_APP_FILE = "$SLAMTXT_DIR/app/app.txt";             # SCOM Application txt file 
my $SCOM_FTP_FILE = "$SLAMTXT_DIR/ftp/ftp.txt";             # SCOM FTP Application txt file 

#
# Sysinfo Server
my $SYSINFO_HOST     = "lxmq0007";                          # Sysinfo Host Linux Server without domain
my $SYSINFO_SERVER   = "sysinfo.slac.ca" ;                  # Sysinfo Host Linux Server with domnain
my $SYSINFO_TXT      = "/sysinfo/www/data/txt/${HOSTNAME}"; # Sysinfo Linux Server txt directory  
my $SYSINFO_RPT      = "/sysinfo/www/data/rpt" ;            # Sysinfo Linux Server rpt directory  
my $SYSINFO_RC       = "/sysinfo/www/data/rc" ;             # Sysinfo Linux Server rc directory  
my $SYSINFO_DBA      = "/sysinfo/www/data/dba" ;            # Sysinfo Linux Server DBA rc directory  
my $SLAM_SERVER      = "slamserver" ;                       # Slam Server host name
my $SLAM_ACCOUNT     = "slam\@slamserver:" ;                # Used to rcp files to slamserver
my $SYSINFO_ACCOUNT  = "slam\@sysinfo:" ;                   # Used to rsync files to sysinfo
my $SLAM_ADMIN_EMAIL = "aixteam\@standardlife.ca";          # Unix Admin Email Address
my $SADM_ADMIN_EMAIL= "aixteam\@standardlife.ca";   # Unix Admin Email Address

if ( $OSNAME eq "linux" )                                   # Command located in Linux
{
   $CMD_CP = "/bin/cp" ;                                    # Location of the unix copy command 
   $CMD_TOUCH = "/bin/touch" ;                              # Location of the unix touch command
   $CMD_MAIL = "/bin/mail" ;                                # Location of the unix mail command
   $HDLM_DLKMGR = "/opt/DynamicLinkManager/bin/dlnkmgr";    # Hitachi program to query adapter
}else{                                                      # Command Located in AIX
   $CMD_CP = "/usr/bin/cp" ;                                # Location of the unix cp command 
   $CMD_TOUCH = "/usr/bin/touch" ;                          # Location of the unix touch command
   $CMD_MAIL = "/usr/bin/mail" ;                            # Location of the unix mail command
   $HDLM_DLKMGR = "/usr/DynamicLinkManager/bin/dlnkmgr";    # Location of program to query adapter
}


# server.cfg file layout , field separated by a space
# --------------------------------------------------------------------------------------------------
$SLAM_RECORD = {
   SLAM_ID => " ",                                          # IDENTIFIER 
   SLAM_CURVAL => " ",                                      # Last Value calculated by slam
   SLAM_TEST =>   " ",                                      # Evaluation Operator (=,!=,<,>,=>,=<) 
   SLAM_WARVAL => " ",                                      # Warning Level (0=not evaluated)
   SLAM_ERRVAL => " ",                                      # Error Level (0=not evaluated)     
   SLAM_MINUTES =>" ",                                      # Error must occur over X minutes before trigger
   SLAM_STHRS =>  " ",                                      # Hours to start evaluate (0=not evaluate)
   SLAM_ENDHRS => " ",                                      # Hours to stop evaluate (0=not evaluate
   SLAM_SUN =>    " ",                                      # Test to be done on Sunday (Y/N) 
   SLAM_MON =>    " ",                                      # Test to be done on Monday (Y/N) 
   SLAM_TUE =>    " ",                                      # Test to be done on Tuesday (Y/N) 
   SLAM_WED =>    " ",                                      # Test to be done on Wednesday (Y/N) 
   SLAM_THU =>    " ",                                      # Test to be done on Thrusday (Y/N) 
   SLAM_FRI =>    " ",                                      # Test to be done on Friday (Y/N) 
   SLAM_SAT =>    " ",                                      # Test to be done on Saturday (Y/N) 
   SLAM_ACTIVE => " ",                                      # Line is Active or not
   SLAM_DATE =>   " ",                                      # Last Date this line was evaluated
   SLAM_TIME =>   " ",                                      # Last Time this line was evaluated
   SLAM_QPAGE =>  " ",                                      # Slam Alias to page
   SLAM_EMAIL =>  " ",                                      # Slam Alias to send email
   SLAM_SCRIPT => " ",                                      # Script to execute when an Error occurs
};








# ==================================================================================================
# FUNCTION TO LOAD THE CONTENT OF $SADM_BASE_DIR/CFG/`HOSTNAME`.CFG FILE IN AN ARRAY CALLED @sysmon_array.
# ==================================================================================================
sub load_slam_file {

    # For debug purpose - Display Important Data 
    if ($DEBUG >= 5) {
      print "\nSADM - SADM Tools\n";
      print "------------------------------------------------------------------------------\n";
      print "Version Number           = ${VERSION_NUMBER}\n"; 
      print "O/S Name                 = ${OSNAME}\n" ;
      print "Debugging Level          = ${DEBUG}\n" ;
      print "SADM_BASE_DIR            = ${SADM_BASE_DIR}\n";      
      print "Hostname                 = ${HOSTNAME}\n" ;
      print "Virtual Server           = ${VM}\n" ;
      print "In a Cluster             = ${CLUSTER}\n" ;
      print "Server Type              = ${SERVER_TYPE}\n";
      print "Make Remote Dir          = ${MKDIR_REMOTE}\n";
      print "SSH_BIN                  = ${SSH_BIN}\n";
      print "------------------------------------------------------------------------------\n";
    }


    # Check if Hostname.cfg exist, if not copy standard.cfg in hostname.cfg
    # This should not normally happens - if it does email sysadmin
   if ( ! -e "$SLAMCFG_FILE"  ) {
      my $mail_message = "File $SLAMCFG_FILE not found - New file is created based on standard.cfg";    
      my $mail_subject = "SLAM ALERT: $SLAMCFG_FILE Deleted on $HOSTNAME";
      @cmd = ("echo \"$mail_message\" | $CMD_MAIL -s \"$mail_subject\" $SLAM_ADMIN_EMAIL");
      $return_code = 0xffff & system @cmd ;
      
      # copy Linux or Aix Template config file , depending on OS
      @cmd = ("$CMD_CP $SLAMCFG_DIR/standard.cfg $SLAMCFG_FILE");
      if ( $OSNAME eq "linux" ) { 
         @cmd = ("$CMD_CP $SLAMCFG_DIR/standard_linux.cfg $SLAMCFG_FILE"); 
      }else{
         @cmd = ("$CMD_CP $SLAMCFG_DIR/standard_aix.cfg $SLAMCFG_FILE"); 
      }
      $return_code = 0xffff & system @cmd ;
      @cmd = ("$CMD_CHMOD 664 $SLAMCFG_FILE");
      $return_code = 0xffff & system @cmd ;
   }

    
# Open slam server.cfg file and load it in an array called sysmon_array
# ==================================================================================================
   open (SLAMFILE,"<$SLAMCFG_FILE") or die "Can't open $SLAMCFG_FILE: $!\n";
   $widx = 0;
   while ($line = <SLAMFILE>) {                             # Read while end of file
         next if $line =~ /^#SLAMSTAT/ ;                    # Don't load the Slam statistic line
         next if (($line =~ /^oracle_/) && ($DO_NOT_MONITOR_ORACLE == 1));
         $sysmon_array[$widx++] = $line ;                     # It will be rewritten at the end
         if ($DEBUG >= 6) { print "Line loaded from cfg : $line" ; }
   }
   close SLAMFILE;                                          # Close the SLAM server Config file


# If in debug mode display number of element loaded
# --------------------------------------------------------------------------------------------------
   if ($DEBUG >= 5) {                                       # If in debug mode 
      $nbline = @sysmon_array;                                # Get number of element loaded
      print "File $SLAMCFG_FILE loaded in sysmon_array ($nbline lines loaded)\n";
   }
   if ($DEBUG >= 6)  { display_sysmon_array ; }
}





# THIS FUNCTION IS CALLED AT THE END, TO UNLOAD THE ARRAY BACK TO DISK IN THE `HOSTNAME`.CFG FILE
# --------------------------------------------------------------------------------------------------
sub unload_slam_file {
   
# Open (Create) an empty temporary file to unload SLAM config file
# --------------------------------------------------------------------------------------------------
   open (SLAMTMP,">$SLAMTMP_FILE") or die "Can't create $SLAMTMP_FILE: $!\n";
   if ($DEBUG >= 6) {       
      print "\n-----\nI am unloading the array \"sysmon_array\" to the file $SLAMCFG_FILE\n" ;
   }

# Unload sysmon_array to Disk
# --------------------------------------------------------------------------------------------------
   for ($widx = 0; $widx < @sysmon_array; $widx++) {             # Loop until end of array
      print (SLAMTMP "$sysmon_array[$widx]");                    # Write line to config file
   }

# Get ending time & Write Slam Statistic line at the EOF
# --------------------------------------------------------------------------------------------------
   $end_time = time;                                           # Get current time
   printf (SLAMTMP "#SLAMSTAT $VERSION_NUMBER $HOSTNAME - %s - Execution Time %2.2f seconds\n", scalar localtime(time), $end_time - $start_time); 
   close SLAMTMP ;                                             # Close temporary file


# Delete old SLAM config file and rename the temp file to SLAM config file
# --------------------------------------------------------------------------------------------------
   unlink "$SLAMCFG_FILE" ;                                    # Delete Cur. `hostname`.cfg 
   if (!rename "$SLAMTMP_FILE", "$SLAMCFG_FILE")               # Rename wfile to `hostname`.cfg 
      { print "Could not rename $SLAMTMP_FILE to $SLAMCFG_FILE: $!\n" }
   system ("chmod 660 $SLAMCFG_FILE");                         # Make sure file is read-write for gou
}




# FUNCTION CALLED TO DISPLAY sysmon_array CONTENT (FOR DEBUG PURPOSE)
# --------------------------------------------------------------------------------------------------
sub display_sysmon_array {
   for ($widx = 0; $widx < @sysmon_array; $widx++) { 
      print ("$sysmon_array[$widx]"); 
   }
}






# EXTRACT EACH FIELDS FROM THE LINE RECEIVED IN PARAMETER TO WORK FIELDS
# --------------------------------------------------------------------------------------------------
sub split_fields {
   my $wline = $_[0];
   (  $SLAM_RECORD->{SLAM_ID},
      $SLAM_RECORD->{SLAM_CURVAL},
      $SLAM_RECORD->{SLAM_TEST},
      $SLAM_RECORD->{SLAM_WARVAL},
      $SLAM_RECORD->{SLAM_ERRVAL},
      $SLAM_RECORD->{SLAM_MINUTES},
      $SLAM_RECORD->{SLAM_STHRS},
      $SLAM_RECORD->{SLAM_ENDHRS},
      $SLAM_RECORD->{SLAM_SUN},
      $SLAM_RECORD->{SLAM_MON},
      $SLAM_RECORD->{SLAM_TUE},
      $SLAM_RECORD->{SLAM_WED},
      $SLAM_RECORD->{SLAM_THU},
      $SLAM_RECORD->{SLAM_FRI},
      $SLAM_RECORD->{SLAM_SAT},
      $SLAM_RECORD->{SLAM_ACTIVE},
      $SLAM_RECORD->{SLAM_DATE},
      $SLAM_RECORD->{SLAM_TIME},
      $SLAM_RECORD->{SLAM_QPAGE},
      $SLAM_RECORD->{SLAM_EMAIL},
      $SLAM_RECORD->{SLAM_SCRIPT} ) = split ' ',$wline;
}


# COMBINE ALL FIELDS BACK TOGETHER INTO A LINE IN SLAM SERVER.CFG FORMAT
# --------------------------------------------------------------------------------------------------
sub combine_fields {

   my $wline = sprintf "%-30s %3s %2s %3s %3s %3s %04d %04d %1s %1s %1s %1s %1s %1s %1s %1s %08d %04d %s %s %s\n",
     $SLAM_RECORD->{SLAM_ID},
     $SLAM_RECORD->{SLAM_CURVAL},
     $SLAM_RECORD->{SLAM_TEST},
     $SLAM_RECORD->{SLAM_WARVAL},
     $SLAM_RECORD->{SLAM_ERRVAL},
     $SLAM_RECORD->{SLAM_MINUTES},
     $SLAM_RECORD->{SLAM_STHRS},
     $SLAM_RECORD->{SLAM_ENDHRS},
     $SLAM_RECORD->{SLAM_SUN},
     $SLAM_RECORD->{SLAM_MON},
     $SLAM_RECORD->{SLAM_TUE},
     $SLAM_RECORD->{SLAM_WED},
     $SLAM_RECORD->{SLAM_THU},
     $SLAM_RECORD->{SLAM_FRI},
     $SLAM_RECORD->{SLAM_SAT},
     $SLAM_RECORD->{SLAM_ACTIVE},
     $SLAM_RECORD->{SLAM_DATE},
     $SLAM_RECORD->{SLAM_TIME},
     $SLAM_RECORD->{SLAM_QPAGE},
     $SLAM_RECORD->{SLAM_EMAIL},
     $SLAM_RECORD->{SLAM_SCRIPT};
   return "$wline";
}



# FILESYSTEM INCREASE FUNCTION
# --------------------------------------------------------------------------------------------------
sub filesystem_increase {
   my ($FILESYSTEM) = @_;                                               # filesystem name to incr.

   if (($OSNAME eq "aix") || ($CLUSTER eq "Y")) {
      print "\nFS increase not supported on AIX and within Linux Cluster";     # Advise User
      return 0 ; 
   }else{
      print "\nFilesystem $FILESYSTEM selected for increase";           # Entering filesystem funct.
   }
   
   my $FS_SCRIPT = "${SADM_BIN_DIR}/$SLAM_RECORD->{SLAM_SCRIPT}";
   $FSCMD = "$FS_SCRIPT $FILESYSTEM >>${SLAMLOG_DIR}/$SLAM_RECORD->{SLAM_SCRIPT}.log 2>&1" ;
   print "\nThe command that will be executed is $FSCMD";
   @args = ("$FSCMD");
   $src = system(@args) ;
   if ( $src == -1 ) { print "\ncommand failed: $!"; }else{ printf "\ncommand exited with value %d", $? >> 8; }
   return $src ;
}



# ROUTINE TO CHECK THE ACTUAL VALUE VERSUS THE WARNING & ERROR VALUE
# --------------------------------------------------------------------------------------------------
sub check_for_error {

# Fields received as parameters ;
#  Actual Value, Warning Value, Error Value, Test to make (=,<,>,...) 
#  Module Name (AIX, PSSP, ADSM, AUTOSYS, ...) Submodule (Filesystem, ...) and
#  Value used in the error message.
   my ($ACTVAL, $WARVAL, $ERRVAL, $TEST, $MODULE, $SUBMODULE, $WID) = @_;
   if ($DEBUG >= 6) { printf "\nCheck for Error - WID = $WID";}
      
   $error_detected="N";                                                 # No Error detected by default

# If the test to perform involve ">=" operator.
   if ($TEST eq ">=" ) {
      if (($ACTVAL >= $WARVAL) && ($WARVAL != 0)) {                     # Check the actual value against the warning level
         $error_detected="W";                                           # Save type of error encountered
         $value_exceeded=$WARVAL;                                       # Save the warning level value
      }
      if (($ACTVAL >= $ERRVAL) && ($ERRVAL != 0)) {                     # Check the actual value against the error level
         $error_detected="E";                                           # Save type of error encountered
         $value_exceeded=$ERRVAL;                                       # Save the error level value
      }
   }

# If the test to perform involve "<=" operator.
   if ($TEST eq "<=" ) {
       # Check the actual value against the warning level
       if (($ACTVAL <= $WARVAL) && ($WARVAL != 0)) {
          $error_detected="W";              # Save type of error encountered
          $value_exceeded=$WARVAL;          # Save the warning level value
       }
       # Check the actual value against the error level
       if (($ACTVAL <= $ERRVAL) && ($ERRVAL != 0)) {
          $error_detected="E";              # Save type of error encountered
          $value_exceeded=$ERRVAL;          # Save the error level value
       }
   }

# If the test to perform involve "!=" operator.
   if ($TEST eq "!=" ) {
       # Check the actual value against the warning level
       if (($ACTVAL != $WARVAL) && ($WARVAL != 0)) {
          $error_detected="W";              # Save type of error encountered
          $value_exceeded=$WARVAL;          # Save the warning level value
       }
       # Check the actual value against the error level
       if (($ACTVAL != $ERRVAL) && ($ERRVAL != 0)) {
          $error_detected="E";              # Save type of error encountered
          $value_exceeded=$ERRVAL;          # Save the error level value
       }
   }

# If the test to perform involve "=" operator.
   if ($TEST eq "=" ) {
       # Check the actual value against the warning level
       if (($ACTVAL == $WARVAL) && ($WARVAL != 0)) {
          $error_detected="W";              # Save type of error encountered
          $value_exceeded=$WARVAL;          # Save the warning level value
       }
       # Check the actual value against the error level
       if (($ACTVAL == $ERRVAL) && ($ERRVAL != 0)) {
          $error_detected="E";              # Save type of error encountered
          $value_exceeded=$ERRVAL;          # Save the error level value
       }
   }

# If the test to perform involve "<" operator.
   if ($TEST eq "<" ) {
       # Check the actual value against the warning level
       if (($ACTVAL < $WARVAL) && ($WARVAL != 0)) {
          $error_detected="W";              # Save type of error encountered
          $value_exceeded=$WARVAL;          # Save the warning level value
       }
       # Check the actual value against the error level
       if (($ACTVAL < $ERRVAL) && ($ERRVAL != 0)) {
          $error_detected="E";              # Save type of error encountered
          $value_exceeded=$ERRVAL;          # Save the error level value
       }
   }

# If the test to perform involve ">" operator.
   if ($TEST eq ">" ) {
       # Check the actual value against the warning level
       if (($ACTVAL > $WARVAL) && ($WARVAL != 0)) {
          $error_detected="W";              # Save type of error encountered
          $value_exceeded=$WARVAL;          # Save the warning level value
       }
       # Check the actual value against the error level
       if (($ACTVAL > $ERRVAL) && ($ERRVAL != 0)) {
          $error_detected="E";              # Save type of error encountered
          $value_exceeded=$ERRVAL;          # Save the error level value
       }
   }



# If no Error was detected - Exit function
# --------------------------------------------------------------------------------------------------
   if ($error_detected eq "N") { return ; }                                   # Return to caller


# AIX or Linux Error Related portion
# --------------------------------------------------------------------------------------------------
   if (($MODULE eq "aix") || ($MODULE eq "linux")) {
           
      # FILESYSTEM ALERT OCCURED
      if (($SUBMODULE eq "FILESYSTEM") && ($MODULE eq "aix")) {                  # If error/warning on filesystem
         #$ERR_MESS = "FS $WID at $ACTVAL% full > $value_exceeded%" ;            # Set up Error Message
         $ERR_MESS = "FS $WID usage exceed $value_exceeded%" ;                   # Set up Error Message
         write_error_file($error_detected ,"$OSNAME", "FILESYSTEM", $ERR_MESS ); # Write error to rpt file
      }
      if (($SUBMODULE eq "FILESYSTEM") && ($MODULE eq "linux")) {                # If error/warning on filesystem
         ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();           # Get current epoch time
         if ($DEBUG >= 5) {                                                      # If Debug is ON
            print "\n\n----- Filesystem Increase: $WID at $ACTVAL%\n";           # FileSystem Entered
            print "The Actual Time is $year $month $day $hour $min $sec\n";      # Print current time
            print "The Actual epoch time is $epoch\n";                           # Print Epoch time
         }
         
         # If it is the first occurence of the Error - Put Date and Time in cfg
         if ( $SLAM_RECORD->{SLAM_DATE} == 0 ) {                                 # If current date = 0 in SLAM Array
            $SLAM_RECORD->{SLAM_DATE} = sprintf("%04d%02d%02d",$year,$month,$day);# Update SLAM_DATE=current date
            $SLAM_RECORD->{SLAM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);     # Update SLAM_Time=current time
         }
                  
         # Separate Date and Time ready to call get_epoch function
         $wyear  = sprintf "%04d",substr($SLAM_RECORD->{SLAM_DATE},0,4);            # Extract Year from SLAM_DATE
         $wmonth = sprintf "%02d",substr($SLAM_RECORD->{SLAM_DATE},4,2);            # Extract Month from SLAM_DATE
         $wday   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_DATE},6,2);            # Extract Day from SLAM_DATE
         $whrs   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_TIME},0,2);            # Extract Hour from SLAM_TIME
         $wmin   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_TIME},2,2);            # Extract Min from SLAM_TIME
           
         # Get Epoch Time of the last time we had a load exceeded
         $last_epoch = get_epoch("$wyear","$wmonth","$wday","$whrs","$wmin","0");   # Calc. Epoch of first filesystem increase
         if ($DEBUG >= 5) {                                                         # If DEBUG if ON
             print "Last series of filesystem increase started at $wyear $wmonth $wday $whrs $wmin 00\n"; 
             print "Elapsed time since last series of filesystem increase : $last_epoch\n"; 
         }

         # Calculate the number of seconds before since the first execution reset
         $elapse_second = $epoch - $last_epoch;                                     # Substract First Series epoch from curr. epoch
         if ($DEBUG >= 5) {                                                         # If DEBUG Activated
            print "So $epoch - $last_epoch = $elapse_second seconds\n";             # Print Elapsed seconds
         }
         # If number of second between the last increase and now is greater than 1 Day = OK RUN
         if ( $elapse_second >= $MINIMUM_SEC ) {                                    # If Elapsed Sec >= 1 Days (86400 Sec)          
            ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();           # Get current epoch time
            $SLAM_RECORD->{SLAM_DATE} = sprintf("%04d%02d%02d", $year,$month,$day); # Update SLAM_DATE=current date
            $SLAM_RECORD->{SLAM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);        # Update SLAM_Time=current time
            $SLAM_RECORD->{SLAM_MINUTES} = "001";                                   # Incr. Counter = First one Today
            if ($DEBUG >= 5) {                                                      # If DEBUG Activated
               print "Filesystem increase number $SLAM_RECORD->{SLAM_MINUTES} ";    # Print Nb of Incr.
            }
            filesystem_increase($WID);                                              # Go Increase Filesystem
         }else{
            #$SLAM_RECORD->{SLAM_MINUTES} ++ ;                                      # Increase filesystem counter 
            if (($SLAM_RECORD->{SLAM_MINUTES} + 1) > $INCREASE_PER_DAY) {           # If Counter exceed limit
               if ($DEBUG >= 5) {                                                   # If DEBUG Activated
                  print "Filesystem increase for $WID as been done $INCREASE_PER_DAY times within last 24 Hrs.";
                  print "\nFilesystem increase will not be done.";         # Inform user not done
               }
               #$ERR_MESS = "FS $WID at $ACTVAL% > $value_exceeded%" ;              # Set up Error Message
               $ERR_MESS = "FS $WID usage exceed $value_exceeded%" ;                # Set up Error Message
               write_error_file($error_detected ,"$OSNAME", "FILESYSTEM",$ERR_MESS);# Write error to rpt file
            }else{
               $WORK = $SLAM_RECORD->{SLAM_MINUTES} + 1;                            # Incr. FS Counter
               $SLAM_RECORD->{SLAM_MINUTES} = sprintf("%03d",$WORK);                # Insert Cnt in Array
               if ($DEBUG >= 5) {                                                   # If DEBUG Activated
                  print "Filesystem increase number $SLAM_RECORD->{SLAM_MINUTES} ";
               }
               filesystem_increase($WID);                                           # Go Increase Filesystem
            }
         }
      }
           
      
      # LOAD AVERAGE ALERT OCCURED
      if ($SUBMODULE eq "LOAD") {
         # Get Today Date, Time and Epoch Time
         ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();       
         if ($DEBUG >= 5) { 
            print "\nThe Actual Time is $year $month $day $hour $min $sec\n"; 
            print "The Actual epoch time is $epoch\n"; 
         }
                              
         # If it is the first occurence of the Error - Put Date and Time in cfg
         if ( $SLAM_RECORD->{SLAM_DATE} == 0 ) {
            $SLAM_RECORD->{SLAM_DATE} = sprintf ("%04d%02d%02d", $year,$month,$day);
            $SLAM_RECORD->{SLAM_TIME} = sprintf ("%02d%02d",$hour,$min,$sec); 
         }
                  
         # Separate Date and Time ready to call get_epoch function
         $wyear  = sprintf "%04d",substr($SLAM_RECORD->{SLAM_DATE},0,4);
         $wmonth = sprintf "%02d",substr($SLAM_RECORD->{SLAM_DATE},4,2);
         $wday   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_DATE},6,2);
         $whrs   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_TIME},0,2);
         $wmin   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_TIME},2,2);
           
         # Get Epoch Time of the last time we had a load exceeded
         $last_epoch = get_epoch("$wyear", "$wmonth", "$wday", "$whrs", "$wmin", "0");
         if ($DEBUG >= 5) { 
             print "The load on the cpu started at $wyear $wmonth $wday $whrs $wmin 00\n"; 
             print "The load started time in epoch time $last_epoch\n"; 
         }

         # Calculate the number of seconds before SLAM report the errors (Min * 60 sec)
         $elapse_second = $epoch - $last_epoch;
         $max_second = $SLAM_RECORD->{SLAM_MINUTES} * 60 ;
         if ($DEBUG >= 5) { 
            print "So $epoch - $last_epoch = $elapse_second seconds\n"; 
            print "You asked to wait $max_second seconds before report an error\n";
         }

         # If the number of second between the last error and now is greater than wanted - Issue error
         if ( $elapse_second >= $max_second ) {
            $ERR_MESS = "System Load Average is $WID and exceeding $value_exceeded for more than $SLAM_RECORD->{SLAM_MINUTES} Min.";
            write_error_file($error_detected ,"$OSNAME", "LOAD", $ERR_MESS );
            $SLAM_RECORD->{SLAM_DATE} = $SLAM_RECORD->{SLAM_TIME} = 0 ;
         }
      }
           
      # AIX HARDWARE ERROR ALERT           
      if ($SUBMODULE eq "ERRPT")    { 
         if ($ACTVAL == "2") { $error_detected="W"; }
         if ($ACTVAL == "3") { $error_detected="E"; }
         if ($DEBUG >= 5) { 
            print "\nActual Value = $ACTVAL";  
            print "  -  Error Type = $error_detected";  
         } 
         $ERR_MESS = "$WID" ; write_error_file($error_detected ,"AIX", "ERRPT", $ERR_MESS ); 
      }
           
      # HP HARDWARE ERROR ALERT     
      if ($SUBMODULE eq "HPLOG" ) {
         $error_detected="E"; 
         if ($DEBUG >= 5) { 
            print "\nActual Value = $ACTVAL";  
            print "  -  Error Type = $error_detected"; 
         }
         $ERR_MESS = "$WID" ; write_error_file($error_detected ,"LINUX", "HPLOG", $ERR_MESS ); 
      }
           
      # PAGING ALERT OCCURED     
      if ($SUBMODULE eq "PAGING")   { 
         #$ERR_MESS = "Paging space at $ACTVAL% > $value_exceeded%" ;
         $ERR_MESS = "Paging space usage exceed $value_exceeded Pct." ;
         write_error_file($error_detected ,"$OSNAME", "PAGING", $ERR_MESS );
      }
      
           
      # MULTIPATH ALERT OCCURED     
      if ($SUBMODULE eq "MULTIPATH")   { 
         $ERR_MESS = "MultiPath Error - Status is $WID" ;
         write_error_file($error_detected ,"$OSNAME", "MULTIPATH", $ERR_MESS );
      }
      

      # SCRIPT EXECUTION REQUEST WHEN ERROR OCCURED
      if ($SUBMODULE eq "SCRIPT")   { 
         $ERR_MESS = "$OSNAME - Script ${WID}.sh failed !" ;
         my $smess = "${WID}.txt";
         if ($DEBUG >= 5) { print "\nChecking presence of WasMonitor Status text file ${SLAMSCR_DIR}/$smess"; } 
         if ( -e "${SLAMSCR_DIR}/$smess" ) {
            if ($DEBUG >= 5) { print "\nContent of file ${SLAMSCR_DIR}/$smess used for error msg"; }
            open SMESSAGE, "${SLAMSCR_DIR}/$smess" or die $!;
            #open (SMESSAGE, "<$smess");
            while ($sline = <SMESSAGE>) { chomp $sline ; $ERR_MESS="$sline "; }
            close SMESSAGE;
         }
         write_error_file($error_detected ,"$OSNAME", "SCRIPT", $ERR_MESS );
      }
           
      # CPU ERROR OCCURED   
      if ($SUBMODULE eq "CPU") {
         # Get Today Date, Time and Epoch Time
         ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();
         if ($DEBUG >= 5) { 
            print "The Actual Time is $year $month $day $hour $min $sec\n";
            print "The Actual epoch time is $epoch";
         }

         # If it is the first occurence of the Error - Put Date and Time in cfg
         if ( $SLAM_RECORD->{SLAM_DATE} == 0 ) {
            $SLAM_RECORD->{SLAM_DATE} = sprintf ("%04d%02d%02d", $year,$month,$day);
            $SLAM_RECORD->{SLAM_TIME} = sprintf ("%02d%02d",$hour,$min,$sec);
         }

         # Separate Date and Time ready to call get_epoch function
         $wyear  = sprintf "%04d",substr($SLAM_RECORD->{SLAM_DATE},0,4);
         $wmonth = sprintf "%02d",substr($SLAM_RECORD->{SLAM_DATE},4,2);
         $wday   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_DATE},6,2);
         $whrs   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_TIME},0,2);
         $wmin   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_TIME},2,2);

         # Get Epoch Time of the last time we had a load exceeded
         $last_epoch = get_epoch("$wyear", "$wmonth", "$wday", "$whrs", "$wmin", "0");
         if ($DEBUG >= 5) { 
             print "\nThe load on the cpu started at $wyear $wmonth $wday $whrs $wmin 00";
             print "\nThe load started time in epoch time $last_epoch";
         }

         # Calculate the number of seconds before SLAM report the errors (Min * 60 sec)
         $elapse_second = $epoch - $last_epoch;
         $max_second = $SLAM_RECORD->{SLAM_MINUTES} * 60 ;
         if ($DEBUG >= 5) { 
            print "\nSo $epoch - $last_epoch = $elapse_second seconds";
            print "\nYou asked to wait $max_second seconds before report an error";
         }
              
         # If the number of second between the last error and now is greater than wanted - Issue error
         if ( $elapse_second >= $max_second ) {
            print "\nValue exceeded = $value_exceeded";
            print "\nActual Value   = $ACTVAL";
            print "\nMinutes        = $SLAM_RECORD->{SLAM_MINUTES}";
            $ERR_MESS = sprintf ("CPU at %-3d pct for more than %-3d min",$ACTVAL,$SLAM_RECORD->{SLAM_MINUTES}) ;
            write_error_file($error_detected ,"$OSNAME", "CPU", $ERR_MESS );
            $SLAM_RECORD->{SLAM_DATE} = $SLAM_RECORD->{SLAM_TIME} = 0 ;
         }
      }  # End of CPU SubModule
        }  # end of AIX/Linux Module  ==============================================================
             


   # Error detected for the Module name "MQSeries" 
   # --------------------------------------------------------------------------------------------------
   if ($MODULE eq "MQSERIES") {
      if ($SUBMODULE eq "SCRIPT") {
         $ERR_MESS = "MQSeries is down ($WID)";
         write_error_file($error_detected ,"MQSERIES", "SCRIPT", $ERR_MESS );
      }  
   }


   # Error detected for the Module name "NETWORK" 
   # --------------------------------------------------------------------------------------------------
   # Error detected for the Module name "Network"
   if ($MODULE eq "NETWORK")   { 
      if ($SUBMODULE eq "PING")   { 
         if ($DEBUG >= 5) { print "\nPing to server $WID Failed"; }
         $ERR_MESS = "Cannot ping server $WID - Server may be down" ;
         write_error_file($error_detected ,"NETWORK", "PING", $ERR_MESS );
      }
   }

    

   # Error detected for the Module name "WebSphere" 
   # --------------------------------------------------------------------------------------------------
   # Error detected for the Module name "WebSphere"
   if ($MODULE eq "WEBSPHERE")   { 
      $ERR_MESS = "WebSphere App. Server $WID is not running" ;
      write_error_file($error_detected ,"WEBSPHERE", "APP_SERVER", $ERR_MESS );
   }


   # Error detected for the Module name "IBM-HTTP" 
   # --------------------------------------------------------------------------------------------------
   if ($MODULE eq "HTTP")   { 
      $ERR_MESS = "HTTP Server for Application $WID is not running" ;
      write_error_file($error_detected ,"HTTP", "WEBSITE", $ERR_MESS );
   }


   # Error detected for the Module name "SUN-HTTP" 
   # --------------------------------------------------------------------------------------------------
   if ($MODULE eq "SUN-HTTP")   { 
      $ERR_MESS = "SUN HTTP Server for Application $WID is not running" ;
      write_error_file($error_detected ,"SUN-HTTP", "WEBSITE", $ERR_MESS );
   }

   # Error detected for the Module name CLUSTER
   # --------------------------------------------------------------------------------------------------
   if ($MODULE eq "CLUSTER")   {
      $ERR_MESS = "Linux Cluster Service $SUBMODULE status is $WID" ;
      write_error_file($error_detected ,"CLUSTER", "Service", $ERR_MESS );
   }

   # Error detected for the Module name "Autosys"
   # --------------------------------------------------------------------------------------------------
   if ($SUBMODULE eq "CCI") {
      $ERR_MESS = "Autosys cci connect to ZEKE is not ACTIVE ..." ;
      write_error_file($error_detected ,"AUTOSYS", "CCI", $ERR_MESS );
   }
    

   # Error detected for the Module DB2
   # --------------------------------------------------------------------------------------------------
   if ($MODULE eq "DB2") {
      if ($SUBMODULE eq "INSTANCE") {
         $ERR_MESS = "DB2 Instance $WID is down - DBA Should Check";
         write_error_file($error_detected ,"DB2", "INSTANCE", $ERR_MESS );
      }  
      if ($SUBMODULE eq "DATABASE") {
         $ERR_MESS = "DB2 Database $WID is down - DBA Should Check";
         write_error_file($error_detected ,"DB2", "DATABASE", $ERR_MESS );
      }  
   }
    

   # Error detected - A Daemon was suppose to be running and it is not
   # --------------------------------------------------------------------------------------------------
   if ($MODULE eq "DAEMON") {
      if ($SUBMODULE eq "PROCESS") {
         $ERR_MESS = "Daemon $WID not running !";
         write_error_file($error_detected ,"DAEMON", "PROCESS", $ERR_MESS );
      }  
   }
    

   # Error detected for the Module name "Oracle"
   # --------------------------------------------------------------------------------------------------
   if ($MODULE eq "ORACLE") {
      if ($SUBMODULE eq "INSTANCE") {
         $ERR_MESS = "Oracle instance $WID, " ;
         if ($error_detected eq "W") { $ERR_MESS .= "is not in archive mode" ;}
         if ($error_detected eq "E") { $ERR_MESS .= "is down !!" ; }
         write_error_file($error_detected ,"ORACLE", "INSTANCE", $ERR_MESS );
      }  
   }
        

   # Error detected for the Module name "ADSM"
   # --------------------------------------------------------------------------------------------------
   if ($MODULE eq "ADSM") {
      if ($SUBMODULE eq "RECOVLOG") {
         $ERR_MESS = sprintf "TSM Database log is %d pct full > %d ",  $ACTVAL,$value_exceeded ;
         write_error_file($error_detected ,"ADSM", "RECOVLOG", $ERR_MESS );
      }
      if ($SUBMODULE eq "SCRATCH") {
         #$ERR_MESS = "TSM scratch at $ACTVAL < $value_exceeded" ;
         $ERR_MESS = "Number of TSM scratch are less than $value_exceeded" ;
         write_error_file($error_detected ,"ADSM", "SCRATCH", $ERR_MESS );
      }  
      if ($SUBMODULE eq "STAGING") {
         $ERR_MESS = "TSM staging pool is $ACTVAL% full > $value_exceeded%" ;
         write_error_file($error_detected ,"ADSM", "STAGING", $ERR_MESS );
      }  
      if ($SUBMODULE eq "DATABASE") {
         #$ERR_MESS = "TSM Database is $ACTVAL% full > $value_exceeded%" ;
         $ERR_MESS = "TSM Database usage exceed $value_exceeded Pct." ;
         write_error_file ( $error_detected ,"ADSM", "DATABASE", $ERR_MESS );
      }
      if ($SUBMODULE eq "DRIVE") {
         $ERR_MESS = sprintf ("%d Drive(s) in TSM offline" ,$value_exceeded-$ACTVAL) ;
         write_error_file ( $error_detected ,"ADSM", "DRIVE", $ERR_MESS );
      }
      if ($SUBMODULE eq "PATH") {
         $ERR_MESS = sprintf ("%d Path(s) in TSM is offline" ,$value_exceeded-$ACTVAL) ;
         write_error_file ( $error_detected ,"ADSM", "PATH", $ERR_MESS );
      }
   }
   
}           # End of Function






# CHECK WEBSPHERE APPLICATIONS
# --------------------------------------------------------------------------------------------------
sub check_websphere {

# From the sysmon_array extract the application name
    @dummy = split (/_/, $SLAM_RECORD->{SLAM_ID},2) ;
    $ws_appname = $dummy[1];
    if ($DEBUG >= 5) { print "\n-----\nChecking WebSphere App. Server $ws_appname is running"};

# Grep for Application process in the PSFILE1 a first time
    open (WS_FILE,"grep 'application com.ibm.ws.bootstrap.WSLauncher com.ibm.ws.runtime.WsServer' $PSFILE1|grep -v grep | awk -F\" \" '{ print \$NF }'|sort|grep -i $ws_appname |wc -l |");
    $daemon1 = <WS_FILE> ;  chop $daemon1 ; $daemon1 = int $daemon1;
    close WS_FILE;

# Grep for Application process in the PSFILE2 a second time
    open (WS_FILE,"grep 'application com.ibm.ws.bootstrap.WSLauncher com.ibm.ws.runtime.WsServer' $PSFILE2|grep -v grep | awk -F\" \" '{ print \$NF }'|sort|grep -i $ws_appname |wc -l |");
    $daemon2 = <WS_FILE> ; chop $daemon2 ;  $daemon2 = int $daemon2;
    close WS_FILE;
    
# Retain only the largest number 
    if ( $daemon1 >= $daemon2 ) { $daemon = $daemon1 } else { $daemon = $daemon2 } ; 

# Put current value in slam array and check for error.
    $SLAM_RECORD->{SLAM_CURVAL} = $daemon ;
    if ($DEBUG >= 5) { printf "\nNumber of WebSphere App Server for %s running is %d",$ws_appname, $daemon };
    check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "WEBSPHERE","APP_SERVER",$ws_appname);

}



# CHECK IBM HTTP SERVER
# --------------------------------------------------------------------------------------------------
sub check_http {

# From the sysmon_array extract the application name
   @dummy = split /-/, $SLAM_RECORD->{SLAM_ID} ;
   $HTTP = $dummy[1];
   if ($DEBUG >= 5) { print "\n-----\nChecking http server instance $HTTP "};

# Grep for Application process in the PSFILE1
   open (WS_FILE, "$MATCH_HTTP $PSFILE1|grep -w $HTTP|wc -l|");
   $daemon1 = <WS_FILE> ;  chop $daemon1 ; $daemon1 = int $daemon1;
   close WS_FILE;

# Grep for Application process in the PSFILE2
   open (WS_FILE, "$MATCH_HTTP $PSFILE2|grep -w $HTTP|wc -l|");
   $daemon2 = <WS_FILE> ; chop $daemon2 ;  $daemon2 = int $daemon2;
   close WS_FILE;

# Retain only the largest number
   if ( $daemon1 >= $daemon2 ) { $daemon = $daemon1 } else { $daemon = $daemon2 } ;

# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = $daemon ;
   if ($DEBUG >= 5) { printf "\nThe number of HTTP server for %s running is %d",$HTTP, $daemon };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "HTTP","WEBSITE",$HTTP);
}



# CHECK SUN HTTP SERVER
# --------------------------------------------------------------------------------------------------
sub check_sun_http {

# From the sysmon_array extract the application name
    @dummy = split /_/, $SLAM_RECORD->{SLAM_ID} ;
    $HTTP = $dummy[1];
    if ($DEBUG >= 5) { print "\nChecking SUN / iPlanet http server instance $HTTP \n"};

# Grep for Application process in the PSFILE1
   open (WS_FILE, "$MATCH_SUN_HTTP $PSFILE1|grep -w $HTTP|wc -l|");
   $daemon1 = <WS_FILE> ;  chop $daemon1 ; $daemon1 = int $daemon1;
   close WS_FILE;

# Grep for Application process in the PSFILE2
   open (WS_FILE, "$MATCH_SUN_HTTP $PSFILE2|grep -w $HTTP|wc -l|");
   $daemon2 = <WS_FILE> ; chop $daemon2 ;  $daemon2 = int $daemon2;
   close WS_FILE;
    
# Retain only the largest number
   if ( $daemon1 >= $daemon2 ) { $daemon = $daemon1 } else { $daemon = $daemon2 } ; 

# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = $daemon ;
   if ($DEBUG >= 5) { printf "The number of SUN / iPlanet HTTP server for %s running is %d",$HTTP, $daemon };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "SUN-HTTP","WEBSITE",$HTTP);
}





# CHECK IF A PARTICULAR DAEMON IS RUNNING
# --------------------------------------------------------------------------------------------------
sub check_daemon {

# From the sysmon_array extract the daemon name
   @dummy = split /_/, $SLAM_RECORD->{SLAM_ID} ;
   $daemon_name = $dummy[1];
   if ($DEBUG >= 5) { print "\n-----\nChecking if daemon \"$daemon_name \" is running"};

#Grep for process in the PSFILE1
   open (DB_FILE, "grep \"$daemon_name\" $PSFILE1 | grep -v grep  | wc -l|");
   $daemon1 = <DB_FILE> ; 
   chop $daemon1 ;
   $daemon1 = int $daemon1;
   close DB_FILE;

# Grep for process in the PSFILE2
   open (DB_FILE, "grep \"$daemon_name\"  $PSFILE2 | grep -v grep | wc -l|");
   $daemon2 = <DB_FILE> ; 
   chop $daemon2 ;
   $daemon2 = int $daemon2;
   close DB_FILE;
    
# Retain only the largest number
   if ( $daemon1 >= $daemon2 ) { $daemon = $daemon1 } else { $daemon = $daemon2 } ; 

# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = $daemon ;
   if ($DEBUG >= 5) { printf "\nThe number of %s running is %d",$daemon_name, $daemon };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "DAEMON", "PROCESS", $daemon_name);
}







# RETURN DATE AND TIME OF THE DAY
# - EXAMPLE : ($CYEAR,$CMONTH,$CDAY,$CHOUR,$CMIN,$CSEC,$CEPOCH) = TODAY_AND_NOW();
# --------------------------------------------------------------------------------------------------
sub Today_and_Now {

   $curtime = Date::EzDate->new;
   $ctyear  = $curtime->{'year'}; 
   $ctmonth = $curtime->{'month number base 1'};
   $ctday   = $curtime->{'day of month'};
   $cthrs   = $curtime->{'hour'};
   $ctmin   = $curtime->{'min'};
   $ctsec   = $curtime->{'sec'};
   $ctepoch = $curtime->{'epoch second'};
   return ($ctyear,$ctmonth,$ctday,$cthrs,$ctmin,$ctsec,$ctepoch);
}

# FUNCTION YOU GIVE A DATE AND RETURN YOU THE EPOCH TIME
#  - EXAMPLE : $WEPOCH = GET_EPOCH($CYEAR,$CMONTH,$CDAY,$CHOUR,$CMIN,$CSEC);
# --------------------------------------------------------------------------------------------------
sub get_epoch {
   my ($eyear, $emonth, $eday, $ehrs, $emin, $esec) = @_;

   $etime = Date::EzDate->new;
   $etime->{'year'}                = "$eyear";
   $etime->{'month number base 1'} = "$emonth";
   $etime->{'day of month'}        = "$eday";
   $etime->{'hour'}                = "$ehrs";
   $etime->{'min'}                 = "$emin";
   $etime->{'sec'}                 = "$esec";
   $epoch_time                     = $etime->{'%s'};
   #if ($DEBUG >= 5) { print "$epoch_time = get_epoch($eyear $emonth $eday $ehrs $emin $esec)";} 
   return $epoch_time;
}







# CHECK AIX/NT TSM DATABASE PERCENTAGE USED 
# --------------------------------------------------------------------------------------------------
sub check_aix_tsm_db {

# Get ADSM Database Percentage Used 
   if ($DEBUG >= 5) { print "\n-----\nChecking Production TSM Database Percentage used" ;}
   open (DB_FILE, "$AIX_DSMADMC q db 2>/dev/null|tail -5 | head -1|");

   $db_pct = <DB_FILE> ; 
   if ($DEBUG >= 5) { print "\nThe Production TSM Database Data line is \n$db_pct"; };
   @ligne = split ' ',$db_pct;
   $db_pct = int $ligne[7];
   if ($DEBUG >= 6) { print "\nThe Production TSM Database percentage usage is $db_pct"; };
   close DB_FILE;

# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$db_pct ;
   if ($DEBUG >= 5) { printf "\nProduction Database percentage use is %d",$db_pct };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"ADSM","DATABASE",$db_pct);
}





# CHECK NOVELL/EXCHANGE TSM DATABASE PERCENTAGE USED
# --------------------------------------------------------------------------------------------------
sub check_novell_tsm_db {

# Get ADSM Database Percentage Used
   if ($DEBUG >= 5) { print "\n-----\nChecking Development TSM Database Percentage used" ;}
   open (DB_FILE, "$NOV_DSMADMC q db 2>/dev/null|tail -5 | head -1|");

   $db_pct = <DB_FILE> ;
   if ($DEBUG >= 5) { print "\nThe Development TSM Database Data line is \n$db_pct"; };
   @ligne = split ' ',$db_pct;
   $db_pct = int $ligne[7];
   if ($DEBUG >= 6) { print "\nThe Development TSM Database percentage usage is $db_pct"; };
   close DB_FILE;

# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$db_pct ;
   if ($DEBUG >= 5) { printf "\nDevelopment Database percentage use is %d",$db_pct };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"ADSM","DATABASE",$db_pct);
}






# CHECK HITACHI HDLM STATUS
# --------------------------------------------------------------------------------------------------
sub check_hdlm {
   if ( $OSNAME eq "linux" ) { return ; } 
   if ($DEBUG >= 5) { print "\n----\nChecking Hitachi HDLM"; }

# Get HDLM Status Will Return something like this
# dlnkmgr view -path -c
# Paths:000002 OnlinePaths:000002
# PathStatus   IO-Count    IO-Errors
# Online       10051468    0
## Combine the 2 schedules missed files

# Test if $HDLM_DLKMGR is running without Error
   if ($DEBUG >= 6) {
      $hdlm_error = system("$HDLM_DLKMGR view -path -c");
   }else{
      $hdlm_error = system("$HDLM_DLKMGR view -path -c >/dev/null 2>&1");
   }
   printf "\n$HDLM_DLKMGR view -path --- Return Code is $hdlm_error";
   if ( $hdlm_error != 0 ) {
      write_error_file ( "E"  ,"$OSNAME", "HITACHI", "HDLM Error - $HDLM_DLKMGR view -path -c");
      return ;
   }

# Get ouput of command and analyse it 
   open (HDLM, "$HDLM_DLKMGR view -path -c | ") or die "Can't execute $HDLM_DLKMGR view -path; $!\n";
   $WINDEX = 0 ;

while ($line = <HDLM>)
{
   $WINDEX ++;
   @ligne = split ' ',$line;


# Check the First Line  = (Paths:000002 OnlinePaths:000002)
   if ( $WINDEX == 1 ) {
      ($hdlm_path,$hdlm_online_path) = @ligne;
      ($dum1,$hdlm_path_defined) = split ':' , $hdlm_path;
      ($dum1,$hdlm_path_active)   = split ':' , $hdlm_online_path;
      if ($DEBUG >= 5) { print "\nChecking Path Active\nHDLM - Path Defined=$hdlm_path_defined  Path Active=$hdlm_path_active"; }
      if ( $hdlm_path_defined ne $hdlm_path_active ) {
         if ( $SLAM_RECORD->{SLAM_ERRVAL} > 0 ) {
            write_error_file ( "E"  ,"$OSNAME", "HITACHI", "HDLM Error - They are $hdlm_path_defined path defined and only $hdlm_path_active is active");
            close HDLM;
            return ;
         }else{
            if ( $SLAM_RECORD->{SLAM_WARVAL} > 0 ) {
               write_error_file ( "W"  ,"$OSNAME", "HITACHI", "HDLM Error - They are $hdlm_path_defined path defined and only $hdlm_path_active is active");
               close HDLM;
               return ;
            }
         }
      }
   }


# Check the third Line = (Online 10051468 0) = (State, I/O Count, I/O Errors)
   if ( $WINDEX == 3 ) {
      ($hdlm_state,$hdlm_count,$hdlm_errors) = @ligne; 
      if ($DEBUG >= 5) { print "\nChecking HLDM State\nHDLM - State=$hdlm_state  IO-Count=$hdlm_count  IO-Errors=$hdlm_errors"; }
         if ( $hdlm_state ne "Online" ) {
            if ( $SLAM_RECORD->{SLAM_ERRVAL} > 0 ) {
               write_error_file ( "E"  ,"$OSNAME", "HITACHI", "HDLM state is $hdlm_state - should be Online");
            }else{
               if ( $SLAM_RECORD->{SLAM_WARVAL} > 0 ) {
                  write_error_file ( "W"  ,"$OSNAME", "HITACHI", "HDLM statte is $hdlm_state should be Online");
               }
            }
         }else{
            write_error_file ( "H"  ,"$OSNAME", "HITACHI", "HDLM Path Healthy");
         }
      }    
   }
   close HDLM;
}




# CHECK LOAD AVERAGE
# --------------------------------------------------------------------------------------------------
sub check_load_average {
   if ($DEBUG >= 5) { print "\n-----\nEntering check_load_average\n"; }

# Get Load Average
   open (DB_FILE, "$CMD_UPTIME |");
   $load_line = <DB_FILE> ;
   @ligne = split ' ',$load_line;
   @dummy = split ',',$ligne[10];
   $load_average = int $dummy[0];
   if ($DEBUG >= 5) { printf "Uptime line  is $load_line"; }; 
   if ($DEBUG >= 5) { printf "Load Average in the last 5 minutes is $load_average"; }; 
   close DB_FILE;
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$load_average ;   # Put current value in slam array and check for error.
    
    
# If load average is less then warning value then reset to 0 Date & time of last exceeded value
   if ( $SLAM_RECORD->{SLAM_CURVAL} < $SLAM_RECORD->{SLAM_WARVAL} ) {
      $SLAM_RECORD->{SLAM_DATE} = $SLAM_RECORD->{SLAM_TIME} = 0 ;
   }
    
   if ($DEBUG >= 5) { 
      printf "\nLoad Average on $HOSTNAME is $load_average - W=$SLAM_RECORD->{SLAM_WARVAL} E=$SLAM_RECORD->{SLAM_ERRVAL}";
   }
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","LOAD",$load_average);
}





# CHECK CPU USAGE
# --------------------------------------------------------------------------------------------------
sub check_cpu_usage {

   if ($DEBUG >= 5) { print "\n-----\nEntering check_cpu_usage"; }

# Get CPU Usage
   open (DB_FILE, "$CMD_VMSTAT 1 2 | tail -1 |");
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


# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$cpu_total ;
    
# If CPU Usage is less then warning value then reset to 0 Date & time of last exceeded value
   if ( $SLAM_RECORD->{SLAM_CURVAL} < $SLAM_RECORD->{SLAM_WARVAL} ) {
       $SLAM_RECORD->{SLAM_DATE} = $SLAM_RECORD->{SLAM_TIME} = 0 ;
   }

# If CPU Usage is less then error value then reset to 0 Date & time of last exceeded value
   if ( $SLAM_RECORD->{SLAM_CURVAL} < $SLAM_RECORD->{SLAM_ERRVAL} ) {
       $SLAM_RECORD->{SLAM_DATE} = $SLAM_RECORD->{SLAM_TIME} = 0 ;
   }

# Print Information for debug mode
   if ($DEBUG >= 5) { 
      printf "CPU User=%3d System=%3d Total=$cpu_total",$cpu_user, $cpu_system, $cpu_total;
      printf "\nWarning Level=%3d  Error Level=%3d",$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL};
   }
   
# Check if value is normal  
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","CPU",$cpu_total);
}







# CHECK TSM DRIVE STATUS
# --------------------------------------------------------------------------------------------------
sub check_tsm_missed_schedule {

# Set TSM Missed checking flag to on
   $TSMMISSED_FLAG = 1 ;                   # Set to on when TSM Schedule are checked

# Get All schedule missed or failed
   if ( $DEBUG >= 5 ) { print "\n-----\nChecking Production instance for Missed Schedule\n" ;}
   if ( $DEBUG >= 6 ) { print "\n$AIX_DSMADMC -out=$TSMTMP1 -commadel \"q ev PRODUCTION * type=client EX=yes begint=now-16:00 endd=today\" 2>/dev/null";}
   system ("$AIX_DSMADMC -out=$TSMTMP1 -commadel \"q ev PRODUCTION * type=client EX=yes begint=now-18:00 endd=today\" 2>/dev/null");

   if ( $DEBUG >= 5 ) { print "\n------\nChecking Development instance for TSM Missed Schedule\n" ;}
   if ( $DEBUG >= 6 ) { print "\n$NOV_DSMADMC -out=$TSMTMP2 -commadel \"q ev * * type=client EX=yes begint=now-16:00 endd=today\" 2>/dev/null\n";}
   system ("$NOV_DSMADMC -out=$TSMTMP2 -commadel \"q ev * * type=client EX=yes begint=now-18:00 endd=today\" 2>/dev/null");

# Combine the 2 schedules missed files
   @args = ("cat $TSMTMP1 $TSMTMP2 > $TSMTMP");
   system(@args) ;

   open ( DB_FILE, "<  $TSMTMP") or die "Cannnot open $TSMTMP: $!\n";

# Remove And recreate The RC File in /var/adsmlog that is needed below - Make sure tey are empty
   unlink "$AIX_RCFILE" ;
   open ( AIXRC, ">$AIX_RCFILE" ) or die "Cannnot open $AIX_RCFILE: $!\n";
#
   unlink "$WIN_RCFILE" ;
   open ( WINRC, ">$WIN_RCFILE" ) or die "Cannnot open $WIN_RCFILE: $!\n";
#
   unlink "$DBA_RCFILE" ;
   open ( DBARC, ">$DBA_RCFILE" ) or die "Cannnot open $DBA_RCFILE: $!\n";

# Read the result file and process each line
   while ( $tsmline = <DB_FILE>)  {
      next if ( ( $tsmline !~ /Missed/ ) && ( $tsmline !~ /Failed/ )) ; 
      @ligne = split ',',$tsmline;
      #$event_start    = $ligne[0];
      ($event_date,$event_time) = split ' ',$ligne[0];
      $event_year     = substr($event_date,6,4);
      $event_month    = substr($event_date,3,2);
      $event_day      = substr($event_date,0,2);
      $event_schedule = $ligne[2];
      $event_schedule =~ tr/A-Z/a-z/;                # Make Sure name is in lowercase 
      $event_hostname = $ligne[3];
      $event_hostname =~ tr/A-Z/a-z/;                # Make Sure name is in lowercase 
      $event_status   = $ligne[4];
      chop $event_status;
      $host_prefix    = substr($event_hostname,0,2); # Get 2 first letter of hostname
      $host_prefix    =~ tr/A-Z/a-z/;                # Make Sure name is in lowercase 
      if ($DEBUG >= 5) { 
         print "\n\nEvent line is = @ligne" ;
         print "EventTime=$event_time EventName=$event_schedule EventHost=$event_hostname EventStatus=$event_status HostPrefix=$host_prefix";
      }


# Check if it is an Oracle - DB2 or SQL Backup (By the name of the schedule
      if ( ( $event_schedule =~ /ora/ ) || ( $event_schedule =~ /db2/ ) || ( $event_schedule =~ /sql/ ) || ( $event_schedule =~ /cold/ ) || ( $event_schedule =~ /hot/ ) || ( $event_schedule =~ /arc/ ) ) { 
         # Write line to error file
         printf DBARC   "%s;%s;%s;%s;%s;%s;%s;%s;%s\n","Error",$event_hostname,"$event_day/$event_month/$event_year",substr($event_time,0,5),"DBA","BACKUP","$event_status schedule $event_schedule","dba","dba";
         printf         "\n%s;%s;%s;%s;%s;%s;%s;%s;%s","Error",$event_hostname,"$event_day/$event_month/$event_year",substr($event_time,0,5),"DBA","BACKUP","$event_status schedule $event_schedule","dba","dba";
      }else{

# AIX Schedule Missed or Failed
         if (($host_prefix eq "sx") || ($host_prefix eq "sp") || ($host_prefix eq "px") ||  ($host_prefix eq "fv") || 
             ($host_prefix eq "lx") || ($host_prefix eq "dx") || ($host_prefix eq "fx") ||  ($host_prefix eq "f2") || ($host_prefix eq "la") ||
            ($event_hostname eq "wonhyo") ||($event_hostname eq "dsiem") || ($event_hostname eq "yulgok") || ($event_hostname eq "psiem")) {
            printf AIXRC "%s;%s;%s;%s;%s;%s;%s;%s;%s\n","Error",$event_hostname,"$event_day/$event_month/$event_year",substr($event_time,0,5),"TSM","BACKUP","$event_status schedule $event_schedule","aix","aix";
            printf       "\n%s;%s;%s;%s;%s;%s;%s;%s;%s","Error",$event_hostname,"$event_day/$event_month/$event_year",substr($event_time,0,5),"TSM","BACKUP","$event_status schedule $event_schedule","aix","aix";
         }else{
             
# Windows Schedule Missed or Failed
            if (($host_prefix eq "na") || ($host_prefix eq "nd") || ($host_prefix eq "ne") ||
               ($host_prefix eq "wd") || ($host_prefix eq "nt") || ($host_prefix eq "nm") || ($host_prefix eq "sw") ||
               ($event_hostname eq "ultraselectcal2") || ($event_hostname eq "dispatcher01") || ($event_hostname eq "volumetesting") ||
               ($event_hostname eq "ultraupx1") || ($event_hostname eq "vdmq1000") ) {
               printf WINRC "%s;%s;%s;%s;%s;%s;%s;%s;%s\n","Error",$event_hostname,"$event_day/$event_month/$event_year",substr($event_time,0,5),"TSM","BACKUP","$event_status schedule $event_schedule","win","win";
               printf       "\n%s;%s;%s;%s;%s;%s;%s;%s;%s","Error",$event_hostname,"$event_day/$event_month/$event_year",substr($event_time,0,5),"TSM","BACKUP","$event_status schedule $event_schedule","win","win";
            }
         }
      }
   } 
   close DB_FILE;
   close WINRC;
   close AIXRC;
   close AIXRC;
   close DBARC;
}



# CHECK TSM DRIVE STATUS
# --------------------------------------------------------------------------------------------------
sub check_tsm_drive {

   if ( $OSNAME eq "linux" ) { return 0; } 
   if ($DEBUG >= 5) { print "\n-----\nChecking TSM Tape drive status" ;}

# Get Drive Status
   open (DB_FILE, "$AIX_DSMADMC q dr|grep SL8500|");

# Read Query result and locate drive name & check status
   $drive_ok = 0;
   while ($dbline = <DB_FILE>) {
      @ligne = split ' ',$dbline;
      $drive_status = $ligne[3];
      #$drive_name = $ligne[1];
      if ($drive_status eq "Yes") { $drive_ok++ ; }
   }
   close DB_FILE;
   if ($DEBUG >= 5) { print "\nDrive ok = $drive_ok" ;}


# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$drive_ok ;
   if ($DEBUG >= 5) { printf "\nNumber of ADSM Drive Online is %d",$drive_ok };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"ADSM","DRIVE",$drive_ok);
}





# CHECK TSM DRIVE PATH STATUS
# --------------------------------------------------------------------------------------------------
sub check_tsm_path {

   if ( $OSNAME eq "linux" ) { return 0; } 
   if ($DEBUG >= 5) { print "\n-----\nChecking TSM Drive PATH Status" ;}

# Read Query result and locate drive name & check status of PATH
   open (DB_FILE, "$AIX_DSMADMC q path | grep DRIVE|");
   $path_ok = 0;
   while ($dbline = <DB_FILE>) {
      @ligne = split ' ',$dbline;
      $drive_status = $ligne[4];
      if ($drive_status eq "Yes") { $path_ok++ ; }
   }
   close DB_FILE;

# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$path_ok ;
   if ($DEBUG >= 5) { printf "\nNumber of ADSM Path Online is %d",$path_ok };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"ADSM","PATH",$path_ok);
}







# CHECK TSM FOR NUMBER OF SCRATCH 
# --------------------------------------------------------------------------------------------------
sub check_tsm_scratch {

   if ( $OSNAME eq "linux" ) { return 0; } 

# Query TSM Main Instance for Scratch using query libvolume instruction
   if ($DEBUG >= 5) { print "\n---\nChecking number of scratch in TSM" ;}
   open (DB_FILE, "$AIX_DSMADMC q libvol 2>/dev/null| grep \"Scratch\"| grep -E \"C6\" |wc -l|");
   if ($DEBUG >= 6) { print "\n$AIX_DSMADMC q libvol 2>/dev/null| grep \"Scratch\"| grep -E \"C6\" |wc -l|";}
   $db_scratch = <DB_FILE> ; 
   chop $db_scratch ;
   $db_scratch = int $db_scratch;
   close DB_FILE;

# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$db_scratch ;
   if ($DEBUG >= 5) { printf "\nTSM number of scratch is %d",$db_scratch  };
    
# Go check if under minimum
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "ADSM", "SCRATCH",$db_scratch);
}




# CHECK AIX TSM DATABASE LOG USAGE
# --------------------------------------------------------------------------------------------------
sub check_aix_tsm_log {

   if ( $OSNAME eq "linux" ) { return 0; } 
   if ($DEBUG >= 5) { print "\n-----\nChecking Production Database Log Usage" ;}

# Get ADSM Database Percentage Used 
   open (DB_FILE, "$AIX_DSMADMC q log 2>/dev/null|tail -4 | head -1|");
   $db_pct = <DB_FILE> ; 
   if ($DEBUG >= 5) { print "\nThe Production TSM Database Log line is \n $db_pct"; };
   @ligne = split ' ',$db_pct;
   $db_pct = int $ligne[7];
   close DB_FILE;

# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$db_pct ;
   if ($DEBUG >= 5) { printf "\nProduction Database Log percentage use is %d",$db_pct };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "ADSM", "RECOVLOG",$db_pct);
}




# CHECK NOVELL TSM DATABASE LOG USAGE
# --------------------------------------------------------------------------------------------------
sub check_novell_tsm_log {

   if ( $OSNAME eq "linux" ) { return 0; }
   if ($DEBUG >= 5) { print "\n-----\nChecking Development Database Log Usage" ;}

# Get ADSM Database Percentage Used
   open (DB_FILE, "$NOV_DSMADMC q log 2>/dev/null|tail -4 | head -1|");
   $db_pct = <DB_FILE> ;
   if ($DEBUG >= 5) { print "\nThe Development TSM Database Log line is \n$db_pct"; };
   @ligne = split ' ',$db_pct;
   $db_pct = int $ligne[7];
   close DB_FILE;

# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$db_pct ;
   if ($DEBUG >= 5) { printf "\nDevelopment TSM Database Log percentage use is %d",$db_pct };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "ADSM", "RECOVLOG",$db_pct);
}








# PAGING SPACE CHECKING
# --------------------------------------------------------------------------------------------------
sub check_swap_space  {

# Get Paging space information.
   if ($DEBUG >= 5) { print "\n-----\n$OSNAME - Paging/Swap" ;}

# ON Linux
   if ( $OSNAME eq "linux" ) { 
      # Linux will return line similar to this "Swap: 2097136 0 20971" 
      open (DF_FILE,"free | grep -i swap |");
      $total_size = $total_use = 0;
      while ($paging = <DF_FILE>) {
         @pline = split ' ', $paging;
         $paging_size = $pline[1] ;
         $paging_use  = $pline[2] ;
         if ($DEBUG >= 5) { 
            print "check_swap_space : Paging size is $paging_size and using $paging_use \n";
         }
      }
      close DF_FILE;
      if ($paging_use == 0) { $paging_pct = 0 };
      if ($paging_use != 0) { $paging_pct = int (($paging_use / $paging_size) * 100) } ;
      $total_size = $paging_size;
      $total_use = $paging_use;
   # ON AIX
   }else{
      # AIX Will return a line similar to this "512MB  2%"
      open (DF_FILE, "/usr/sbin/lsps -s | tail -1 |");
      $total_size = $total_use = 0; 
      while ($paging = <DF_FILE>) {
         @pline = split ' ', $paging;
         if ($DEBUG >= 5) { print "Paging line used is @pline\n"; }
         $paging_size = $pline[0] ;
         $paging_size =~ s/MB//;
         $paging_use  = $pline[1] ;
         $paging_use  =~ s/%//;
         $total_size += $paging_size;
         $total_use += $paging_use;
      }
      close DF_FILE;
      $paging_pct = $paging_use ; 
   }


# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$paging_pct ;
   if ($DEBUG >= 5) { print "check_swap_space : Total size $total_size MB Pct= $paging_pct %"; }
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "$OSNAME", "PAGING",$paging_pct);
}






# CHECK LINUX HPLOG
# --------------------------------------------------------------------------------------------------
sub check_hplog {
   if ( $OSNAME ne "linux" ) { return 0; }                              # Run only on HP Server
   if ( $VM eq "Y" ) { return 0; }                                      # Do not run if under VM
   if ($DEBUG >= 5) { print "\n-----\nChecking Linux hplog";};          # Print Debugging Info
   my @data=`hplog -v | grep -Eiv \'Count|^--|^\$\'`;

   #Example of hplog -v
   #0000 Critical       22:17  11/25/2010 22:17  11/25/2010 0001
   #LOG: ASR Detected by System ROM
   #0001 Repaired       22:21  11/25/2010 22:21  11/25/2010 0001
   #LOG: Network Adapter Link Down (Slot 0, Port 1)
   #
   # hplog -v | grep -Eiv 'Count|^--|^\$'
   # hplog: The IML Log is empty.


    my $data_line="";
    my $line_count=-1;
    my ( $message, $index, $severity, $itime, $idate, $utime, $udate, $count ) = "";

   foreach $data_line (@data) {
      chomp ($data_line);
      next if ( $data_line =~ /^\s*$/ );
      $line_count++;
      my ($first_field, $hp_message) = split (':', $data_line );
      if ($DEBUG >= 5) { print "\nDataLine = $data_line - First_Field = $first_field"; }
      if ($first_field eq "LOG")  {
         print "\n$hp_message\n";
         $data_string = "$itime $severity $hp_message";
         if (( "$severity" eq "Critical" ) || ( "$severity" eq "Caution" ))  {
            $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%02d" ,2;
         }else{
            $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%02d" ,0;
         }
         check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","HPLOG","$data_string" );
      }else{
         ($index,$severity,$itime,$idate,$utime,$udate,$count ) = split ( /\s+/, $data_line );
         print "\n$index, $severity, $itime, $idate, $utime, $udate, $count";
         $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%02d" ,0;
         check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","HPLOG","$data_string" );
      }
   }
}





# CHECK AIX ERROR REPORT 
# --------------------------------------------------------------------------------------------------
sub check_errpt {

# Only available on AIX - Skip for Linux
   if ( $OSNAME eq "linux" ) { return 0; }
   if ($DEBUG >= 5) { print "\n\-----\nChecking Aix Error Report";};

# Build the Yesterday Date
   my $mydate = Date::EzDate->new;         # mydate = current date now
   $mydate = $mydate - 1;              # mydate = yesterday Date & time now
   $START_DATE = $mydate->{'%m%d%H%M%y'};
   print "\nError Report Start Date is $START_DATE";


# Run the error report command 
   if ($DEBUG >= 5) { print "\n/bin/errpt -d H -T TEMP,PERM -s $START_DATE \n";};
   open (ERRPT_FILE, "/bin/errpt -d H -T TEMP,PERM -s $START_DATE | grep -v \"IDENTIFIER\" | ");
   $SLAM_RECORD->{SLAM_CURVAL} = 01;

# Read each host respond line and react if status = 0 (host_respond is down)
   my $NUMBER_OF_ERRORS = 0 ;
   while ($wline = <ERRPT_FILE>)
      {
      @pline = split ' ', $wline;
      #$err_date  = "$pline[1]" ;
      $err_type   = "$pline[2]" ;
      #$err_mm    = substr($pline[1],0,2) ;
      #$err_dd    = substr($pline[1],2,2) ;
      $err_hh     = substr($pline[1],4,2) ;
      $err_min    = substr($pline[1],6,2) ;
      $err_msg    = substr($wline,41,40) ;
      $err_desc   = "$err_hh:$err_min $err_type $pline[4] $err_msg" ;
      chomp ($err_desc) ;
      if ( "$err_desc" =~ "rmt" ) {$err_type = "T";}
      if ($DEBUG >= 5) { print "\nCheck_errpt : $wline";};
      if ($DEBUG >= 5) { print "Error Type  : $err_type";};
      if ($err_type eq "T") {
         $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%02d" ,2;
         $NUMBER_OF_ERRORS++ ; 
         check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","ERRPT","$err_desc" );
      }else{
         $NUMBER_OF_ERRORS++ ; 
         $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%02d" ,3;
         check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","ERRPT","$err_desc" );
      }
   }
   if ( $NUMBER_OF_ERRORS == 0 ) {
      $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%02d" ,1;
      check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","ERRPT","Healthy" );
   }    
   close ERRPT_FILE ;
}






# CHECK FILESYSTEM USAGE - CURRENT RESULT OF COMMAND "DF"  WAS PLACE IN ARRAY %DF_ARRAY.
# NOW WE TRY TO FIND A MATCH BETWEEN %DF ARRAY AND THE HOSTNAME.CFG FILE WITCH IS IN ARRAY 
# --------------------------------------------------------------------------------------------------
sub check_filesystems_usage  {
   if ($DEBUG >= 5) { print "\n-----\nChecking Filesystem Usage";};     # Print Debugging Info
   #$SLAM_RECORD->{SLAM_SCRIPT} = "scom-fs-inc.sh";                     # Make sure autoincr is there
   
# Try to locate the filesystem in SLAM Array 
   foreach $key (keys %df_array) {
      if ($key eq $SLAM_RECORD->{SLAM_ID}) {
         @dummy = split /_/, $key ;
         $fname = substr ($key,2,length($key)-1);
         $fpct  = $df_array{$key};
         # Put current value in slam array and check for error.
         $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d",$fpct; 
         if ($DEBUG >= 5) {
            print "\nFilesystem $fname at $SLAM_RECORD->{SLAM_CURVAL} % - Warning at $SLAM_RECORD->{SLAM_WARVAL} % - Error at $SLAM_RECORD->{SLAM_ERRVAL} %";
         }
         check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "$OSNAME" , "FILESYSTEM", $fname);
         last; 
      }
   }
}


# GET NUMBER OF "ORA_" PROCESS FOR THE ORACLE INSTANCE SPECIFY IN $SLAM_RECORD->{SLAM_ID} 
# --------------------------------------------------------------------------------------------------
sub get_number_of_oracle_process  {

# From the sysmon_array extract the instance name
   @dummy = split /_/, $SLAM_RECORD->{SLAM_ID} ;
   $winstance = $dummy[2];


# Run ps command To count the number of process used the instance.
   open (ORA_COUNT, "grep \"ora_\" $PSFILE1 | grep -v grep | grep $winstance | wc -l|");
   $nb_instance = <ORA_COUNT> ; 
   chop $nb_instance ;
   $nb_instance = int $nb_instance;
   close ORA_COUNT;
#
   if ($DEBUG >= 5) { printf "\nThe number of Oracle process for the instance %s is %d",$winstance,$nb_instance };
   return $nb_instance;
}


# Ping the server specified
# --------------------------------------------------------------------------------------------------
sub ping_ip  {

# Extract Name or IP from ID
   @dummy = split /_/, $SLAM_RECORD->{SLAM_ID} ;
   $ipname = $dummy[1];
   if ($DEBUG >= 5) { print "\n\-----\nTest ping to server $ipname";};
   $PCMD = "ping -c2 $ipname >/dev/null 2>&1" ;
   print "\nThe command that will be executed is $PCMD";
   @args = ("$PCMD");
   system(@args) ;
   $src = $? >> 8;
   $SLAM_RECORD->{SLAM_CURVAL}=$src;
   if ($DEBUG >= 5) { print "\nReturn code is $SLAM_RECORD->{SLAM_CURVAL}" ;}
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"NETWORK","PING",$ipname);
   return 
}


# CHECK /ETC/DB2TAB AND LAUNCH DB_TEST_CONNECT_MASTER.SH
# --------------------------------------------------------------------------------------------------
sub check_db2tab  {

# If /etc/db2tab does not exist = nothing to do here
   if ( ! -e "$DB2TAB"  ) { return;  }

# Write Slam RC file all Database with 1 in the last column
   open (DB2TAB, "grep -i :Y:1 $DB2TAB | ");
   while ($db2line = <DB2TAB>) {
      chomp $db2line ; 
      @dline = split ':', $db2line;
      if ($DEBUG >= 5) { print "DB2line is @dline\n"; }
      $DB2INST   = $dline[0];
      $DB2DB     = $dline[1];
      write_error_file("E" ,"DB2 Database", "DB2 DB Avail.", "DB2 Database $DB2DB on instance $DB2INST unreachable.");
      if ( $DEBUG >=5) { print ("\nE" ,"Database", "DB2 DB Avail.", "DB2 Database $DB2DB on instance $DB2INST unreachable.\n");}
   } 
   close DB2TAB;

# Check if db2perf is defined in /etc/passwd 
   open (PASSWD, "grep -i db2perf /etc/passwd | wc -l | ");
   $db2perf_count = <PASSWD> ;
   chop $db2perf_count ;
   $nb_db2perf_count = int $db2perf_count;
   close PASSWD;
   if ($nb_db2perf_count < 1 ) { 
      print "User db2perf MUST be created in order to execute $SLAMSCR_DBA\n";
      @args = ("echo \"User db2perf MUST be created on $HOSTNAME for SLAM to check DB2 Database\" | mail -s SLAM_NEED_DB2PERF dba_production.it\@standardlife.ca");
      $src = system(@args) ; 
   }

# CAll DBA Script
   if ( $DEBUG >=5) { print "\n-----\nExecution of script $SLAMSCR_DBA is requested\n";}
   @args = ("echo \"su - db2perf \'-c $SLAMSCR_DBA \' >>$SLAMSCR_DBA.log 2>&1\" | at now");
   $src = system(@args) ; 
   if ( $DEBUG >=5) { print "\nExecution of script $SLAMSCR_DBA - Return Code is $src";}
}






# CHECK DB2 INSTANCE
# --------------------------------------------------------------------------------------------------
sub check_db2_instance  {

# Get the name of the db2 Owner instance to check
   if ($DEBUG >= 5) { print "\n" ;}
   @dummy = split /_/, $SLAM_RECORD->{SLAM_ID} ;
   $winstance   = $dummy[1];
   $db2_daemon  = $dummy[2];

# Check if Database if Y in /etc/db2tab - If set to N bypass verification
   open (DB2TAB, "grep -v \"^#\" $DB2TAB | grep $winstance | awk -F: '{print $3}'");
   chomp ($db_active = <DB2TAB>);
   close DB2TAB;
   if (($db_active eq "N") || ($db_active eq "n")) { return 0 ; }

# Run ps command To count the number of process used the instance.
   open (DB2_COUNT, "grep \"${winstance}\" $PSFILE1 | grep -v grep | grep $db2_daemon | wc -l|");
   $nb_instance = <DB2_COUNT> ;
   chop $nb_instance ;
   $nb_instance = int $nb_instance;
   close DB2_COUNT;
   if ($DEBUG >= 5) { print "The number of DB2 process for the owner $winstance and process $db2_daemon is $nb_instance\n" };
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" , $nb_instance ;

# From the number of process detected, call the function to check if an error is to be signaled
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"DB2","INSTANCE","${winstance}");
}





# CHECK ORACLE INSTANCE 
# --------------------------------------------------------------------------------------------------
sub check_oracle_instance  {

   if ($DO_NOT_MONITOR_ORACLE == 1) {
      print "\n-----\nNo longer Monitoring Oracle Instance on this server";
      return 0;
   }
   
# Get the name of the Oracle instance to check
   if ($DEBUG >= 5) { print "\n" ;}
   @dummy = split /_/, $SLAM_RECORD->{SLAM_ID} ;
   $winstance = $dummy[2];

# Check if Database if Y in /etc/oratab - If set to N bypass verification
   open (ORATAB, "grep -v \"^#\" /etc/oratab | grep $winstance | awk -F: '{print $3}'");
   chomp ($db_active = <ORATAB>);
   close ORATAB;
   if (($db_active eq "N") || ($db_active eq "n")) { return 0 ; }


# Get the number of "ora_" process are running gor this instance
   $number = get_number_of_oracle_process;
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" , $number ;

# Get all Backup log files and isolate line with return code 1 or 2
   while (glob("$ADSMLOG_DIR/rc\.$HOSTNAME\.*$winstance*.log")) {
         system ("tail -1 $_ >> $SADM_BASE_DIR/tmp/$winstance.$$");
   }


# Check the ADSM log file to see if a database backup is running
   if ( -e "$SADM_BASE_DIR/tmp/$winstance.$$"  ) {
      open (ADSMLOG, "cat $SADM_BASE_DIR/tmp/$winstance.$$ |") or die "Cannnot open $SADM_BASE_DIR/tmp/$winstance.$$: $!\n";
      while ($adsmlog_line = <ADSMLOG>) {
         chomp $adsmlog_line ;
         @dummy = split ' ' , $adsmlog_line ;
         $backup_status = $dummy[5];
         if ($DEBUG >= 5) { print "\nStatus = $backup_status - AdsmLog line: $adsmlog_line";}
         if ($backup_status == 2) { 
             $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" , 99 ;
             if ($DEBUG >= 5) {
               print "Number of Oracle process for $winstance is set 99 while backup is running\n";
             }
         }
      }
      close ADSMLOG;
      unlink "$SADM_BASE_DIR/tmp/$winstance.$$" ;
   }else{
      write_error_file("W" ,"DBA", "NOBACKUP", "$winstance is not backup - No $ADSMLOG_DIR/rc\.$HOSTNAME\.*$winstance*.log");
   }

# From the number of process detected, call the function to check if an error is to be signaled
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"ORACLE","INSTANCE",$winstance);
}





# THIS FUNCTION IS CALL WHEN A SCRIPT EXECUTION IS REQUESTED
# --------------------------------------------------------------------------------------------------
sub run_script {

   ($dummy,$sname) = split /:/, $SLAM_RECORD->{SLAM_ID} ;               # Extract Full script name
   (my $sfile_name, my $dirName, my $sfile_extension) = fileparse($sname, ('\.sh') );
   #(my $sfile_name, my $sfile_extension) = split /./, $sname ;          # Split name & extension
   $sname = "${SLAMSCR_DIR}/${sname}";
   if ( $DEBUG >=5) { print "\n-----\nExecution of script $sname is requested";}
   if ( $DEBUG >=5) { print "\nFilename is $sfile_name - Extension is $sfile_extension";}
   
   # If no script specified - return to caller
   if ((length $sname == 0 ) || ($sname eq "-")) {                      # no script specified Error
      print "Script $sname is not specified ??" ;                       # Inform user no script specified
      $SLAM_RECORD->{SLAM_CURVAL}=1;                                    # Set actual value to 1
      #check_for_error($src,$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","SCRIPT",$sname);
      check_for_error($src,$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","SCRIPT",$sfile_name);
      return;                                                           # return to caller
   }      

   # Make sure script Exist and is executable - if not return to caller
   if (( -e "$sname" ) && ( ! -x "$sname")) {                           # Script !exist or !executable
      print "\nScript $sname exist, but not executable";                # Inform user of error
      $SLAM_RECORD->{SLAM_CURVAL}=1;                                    # Set Actual Value to 1
      check_for_error($src,$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","SCRIPT",$sfile_name);
      return;                                                           # return to caller
   }

# Create an empty file when no error are reported
   ($script_name, $dirName, $sfile_extension) = fileparse($sname, ('\.sh') );
   $SCOM_APP_FILE = "$SCOM_APP_DIR" . "/" . "$script_name" . ".txt" ;
   if ($DEBUG >= 5) { printf "\nCreate an empty file name $SCOM_APP_FILE";} # Print Empty filename
   unlink "$SCOM_APP_FILE" ;  
   open OUT, ">$SCOM_APP_FILE";
   close OUT;
#   
   @args = ("$sname >> ${sname}.log 2>&1");                             # Command to execute
   system(@args) ;                                                      # Execute the Script
   $src = $? >> 8;                                                      # Return code from script


# Put current value in slam array.
   if ($DEBUG >= 5) { printf "\nScript $sname return code is $src";}    # Print Return Code
   $SLAM_RECORD->{SLAM_CURVAL}=$src;                                    # Actual Value=Return Code
   check_for_error($src,$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"$OSNAME","SCRIPT",$sfile_name);
}






# Check if MQSeries is running - Run the script mqcheck
# --------------------------------------------------------------------------------------------------
sub check_mqseries  {
my $script = " " ;

# Get the name of the script to execute
   if ($DEBUG >= 5) { print "\n" ;}
   @dummy = split /_/, $SLAM_RECORD->{SLAM_ID} ;
   $script = $dummy[1];


# Call the script that check MQSeries Status - The script executed, echo 0 or 1  (1=not running)
# I did not tranpose the script in Perl cause script are different from prod. to dev. machine
   if ( $OSNAME eq "linux" ) {
      $return_code = system ("$SADM_BASE_DIR/linux/mqcheck");
   }else{
      $return_code = system ("$script");
   }
    

# Make sure that return code is 0 or 1 only
   if ( $return_code != 0) { $return_code = 1;}

# Put current value in slam array and check for error.
   $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%d" ,$return_code ;
   if ($DEBUG >= 5) { printf "The result code returned for MQSeries is %d\n",$return_code };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST},"MQSERIES","SCRIPT",$script);
   return $return_code;
}








# CHECK FOR NEW FILESYSTEM - IF THEY ARE NOT IN sysmon_array THEN INSERT THEM 
# --------------------------------------------------------------------------------------------------
sub check_for_new_filesystems  {

   if ($DEBUG >= 5) { print "\n-----\nChecking for new filesystems." };

   # First Get Actual Filesystem Info
   # Don't check cdrom (/dev/cd0) and NFS Filesystem (:) 
   if ($OSNAME eq "linux" ) {
      open (DF_FILE, "/bin/df -hP | grep \"^\/\" | grep -v \"\/mnt\/\"| grep -v \"cdrom\"| grep -v \":\" |");
   }else{
      open (DF_FILE, "/bin/df | grep \"^\/\" | grep -v \"\/dev\/cd0\"| grep -v \"\/dev\/cd1\"| grep -v \"cdrom\"| grep -v \":\" |");
   }

   # Then Compare Actual value versus Warning & Error Value.
   while ($filesys = <DF_FILE>) {
      # Get Filesystem Name and Percentage Full
      @sysline = split ' ', $filesys;
      if ($OSNAME eq "linux" ) {
         $fname = $sysline[5];
      }else{
         $fname = $sysline[6];
      }

      # Try to locate the filesystem in SLAM Array 
      $found="N";
      for ($index = 0; $index < @sysmon_array; $index++) {     
         next if ($sysmon_array[$index] !~ /^FS/ && ($sysmon_array[$index] !~ /^aix_fs/ )) ;
         split_fields($sysmon_array[$index]);
         if (($SLAM_RECORD->{SLAM_ID} eq "FS" . "$fname") || ($SLAM_RECORD->{SLAM_ID} eq "aix_fs_$fname")){
            $found="Y";
            last;
         }
      }

      # If filesystem not in sysmon_array then Insert new filesystem in slam.array
      if ($found eq "N" ) {
         $SLAM_RECORD->{SLAM_ID} = "FS" . "$fname" ;
         $SLAM_RECORD->{SLAM_CURVAL} = "00" ;
         $SLAM_RECORD->{SLAM_TEST} = ">=";
         $SLAM_RECORD->{SLAM_WARVAL} = "85" ;
         $SLAM_RECORD->{SLAM_ERRVAL} = "95";
         if ($OSNAME eq "linux" ) { $SLAM_RECORD->{SLAM_WARVAL} = "85" ; } 
         if ($OSNAME eq "linux" ) { $SLAM_RECORD->{SLAM_ERRVAL} = "95" ; } 
         $SLAM_RECORD->{SLAM_MINUTES} = "000";
         $SLAM_RECORD->{SLAM_STHRS} = "0000" ;
         $SLAM_RECORD->{SLAM_ENDHRS} = "0000";
         $SLAM_RECORD->{SLAM_SUN} = "Y";
         $SLAM_RECORD->{SLAM_MON} = "Y";
         $SLAM_RECORD->{SLAM_TUE} = "Y";
         $SLAM_RECORD->{SLAM_WED} = "Y";
         $SLAM_RECORD->{SLAM_THU} = "Y" ;
         $SLAM_RECORD->{SLAM_FRI} = "Y";
         $SLAM_RECORD->{SLAM_SAT} = "Y" ;
         $SLAM_RECORD->{SLAM_ACTIVE} = "Y";
         $SLAM_RECORD->{SLAM_DATE} = "00000000";
         $SLAM_RECORD->{SLAM_TIME} = "0000";
         $SLAM_RECORD->{SLAM_QPAGE} = "aix"; 
         if ( "$fname" =~ "arc" ) {$SLAM_RECORD->{SLAM_QPAGE} = "dba";}
         if ( "$fname" =~ "ora" ) {$SLAM_RECORD->{SLAM_QPAGE} = "dba";}
         if ( "$fname" =~ "exp" ) {$SLAM_RECORD->{SLAM_QPAGE} = "dba";}
         if ( "$fname" =~ "dmp" ) {$SLAM_RECORD->{SLAM_QPAGE} = "dba";}
         if ( "$fname" =~ "db2" ) {$SLAM_RECORD->{SLAM_EMAIL} = "dba";}
         if ( "$fname" =~ "dbf" ) {$SLAM_RECORD->{SLAM_QPAGE} = "dba";}
         $SLAM_RECORD->{SLAM_EMAIL} = "aix";
         if ( "$fname" =~ "db2" ) {$SLAM_RECORD->{SLAM_EMAIL} = "dba";}
         if ( "$fname" =~ "arc" ) {$SLAM_RECORD->{SLAM_EMAIL} = "dba";}
         if ( "$fname" =~ "ora" ) {$SLAM_RECORD->{SLAM_EMAIL} = "dba";}
         if ( "$fname" =~ "exp" ) {$SLAM_RECORD->{SLAM_EMAIL} = "dba";}
         if ( "$fname" =~ "dmp" ) {$SLAM_RECORD->{SLAM_EMAIL} = "dba";}
         if ( "$fname" =~ "dbf" ) {$SLAM_RECORD->{SLAM_EMAIL} = "dba";}
         $SLAM_RECORD->{SLAM_SCRIPT} = "scom-fs-inc.sh";

         if ($DEBUG >= 5) { print "New filesystem Found - $fname\n";}
         $index=@sysmon_array;
         $sysmon_array[$index] = combine_fields() ;
         }
   }
   close DF_FILE;
}





# ISSUE A DF COMMAND AND LOAD THE RESULT IN AN ARRAY CALLED @DF_ARRAY.
# --------------------------------------------------------------------------------------------------
sub load_df_in_array {


# First Get Actual Filesystem Info
   if ($DEBUG >= 6) { print "\nPutting result of \"df\" command in memory." };
   if ($OSNAME eq "linux" ) {
      open (DF_FILE, "/bin/df -hP | grep \"^\/\" | grep -v \"\/dev\/cd0\"| grep -v \"\/dev\/cd1\"| grep -v \"cdrom\"| grep -v \":\" |");
   }else{
      open (DF_FILE, "/bin/df | grep \"^\/\" | grep -v \"\/dev\/cd0\"| grep -v \"\/dev\/cd1\"| grep -v \"cdrom\"| grep -v \":\" |");
   }


# Read everyline of the df result and store name & percentage use
   while ($filesys = <DF_FILE>) {
      # Get Filesystem Name and Percentage Full
      @sysline = split ' ', $filesys;
      if ($OSNAME eq "linux" ) {
         $fname = "FS" . "$sysline[5]";
         $fpct =  substr ($sysline[4],0,length($sysline[4])-1);
      }else{
         $fname = "FS" . "$sysline[6]" ;
         $fpct =  substr ($sysline[3],0,length($sysline[3])-1);
      }
      if ($DEBUG >= 6) { print "Filesystem $fname is currently at $fpct\n" ;}
      $df_array{"$fname"} = $fpct;
   }
   close DF_FILE;

# Debug info
   if ($DEBUG >= 6) { 
      foreach $key (keys %df_array) {
         print "load_df_in_array : Key=$key Value=$df_array{$key}\n";
      }
   }
}






# CHECK IF NEW DB2 DATABASE DAEMON DB2LOGGR - IF NOT IN SLAM CONFIG FILE, THEN INSERT IT
# --------------------------------------------------------------------------------------------------
sub check_for_new_db2_database {

   if ($DEBUG >= 5) { print "\nChecking for new db2 DataBase." };

# Get List of db2loggr process
   open (DB2DB, "grep \"db2loggr\" $PSFILE1 | ");

# Process all db2loggr process found
   while ( $oline = <DB2DB> ) {
      if ($DEBUG >= 5) { print "\nPrint $oline\n" };

      # Get Instance Name
      @oarray = split '\(', $oline;
      $db = $oarray[1];
      @oarray = split '\)', $db;
      $db = $oarray[0];
      chomp $db;
      $db = substr ($db,0,length($db));
      print "Check if DB2 DataBase $db is a new one\n" ;

      # Try to locate the instance in slam array
      $found="N";
      for ($index = 0; $index < @sysmon_array; $index++) {
         next if $sysmon_array[$index] !~ /^db2db_${db}_db2loggr/ ;
         $found="Y";
         last;
      }

      # Not found then Insert new instance in slam array
      if ($found eq "N" ) {
         print "New DB2 Database Found - $db\n";
         $SLAM_RECORD->{SLAM_ID}      = "db2db_${db}_db2loggr" ;
         $SLAM_RECORD->{SLAM_CURVAL}  = "---" ;
         $SLAM_RECORD->{SLAM_TEST}    = "<";
         $SLAM_RECORD->{SLAM_WARVAL}  = "00";
         $SLAM_RECORD->{SLAM_ERRVAL}  = "01" ;
         $SLAM_RECORD->{SLAM_MINUTES} = "000";
         $SLAM_RECORD->{SLAM_STHRS}   = "0000" ;
         $SLAM_RECORD->{SLAM_ENDHRS}  = "0000";
         $SLAM_RECORD->{SLAM_SUN}     = "Y";
         $SLAM_RECORD->{SLAM_MON}     = "Y";
         $SLAM_RECORD->{SLAM_TUE}     = "Y";
         $SLAM_RECORD->{SLAM_WED}     = "Y";
         $SLAM_RECORD->{SLAM_THU}     = "Y" ;
         $SLAM_RECORD->{SLAM_FRI}     = "Y";
         $SLAM_RECORD->{SLAM_SAT}     = "Y" ;
         $SLAM_RECORD->{SLAM_ACTIVE}  = "Y";
         $SLAM_RECORD->{SLAM_DATE}    = "00000000" ;
         $SLAM_RECORD->{SLAM_TIME}    = "0000";
         $SLAM_RECORD->{SLAM_QPAGE}   = "dba ";
         $SLAM_RECORD->{SLAM_EMAIL}   = "dba ";
         $SLAM_RECORD->{SLAM_SCRIPT}  = "-";
         $index=@sysmon_array;
         $sysmon_array[$index] = combine_fields() ;
      }
   }
   close DB2FILE;
}





# CHECK IF ALL INSTANCE OF DB2 ARE IN SLAM ARRAY - IF NOT INSERT IT
# --------------------------------------------------------------------------------------------------
sub check_for_new_db2_instance {

   if ($DEBUG >= 5) { print "\n-----\nChecking for new db2 instance." };

# Get owner of every db2sysc running
   open (DB2FILE, "grep \"db2sysc\" $PSFILE1 | grep -v grep | ");


# Read Owner (Instance name) of every db2sysc running
   while ($oline = <DB2FILE>) {

      # Get Instance Name
      if ($DEBUG >= 5) { print "\nPrint $oline\n" };
      @oarray = split ' ', $oline;
      $instance = $oarray[0];
      chomp $instance;
      $instance = substr ($instance,0,length($instance));
      print "Check if DB2 $instance is a new one\n" ;

      # Try to locate the instance in slam array
      $found="N";
      for ($index = 0; $index < @sysmon_array; $index++) {
         next if $sysmon_array[$index] !~ /^db2i_${instance}_db2sysc/ ;
         $found="Y";
         last;
      }

      # Not found then Insert new instance in slam array
      if ($found eq "N" ) {
         print "New DB2 Instance Found - $instance\n";
         $SLAM_RECORD->{SLAM_ID}      = "db2i_${instance}_db2sysc" ;
         $SLAM_RECORD->{SLAM_CURVAL}  = "---" ;
         $SLAM_RECORD->{SLAM_TEST}    = "<";
         $SLAM_RECORD->{SLAM_WARVAL}  = "00";
         $SLAM_RECORD->{SLAM_ERRVAL}  = "01" ; 
         $SLAM_RECORD->{SLAM_MINUTES} = "000";
         $SLAM_RECORD->{SLAM_STHRS}   = "0000" ;
         $SLAM_RECORD->{SLAM_ENDHRS}  = "0000";
         $SLAM_RECORD->{SLAM_SUN}     = "Y";
         $SLAM_RECORD->{SLAM_MON}     = "Y";
         $SLAM_RECORD->{SLAM_TUE}     = "Y";
         $SLAM_RECORD->{SLAM_WED}     = "Y";
         $SLAM_RECORD->{SLAM_THU}     = "Y" ;
         $SLAM_RECORD->{SLAM_FRI}     = "Y";
         $SLAM_RECORD->{SLAM_SAT}     = "Y" ;
         $SLAM_RECORD->{SLAM_ACTIVE}  = "Y";
         $SLAM_RECORD->{SLAM_DATE}    = "00000000" ;
         $SLAM_RECORD->{SLAM_TIME}    = "0000";
         $SLAM_RECORD->{SLAM_QPAGE}   = "dba ";
         $SLAM_RECORD->{SLAM_EMAIL}   = "dba ";
         $SLAM_RECORD->{SLAM_SCRIPT}  = "-";
         $index=@sysmon_array;
         $sysmon_array[$index] = combine_fields() ;
      }
   }
   close DB2FILE;
}






# CHECK IF ALL INSTANCE ARE IN SLAM ARRAY IF NOT INSERT IT
# --------------------------------------------------------------------------------------------------
sub check_for_new_oracle_instance {

   if ($DO_NOT_MONITOR_ORACLE == 1) {
      print "\n-----\nNo longer checking for new Oracle Instance on this server";
      return 0;
   }
   if ($DEBUG >= 5) { print "\n-----\nChecking for new oracle instance." };

# First Get Actual Filesystem Info
   open (DF_FILE, "grep \"ora_pmon\" $PSFILE1 | grep -v grep |");



# Read everyline where ora_bwr in running
   while ($oline = <DF_FILE>) {

      # Get Instance Name 
      @oarray = split '_', $oline;
      $instance = $oarray[2];
      chomp $instance;
      if ( $OSNAME eq "linux" ) { $instance = substr ($instance,0,length($instance)); } 
      if ( $OSNAME ne "linux" ) { $instance = substr ($instance,0,length($instance)-1); } 
      if ($DEBUG >= 5) { print "\nCheck if $instance is a new one" };

      # Try to locate the instance in slam array
      $found="N";
      for ($index = 0; $index < @sysmon_array; $index++) {     
         next if $sysmon_array[$index] !~ /^oracle_instance_${instance}/ ;
         $found="Y";
         last;
      }

      # Not found then Insert new instance in slam array
      if ($found eq "N" ) {
         if ($DEBUG >= 5) { print "\nNew Instance Found $instance"};
         $SLAM_RECORD->{SLAM_ID} = "oracle_instance_$instance" ;
         $SLAM_RECORD->{SLAM_CURVAL} = "---" ;
         $SLAM_RECORD->{SLAM_TEST} = "<";
         $SLAM_RECORD->{SLAM_WARVAL} = sprintf "%02d", get_number_of_oracle_process;
         $SLAM_RECORD->{SLAM_ERRVAL} = sprintf "%02d", $SLAM_RECORD->{SLAM_WARVAL} - 1; 
         $SLAM_RECORD->{SLAM_MINUTES} = "000";
         $SLAM_RECORD->{SLAM_STHRS} = "0000" ;
         $SLAM_RECORD->{SLAM_ENDHRS} = "0000";
         $SLAM_RECORD->{SLAM_SUN} = "Y";
         $SLAM_RECORD->{SLAM_MON} = "Y";
         $SLAM_RECORD->{SLAM_TUE} = "Y";
         $SLAM_RECORD->{SLAM_WED} = "Y";
         $SLAM_RECORD->{SLAM_THU} = "Y" ;
         $SLAM_RECORD->{SLAM_FRI} = "Y";
         $SLAM_RECORD->{SLAM_SAT} = "Y" ;
         $SLAM_RECORD->{SLAM_ACTIVE} = "Y";
         $SLAM_RECORD->{SLAM_DATE} = "00000000" ;
         $SLAM_RECORD->{SLAM_TIME} = "0000"; 
         $SLAM_RECORD->{SLAM_QPAGE} = "dba"; 
         $SLAM_RECORD->{SLAM_EMAIL} = "dba";
         $SLAM_RECORD->{SLAM_SCRIPT} = "-";
         $index=@sysmon_array;
         $sysmon_array[$index] = combine_fields() ;
      }
   }
   close DF_FILE;
}




# CHECK IF ALL WEBSPHERE APPLICATION SERVER ARE IN SLAM ARRAY IF NOT INSERT IT
# --------------------------------------------------------------------------------------------------
sub check_for_new_websphere_appserver {

   if ($DEBUG >= 5) { print "\n-----\nChecking for new WebSphere app. server." };

# Build Listing of WebSphere Application Running
   if ( $OSNAME eq "linux" ) {
      open (WEB_FILE,"grep 'application com.ibm.ws.bootstrap.WSLauncher com.ibm.ws.runtime.WsServer' $PSFILE1|grep -v grep| awk -F\" \" '{ print \$NF }'|sort|uniq|");
   }else{
      open (WEB_FILE,"grep 'application com.ibm.ws.bootstrap.WSLauncher com.ibm.ws.runtime.WsServer' $PSFILE1|grep -v grep| awk -F\" \" '{ print \$NF }'|sort|uniq|");
   }


# Read evry WebPshere Application name that are running
   while ($oline = <WEB_FILE>) {
      # Get WebSphere Application Name
      $webapp = $oline;
      chomp $webapp;
      if ($DEBUG >= 5) { print "\nCheck if $webapp WebSphere App. is a new one" };
      # Try to locate the Web Sphere Application in slam array
      $found="N";
      for ($index = 0; $index < @sysmon_array; $index++) {     
         next if $sysmon_array[$index] !~ /^websphere_${webapp} / ;
         $found="Y";
         last;
      }

# Not found then Insert new instance in slam array
      if ($found eq "N" ) {
         if ($DEBUG >= 5) { print "\nNew WebSphere App. Found $webapp"};
         @args = ("grep -i 'application com.ibm.ws.bootstrap.WSLauncher com.ibm.ws.runtime.WsServer' $PSFILE1 | mail -s NEW_WEBSPHERE_APP-${webapp} jack.duplessis\@standardlife.ca");
         system(@args) ;
         $SLAM_RECORD->{SLAM_ID} = "websphere_$webapp" ;
         $SLAM_RECORD->{SLAM_CURVAL} = "---" ;
         $SLAM_RECORD->{SLAM_TEST} = "< ";
         $SLAM_RECORD->{SLAM_WARVAL} = "000"; 
         $SLAM_RECORD->{SLAM_ERRVAL} = "001";
         $SLAM_RECORD->{SLAM_MINUTES} = "000";
         $SLAM_RECORD->{SLAM_STHRS} = "0500" ;
         $SLAM_RECORD->{SLAM_ENDHRS} = "0355";
         $SLAM_RECORD->{SLAM_SUN} = "Y";
         $SLAM_RECORD->{SLAM_MON} = "Y";
         $SLAM_RECORD->{SLAM_TUE} = "Y";
         $SLAM_RECORD->{SLAM_WED} = "Y";
         $SLAM_RECORD->{SLAM_THU} = "Y";
         $SLAM_RECORD->{SLAM_FRI} = "Y";
         $SLAM_RECORD->{SLAM_SAT} = "Y" ;
         $SLAM_RECORD->{SLAM_ACTIVE} = "Y";
         $SLAM_RECORD->{SLAM_DATE} = "00000000" ;
         $SLAM_RECORD->{SLAM_TIME} = "0000"; 
         $SLAM_RECORD->{SLAM_QPAGE} = "web"; 
         $SLAM_RECORD->{SLAM_EMAIL} = "web";
         $SLAM_RECORD->{SLAM_SCRIPT} = "-";
         $index=@sysmon_array;
         $sysmon_array[$index] = combine_fields() ;
      }
   }
   close WEB_FILE;
}





# CHECK IF ALL WAS HTTP WEB SITE ARE IN SLAM CURRENT ARRAY
# --------------------------------------------------------------------------------------------------
sub check_for_new_cluster_services {
   if ($DEBUG >= 5) { print "\n-----\nChecking for new cluster services" };
   print "\nWe are in a Cluster ($CLUSTER)";
   if ($CLUSTER eq "N") { return ; }

    
# First list of cluster services
   open (CLUSERV, "$CLUSTAT | grep service: | cut -d' ' -f2 | cut -d: -f2 |");

# Read the result one line at a time.
   while ($cline = <CLUSERV>) {
      $SERVICE = $cline;       # Get Service name
      chomp $SERVICE;
      $found="N";
      for ($index = 0; $index < @sysmon_array; $index++) {     
         next if $sysmon_array[$index] !~ /^cserv-${SERVICE}/ ;
         if ($DEBUG >= 5) { print "\n- Service cserv-$SERVICE already there"};
         $found="Y";
         last;
      }

      # Not found then Insert new instance in slam array
      if ($found eq "N" ) {
         if ($DEBUG >= 5) { print "New cluster service found ($SERVICE)\n"};
         $SLAM_RECORD->{SLAM_ID} = "cserv-${SERVICE}" ;
         $SLAM_RECORD->{SLAM_CURVAL} = "---" ;
         $SLAM_RECORD->{SLAM_TEST} = "< ";
         $SLAM_RECORD->{SLAM_WARVAL} = "000"; 
         $SLAM_RECORD->{SLAM_ERRVAL} = "001";
         $SLAM_RECORD->{SLAM_MINUTES} = "000";
         $SLAM_RECORD->{SLAM_STHRS} = "0000" ;
         $SLAM_RECORD->{SLAM_ENDHRS} = "0000";
         $SLAM_RECORD->{SLAM_SUN} = "Y";
         $SLAM_RECORD->{SLAM_MON} = "Y";
         $SLAM_RECORD->{SLAM_TUE} = "Y";
         $SLAM_RECORD->{SLAM_WED} = "Y";
         $SLAM_RECORD->{SLAM_THU} = "Y" ;
         $SLAM_RECORD->{SLAM_FRI} = "Y";
         $SLAM_RECORD->{SLAM_SAT} = "Y" ;
         $SLAM_RECORD->{SLAM_ACTIVE} = "Y";
         $SLAM_RECORD->{SLAM_DATE} = "00000000" ;
         $SLAM_RECORD->{SLAM_TIME} = "0000"; 
         $SLAM_RECORD->{SLAM_QPAGE} = "aix"; 
         $SLAM_RECORD->{SLAM_EMAIL} = "aix";
         $SLAM_RECORD->{SLAM_SCRIPT} = "-";
         $index=@sysmon_array;
         $sysmon_array[$index] = combine_fields() ;
      }
   }
   close CLUSERV;
}




# CHECK IF ALL HTTP WEB SITE ARE IN SLAM CURRENT ARRAY
# --------------------------------------------------------------------------------------------------
sub check_for_new_http_site {

   if ($DEBUG >= 5) { print "\n-----\nChecking for new HTTP Web sites." };

# First Get HTTP Server
   open (WEB_FILE, "$MATCH_HTTP $PSFILE1|sort|uniq|");

# Read everyline that match
   while ($oline = <WEB_FILE>) {

      # Get WebSphere Application Name
      $HTTP = $oline;
      chomp $HTTP;
      if ($DEBUG >= 5) { print "\nCheck if HTTP for $HTTP is a new one" };

      # Try to locate the HTPP in slam array
      $found="N";
      for ($index = 0; $index < @sysmon_array; $index++) {     
         next if $sysmon_array[$index] !~ /^http-${HTTP}/ ;
         $found="Y";
         last;
      }

      # Not found then Insert new instance in slam array
      if ($found eq "N" ) {
         if ($DEBUG >= 5) { print "\nNew HTTP Instance Found $HTTP"};
         $SLAM_RECORD->{SLAM_ID} = "http-$HTTP" ;
         $SLAM_RECORD->{SLAM_CURVAL} = "---" ;
         $SLAM_RECORD->{SLAM_TEST} = "< ";
         $SLAM_RECORD->{SLAM_WARVAL} = "000"; 
         $SLAM_RECORD->{SLAM_ERRVAL} = "001";
         $SLAM_RECORD->{SLAM_MINUTES} = "000";
         $SLAM_RECORD->{SLAM_STHRS} = "0500" ;
         $SLAM_RECORD->{SLAM_ENDHRS} = "0355";
         $SLAM_RECORD->{SLAM_SUN} = "Y";
         $SLAM_RECORD->{SLAM_MON} = "Y";
         $SLAM_RECORD->{SLAM_TUE} = "Y";
         $SLAM_RECORD->{SLAM_WED} = "Y";
         $SLAM_RECORD->{SLAM_THU} = "Y" ;
         $SLAM_RECORD->{SLAM_FRI} = "Y";
         $SLAM_RECORD->{SLAM_SAT} = "Y" ;
         $SLAM_RECORD->{SLAM_ACTIVE} = "Y";
         $SLAM_RECORD->{SLAM_DATE} = "00000000" ;
         $SLAM_RECORD->{SLAM_TIME} = "0000"; 
         $SLAM_RECORD->{SLAM_QPAGE} = "web"; 
         $SLAM_RECORD->{SLAM_EMAIL} = "web";
         $SLAM_RECORD->{SLAM_SCRIPT} = "-";
         $index=@sysmon_array;
         $sysmon_array[$index] = combine_fields() ;
      }
   }
   close WEB_FILE;
}




# CHECK IF ALL SUN HTTP WEB SITE ARE IN SLAM CURRENT ARRAY
# --------------------------------------------------------------------------------------------------
sub check_for_new_sun_http_site {

   if ($DEBUG >= 5) { print "\n-----\nChecking for new SUN / iPlanet HTTP Web sites." };

   # First Get HTTP Server
   open (WEB_FILE, "$MATCH_SUN_HTTP $PSFILE1|sort|uniq|");

# Read everyline that match
   while ($oline = <WEB_FILE>) {

# Get WebSphere Application Name
      $HTTP = $oline;
      chomp $HTTP;
      if ($DEBUG >= 5) { print "\nCheck if SUN / iPlanet HTTP for $HTTP is a new one" };

# Try to locate the HTPP in slam array
      $found="N";
      for ($index = 0; $index < @sysmon_array; $index++) {     
         next if $sysmon_array[$index] !~ /^sun-http_${HTTP}/ ;
         $found="Y";
         last;
      }

# Not found then Insert new instance in slam array
      if ($found eq "N" ) {
         if ($DEBUG >= 5) { print "\nNew SUN / iPlanet HTTP Instance Found $HTTP"};
         $SLAM_RECORD->{SLAM_ID} = "sun-http_$HTTP" ;
         $SLAM_RECORD->{SLAM_CURVAL} = "---" ;
         $SLAM_RECORD->{SLAM_TEST} = "< ";
         $SLAM_RECORD->{SLAM_WARVAL} = "000"; 
         $SLAM_RECORD->{SLAM_ERRVAL} = "001";
         $SLAM_RECORD->{SLAM_MINUTES} = "000";
         $SLAM_RECORD->{SLAM_STHRS} = "0500" ;
         $SLAM_RECORD->{SLAM_ENDHRS} = "0355";
         $SLAM_RECORD->{SLAM_SUN} = "Y";
         $SLAM_RECORD->{SLAM_MON} = "Y";
         $SLAM_RECORD->{SLAM_TUE} = "Y";
         $SLAM_RECORD->{SLAM_WED} = "Y";
         $SLAM_RECORD->{SLAM_THU} = "Y" ;
         $SLAM_RECORD->{SLAM_FRI} = "Y";
         $SLAM_RECORD->{SLAM_SAT} = "Y" ;
         $SLAM_RECORD->{SLAM_ACTIVE} = "Y";
         $SLAM_RECORD->{SLAM_DATE} = "00000000" ;
         $SLAM_RECORD->{SLAM_TIME} = "0000"; 
         $SLAM_RECORD->{SLAM_QPAGE} = "web"; 
         $SLAM_RECORD->{SLAM_EMAIL} = "web";
         $SLAM_RECORD->{SLAM_SCRIPT} = "-";
         $index=@sysmon_array;
         $sysmon_array[$index] = combine_fields() ;
      }
   }
   close WEB_FILE;
}





# CHECK CLUSTER SERVICES STATE
# --------------------------------------------------------------------------------------------------
sub check_cluster_services {
   # From the sysmon_array extract the service name
   @dummy = split /-/, $SLAM_RECORD->{SLAM_ID} ;
   $SERVICE_NAME = $dummy[1];
   if ($DEBUG >= 5) { print "\n-----\nChecking Cluster Service ${SERVICE_NAME}"};

   open (CLUSERV,"$CLUSTAT |grep -i $SERVICE_NAME | awk '{ print \$3 }' |");
   while ($xline = <CLUSERV>) {
      chomp $xline;
      $SERVICE_STATUS = $xline;                        
      if ($SERVICE_STATUS eq "started") {
         $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%02d" ,1; 
      }else{
         $SLAM_RECORD->{SLAM_CURVAL} = sprintf "%02d" ,0;
      }
   }
   close CLUSERV;
   if ($DEBUG >= 5) { printf "\nThe Cluster Status for service %s is %s (%d)",$SERVICE_NAME, $SERVICE_STATUS, $SLAM_RECORD->{SLAM_CURVAL} };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "CLUSTER",$SERVICE_NAME,$SERVICE_STATUS);
}




# CHECK MULTIPATH STATE 
#  --------------------------------------------------------------------------------------------------
# echo 'show paths' | multipathd -k | grep -vi multipath
#   0:0:0:0 sda 8:0   1   [active][ready] XX........ 4/20
#   0:0:0:1 sdb 8:16  1   [active][ready] XX........ 4/20
#   1:0:0:0 sdc 8:32  1   [active][ready] XXXX...... 8/20
#   1:0:0:1 sdd 8:48  1   [active][ready] XXXX...... 8/20
#  --------------------------------------------------------------------------------------------------
sub check_multipath {
   if ( $OSNAME eq "aix" ) { return ; } 
   if ($DEBUG >= 5) { print "\n----\nChecking Linux Multipath"; }

   # Get ouput of command and analyse it 
   open (FPATH, "echo 'show paths' | $CMD_MULTIPATHD -k | grep -vEi 'cciss|multipath' | ") or die "Can't execute $CMD_MULTIPATHD \n";
   $WINDEX = 0 ;
   $SLAM_RECORD->{SLAM_CURVAL} = 1 ; 
   
   while ($line = <FPATH>)
   {
      $WINDEX ++;
      @ligne = split ' ',$line;
      ($mhcli,$mdev,$mmajor,$mdummy1,$mstatus,$mdumm2,$mdummy3) = @ligne;
      print "\nMultipath Status = $mstatus";
      if ($mstatus ne "[active][ready]")
         {
         $SLAM_RECORD->{SLAM_CURVAL} = 0;
         print "Multipath Error Detected" ; 
         }
   }
   close FPATH ;
   if ($DEBUG >= 5) { printf "\nThe Multipath status is %s - Code is (%d) (1=ok 0=Error)",$mstatus, $SLAM_RECORD->{SLAM_CURVAL} };
   check_for_error($SLAM_RECORD->{SLAM_CURVAL},$SLAM_RECORD->{SLAM_WARVAL},$SLAM_RECORD->{SLAM_ERRVAL},$SLAM_RECORD->{SLAM_TEST}, "linux","MULTIPATH",$mstatus);
}





# CREATE & WRITE TO SCOM TXT REPORT FILE
# --------------------------------------------------------------------------------------------------
sub write_scom_file {
# Save variables received as parameter
   my ($SC_STATUS,$SC_MODULE,$SC_SUBMODULE,$SC_MESS) = @_;
   if ($DEBUG >= 5) {                                                   # If Debug is ON
      print "\nSC_STATUS = $SC_STATUS - SC_MODULE = $SC_MODULE - SC_SUBMODULE = $SC_SUBMODULE";
      print "\nSC_MESS = $SC_MESS";
   }
      
   if ( ${SC_STATUS} eq ${HEALTHY} ) { return ; };                         # Don't write when healthy
   
# Construct Error Message in bracket
   my $SCOM_MESS1 = "";    
   my $SCOM_MESS2 = "[$SC_MESS]";    
   my $SCOM_MESS  = "";    

# Make sure SCOM first part is unique and meaningfull
   my $WORK_ID    = $SLAM_RECORD->{SLAM_ID};
   $WORK_ID       =~ s/\//_/g ;                                             # Replace / with underscore
   $WORK_ID       =~ s/aix_database/prod_database/ ;
   $WORK_ID       =~ s/nov_database/dev_database/ ;
   $WORK_ID       =~ s/script:// ;

# If Error is for Web Team
   if (($SLAM_RECORD->{SLAM_QPAGE} =~ /web/ ) || ($SLAM_RECORD->{SLAM_QPAGE} =~ /was/ )) {
      $SCOM_MESS1 = "${HOSTNAME}_was_$WORK_ID = ${SC_STATUS} ";            # Std SCOM Line
      $SCOM_MESS  = "${SCOM_MESS1}${SCOM_MESS2}";                          # Combine 2 Part messages
      if ($DEBUG >= 5) { print ("\nAdding $SCOM_MESS to $SCOM_WAS_FILE");} # Print file content to screen
      print (SCOM_WAS "${SCOM_MESS}\n");                                   # Write line to SCOM file
      return
   }

# If Error is for DBA Team
   if ($SLAM_RECORD->{SLAM_QPAGE} =~ /dba/ ) {
      if ($WORK_ID eq "NOBACKUP") {                                        # Schedule missing Backup
         $SCOM_MESS1 = "${HOSTNAME}_dba_backup_$WORK_ID = ${SC_STATUS}";   # Add backup to ID 
         $SCOM_MESS2="[No Backup Scheduled for $WORK_ID]";                 # Special Backup Msg
      }else{                                                               # If not a missing schedule
         $SCOM_MESS1 = "${HOSTNAME}_dba_$WORK_ID = ${SC_STATUS} ";         # Std SCOM Line
      }
      $SCOM_MESS  = "${SCOM_MESS1}${SCOM_MESS2}";                          # Combine 2 Part messages
      if ($DEBUG >= 5) { print ("\nAdding $SCOM_MESS to $SCOM_DBA_FILE");} # Print file content to screen
      print (SCOM_DBA "${SCOM_MESS}\n");                                   # Write line to SCOM file
      return
   }

# If Error is for MVS Team
   if ($SLAM_RECORD->{SLAM_QPAGE} =~ /mvs/ ) {
      $SCOM_MESS1 = "${HOSTNAME}_mvs_$WORK_ID = ${SC_STATUS} ";            # Std SCOM Line
      $SCOM_MESS  = "${SCOM_MESS1}${SCOM_MESS2}";                          # Combine 2 Part messages
      if ($DEBUG >= 5) { print ("\nAdding $SCOM_MESS to $SCOM_MVS_FILE");} # Print file content to screen
      print (SCOM_MVS "${SCOM_MESS}\n");                                   # Write line to SCOM file
      return
   }

# If Error is for Production Analyst Team
   if ($SLAM_RECORD->{SLAM_QPAGE} =~ /pa/ ) {
      $SCOM_MESS1 = "${HOSTNAME}_pa_$WORK_ID = ${SC_STATUS} ";             # Std SCOM Line
      $SCOM_MESS  = "${SCOM_MESS1}${SCOM_MESS2}";                          # Combine 3 Part messages
      if ($DEBUG >= 5) { print ("\nAdding $SCOM_MESS to $SCOM_PA_FILE");}  # Print file content to screen
      print (SCOM_PA "${SCOM_MESS}\n");                                    # Write line to SCOM file
      return
   }

# If Error is for FTP Team
   if ($SLAM_RECORD->{SLAM_QPAGE} =~ /ftp/ ) {
      $SCOM_MESS1 = "${HOSTNAME}_ftp_$WORK_ID = ${SC_STATUS} ";             # Std SCOM Line
      $SCOM_MESS  = "${SCOM_MESS1}${SCOM_MESS2}";                          # Combine 3 Part messages
      if ($DEBUG >= 5) { print ("\nAdding $SCOM_MESS to $SCOM_FTP_FILE");} # Print file content to screen
      print (SCOM_FTP "${SCOM_MESS}\n");                                   # Write line to SCOM file
      return
   }
      
   
# If Error is for Application Analyst Team
   if ($SLAM_RECORD->{SLAM_QPAGE} =~ /app/ ) {
      $SCOM_MESS1 = "${HOSTNAME}_app_$WORK_ID = ${SC_STATUS} ";            # Std SCOM Line
      $SCOM_MESS  = "${SCOM_MESS1}${SCOM_MESS2}";                          # Combine 3 Part messages
      if ($SLAM_RECORD->{SLAM_ID} =~ /^script/  ) {                        # Really a script invoked
         ($dummy,$sname) = split /:/, $SLAM_RECORD->{SLAM_ID} ;            # Extract Full script name
         (my $script_name, my $dirName, my $sfile_extension) = fileparse($sname, ('\.sh') );
         $SCOM_APP_FILE = "$SCOM_APP_DIR" . "/" . "$script_name" . ".txt" ;
         if ($DEBUG >= 5) { print ("\nAdding $SCOM_MESS to $SCOM_APP_FILE");}# Print file content to screen
         open (SCOM_APP, ">$SCOM_APP_FILE")  or die "Can't open $SCOM_PA_FILE: $!\n";  # Advise if can't create file
         print (SCOM_APP "${SCOM_MESS}\n");                                # Write line to SCOM file
         close SCOM_APP;                                        # Close SCOM PA Status file
      }else{
         if ($DEBUG >= 5) {
            print ("\nAdding $SCOM_MESS to $SCOM_APP_FILE");               # Print file content to screen
            print "\nSlam identifier is $SLAM_RECORD->{SLAM_ID}";          # Print SLam Identifier
         } 
         print (SCOM_APP "${SCOM_MESS}\n");                                # Write line to SCOM file
      }
      return
   }


# Default : Error is for Unix Admin
   $SCOM_MESS1 = "${HOSTNAME}_os_$WORK_ID = ${SC_STATUS} ";                # Std SCOM Line
   $SCOM_MESS  = "${SCOM_MESS1}${SCOM_MESS2}";                             # Combine 2 Part messages
   if ($DEBUG >= 5) { print ("\nAdding $SCOM_MESS to $SCOM_OS_FILE");}     # Print file content to screen
   print (SCOM_OS "${SCOM_MESS}\n");                                       # Write line to SCOM file
   return

}




# THIS FUNCTION IS CALLED EVERY TIME AN ERROR IS DETECTED, IT WRITE A LINE TO THE ERROR FILE.
# --------------------------------------------------------------------------------------------------
sub write_error_file {

# Save variables received as parameter
   my ($ERR_LEVEL,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESSAGE) = @_;
   if ($DEBUG >= 6) {                                                   # If Debug is ON
      print "\nError Soft = $ERR_SOFT";
      print "\nError SUBSYSTEM = $ERR_SUBSYSTEM";
      print "\nError MEssage = $ERR_MESSAGE";
   }
   
# SETUP DATE & TIME FORMAT OF ERROR 
   $ERR_DATE = `date +%d/%m/%Y`; chop $ERR_DATE;
   $ERR_TIME = `date +%H:%M`   ; chop $ERR_TIME;

# IF STATUS IS H (HEALTHY) Write healthy line and return to caller
   if ($ERR_LEVEL eq "H") { return; }
   
# Set SCOM_STATUS AND ERROR TYPE
   if ($ERR_LEVEL eq "W") {
      $ERROR_TYPE = "Warning" ; 
      $SCOM_STATUS = $WARNING ; 
   }else{
      $ERROR_TYPE = "Error" ;
      $SCOM_STATUS = $CRITICAL ; 
   }
 
# Create rpt line content in case we have to write it later
   my $SLAM_LINE="";
   if (($ERR_SOFT eq "DB2 Database") || ($ERR_SOFT eq "Oracle Database")) {
      $SLAM_LINE = sprintf "%s;%s;%s;%s;%s;%s;%s;%s;%s\n",$ERROR_TYPE,$HOSTNAME,$ERR_DATE,$ERR_TIME,$ERR_SOFT,$ERR_SUBSYSTEM,"$ERR_MESSAGE","dba","dba";
   }else{
      $SLAM_LINE = sprintf "%s;%s;%s;%s;%s;%s;%s;%s;%s\n",$ERROR_TYPE,$HOSTNAME,$ERR_DATE,$ERR_TIME,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESSAGE,$SLAM_RECORD->{SLAM_QPAGE},$SLAM_RECORD->{SLAM_EMAIL};
   }
   
# THIS GLOBAL VARIABLE IS SET TO Y , SO WE KNOW THAT AT LEAST ONE ERROR WERE FOUND 
   $ERROR_FOUND = "Y";

# IF IT IS A WARNING WRITE SCOM FILE AND RPT FILE AND RETURN TO CALLER
   if ($ERR_LEVEL eq "W") {
      write_scom_file ($SCOM_STATUS,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESSAGE);  
      print SLAMRPT $SLAM_LINE;
      return;
   }
# FROM HERE IT IS AN ERROR - IF FILESYSTEM ERROR WILL BE TAKEN CARE - NO SCRIPT TO EXECUTE
   if ($ERR_SUBSYSTEM eq "FILESYSTEM")  {
      write_scom_file ($SCOM_STATUS,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESSAGE);  
      print SLAMRPT $SLAM_LINE;
      return;
   }

# SO ERROR WERE DISCOVER _ BUT HAVE NO SCRIPT TO CORRECT THE SITUATION - RETURN TO CALLER
   my $script_name="$SLAM_RECORD->{SLAM_SCRIPT}";                       # Get Basename of script to run
   if ((length $script_name == 0 ) || ($script_name eq "-")) {          # If no script name specified
      write_scom_file ($SCOM_STATUS,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESSAGE); #
      printf SLAMRPT $SLAM_LINE;                                        # Write Error to Scom txt
      return;                                                           # Return to caller
   }

# MAKE SURE SCRIPT EXIST - IF NOT RETURN TO CALLER
   $script_name="${SLAMSCR_DIR}/$script_name";                          # Full path to script name added
   if (! -e $script_name) {                                             # If script doesn't exist
      print "\nThe requested script doesn't exist ($script_name)";      # Advise user
      write_scom_file ($SCOM_STATUS,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESSAGE);  
      printf SLAMRPT $SLAM_LINE;
      return;
   }

# MAKE SURE SCRIPT IS EXECUTABLE - IF NOT RETURN TO CALLER
   if (( -e "$script_name" ) && ( ! -x "$script_name")) {               # If Script doesn't exist or not executable
      print "\nScript $script_name exist, but is not executable";       # Inform user of error
      write_scom_file ($SCOM_STATUS,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESSAGE);  
      printf SLAMRPT $SLAM_LINE;
      return;
   }

# GET CURRENT DATE & TIME IN EPOCH TIME
   ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();        # Get current epoch time
   if ($DEBUG >= 5) {                                                   # If Debug is ON
      print "\nScript name is : $script_name ";                         # Print Script name
      print "\nCurrent Time: $year $month $day $hour $min $sec";        # Print current time
      print "\nThe Actual epoch time is $epoch";                        # Print Epoch time
   }
         
# IF IT IS THE FIRST TIME THE SCRIPT IS RUN - PUT CURRENT DATE AND TIME IN HOSTNAME.CFG ARRAY
   if ( $SLAM_RECORD->{SLAM_DATE} == 0 ) {                              # If current date = 0 in SLAM Array
      $SLAM_RECORD->{SLAM_DATE} = sprintf("%04d%02d%02d",$year,$month,$day);  # Update SLAM_DATE=current date
      $SLAM_RECORD->{SLAM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);  # Update SLAM_Time=current time
   }
                  
# BREAK LAST EXECUTION DATE AND TIME FROM HOSTNAME.CFG ARRAY - READY FOR EPOCH CALCULATION 
   $wyear  = sprintf "%04d",substr($SLAM_RECORD->{SLAM_DATE},0,4);      # Extract Year from SLAM_DATE
   $wmonth = sprintf "%02d",substr($SLAM_RECORD->{SLAM_DATE},4,2);      # Extract Month from SLAM_DATE
   $wday   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_DATE},6,2);      # Extract Day from SLAM_DATE
   $whrs   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_TIME},0,2);      # Extract Hour from SLAM_TIME
   $wmin   = sprintf "%02d",substr($SLAM_RECORD->{SLAM_TIME},2,2);      # Extract Min from SLAM_TIME
           
# GET EPOCH TIME OF THE LAST TIME WE HAD A LOAD EXCEEDED
   $last_epoch = get_epoch("$wyear","$wmonth","$wday","$whrs","$wmin","0");   # Calc. Epoch of first filesystem increase
   if ($DEBUG >= 5) {                                                   # If DEBUG if ON
      print "\nLast time that $script_name script was executed : $wyear $wmonth $wday $whrs $wmin 00"; 
      print "\nEpoch time of last execution : $last_epoch";             # Print last execution epoch time
   }

# CALCULATE THE NUMBER OF SECONDS SINCE THE LAST EXECUTION AND NOW IN SECONDS
   $elapse_second = $epoch - $last_epoch;                               # Substract last epoch from curr. epoch
   if ($DEBUG >= 5) {                                                   # If DEBUG Activated
      print "\nSo $epoch - $last_epoch = $elapse_second seconds";       # Print Elapsed seconds
   }

# Get Process Name
   @dummy = split /_/, $SLAM_RECORD->{SLAM_ID} ;
   $daemon_name = $dummy[1];

# IF THE NUMBER OF SECONDS BETWEEN NOW AND THE LAST RUN TIME IS GREATER THAN WANTED - ISSUE ERROR
   if ( $elapse_second >= $SCRIPT_MIN_SEC_BETWEEN_EXEC ) {              # Elapsed Sec >= 86400 Sec. then ok to run
      ($year,$month,$day,$hour,$min,$sec,$epoch) = Today_and_Now();     # Get current date and time
      $SLAM_RECORD->{SLAM_DATE} = sprintf("%04d%02d%02d", $year,$month,$day); # Update SLAM_DATE=current date
      $SLAM_RECORD->{SLAM_TIME} = sprintf("%02d%02d",$hour,$min,$sec);  # Update SLAM_Time=current time
      $SLAM_RECORD->{SLAM_MINUTES} = "001";                             # Reset counter to 1, since first run today
      if ($DEBUG >= 5) {                                                # If DEBUG Activated
         print "\nScript selected for execution $SLAM_RECORD->{SLAM_SCRIPT}"; # Advise user
      }
      my $mail_message1 = "Daemon $daemon_name was not running on $HOSTNAME\n";
      my $mail_message2 = "SADM Automatically executed restart script : $SLAM_RECORD->{SLAM_SCRIPT}";
      my $mail_message3 = " to restart the service. \nThis is the first time I am restarting it.";
      my $mail_message  = "$mail_message1 $mail_message2 $mail_message3";
      my $mail_subject = "SADM Notification: $HOSTNAME daemon $daemon_name restarted";
      @args = ("echo \"$mail_message\" | $CMD_MAIL -s \"$mail_subject\" $SLAM_ADMIN_EMAIL");
      system(@args) ;
      if ( $? == -1 ) { print "\ncommand failed: $!"; }else{ printf "\ncommand exited with value %d", $? >> 8; }
      $COMMAND = "$script_name >>${script_name}.log 2>&1";
      print "\nCommand sent ${COMMAND}"; 
      @args = ("$COMMAND");
      system(@args) ;
      if ( $? == -1 ) { print "\ncommand failed: $!"; }else{ printf "\ncommand exited with value %d", $? >> 8; }
      
   }else{
      if (($SLAM_RECORD->{SLAM_MINUTES} + 1) > $SCRIPT_MAX_RUN_PER_DAY){# If Counter exceed daily run limit
         if ($DEBUG >= 5) {                                             # If DEBUG Activated
            print "\nScript $SLAM_RECORD->{SLAM_SCRIPT} as ran $SLAM_RECORD->{SLAM_MINUTES} times in last 24 Hrs.";
            print "\nWill therefore not be executed.";                  # Inform user not done
         }
         @dummy = split /_/, $SLAM_RECORD->{SLAM_ID} ;
         $daemon_name = $dummy[1];
         $ERR_MESS = "Failed to restart daemon $daemon_name " ;         # Set up Error Message
         $error_detected="E";
         $SCOM_STATUS = $CRITICAL ;
         write_scom_file ($SCOM_STATUS,$ERR_SOFT,$ERR_SUBSYSTEM,$ERR_MESS);  
         print SLAMRPT $SLAM_LINE;
      }else{
         $WORK = $SLAM_RECORD->{SLAM_MINUTES} + 1;                      # Incr. Run script Counter
         $SLAM_RECORD->{SLAM_MINUTES} = sprintf("%03d",$WORK);          # Insert Cnt in Array
         if ($DEBUG >= 5) {                                             # If DEBUG Activated
            print "\nThe script $SLAM_RECORD->{SLAM_SCRIPT} ran $SLAM_RECORD->{SLAM_MINUTES} time(s) in last 24hrs.";
         }
         $COMMAND = "$script_name >>${script_name}.log 2>&1";
         print "\nCommand sent ${COMMAND}"; 
         @args = ("$COMMAND");
         system(@args) ;
         if ( $? == -1 ) { print "\ncommand failed: $!"; }else{ printf "\ncommand exited with value %d", $? >> 8; }
      }
   }
}





# COPY RPT FILES TO SLAMSERVER
# --------------------------------------------------------------------------------------------------
sub copyfile2slamserver {


# Copy RPT to Slam server   
#   print "\n-----\nCopying $SLAMRPT_FILE to ${SLAM_SERVER}";
#   if ($SLAM_SERVER eq $HOSTNAME) {
#      $COMMAND = "su - slam \"-c cp $SLAMRPT_FILE /slam/files/aix/rpt/${HOSTNAME}.rpt\"";
#   }else{
#      if ($USE_SSH eq "Y") {
#         $SFTP="/usr/bin/sftp -P32 " ; 
#         $SFTP="/usr/bin/sftp -oPort=32 -b" ; 
#         #$COMMAND = "su - slam \"-c echo put $SLAMRPT_FILE | $SFTP -B - ${SLAM_SERVER}:/slam/files/aix/rpt\"";
#         $COMMAND = "su - slam \"-c echo put $SLAMRPT_FILE | $SFTP   - ${SLAM_SERVER}:/slam/files/aix/rpt\"";
#      }else{
#         $COMMAND = "su - slam \"-c $CMD_RCP $SLAMRPT_FILE ${SLAM_SERVER}:/slam/files/aix/rpt\"";
#      }
#   }
#   print "\nCommand sent ${COMMAND}"; 
#   @args = ("$COMMAND");
#   system(@args) ;
#   if ( $? == -1 ) {
#      print "\ncommand failed: $!\n";
#      email_error  ("$COMMAND") ;
#   }else{
#      printf "\ncommand exited with value %d", $? >> 8;
#   }
   

# IF TSM MISSED SCHEDULE WAS CHECKED THEN COPY THE AIX/NOV/WIN RPT FILE TO SLAMSERVER
   if ( $TSMMISSED_FLAG > 0 ) { 
      print    "\nsu - slam \" -c $CMD_RCP $AIX_RCFILE ${SLAM_SERVER}:files/aix/rpt\"";
      @args = ("su - slam \"   -c $CMD_RCP $AIX_RCFILE ${SLAM_SERVER}:files/aix/rpt\"");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!\n";
         email_error  ("@args") ;
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }
   
      print    "\nsu - slam \" -c $CMD_RCP $WIN_RCFILE ${SLAM_SERVER}:files/win/rpt\"";
      @args = ("su - slam \"   -c $CMD_RCP $WIN_RCFILE ${SLAM_SERVER}:files/win/rpt\"");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!\n";
         email_error  ("@args") ;
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }

      print    "\nsu - slam \" -c $CMD_RCP $DBA_RCFILE ${SLAM_SERVER}:files/dba/rpt\"";
      @args = ("su - slam \"   -c $CMD_RCP $DBA_RCFILE ${SLAM_SERVER}:files/dba/rpt\"");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!\n";
         email_error  ("@args") ;
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }
   }
}




# ==================================================================================================
#     Advise Sysadmin when a problem occurs when transfering file to Scom server or Sysinfo
# ==================================================================================================
sub email_error {
   
   # Save variables received as parameter
   my ($MAIL_MESSAGE) = @_;
   if ($DEBUG >= 6) { print "\nMail Message is $MAIL_MESSAGE"; }

   my $MAIL_SUBJECT = "SADM File transfer problem on $HOSTNAME";
   #$COMMAND =  "echo \"$MAIL_MESSAGE\" | $CMD_MAIL -s \"$MAIL_SUBJECT\" $SADM_ADMIN_EMAIL";
#   @cmd =      "echo \"$MAIL_MESSAGE\" | $CMD_MAIL -s \"$MAIL_SUBJECT\" $SADM_ADMIN_EMAIL";
   @cmd =      "echo \"$MAIL_MESSAGE\" | $CMD_MAIL -s \"$MAIL_SUBJECT\" jack.duplessis\@standardlife.ca";
   #print "\nCommand sent ${COMMAND}\n"; 
   print "\nCommand sent @cmd \n"; 
   $return_code = 0xffff & system @cmd ;
   #@args = ("$COMMAND");
   #system(@args) ;
    
   if ( $? == -1 ) {
      print "\ncommand failed: $!";
   }else{
      printf "\ncommand exited with value %d", $? >> 8;
   }
}

# ==================================================================================================
#                CREATED REMOTE DIRECTORIES ON THE PROPER SCOM SERVER (DEV OR PROD)
# ==================================================================================================
sub create_scom_directory {
   
      print "\n------------ \nCreating needed directories on SCOM and sysinfo server"; 
      $MKDIR_REMOTE = "N";
      $COMMAND = "su - slam \"-c $SSH_COMMAND \'mkdir ${SCOM_RDIR}\\${HOSTNAME}\'\"";
      print "\nCommand sent ${COMMAND}\n"; 
      @args = ("$COMMAND");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!";
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }

      $COMMAND = "su - slam \"-c $SSH_COMMAND \'mkdir ${SCOM_RDIR}\\${HOSTNAME}\\pa\'\"";
      print "\nCommand sent ${COMMAND}\n"; 
      @args = ("$COMMAND");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!";
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }

      $COMMAND = "su - slam \"-c $SSH_COMMAND \'mkdir ${SCOM_RDIR}\\${HOSTNAME}\\app\'\"";
      print "\nCommand sent ${COMMAND}\n"; 
      @args = ("$COMMAND");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!";
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }

      $COMMAND = "su - slam \"-c $SSH_COMMAND \'mkdir ${SCOM_RDIR}\\${HOSTNAME}\\was\'\"";
      print "\nCommand sent ${COMMAND}\n"; 
      @args = ("$COMMAND");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!";
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }

      $COMMAND = "su - slam \"-c $SSH_COMMAND \'mkdir ${SCOM_RDIR}\\${HOSTNAME}\\dba\'\"";
      print "\nCommand sent ${COMMAND}\n"; 
      @args = ("$COMMAND");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!\n";
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }

      $COMMAND = "su - slam \"-c $SSH_COMMAND \'mkdir ${SCOM_RDIR}\\${HOSTNAME}\\os\'\"";
      print "\nCommand sent ${COMMAND}\n"; 
      @args = ("$COMMAND");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!";
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }
      
      $COMMAND = "su - slam \"-c $SSH_COMMAND \'mkdir ${SCOM_RDIR}\\${HOSTNAME}\\ftp\'\"";
      print "\nCommand sent ${COMMAND}\n"; 
      @args = ("$COMMAND");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!";
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }
      
      # MAKE SURE THE SERVER DIRECTORY EXIST IN /sysinfo/www/data/txt DIRECTORY ON SYSINFO SERVER
      print "\n------------ \nMaking sure that ${SYSINFO_TXT} is created on sysinfo server";
      if ($SYSINFO_HOST == $HOSTNAME) {
         $COMMAND = "mkdir -p ${SYSINFO_TXT} >/dev/null 2>&1" ;
      }else{
         $COMMAND = "su - slam \"-c $SSH_BIN $SSH_OPTS ${SYSINFO_SERVER} \'mkdir -p ${SYSINFO_TXT}\' >/dev/null 2>&1\"";
      }
      print "\nCommand sent ${COMMAND}\n"; 
      @args = ("$COMMAND");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!";
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }

      # MAKE SURE THE SERVER DIRECTORY EXIST IN /sysinfo/www/data/rc DIRECTORY ON SYSINFO SERVER
      print "\n------------ \nMaking sure that ${SYSINFO_RC}/${HOSTNAME} is created on sysinfo server";
      if ($SYSINFO_HOST == $HOSTNAME) {
         $COMMAND = "mkdir -p ${SYSINFO_RC}/${HOSTNAME} >/dev/null 2>&1" ;
      }else{
         $COMMAND = "su - slam \"-c $SSH_BIN $SSH_OPTS ${SYSINFO_SERVER} \'mkdir -p ${SYSINFO_RC}/${HOSTNAME}\' >/dev/null 2>&1\"";
      }
      print "\nCommand sent ${COMMAND}\n"; 
      @args = ("$COMMAND");
      system(@args) ;
      if ( $? == -1 ) {
         print "\ncommand failed: $!";
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }
}




# ==================================================================================================
#                    COPY TXT FILES TO SCOM SERVER AND SYSINFO SERVER
# ==================================================================================================
sub copyfile2scomserver {
   

   # Prepare SSH command to use depending upon server is Dev. or Prod.
   # -----------------------------------------------------------------------------------------------
   if ($SERVER_TYPE eq "D") { 
      $SSH_COMMAND = "$SCOM_DSSH";
      print "\n\n------------ \nCopying files to Dev. SCOM server $SCOM_DSERVER ..." ;
   }else{
      $SSH_COMMAND = "$SCOM_PSSH";
      print "\n\n------------ \nCopying files to Prod. SCOM server $SCOM_PSERVER ..." ;
   }
   
   # If Directory was not created on SCOM server do it now.
   # -----------------------------------------------------------------------------------------------
   if ( ${MKDIR_REMOTE} eq "Y" ) {
      create_scom_directory;
   }else{
      if ($SERVER_TYPE eq "D") { 
         print "\nAssuming that $HOSTNAME directories are created on SCOM server ${SCOM_DSERVER}";
      }else{
         print "\nAssuming that $HOSTNAME directories are created on SCOM server ${SCOM_PSERVER}";
      }
      print "\nIf you want to create them, modify $SCOM_CFG_FILE (mkdir_remote = Y) & rerun SADM";
      
   }


   # COPY TXT FILES TO SCOM SERVER
   #  scp -rP 32  /scom/txt/*.txt dsccsrv@nmmq1d27.slacdev.ca:\lxmq0007
   # -----------------------------------------------------------------------------------------------
   print "\n-----\nCopying txt files to SCOM Server";
   my $SCP_CMD_BACKUP = $SCOM_SCP ;                                     # Save Cur. Value of SCOM_SCP
   if (($HOSTNAME eq "wonhyo") ||  ($HOSTNAME eq "yulgok")) { $SCOM_SCP = "/usr/bin/scp -r -P32"; }
   if ($SERVER_TYPE eq "D") { 
      $COMMAND = "su - slam \"-c $SCOM_SCP $SLAMTXT_DIR/* ${SCOM_DUSER}\@${SCOM_DSERVER}:\\${HOSTNAME}\"";
   }else{
      $COMMAND = "su - slam \"-c $SCOM_SCP $SLAMTXT_DIR/* ${SCOM_PUSER}\@${SCOM_PSERVER}:\\${HOSTNAME}\"";
   }
   my $SCOM_SCP = $SCP_CMD_BACKUP ;                                     # Restore Org. Value of SCOM_SCP
   print "\nCommand sent $COMMAND \n";                                  # Display Command pass to O/S
   @args = ("$COMMAND");                                                # Move Command to Array
   system(@args) ;                                                      # Execute Command at OS Level
   if ( $? != 0 ) {  
      print "\ncommand failed: $!\n";
      #email_error  ("$COMMAND") ;
   }else{
      printf "\ncommand exited with value %d", $? >> 8;
   }


   # COPY TXT FILES TO SYSINFO SERVER
   # -----------------------------------------------------------------------------------------------
   print "\n-----\nCopying txt files to sysinfo server";
   if ($SYSINFO_HOST eq $HOSTNAME) {
      $COMMAND = "su - slam \"-c rsync -e '$SSH_BIN -x' -vatr --delete ${SLAMTXT_DIR}/ ${SYSINFO_ACCOUNT}${SYSINFO_TXT}/\"" ;
   }else{
      #$COMMAND = "su - slam \"-c $SCOM_SCP $SLAMTXT_DIR/* ${SYSINFO_SERVER}:$SYSINFO_TXT\"";
      #$COMMAND = "su - slam \"-c $SCOM_SCP $SLAMTXT_DIR/* ${SYSINFO_ACCOUNT}${SYSINFO_TXT}\"";
      #$COMMAND = "su - slam \"-c $SCOM_SCP $SLAMTXT_DIR/* ${SYSINFO_ACCOUNT}${SYSINFO_TXT}\"";
      if ($OSNAME eq "aix" &&  ${OPENSSH} eq 'N') {
         $COMMAND = "su - slam \"-c rsync -e '$SSH_BIN -xp32' -vatr --delete ${SLAMTXT_DIR}/ ${SYSINFO_ACCOUNT}${SYSINFO_TXT}/\"" ;
      }else{
         $COMMAND = "su - slam \"-c rsync -e \'$SSH_BIN -xp32\' -vatr --delete ${SLAMTXT_DIR}/ ${SYSINFO_ACCOUNT}${SYSINFO_TXT}/\"" ;
         #$COMMAND = "su - slam \"-c rsync -vatr --delete ${SLAMTXT_DIR}/ ${SYSINFO_SERVER}:${SYSINFO_TXT}/\"" ;
      }
   }
   print "\nCommand sent $COMMAND \n"; 
   @args = ("$COMMAND");
   system(@args) ;
   if ( $? != 0 ) {
      print "\ncommand failed: $!\n";
      #email_error  ("$COMMAND") ;
   }else{
      printf "\ncommand exited with value %d", $? >> 8;
   }

 

   # COPY RPT FILES TO SYSINFO SERVER
   # -----------------------------------------------------------------------------------------------
   $SCP_CMD_BACKUP = $SCOM_SCP ; 
   if (($HOSTNAME eq "wonhyo") ||  ($HOSTNAME eq "yulgok")) { $SCOM_SCP = "/usr/bin/scp -r -P32"; }
   if ("$SYSINFO_HOST" eq "$HOSTNAME") {
      $COMMAND = "$CMD_CP -p $SLAMRPT_FILE ${SYSINFO_RPT}/aix" ;
   }else{
      $COMMAND = "su - slam \"-c $SCOM_SCP $SLAMRPT_FILE ${SYSINFO_SERVER}:${SYSINFO_RPT}/aix\"";
      $COMMAND = "su - slam \"-c $SCOM_SCP $SLAMRPT_FILE ${SYSINFO_ACCOUNT}${SYSINFO_RPT}/aix\"";
   }
   $SCOM_SCP = $SCP_CMD_BACKUP ;
   print "\n-----\nCopying rpt files to sysinfo server";
   print "\nCommand sent ${COMMAND} \n"; 
   @args = ("$COMMAND");
   system(@args) ;
   if ( $? != 0 ) {
      print "\ncommand failed: $!\n";
      #email_error  ("$COMMAND") ;
   }else{
      printf "\ncommand exited with value %d", $? >> 8;
   }
   


   # IF TSM MISSED SCHEDULE WAS CHECKED THEN COPY THE AIX/DBA/WIN RPT FILE TO SYSINFO SERVER
   # -----------------------------------------------------------------------------------------------
   if ( $TSMMISSED_FLAG > 0 ) { 
      print "\n-----\nCopy AIX/Linux Missed Schedule Report to SysInfo server";
      @args = ("su - slam \"   -c $SCOM_SCP -q $AIX_RCFILE ${SYSINFO_SERVER}:${SYSINFO_RPT}/aix\"");
      system(@args) ;
      if ( $? != 0 ) {
         print "\ncommand failed: $!\n";
         email_error  ("$COMMAND") ;
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }

      print "\n-----\nCopy Windows Missed Schedule Report to SysInfo server";
      print "\n$SCOM_SCP $WIN_RCFILE ${SYSINFO_SERVER}:${SYSINFO_RPT}/win";
      @args = ("su - slam \"   -c $SCOM_SCP -q $WIN_RCFILE ${SYSINFO_SERVER}:${SYSINFO_RPT}/win\"");
      system(@args) ;
      if ( $? != 0 ) {
         print "\ncommand failed: $!\n";
         email_error  ("$COMMAND") ;
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }

      print "\n-----\nCopy DBA Missed Schedule Report to SysInfo server";
      print "\n$SCOM_SCP -q $DBA_RCFILE ${SYSINFO_SERVER}:${SYSINFO_RPT}/dba";
      @args = ("su - slam \"   -c $SCOM_SCP -q $DBA_RCFILE ${SYSINFO_SERVER}:${SYSINFO_RPT}/dba\"");
      system(@args) ;
      if ( $? != 0 ) {
         print "\ncommand failed: $!\n";
         email_error  ("$COMMAND") ;
      }else{
         printf "\ncommand exited with value %d", $? >> 8;
      }
   }



   # Copy rc*.log to sysinfo server   
   # -----------------------------------------------------------------------------------------------
   print "\n-----\nCopying /var/adsmlog/rc*.log files to sysinfo server";
   if ( $SYSINFO_HOST eq $HOSTNAME) {
      $COMMAND = "cp -p $ADSMLOG_DIR/rc.*.log ${SYSINFO_RC}/${HOSTNAME}";
      #$COMMAND = "cp $ADSMLOG_DIR/rc.*.log ${SYSINFO_ACCOUNT}${SYSINFO_RC}/${HOSTNAME}";
      #$COMMAND = "su - slam \"-c rsync -vatc --delete -e '$SSH_BIN -xp32' $ADSMLOG_DIR/rc.*.log  slam\@${SYSINFO_SERVER}:${SYSINFO_RC}/${HOSTNAME}\/\"";
   }else{
      #$COMMAND = "su - slam \"-c $SCOM_SCP $ADSMLOG_DIR/rc.*.log ${SYSINFO_ACCOUNT}${SYSINFO_RC}/${HOSTNAME}\"";
      $COMMAND = "su - slam \"-c rsync -vatc --delete -e '$SSH_BIN -xp32' $ADSMLOG_DIR/rc.*.log  slam\@${SYSINFO_SERVER}:${SYSINFO_RC}/${HOSTNAME}\/\"";
   }
   print "\nCommand sent ${COMMAND} \n"; 
   @args = ("$COMMAND");
   system(@args) ;
   if ( $? != 0 ) {
      print "\ncommand failed: $!\n";
      #email_error  ("$COMMAND") ;
   }else{
      printf "\ncommand exited with value %d", $? >> 8;
   }
   
   
   
   # Copy /var/adsmlog/dba/rc*.log to sysinfo server   
   # -----------------------------------------------------------------------------------------------

   
   # Make sure at least one file exist in the dba directory - to prevent faulty error on rsync
   my $DBA_RCFILE="$ADSMLOG_DIR/dba/rc.${HOSTNAME}.test.log";
   print "\n-----\nMake sure $DBA_RCFILE exist and with proper permission" ;
   if ( ! -e "$DBA_RCFILE") {
      print "\nCreating dba dummy rc file $DBA_RCFILE\n";
      @args = ("$CMD_TOUCH", "$DBA_RCFILE");
      system(@args) == 0   or die "system @args failed: $?";
   }
   @args = ("$CMD_CHMOD" , "664", "$DBA_RCFILE");
   system(@args) == 0   or die "system @args failed: $?";

   print "\n-----\nCopying /var/adsmlog/dba/rc*.log files to ${SYSINFO_DBA} on sysinfo server";
   $SCP_CMD_BACKUP = $SCOM_SCP ; 
   if (($HOSTNAME eq "wonhyo") ||  ($HOSTNAME eq "yulgok")) { $SCOM_SCP = "/usr/bin/scp -r -P32"; }
   $COMMAND = "su - slam \"-c $SCOM_SCP $ADSMLOG_DIR/dba/rc.*.log ${SYSINFO_ACCOUNT}${SYSINFO_DBA}\/\"";
   if ( $SYSINFO_HOST eq $HOSTNAME) {
      $COMMAND = "su - slam \"-c rsync -vatc --delete -e '$SSH_BIN -xp32' $ADSMLOG_DIR/dba/rc.*.log  slam\@${SYSINFO_SERVER}:${SYSINFO_DBA}\/\"";
   }else{
      $COMMAND = "su - slam \"-c rsync -vatc --delete -e '$SSH_BIN -xp32' $ADSMLOG_DIR/dba/rc.*.log  slam\@${SYSINFO_SERVER}:${SYSINFO_DBA}\/\"";
   }
   $SCOM_SCP = $SCP_CMD_BACKUP ;
   print "\nCommand sent ${COMMAND} \n"; 
   @args = ("$COMMAND");
   system(@args) ;
   if ( $? != 0 ) {
      print "\ncommand failed: $!\n";
      #email_error  ("$COMMAND") ;
   }else{
      printf "\ncommand exited with value %d", $? >> 8;
   }
   
}





# FUNCTION IS CALLED TO DETERMINE IF THE CURRENT SERVER IS A PRODUCTION SERVER OR A DEV. SERVER
# --------------------------------------------------------------------------------------------------
sub get_server_type {
   if ($DEBUG >= 5) { print "\n-----\ngrepping $DSM_INCL_FILE for PRODUCTION"};
   open (DSMINCL,"<$DSM_INCL_FILE") or die "\nCan't open $DSM_INCL_FILE: $!";
   $FOUND_PROD = 0;
   while ($line = <DSMINCL>) {                              # Read TSM include/exclude list file
         next if $line =~ /^#/ ;                            # Skip comment line
         next if $line =~ /^$/ ;                            # Skip blank line
         $line =~ tr/A-Z/a-z/;                              # Make Sure line is all lower case
         if ($line =~ /production/ ) { $FOUND_PROD = 1 ;}   # Check for word "Production"
   }
   close DSMINCL;                                           # Close include/exclude TSM file
   
   if ( ${FOUND_PROD} eq 0 ) {                              # FOUND_PROD at zero = Dev. Server
      if ($DEBUG >= 5) { print "\nServer type is Dev.\n"; } # Print debug information
      return 'D' ;                                          # Return letter D to caller
   }else{
      if ($DEBUG >= 5) { print "\nServer type is Prod.\n"; }# FOUND_PROD not at zero = Prod. Server
      return 'P' ;                                          # Return Letter P to caller
   }
}

# CALL ONCE AT THE END OF THE SCRIPT TO UNLOAD THE SCOM.CFG FILE GLOBAL VARIABLES
# --------------------------------------------------------------------------------------------------
sub unload_config_file {
   open (SCOM_CONFIG_FILE,"> $SCOM_CFG_FILE") or die "Can't create $SCOM_CFG_FILE: $!\n"; # create it
   print (SCOM_CONFIG_FILE "server_type  = ${SERVER_TYPE}\n");
   print (SCOM_CONFIG_FILE "use_ssh      = ${USE_SSH}\n");
   print (SCOM_CONFIG_FILE "mkdir_remote = ${MKDIR_REMOTE}\n");
   print (SCOM_CONFIG_FILE "openssh      = ${OPENSSH}\n");
   close SCOM_CONFIG_FILE;
}




# Mkdir routine to ensure right privilege
# --------------------------------------------------------------------------------------------------
sub scom_mkdir {
   my ($WDIR) = @_;
   
   if ( -d "$WDIR") { return; }
       
   $COMMAND = "mkdir -p ${WDIR}";
   print "\nCommand sent ${COMMAND}"; 
   @args = ("$COMMAND");
   system(@args) ;
   if ( $? == -1 ) { print "\ncommand failed: $!\n"; }else{ printf "\ncommand exited with value %d", $? >> 8; }
   
   $COMMAND = "chmod 777 ${WDIR}";
   print "\nCommand sent ${COMMAND}"; 
   @args = ("$COMMAND");
   system(@args) ;
   if ( $? == -1 ) { print "\ncommand failed: $!\n"; }else{ printf "\ncommand exited with value %d", $? >> 8; }
   
   $COMMAND = "chmod +t ${WDIR}";
   print "\nCommand sent ${COMMAND}"; 
   @args = ("$COMMAND");
   system(@args) ;
   if ( $? == -1 ) { print "\ncommand failed: $!\n"; }else{ printf "\ncommand exited with value %d", $? >> 8; }
}


# CALL ONCE AT THE BEGINNING OF THE SCRIPT TO LOAD THE SCOM.CFG FILE AND SET GLOBAL VARIABLES
# --------------------------------------------------------------------------------------------------
sub load_config_file {

   if ( ! -e "$SCOM_CFG_FILE"  ) {                                      # If slam.cfg doesn't exist
      open (SCOM_CONFIG_FILE,"> $SCOM_CFG_FILE") or die "Can't create $SCOM_CFG_FILE: $!\n"; # create it
      $SERVER_TYPE = get_server_type() ;                                # Get type of server D/P
      print (SCOM_CONFIG_FILE "server_type  = ${SERVER_TYPE}\n");
      print (SCOM_CONFIG_FILE "use_ssh      = Y\n");
      print (SCOM_CONFIG_FILE "mkdir_remote = Y\n");
      print (SCOM_CONFIG_FILE "openssh      = Y\n");
      close SCOM_CONFIG_FILE;
   }else{
      open (SCOM_CONFIG_FILE, "< $SCOM_CFG_FILE") or die "Can't open $SCOM_CFG_FILE: $!\n";
      while (<SCOM_CONFIG_FILE>) {
         ($scom_name, $scom_value ) = split("\=");                      # Split Name and value content
         $scom_name =~ tr/[a-z]/[A-Z]/;                                 # Make sure name is in uppercase
         $scom_name =~ s/^\s+|\s+$//g;                                  # Remove trailing and ending spaces

         if ($scom_name eq 'SERVER_TYPE' ) {                            # If server type line
            $scom_value =~ s/^\s+|\s+$//g;                              # Remove trailing and ending spaces
            $SERVER_TYPE = $scom_value;                                 # Set server type value
            $SERVER_TYPE =~ tr/[a-z]/[A-Z]/;                            # Make sure server type is in uppercase
            if (${SERVER_TYPE} ne 'P' &&  ${SERVER_TYPE} ne 'D') {      # Check for valid values
               if ($DEBUG >= 5) { print "\nThe Server Type $SERVER_TYPE is invalid (Production Assumed)" };
               ${SERVER_TYPE} = 'P' ;
            }
         }
         if ($scom_name eq 'USE_SSH' ) {                                # If server type line
            $scom_value =~ s/^\s+|\s+$//g;                              # Remove trailing and ending spaces
            $USE_SSH = $scom_value;                                     # Set server type value
            $USE_SSH =~ tr/[a-z]/[A-Z]/;                                # Make sure server type is in uppercase
            if (${USE_SSH} ne 'Y' &&  ${USE_SSH} ne 'N') {              # Check for valid values
               if ($DEBUG >= 5) { print "\nThe USE_SSH value in $SCOM_CFG_FILE is invalid (Y Assumed)" };
               ${USE_SSH} = 'Y' ;
            }
         }
         if ($scom_name eq 'OPENSSH' ) {                                # If server type line
            $scom_value =~ s/^\s+|\s+$//g;                              # Remove trailing and ending spaces
            $OPENSSH = $scom_value;                                     # Set server type value
            $OPENSSH =~ tr/[a-z]/[A-Z]/;                                # Make sure server type is in uppercase
            if (${OPENSSH} ne 'Y' &&  ${OPENSSH} ne 'N') {              # Check for valid values
               if ($DEBUG >= 5) { print "\nThe OPENSSH value in $SCOM_CFG_FILE is invalid (Y Assumed)" };
               ${OPENSSH} = 'Y' ;
            }
         }
         if ($scom_name eq 'MKDIR_REMOTE' ) {                           # If server type line
            $scom_value =~ s/^\s+|\s+$//g;                              # Remove trailing and ending spaces
            $MKDIR_REMOTE = $scom_value;                                # Set the MKDIR_REMOTE Value (Y/N)
            $MKDIR_REMOTE =~ tr/[a-z]/[A-Z]/;                           # Make sure server type is in uppercase
            if (${MKDIR_REMOTE} ne 'Y' &&  ${MKDIR_REMOTE} ne 'N') {
               if ($DEBUG >= 5) { print "\nThe MKDIR_REMOTE value of $SCOM_CFG_FILE is invalid (Y Assumed)" };
               ${MKDIR_REMOTE} = 'Y' ;
            }
         }

      }
      close SCOM_CONFIG_FILE;
      #######$MKDIR_REMOTE = "Y" ;   ####################### TEMP - CREATE DIR EVERY TIME SCRIPT IS RUN ############
   }
   if ($DEBUG >= 6) { print "\nThe Server Type is (P=Prod D=Dev) $SERVER_TYPE" };

   if ( $OPENSSH eq "Y" ) {                                    # For Linux Servers
#      $SSH_BIN = "/usr/bin/ssh ";                             # Default Location for OpenSSH Pgm
      $SCP_BIN = "/usr/bin/scp ";                              # Default Location for OpenSSH Pgm
   }else{                                                      # For AIX Servers
#      $SSH_BIN = "/usr/local/bin/ssh ";                       # Default Location for Tectia SSH Pgm
      $SCP_BIN = "/usr/local/bin/scp ";                        # Default Location for Tectia SSH Pgm
   }

# Determine on AIX if using V4 or V5 of Tectia product (Command line Option Different)
   if ( $OPENSSH eq "N" ) {
       if ($DEBUG >= 6) { print "\n-----\nDetermine version of Tectia SSH"; }
       $SSH_TMP="/tmp/ssh_version.txt"; 
       $COMMAND = "/usr/local/bin/ssh -V >$SSH_TMP 2>&1";
       if ($DEBUG >= 6) { print "\nCommand sent ${COMMAND}"; }
       @args = ("$COMMAND");
       system(@args) ;
       if ( $? == -1 ) {
             if ($DEBUG >= 6) { print "\ncommand failed: $!"; }
          }else{
             if ($DEBUG >= 6) { printf "\ncommand exited with value %d", $? >> 8; }
       }
       $COMMAND = "grep 'ssh: SSH Tectia' $SSH_TMP | awk '{ print \$5 }' | awk -F\. '{ print \$1 }'|";
       if ($DEBUG >= 6) { print "\nCommand sent ${COMMAND}"; }
       open (SSH_FILE, "${COMMAND}");
       $SSH_WS = <SSH_FILE> ; chop $SSH_WS ;  $SSH_VER = int $SSH_WS;
       close SSH_FILE;
       unlink "$SSH_TMP" ;
       if ( $SSH_VER == 0 ) {  $SSH_VER = 6 ; }
       if ($DEBUG >= 6) { print "\n Tectia SSH Version is : $SSH_VER"; }
       if ( $SSH_VER >= 5) {   # Tectia V5
           $SCOM_SCP  = "$SCP_BIN -rP 32 --checksum=no " ;}    # For Tectia V5 Need checksum option
   }


}



# THIS FUNCTION IS CALLED AT THE BEGINNING TO CREATE A LOCK FILE IN $SADM_BASE_DIR/SLAM.LOCK
# IF THE FILE ALREADY EXIST - WE GET THE TIMESTAMP OF THE FILE.
# IF IT WAS CREATED MORE THAN 5 MINUTES AGO, IT IS DELETED AND A NEW ONE IS CREATED.
# THE LOCK IS USED TO MAKE SURE THAT ONLY ONE INSTANCE OF SLAM IS RUNNING AT THE SMAE TIME.
# - ISSUE THE PS COMMAND ONCE THAT WILL BE USED FOR THE REST OF THE SCRIPT
# --------------------------------------------------------------------------------------------------
sub init_process {

   scom_mkdir ("$SLAMRPT_DIR")  ;                                       # Make sure dir exist
   scom_mkdir ("$SLAMTMP_DIR")  ;                                       # Make sure dir exist
   scom_mkdir ("$SLAMTXT_DIR")  ;                                       # Make sure dir exist
   scom_mkdir ("$SLAMTXT_DIR/app") ;                                    # Make sure dir exist
   scom_mkdir ("$SLAMTXT_DIR/ftp") ;                                    # Make sure dir exist
   scom_mkdir ("$SLAMTXT_DIR/was") ;                                    # Make sure dir exist
   scom_mkdir ("$SLAMTXT_DIR/dba") ;                                    # Make sure dir exist
   scom_mkdir ("$SLAMTXT_DIR/os")  ;                                    # Make sure dir exist
   scom_mkdir ("$SLAMTXT_DIR/pa")  ;                                    # Make sure dir exist
   scom_mkdir ("$SLAMTXT_DIR/mvs")  ;                                   # Make sure dir exist
   
   
# IF REALLY WANT TO PREVENT SLAM FROM RUNNING CREATE THIS FILE /TMP/SLAMLOCK.TXT
   if ( -e "/tmp/SLAMLOCK.TXT") { print "/tmp/SLAMLOCK.TXT Exist - SLAM not executed";exit 1;} 

# GET THE ALL THE VALUES FOR CURRENT TIME
#($SECOND, $MINUTE, $HOUR, $DAY, $MONTH, $YEAR, $WEEKDAY, $DAYOFYEAR, $ISDST) = LOCALTIME(TIME);
# IF LOCK FILE EXIST, CHECK IF IT IS THERE FOR MORE THAN 15 MINUTES, IF SO DELETE IT
   if ( -e "$SLAMLCK_FILE"  ) { 
       
      # Get the creation time of the lock file in epoch time
      ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat ($SLAMLCK_FILE);
      print "\nThe lockfile creation time in epoch time = $ctime";
      $creation_date = Date::EzDate->new($ctime);
      print "\nThe lockfile creation time is $creation_date";
      my $actual_date = Date::EzDate->new;
      $actual_epoch_time = $actual_date->{'%s'};      
      print "\nThe actual time in epoch time = $actual_epoch_time";
      print "\nThe actual time is $actual_date";
      my $elapse_time = ($actual_epoch_time - $ctime) ; 
      print "\nThe lock file was created $elapse_time seconds ago";
       
# 30 MINUTES X 60 SECONDS = 1800 SECONDS       
# IF LOCK FILE IS THERE FOR MORE THAN 1800 SECOND DELETE IT
      if ( $elapse_time >= 1800 ) {
         if ($DEBUG >= 5) { print "\nUpdating TimeStamp of Lock File $SLAMLCK_FILE" ; }
         #unlink "$SLAMLCK_FILE" ;
         #print "\nCreating lock file $SLAMLCK_FILE\n";
         @args = ("$CMD_TOUCH", "$SLAMLCK_FILE");
         system(@args) == 0   or die "system @args failed: $?";
      }else{
         print "\nLock file $SLAMLCK_FILE was create $elapse_time seconds ago - Slam maybe running ?\n";
         print "I will wait until the lock file is 1800 seconds old before deleting it.\n";
         exit 1;
      }    
   }else{
      #print "\nCreating lock file $SLAMLCK_FILE\n";
      @args = ("$CMD_TOUCH", "$SLAMLCK_FILE");
      system(@args) == 0   or die "system @args failed: $?";
   }



    # EXECUTE THE "PS" COMMAND AND OUTPUT THE RESULT TO A FILE
    if ( $OSNAME eq "linux" ) {
      @args = ("export COLUMNS=4096 ; ps -efwww  > $PSFILE1 ; export COLUMNS=80");
      system(@args) == 0   or print "ps 1 command Failed ! : $?";
      sleep(1);
      @args = ("export COLUMNS=4096 ; ps -efwww > $PSFILE2 ; export COLUMNS=80");
      system(@args) == 0   or print "ps 2 command Failed ! : $?";
      if ($DEBUG >= 6) {
         print "\n\n-----\nContent of PSFILE1\n" ;
         @args = ("cat $PSFILE1");
         system(@args) == 0   or print "Printing PSFILE1 failed ! : $?";
         print "\n\n-----\nContent of PSFILE2\n" ;
         @args = ("cat $PSFILE2");
         system(@args) == 0   or print "Printing PSFILE2 failed ! : $?";
      }
   }else{
      @args = ("export COLUMNS=4096 ; ps -ef > $PSFILE1 ; export COLUMNS=80");
      system(@args) == 0   or print "ps 1 command Failed ! : $?";
      @args = ("export COLUMNS=4096 ; ps -ef > $PSFILE2 ; export COLUMNS=80");
      system(@args) == 0   or print "ps 2 command Failed ! : $?";
   }
   
   
# UNDER LINUX CHECK TO SEE IF WE ARE RUNNING IN A VM (DO NOT CHECK FOR HP ERROR IF IN VM)
   if ( $OSNAME eq "linux" ) {
      $COMMAND = "$DMIDECODE | grep -i vmware >/dev/null 2>&1" ;
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
   




# E N D    O F    P R O C E S S I N G   
# --------------------------------------------------------------------------------------------------
sub end_of_process {

# Remove slam.lock file
   print "\n------------ \nDeleting lock file $SLAMLCK_FILE";
   unlink "$SLAMLCK_FILE" or die "Cannnot delete $SLAMLCK_FILE: $!\n" ;

# Delete PSFILE (contain ps command results)
   unlink "$PSFILE1" or die "Cannnot delete $PSFILE1: $!\n" ;
   unlink "$PSFILE2" or die "Cannnot delete $PSFILE2: $!\n" ;


# Print Ececution time
   if ($DEBUG >= 5) { 
      printf ("\n#SLAMSTAT $VERSION_NUMBER $HOSTNAME - %s - Execution Time %2.2f seconds\n", scalar localtime(time),$end_time - $start_time); 
   }
}


# WebSphere - Replace multiple WebSphere App. server down with one Error
# --------------------------------------------------------------------------------------------------
sub check_multiple_was_error {

   # Count the Number of WebSphere App. Not Running
   if ($DEBUG >= 5) { print "\n-----\nChecking How many WebSphere App. Server Error"};
   $WAS_STRING = "WebSphere App. Server";                # String to search in was.txt file
   $WAS_ERRCNT = 0;                                      # WebSphere App. Error Counter
   $MINCOUNT = 5;                                        # Min App. Down before summarize error
   $WAS_CMD = "grep -i \'$WAS_STRING\' $SCOM_WAS_FILE | wc -l |";
   if ($DEBUG >= 5) { print "\nRunning Command below\n $WAS_CMD"; };
   open (WASCOUNT,$WAS_CMD);
   while ($linew = <WASCOUNT>) {
      chomp $linew;
      $WAS_ERRCNT = $linew;                        
      }
   close WASCOUNT;
   if ($DEBUG >= 5) { printf "\nThe number of WebSphere App. not running is $WAS_ERRCNT" ; }
   
   
   # Delete multiple error in file and replace then with one error line.
   # Delete old SLAM config file and rename the temp file to SLAM config file
   # -----------------------------------------------------------------------------------------------
   if ( $WAS_ERRCNT > $MINCOUNT ) {                          # If more than 5 WebSphere App Down
      unlink "$SCOM_WAS_TMP" ;                               # Delete was temp file 
      if (!rename "$SCOM_WAS_FILE", "$SCOM_WAS_TMP") {       # Rename curr. was.txt to tmp/was.tmp
         print "\nCould not rename $SCOM_WAS_FILE to $SCOM_WAS_TMP: $!\n" ;
      }else{
         print "\nRenaming $SCOM_WAS_FILE to $SCOM_WAS_TMP\n" ;
      }
      system ("chmod 660 $SCOM_WAS_TMP");                    # Make sure file is read-write 
      open (SCOM_TMP, "<$SCOM_WAS_TMP")  or die "Can't open $SCOM_WAS_TMP:  $!\n";
      open (SCOM_WAS, ">$SCOM_WAS_FILE") or die "Can't open $SCOM_WAS_FILE: $!\n"; # Advise if can't create file
      while ($line = <SCOM_TMP>) {                           # Read while end of file
         if ($DEBUG >= 6) { print "Line read from $SCOM_WAS_TMP : $line" ; }
         next if $line =~ /WebSphere App. Server/ ;          # Don't Write WebSphere App. Error
         if ($DEBUG >= 6) { print "Line Written to new $SCOM_WAS_FILE : $line" ; }
         print (SCOM_WAS "${line}\n");                       # Add line to new was.txt file
      }
      $SLAM_RECORD->{SLAM_QPAGE} = "was"; 
      write_scom_file ('critical','WEBSPHERE','APP_SERVER',"More than $MINCOUNT WebSphere App. are down");
      close SCOM_WAS;
      unlink "$SCOM_WAS_TMP" or die "Cannnot delete $SCOM_WAS_TMP: $!\n" ;
   }
   
}




# UNLOAD THE UPDATED VERSION OF sysmon_array TO SLAM.CFG FILE
# --------------------------------------------------------------------------------------------------
sub loop_through_array {

# Loop Through All Slam.cfg File in Memory
   for ($index = 0; $index < @sysmon_array; $index++)                     # Treat each line one at a time
      {  
      next if $sysmon_array[$index] =~ /^#/ ;                             # Don't process comment line
      next if $sysmon_array[$index] =~ /^$/ ;                             # Don't process blank line
      split_fields($sysmon_array[$index]);                                # Split line into fields
      next if $SLAM_RECORD->{SLAM_ACTIVE} eq "N";                       # If line inactive skip line
      next if `date +%a` =~ /Sun/ && $SLAM_RECORD->{SLAM_SUN} =~ /N/ ;  # Skip if today=Sunday & Sunday inactivate
      next if `date +%a` =~ /Mon/ && $SLAM_RECORD->{SLAM_MON} =~ /N/ ;  # Skip if today=Monday & Monday inactivate
      next if `date +%a` =~ /Tue/ && $SLAM_RECORD->{SLAM_TUE} =~ /N/ ;  # Skip if today=Tuesday & Tuesday inactivate
      next if `date +%a` =~ /Wed/ && $SLAM_RECORD->{SLAM_WED} =~ /N/ ;  # Skip if today=Wednesday & Wednesday inactivate
      next if `date +%a` =~ /Thu/ && $SLAM_RECORD->{SLAM_THU} =~ /N/ ;  # Skip if today=Thursday & Thursday inactivate
      next if `date +%a` =~ /Fri/ && $SLAM_RECORD->{SLAM_FRI} =~ /N/ ;  # Skip if today=Friday & Friday inactivate
      next if `date +%a` =~ /Sat/ && $SLAM_RECORD->{SLAM_SAT} =~ /N/ ;  # Skip if today=Sat & Sat inactivate

# IF A START OR AN END TIME WAS SPECIFIED , WE NEED TO VERIFY IF THE LINE IS ACTIVE AT CURRENT TIME
      $evaluate_line="yes" ;                                            # Need to evaluate line ? Default = yes
      if ($SLAM_RECORD->{SLAM_STHRS} != 0 and $SLAM_RECORD->{SLAM_ENDHRS} != 0) {
         $current_time = `date +%H%M` ;                                 # Get current Time
         if ($SLAM_RECORD->{SLAM_ENDHRS} < $SLAM_RECORD->{SLAM_STHRS}) {
            if (($current_time > $SLAM_RECORD->{SLAM_STHRS})  || ($current_time < $SLAM_RECORD->{SLAM_ENDHRS})) { 
               $evaluate_line="yes"; 
            }else{
               $SLAM_RECORD->{SLAM_DATE} = 0; 
               $SLAM_RECORD->{SLAM_TIME} = 0; 
               $evaluate_line="no"; 
               $sysmon_array[$index] = combine_fields(); # Combine all fields & put it back into array 
            }   
         }else{
            if (($current_time >= $SLAM_RECORD->{SLAM_STHRS}) && ($current_time <= $SLAM_RECORD->{SLAM_ENDHRS})) { 
               $evaluate_line="yes"; 
            }else{ 
               $SLAM_RECORD->{SLAM_DATE} = 0; 
               $SLAM_RECORD->{SLAM_TIME} = 0; 
               $evaluate_line="no"; 
               $sysmon_array[$index] = combine_fields(); # Combine all fields & put it back into array 
            }
         }
      }
      next if $evaluate_line eq "no" ;
                
      if ($SLAM_RECORD->{SLAM_ID} =~ /^check_multipath/  )  {check_multipath ;}           # Check Linux Multipath State
      if ($SLAM_RECORD->{SLAM_ID} =~ /^check_hdlm/  )       {check_hdlm ;}                # Check Hitachi HDLM Status
      if ($SLAM_RECORD->{SLAM_ID} eq "tsm_aix_database")    {check_aix_tsm_db ;}          # Check Prod. TSM DataBase Usage
      if ($SLAM_RECORD->{SLAM_ID} eq "tsm_nov_database")    {check_novell_tsm_db ;}       # Check Dev.  TSM DataBase Usage
      if ($SLAM_RECORD->{SLAM_ID} eq "tsm_sched_missed")    {check_tsm_missed_schedule ;} # Check TSM Schedule missed
      if ($SLAM_RECORD->{SLAM_ID} eq "tsm_aix_databaselog") {check_aix_tsm_log ;}         # Check Prod. Recovery Log Usage
      if ($SLAM_RECORD->{SLAM_ID} eq "tsm_nov_databaselog") {check_novell_tsm_log ;}      # Check Dev.  Recovery Log Usage
      if ($SLAM_RECORD->{SLAM_ID} =~ /^tsm_drive/ )         {check_tsm_drive ;}           # Check TSM Drive Status
      if ($SLAM_RECORD->{SLAM_ID} =~ /^tsm_path/ )          {check_tsm_path ;}            # Check TSM Path Status
      if ($SLAM_RECORD->{SLAM_ID} eq "tsm_scratch")         {check_tsm_scratch ; }        # Check TSM number of scratch
      if ($SLAM_RECORD->{SLAM_ID} eq "aix_errpt")           {check_errpt ; }              # Check AIX Error Report
      if ($SLAM_RECORD->{SLAM_ID} eq "linux_hplog")         {check_hplog ;}               # Linux Specific Part - Check hplog
      if ($SLAM_RECORD->{SLAM_ID} =~ /^load_average/ )      {check_load_average ; }       # Load Average
      if ($SLAM_RECORD->{SLAM_ID} =~ /^cpu_level/ )         {check_cpu_usage ;  }         # Check CPU Usage
      if ($SLAM_RECORD->{SLAM_ID} eq "swap_space")          {check_swap_space ; }         # Check Swap Space
      if ($SLAM_RECORD->{SLAM_ID} =~ /^FS/ )                {check_filesystems_usage ;}   # Check filesystem usage
      if ($SLAM_RECORD->{SLAM_ID} =~ /^script/  )           {run_script ;}                # Check Running Script
      if ($SLAM_RECORD->{SLAM_ID} =~ /^daemon_/ )           {check_daemon; }              # Check if specified daemon is running
      if ($SLAM_RECORD->{SLAM_ID} =~ /^oracle_instance/ )   {check_oracle_instance; }     # Check Oracle Instance
      if ($SLAM_RECORD->{SLAM_ID} =~ /^db2i_/ )             {check_db2_instance; }        # Check DB2 Instance
      if ($SLAM_RECORD->{SLAM_ID} =~ /^websphere/ )         {check_websphere;   }         # Check WebSphere Applications
      if ($SLAM_RECORD->{SLAM_ID} =~ /^http/ )              {check_http;    }             # Check HTTP
      if ($SLAM_RECORD->{SLAM_ID} =~ /^sun-http/ )          {check_sun_http;  }           # Check SUN / iPlanet HTTP
      if ($SLAM_RECORD->{SLAM_ID} =~ /^cserv/ )             {check_cluster_services; }    # Check Cluster Services
      if ($SLAM_RECORD->{SLAM_ID} =~ /^mq_/ )               {check_mqseries; }            # Check MQseries Status
      if ($SLAM_RECORD->{SLAM_ID} =~ /^ping_/ )             {ping_ip; }                   # Check Ping an IP
      $sysmon_array[$index] = combine_fields() ;              # Combine all the fields into a line and put it back into the array 
   }
}


#                        M A I N    P R O G R A M    S T A R T   H E R E  !
# --------------------------------------------------------------------------------------------------
#
   init_process;                                         # Create lock file & do ps command to file
   $start_time = time;                                   # Starting time - To calculate elapse time.
   load_config_file;                                     # Load the slam.cfg file 
   load_slam_file;                                       # Load `hostname`.cfg file in memory into array
   load_df_in_array;                                     # Load the "df"  result in a array

# Open Output scom status text file for dba,os,was and pa
   open (SLAMRPT," >$SLAMRPT_FILE")  or die "Can't open $SLAMRPT_FILE: $!\n";  # Advise if can't create file
   open (SCOM_DBA,">$SCOM_DBA_FILE") or die "Can't open $SCOM_DBA_FILE: $!\n"; # Advise if can't create file
   open (SCOM_OS, ">$SCOM_OS_FILE")  or die "Can't open $SCOM_OS_FILE: $!\n";  # Advise if can't create file
   open (SCOM_PA, ">$SCOM_PA_FILE")  or die "Can't open $SCOM_PA_FILE: $!\n";  # Advise if can't create file
   open (SCOM_WAS,">$SCOM_WAS_FILE") or die "Can't open $SCOM_WAS_FILE: $!\n"; # Advise if can't create file
   open (SCOM_MVS,">$SCOM_MVS_FILE") or die "Can't open $SCOM_MVS_FILE: $!\n"; # Advise if can't create file
   open (SCOM_FTP,">$SCOM_FTP_FILE") or die "Can't open $SCOM_FTP_FILE: $!\n"; # Advise if can't create file
   open (SCOM_APP,">$SCOM_APP_FILE") or die "Can't open $SCOM_APP_FILE: $!\n"; # Advise if can't create file
   
# CHECK FOR NEW STUFF ON THE SERVER
   check_for_new_cluster_services;                       # Check for new cluster services
   check_for_new_filesystems;                            # Check for new filesystem first
   check_for_new_oracle_instance;                        # Check for new oracle instance
   check_for_new_websphere_appserver;                    # Check for new Web Sphere Application
   check_for_new_sun_http_site;                          # Check for SUN / iPlanet HTTP Server
   check_for_new_http_site;                              # Check for HTTP SErver
   check_for_new_db2_instance;                           # Check for new db2 instance

# PROCESS EACH LINE OF THE ARRAY (hostname.cfg file)
   loop_through_array;                                   # Loop through Slam Array line by line
   check_db2tab  ;                                       # Check /etc/db2tab and run dba script

# Close SLAM rpt file and SCOM Status files
   close SLAMRPT;                                        # Close report file 
   system ("chmod 644 $SLAMRPT_FILE");                   # Make file readable by everyone
   close SCOM_MVS;                                       # Close SCOM MVS Status file
   close SCOM_DBA;                                       # Close SCOM DBA Status file
   close SCOM_OS;                                        # Close SCOM OS Status file
   close SCOM_PA;                                        # Close SCOM PA Status file
   close SCOM_FTP;                                       # Close SCOM FTP Status file
   close SCOM_APP;                                       # Close SCOM APP Status file

# Check if file wasmon_p.txt file is present - if so merge it with was.txt file
   if ($DEBUG >= 5) { print "\n-----\nChecking presence of $SCOM_WASMON_FILE"};      
   if ( -e "$SCOM_WASMON_FILE") {
      if ($DEBUG >= 5) { print "\nThe $SCOM_WASMON_FILE exist, transfer content to $SCOM_WAS_FILE"};      
      open (FH_WASMON, "< $SCOM_WASMON_FILE") or die "Can't open $SCOM_WASMON_FILE: $!\n";
      while ($wasline = <FH_WASMON>) {                   # Read while end of file
         next if $wasline =~ /^#/ ;                      # Don't load comment line
         print (SCOM_WAS "${wasline}\n");                # Add line to was.txt file
         print "\nAdding $wasline to $SCOM_WAS_FILE";    # Print the line added
      }
      close FH_WASMON;                                   # Close SCOM WAS Status file
   }
   close SCOM_WAS;                                       # Close SCOM APP Status file



# PROCESS IS DONE - NEED TO UPDATE FILES AND COPY THEM TO OTHER SERVERS
   check_multiple_was_error;                             # Replace multiple was error line with one
   unload_slam_file;                                     # Unload Update Array to hostname.cfg file
   copyfile2scomserver;                                  # Copy result file to SCOM & Sysinfo
   copyfile2slamserver;                                  # Copy result file to Slamserver
   unload_config_file;                                   # Unload update slam.cfg file 
   end_of_process;                                       # Delete lock file - Print Elapse time

