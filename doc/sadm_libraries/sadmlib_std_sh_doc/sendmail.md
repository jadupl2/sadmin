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






# Send an email to sysadmin define in sadmin.cfg with subject and body received
# ----------------------------------------------------------------------------------------------
#def sendmail(mail_addr, mail_subject, mail_body, mail_attach="") :
#    
#    """ Send email to email address received.
#        
#        Args:            
#            mail_addr (str)     : Email Address to which you want to send it
#            mail_subject (str)  : Subject of your email
#            mail_body (str)     : Body of your email
#            mail_attach (str)   : Name of the file (MUST exist) to attach to the email.
#                                  (If no attachment, leave blank)
#    
#        Returns:
#            Return Code (Int)   : 0 Successfully sent the email
#                                  1 Error while sending the email (Parameters may be wrong)
#    """
#
#    data = MIMEMultipart()                                              # Instance of MIMEMultipart
#    data['From '] = sadm_smtp_sender                                    # store sender email address  
#    data['To '] = mail_addr                                             # store receiver email 
#    data['Subject '] = mail_subject                                     # storing the subject 
#    data.attach(MIMEText(str(mail_body), 'plain'))                      # attach body with msg inst
#
#    if mail_attach != "" :
#        filenames = mail_attach.split(',')
#        for filename in filenames :
#            if os.path.exists(filename): 
#                attachment = open(filename, "rb")                       # Read file into memory
#                p = MIMEBase('application', 'octet-stream')             # MIMEBase inst & named as p
#                p.set_payload((attachment).read())                      # Payload into encoded form
#                encoders.encode_base64(p)                               # encode into base64
#                p.add_header('Content-Disposition', "attachment; filename= %s" % filename)
#                data.attach(p)                                          # attach inst p to inst msg
#    text = data.as_string()                                             # Conv. Multipart msg 2 str
#    try : 
#        context = ssl.create_default_context()
#        with smtplib.SMTP(sadm_smtp_server, sadm_smtp_port) as server:
#            server.ehlo()  # Can be omitted
#            server.starttls(context=context)
#            server.ehlo()  # Can be omitted
#            try:
#                server.login(sadm_smtp_sender, sadm_gmpw)
#            except smtplib.SMTPException :
#                write_err("Authentication for %s at %s:%d failed (%s)." % (sadm_smtp_sender,sadm_smtp_server,sadm_smtp_port,sadm_gmpw))
#                return (1)
#            try : 
#                server.sendmail(sadm_smtp_sender, mail_addr, text)
#            except Exception as e: 
#                write_err("[ ERROR ] Trying to send email to %s" % (mail_addr))
#                write_err("%s" % e)
#                return (1)
#            finally:
#                server.close()
#    except (smtplib.SMTPException, socket.error, socket.gaierror, socket.herror) as e:
#            write_err("[ ERROR ] Connection to %s port %s failed" % (sadm_smtp_server,sadm_smtp_port))
#            write_err("%s" % e)
#            return(1)
#    return (0)


#def send_gmail(recipient_email, subject, body, attachment_str):
#    # Retrieve Gmail credentials from environment variables for security
#    sender_email = "brucetalbot95@gmail.com"
#    sender_password = "wtuapkxdxtuaidon"
#
#    if not sender_email or not sender_password:
#        return "Error: GMAIL_USER or GMAIL_APP_PASSWORD environment variables not set."
#
#    try:
#        # Create the email message
#        msg = EmailMessage()
#        msg["Subject"] = subject
#        msg["From"] = sender_email
#        msg["To"] = recipient_email
#        msg.set_content(body)
#
#        # Handle attachments if the string is not empty
#        if attachment_str:
#            # Split the string by comma and strip any whitespace
#            files = [file.strip() for file in attachment_str.split(",")]
#
#            for file_path in files:
#                if os.path.exists(file_path):
#                    with open(file_path, "rb") as f:
#                        file_data = f.read()
#                        file_name = os.path.basename(file_path)
#                        msg.add_attachment(
#                            file_data,
#                            maintype="application",
#                            subtype="octet-stream",
#                            filename=file_name,
#                        )
#                else:
#                    return f"Error: File not found - {file_path}"
#
#        # Connect to Gmail's SMTP server
##        with smtplib.SMTP_SSL("://gmail.com", 465) as smtp:
#        with smtplib.SMTP_SSL("://gmail.com", 587) as smtp:
#            smtp.login(sender_email, sender_password)
#            smtp.send_message(msg)
#
#        return "Email sent successfully!"
#
#    except Exception as e:
#        return f"Failed to send email. Error: {e}"
#


# --------------------------------------------------------------------------------------------------
