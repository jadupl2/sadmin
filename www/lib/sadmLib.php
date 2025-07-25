<?php
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadmlib.php
#   Version  :  1.0
#   Date     :  22 March 2016
#   Requires :  php
#   Synopsis :  This file is the PHP Library that's used by the SADMIN Web Interface
#
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#   If not, see <https://www.gnu.org/licenses/>.
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
# 2019_01_11 lib v2.5 CLicking on logo bring you back to sadmin Home page.
# 2019_01_21 lib v2.6 Add function from From Schedule to Text.
# 2019_02_16 lib v2.7 Convert schedule metadata to one text line (Easier to read in Sched. List)
# 2019_04_04 lib v2.8 Function SCHEDULE_TO_TEXT now return 2 values (Occurrence & Date of update)
# 2019_05_02 lib v2.9 Function sadm_fatal_error - Insert back page link before showing alert.
# 2019_08_04 lib v2.10 Added function 'sadm_show_logo' to show distribution logo in a table cell.
# 2019_08_13 lib v2.11 Fix bug - When creating one line schedule summary
# 2019_08_14 lib v2.12 Add function for new page header look (display_lib_heading).
# 2019_10_15 lib v2.13 Reduce Logo size image from 32 to 24 square pixels
# 2019_10_15 lib v2.14 Reduce font size on 2nd line of heading in "display_lib_heading".
# 2020_01_13 lib v2.15 Reduce Day of the week name returned by SCHEDULE_TO_TEXT to 3 Char.
# 2020_04_27 lib v2.16 Change 2019 to 2020 in page footer
# 2020_09_22 lib v2.17 Facilitate going back to previous & Home page by adding button in header.
# 2021_08_05 lib v2.18 New function "getdocurl($RefString)" to allow link from script to doc
# 2021_08_29 lib v2.19 New function "get_alert_group_data" Return used alert grp name,type,tooltip.
# 2021_08_31 lib v2.20 New function "sadm_return_logo(OSNAME)" return image path, doc url & tooltip
# 2022_06_02 lib v2.21 Added Logo of AlmaLinux, Rocky Linux & update logo of Ubuntu.
# 2022_07_26 lib v2.22 Fix bug calculating "Next Update Date/Time" in some situation.
# 2024_09_12 lib v2.23 Minor change to standard heading function used for every page.
#@2024_10_31 lib v2.24 Add debug info and fix some problem in 'SCHEDULE_TO_TEXT()'.
#@2024_12_28 lib v2.25 Fix problem date of next schedule at end of year in 'SCHEDULE_TO_TEXT()'.
#@2025_03_05 lib v2.26 Update O/S Logo and documentation URL.
#@2025_05_07 lib v2.27 Update O/S Logo and documentation URL.
#@2025_07_20 lib v2.28 Add pencil image in standar5d page heading.
display_lib_heading
#===================================================================================================



#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG  = False ;                                                        # Debug Activated True/False
$LIBVER = "2.28" ;   
    

#===================================================================================================
# DISPLAY HEADING LINES OF THE WEB PAGE 
#===================================================================================================
function display_lib_heading($BACK_URL,$TITLE1,$TITLE2,$WVER) {

    $URL_HOME   = '/index.php';                                         # Site Home Page URL
    
    # HEADING LINE 1 - Icon on the left
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

    # HEADING LINE 1 - Title and version number.
    echo "\n<div style='text-align: center ; color: #271c1c; font-size: 1.8em; ";
    echo "font-family: Verdana, sans-serif; font-weight: bold; '>"; 
    echo "$TITLE1" ." - v$WVER";
    echo "</div>";
 
    # SHOW HEADING LINE 2
    if ($TITLE2 != "") {
        echo "\n<div style='text-align: center ; color: #271c1c; ";
        echo "font-size: 1.0em; font-family: Verdana, sans-serif; font-weight: bold; '>"; 
        echo "$TITLE2" ;   
        echo "</div>";
    }        

    # Space line for separation purpose
    echo  "\n\n<br><center><img src='/images/pencil2.gif'></center>\n\n"; 

    #echo "<hr/>\n\n";                                                     # Print Horizontal Line
#    echo "\n\n";                                                     # Print Horizontal Line
}


