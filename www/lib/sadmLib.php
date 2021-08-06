<?php
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadmlib.php
#   Version  :  1.0
#   Date     :  22 March 2016
#   Requires :  php
#   Synopsis :  This file is the PHP Library that's used by the SADMIN Web Interface
#
#   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
#   2016_03_16 - Jacques Duplessis
#       V1.0 Initial Version
#   2017_11_15 - Jacques Duplessis
#       V2.0 Restructure and modify to used to new web interface and MySQL Database.
#   2017_12_31 - Jacques Duplessis
#       V2.1 Include Function to update User Crontab (permit tun run O/s Update Schedule)
#   2018_01_04 - Jacques Duplessis
#       V2.2 Remove display_file function & Page footer now have default value for parameter
#   2018_04_17 - Jacques Duplessis
#       V2.3 Added 3 functions for Network Information (netinfo, mask2cidr and cidr2mask)
#   2018_04_17 - Jacques Duplessis
#       V2.4 Added getEachIpInRange Function that return list of IP in a CIDR
# 2019_01_11 Add: v2.5 CLicking on logo bring you back to sadmin Home page.
# 2019_01_21 v2.6 Add function from From Schedule to Text.
# 2019_02_16 Change: v2.7 Convert schedule metadata to one text line (Easier to read in Sched. List)
# 2019_04_04 Update: v2.8 Function SCHEDULE_TO_TEXT now return 2 values (Occurrence & Date of update)
# 2019_05_02 Update: v2.9 Function sadm_fatal_error - Insert back page link before showing alert.
# 2019_08_04 Update: v2.10 Added function 'sadm_show_logo' to show distribution logo in a table cell.
# 2019_08_13 Update: v2.11 Fix bug - When creating one line schedule summary
# 2019_08_14 Update: v2.12 Add function for new page header look (display_lib_heading).
# 2019_10_15 Update: v2.13 Reduce Logo size image from 32 to 24 square pixels
# 2019_10_15 Update: v2.14 Reduce font size on 2nd line of heading in "display_lib_heading".
# 2020_01_13 Update: v2.15 Reduce Day of the week name returned by SCHEDULE_TO_TEXT to 3 Char.
# 2020_04_27 Update: v2.16 Change 2019 to 2020 in page footer
# 2020_09_22 Update: v2.17 Facilitate going back to previous & Home page by adding button in header.
#@2021_08_05 web: v2.18 Add function "getdocurl($RefString)" to allow link from script to doc
#
# ==================================================================================================
#

#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG  = False ;                                                        # Debug Activated True/False
$LIBVER = "2.18" ;   
    

#===================================================================================================
# DISPLAY HEADING LINES OF THE WEB PAGE 
#===================================================================================================
function display_lib_heading($BACK_URL,$TITLE1,$TITLE2,$WVER) {

    $URL_HOME   = '/index.php';                                         # Site Home Page URL
    
    # SHOW HEADING LINE 1
    echo "\n<div style='float: left;'>";                                # Align Left Link Go Back
    if (strtoupper($BACK_URL) != "HOME") {                              # Parameter Recv. = home
        echo "<a href='javascript:history.go(-1)'>";                    # URL Go Back Previous Page
        echo "<span data-toggle='tooltip' title='Back to previous page'>";  # Show Tooltip 
        echo "<img src='/images/back_hand.png' ";                       # Show hand pointing left
        echo "style='width:32px;height:32px;'></span></a>";             # Size Icons 32x32
    }else{
        echo "<a href='" . $URL_HOME . "'>";                            # URL to Go Back Home Page
        echo "<span data-toggle='tooltip' title='Back to Home page'>";  # Show Tooltip 
        echo "<img src='/images/home.png' ";                            # Show Home Icon
        echo "style='width:32px;height:32px;'></span></a>";             # Size Icons 32x32
    }
    echo "</div>"; 
    echo "\n<div style='";
    echo "text-align: center ; color: #271c1c; ";
    echo "font-size: 1.8em; font-family: Verdana, sans-serif; ";
    echo "font-weight: bold; '>"; 
    echo "\n${TITLE1} " ."- v${WVER}";
    echo "\n</div>";
 
    # SHOW HEADING LINE 2
    if ($TITLE2 != "") {
        echo "\n<div style='";
        echo "text-align: center ; color: #271c1c; ";
        echo "font-size: 1.0em; font-family: Verdana, sans-serif; ";
        echo "font-weight: bold; '>"; 
        echo "${TITLE2}" ;   
        echo "\n</div>";
    }        

    # Space line for separation purpose
    echo "\n<hr/>";                                                     # Print Horizontal Line

   
}


# ==================================================================================================
#        Function called at every end of SADM web page (Close Database and end all std Div)
# ==================================================================================================
function std_page_footer($wcon="") {
    if ($wcon != "") { mysqli_close($wcon); }                           # Close Database Connection
    echo "\n</div> <!-- End of sadmRightColumn   -->" ;                 # End of Left Content Page       
    echo "\n</div> <!-- End of sadmPageContents  -->" ;                 # End of Content Page
    echo "\n\n<div id='sadmFooter'>";
    echo "\nCopyright &copy; 2015-2021 - www.sadmin.ca - Suggestions, Questions or Report a problem at ";
    echo '<a href="mailto:support@sadmin.ca">support@sadmin.ca</a></small>';
    echo "\n</div> <!-- End of Div sadmFooter -->";

    echo "\n\n</div> <!-- End of sadmWrapper       -->" ;                 # End of Real Full Page
    echo "\n<br>";
    echo "\n</body>";
    echo "\n</html>";
}



