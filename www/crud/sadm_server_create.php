<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis 
#   Email       :  jacques.duplessis@sadmin.ca
#   Title       :  sadm_server_create.php
#   Version     :  1.8
#   Date        :  13 June 2016
#   Requires    :  php - BootStrap - PostGresSql
#   Description :  Web Page used to create a new server.
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
#
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_init.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/crud/sadm_server_common.php');


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                       # Activate (TRUE) or Deactivate (FALSE) Debug





# ==================================================================================================
#                                      PROGRAM START HERE
# ==================================================================================================
 

    # Form is submitted - Process the Insertion of the row
    if (isset($_POST['submitted'])) {
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }
        if ($DEBUG) { echo "<br>Post Submitted for " . sadm_clean_data($_POST['scr_name']); }
        

        $wmonth=$_POST['scr_update_month'];
    	if (empty($wmonth)) { for ($i = 0; $i < 12; $i = $i + 1) { $wmonth[$i] = $i; } }
        $wstr=str_repeat('N',12);
        foreach ($wmonth as $p) { $wstr=substr_replace($wstr,'Y',intval($p),1); }
        $pmonth=$wstr;

        $wdom=$_POST['scr_update_dom'];
    	if (empty($wdom)) { for ($i = 0; $i < 31; $i = $i + 1) { $wdom[$i] = $i; } }
        $wstr=str_repeat('N',31);
        foreach ($wdom as $p) { $wstr=substr_replace($wstr,'Y',intval($p),1); }
        $pdom=$wstr;

        $wdow=$_POST['scr_update_dow'];
    	if (empty($wdow)) { for ($i = 0; $i < 7; $i = $i + 1) { $wdow[$i] = $i; } }
        $wstr=str_repeat('N',7);
        foreach ($wdow as $p) { $wstr=substr_replace($wstr,'Y',intval($p),1); }
        $pdow=$wstr;
        
        # Construct SQL to Insert row
        $sql = "INSERT INTO sadm.server ";
        $sql = $sql . "(srv_name, srv_desc, srv_cat, srv_domain, srv_notes, srv_tag, srv_sporadic,
                        srv_backup, srv_monitor, srv_update_auto, srv_update_reboot,
                        srv_update_hour, srv_update_minute, srv_maintenance,
                        srv_update_month, srv_update_dom, srv_update_dow,
                        srv_last_edit_date, srv_creation_date, srv_ostype,
                        srv_active) ";
        $sql = $sql . " VALUES ('" .  $_POST['scr_name'] . "','" ;
        $sql = $sql . $_POST['scr_desc']          . "','" ;
        $sql = $sql . $_POST['scr_cat']           . "','" ;
        $sql = $sql . $_POST['scr_domain']        . "','" ;
        $sql = $sql . $_POST['scr_notes']         . "','" ;
        $sql = $sql . $_POST['scr_tag']           . "','" ;
        $sql = $sql . $_POST['scr_sporadic']      . "','" ;
        #
        $sql = $sql . $_POST['scr_backup']        . "','" ;
        $sql = $sql . $_POST['scr_monitor']       . "','" ;
        $sql = $sql . $_POST['scr_update_auto']   . "','" ;
        $sql = $sql . $_POST['scr_update_reboot'] . "','" ;
        #
        $sql = $sql . $_POST['scr_update_hour']   . "','";
        $sql = $sql . $_POST['scr_update_minute'] . "','";
        $sql = $sql . $_POST['scr_maintenance']   . "','";
        #
        $sql = $sql . $pmonth                     . "','";
        $sql = $sql . $pdom                       . "','";
        $sql = $sql . $pdow                       . "','";
        #
        $sql = $sql . date("Y-m-d H:i:s")         . "','" ;
        $sql = $sql . date("Y-m-d H:i:s")         . "','" ;
        $sql = $sql . $_POST['scr_ostype']        . "','" ;
        #
        $sql = $sql . $_POST['scr_active']       . "')"  ;
        if ($DEBUG) { echo "<br>Execute SQL Command = $sql"; }

        # Execute the Row Insertion SQL
        $row = pg_query($sql) ;
        if (!$row){
            $err_msg = "ERROR : Row was not inserted\n";
            $err_msg = $err_msg . pg_last_error() . "\n";
            if ($DEBUG) { $err_msg = $err_msg . "\nProblem with Command :" . $sql ; }
            sadm_alert ($err_msg) ;
        }else{
            # Go Update the SADMIN crontab 
            update_crontab (SADM_UPDATE_SCRIPT . " " . $_POST['scr_name'],'C',$pmonth,
                $pdom,$pdow,$_POST['scr_update_hour'], $_POST['scr_update_minute']) ;
            sadm_alert ("Server '" . $_POST['scr_name'] . "' inserted.");
        }

        # frees the memory and data associated with the specified PostgreSQL query result
        pg_free_result($row);

        # Back to Server List Page
        ?> <script> location.replace("/crud/sadm_server_main.php"); </script><?php
        exit;
    }
    
    
    # Display initial page for Insertion 
    $title = "Create a Server" ;                                        # Page Heading Title
    sadm_page_heading ("$title");                                       # Display Page Heading  

    # Start of Form - Display Form Ready to Accept Data
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_server_form( $row , "C");                                   # Display Form Default Value
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "<input type='hidden' value='1' name='submitted' />";
    
    # Display Buttons at the bottom of the form
    echo "<center>";
    echo "<button type='submit' class='btn btn-sm btn-primary'>Create</button>   ";
    echo "<a href='/crud/sadm_server_main.php'>";
    echo "<button type='button' class='btn btn-sm btn-primary'>Cancel</button></a>";
    echo "</center>";
    
    # End of Form
    echo "</form>"; 
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