# ==================================================================================================
#        Function called at every end of SADM web page (Close Database and end all std Div)
# ==================================================================================================
function std_page_footer($wcon="") {

    if ($wcon != "") { mysqli_close($wcon); }                           # Close Database Connection
    echo "\n</div> <!-- End of sadmRightColumn   -->" ;                 # End of Left Content Page
    echo "\n</div> <!-- End of sadmPageContents  -->" ;                 # End of Content Page
   #echo "\n</div> <!-- End of ... -->" ;                               # End of Content Page
    
    #echo  "\n\n<center><img src='/images/pencil2.gif'></center>\n"; 


    echo "\n\n<div id='sadmFooter'>";
    echo "\nCopyright &copy; 2015-2025 - sadmin.ca - Suggestions, Questions or Report a problem at ";
    echo '<a href="mailto:sadmlinux@gmail.com">sadmlinux@gmail.com</a></small>';
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
    # calculate network address
    $ip_net              = $ip_address_long & $ip_nmask_long;
    # calculate first usable address
    $ip_host_first       = ((~$ip_nmask_long) & $ip_address_long);
    $ip_first            = ($ip_address_long ^ $ip_host_first) + 1;
    # calculate last usable address
    $ip_broadcast_invert = ~$ip_nmask_long;
    $ip_last             = ($ip_address_long | $ip_broadcast_invert) - 1;
    # calculate broadcast address
    $ip_broadcast        = $ip_address_long | $ip_broadcast_invert;

    return array (long2ip($ip_net), long2ip($ip_first), long2ip($ip_last), long2ip($ip_broadcast));
}