# ==================================================================================================
# Function accept an IP Address (Example: 192.168.1.5) and a Netmask (Example: 255.255.255.0)
# Function Return 4 Values - 1=Network IP, 2=First Usable IP, 3=Last Usable IP 4=Broadcast IP
# ==================================================================================================
function netinfo ($ip_address,$ip_nmask) {

    # convert ip addresses to long form
    $ip_address_long     = ip2long($ip_address);
    $ip_nmask_long       = ip2long($ip_nmask);
    # caculate network address
    $ip_net              = $ip_address_long & $ip_nmask_long;
    # caculate first usable address
    $ip_host_first       = ((~$ip_nmask_long) & $ip_address_long);
    $ip_first            = ($ip_address_long ^ $ip_host_first) + 1;
    # caculate last usable address
    $ip_broadcast_invert = ~$ip_nmask_long;
    $ip_last             = ($ip_address_long | $ip_broadcast_invert) - 1;
    # caculate broadcast address
    $ip_broadcast        = $ip_address_long | $ip_broadcast_invert;

    return array (long2ip($ip_net), long2ip($ip_first), long2ip($ip_last), long2ip($ip_broadcast));
}



# ==================================================================================================
# Function to convert a netmask (ex: 255.255.255.240) to a cidr mask (ex: 28):
# Example: mask2cidr('255.255.255.0') would return 24 
# ==================================================================================================
function mask2cidr($wmask)
{
    $long = ip2long($wmask);
    $base = ip2long('255.255.255.255');
    return 32-log(($long ^ $base)+1,2);
}



# ==================================================================================================
# Function to convert a CIDR (Example: 24) to Netmask (Example: 255.255.255.000) 
# Example: cidr2netmask(23) would return 255.255.254.0 ; 
# ==================================================================================================
function cidr2mask($cidr) {
    static $max_ip;
    if (!isset($max_ip))                                                # Make sure max_ip is set
        $max_ip = ip2long('255.255.255.255');                           # Set maximum NetMask
    if ($cidr < 0 || $cidr > 32)                                        # Validate CIDR 
        return NULL;                                                    # Return NULL if invalid
    $subnet_long = $max_ip << (32 - $cidr);                             # Calculate netmask
    return long2ip($subnet_long);                                       # Return NetMask
}



# ==================================================================================================
# Function getEachIpInRange return an array of ip address in CIDR Received (Ex: '192.168.1.0/24')
# (Function getIpRange is used by getEachIpInRange)
# ==================================================================================================
function getIpRange($cidr) {
    list($ip, $mask) = explode('/', $cidr);
    $maskBinStr =str_repeat("1", $mask ) . str_repeat("0", 32-$mask );      //net mask binary string
    $inverseMaskBinStr = str_repeat("0", $mask ) . str_repeat("1",  32-$mask ); //inverse mask

    $ipLong = ip2long( $ip );
    $ipMaskLong = bindec( $maskBinStr );
    $inverseIpMaskLong = bindec( $inverseMaskBinStr );
    $netWork = $ipLong & $ipMaskLong; 

    $start = $netWork+1;//ignore network ID(eg: 192.168.1.0)
    $end = ($netWork | $inverseIpMaskLong) -1 ; //ignore brocast IP(eg: 192.168.1.255)
    return array('firstIP' => $start, 'lastIP' => $end );
}

function getEachIpInRange ($cidr) {
    $ips = array();
    $range = getIpRange($cidr);
    for ($ip = $range['firstIP']; $ip <= $range['lastIP']; $ip++) {
        $ips[] = long2ip($ip);
    }
    return $ips;
}



