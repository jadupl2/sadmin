def main(argv):
    (pdebug) = cmd_options(argv)                                        # Analyze cmdline options
    sa.start(pver,pdesc)                                                # Initialize SADMIN env.
    
    #sa.write_log ("just returning from start()")
    #ccode, cstdout, cstderr = sa.oscommand("ls -l %s" % (sa.log_file))
    #sa.write_log ("oscommand: stdout is     : %s" % (cstdout))
    #sa.write_log ("oscommand: stderr is     : %s" % (cstderr))
    #sa.write_log ("oscommand: returncode is : %s" % (ccode))
    #input ("Press Enter to continue")
        
    pexit_code = main_process()                                         # Default: Run main_process
   
    #sa.write_log ("just after mainprocess")
    #ccode, cstdout, cstderr = sa.oscommand("ls -l %s" % (sa.log_file))
    #sa.write_log ("oscommand: stdout is     : %s" % (cstdout))
    #sa.write_log ("oscommand: stderr is     : %s" % (cstderr))
    #sa.write_log ("oscommand: returncode is : %s" % (ccode))
    #input ("Press Enter to continue")

    sa.stop(pexit_code)                                                 # Exit Gracefully SADMIN Lib

    #print ("just after stop")
    #ccode, cstdout, cstderr = sa.oscommand("ls -l %s" % (sa.log_file))
    #print ("oscommand: stdout is     : %s" % (cstdout))
    #print ("oscommand: stderr is     : %s" % (cstderr))
    #print ("oscommand: returncode is : %s" % (ccode))
    #input ("Press Enter to continue")
   
    sys.exit(pexit_code)                                                # Back to O/S with Exit Code

# This idiom means the below code only runs when executed from command line
if __name__ == "__main__": main(sys.argv)
