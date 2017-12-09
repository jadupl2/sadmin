#!/usr/bin/env python3
# Python Dictionnary Related Examples - Oct 2017 - J.D.
#---------------------------------------------------------------------------------------------------

# ---
print ("my_notes_dict.py")
print ('-'*80) ; print ("DICTIONNARY EXAMPLES") ; print ('-'*80) 

print ("\nCreate an empty Dictionary")
print ("table = {}")
table = {}


print ("\nStarting with this dictionnary")
print ("table = {'Bob': 26,'Jack': 2,'Gille': 9}")
table = {'Bob': 26,'Jack': 2,'Gille': 9}
print ("\nWE DO NOT CONTROL ORDER IN DICTIONNARY")
print ("table = ",table)
print ("table['Jack'] = ",table['Jack'])
print ("len(table)    = ",len(table))

# has_key was removed in Python 3
#print ("table.has_key('Jack') = ",table.has_key('Jack'))
#print ("table.has_key('coco') = ",table.has_key('coco'))

print ("\n'Jack' in table = ", 'Jack' in table)
print ("'coco' in table = ", 'coco' in table)


print ("\nDeleting an Entry")
print ("table = ", table)
print ("del table['Jack']" )
del table['Jack']
print ("table = ", table)

print ("\nAdding an Entry")
print ("table = ", table)
table['John'] = 33
print ("table['John'] = 33")
print ("table = ", table)

print ("\nChanging an entry")
print ("table = ", table)
print ("table['John'] = 44")
table['John'] = 44
print ("table = ", table)

print ("\nOthers Dictionnary methods")
print ("table.keys()         = ",table.keys())
print ("table.values()       = ",table.values())
print ("table.items()        = ",table.items())
print ("table                = ",table)
print ("table.get('coco')    = ",table.get('coco'))
print ("table.get('John')    = ",table.get('John'))

print ("\nTable Update examples")
print ("table = ", table)
wline = {'Roger':99, 'Albert':88} 
print ("wline = ", wline)
print ("table.update(wline)")
table.update(wline)

print ("table = ", table)
wline = {'Roger':100, 'John':188} 
print ("wline = ", wline)
print ("table.update(wline)")
table.update(wline)
print ("table = ", table)

print ("\nLooping thru Dictionnary with for loop")
print ("table = ", table)
print ("for wline in table.keys():")
print ("    print (wline,\'\\t\',table[wline])")
for wline in table.keys():
    print (wline,'\t',table[wline])