# ==================================================================================================
#                      Update the crontab based on the $paction parameter
#
#   pscript  The name of the script to execute (With NO path - Need to be in $SADMIN/bin)
#   pname    The hostname of the server to include/modify/delete in crontab
#   paction  [C] for create entry  [U] for Updating the crontab   [D] Delete crontab entry
#   pmonth   13 Characters (either a Y or a N) each representing a month (YNNNNNNNNNNNN)
#            Position 0 = Y Then ALL Months are Selected
#            Position 1-12 represent the month that are selected (Y or N)             
#            Default is YNNNNNNNNNNNN meaning will run every month 
#   pdom     32 Characters (either a Y or a N) each representing a day (1-31) Y=Update N=No Update
#            Position 0 = Y Then ALL Date in the month are Selected
#            Position 1-31 Indicate (Y) date of the month that script will run or not (N)
#   pdow     8 Characters (either a Y or a N) 
#            If Position 0 = Y then will run every day of the week
#            Position 1-7 Indicate a week day () Starting with Sunday
#            Default is all Week (YNNNNNNN)
#   phour    Hour when the update should begin (00-23) - Default 1am
#   pmin     Minute when the update will begin (00-50) - Default 5min
#
# Example of line generated
#  +---------------- minute (0 - 59)
#  |  +------------- hour (0 - 23)
#  |  | +----------- date of month (1 - 31)
#  |  | | +--------- month (1 - 12)
#  |  | | |  +------ day of week (0 - 6) (Sunday=0 or 7)
#  |  | | |  | User |Command to execute  
# 15 04 * * 06 root /sadmin/bin/sadm_osupdate_farm.sh -s nano >/dev/null 2>&1
# ==================================================================================================
#
function update_crontab ($pscript,$paction = "U",$pmonth = "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN",
                        $pdom = "YNNNNNNNNNNNN",$pdow="NNNNNNNY",$phour=01,$pmin=00) {

    # To Display Parameters received - Used for Debugging Purpose ----------------------------------
    if ($DEBUG) { 
        echo "<BR>I'm in update crontab" ; 
        $wmsg1 = "\npscript = " . $pscript ;                            # Script to execute
        $wmsg2 = "\npaction = " . $paction ;                            # U=Update C=Create D=Delete
        $wmsg3 = "\npmonth  = " . $pmonth ;                             # Month String YNYNYNYNYNY..
        $wmsg4 = "\npdom    = " . $pdom;                                # Day of MOnth String YNYN..
        $wmsg5 = "\npdow    = " . $pdow;                                # Day of Week String YNYN...
        $wmsg6 = "\nphour   = " . $phour;                               # Hour to run script
        $wmsg7 = "\npmin    = " . $pmin;                                # Min. to run Script
        $wmsg  = $wmsg1.$wmsg2.$wmsg3.$wmsg4.$wmsg5.$wmsg6.$wmsg7 ;     # Combine information
        sadm_alert ($wmsg) ;                                            # Display Alert with Info
        #return ;
    } 
    
    # Begin constructing our crontab line ($cline) - Based on Hour and Min. Received ---------------
    $cline = sprintf ("%02d %02d ",$pmin,$phour);                       # Hour & Min. of Execution

    # Construct Date of the month (1-31) to run and add it to crontab line ($cline) ----------------
    if ($pdom == "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN") {                  # If it's to run every Date
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Date 
        $cdom = "";                                                     # Clear Work Variable
        for ($i = 1; $i < 32; $i = $i + 1) {                            # Check for Y or N in DOM
            if (substr($pdom,$i,1) == "Y") {                            # If Yes to run that Date
                if (strlen($cdom) == 0) {                               # And first date to add
                    $cdom = sprintf("%02d",$i);                         # Add Date number 
                }else{                                                  # If not 1st month in list
                    $cdom = $cdom . "," . sprintf("%02d",$i);           # More Date add , before
                }
            }    
        }
        $cline = $cline . $cdom . " " ;                                 # Add DOM in Crontab Line
    }
    
    # Construct the month(s) (1-12) to run and add it to crontab line ($cline) ---------------------
    if ($pmonth == "YNNNNNNNNNNNN") {                                   # If it's to run every Month
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Months
        $cmonth = "";                                                   # Clear Work Variable
        for ($i = 1; $i < 13; $i = $i + 1) {                            # Check for Y or N in Month
            if (substr($pmonth,$i,1) == "Y") {                          # If Yes to run that month
                if (strlen($cmonth) == 0) {                             # And first month to add
                    $cmonth = sprintf("%02d",$i);                       # Add month number 
                }else{                                                  # If not 1st month in list
                    $cmonth = $cmonth . "," . sprintf("%02d",$i);       # More Mth add , before Mth
                }
            }    
        }
        $cline = $cline . $cmonth . " " ;                               # Add Month in Crontab Line
    }
    
    # Construct the day of the week (0-6) to run and add it to crontab line ($cline) ---------------
    if ($pdow == "YNNNNNNN") {                                          # If it's to run every Day
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Day
        $cdow = "";                                                     # Clear Work Variable
        for ($i = 1; $i < 8; $i = $i + 1) {                             # Check for Y or N in Week
            if (substr($pdow,$i,1) == "Y") {                            # If Yes to run that Day
                if (strlen($cdow) == 0) {                               # And first add day of week
                    $cdow = sprintf("%02d",$i-1);                       # Add Day number 
                }else{                                                  # If not 1st Day in list
                    $cdow = $cdow . "," . sprintf("%02d",$i-1);         # More Day add , before Day
                }
            }    
        }
        $cline = $cline . $cdow . " " ;                                 # Add Month in Crontab Line
    }
    
    # Add User, script name and script parameter to crontab line -----------------------------------
    # SCRIPT WILL RUN ONLY IF LOCATED IN $SADMIN/BIN
    #$cline = $cline.SADM_USER." sudo ".SADM_BIN_DIR."/".$pscript." >/dev/null 2>&1\n";   
    $cline = $cline . " root " . SADM_BIN_DIR . "/" . $pscript . " >/dev/null 2>&1\n";   
    if ($DEBUG) { echo "\n<br>Final crontab line : " . $cline ; }       # Debug Show crontab line
   
    # Opening what will become the new crontab file ------------------------------------------------
    $newtab = fopen(SADM_WWW_TMP_FILE3,"w");                            # Create new Crontab File
    if (! $newtab) {                                                    # If Create didn't work
        sadm_fatal_error ("Can't create file " . SADM_WWW_TMP_FILE3) ;  # Show Err & Back Prev. Page
    } 

    # Write Crontab File Header --------------------------------------------------------------------
    $wline = "# Please don't edit manually, SADMIN generated file ". date("Y-m-d H:i:s") ."\n"; 
    fwrite($newtab,$wline);                                             # Write SADM Cron Header
    fwrite($newtab,"# \n");                                             # Write Comment Line
    fwrite($newtab,"SADMIN=".SADM_BASE_DIR."\n");                       # Write SADMIN Dir. Location
    fwrite($newtab,"# \n");                                             # Write Comment Line

    # Open existing crontab File - If don't exist create empty one ---------------------------------
    if (!file_exists(SADM_CRON_FILE)) {                                 # SADM crontab doesn't exist
        touch(SADM_CRON_FILE);                                          # Create empty crontab file
        chmod(SADM_CRON_FILE,0640);                                     # Set Permission on crontab
    }

    # Load actual crontab in array and process each line in array ----------------------------------
    $alines = file(SADM_CRON_FILE);                                     # Load Crontab in Array
    $UPD_DONE = False;                                                  # AutoUpdate was Off now ON?
    foreach ($alines as $line_num => $line) {                           # Process each line in Array
        if ($DEBUG) { echo "\n<br>Before Processing Ligne #{$line_num} : " . $line ; }        
        if (strpos(trim($line), '#') === 0) continue;                   # Next line if comment
        if (strpos(trim($line), 'SADMIN=') === 0) continue;             # Next line if SADMIN Env.
        $line = trim($line);                                            # Trim Crontab Line
        $wpos = strpos($line,$pscript);                                 # Get Pos. of script on line
        if ($wpos == false) {                                           # If Script is not on line
            fwrite($newtab,${line}."\n");                               # Write line to new crontab
        }else{                                                          # If script to Upd or Del
            continue;                                                   # Line Match then skip it
        }    
    }
    if ($paction == 'C') { fwrite($newtab,$cline); }                    # Add new line to crontab 
    if ($paction == "U") { fwrite($newtab,$cline); }                    # Add Update line to crontab 
    fclose($newtab);                                                    # Close sadm new crontab
    if (! copy(SADM_WWW_TMP_FILE3,SADM_CRON_FILE)) {                    # Copy new over existing 
        sadm_fatal_error ("Error copying " . SADM_WWW_TMP_FILE3 . " to " . SADM_CRON_FILE . " ");
    }
    unlink(SADM_WWW_TMP_FILE3);                                         # Delete Crontab tmp file
}



