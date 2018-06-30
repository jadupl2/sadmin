<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_server_info.php
#   Version     :  1.5
#   Date        :  9 Dec 2016
#   Requires    :  php - MySql
#   Description :  This page allow to view the servers farm information 
#   
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
#   Version 2.0 - October 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
#   2018_01_04 JDuplessis
#       V2.1 Add Button at bottom of page to display more System Information
#   2018_02_08 JDuplessis
#       V2.2 Rework page design and button at bottom of page
#   2018_04_07 JDuplessis
#       V2.3 Change Page & Fixes some bugs
# ==================================================================================================
#
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript</Head>
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.3" ;                                                        # Current version number
$URL_CREATE = '/crud/srv/sadm_server_create.php';                       # Create Page URL
$URL_UPDATE = '/crud/srv/sadm_server_update.php';                       # Update Page URL
$URL_DELETE = '/crud/srv/sadm_server_delete.php';                       # Delete Page URL
$URL_MAIN   = '/crud/srv/sadm_server_main.php';                         # Maintenance Main Page URL
$URL_HOME   = '/index.php';                                             # Site Main Page
$URL_MENU      = '/crud/srv/sadm_server_menu.php';                      # Maintenance Main Menu URL
$CREATE_BUTTON = False ;                                                # Yes Display Create Button



# ==================================================================================================
#                      DISPLAY SERVER DATA USED IN THE DATA INPUT FORM
#
#  wrow  = Array containing table row keys/values
#  mode  = "[D]isplay" Only show row content - Can't modify any information
#        = "[C]reate"  Display default values and user can modify all fields, except the row key
#        = "[U]pdate"  Display row content and user can modify all fields, except the row key
# ==================================================================================================
function display_server_data ($wrow) {
    global $URL_UPDATE, $URL_MENU;
    
    # DISPLAY TOP BUTTONS 
    echo "\n\n<div class='server_top_buttons'>          <!-- Start of Bottom Buttons DIV -->";
    echo "\n<center>";
    display_top_buttons ($wrow);  
    echo "\n</center>";
    echo "\n</div>                                      <!-- End of Bottom Buttons DIV -->";
    echo "\n<br>";
    
    # Server Data Info DIV
    echo "\n\n<div class='server_data'>                 <!-- Start of Server Data DIV -->";

    # DATA LEFT SIDE DIV
    echo "\n\n<div class='server_leftside'>             <!-- Start Data LeftSide  -->";
    display_left_side ($wrow);
    echo "\n\n</div>                                    <!-- End of LeftSide Data -->";

    # DATA RIGHT SIDE DIV
    echo "\n\n<div class='server_rightside'>            <!-- Start RightSide Data  -->";
    display_right_side ($wrow);
    echo "\n\n</div>                                    <!-- End of RightSide Data -->";

    echo "\n<div style='clear: both;'> </div>\n";                       # Clear Move Down Now
    echo "\n</div>                                      <!-- End of Server Data DIV -->";



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
 
    # Server Description
    echo "\n\n<div class='server_left_label'>Description</div>";
    echo "\n<div class='server_left_data'>" . $wrow['srv_desc'] . "</div>";
 
    # Server O/S Type 
    echo "\n\n<div class='server_left_label'>O/S Type</div>";
    echo "\n<div class='server_left_data'>" . ucfirst($wrow['srv_ostype']) . "</div>";
 
    # O/S Name and Version
    echo "\n\n<div class='server_left_label'>O/S Name & Version</div>";
    echo "\n<div class='server_left_data'>";
    echo ucfirst($wrow['srv_osname']) ." (". $wrow['srv_oscodename'] .") ". $wrow['srv_osversion'];
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

    # Server Tag 
    echo "\n\n<div class='server_left_label'>Server Tag</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_tag'])) { echo "&nbsp" ; }else{ echo $wrow['srv_tag'] ; }
    echo "</div>";

    # SADMIN Install Root Directory
    echo "\n\n<div class='server_left_label'>SADMIN Install Dir.</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_sadmin_dir'])) { echo "&nbsp" ; }else{ echo $wrow['srv_sadmin_dir'] ; }
    echo "</div>";

    # Server Note
    echo "\n\n<div class='server_left_label'>Server Note</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_note'])) { echo "&nbsp" ; }else{ echo $wrow['srv_note'] ; }
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
    if ($wrow['srv_active'] == True) { echo "Yes" ; }else{ echo "No" ; }
    echo "</div>";

    # Server Virtual ?
    echo "\n\n<div class='server_left_label'>Virtual/Physical</div>";
    echo "\n<div class='server_left_data'>";
    if ($wrow['srv_vm'] == True) { echo "Virtual" ; }else{ echo "Physical" ; }
    echo "</div>";

    # Server Sporadic
    echo "\n\n<div class='server_left_label'>Online Sporadically</div>";
    echo "\n<div class='server_left_data'>";
    if ($wrow['srv_sporadic'] == True) { echo "Yes" ; }else{ echo "No" ; }
    echo "</div>";

    # Include Server in Performance Graph
    echo "\n\n<div class='server_left_label'>Performance Graph</div>";
    echo "\n<div class='server_left_data'>";
    if ($wrow['srv_graph'] == True) { echo "Yes" ; }else{ echo "No" ; }
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
    echo "\n\n<div class='server_left_label'>Monitor Server</div>";
    echo "\n<div class='server_left_data'>";
    if ($wrow['srv_monitor'] == True) { echo "Yes" ; }else{ echo "No" ; }
    echo "</div>"; 
    
    # Creation Date 
    echo "\n\n<div class='server_left_label'>Creation Date</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_date_creation'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo $wrow['srv_date_creation']; 
    }
    echo "</div>";
    
    # Last Edit Date 
    echo "\n\n<div class='server_left_label'>Last Edit Date</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_date_edit'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo $wrow['srv_date_edit']; 
    }
    echo "</div>";

    # Last Update Date 
    echo "\n\n<div class='server_left_label'>Last Automatic Upd.</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_date_update'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo $wrow['srv_date_update']; 
    }
    echo "</div>";
    
    # Last O/S Update Date 
    echo "\n\n<div class='server_left_label'>Last O/S Update</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_date_osupdate'])) { 
        echo "&nbsp" ; 
    }else{ 
        echo $wrow['srv_date_osupdate']; 
    }
    echo "</div>";
    
    # Last O/S Update Status
    echo "\n\n<div class='server_left_label'>Last O/S Upd. Status</div>";
    echo "\n<div class='server_left_data'>";
    if (empty($wrow['srv_update_status'])) { 
        echo "No Update Yet" ; 
    }else{ 
        $os_status = "Unknown";
        if ($wrow['srv_update_status'] =="R") { $os_status = "Running" ; } 
        if ($wrow['srv_update_status'] =="F") { $os_status = "Failed"  ; } 
        if ($wrow['srv_update_status'] =="S") { $os_status = "Success" ; } 
        echo "$os_status";
    }
    echo "</div>";

}


