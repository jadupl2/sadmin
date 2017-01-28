<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_server_edit.php
*   Version     :  1.8
*   Date        :  13 June 2016
*   Requires    :  php - BootStrap - PostGresSql
*   Description :  Web Page used to edit a server.
*
*   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/crud/sadm_server_common.php');


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                       # Activate (TRUE) or Deactivate (FALSE) Debug



/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/

    
    # THIS SECTION IS EXECUTED WHEN THE UPDATE BUTTON IS PRESS
    # ----------------------------------------------------------------------------------------------
    
    # Form is submitted - Process the Update of the selected row
    if (isset($_POST['submitted'])) {
        if ($DEBUG) { echo "<br>Post Submitted for " . sadm_clean_data($_POST['scr_name']); }
        foreach($_POST AS $key => $value) { $_POST[$key] = $value; }
        
        if ($DEBUG) {
            echo "<br>Week2 = " . $_POST['scr_osupdate_week2'];
            if ($_POST['scr_osupdate_week2'] == True)  { echo "<br>Week2 Bool is True" ; }
            if ($_POST['scr_osupdate_week2'] == False) { echo "<br>Week2 Bool is False" ; }
            echo "<br>Week3 = " . $_POST['scr_osupdate_week3'];
            if ($_POST['scr_osupdate_week3'] == True)  { echo "<br>Week3 Bool is True" ; }
            if ($_POST['scr_osupdate_week3'] == False) { echo "<br>Week3 Bool is False" ; }            
            echo "<br>Week4 = " . $_POST['scr_osupdate_week4'];
            if ($_POST['scr_osupdate_week4'] == True)  { echo "<br>Week4 Bool is True" ; }
            if ($_POST['scr_osupdate_week4'] == False) { echo "<br>Week4 Bool is False" ; }
        }
       
        # Construct SQL to Update row
        $sql = "UPDATE sadm.server SET ";
        $sql = $sql . "srv_name   = '"          . sadm_clean_data($_POST['scr_name'])            ."', ";
        $sql = $sql . "srv_desc   = '"          . sadm_clean_data($_POST['scr_desc'])            ."', ";
        $sql = $sql . "srv_cat    = '"          . sadm_clean_data($_POST['scr_cat'])             ."', ";
        $sql = $sql . "srv_domain = '"          . sadm_clean_data($_POST['scr_domain'])          ."', ";
        $sql = $sql . "srv_tag    = '"          . sadm_clean_data($_POST['scr_tag'])             ."', ";
        $sql = $sql . "srv_notes  = '"          . sadm_clean_data($_POST['scr_notes'])           ."', ";
        $sql = $sql . "srv_sporadic = '"        . sadm_clean_data($_POST['scr_sporadic'])        ."', ";
        $sql = $sql . "srv_backup   = '"        . sadm_clean_data($_POST['scr_backup'])          ."', ";
        $sql = $sql . "srv_monitor  = '"        . sadm_clean_data($_POST['scr_monitor'])         ."', ";
        $sql = $sql . "srv_osupdate = '"        . sadm_clean_data($_POST['scr_osupdate'])        ."', ";
        $sql = $sql . "srv_osupdate_reboot = '" . sadm_clean_data($_POST['scr_osupdate_reboot']) ."', ";
        $sql = $sql."srv_osupdate_start_month = '".sadm_clean_data($_POST['scr_osupdate_start_month'])."', ";
        $sql = $sql . "srv_osupdate_day = '"    . sadm_clean_data($_POST['scr_osupdate_day'])    ."', ";
        $sql = $sql . "srv_osupdate_period = '" . sadm_clean_data($_POST['scr_osupdate_period']) ."', ";
        if ($_POST['scr_osupdate_week1'] == True) { $sql = $sql . "srv_osupdate_week1 = '1', "; }
        if ($_POST['scr_osupdate_week1'] != True) { $sql = $sql . "srv_osupdate_week1 = '0', "; }
        if ($_POST['scr_osupdate_week2'] == True) { $sql = $sql . "srv_osupdate_week2 = '1', "; }
        if ($_POST['scr_osupdate_week2'] != True) { $sql = $sql . "srv_osupdate_week2 = '0', "; }
        if ($_POST['scr_osupdate_week3'] == True) { $sql = $sql . "srv_osupdate_week3 = '1', "; }
        if ($_POST['scr_osupdate_week3'] != True) { $sql = $sql . "srv_osupdate_week3 = '0', "; }
        if ($_POST['scr_osupdate_week4'] == True) { $sql = $sql . "srv_osupdate_week4 = '1', "; }
        if ($_POST['scr_osupdate_week4'] != True) { $sql = $sql . "srv_osupdate_week4 = '0', "; }
        #$sql = $sql . "srv_last_edit_date = '" . sadm_clean_data($_POST['scr_last_edit_date']) ."', ";
        $sql = $sql . "srv_last_edit_date = '" . date("Y-m-d H:i:s")  . "', ";
 
        
        # ReCalculate the Next O/S Update Date
        #$srv_osupdate_date = calculate_osupdate_date($srv_osupdate_start_month,$srv_osupdate_period,
        #     $srv_osupdate_week1,$srv_osupdate_week2,$srv_osupdate_week3,$srv_osupdate_week4,
        #     $srv_osupdate_day);
        #$sql = $sql . "srv_osupdate_date = '"   . sadm_clean_data($_POST['scr_osupdate_date']) ."', ";
        $sql = $sql . "srv_osupdate_date = '"   . "2016-11-16" ."', ";
        $sql = $sql . "srv_ostype        = '"   . sadm_clean_data($_POST['scr_ostype'])        ."', ";
        $sql = $sql . "srv_active        = '"   . sadm_clean_data($_POST['scr_active'])        ."'  ";
        $sql = $sql . "WHERE srv_name = '"      . sadm_clean_data($_POST['scr_name'])          ."'; ";
        if ($DEBUG) { echo "<br>Update SQL Command = $sql"; }

        # Execute the Row Update SQL
        $row = pg_query($sql) ;
        if (!$row){
            $err_msg = "ERROR : Row was not updated\n";
            $err_msg = $err_msg . pg_last_error() . "\n";
            if ($DEBUG) { $err_msg = $err_msg . "\nProblem with Command :" . $sql ; }
            #sadm_alert ($err_msg) ;
        }else{
            sadm_alert ("Server '" . sadm_clean_data($_POST['scr_name']) . "' updated.");
        }

        # frees the memory and data associated with the specified PostgreSQL query result
        pg_free_result($row);

        # Back to server List Page
        ?> <script> location.replace("/crud/sadm_server_main.php"); </script><?php
        exit;
    }

        
    # INITIAL PAGE EXECUTION - DISPLAY FORM WITH CORRESPONDING ROW DATA
    # ----------------------------------------------------------------------------------------------

    # Check if the Key Received, exist in the Database and retrieve the row Data    
    if (isset($_GET['sel']) ) {
        $wkey = $_GET['sel'];
        if ($DEBUG) { echo "<br>Post is not Submitted - Read Key " . $wkey; }

        # Construct SQL to Read the row
        $query = "SELECT * FROM sadm.server WHERE srv_name = '" . $wkey ."';";
        if ($DEBUG) { echo "<br>SQL = $query"; }
        
         # Execute the SQL to Read the Row
         $result = pg_query($query) ;
         $NUMROW = pg_num_rows($result) ;
         if ((!$result) or ($NUMROW == 0))  {
            $err_msg = "ERROR : The row of server " . $wkey . " was not found in Database";
            $err_msg = $err_msg . pg_last_error() . "\n";
            if ($DEBUG) { $err_msg = $err_msg . "\nMaybe a problem with SQL Command ?\n" . $query ;}
            sadm_alert ($err_msg) ;  
            exit;
        }else{
           $row = pg_fetch_array($result, null, PGSQL_ASSOC) ;
        }
    }else{
        $err_msg = "No Key Received - Please Advice" ;
        sadm_alert ($err_msg) ;
        exit ;
    }
    
    # Display initial page for Row Update 
    $title = "Update Server" ;                                          # Page Heading Title
    sadm_page_heading ("$title");                                       # Display Page Heading  

    # Start of Form - Display Form Ready to Update Data
    echo "<form action='" . htmlentities($_SERVER['PHP_SELF']) . "' method='POST'>"; 
    display_server_form( $row , "U");                                   # Display Form Default Value
    
    # Set the Submitted Flag On - We are done with the Form Data
    echo "<input type='hidden' value='1' name='submitted' />";
    
    # Display Buttons at the bottom of the form
    echo "<center>";
    echo "<button type='submit' class='btn btn-sm btn-primary'>Update </button>   ";
    echo "<a href='/crud/sadm_server_main.php'>";
    echo "<button type='button' class='btn btn-sm btn-primary'> Cancel</button></a>";
    echo "</center>";
    
    # End of Form
    echo "</form>"; 
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