# ==================================================================================================
#          Function to Calculate the OS Update Time Based on Parameters Received
# ==================================================================================================
function calculate_osupdate_date($W1stMth,$WFreq,$Week1,$Week2,$Week3,$Week4,$WUpdDay) {
    
    $DEBUG = True ;                                   # Activate (TRUE) or Deactivate (FALSE) Debug

    if ($DEBUG) {
        echo "\nFirst Month is ";    
        echo "\nFrequency is ";    
        echo "\nWeek1 is ";    
        echo "\nWeek2 is ";    
        echo "\nWeek3 is ";    
        echo "\nWeek4 is ";    
        echo "\nUpdate Day is ";     
    }
    
    # !st Get Current Date Information
    $CurDay  = "";
    $CurMth  = "";
    $CurYear = ""; 
    if ($DEBUG) { echo "CurDay is ".$CurDay . " CurMth is ".$CurMth . " CurYear is ".$CurYear; }
    
    return $UPD_DATE;
}



# ==================================================================================================
#               Popup Message received as parameter and wait for OK to be pressed
# ==================================================================================================
function sadm_confirm($msg) {
    $message = preg_replace("/\r?\n/", "\\n", addslashes($msg));
    echo "<a href='http://stackoverflow.com'";
    echo "onclick=\"return confirm('Are you sure?');\">My Link</a>";
    // echo "\n<script type=\"text/javascript\">";
    // $reponse = "\nwindow.confirm(\"$message\");";
    // echo "\n</script>\n";
    // return $reponse;
    
    // echo $Confirmation;
    // if ($Confirmation == true) {
    //     your code goes here
    // }
    // $message = preg_replace("/\r?\n/", "\\n", addslashes($msg));
    // echo "\n<script type=\"text/javascript\">";
    // echo "\nvar stay=confirm(\"$message\")";
    // #document.getElementById("demo").innerHTML = x;
    // echo "\n</script>\n";
    // return $reponse;
}



# ==================================================================================================
# Popup with the Error Message wait for 5 seconds and return to previous page
# ==================================================================================================
function sadm_fatal_error($msg) {
    $message = preg_replace("/\r?\n/", "\\n", addslashes($msg));
    echo "<a href='javascript:history.go(-1)'>Click to go back to previous page</a>";   
    echo "\n<script type=\"text/javascript\">";
    echo "\n alert(\"$message\");";
    echo "\n windows.history.back()";
    echo "\n</script>\n";
}



# ==================================================================================================
# Display Popup Message received and wait for User to press OK Button
# ==================================================================================================
function sadm_alert($msg) {
    $message = preg_replace("/\r?\n/", "\\n", addslashes($msg));
    echo "\n<script type=\"text/javascript\">";
    echo "\nalert(\"$message\");";
    echo "\n</script>\n";
}


# ==================================================================================================
#                        Transform date (DD/MM/YYY) into MYSQL format
# ==================================================================================================
function DDMMYYYY_2_mysqldate( $input_date ) {
    $date_array = explode("/",$input_date);
    $mysql_date = $date_array[2] . '/' . $date_array[1] . '/' . $date_array[0] . " 00:00:00";
    return $mysql_date ;
}


// ================================================================================================
//           Transform MYSQL date (YYYY/MM/DD HH:MM:SS) format into user format (DD/MM/YYY)
// ================================================================================================
function mysql_date_2_DDMMYYYY( $mysql_date ) {
    $wyear  = substr($mysql_date, 0, 4);
    $wmonth = substr($mysql_date, 5, 2);
    $wday   = substr($mysql_date, 8, 2);
    $input_date = $wday . '/' . $wmonth . '/' . $wyear ;
    return $input_date ;
}



