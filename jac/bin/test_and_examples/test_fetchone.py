#! /bin/python3
import os,time,sys,pdb,socket,datetime,pwd,grp,pymysql,subprocess,ipaddress

try:
 
    db = pymysql.connect(host="127.0.0.1",
                    user="root",
                    passwd="Icu@9am!",
                    db="sadmin"
                    )
 
    cursor = db.cursor()
    IP = '192.168.1.3'
    sql = "select * from server_network where net_ip='%s' ;" % (IP) 
    number_of_row = cursor.execute(sql)
    print("Number of row = %d" % (number_of_row))
    if (number_of_row > 0) :
        netrow = cursor.fetchone()
        print("Mac Address = %s" % netrow[3])
    else:
        print("Ip %s not found" % (IP))

    #print(cursor.fetchone())  # fetch the first row only
 
    db.close()
 
except pymysql.DataError as e:
    print("DataError")
    print(e)
 
except pymysql.InternalError as e:
    print("InternalError")
    print(e)
 
except pymysql.IntegrityError as e:
    print("IntegrityError")
    print(e)
 
except pymysql.OperationalError as e:
    print("OperationalError")
    print(e)
 
except pymysql.NotSupportedError as e:
    print("NotSupportedError")
    print(e)
 
except pymysql.ProgrammingError as e:
    print("ProgrammingError")
    print(e)
 
except :
    print("Unknown error occurred")

