### (function)  cmd_options   

#### `def cmd_options(argv):`
   
   


    global pdebug                                                       # Script Debug Level (0-9)
    parser = argparse.ArgumentParser(description=pdesc)                 # Desc. is the script name

    # Declare Arguments
    parser.add_argument("-v",
                        action="store_true",
                        dest='version',
                        help="Show script version")
    parser.add_argument("-d",
                        metavar="0-9",
                        type=int,
                        dest='pdebug',
                        help="debug/verbose level from 0 to 9",
                        default=0)
    
    args = parser.parse_args()                                          # Parse the Arguments

    # Set return values accordingly.
    if args.pdebug:                                                  # Debug Level -d specified
        pdebug = args.pdebug                                      # Save Debug Level
        print("Debug Level is now set at %d" % (pdebug))             # Show user debug Level
    if args.version:                                                    # If -v specified
        sa.show_version(pver)                                           # Show Custom Show Version
        sys.exit(0)                                                     # Exit with code 0
    return(pdebug)                                                   # Return opt values





# Main Function
# --------------------------------------------------------------------------------------------------
