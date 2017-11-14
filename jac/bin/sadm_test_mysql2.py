#!/usr/bin/env python3

import pymysql

# Open database connection
db = pymysql.connect(host='localhost',user='root',password='Icu@9am!',db='sadmin' )

# prepare a cursor object using cursor() method
cursor = db.cursor()


# execute SQL query using execute() method.
#cursor.execute("SELECT VERSION()")

# Fetch a single row using fetchone() method.
#data = cursor.fetchone()
#print ("Database version : %s " % data)

sql = "SELECT * FROM server_category ;"  
try:
    # Execute the SQL command
    cursor.execute(sql)
    # Fetch all the rows in a list of lists.
    results = cursor.fetchall()
    for row in results:
      row0 = str(row[0])
      row1 = row[1]
      row2 = row[2]
      row3 = str(row[3])
      row4 = str(row[4])
      # Now print fetched result
      print ("row0 = %s,row1 = %s,row2 = %s,row3 = %s,row4 = %s" % \
             (row0, row1, row2, row3, row4 ))
#except:
except Exception as e: 
    print ("Error: unable to fetch data - Erreur ",e)


# Prepare SQL query to INSERT a record into the database.
sql = "SELECT * FROM server_category where cat_code='Retired';"  
#sql = "SELECT * FROM servers " 
#try:
   # Execute the SQL command
cursor.execute(sql)
result = cursor.fetchone()
print ("result = ",result)

if (result == None) :
    print ("Not Exist")
else :
    print ("Exist")
      
   
   # Fetch all the rows in a list of lists.
   #results = cursor.fetchall()
   #for row in results:
   #   fname = row[2]
   #   # Now print fetched result
   #   print "fname=%s" % (fname)
   #   print "row = %d" % row
#except:
#   print "Error: unable to fecth data"
# disconnect from server
db.close()
