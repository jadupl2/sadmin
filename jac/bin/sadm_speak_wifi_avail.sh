while true;do iwlist wlan0 scan |awk -F\" '/ESSID/{print $2}' |espeak;done

