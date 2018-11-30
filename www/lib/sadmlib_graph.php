<?php
# ================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadmlib_graph.php
#   Version  :  1.0
#   Date     :  25 January 2018
#   Requires :  php
#   Synopsis :  Library of functions to produce Performance Library
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
# ChangeLog
#   2018_01_31 JDuplessis
#       V 1.0 Initial WIP
#
# ==================================================================================================
#



#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG  = False  ;                                                      # Debug Activated True/False
$SVER   = "1.0" ;                                                       # Current version number




# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
#   WHOST_NAME  = Name of Host          RRDTOOL = Path to rrdtool   WRRD   = Name of RRD      
#   WSTART      = "HH:MM DD.MM.YY"      WEND    = HH:MM DD.MM.YY    WTITLE = Graph Title
#   WPNG        = Path PNG to create    WSIZE   = B/S (Big/Small)   DEBUG  = True/False
# ==================================================================================================
function create_cpu_graph($WHOST_NAME,$RRDTOOL,$WRRD,$WSTART,$WEND,$WTITLE,$WPNG,$WSIZE,$DEBUG)
{
    if (file_exists($WPNG)) { unlink($WPNG); }                          # Make sure png don't exist
    $CMD     = "$RRDTOOL graph $WPNG -s \"$WSTART\" -e \"$WEND\"";      # rrdtool gph filename 
    $CMD    .= " --title \"$WTITLE\" ";                                 # Insert Title in Command
    $CMD    .= "--vertical-label \"percentage(%)\" ";                   # Set Vertical Legend
    if (strtoupper($WSIZE) == "B") {                                    # If Want Big Graph
       $CMD .= " --height 250 --width 950 ";                            # Set to Big Graphic Size
    }else{
       $CMD .= " --height 125 --width 250 ";                            # Set to Small Graphic Size
    }
    $CMD .= "--upper-limit 100 --lower-limit 0 ";                       # Set Upper & Lower Limit
    $CMD .= " DEF:total=$WRRD:cpu_total:MAX DEF:user=$WRRD:cpu_user:MAX ";
    $CMD .= " DEF:sys=$WRRD:cpu_sys:MAX DEF:wait=$WRRD:cpu_wait:MAX ";
    $CMD .= " CDEF:csys=user,sys,+ CDEF:cwait=user,sys,wait,+,+  ";
    $CMD .= " AREA:cwait#99CC96:\"% Wait\" AREA:csys#CC3333:\"% Sys\" ";
    $CMD .= " AREA:user#336699:\"% User\" LINE2:total#000000:\"% total\" ";
    if ($DEBUG) { echo "\n<br>CMD:" . $CMD ; }                          # Show RRDTool Command used
    $outline    = exec ("$CMD", $array_out, $retval);                   # Run rrdtool Generate Graph
    if ($DEBUG) { echo "\n<br>Return Value is $retval" ; }              # Show Return Code of CMD
}




# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
#   WHOST_NAME  = Name of Host          RRDTOOL = Path to rrdtool   WRRD   = Name of RRD      
#   WSTART      = "HH:MM DD.MM.YY"      WEND    = HH:MM DD.MM.YY    WTITLE = Graph Title
#   WPNG        = Path PNG to create    WSIZE   = B/S (Big/Small)   DEBUG  = True/False
# ==================================================================================================
function create_runq_graph($WHOST_NAME,$RRDTOOL,$WRRD,$WSTART,$WEND,$WTITLE,$WPNG,$WSIZE,$DEBUG)
{
    if (file_exists($WPNG)) { unlink($WPNG); }                          # Make sure png don't exist
    $CMD     = "$RRDTOOL graph $WPNG -s \"$WSTART\" -e \"$WEND\"";      # rrdtool gph filename 
    $CMD    .= " --title \"$WTITLE\" ";                                 # Insert Title in Command
    $CMD    .= "--vertical-label \"Load\"";                             # Set Vertical Legend
    if (strtoupper($WSIZE) == "B") {                                    # If Want Big Graph
       $CMD .= " --height 250 --width 950 ";                            # Set to Big Graphic Size
    }else{
       $CMD .= " --height 125 --width 250 ";                            # Set to Small Graphic Size
    }
    $CMD .= " DEF:runque=$WRRD:proc_runq:MAX AREA:runque#CC9A57:";
    $CMD .= "\"Number of tasks waiting for CPU resources\"";
    $CMD .= " DEF:runq=$WRRD:proc_runq:MAX LINE2:runq#000000:";
    if ($DEBUG) { echo "\n<br>CMD:" . $CMD ; }                          # Show RRDTool Command used
    $outline    = exec ("$CMD", $array_out, $retval);                   # Run rrdtool Generate Graph
    if ($DEBUG) { echo "\n<br>Return Value is $retval" ; }              # Show Return Code of CMD
}


# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
#   WHOST_NAME  = Name of Host          RRDTOOL = Path to rrdtool   WRRD   = Name of RRD      
#   WSTART      = "HH:MM DD.MM.YY"      WEND    = HH:MM DD.MM.YY    WTITLE = Graph Title
#   WPNG        = Path PNG to create    WSIZE   = B/S (Big/Small)   DEBUG  = True/False
# ==================================================================================================
function create_mem_graph($WHOST_NAME,$RRDTOOL,$WRRD,$WSTART,$WEND,$WTITLE,$WPNG,$WSIZE,$DEBUG)
{
    if (file_exists($WPNG)) { unlink($WPNG); }                          # Make sure png don't exist
    $CMD     = "$RRDTOOL graph $WPNG -s \"$WSTART\" -e \"$WEND\"";      # rrdtool gph filename 
    $CMD    .= " --title \"$WTITLE\" ";                                 # Insert Title in Command
    $CMD    .= "--vertical-label \"in MB\"";                            # Set Vertical Legend
    if (strtoupper($WSIZE) == "B") {                                    # If Want Big Graph
       $CMD .= " --height 250 --width 950 ";                            # Set to Big Graphic Size
    }else{
       $CMD .= " --height 125 --width 250 ";                            # Set to Small Graphic Size
    }
    $CMD .= "--upper-limit 100 --lower-limit 0";                       # Set Upper & Lower Limit
    $CMD .= " DEF:memused=$WRRD:mem_used:MAX DEF:memfree=$WRRD:mem_free:MAX";
    $CMD .= " CDEF:memtotal=memused,memfree,+ ";
    $CMD .= " AREA:memused#294052:\"Memory Use\" ";
    $CMD .= " LINE2:memtotal#000000:\"Total Memory\" ";
    if ($DEBUG) { echo "\n<br>CMD:" . $CMD ; }                          # Show RRDTool Command used
    $outline    = exec ("$CMD", $array_out, $retval);                   # Run rrdtool Generate Graph
    if ($DEBUG) { echo "\n<br>Return Value is $retval" ; }              # Show Return Code of CMD
}


# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
#   WHOST_NAME  = Name of Host          RRDTOOL = Path to rrdtool   WRRD   = Name of RRD      
#   WSTART      = "HH:MM DD.MM.YY"      WEND    = HH:MM DD.MM.YY    WTITLE = Graph Title
#   WPNG        = Path PNG to create    WSIZE   = B/S (Big/Small)   DEBUG  = True/False
# ==================================================================================================
function create_disk_graph($WHOST_NAME,$RRDTOOL,$WRRD,$WSTART,$WEND,$WTITLE,$WPNG,$WSIZE,$DEBUG)
{
    if (file_exists($WPNG)) { unlink($WPNG); }                          # Make sure png don't exist
    $CMD  = "$RRDTOOL graph $WPNG -s \"$WSTART\" -e \"$WEND\"";         # rrdtool gph filename 
    $CMD .= " --title \"$WTITLE\" ";                                    # Insert Title in Command
    $CMD .= "--vertical-label \"MB/Second\"";                           # Set Vertical Legend
    if (strtoupper($WSIZE) == "B") {                                    # If Want Big Graph
       $CMD .= " --height 250 --width 950 ";                            # Set to Big Graphic Size
    }else{
       $CMD .= " --height 125 --width 250 ";                            # Set to Small Graphic Size
    }
    #$CMD .= " DEF:read=$WRRD:disk_kbread_sec:MAX DEF:write=$WRRD:disk_kbwrtn_sec:MAX ";
    #$CMD .= " LINE2:read#000000:\"DISKS Read MB/Sec\"  LINE2:write#0000FF:\"Disks Write MB/Sec\"";
    $CMD .= " DEF:read=$WRRD:disk_kbread_sec:MAX  AREA:read#DC143C:\"Disk Read per second\" ";
    $CMD .= " DEF:write=$WRRD:disk_kbwrtn_sec:MAX AREA:write#0000FF:\"Disk Write per second\" ";
    if ($DEBUG) { echo "\n<br>CMD:" . $CMD ; }                          # Show RRDTool Command used
    $outline    = exec ("$CMD", $array_out, $retval);                   # Run rrdtool Generate Graph
    if ($DEBUG) { echo "\n<br>Return Value is $retval" ; }              # Show Return Code of CMD
}


# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
#   WHOST_NAME  = Name of Host          RRDTOOL = Path to rrdtool   WRRD   = Name of RRD      
#   WSTART      = "HH:MM DD.MM.YY"      WEND    = HH:MM DD.MM.YY    WTITLE = Graph Title
#   WPNG        = Path PNG to create    WSIZE   = B/S (Big/Small)   DEBUG  = True/False
# ==================================================================================================
function create_paging_graph($WHOST_NAME,$RRDTOOL,$WRRD,$WSTART,$WEND,$WTITLE,$WPNG,$WSIZE,$DEBUG)
{
    if (file_exists($WPNG)) { unlink($WPNG); }                          # Make sure png don't exist
    $CMD  = "$RRDTOOL graph $WPNG -s \"$WSTART\" -e \"$WEND\"";         # rrdtool gph filename 
    $CMD .= " --title \"$WTITLE\" ";                                    # Insert Title in Command
    $CMD .= "--vertical-label \"Pages/Second\"";                        # Set Vertical Legend
    if (strtoupper($WSIZE) == "B") {                                    # If Want Big Graph
       $CMD .= " --height 250 --width 950 ";                            # Set to Big Graphic Size
    }else{
       $CMD .= " --height 125 --width 250 ";                            # Set to Small Graphic Size
    }
    $CMD .= " DEF:page_in=$WRRD:page_in:MAX   AREA:page_in#D50A09:\"Pages In \"";
    $CMD .= " DEF:page_out=$WRRD:page_out:MAX AREA:page_out#0000FF:\"Pages Out \"";
    if ($DEBUG) { echo "\n<br>CMD:" . $CMD ; }                          # Show RRDTool Command used
    $outline    = exec ("$CMD", $array_out, $retval);                   # Run rrdtool Generate Graph
    if ($DEBUG) { echo "\n<br>Return Value is $retval" ; }              # Show Return Code of CMD
}



# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
#   WHOST_NAME  = Name of Host          RRDTOOL = Path to rrdtool   WRRD   = Name of RRD      
#   WSTART      = "HH:MM DD.MM.YY"      WEND    = HH:MM DD.MM.YY    WTITLE = Graph Title
#   WPNG        = Path PNG to create    WSIZE   = B/S (Big/Small)   DEBUG  = True/False
# ==================================================================================================
function create_swap_graph($WHOST_NAME,$RRDTOOL,$WRRD,$WSTART,$WEND,$WTITLE,$WPNG,$WSIZE,$DEBUG)
{
    if (file_exists($WPNG)) { unlink($WPNG); }                          # Make sure png don't exist
    $CMD  = "$RRDTOOL graph $WPNG -s \"$WSTART\" -e \"$WEND\"";         # rrdtool gph filename 
    $CMD .= " --title \"$WTITLE\" ";                                    # Insert Title in Command
    $CMD .= " --vertical-label \"in MB\"";                              # Set Vertical Legend
    #$CMD .= " --upper-limit 100 --lower-limit 0 ";                      # Set Upper/Lower Baseline
    if (strtoupper($WSIZE) == "B") {                                    # If Want Big Graph
       $CMD .= " --height 250 --width 950 ";                            # Set to Big Graphic Size
    }else{
       $CMD .= " --height 125 --width 250 ";                            # Set to Small Graphic Size
    }
    $CMD .= " DEF:page_used=$WRRD:page_used:MAX   AREA:page_used#83AFE5:\"Virtual Memory Use\" ";
    $CMD .= " DEF:page_total=$WRRD:page_total:MAX LINE2:page_total#000000:\"Total Virtual Memory\"";
    if ($DEBUG) { echo "\n<br>CMD:" . $CMD ; }                          # Show RRDTool Command used
    $outline    = exec ("$CMD", $array_out, $retval);                   # Run rrdtool Generate Graph
    if ($DEBUG) { echo "\n<br>Return Value is $retval" ; }              # Show Return Code of CMD
}



# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
#   WHOST_NAME  = Name of Host          RRDTOOL = Path to rrdtool   WRRD   = Name of RRD      
#   WSTART      = "HH:MM DD.MM.YY"      WEND    = HH:MM DD.MM.YY    WTITLE = Graph Title
#   WPNG        = Path PNG to create    WSIZE   = B/S (Big/Small)   DEBUG  = True/False
#   $WDEV       = Interface A(1st), B(2nd), C(3th), D(4th) 
# ==================================================================================================
function create_net_graph($WHOST_NAME,$RRDTOOL,$WRRD,$WSTART,$WEND,$WTITLE,$WPNG,$WSIZE,$DEBUG,$WDEV)
{
    if (file_exists($WPNG)) { unlink($WPNG); }                          # Make sure png don't exist
    $CMD  = "$RRDTOOL graph $WPNG -s \"$WSTART\" -e \"$WEND\"";         # rrdtool gph filename 
    $CMD .= " --title \"$WTITLE\" ";                                    # Insert Title in Command
    $CMD .= " --vertical-label \"KB/s\"";                               # Set Vertical Legend
    $CMD .= " --upper-limit 100 --lower-limit 0 ";                      # Set Upper/Lower Baseline
    if (strtoupper($WSIZE) == "B") {                                    # If Want Big Graph
       $CMD .= " --height 250 --width 950 ";                            # Set to Big Graphic Size
    }else{
       $CMD .= " --height 125 --width 250 ";                            # Set to Small Graphic Size
    }
    $CMD .= " DEF:kbin=$WRRD:eth${WDEV}_readkbs:MAX   AREA:kbin#1E8CD1:\"KB Received \"";
    $CMD .= " DEF:kbout=$WRRD:eth${WDEV}_writekbs:MAX AREA:kbout#A4300B:\"KB Transmitted \"";
    if ($DEBUG) { echo "\n<br>CMD:" . $CMD ; }                          # Show RRDTool Command used
    $outline    = exec ("$CMD", $array_out, $retval);                   # Run rrdtool Generate Graph
    if ($DEBUG) { echo "\n<br>Return Value is $retval" ; }              # Show Return Code of CMD
}


# ==================================================================================================
#                  Generate the Performance Graphic from the rrd of hostname received 
# --------------------------------------------------------------------------------------------------
#   WHOST_NAME  = Name of Host          RRDTOOL = Path to rrdtool   WRRD   = Name of RRD      
#   WSTART      = "HH:MM DD.MM.YY"      WEND    = HH:MM DD.MM.YY    WTITLE = Graph Title
#   WPNG        = Path PNG to create    WSIZE   = B/S (Big/Small)   DEBUG  = True/False
# ==================================================================================================
function create_memdist_graph($WHOST_NAME,$RRDTOOL,$WRRD,$WSTART,$WEND,$WTITLE,$WPNG,$WSIZE,$DEBUG)
{
    if (file_exists($WPNG)) { unlink($WPNG); }                          # Make sure png don't exist
    $CMD  = "$RRDTOOL graph $WPNG -s \"$WSTART\" -e \"$WEND\"";         # rrdtool gph filename 
    $CMD .= " --title \"$WTITLE\" ";                                    # Insert Title in Command
    $CMD .= " --vertical-label \"Memory Usage Pct\"" ;                  # Set Vertical Legend
    $CMD .= " --upper-limit 100 --lower-limit 0 ";                      # Set Upper/Lower Baseline
    if (strtoupper($WSIZE) == "B") {                                    # If Want Big Graph
       $CMD .= " --height 250 --width 950 ";                            # Set to Big Graphic Size
    }else{
       $CMD .= " --height 125 --width 250 ";                            # Set to Small Graphic Size
    }
    $CMD .= " DEF:mem_new_proc=$WRRD:mem_new_proc:MAX ";      
    $CMD .= " DEF:mem_new_fscache=$WRRD:mem_new_fscache:MAX ";
    $CMD .= " DEF:mem_new_system=$WRRD:mem_new_system:MAX ";
    $CMD .= " CDEF:totproc=mem_new_proc,mem_new_system,+  ";
    $CMD .= " CDEF:wcache=mem_new_proc,mem_new_fscache,mem_new_system,+,+  ";
    $CMD .= " AREA:wcache#DFC184:\"FS Cache %\" ";
    $CMD .= " AREA:totproc#2A75A9:\"Process %\" ";
    $CMD .= " AREA:mem_new_system#7EB5D6:\"System %\" ";
    if ($DEBUG) { echo "\n<br>CMD:" . $CMD ; }                          # Show RRDTool Command used
    $outline    = exec ("$CMD", $array_out, $retval);                   # Run rrdtool Generate Graph
    if ($DEBUG) { echo "\n<br>Return Value is $retval" ; }              # Show Return Code of CMD
}



?>