# ==================================================================================================
# Show Distribution Logo as a cell in a table
# ==================================================================================================
function sadm_show_logo($WOS) {

    switch (strtoupper($WOS)) {
        case 'REDHAT' :
            echo "<td class='dt-center'>";
            echo "<a href='http://www.redhat.com' ";
            echo "title='Server $whost is a RedHat server - Visit redhat.com'>";
            echo "<img src='/images/logo_redhat.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'FEDORA' :
            echo "<td class='dt-center'>";
            echo "<a href='https://getfedora.org' ";
            echo "title='Server $whost is a Fedora server - Visit getfedora.org'>";
            echo "<img src='/images/logo_fedora.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'MACOSX' :
            echo "<td class='dt-center'>";
            echo "<a href='https://apple.com' ";
            echo "title='Server $whost is an Apple System - Visit apple.com'>";
            echo "<img src='/images/logo_apple.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'CENTOS' :
            echo "<td class='dt-center'>";
            echo "<a href='https://www.centos.org' ";
            echo "title='Server $whost is a CentOS server - Visit centos.org'>";
            echo "<img src='/images/logo_centos.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'UBUNTU' :
            echo "<td class='dt-center'>";
            echo "<a href='https://www.ubuntu.com/' ";
            echo "title='Server $whost is a Ubuntu server - Visit ubuntu.com'>";
            echo "<img src='/images/logo_ubuntu.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'LINUXMINT' :
            echo "<td class='dt-center'>";
            echo "<a href='https://linuxmint.com/' ";
            echo "title='Server $whost is a LinuxMint server - Visit linuxmint.com'>";
            echo "<img src='/images/logo_linuxmint.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'DEBIAN' :
            echo "<td class='dt-center'>";
            echo "<a href='https://www.debian.org/' ";
            echo "title='Server $whost is a Debian server - Visit debian.org'>";
            echo "<img src='/images/logo_debian.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'RASPBIAN' :
            echo "<td class='dt-center'>";
            echo "<a href='https://www.raspbian.org/' ";
            echo "title='Server $whost is a Raspbian server - Visit raspian.org'>";
            echo "<img src='/images/logo_raspbian.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'SUSE' :
            echo "<td class='dt-center'>";
            echo "<a href='https://www.opensuse.org/' ";
            echo "title='Server $whost is a OpenSUSE server - Visit opensuse.org'>";
            echo "<img src='/images/logo_suse.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        case 'AIX' :
            echo "<td class='dt-center'>";
            echo "<a href='http://www-03.ibm.com/systems/power/software/aix/' ";
            echo "title='Server $whost is an AIX server - Visit Aix Home Page'>";
            echo "<img src='/images/logo_aix.png' ";
            echo "style='width:24px;height:24px;'></a></td>\n";
            break;
        default:
            echo "<td class='dt-center'>";
            echo "<img src='/images/logo_linux.png' style='width:32px;height:32px;'>";
            echo "${WOS}</td>\n";
            break;
    }
}




// ================================================================================================
//  Calculate elepsed time between two times value passed as arguments
//  Parameters are in this format HH:MM:SS in 24 hours format - Will return difference in HH:MM:
// ================================================================================================
function time_difference ( $wstart, $wend)
{
    #echo "<br>Start $wstart End $wend";
    list ($shour, $smin,   $ssec) = split(":", $wstart, 3);
    $wtime1 = ($shour*60*60)+ ($smin*60) + $ssec;

    list ($ehour, $emin,   $esec) = split(":", $wend, 3);
    $wtime2 = ($ehour*60*60)+ ($emin*60) + $esec;

    #echo "<br>Time 2 = $wtime2 Time 1 = $wtime1 Difference = " . ($wtime2 -$wtime1) . "<br>" ;
    $TOTAL_SEC = $wtime2 - $wtime1 ;

    #echo "<BR>Total Sec before is $TOTAL_SEC";
    if ($TOTAL_SEC < 0) { $TOTAL_SEC = ((24*60*60) - $wtime1) + $wtime2 ;}
    #echo "<BR>Total Sec after is $TOTAL_SEC";

    $fhrs = 0 ;
    if ($TOTAL_SEC > 3600) {
        $fhrs = intval($TOTAL_SEC/3600);
        $WORK = trim($TOTAL_SEC - ($fhrs*3600));
        $TOTAL_SEC = $WORK;
    }
    $HOURS = sprintf("%02d",number_format( $fhrs,0 ));
    $fmin = 0 ;
    if ($TOTAL_SEC > 60  ) {
        $fmin = intval($TOTAL_SEC/60) ;
        $WORK = trim($TOTAL_SEC - ($fmin*60)) ;
        $TOTAL_SEC = $WORK;
    }
    $MIN = sprintf("%02d",number_format($fmin,0));
    $fsec = $TOTAL_SEC ;
    $SEC = sprintf("%02d",number_format($fsec,0));
    $DUREE = $HOURS . ":" . $MIN . ":" . $SEC ;
    return ($DUREE);
}


// ================================================================================================
//                  Simple form to accept the server name and function to perform
// ================================================================================================
function accept_key($server_key) {
    echo "<form action='' method='POST'>";
    echo '<br><table frame="border" bgcolor="99FF66" border="0" cellspacing="2" width="600">';
    echo '<tr bgcolor="99FF66"><td valign="bottom" width=150 align=left><b>Server name</b></td>';
    echo '<td><input type="text" name="server_key" size="12" value="" /></td>';
    //echo "<td><input type='submit' value='Submit'/><a href='server_list.php'></td>";
    //echo '<td><input type="button" value="Google" onClick="window.location="http://www.google.com" /></td>';
    echo '<td><a href=server_create.php?id="$server_key"><button name="test" value=0 type="button">Create</button></td>';
    echo "<td><button name='create' value='0' type='button'>Create</button></td>";
    echo "<td><button name='query'  value='0' type='button'>Query </button></td>";
    echo "<td><button name='modify' value='0' type='button'>Modify</button></td>";
    echo "<td><button name='delete' value='0' type='button'>Delete</button></td>";
    echo "<td><button name='exit'   value='0' type='button'>Exit  </button></td>";
    echo '</tr><tr><td colspan="7" height="20" >Enter the server name you wish to to Create, Modify, Query or Delete & press corresponding button.</td></tr>';
    echo '<tr><td colspan=7><hr></td></tr></table>';
    echo '</form>';
}


