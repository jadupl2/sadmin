<?php
/*
* ==================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_edit_server.php
*   Version  :  1.5
*   Date     :  2 April 2016
*   Requires :  php
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_constants.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_connect.php');
include           ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php')  ;
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
include           ($_SERVER['DOCUMENT_ROOT'].'/sadmin/sadm_menu.php')  ;
?>
 

/ ================================================================================================
//                                    Main Program Start Here
// ================================================================================================

//      $SERVER_NAME = $_POST['server_name'];   echo "server_name   $SERVER_NAME <br>";
//      $SDATE = $_POST['sdate'];                               echo "sdate   $SDATE  <br>";
//      $EDATE = $_POST['edate'];                               echo "edate   $EDATE  <br>";
//      $STIME = $_POST['stime'];                               echo "stime   $STIME  <br>";
//      $ETIME = $_POST['etime'];                               echo "etime   $ETIME  <br>";

        if (isset($_POST['server_name']) ) {
            $SERVER_NAME = $_POST['server_name'];
                $row = mysql_fetch_array ( mysql_query("SELECT * FROM `servers` WHERE `server_name` = '$SERVER_NAME' "));
                $SERVER_DESC   = $row['server_desc'];
                $SERVER_OS     = $row['server_os'];
        }else{
            echo "The server name was not received !";
                echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
            exit ;
        }

        if (isset($_POST['sdate']) ) {
            $SDATE = str_replace ("-",".",$_POST['sdate']);
        }else{
            echo "The starting date was not received !";
                echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
            exit ;
        }

        if (isset($_POST['edate']) ) {
            $EDATE = str_replace ("-",".",$_POST['edate']);
        }else{
            echo "The ending date was not received !";
                echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
            exit ;
        }

        if (isset($_POST['stime']) ) {
            $STIME = str_replace ("-",".",$_POST['stime']);
        }else{
            echo "The starting time was not received !";
                echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
            exit ;
        }

        if (isset($_POST['etime']) ) {
            $ETIME = str_replace ("-",".",$_POST['etime']);
        }else{
            echo "The ending time was not received !";
                echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
            exit ;
        }

        echo "<center><strong><H1>Performance Graph for $SERVER_OS server $SERVER_NAME - $SERVER_DESC</strong></H1></center><br>";

        