<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis
*   Title       :  sadm_view_server_info.php
*   Version     :  1.5
*   Date        :  9 Dec 2016
*   Requires    :  secure.php.net, postgresql.org, getbootstrap.com, DataTables.net
*   Description :  This page allow to view the servers farm information 
*   
*   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
*
*   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
*   of the GNU General Public License as published by the Free Software Foundation; either
*   version 2 of the License, or (at your option) any later version.
*
*   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
*   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*   See the GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License along with this program.
*   If not, see <http://www.gnu.org/licenses/>.
* ==================================================================================================
*/
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_init.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');

#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = FALSE;                                       # Activate (TRUE) or Deactivate (FALSE) Debug

# ==================================================================================================
#                      DISPLAY SERVER DATA USED IN THE DATA INPUT FORM
#
#  wrow  = Array containing table row keys/values
#  mode  = "[D]isplay" Only show row content - Can't modify any information
#        = "[C]reate"  Display default values and user can modify all fields, except the row key
#        = "[U]pdate"  Display row content and user can modify all fields, except the row key
# ==================================================================================================
function display_server_data ($wrow) {

    # Server Data DIV
    echo "\n\n<div class='server_data'>             <!-- Start of Data Scr DIV -->";

    # DATA LEFT SIDE DIV
    echo "\n\n<div class='server_leftside'>         <!-- Start Data LeftSide  -->";
    display_left_side ($wrow);
    echo "\n\n</div>                                <!-- End of LeftSide Data -->";

    # DATA RIGHT SIDE DIV
    echo "\n\n<div class='server_rightside'>        <!-- Start RightSide Data  -->";
    display_right_side ($wrow);
    echo "\n\n</div>                                <!-- End of RightSide Data -->";

    echo "\n</div>                                  <!-- End of Data Scr DIV -->";

    # Update Button
    echo "\n<center>";
    echo "\n<a href=/crud/sadm_server_update.php?sel=" . $wrow['srv_name'] .">";
    echo "\n<button type='button' class='btn btn-info btn-xs'>";
    echo "\n<span class='glyphicon glyphicon-pencil'></span> Update</button></a>";
    echo "\n</center>\n<br>                         <!-- Blank Line Before Footer -->";
}