#===================================================================================================
# Convert Data for a schedule to one line text
# wdom =  Date of the month the schedule will run, value receive is a string of 32 Char. 
#         32 Characters (either a Y or a N) each representing a day (1-31) Y=Update N=No Update
#            Position 0 = Y Then ALL Date in the month are Selected
#            Position 1-31 Indicate (Y) date of the month that script will run or not (N)
# wmth =  13 Characters (either a Y or a N) each representing a month (YNNNNNNNNNNNN)
#           Position 0 = Y Then ALL Months are Selected
#           Position 1-12 represent the month that are selected (Y or N)             
#           Default is YNNNNNNNNNNNN meaning will run every month 
# wdow =  8 Characters (either a Y or a N) 
#            If Position 0 = Y then will run every day of the week
#            Position 1-7 Indicate a week day () Starting with Sunday
#            Default is all Week (YNNNNNNN)
# whrs    Hour when the update should begin (00-23) - Default 1am
# wmin    Minute when the update will begin (00-50) - Default 5min
#
# The function return 2 Values:
#  First one is a string that specify when (Day,Time) and at what repetition the schedule occurs.
#       Example of string returned : "Every Wednesday at 01:15"
#  Second one is also a string containing the date and time the next O/S update will occur.
#       Example of string returned : "2019-04-03 22:00"
#===================================================================================================
function SCHEDULE_TO_TEXT($wdom,$wmth,$wdow,$whrs,$wmin)
{

    # Variables used to construct the next O/S Update Date
    $sdate    = "";                                                     # Sel Day (1,3,31) empty now
    $smth     = "";                                                     # Selected Mth empty for now
    $sday     = "";                                                     # Selected Day empty for now
    $selhrs   = sprintf("%02d", $whrs);                                 # Save & Format Selected Hrs
    $selmin   = sprintf("%02d", $wmin);                                 # Save & Format Selected Min
    $seltime  = "${selhrs}:${selmin}";                                  # Store Hrs:Min for
    $curday   = sprintf("%02d", date("d"));                             # Get Current Date
    $curmth   = sprintf("%02d", date("m"));                             # Get Current Month
    $curyear  = sprintf("%04d", date("Y"));                             # Get Current Year
    $curepoch = time();                                                 # Current Epoch Time
    $selday   = $curday; $selmth=$curmth ; $selyear=$curyear;           # Set Default Selection Date

    # Date in the month the Backup Schedule will run 
    # If any date part1 and sdate will be empty or sdate contains (Ex: 1,4,8) & part1 (1st,4th,8th)
    $part1 = "";                                                        # Default no particular date 
    if (substr($wdom,0,1) != "Y") {                                     # If DOM don't begin with Y
        for ($i = 1; $i < 32; $i = $i + 1) {
            if ((substr($wdom,$i,1) == "Y") && ($i == 1)) {             # Is First Month is Yes
                $part1 = $part1 . "1st," ;                              # Insert 1st, in part1
                $sdate="${sdate}1,";                                    # Insert 1 in Selected Date
            }
            if ((substr($wdom,$i,1) == "Y") && ($i == 2)) {             # Is Second Month is Yes
                $part1 = $part1 . "2nd," ;                              # Insert 2nd, in part1
                 $sdate="${sdate}2,";                                   # Insert 2 in Selected Date
            }
            if ((substr($wdom,$i,1) == "Y") && ($i == 3)) {             # Is Third Month is Yes
                $part1 = $part1 . "3rd," ;                              # Insert 3rd, in part1
                $sdate="${sdate}3,";                                    # Insert 3 in Selected Date
            }
            if ((substr($wdom,$i,1) == "Y") && ($i > 3))  {             # For all months > than 3
                $part1 = $part1 . $i . "th," ;                          # Insert day number  + "th,"
                $sdate="${sdate}$i,";                                   # Insert Day Number in sdate
            }
        }
        $part1 = rtrim($part1, ',') ;                                   # Del part1 trailing Comma 
        $sdate = rtrim($sdate, ',') ;                                   # Del sdate trailing Comma
        if ($part1 != "") { $part1 = $part1 . " of " ; }                # At least one date specify
    }


    # Month(s) that the Schedule Backup will Run
    #   part2 will contains the months names (Jan,Apr,Aug) or nothing if every month (if 1st Char=Y)
    #   smonth will contains the months selected (1,4,8) or nothing if every month is selected
    $part2 = "";                                                        # Default run every months
    $mth_name = array('every month,','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
    if (substr($wmth,0,1) == "Y") {                                     # 1st Letter is Y=EveryMonth
        if ($part1 != "") { $part2 = $mth_name[0]; }                    # Any Mth ins. "every month"
    }else{                                                              # If Month No. is Specify
        for ($i = 1; $i < 13; $i = $i + 1) {                            # Loop through the 12 Months
            if (substr($wmth,$i,1) == "Y") {                            # If month=Y=Selected
                $part2 = $part2 . $mth_name[$i] . "," ;                 # Insert Mth Name in Part2
                $smth  = $smth . $i . ",";                              # Insert Mth Num in Sel. Mth
            }
        }
    }
#    $part2 = rtrim($part2,',') . " " ;                                  # Del part2 trailing Comma
    $part2 = rtrim($part2,',') ;                                  # Del part2 trailing Comma
    $smth  = rtrim($smth, ',') ;                                        # Del smth trailing Comma
    
   
    #echo "wdom= " . substr($wdom,0,1) . " - wmth = " . substr($wmth,0,1) . " - wdow= " . substr($wdow,0,1) ;
    #echo "Part1 = $part1 - Part2 = $part2 - Part3 = $part3" ;
    
    # Days of the week the schedule will run
    if ((substr($wdom,0,1) == "Y") and (substr($wmth,0,1) == "Y")) { 
        $part2 = "Every "; $part3 = ""; 
        if (substr($wdow,0,1) == "Y") {                                 # If DOW begin with Y=AllWeek
            $part3 = " day"; 
        }else{                                                          # If not Get Days it Run
            #if (substr($wdow,1,1) == "Y") { $part3 = $part3 . "Sunday,"    ;  $sday="1,"; }
            #if (substr($wdow,2,1) == "Y") { $part3 = $part3 . "Monday,"    ;  $sday = $sday . "2," ;}
            #if (substr($wdow,3,1) == "Y") { $part3 = $part3 . "Tuesday,"   ;  $sday = $sday . "3," ;}
            #if (substr($wdow,4,1) == "Y") { $part3 = $part3 . "Wednesday," ;  $sday = $sday . "4," ;}
            #if (substr($wdow,5,1) == "Y") { $part3 = $part3 . "Thursday,"  ;  $sday = $sday . "5," ;}
            #if (substr($wdow,6,1) == "Y") { $part3 = $part3 . "Friday,"    ;  $sday = $sday . "6," ;}
            #if (substr($wdow,7,1) == "Y") { $part3 = $part3 . "Saturday,"  ;  $sday = $sday . "7," ;}
            if (substr($wdow,1,1) == "Y") { $part3 = $part3 . "Sun," ;  $sday="1,"; }
            if (substr($wdow,2,1) == "Y") { $part3 = $part3 . "Mon," ;  $sday = $sday . "2," ;}
            if (substr($wdow,3,1) == "Y") { $part3 = $part3 . "Tue," ;  $sday = $sday . "3," ;}
            if (substr($wdow,4,1) == "Y") { $part3 = $part3 . "Wed," ;  $sday = $sday . "4," ;}
            if (substr($wdow,5,1) == "Y") { $part3 = $part3 . "Thu," ;  $sday = $sday . "5," ;}
            if (substr($wdow,6,1) == "Y") { $part3 = $part3 . "Fri," ;  $sday = $sday . "6," ;}
            if (substr($wdow,7,1) == "Y") { $part3 = $part3 . "Sat," ;  $sday = $sday . "7," ;}
        }
    }else{
        $part3=""; 
    }
    $part3 = rtrim($part3, ',') ." " ;                                  # Del part3 trailing Comma
    $sday  = rtrim($sday, ',');                                         # Del sday trailing Comma
    

    # Part4 is the hours and minutes of the schedule, just format them and put them in part4.
    $part4a = sprintf("%02d", $whrs);
    $part4b = sprintf("%02d", $wmin);
    $part4 = "at ${part4a}:${part4b}";

    # Combine the Four part to define the schedule event occurence 
    #print ("1=" . $part1 . " 2=". $part2 . " 3=".$part3 . " 4=".$part4);
    $event_occurence = "$part1" . "$part2" . "$part3" . "$part4";
    
    # Now let's construct the date and time of the next O/S Update.
    #print ("<br>sdate='" . $sdate . "' smth='". $smth . "' sday='" .$sday . "' seltime='".$seltime."'");
    if (($sdate == "") and ($smth == "") and ($sday == "")) {
        $update_date_time = date('Y-m-d', strtotime('tomorrow'))        . " $seltime";
        return array ($event_occurence , $update_date_time) ;
    }

    if (($sdate == "") and ($smth == "")) { 
        $aday = array ($sday);
        foreach($aday as $wday)                                        # Process each Date Selected
            {
                $pos = strpos($wday,"1") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Sunday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Sunday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Sunday'));            # Day of next update
                    $tepoch = mktime($whrs, $wmin, 0, $tmonth, $tdate, $tyear);
                    if ($tepoch >= $curepoch) {
                        $update_date_time = date('Y-m-d', strtotime('next Sunday'))    . " $seltime";
                        return array ($event_occurence , $update_date_time) ;
                    }
                }
                $pos = strpos($wday,"2") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Monday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Monday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Monday'));            # Day of next update
                    $tepoch = mktime($whrs, $wmin, 0, $tmonth, $tdate, $tyear);
                    if ($tepoch >= $curepoch) {
                        $update_date_time = date('Y-m-d', strtotime('next Monday'))    . " $seltime";
                        return array ($event_occurence , $update_date_time) ;
                    }
                }
                $pos = strpos($wday,"3") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Tuesday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Tuesday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Tuesday'));            # Day of next update
                    $tepoch = mktime($whrs, $wmin, 0, $tmonth, $tdate, $tyear);
                    if ($tepoch >= $curepoch) {
                        $update_date_time = date('Y-m-d', strtotime('next Tuesday'))    . " $seltime";
                        return array ($event_occurence , $update_date_time) ;
                    }
                }
                $pos = strpos($wday,"4") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Wednesday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Wednesday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Wednesday'));            # Day of next update
                    $tepoch = mktime($whrs, $wmin, 0, $tmonth, $tdate, $tyear);
                    if ($tepoch >= $curepoch) {
                        $update_date_time = date('Y-m-d', strtotime('next Wednesday'))    . " $seltime";
                        return array ($event_occurence , $update_date_time) ;
                    }
                }
                $pos = strpos($wday,"5") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Thursday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Thursday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Thursday'));            # Day of next update
                    $tepoch = mktime($whrs, $wmin, 0, $tmonth, $tdate, $tyear);
                    if ($tepoch >= $curepoch) {
                        $update_date_time = date('Y-m-d', strtotime('next Thursday'))    . " $seltime";
                        return array ($event_occurence , $update_date_time) ;
                    }
                }                                                
                $pos = strpos($wday,"6") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Friday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Friday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Friday'));            # Day of next update
                    $tepoch = mktime($whrs, $wmin, 0, $tmonth, $tdate, $tyear);
                    if ($tepoch >= $curepoch) {
                        $update_date_time = date('Y-m-d', strtotime('next Friday'))    . " $seltime";
                        return array ($event_occurence , $update_date_time) ;
                    }
                }                                                
                $pos = strpos($wday,"7") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Saturday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Saturday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Saturday'));            # Day of next update
                    $tepoch = mktime($whrs, $wmin, 0, $tmonth, $tdate, $tyear);
                    if ($tepoch >= $curepoch) {
                        $update_date_time = date('Y-m-d', strtotime('next Saturday'))    . " $seltime";
                        return array ($event_occurence , $update_date_time) ;
                    }
                }                                                
    }
}

    # If a Date was specify and can occur every month.
    # Example : sdate='2' smth='' sday='' seltime='01:44'
    if (($sdate != "") and ($smth == "")) {
        $adate = array ($sdate);                                        # Convert Str Date in Array
        foreach($adate as $tdate) {                                     # Try all Date in Cur Mth
            $tepoch = mktime($whrs, $wmin, 0, $curmth, $tdate, $curyear);
            if ($tepoch >= $curepoch) {
                $update_date_time = $curyear ."-". $curmth ."-".$tdate . " $seltime";
                return array ($event_occurence , $update_date_time) ;
            }
        }
        foreach($adate as $tdate) {                                     # Try all Date for Nxt Mth
            $tepoch = mktime($whrs,$wmin,0,date('m',strtotime('next month')),$tdate,$curyear);
            if ($tepoch >= $curepoch) {
                $update_date_time = $curyear ."-". date('m',strtotime('next month')) ."-". sprintf("%02d",$tdate) . " $seltime";
                return array ($event_occurence , $update_date_time) ;
            }
        }
    }

    # If a Date was specify and specific month is specified.
    # Example : sdate='3,5' smth='3,6' sday='' seltime='01:15'
    if (($sdate != "") and ($smth != "")) {
        $amth = explode(",",$smth);                                         # Convert Str Mth in Array
        $adate = explode(",",$sdate);                                        # Convert Str Date in Array
        foreach($amth as $tmth) {                                       # Try all Mth Specify
            foreach($adate as $tdate) {                                 # Try all Date Specify
                $tepoch = mktime($whrs, $wmin, 0, $tmth, $tdate, $curyear);
                if ($tepoch >= $curepoch) {
                    $update_date_time = $curyear ."-". sprintf("%02d",$tmth) ."-".sprintf("%02d",$tdate) . " $seltime";
                    return array ($event_occurence , $update_date_time) ;
                }
            }
        }
    }


    #print "Function Returned : $update_date_time - $event_occurence"; 
    return array ($event_occurence , $update_date_time) ;
}



