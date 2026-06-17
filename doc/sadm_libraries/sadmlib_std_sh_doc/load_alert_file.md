### (function)  load_alert_file   

#### `def load_alert_file():`
   
   
    
    if lib_debug > 4 : print ("Load Alert Group Configuration file %s" % (cfg_file))

    # Make sure the Alert Group File exist ($SADMIN/cfg/alert_group.cfg).
    # If it doesn't exist, create one using alert initial file ($SADMIN/cfg/.alert_group.cfg)
    if not os.path.exists(alert_file):                                  # alert_group.cfg not Exist
        if not os.path.exists(alert_init):                              # .alert_group.cfg not Exist
          print ("SADMIN Alert Group file not found - " + alert_file)
          print ("Even Alert Group Template file is missing - " + alert_init)
          print ("Copy both files from another system to this server")
          print ("Or restore them from a backup")
          stop(1)                                                       
          sys.exit(1)                                                   # Exit to O/S with Error
        else:
            print ("cp %s %s " % (alert_init,alert_file))           # Install Default alert file
            try:
                shutil.copy(alert_init,alert_file)
            except:
                print ("Could not copy %s to %s" % (alert_init,alert_file))
                stop(1)   
                sys.exit(1)                                             # Exit to O/S with Error
    if os.getuid() == 0:                                                # If running as root
        uid = pwd.getpwnam(sadm_user).pw_uid                            # Get UID User in sadmin.cfg
        gid = grp.getgrnam(sadm_group).gr_gid                           # Get GID User in sadmin.cfg
        os.chown(alert_file,uid,gid)                                    # Change alert File Owner
        os.chmod(alert_file,0o0664)                                     # Change alert File Perm.

    # Open Alert Group file
    try:
        alert_file_fh= open(alert_file,'r')                             # Open Config File
    except IOError as e:                                                # If Can't open cfg file
        print ("Error opening file %s" % (alert_file))              # Print Log FileName
        print ("Error Line No.: %d" % (inspect.currentframe().f_back.f_lineno)) # Print Line No.
        print ("Function Name : %s" % (sys._getframe().f_code.co_name)) # Get function Name
        print ("Error Number  : %d" % (e.errno))                    # print Error Number
        print ("Error Text    : %s" % (e.strerror))                 # Print Error Message
        print ("Script aborted\n")
        sys.exit(1)                     

    # Read Configuration file and Save Options values
    for aline in alert_file_fh:                                         # Loop until on all servers
        wline        = aline.strip()                                    # Strip CR/LF & Trail spaces
        if (wline[0:1] == '#' or len(wline) == 0) :                     # If comment or blank line
            continue                                                    # Go read the next line
        split_line = wline.split()                                      # Split based on space
        grp_name   = str(split_line[0]).lower().strip()                 # Group Name Lowercase Trim
        grp_type   = str(split_line[1]).lower().strip()                 # Group Type Lowercase Trim
        grp_dest   = str(split_line[2]).lower().strip()                 # Grp Destination Lowercase
        try:                                                            # May have 4th, Slack Hook
            grp_slhook = str(split_line[3]).strip()                     # Group Slack Hook
        except IndexError:                                              # If no Slack Hook on Line
            grp_slhook = ""                                             # Blank Hook if no 4th field
        dict_alert[grp_name] = (grp_name,grp_type,grp_dest,grp_slhook)  # Insert Grp Data in Dict
    return (dict_alert)











# --------------------------------------------------------------------------------------------------