# ==================================================================================================
# Function accept a valid alert group name (like 'default' and defined in 'alert_group.cfg' file) 
# Return :
#   - The real group name (in case this function receive 'default' as the group name)
#   - The group type (M=Mail, S=SLack, T=Texto, C=Cellular)
#   - The Tool tip (Used when mouse is over the link, indicate the members of the alert group)
# ==================================================================================================
function get_alert_group_data ($calert) 
{
    global $DEBUG ;
    
    # If 'default' alert group is used, get the real effective alert group name.
    if ($calert == "default") {                                         # If Alert Group is default
        $CMD="grep -i \"^default\" " . SADM_ALERT_FILE . " |awk '{print$3}' |tr -d ' '";
        if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ; } 
        unset($output_array);                                           # Clear output Array
        exec ( $CMD , $output_array, $RCODE);                           # Execute command
        if ($DEBUG) {                                                   # If in Debug Mode
            echo "\n<br>Return code of command : " . $RCODE ;           # Command ReturnCode
            echo "\n<br>Content of output array:";                      # Show what's next
            echo '<code><pre>';                                         # Code to Show
            print_r($output_array);                                     # Show Cmd output
            echo '</pre></code>';                                       # End of code 
        }
        $calert=$output_array[0];                                       # Real Alert Grp Name
    }

    # Get the group Alert Type (M=Mail, S=SLack, T=Texto, C=Cellular)
    $CMD="grep -i \"^" . $calert . "\" " . SADM_ALERT_FILE . " |awk '{print$2}' |tr -d ' '";
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ;}         # Cmd we execute
    unset($output_array);                                               # Clear output Array
    exec ( $CMD , $output_array, $RCODE);                               # Execute command
    if ($DEBUG) {                                                       # If in Debug Mode
        echo "\n<br>Return code of command is : " . $RCODE ;            # Command ReturnCode
        echo "\n<br>Content of output array :";                         # Show what's next
        echo '<code><pre>';                                             # Code to Show
        print_r($output_array);                                         # Show Cmd output
        echo '</pre></code>';                                           # End of code 
    }
    $alert_group_type=$output_array[0];                             # GrpType t,m,s,c              

    # Get Alert group members for tooltip
    $CMD="grep -i \"^" . $calert . "\" " . SADM_ALERT_FILE . " |awk '{print$3}' |tr -d ' '";
    if ($DEBUG) { echo "\n<br>Command executed is : " . $CMD ;}     # Cmd we execute
    unset($output_array);                                           # Clear output Array
    exec ( $CMD , $output_array, $RCODE);                           # Execute command
    if ($DEBUG) {                                                   # If in Debug Mode
        echo "\n<br>Return code of command is : " . $RCODE ;        # Command ReturnCode
        echo "\n<br>Content of output array :";                     # Show what's next
        echo '<code><pre>';                                         # Code to Show
        print_r($output_array);                                     # Show Cmd output
        echo '</pre></code>';                                       # End of code 
    }
    $alert_member=$output_array[0];                                 # Alert Group Member

    # Build to tooltip for the alert group 
    switch (strtoupper($alert_group_type)) {
        case 'M' :  $stooltip="Alert send by email to " . $alert_member ;  
                    break;
                    ;; 
        case 'C' :  $stooltip="Alert send by SMS to " . $alert_member ;   
                    break;
                    ;; 
        case 'T' :  $stooltip="Alert send by SMS to " . $alert_member ;
                    break;
                    ;; 
        case 'S' :  $stooltip="Alert send with Slack to " . $alert_member ;
                    break;
                    ;; 
        default  :  $stooltip="Invalid Alert type(" . $alert_type .")";
                    break;
                    ;;
    }                    

    return array ($calert, $alert_group_type, $stooltip) ; 
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
    $URL_HOME   = '/index.php';                                         # Site Home Page URL
    echo "\n<div style='float: left;'>";                                # Align Left Link Go Back
    echo "<a href='" . $URL_HOME . "'>";                                # URL to Go Back Home Page
    echo "<span data-toggle='tooltip' title='Back to Home page'>";      # Show Tooltip 
    echo "<img src='/images/home.png' ";                                # Show Home Icon
    echo "style='width:32px;height:32px;'></span></a>";                 # Size Icons 32x32
    echo "</div>"; 
    echo "\n<script type=\"text/javascript\">";
    echo "\n alert(\"$message\");";
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
# Function: 
#   - Return the path to the linux distribution logo.
# Parameter : 
#   - Name of the distribution
# Return :
#   - Path to the image (logo) file.
#   - The url to the distribution web page
# ==================================================================================================
function sadm_return_logo($WOS) {

    $ititle = ucfirst($WOS) . " documentation";
    
    switch (strtoupper($WOS)) {
        case 'REDHAT' :
            $iurl='https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9' ;
            $ipath='/images/logo_redhat.png';
            break;
        case 'FEDORA' :
            $iurl='https://docs.fedoraproject.org/en-US/docs/' ;
            $ipath='/images/logo_fedora.png';
            break;
        case 'MACOSX' :
            $iurl='https://support.apple.com/guide/mac-help/welcome/mac' ;
            $ipath='/images/logo_apple.png';
            break;
        case 'CENTOS' :
            $iurl='https://docs.centos.org' ;
            $ipath='/images/logo_centos.png';
            break;
        case 'ALMA' :
            $iurl='https://wiki.almalinux.org/documentation/guides.html' ;
            $ipath='/images/logo_almalinux.png';
            break;
        case 'ROCKY' :
            $iurl='https://docs.rockylinux.org/' ;
            $ipath='/images/logo_rockylinux.png';
            break;
        case 'UBUNTU' :
            $iurl='https://help.ubuntu.com/' ;
            $ipath='/images/logo_ubuntu.png';
            break;
        case 'MINT' :
            $iurl='https://linuxmint.com/documentation.php' ;
            $ipath='/images/logo_linuxmint.png';
            break;
        case 'DEBIAN' :
            $iurl='https://www.debian.org/doc/' ;
            $ipath='/images/logo_debian.png';
            break;
        case 'RASPBIAN' :
            $iurl='https://www.raspberrypi.com/documentation/computers/os.html' ;
            $ipath='/images/logo_raspbian.png';
            break;
        case 'SUSE' :
            $iurl='https://doc.opensuse.org/' ;
            $ipath='/images/logo_suse.png';
            break;
        case 'AIX' :
            $iurl='https://www.ibm.com/docs/en/aix' ;
            $ipath='/images/logo_aix.png';
            break;
        case 'MACOS' :
            $iurl='https://support.apple.com/fr-ca/docs/mac#' ;
            $ipath='/images/logo_apple.png';
            break;
        default:
            $iurl='https://en.wikipedia.org/wiki/Linux' ;
            $ipath='/images/logo_linux.png';
            break;
    }

    return array ($ipath, $iurl, $ititle) ; 
}