# ==================================================================================================
# Test if a string begin with another string. Return True or False.
#
#   $ExampleText = 'Hello world!';
#   if (StartsWith($ExampleText, 'Hello')){
#       print 'The text starts with hello!';
#   }
#   $ExampleText = 'Evil monkey.';
#   if (!StartsWith($ExampleText, 'monkey')){
#       print 'The text does not start with monkey!';
#   }
# ==================================================================================================
function StartsWith($MainString, $searchString) {
    return strpos($MainString, $searchString) === 0;
}




# ==================================================================================================
# This function receive a string the has to be in ($SADMIN/www/doc/pgm2doc.cfg) first column.
# It return the second column of the same file, which is the documentation link of string received.
# If RefString received isn't found in the pgm2doc file or file don't exist, return an empty string.
#
# Example of $SADMIN/www/doc/pgm2doc.cfg content : 
#   alert_group_cfg                ,  alert-group-cfg
#   how_to_sms                     ,  how-to-sms
#   sadm_backup                    ,  sadm-backup
#   sadm_cfg2html                  ,  sadm-cfg2html
#   sysmon_filesystem              ,  sysmon-filesystem
#   sysmon_https                   ,  sysmon-https
#   sysmon_load_average            ,  sysmon-load-average
#
# ==================================================================================================
function getdocurl($RefString) {
    global $DEBUG ;

    $RefString = strtolower($RefString); 

    # Open Documentation Link File ($SADMIN/www/doc/pgm2doc.cfg)
    try {
      if ( !file_exists(SADM_PGM2DOC) ) { 
          throw new Exception("File not found (" . SADM_PGM2DOC . ")."); 
      }
      $fh = fopen(SADM_PGM2DOC, "r");                                   # Open pgm2doc file
      if ( !$fh ) { 
          throw new Exception("File open failed (" . SADM_PGM2DOC . ")."); 
      } 
    }
    catch ( Exception $e ) {
        sadm_fatal_error ("Unable to open file (" . SADM_PGM2DOC . ").");
        return ("");
    }

    # Read file until RefString is found or End of file
    $RefURL = "" ;                                                      # Default return value
    while(!feof($fh)) {                                                 # Read till End Of File
      $wline = fgets($fh);                                              # Read Line By Line    
      if (strlen($wline) > 0) {                                         # Don't process empty Line
          if (startsWith($wline, '#'))   { continue; }                  # Skip comment line
          list($keyname,$doc_link) = explode(",", $wline);          # SPlit Line Key & URL
          $keyname = str_replace(' ', '', $keyname);            # Remove Spaces
          if ($keyname == $RefString) {                             # Key we seach for ?
            $RefURL = str_replace(' ', '', $doc_link);                  # Remove Spaces of URL 
            break ; 
          } 
      } 
    }
    fclose($fh);                                                        # Close File
    return ($RefURL) ;                                                  # Return URL or empty string
}





// ================================================================================================
//                   Display Content of file receive as parameter
// ================================================================================================
// function display_file( $nom_du_fichier ) {
//     $url = htmlspecialchars($_SERVER['HTTP_REFERER']);
//     echo "<a href='$url'>Back</a>";

//     echo '<table style="background-color: #EFCFFE"  frame="border" border="0" width="700">';
//     echo '<tr><td><pre>';
//     ///$myFile = "testFile.txt";
//     //$fh = fopen($nom_du_fichier, 'r');
//     //$theData = fgets($fh);
//     //fclose($fh);
//     //echo $theData;
//     @readfile($nom_du_fichier);
//     echo '</pre></td></tr>';
//     echo '</table>';
// }



# ==================================================================================================
# Function to strip unwanted characters (Extra space,tab,newline) from beginning and end of data
# Strips any quotes escaped with slashes and passes it through htmlspecialschar.
# ==================================================================================================
function sadm_clean_data($wdata) {
    if (! is_array($wdata)) {
        $wdata = trim($wdata);
        $wdata = stripslashes($wdata);
        $wdata = htmlspecialchars($wdata);
    }
    return $wdata;
}

?>