# ==================================================================================================
#                               DISPLAY LEFT SIDE OF SERVER DATA 
#                           wrow  = Array containing table row keys/values
# ==================================================================================================
function display_left_side ($wrow) {

    # Server Name and Domain
    echo "\n\n<div class='server_left_label'>Server Name</div>";
    echo "\n<div class='server_left_data'>" ;
    echo $wrow['srv_name'] . "." . $wrow['srv_domain'] ;
    echo "</div>";
 
    # Server IP
    echo "\n\n<div class='server_left_label'>Server IP</div>";
    echo "\n<div class='server_left_data'>" ;
    if (empty($wrow['srv_ip']) or $wrow['srv_ip'] == " " ) { 
        echo "No IP ?" ; 
    }else{ 
        echo $wrow['srv_ip'];
    }
    echo "</div>";
 
     # Server Description
    echo "\n\n<div class='server_left_label'>Description</div>";
    echo "\n<div class='server_left_data'>" . $wrow['srv_desc'] . "</div>";
 
    # Server O/S Type 
    echo "\n\n<div class='server_left_label'>O/S Type</div>";
    echo "\n<div class='server_left_data'>" . $wrow['srv_ostype'] . "</div>";
 
    # O/S Name and Version
    echo "\n\n<div class='server_left_label'>O/S Name & Version</div>";
    echo "\n<div class='server_left_data'>";
    echo $wrow['srv_osname'] . " (" . $wrow['srv_oscodename'] . ") " . $wrow['srv_osversion'];
    echo "</div>";

    # Kernel Version & Bit Mode
    echo "\n\n<div class='server_left_label'>Kernel Version</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_kernel_version'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo $wrow['srv_kernel_version'] ; 
    }
    if (empty($wrow['srv_kernel_bitmode'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo " - " . $wrow['srv_kernel_bitmode'] . " Bits" ; 
    }
    echo "</div>";

    # Hardwarel Bit Mode
    echo "\n\n<div class='server_left_label'>Hardware Bit Mode</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_hwd_bitmode'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo $wrow['srv_hwd_bitmode'] . " Bits" ; 
    }
    echo "</div>";
    
    # Creation Date 
    echo "\n\n<div class='server_left_label'>Creation Date</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_creation_date'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo $wrow['srv_creation_date']; 
    }
    echo "</div>";

    # Server Tag 
    echo "\n\n<div class='server_left_label'>Server Tag</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_notes'])) { echo "&nbsp" ; }else{ echo $wrow['srv_tag'] ; }
    echo "</div>";

    # Server Note
    echo "\n\n<div class='server_left_label'>Server Note</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_notes'])) { echo "&nbsp" ; }else{ echo $wrow['srv_notes'] ; }
    echo "</div>";

    # Server Category
    echo "\n\n<div class='server_left_label'>Category</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_cat'])) { echo "&nbsp" ; }else{ echo $wrow['srv_cat'] ; }
    echo "</div>";

    # Server Group
    echo "\n\n<div class='server_left_label'>Group</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_group'])) { echo "&nbsp" ; }else{ echo $wrow['srv_group'] ; }
    echo "</div>";

    # Server Status
    echo "\n\n<div class='server_left_label'>Server Active</div>";
    echo "\n<div class='server_left_data'>";
    if ($wrow['srv_active'] == 't') { echo "Yes" ; }else{ echo "No" ; }
    echo "</div>";

    # Server Virtual ?
    echo "\n\n<div class='server_left_label'>Virtual/Physical Server</div>";
    echo "\n<div class='server_left_data'>";
    if ($wrow['srv_vm'] == 't') { echo "Virtual" ; }else{ echo "Physical" ; }
    echo "</div>";

    # Server Sporadic
    echo "\n\n<div class='server_left_label'>Online Sporadically</div>";
    echo "\n<div class='server_left_data'>";
    if ($wrow['srv_sporadic'] == 't') { echo "Yes" ; }else{ echo "No" ; }
    echo "</div>";

    # Server Model
    echo "\n\n<div class='server_left_label'>Server Model</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_model'])) { echo "&nbsp" ; }else{ echo $wrow['srv_model'] ; }
    echo "</div>";

    # Server Serial
    echo "\n\n<div class='server_left_label'>Serial Number</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_serial'])) { echo "N/A" ; }else{ echo $wrow['srv_serial'] ; }
    echo "</div>";

    # Server Monitored
    echo "\n\n<div class='server_left_label'>Monitor SSH Conn.</div>";
    echo "\n<div class='server_left_data'>";
    if ($wrow['srv_monitor'] == 't') { echo "Yes" ; }else{ echo "No" ; }
    echo "</div>"; 

    # Server Backup with Rear ?
    echo "\n\n<div class='server_left_label'>Backup with Rear</div>";
    echo "\n<div class='server_left_data'>\n";
    switch ($wrow['srv_backup']) {
        case 0: echo "No Backup";
                      break;
        case 1: echo "Monday "    ;
                     break;
        case 2: echo "Tuesday "   ;
                      break;
        case 3: echo "Wednesday " ;
                      break;
        case 4: echo "Thursday "  ;
                      break;
        case 5: echo "Friday "    ;
                      break;
        case 6: echo "Saturday "  ;
                      break;
        case 7: echo "Sunday "    ;
                      break;
    }

    # Date & Time the Backup Start 
    echo " at " . sprintf("%02d",$wrow['srv_backup_hour']) . ":" ;
    echo sprintf("%02d",$wrow['srv_backup_minute']) ;
    echo "</div>";

    # Server Maintenance Mode
    echo "\n\n<div class='server_left_label'>Maintenance Mode</div>";
    echo "\n<div class='server_left_data'>";
    if ($wrow['srv_maintenance'] == 't')  { echo "Active" ; }else{ echo "Inactive" ; }
    echo "</div>";

    # Maintenance Mode Start and Stop TimeStamp
    echo "\n\n<div class='server_left_label'>Maintenance Period</div>";
    echo "\n<div class='server_left_data'>";
    echo " From: " . substr($wrow['srv_maint_start'],0,16) ;
    echo " To: "   . substr($wrow['srv_maint_end'],0,16) ;
    echo "\n</div>";

}