# ==================================================================================================
# Show Distribution Logo as a cell in a table
# ==================================================================================================
function sadm_show_logo($WOS) {

    list($ipath, $iurl, $ititle) = sadm_return_logo ($WOS) ;

    echo "<td align='center'>";
    echo "<a href='". $iurl . "' ";
    echo "title='" . $ititle . "'>";
    echo "<img src='" . $ipath . "' ";
    echo "style='width:32px;height:32px;'>"; 
    echo "</a></td>\n";
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
#            Position 0 = Y Then ALL Date in the month are selected
#            Position 1-31 a 'Y' Indicate the date of the month that script will run or not 'N'.
#            Default is YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN meaning will run every Day Of the Month.
#
# wmth =  13 Characters (either a Y or a N) each representing a month (YNNNNNNNNNNNN)
#           Position 0 = Y Then ALL months are selected
#           Position 1-12 represent the month that are selected ('Y') to run or not (N) ,
#           Default is YNNNNNNNNNNNN meaning will run every month.
#
# wdow =  8 Characters (either a Y or a N) 
#            If Position 0 = Y then will run every day of the week.
#            Position 1-7 Indicate a week day, starting with Sunday.
#            Default is all Week (YNNNNNNN)
#
# whrs =  Hour when the event should begin (00-23) - Default 1am
# wmin =  Minute when the event will begin (00-50) - Default 5min
#
#
# Return 2 Values: 
#  - event_occurence: 
#       Is a string that specify when (Day,Time) at what repetition the schedule occurs.
#       Example of string returned : "Each Wednesday at 01:15"
#  - update_date_time
#       Is a string containing the date and time the next events will occur.
#       Example of string returned : "2019-04-03 22:00"
# 
#===================================================================================================
function SCHEDULE_TO_TEXT($wdom,$wmth,$wdow,$whrs,$wmin)
{
    $DEBUG = False; 
    if ($DEBUG) { 
        echo "\n<br>Parameters received : \n<br>"; 
        echo "wdom=".$wdom."<br>wmth=".$wmth."<br>wdow=".$wdow."<br>whrs=".$whrs."<br>wmin=".$wmin;
    }

    # Variables used to construct the next event date and occurence
    $sdate    = "";                                                     # Sel Day (1,3,31) empty now
    $smth     = "";                                                     # Selected Mth empty for now
    $sday     = "";                                                     # Selected Day empty for now
    $selhrs   = sprintf("%02d", $whrs);                 # Save & Format Selected Hrs
    $selmin   = sprintf("%02d", $wmin);                 # Save & Format Selected Min
    $seltime  = "${selhrs}:${selmin}";                                  # Store Hrs:Min for
    $curday   = sprintf("%02d", date("d"));     # Get Current Date
    $curmth   = sprintf("%02d", date("m"));     # Get Current Month
    $curyear  = sprintf("%04d", date("Y"));     # Get Current Year
    $curepoch = time();                                                 # Current Epoch Time
    $selday   = $curday; $selmth=$curmth ; $selyear=$curyear;           # Set Default Selection Date


    # part1 = Date of the month (1-31) the export schedule will run.
    # If no particular date specified, 'sdate' will be empty.
    # If date were specified, 'sdate' (Ex: 1,4,8), 'part1' will contains '1st,4th,8th of '
    $part1 = "";                                                        # Default no date=every mth
    if (substr($wdom,0,1) != "Y") {             # 1st Char = Y = Each Month
        for ($i = 1; $i < 32; $i = $i + 1) {                            # Loop 1-31 days, Y=date Sel
            # If first of the month is selected                         # If 1st Month selected 
            if ((substr($wdom,$i,1) == "Y") && ($i == 1)) {             
                $part1 = $part1 . "1st," ;                              # Insert 1st, in part1
                $sdate="${sdate}1,";                                    # Insert 1 in Selected Date
            }
            # If second of the month is selected
            if ((substr($wdom,$i,1) == "Y") && ($i == 2)) { 
                $part1 = $part1 . "2nd," ;                              # Insert 2nd, in part1
                $sdate="${sdate}2,";                                    # Insert 2 in Selected Date
            }
            # If third of the month is selected
            if ((substr($wdom,$i,1) == "Y") && ($i == 3)) { 
                $part1 = $part1 . "3rd," ;                              # Insert 3rd, in part1
                $sdate="${sdate}3,";                                    # Insert 3 in Selected Date
            }
            # If date if greater than 3 
            if ((substr($wdom,$i,1) == "Y") && ($i > 3)) { # All month>than 3
                $part1 = $part1 . $i . "th," ;                          # Insert day number  + "th,"
                $sdate="${sdate}$i,";                                   # Insert Day Number in sdate
            }
        }
        $part1 = rtrim($part1, ',') ;               # Del part1 trailing comma 
        $sdate = rtrim($sdate, ',') ;               # Del sdate trailing comma
        if ($part1 != "") { $part1 = $part1 . " of " ; }                # At least one date specify
    }
    if ($DEBUG) { echo "<br>-C- Part1 = $part1"; echo "<br>"; } 


    # Determine the Month(s) that the event will run.
    # - 'part2' will contains the months names (Jan,Apr,Aug) or nothing if every month (1st Char=Y)
    # - 'smonth' will contains the months selected (1,4,8) or nothing if every month is selected.
    $part2 = "";                                                        # Default run every months
    $mth_name = array('each month,','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
    if (substr($wmth,0,1) == "Y") {             # 1st Char is Y = Each Month
        if ($part1 != "") { $part2 = $mth_name[0]; }                    # Any Mth ins. "each month"
    }else{                                                              # If Month No. is Specify
        for ($i = 1; $i < 13; $i = $i + 1) {                            # Loop through the 12 Months
            if (substr($wmth,$i,1) == "Y") {    # If month=Y=Selected
                $part2 = $part2 . $mth_name[$i] . "," ;                 # Insert Mth Name in Part2
                $smth  = $smth . $i . ",";                              # Insert Mth Num in Sel. Mth
            }
        }
    }
    $part2 = rtrim($part2,',') ;                    # Del part2 trailing Comma
    $smth  = rtrim($smth, ',') ;                    # Del smth trailing Comma
    if ($DEBUG) { 
        echo "<br>-D-";     
        echo "- wdom = " . substr($wdom,0,1) . 
            " - wmth = " . substr($wmth,0,1) . 
            " - wdow = " . substr($wdow,0,1) ;
        echo "<br>-D- Part1 = $part1 - Part2 = $part2<br>" ;
    } 
    

    # Days of the week the schedule will run
    # If no date and no month specified
    if ((substr($wdom,0,1) == "Y") and
        (substr($wmth,0,1) == "Y")) { 
        $part2 = "each "; $part3 = ""; 
        if (substr($wdow,0,1) == "Y") {        # If DOW begin with Y=AllWeek
            $part3 = " day"; 
        }else{                                                         # If not Get Days it Run
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
    $part3 = rtrim($part3, ',') . " " ;               # Del part3 trailing Comma
    $sday  = rtrim($sday, ',');                       # Del sday trailing Comma
    if ($DEBUG) { print "\n<br>-E-- sday = $sday Part1 = $part1 - Part2 = $part2 - Part3 = $part3";}


    # Part4 is the hours and minutes of the schedule, just format them and put them in part4.
    $part4 = "at $seltime" ;
    $event_occurence = "$part1" . "$part2" . "$part3" . "$part4";
    if ($DEBUG) { echo nl2br("\n<br>-F- Final Event Occurence : $event_occurence"); } 
    

    # From Here, Now let's construct the date and time of the next event.
    # If any month, any date, any day, then event could be later today or tomorrow.
    if ($DEBUG) { 
        echo "\n<br>-G- sdate='" .$sdate. "' smth='" .$smth. "' sday='" .$sday. "' seltime='".$seltime."'";
    }
    if (($sdate == "") and ($smth == "") and ($sday == "")) {
        $curepoch = time();                                             # Current Epoch Time 
        $event1   = mktime($selhrs,$selmin,0,$curmth,$curday,$curyear); # Epoch if run today
        $tyear    = date('Y', strtotime('tomorrow'));  # tomorrow Year 
        $tmonth   = date('m', strtotime('tomorrow'));  # tomorrow Month
        $tdate    = date('d', strtotime('tomorrow'));  # tomorrow Day 
        $event2   = mktime($whrs,$wmin,0,$tmonth,$tdate,$tyear);        # Epoch for tommorow
        if ($event1 > $curepoch) {
            $update_date_time = date("Y-m-d H:i", substr("$event1", 0, 16));
        }else{
            $update_date_time = date("Y-m-d H:i", substr("$event2", 0, 16));
        }
        if ($DEBUG) { 
           echo "\n<br>-H- Function Returned : $event_occurence - $update_date_time"; 
        } 
        return array ($event_occurence , $update_date_time) ;
    }

    # No Particular date or month (both empty), then check for a day of the week
    if ($DEBUG) { echo "<br>-I-"; } 
    if (($sdate == "") and ($smth == "")) {                             # Any Mth or Date, at DOWeek
        $aday = array($sday);                                           # Get name of the day 
        if ($DEBUG) { echo "<br>-Ia"; } 
        foreach($aday as $wday)                                         # Process each Date Selected
            {

                if ($DEBUG) { echo "<br>-Ib"; } 
                $pos = strpos($wday,"1") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Sunday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Sunday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Sunday'));            # Day of next update
                    $nxtepoch  = mktime($whrs,$wmin,0,$tmonth,$tdate,$tyear); # Epoch if nxt week
                    $dayofweek = date('w');                                   # Get Day of the week
                    if ($dayofweek == 0) {
                        $w_month  = date('m') ;                               # Today Mth Num.
                        $w_day    = date('d') ;                               # Today day Num.
                        $w_year   = date('Y') ;                               # Today Year Num. 
                        $w_epoch = mktime($whrs,$wmin,0,$w_month,$w_day,$w_year); # Epoch this week
                        if ($w_epoch >= $curepoch) {
                            $update_date_time = date('Y-m-d') . " $seltime";
                            if ($DEBUG) { 
                                print "\n<br>-Ic-" ; 
                                print "Function Returned : $event_occurence - $update_date_time"; 
                            } 
                            return array ($event_occurence , $update_date_time) ;
                        }
                    }
                    $update_date_time = date('Y-m-d', strtotime('next Sunday'))    . " $seltime";
                    if ($DEBUG) { 
                        print "\n<br>-E2-" ; 
                        print "Function Returned : $event_occurence - $update_date_time"; 
                    } 
                    return array ($event_occurence , $update_date_time) ;
                }


                $pos = strpos($wday,"2") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Monday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Monday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Monday'));            # Day of next update
                    $nxtepoch  = mktime($whrs,$wmin,0,$tmonth,$tdate,$tyear); # Epoch if nxt week    America/Toronto
                    $curepoch = time();                                 # Current Epoch Time
                    $dayofweek = date('w');                     # Get Day of the week
                    if ($dayofweek == 1) {
                        $w_month  = date('m') ;                 # Today Mth Num.
                        $w_day    = date('d') ;                 # Today day Num.
                        $w_year   = date('Y') ;                 # Today Year Num. 
                        $w_epoch = mktime($whrs,$wmin,0,$w_month,$w_day,$w_year); # Epoch this week
                        $curepoch = time();                                                 # Current Epoch Time
                        #print "\njack w_epoch = " . $w_epoch . " curepoch= " . $curepoch . " ";
                        if ($w_epoch > $curepoch) {
                            #print "\ncoco" ;
                            $update_date_time = date('Y-m-d',strtotime('today')) . " $seltime";
                            if ($DEBUG) { 
                                print "\n<br>-E3-" ; 
                                print "Function Returned : $event_occurence - $update_date_time"; 
                            } 
                            return array ($event_occurence , $update_date_time) ;
                        }
                    }
                    $update_date_time = date('Y-m-d', strtotime('next Monday'))    . " $seltime";
                    if ($DEBUG) { 
                        print "\n<br>-E4-" ; 
                        print "Function Returned : $event_occurence - $update_date_time"; 
                    } 
                    return array ($event_occurence , $update_date_time) ;
                }



                $pos = strpos($wday,"3") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Tuesday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Tuesday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Tuesday'));            # Day of next update
                    $nxtepoch = mktime($whrs, $wmin, 0, $tmonth, $tdate, $tyear);
                    $dayofweek = date('w');                                   # Get Day of the week
                    if ($dayofweek == 2) {
                        $w_month  = date('m') ;                               # Today Mth Num.
                        $w_day    = date('d') ;                               # Today day Num.
                        $w_year   = date('Y') ;                               # Today Year Num. 
                        $w_epoch = mktime($whrs,$wmin,0,$w_month,$w_day,$w_year); # Epoch this week
                        #echo nl2br("\nw_epoch=$w_epoch - curepoch=$curepoch\n");
                        if ($w_epoch >= $curepoch) {
                            $update_date_time = date('Y-m-d') . " $seltime";
                            if ($DEBUG) { 
                                print "\n<br>-E4-" ; 
                                print "Function Returned : $event_occurence - $update_date_time"; 
                            } 
                            return array ($event_occurence , $update_date_time) ;
                        }
                    }
                $update_date_time = date('Y-m-d', strtotime('next Tuesday'))    . " $seltime";
                if ($DEBUG) { 
                    print "\n<br>-E5-" ; 
                    print "Function Returned : $event_occurence - $update_date_time"; 
                } 
                return array ($event_occurence , $update_date_time) ;
                }


                $pos = strpos($wday,"4") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Wednesday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Wednesday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Wednesday'));            # Day of next update
                    $nxtepoch  = mktime($whrs,$wmin,0,$tmonth,$tdate,$tyear); # Epoch if nxt week
                    $dayofweek = date('w');                                   # Get Day of the week
                    if ($dayofweek == 3) {
                        $w_month  = date('m') ;                               # Today Mth Num.
                        $w_day    = date('d') ;                               # Today day Num.
                        $w_year   = date('Y') ;                               # Today Year Num. 
                        $w_epoch = mktime($whrs,$wmin,0,$w_month,$w_day,$w_year); # Epoch this week
                        if ($w_epoch >= $curepoch) {
                            $update_date_time = date('Y-m-d') . " $seltime";
                            if ($DEBUG) { 
                                print "\n<br>-E6-" ; 
                                print "Function Returned : $event_occurence - $update_date_time"; 
                            } 
                            return array ($event_occurence , $update_date_time) ;
                        }
                    }
                $update_date_time = date('Y-m-d', strtotime('next Wednesday'))    . " $seltime";
                if ($DEBUG) { 
                    print "\n<br>-E7-" ; 
                    print "Function Returned : $event_occurence - $update_date_time"; 
                } 
                return array ($event_occurence , $update_date_time) ;
                }


                $pos = strpos($wday,"5") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Thursday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Thursday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Thursday'));            # Day of next update
                    $nxtepoch  = mktime($whrs,$wmin,0,$tmonth,$tdate,$tyear); # Epoch if nxt week
                    $dayofweek = date('w');                                   # Get Day of the week
                    if ($dayofweek == 4) {
                        $w_month  = date('m') ;                               # Today Mth Num.
                        $w_day    = date('d') ;                               # Today day Num.
                        $w_year   = date('Y') ;                               # Today Year Num. 
                        $w_epoch = mktime($whrs,$wmin,0,$w_month,$w_day,$w_year); # Epoch this week
                        if ($w_epoch >= $curepoch) {
                            $update_date_time = date('Y-m-d') . " $seltime";
                            if ($DEBUG) { 
                                print "\n<br>-E8-" ; 
                                print "Function Returned : $event_occurence - $update_date_time"; 
                            } 
                            return array ($event_occurence , $update_date_time) ;
                        }
                    }
                $update_date_time = date('Y-m-d', strtotime('next Thursday'))    . " $seltime";
                if ($DEBUG) { 
                    print "\n<br>-E8-" ; 
                    print "Function Returned : $event_occurence - $update_date_time"; 
                } 
                return array ($event_occurence , $update_date_time) ;
                }                                                


                $pos = strpos($wday,"6") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Friday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Friday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Friday'));            # Day of next update
                    $nxtepoch  = mktime($whrs,$wmin,0,$tmonth,$tdate,$tyear); # Epoch if nxt week
                    $dayofweek = date('w');                                   # Get Day of the week
                    if ($dayofweek == 5) {
                        $w_month  = date('m') ;                               # Today Mth Num.
                        $w_day    = date('d') ;                               # Today day Num.
                        $w_year   = date('Y') ;                               # Today Year Num. 
                        $w_epoch = mktime($whrs,$wmin,0,$w_month,$w_day,$w_year); # Epoch this week
                        if ($w_epoch >= $curepoch) {
                            $update_date_time = date('Y-m-d') . " $seltime";
                            if ($DEBUG) { 
                                print "\n<br>-E9-" ; 
                                print "Function Returned : $event_occurence - $update_date_time"; 
                            } 
                            return array ($event_occurence , $update_date_time) ;
                        }
                    }
                    $update_date_time = date('Y-m-d', strtotime('next Friday'))    . " $seltime";
                    if ($DEBUG) { 
                        print "\n<br>-E10-" ; 
                        print "Function Returned : $event_occurence - $update_date_time"; 
                    } 
                    return array ($event_occurence , $update_date_time) ;
                }    


                $pos = strpos($wday,"7") ;
                if ($pos !== false) {
                    $tyear  = date('Y', strtotime('next Saturday'));            # Year of next update
                    $tmonth = date('m', strtotime('next Saturday'));            # Month of next update
                    $tdate  = date('d', strtotime('next Saturday'));            # Day of next update
                    $nxtepoch  = mktime($whrs,$wmin,0,$tmonth,$tdate,$tyear); # Epoch if nxt week
                    $dayofweek = date('w');                                   # Get Day of the week
                    if ($dayofweek == 6) {
                        $w_month  = date('m') ;                               # Today Mth Num.
                        $w_day    = date('d') ;                               # Today day Num.
                        $w_year   = date('Y') ;                               # Today Year Num. 
                        $w_epoch = mktime($whrs,$wmin,0,$w_month,$w_day,$w_year); # Epoch this week
                        if ($w_epoch >= $curepoch) {
                            $update_date_time = date('Y-m-d') . " $seltime";
                            if ($DEBUG) { 
                                print "\n<br>-E11-" ; 
                                print "Function Returned : $event_occurence - $update_date_time"; 
                            } 
                            return array ($event_occurence , $update_date_time) ;
                        }
                    }
                    $update_date_time = date('Y-m-d', strtotime('next Saturday'))    . " $seltime";
                    if ($DEBUG) { 
                        print "\n<br>-E12-" ; 
                        print "Function Returned : $event_occurence - $update_date_time"; 
                    } 
                    return array ($event_occurence , $update_date_time) ;
                }                                                
            }
}

    # If a Date was specify and can occur every month.
    # Example : sdate='2' smth='' sday='' seltime='01:44'   HERE PROBLEM WHEN date = 8,25
    if (($sdate != "") and ($smth == "")) {
        #$adate = array ($sdate);                                        # Convert Str Date in Array
        $adate = explode(",", $sdate);
        #$adate = array (str_replace( ',', ' ', $sdate));  # Convert Str Date in Array
        if ($DEBUG) { print "\n<br>adate=" ; print_r ($adate) ; print " - sdate=$sdate" ;  }

        # Try specified date(s) in current month 
        foreach($adate as $tdate) {                                     # Try all Date in Cur Mth
            $curepoch = time();                                         # Current Epoch Time 
            if ($DEBUG) { print "\n<br>$whrs, $wmin, 0, $curmth, $tdate, $curyear" ; }
            $tepoch = mktime($whrs, $wmin, 0, $curmth, $tdate, $curyear);
            if (! $tepoch) { print "\n<br>tepoch=false" ;} 
            if ($DEBUG) { print "\n<br>" ; print_r ($adate) ; print " - tdate=$tdate" ;}
            if ($DEBUG) { print "\n<br>tepoch=$tepoch curepoch=$curepoch" ;} 
            if ($tepoch >= $curepoch) {
                $update_date_time = $curyear ."-". $curmth ."-".$tdate . " $seltime";
                if ($DEBUG) { print "\n<br>-E47- Function return: $event_occurence - $update_date_time";}
                return array ($event_occurence , $update_date_time) ;
            }
        }

        # Next event is in next month
        if ($DEBUG) { print "\n<br>-E48-" ; }
        $update_date_time = "" ;
        foreach($adate as $tdate) {                                     # Try all Date for Nxt Mth
            if ($DEBUG) { print "\n<br>-E48A-  tdate=" . $tdate; }
            $curmth += 1 ;
            if ($curmth > 12) { $curmth = 1 ; $curyear += 1 ; }
            $tepoch = mktime($whrs, $wmin, 0, $curmth, $tdate, $curyear);
            #$tepoch = mktime($whrs,$wmin,0,date('m',strtotime('next month')),$tdate,$curyear);
            $curepoch = time();                                         # Current Epoch Time 
            if ($DEBUG) { print "\n<br>-E48C- tepoch " . $tepoch.  "  curepoch = " . $curepoch; }
            if ($tepoch >= $curepoch) {                                 # If Next Event >= Cur Epoch
                if ($DEBUG) { print "\n<br>-E48A-" ; }
                #echo "param to update_date_time=" .$curyear ."-". date('m',strtotime('next month')) ."-". sprintf("%02d",$tdate) . " $seltime";
                #$update_date_time = $curyear ."-". date('m',strtotime('next month')) ."-". sprintf("%02d",$tdate) . " $seltime";
                $update_date_time = $curyear ."-". sprintf("%02d",$curmth) ."-". sprintf("%02d",$tdate) . " $seltime";
                if ($DEBUG) { print "\n<br>-E55- Occurence & Update time: $event_occurence - $update_date_time"; } 
                return array ($event_occurence , $update_date_time) ;
            }
        }
    }

    # If a Date was specify and specific month is specified.
    # Example : sdate='3,5' smth='3,6' sday='' seltime='01:15'
    if (($sdate != "") and ($smth != "")) {
        $amth = explode(",",$smth);                  # Convert Str Mth in Array
        $adate = explode(",",$sdate);                # Convert Str Date in Array
        foreach($amth as $tmth) {                                       # Try all Mth Specify
            foreach($adate as $tdate) {                                 # Try all Date Specify
                $tepoch = mktime($whrs, $wmin, 0, $tmth, $tdate, $curyear);
                if ($tepoch >= $curepoch) {
                    $update_date_time = $curyear ."-". sprintf("%02d",$tmth) ."-".sprintf("%02d",$tdate) . " $seltime";
                    if ($DEBUG) { print "\n<br>-E60- Occurence & Update Time $event_occurence - $update_date_time"; } 
                    return array ($event_occurence , $update_date_time) ;
                }
            }
        }
    }

    if ($DEBUG) { print "Finally Function Returned : $update_date_time - $event_occurence"; } 
    $DEBUG = False;
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
# This function receive a string that has to be in ($SADMIN/www/doc/pgm2doc.cfg) first column.
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
          list($keyname,$doc_link) = explode(",", $wline);              # SPlit Line Key & URL
          $keyname = str_replace(' ', '', $keyname);                    # Remove Spaces
          if ($keyname == $RefString) {                                 # Key we seach for ?
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
