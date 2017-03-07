<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_server_update.php
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

        # Construct SQL to Update row
        $sql = "UPDATE sadm.server SET ";
        $sql = $sql . "srv_name = '"          . sadm_clean_data($_POST['scr_name'])          ."', ";
        $sql = $sql . "srv_desc = '"          . sadm_clean_data($_POST['scr_desc'])          ."', ";
        $sql = $sql . "srv_cat  = '"          . sadm_clean_data($_POST['scr_cat'])           ."', ";
        $sql = $sql . "srv_domain = '"        . sadm_clean_data($_POST['scr_domain'])        ."', ";
        $sql = $sql . "srv_tag = '"           . sadm_clean_data($_POST['scr_tag'])           ."', ";
        $sql = $sql . "srv_notes = '"         . sadm_clean_data($_POST['scr_notes'])         ."', ";
        $sql = $sql . "srv_sporadic = '"      . sadm_clean_data($_POST['scr_sporadic'])      ."', ";
        $sql = $sql . "srv_backup = '"        . sadm_clean_data($_POST['scr_backup'])        ."', ";
        $sql = $sql . "srv_monitor = '"       . sadm_clean_data($_POST['scr_monitor'])       ."', ";
        $sql = $sql . "srv_update_auto = '"   . sadm_clean_data($_POST['scr_update_auto'])   ."', ";
        $sql = $sql . "srv_update_reboot = '" . sadm_clean_data($_POST['scr_update_reboot']) ."', ";

        $wmonth=$_POST['scr_update_month'];
    	if (empty($wmonth)) { for ($i = 0; $i < 12; $i = $i + 1) { $wmonth[$i] = $i; } }
        $wstr=str_repeat('N',12);
        foreach ($wmonth as $p) { $wstr=substr_replace($wstr,'Y',intval($p),1); }
        $sql = $sql . "srv_update_month = '"  . $wstr  ."', ";
        $pmonth = trim($wstr);                                                # Save for crontab
        
        $wdom=$_POST['scr_update_dom'];
    	if (empty($wdom)) { for ($i = 0; $i < 31; $i = $i + 1) { $wdom[$i] = $i; } }
        $wstr=str_repeat('N',31);
        foreach ($wdom as $p) { $wstr=substr_replace($wstr,'Y',intval($p),1); }
        $sql = $sql . "srv_update_dom = '"    . $wstr  ."', ";
        $pdom = trim($wstr) ;                                                 # Save for crontab

        $wdow=$_POST['scr_update_dow'];
    	if (empty($wdow)) { for ($i = 0; $i < 7; $i = $i + 1) { $wdow[$i] = $i; } }
        $wstr=str_repeat('N',7);
        foreach ($wdow as $p) { $wstr=substr_replace($wstr,'Y',intval($p),1); }
        $sql = $sql . "srv_update_dow = '"  . $wstr  ."', ";
        $pdow = trim($wstr) ;                                                 # Save for crontab

        $sql = $sql . "srv_update_hour = '"   . sadm_clean_data($_POST['scr_update_hour'])   ."', ";
        $sql = $sql . "srv_update_minute = '" . sadm_clean_data($_POST['scr_update_minute']) ."', ";
        $sql = $sql . "srv_maintenance = '"   . sadm_clean_data($_POST['scr_maintenance'])   ."', ";
        $sql = $sql . "srv_last_edit_date = '". date("Y-m-d H:i:s")                          ."', ";
        $sql = $sql . "srv_ostype        = '" . sadm_clean_data($_POST['scr_ostype'])        ."', ";
        $sql = $sql . "srv_active        = '" . sadm_clean_data($_POST['scr_active'])        ."'  ";
        $sql = $sql . "WHERE srv_name = '"    . sadm_clean_data($_POST['scr_name'])          ."'; ";
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

        # Go Update the SADMIN crontab 
        if ($_POST['scr_ostype'] == "linux") {
            if (! $_POST['scr_update_auto']) { $MODE = "D"; }else{ $MODE = "U" ; }
            update_crontab (SADM_UPDATE_SCRIPT . " " . $_POST['scr_name'],$MODE,$pmonth,$pdom,$pdow, 
                    $_POST['scr_update_hour'], $_POST['scr_update_minute']) ;
        }
        # Back to server List Page
        #header("Location: {$_SERVER['HTTP_REFERER']}");
		#?> <script> location.replace("/crud/sadm_server_main.php"); </script><?php
		#?> <script> location.replace($_SERVER['HTTP_REFERER']); </script><?php
		?> <script> goBack() ; </script><?php
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
