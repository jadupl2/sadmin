#!/usr/bin/env python3
# Python List Related Examples - Oct 2017 - J.D.
#---------------------------------------------------------------------------------------------------

# ---
print ("my_notes_list.py")
print ('-'*80) ; print ("LIST EXAMPLES") ; print ('-'*80) 


s = 'Jacques'  ; print ('s = ', s) 
print ('l =  list(s)')
l = list(s)
print ('l = ', l )

# ---
print ("\n",'-'*10) ; print ("Line Split")
line = 'Bob,Jack,Gille'
print ("line =",line)
print ("split_line = line.split(',')")
split_line = line.split(',')
print ("split_line =", split_line)



print ("..\n..",'-'*80, "USING ARRAY") 
array = ['Bob','Jack','Gille']
print ("array      = ",array)
print ("array[2]   =", array[2])
print ("array[-2]  =", array[-2])
print ("array[3-2] =", array[3-2])
print ("array[1:]  =", array[1:])
print ("array[:1]  =", array[:1])
print ('array.append("George") =', array.append("George"))
print ("array = ", array)
print ("array[2] = 'Helene'")
array[2] = 'Helene'
print ("array = ", array)
array.sort()
print ("array.sort()")
print ("array = ", array)
array.extend(["Catherine","Mireille"])
print ('array.extend(["Catherine","Mireille"])' )
print ("array = ", array)
del array[2]
print ('del array[2]')
print ("array = ", array)
print ("len(array) = ", len(array))
