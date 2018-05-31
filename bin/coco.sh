#! /bin/sh
FILE="$SADMIN/bin/coco.txt"

    while read wline                                                    # Loop Until EOF Backup List
        do
        FC=`echo $wline | cut -c1`                                      # Get First Char. of Line
        if [ "$FC" = "#" ] || [ ${#wline} -eq 0 ] ; then continue ; fi  # Skip Comment or Blank Line
        #
        echo "wline = ..${wline}.." 
        done < $FILE                                                    # Read Backup File 