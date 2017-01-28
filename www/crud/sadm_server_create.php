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
        
        # Construct SQL to Insert row
        $sql = "INSERT INTO sadm.server ";
        $sql = $sql . "(srv_name, srv_desc, srv_cat, srv_domain, srv_notes, srv_tag, srv_sporadic,
                        srv_backup, srv_monitor, srv_osupdate, srv_osupdate_reboot,
                        srv_osupdate_day, srv_osupdate_period, srv_osupdate_start_month,
                        srv_osupdate_week1, srv_osupdate_week2, srv_osupdate_week3,
                        srv_osupdate_week4, srv_osupdate_date, srv_ostype,
                        srv_active) ";
        $sql = $sql . " VALUES ('" .  $_POST['scr_name'] . "','" ;
        $sql = $sql . $_POST['scr_desc']         . "','" ;
        $sql = $sql . $_POST['scr_cat']          . "','" ;
        $sql = $sql . $_POST['scr_domain']       . "','" ;
        $sql = $sql . $_POST['scr_notes']        . "','" ;
        $sql = $sql . $_POST['scr_tag']          . "','" ;
        $sql = $sql . $_POST['scr_sporadic']     . "','" ;
        $sql = $sql . $_POST['scr_backup']       . "','" ;
        $sql = $sql . $_POST['scr_monitor']      . "','" ;
        $sql = $sql . $_POST['scr_osupdate']      . "','" ;
        $sql = $sql . $_POST['scr_osupdate_reboot']      . "','" ;
        $sql = $sql . $_POST['scr_osupdate_day']      . "','" ;
        $sql = $sql . $_POST['scr_osupdate_period']      . "','" ;
        $sql = $sql . $_POST['scr_osupdate_start_month']      . "','" ;
        if ($_POST['scr_osupdate_week1'] == True) { $sql = $sql . "1"  . "','" ; }
        if ($_POST['scr_osupdate_week1'] != True) { $sql = $sql . "0"  . "','" ; }
        if ($_POST['scr_osupdate_week2'] == True) { $sql = $sql . "1"  . "','" ; }
        if ($_POST['scr_osupdate_week2'] != True) { $sql = $sql . "0"  . "','" ; }
        if ($_POST['scr_osupdate_week3'] == True) { $sql = $sql . "1"  . "','" ; }
        if ($_POST['scr_osupdate_week3'] != True) { $sql = $sql . "0"  . "','" ; }
        if ($_POST['scr_osupdate_week4'] == True) { $sql = $sql . "1"  . "','" ; }
        if ($_POST['scr_osupdate_week4'] != True) { $sql = $sql . "0"  . "','" ; }
        
        # ReCalculate the Next O/S Update Date
        #$srv_osupdate_date = date("Y/m/d") ;
        $srv_osupdate_date = "2032/01/01" ; 
#        $srv_osupdate_date = calculate_osupdate_date($scr_osupdate_start_month,$srv_osupdate_period,
#             $srv_osupdate_week1,$srv_osupdate_week2,$srv_osupdate_week3,$srv_osupdate_week4,
#             $srv_osupdate_day);
        $sql = $sql . $srv_osupdate_date      . "','" ;
        $sql = $sql . $_POST['scr_ostype']      . "','" ;
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
            sadm_alert ("Server '" . sadm_clean_data($_POST['scr_name']) . "' inserted.");
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
