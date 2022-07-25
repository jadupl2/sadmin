<?php
$whrs=17;
$wmin=30;
$w_month  = date('m') ;                               # Today Mth Num.
$w_day    = date('d') ;                               # Today day Num.
$w_year   = date('Y') ;                               # Today Year Num. 
$selhrs   = sprintf("%02d", $whrs);                                 # Save & Format Selected Hrs
$selmin   = sprintf("%02d", $wmin);                                 # Save & Format Selected Min
$seltime  = "${selhrs}:${selmin}";                                  # Store Hrs:Min for

$w_epoch = mktime($whrs,$wmin,0,$w_month,$w_day,$w_year); # Epoch this week
$curepoch = time();                                                 # Current Epoch Time

print "\nw_epoch(Event Epoch) = " . $w_epoch . " " . date('r', $w_epoch) . "\n" ; 
print "\ncurepoch(Current Epoch)= " . $curepoch . " " . date('r', $curepoch) . "\n" ; 
if ($w_epoch > $curepoch) {
    #print "\ncoco" ;
    $update_date_time = date('Y-m-d',strtotime('today')) . " $seltime";
    print "Uptime time : $update_date_time" ;
}
?>
