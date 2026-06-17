### (function)  trimfile   

#### `def trimfile(filename,nlines=500) :`
   
   
    Trim the file received to the number of lines indicated in the second parameter.
        - If 2nd parameter 'nlines' is omitted a value of 500 is use.
        - If 2nd parameter 'nlines' is specified and is 0, then no trim is done on the file.
        
    Arguments:
        filename (str)  :   Full path of the file to trim.
        nlines (int)    :   Keep the last "nlines" lines of the file.
                            No trim is done if nlines equal 0.

    Returns:
        returncode (int):   0 When command executed with success 
                            1 When error occurred (Permission Error)
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
