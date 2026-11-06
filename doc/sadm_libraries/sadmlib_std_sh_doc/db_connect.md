### (function)  db_connect   

#### `def db_connect(db_name="sadmin",quiet=False):`
   
   
        Open a connection to the Database (default=sadmin).
        
        Args: db_name (str) : Name of the Database to connect to..
                              If not specified, 'sadmin' is assume.
              quiet (bool)  : If True, no error message is printed in case of error.
                              If False, error message is printed in case of error (default=False).

        Returns: (db_conn,db_cur,errno,db_errmsg)
            db_conn (obj)   :   Connector to database or None if can't connect.
            db_cur (obj)    :   Database cursor or None if can't connect.
            errno (int)  :   Return 0 when connected to database (Global variable).
                                Return 1 if error while connecting to database (Global Variable).
            errmsg(str) :   Return Error message when connecting to DB else return empty string.
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