# ==================================================================================================
#                                 DISPLAY RIGHT SIDE OF SERVER DATA 
#                           wrow  = Array containing table row keys/values
# ==================================================================================================
function display_right_side ($wrow) {


    # Last Update Date
    echo "\n\n<div class='server_right_label'>Last Daily Update Date</div>";
    echo "\n<div class='server_right_data'>";
    if (empty($wrow['srv_last_daily_update'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo $wrow['srv_last_daily_update']; 
    }
    echo "</div>";

    # Last Edit Date 
    echo "\n\n<div class='server_right_label'>Last Edit Date</div>";
    echo "\n<div class='server_right_data'>";
    if (empty($wrow['srv_last_edit_date'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo $wrow['srv_last_edit_date']; 
    }
    echo "</div>";

    # Secondary IP Address 
    if (! empty($wrow['srv_ips_info'])) { 
       $ipArray  = explode(",",$wrow['srv_ips_info']);
       $ipNumber = sizeof($ipArray);
       $ipLine   = ""; 
       if (count($ipArray) > 1) {
          for ($i = 0; $i < count($ipArray); ++$i) {
              list($Dev,$Ip,$Netmask,$MacAddr) = explode("|", $ipArray[$i] );
              echo "\n\n<div class='server_right_label'>Network Interface(".$i.")</div>";
              echo "\n<div class='server_right_data'>";
              #$info = sprintf ("%-7s %16s / %-15s / %s",$Dev,$Ip,$Netmask,$MacAddr);
              $IpName = gethostbyaddr ( $Ip );
              $info = sprintf ("%-9s %16s %-10s",$Dev,$Ip,$IpName);
              echo $info;
              echo "</div>";
          }   
        }
    }


    # Server Memory 
    echo "\n\n<div class='server_right_label'>Server Memory</div>";
    echo "\n<div class='server_right_data'>";
    if (empty($wrow['srv_memory'])) { echo "&nbsp" ; }else{ echo $wrow['srv_memory'] . " MB" ; }
    echo "</div>";

    # Server NB of CPU and CPU Speed
    echo "\n\n<div class='server_right_label'>Server CPU</div>";
    echo "\n<div class='server_right_data'>";
    if (empty($wrow['srv_nb_cpu'])) { echo "&nbsp" ; }else{ echo $wrow['srv_nb_cpu']  ; }
    if (empty($wrow['srv_cpu_speed'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo " X " . $wrow['srv_cpu_speed'] . " Mhz" ; 
    }
    echo "</div>";

    # Server Nb. of Socket
    echo "\n\n<div class='server_right_label'>Number of CPU Socket</div>";
    echo "\n<div class='server_right_data'>";
    if (empty($wrow['srv_nb_socket'])) { echo "&nbsp" ; }else{ echo $wrow['srv_nb_socket']; }
    echo "</div>";

    # Server Nb. of Core per Socket
    echo "\n\n<div class='server_right_label'>Number of Core per Socket</div>";
    echo "\n<div class='server_right_data'>";
    if (empty($wrow['srv_core_per_socket'])) { echo "&nbsp" ; }else{ echo $wrow['srv_core_per_socket']; }
    echo "</div>";

    # Server Nb. of Thread Per Core
    echo "\n\n<div class='server_right_label'>Thread per Core</div>";
    echo "\n<div class='server_right_data'>";
    if (empty($wrow['srv_thread_per_core'])) { echo "&nbsp" ; }else{ echo $wrow['srv_thread_per_core']; }
    echo "</div>";

    # Server Disk Information
    if (! empty($wrow['srv_disks_info'])) { 
       $pvArray  = explode(",",$wrow['srv_disks_info']);
       $pvNumber = sizeof($pvArray);
       $pvLine   = ""; 
       if (count($pvArray) > 1) {
          for ($i = 0; $i < count($pvArray); ++$i) {
              list($pvDev,$pvSize) = explode("|", $pvArray[$i] );
              echo "\n\n<div class='server_right_label'>Disk Information(".$i.")</div>";
              echo "\n<div class='server_right_data'>";
              $pvSize = $pvSize / 1000 ;
              $info = sprintf ("%-10s %16s GB",$pvDev,$pvSize);
              echo $info;
              echo "</div>";
          }   
        }
    }

    
    # Server VG Information
    if (! empty($wrow['srv_vgs_info'])) { 
       $vgArray  = explode(",",$wrow['srv_vgs_info']);
       $vgNumber = sizeof($vgArray);
       $vgLine   = ""; 
       if (count($vgArray) > 0) {
          for ($i = 0; $i < count($vgArray); ++$i) {
              list($vgName,$vgSize,$vgUse,$vgFree) = explode("|", $vgArray[$i] );
              echo "\n\n<div class='server_right_label'>Volume Group Info.(".$i.")</div>";
              echo "\n<div class='server_right_data'>";
              $vgSize = round($vgSize / 1024) ;
              $vgUse  = round($vgUse  / 1024) ;
              $vgFree = round($vgFree / 1024) ;
              $info = sprintf ("%-15s %-15s GB Use:%-15s Free:%-15s",$vgName,$vgSize,$vgUse,$vgFree);
              echo $info;
              echo "</div>";
          }   
        }
    }
    
    
    # Blank LIne
    #echo "\n\n<div class='server_right_label'>&nbsp</div>";
    #echo "\n<div class='server_right_data'>";
    #echo "&nbsp";
    #echo "</div>";
 

    # Last O/S Update Date 
    echo "\n\n<div class='server_right_label'>Last O/S Update Date</div>";
    echo "\n<div class='server_right_data'>";
    if (empty($wrow['srv_update_date'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo $wrow['srv_update_date']; 
    }
    echo "</div>";

    # Last O/S Update Status
    echo "\n\n<div class='server_right_label'>Last O/S Update Status</div>";
    echo "\n<div class='server_right_data'>";
    if ($wrow['srv_update_status']) { echo "Success" ; }else{ echo "Failed" ; }
    echo "</div>";
    
    # Reboot after Update
    echo "\n\n<div class='server_right_label'>Reboot after O/S Update</div>";
    echo "\n<div class='server_right_data'>";
    if ($wrow['srv_update_reboot'] == 't') { echo "Yes" ; }else{ echo "No" ; }
    echo "</div>";
       
    # Server Auto Update
    echo "\n\n<div class='server_right_label'>Update O/S Automatically</div>";
    echo "\n<div class='server_right_data'>";
    if ($wrow['srv_update_auto'] == 't') { echo "Yes" ; }else{ echo "No" ; }
    echo "</div>";
    
    # Month that O/S Update Can Occurs
    echo "\n\n<div class='server_right_label'>Update O/S Allowed Month(s)</div>";
    echo "\n<div class='server_right_data'>";
    $months = array('Jan','Feb','Mar','Apr','May','Jun','Jul ','Aug','Sep','Oct','Nov','Dec');
    if ($wrow['srv_update_month'] == str_repeat("Y",12)) {
        echo "Any Month";
    }else{
        $mess = "";
        for ($i = 0; $i < 12; $i = $i + 1) {
            if (substr($wrow['srv_update_month'],$i,1) == "Y") {$mess = $mess . $months[$i] . ",";}
        }
        $mess = substr($mess, 0, -1);
        echo $mess;         
    }
    echo "</div>";

    # Date in the Month that O/S Update can Occur
    echo "\n\n<div class='server_right_label'>Update O/S Allowed Date(s)</div>";
    echo "\n<div class='server_right_data'>";
    if ($wrow['srv_update_dom'] == str_repeat("Y",31)) {                 # If it's to run every Day
        echo "Any Date";                                              # Then use a Star
    }else{                                                              # If not to run every Day
        $mess = "";
        for ($i = 0; $i < 31; $i = $i + 1) {
            if (substr($wrow['srv_update_dom'],$i,1) == "Y") {$mess = $mess . $i + 1 . ","; }
        }
        $mess = substr($mess, 0, -1);
        echo $mess;        
    }
    echo "</div>";

    # Day of the week that O/S Update can Occur
    echo "\n\n<div class='server_right_label'>Update O/S Allowed Day(s)</div>";
    echo "\n<div class='server_right_data'>";
    $days = array('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
    if ($wrow['srv_update_dow'] == str_repeat("Y",7)) {                 # If it's to run every Day
        echo "Any Day";                                              # Then use a Star
    }else{                                                              # If not to run every Day
        $mess = "";
        for ($i = 0; $i < 7; $i = $i + 1) {
            if (substr($wrow['srv_update_dow'],$i,1) == "Y") {$mess = $mess . $days[$i] . ",";}
        }
        $mess = substr($mess, 0, -1);
        echo $mess;
    }
    echo "</div>";
    
    # Time of the O/S Update
    echo "\n\n<div class='server_right_label'>Update O/S Time</div>";
    echo "\n<div class='server_right_data'>";
    echo sprintf("%02d",$wrow['srv_update_hour']); 
    echo ":" ;
    echo sprintf("%02d",$wrow['srv_update_minute']);
    echo "</div>";

}





/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/

    # Get the first Parameter (Should be the server name)
    if (isset($_GET['host']) ) {                                        # Get Parameter Expected
        $HOSTNAME = $_GET['host'];                                      # Parameter is Server Name
        if ($DEBUG) {echo "<br>Parameter received is $HOSTNAME\n";}     # Display Parameter Recv.

        # Construct SQL to Read the row
        $query = "SELECT * FROM sadm.server WHERE srv_name = '" . $HOSTNAME ."';";
        if ($DEBUG) { echo "<br>Select statement is $query\n"; }        # Display SQL Query 
        
         # Execute the SQL to Read the Server Row
         $result = pg_query($connection,$query) ;                       # Perform the SQL select
         $NUMROW = pg_num_rows($result) ;                               # Get Nb of rows returned
         if ((!$result) or ($NUMROW == 0))  {                           # If Server not found
            $err_msg = "<br>Server " . $HOSTNAME . " not found in DB";  # Construct msg to user
            $err_msg = $err_msg . pg_last_error() ;                     # Add Postgresql Error Msg
            if ($DEBUG) {                                               # In Debug Insert SQL in Msg
                $err_msg = $err_msg . "<br>\nMaybe a problem with SQL Command ?\n" . $query ;
            }
            echo $err_msg . "<br>" ;                                    # Print Error Message

            # Give chance to user to see Error Message - Wait for user to press "Go Back" Button 
            echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
            echo "<a href='javascript:history.go(-1)'>";            
            echo "<button type='button' class='btn btn-sm btn-primary'>Go Back</button></a>";
            echo "</form>";
            exit;
         }else{
            if ($DEBUG) {                                               # Debug Print Nb Rows
               echo "<br>Number of row(s) returned is ..." . strval(pg_num_rows($result)) . "... " ;
               echo "<br>Result is ..." . $result . "... " ;
            }
            $row = pg_fetch_array($result, null, PGSQL_ASSOC) ;         # Get Data into row Array
         }
     }else{
         $err_msg = "No Parameter Received - Please Advise Administrator" ;
         # Give chance to user to see Error Message - Wait for user to press "Go Back" Button 
         echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
         echo "<a href='javascript:history.go(-1)'>";            
         echo "<button type='button' class='btn btn-sm btn-primary'>Go Back</button></a>";
         echo "</form>";
         exit ;
     }

    sadm_page_heading ("Information about server " . $row['srv_name']); # Display Page Title
    display_server_data ($row);                                         # Display Server Data
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
