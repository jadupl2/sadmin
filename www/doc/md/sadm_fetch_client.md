# sadm_fetch_clients.sh

## SYNOPSIS
Run on Linux, Aix, MacOS.  
Collect all new or modified script (*.rch) and System Monitor (*.rpt) files and issue alert if needed.  
 
sadm_fetch_clients.sh     [ -v -h  ]    [ -d   0-9  ] 
 
### DESCRIPTION

- All clients having a status of 'active' are selected.
- After making sure that we can SSH to these actives clients :
- All new or modified files with extensions '*.rch', '*.log' and '*.rpt' on clients are synchronize (rsync) with the SADMIN server.
- Then each script Result Code History ('*rch') and System Monitor ('*.rpt') files are examined and alert are issue if needed.
- At last, if any O/S update schedule have been modified the crontab is updated (/etc/crontab.d/sadm_osupdate).

 
### OPTIONS

| Options       | Description   |
| :----------------: | :---------------- |
| **-d**  | Debug level (0-9). |  
| **-h**  | Display this help and exit. |  
| **-v**  | Output version information and exit. |   


### REQUIREMENTS

- Environment variable 'SADMIN', specify the root directory of the SADMIN tools.  
    - Define by setup script in /etc/profile.d/sadmin.sh and in /etc/environment .  
- SADMIN main configuration file, "$SADMIN/cfg/sadmin.cfg". 
- SADMIN Tools Shell Library, "$SADMIN/lib/sadmlib.sh".  
 
### EXIT STATUS

[0]    An exit status of zero indicates success. 
[1]    Failure is indicated by a nonzero value, typically ‘1’.  
 
### AUTHOR
Jacques Duplessis (jacques.duplessis@sadmin.ca.).  
Any suggestions or bug report can be sent at http://www.sadmin.ca/support.php. 

### COPYRIGHT
Copyright © 2020 Free Software Foundation, Inc. License GPLv3+:  
    - GNU GPL version 3 or later http://gnu.org/licenses/gpl.html.  
This is free software, you are free to change and redistribute it.   
There is NO WARRANTY to the extent permitted by law.  

 
### SEE ALSO

sadm_sysmon_tui.sh   (System Monitor Terminal UI).  
sadm_sysmon_cli.sh   (Run System Monitor and show results). 
sadm_sysmon.pl   (SADMIN System Monitor). 

 
### INDEX

NAME. 
SYNOPSIS. 
DESCRIPTION. 
OPTIONS. 
REQUIREMENTS. 
EXIT STATUS. 
AUTHOR. 
COPYRIGHT. 
SEE ALSO. 


Copyright © 2015-2020 - www.sadmin.ca - Suggestions, Questions or Report a problem at support@sadmin.ca 