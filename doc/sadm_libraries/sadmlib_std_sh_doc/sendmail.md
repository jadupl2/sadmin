### (function)  sendmail   

#### `def sendmail(waddr, wsub, wbody, wattach="") :`
   
   

    # Validate email address
    try:
        email_info = validate_email(waddr, check_deliverability=True)
    except EmailNotValidError as e:
        errmsg = {str(e)}
        write_err ("The email specified is not valid '%s'." % waddr)
        write_err (errmsg)
        return 1

    # Ensure email body file exists before checking its size
    if not os.path.exists(wbody) or os.path.getsize(wbody) == 0:    
       if (not quiet) : write_err ("Mail body file is is empty or not found '%s'."  % wbody)
       return 1

    # Add subject to mutt command
    cmd_mutt="mutt -s '%s' " % wsub
    if debug > 4 : write_log ("cmd_mutt with subject added  '%s'" % (cmd_mutt))

    # Validate if attachment exist and prepare for a repetive '-a' option.
    attachment = ""                                                     # -a with each attachment
    if debug > 4 : write_log ("Attachment receive: %s" % wattach) # Show Attachment info rcv
    if wattach != "" :                                                  # If attachment not blank
        filenames = wattach.split(',')                                  # Split by , filename in array
        for filename in filenames :                                     # For each attachement
            if os.path.exists(filename):                                # Check if attachement exist
                attachment += " -a %s " % filename                      # Add -a attachment
                if debug > 4 : write_log ("Attachement list : %s" % attachment)
            else:
                write_err ("Attachment does not exist '%s'" % filename)
                return 1 
    if debug > 4 : write_log ("Final Attachment spec' %s'." % attachment) 

    # Add attachment to mutt command
    cmd_mutt = cmd_mutt + attachment + " -- "                           # combine '-a' and '--' opt
    if debug > 4 : write_log ("Final email separater %s" % cmd_mutt) 

    # Add email address & Body of email 
    cmd_mutt += "%s < %s" % (waddr,wbody)                               # Add email addr & < body
    if debug > 4 : write_log ("Final mutt command : %s" % cmd_mutt)

    # Execute the mutt command
    ccode, cstdout, cstderr = oscommand(cmd_mutt)                       # Go execute 'mutt' command
    if not ccode == 0 :
        write_err ("[ ERROR ] No.%s Trying to send email." % ccode)
        write_err ("%s\n%s\n" % (cstdout,cstderr))
        return(1) 
    
    return (0)