# ==================================================================================================
#                             DISPLAY RIGHT SIDE OF SERVER DATA 
#                           wrow  = Array containing table row keys/values
# ==================================================================================================
function display_right_side ($wrow) {

    # Secondary IP Address 
    if (! empty($wrow['srv_ips_info'])) { 
       $ipArray  = explode(",",$wrow['srv_ips_info']);
       $ipNumber = sizeof($ipArray);
       $ipLine   = ""; 
       if (count($ipArray) > 0) {
          for ($i = 0; $i < count($ipArray); ++$i) {
              list($Dev,$Ip,$Netmask,$MacAddr) = explode("|", $ipArray[$i] );
              echo "\n\n<div class='server_right_label'>Network Interface(".$i.")</div>";
              echo "\n<div class='server_right_data'>";
              #$info = sprintf ("%-7s %16s / %-15s / %s",$Dev,$Ip,$Netmask,$MacAddr);
              $IpName = gethostbyaddr ( $Ip );
              $info = sprintf ("%-10s  %-17s  %-20s",$Dev,$Ip,$IpName);
              echo $info;
              echo "</div>";
          }   
        }
    }else{
        echo "\n\n<div class='server_right_label'>Network Interface</div>";
        echo "\n<div class='server_right_data'>No Secondary IP</div>";
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
    echo "\n\n<div class='server_right_label'>Nb. of CPU Socket</div>";
    echo "\n<div class='server_right_data'>";
    if (empty($wrow['srv_nb_socket'])) { echo "&nbsp" ; }else{ echo $wrow['srv_nb_socket']; }
    echo "</div>";

    # Server Nb. of Core per Socket
    echo "\n\n<div class='server_right_label'>Nb. of Core per Socket</div>";
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
       #echo "count = " . count($pvArray);
       if (count($pvArray) > 0) {
          for ($i = 0; $i < count($pvArray); ++$i) {
              list($pvDev,$pvSize) = explode("|", $pvArray[$i] );
              echo "\n\n<div class='server_right_label'>Disk " . $i . " Information</div>";
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
 
    # Reboot after Update
    echo "\n\n<div class='server_right_label'>Reboot after O/S Update</div>";
    echo "\n<div class='server_right_data'>";
    if ($wrow['srv_update_reboot'] == True) { echo "Yes" ; }else{ echo "No" ; }
    echo "</div>";
       
    # Server Auto Update
    echo "\n\n<div class='server_right_label'>Update O/S Automatically</div>";
    echo "\n<div class='server_right_data'>";
    if ($wrow['srv_update_auto'] == True) { echo "Yes" ; }else{ echo "No" ; }
    echo "</div>";
    
    # Month that O/S Update Can Occurs
    echo "\n\n<div class='server_right_label'>Update O/S Allowed Mth</div>";
    echo "\n<div class='server_right_data'>";
    $months = array('Jan','Feb','Mar','Apr','May','Jun','Jul ','Aug','Sep','Oct','Nov','Dec');
    if ($wrow['srv_update_month'] == "YNNNNNNNNNNNN" ) {
        echo "Any Month";
    }else{
        $mess = "";
        for ($i = 1; $i < 13; $i = $i + 1) {
            if (substr($wrow['srv_update_month'],$i,1) == "Y") {$mess = $mess . $months[$i] . ",";}
        }
        $mess = substr($mess, 0, -1);
        echo $mess;         
    }
    echo "</div>";

    # Date in the Month that O/S Update can Occur
    echo "\n\n<div class='server_right_label'>Update O/S Allowed Date</div>";
    echo "\n<div class='server_right_data'>";
    if ($wrow['srv_update_dom'] == "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN"){ # If it's to run every Day
        echo "Any Date";                                                # Then use a Star
    }else{                                                              # If not to run every Day
        $mess = "";
        for ($i = 1; $i < 32; $i = $i + 1) {
            if (substr($wrow['srv_update_dom'],$i,1) == "Y") {$mess = $mess . $i + 1 . ","; }
        }
        $mess = substr($mess, 0, -1);
        echo $mess;        
    }
    echo "</div>";

    # Day of the week that O/S Update can Occur
    echo "\n\n<div class='server_right_label'>Update O/S Allowed Days</div>";
    echo "\n<div class='server_right_data'>";
    $days = array('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
    if ($wrow['srv_update_dow'] == "YNNNNNNN") {                        # If it's to run every Day
        echo "Any Day";                                                 # Then use a Star
    }else{                                                              # If not to run every Day
        $mess = "";
        for ($i = 1; $i < 8; $i = $i + 1) {
            if (substr($wrow['srv_update_dow'],$i,1) == "Y") {$mess = $mess . $days[$i-1] . ",";}
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

    # Server Maintenance Mode
    echo "\n\n<div class='server_right_label'>Maintenance Mode</div>";
    echo "\n<div class='server_right_data'>";
    if ($wrow['srv_maintenance'] == True)  { echo "Active" ; }else{ echo "Inactive" ; }
    echo "</div>";

    # Maintenance Mode Start and Stop TimeStamp
    echo "\n\n<div class='server_right_label'>Maintenance Period Start</div>";
    echo "\n<div class='server_right_data'>";
    echo $wrow['srv_maint_date_start'] ;
    echo "\n</div>";
    echo "\n\n<div class='server_right_label'>Maintenance Period End</div>";
    echo "\n<div class='server_right_data'>";
    echo $wrow['srv_maint_date_end'] ;
    echo "\n</div>";    


    # Server Backup 
    echo "\n\n<div class='server_right_label'>Run Backup Script</div>";
    echo "\n<div class='server_right_data'>\n";
    switch ($wrow['srv_backup']) {
        case 0: echo "No Backup Scheduled";
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
    if ($wrow['srv_backup'] != 0) {
        echo " at " . sprintf("%02d",$wrow['srv_backup_hour']) . ":" ;
        echo sprintf("%02d",$wrow['srv_backup_minute']) ;
    }
    echo "</div>";


}



# ==================================================================================================
#                             DISPLAY RIGHT SIDE OF SERVER DATA 
#                           wrow  = Array containing table row keys/values
# ==================================================================================================
function display_top_buttons ($wrow) {
    global $URL_UPDATE, $URL_MENU;
    
    # Display Button to Display System Information
    $wname = "/view/log/sadm_view_file.php";                            # URL that display File Recv
    $fname = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] ."/dr/". $wrow['srv_name'] . "_system.txt";
    if (file_exists($fname)) {                                          # If FileName Received exist
        echo "\n<a href='" . $wname . "?filename=". $fname ;            # Build URL 
        echo "' data-toggle='tooltip' title='View System Information'>";# Tool Tips
        echo "<button type='button'>System Information</button></a>";               # Display Button
    }

    # Display Button to Display Network Information
    $wname = "/view/log/sadm_view_file.php";                            # URL that display File Recv
    $fname = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] ."/dr/". $wrow['srv_name'] . "_network.txt";
    if (file_exists($fname)) {                                          # If FileName Received exist
        echo "\n<a href='" . $wname . "?filename=". $fname ;            # Build URL 
        echo "' data-toggle='tooltip' title='Network Information'>";    # Tool Tips
        echo "<button type='button'>Network Information</button></a>";              # Display Button
    }

    # Display Button to Display System Summary Information
    $wname = "/view/log/sadm_view_file.php";                            # URL that display File Recv
    $fname = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] ."/dr/". $wrow['srv_name'] . "_sysinfo.txt";
    if (file_exists($fname)) {                                          # If FileName Received exist
        echo "\n<a href='" . $wname . "?filename=". $fname ;            # Build URL 
        echo "' data-toggle='tooltip' title='System Summary Info'>";    # Tool Tips
        echo "<button type='button'>Server Summary</button></a>";              # Display Button
    }


    # Display Button to Display CFG2HTML Information
    $fname = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] ."/dr/". $wrow['srv_name'] . ".html";
    $url = "/dat/" . $wrow['srv_name'] ."/dr/". $wrow['srv_name'] . ".html";
    if (file_exists($fname)) {                                          # If FileName Received exist
        echo "\n<a href='" . $url ;                                     # Build URL 
        echo "' data-toggle='tooltip' title='CFG2HTML Information'>";   # Tool Tips
        echo "<button type='button'>Server cfg2html</button></a>";             # Display Button
    }

    # Display Button to Display Disks Information
    $wname = "/view/log/sadm_view_file.php";                            # URL that display File Recv
    $fname = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] ."/dr/". $wrow['srv_name'] . "_diskinfo.txt";
    if (file_exists($fname)) {                                          # If FileName Received exist
        echo "\n<a href='" . $wname . "?filename=". $fname ;            # Build URL 
        echo "' data-toggle='tooltip' title='Disk Information'>";       # Tool Tips
        echo "<button type='button'>Disk(s) Information</button></a>";                # Display Button
    }

    # Display Button to Display LVM Information
    $wname = "/view/log/sadm_view_file.php";                            # URL that display File Recv
    $fname = SADM_WWW_DAT_DIR . "/" . $wrow['srv_name'] ."/dr/". $wrow['srv_name'] . "_lvm.txt";
    if (file_exists($fname)) {                                          # If FileName Received exist
        echo "\n<a href='" . $wname . "?filename=". $fname ;            # Build URL 
        echo "' data-toggle='tooltip' title='LVM Information'>";        # Tool Tips
        echo "<button type='button'>LVM</button></a>";                  # Display Button
    }

    # Display the Update Button
    echo "\n<a href=" . $URL_UPDATE . "?sel=" . $wrow['srv_name'] .">";
    echo "\n<button type='button'>Update Static Information</button></a>";
    echo "\n\n<br>                                          ";
}




# ==================================================================================================
#                                PROGRAM START HERE
# ==================================================================================================
#
    # Get the first Parameter (Should be the server name)
    if (isset($_GET['host']) ) {                                        # Get Parameter Expected
        $HOSTNAME = $_GET['host'];                                      # Parameter is Server Name
        if ($DEBUG) {echo "<br>Parameter received is $HOSTNAME\n";}     # Display Parameter Recv.

        # Construct SQL to Read the row
        $sql = "SELECT * FROM server WHERE srv_name = '" . $HOSTNAME ."'";
        if ($DEBUG) { echo "\n<br>Select statement is $sql\n"; }        # Display SQL Query 
        
        $result = mysqli_query($con,$sql) ;                             # Execute SQL Select
        if (!$result)   {                           # If Server not found
            $err_msg = "<br>Server " . $HOSTNAME . " not found in DB";  # Construct msg to user
            $err_msg = $err_msg . mysqli_error($con) ;                  # Add Postgresql Error Msg
            exit;
        }
        $NUMROW = mysqli_num_rows($result);                             # Get Nb of rows returned

         if ((!$result) or ($NUMROW == 0))  {                           # If Server not found
            $err_msg = "<br>Server " . $HOSTNAME . " not found in DB";  # Construct msg to user
            $err_msg = $err_msg . mysqli_error($con) ;                  # Add Postgresql Error Msg
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
               echo "<br>Number of row(s) returned is ..." . strval($NUMROW) . "... " ;
            }
            $row = mysqli_fetch_assoc($result);
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

    display_std_heading("NotHome","Information about server " . $row['srv_name'],"","",$SVER);
    display_server_data ($row);                                         # Display Server Data
    echo "</div> <!-- End of SimpleTable          -->" ;                # End Of SimpleTable Div
    std_page_footer($con)                                               # Close MySQL & HTML Footer
?>