#!/usr/bin/env python
print '-'*80 ; print "using single and double quotes in string" ; print '-'*80
title = "The meaning of life" 
print "knigtt's" , 'knight"s'  # use ' inside "  and " inside ' quote
s = "Jacques" 
print "Length of s is " + str(len(s))	# Get len of string and convert it to string

print '-'*80 ; print "raw string suppress" ; print '-'*80
path = 'c:\new\text.dat' 	#without raw string suppress
print path
path = r'c:\new\text.dat' 	#with raw string suppress \n not equal newline & \t not equal tab
print path

print '-'*80 ; print "in string test" ; print '-'*80
print 'k' in "Jacques" 
print 'a' in "Jacques" 

print '-'*80 ; print "string indexing and slicing" ; print '-'*80
s = "Jacques" 
print "s = " + s
print "print s[0] , s[-2]" 
print s[0] , s[-2] 
print "print s[1:3], s[1:], s[:-1]"
print s[1:3], s[1:], s[:-1]

print '-'*80 ; print "convert string to integer & integer to string" ; print '-'*80
print int("42"), str(42)	# COnvert string to iny and integer to strint
print int("42") + 1 

print '-'*80 ; print "string fomatting" ; print '-'*80
print 'That is test number %d by %s' % (5, 'Jacques')
x = 1234
res = "integers: ...%d...%-6d...%06d" % (x,x,x)
print res


print '-'*80 ; print "String Methods" ; print '-'*80
s = 'Jacques'  ; print 's = Jacques'
print "s = s[:3] + 'xx' + s[5:]" 
s = s[:3] + 'xx' + s[5:]
print s
s = 'Jacques Duplessis'  ; print 's = ', s
print "s = s.replace('ques','k')" 
s = s.replace('ques','k')
print s
print "wpos = s.find('a')"
wpos = s.find('a')
print wpos
print "s = s{;wpos] + 'coco' + s[(wpos+3):]"
s = s[:wpos] + 'coco' + s[(wpos+3):]
print s
s = 'Jacques Joseph Duplessis'  ; print 's = ', s 
col1 = s[0:3]
print "col1 = s[0:3] " 
print col1
print "col3 = s[8:]" 
col3 = s[8:]
print col3 

s = 'Jacques'  ; print 's = ', s 
print 'l = list(s)'
l = list(s)
print 'l = ', l 

print "..\n..",'-'*80, "Line Split" 
line = 'Bob,Jack,Gille'
print "line =",line
print "split_line = line.split(',')"
split_line = line.split(',')
print "split_line =", split_line

print "..\n..",'-'*80, "USING ARRAY" 
array = ['Bob','Jack','Gille']
print "array = ", array
print "array[2] =", array[2]
print "array[-2] =", array[-2]
print "array[3-2] =", array[3-2]
print "array[1:] =", array[1:]
print "array[:1] =", array[:1]
print 'array.append("George") =', array.append("George")
print "array = ", array
print "array[2] = 'Helene'"
array[2] = 'Helene'
print "array = ", array
array.sort()
print "array.sort()"
print "array = ", array
array.extend(["Catherine","Mireille"])
print 'array.extend(["Catherine","Mireille"])' 
print "array = ", array
del array[2]
print 'del array[2]'
print "array = ", array
print "len(array) = ", len(array)


print "..\n.."
print '-'*80
print "USING Dictionnary"
print '-'*80

print "Initialize an empty Dictionnary"
print "table = {}" 
table = {}

print "table = {'Bob': 26,'Jack': 2,'Gille': 9}"
table = {'Bob': 26,'Jack': 2,'Gille': 9}
print "table = ", table, "YOU DO NOT CONTROL ORDER IN DICTIONNARY"
print "table['Jack'] = " , table['Jack']
print "len(table) = ", len(table)
print "table.has_key('Jack') = ",table.has_key('Jack')
print "table.has_key('coco') = ",table.has_key('coco')
print "'Jack' in table = ", 'Jack' in table
print "'coco' in table = ", 'coco' in table
print "table.keys() = ",table.keys()
print "table.values() = ",table.values()
print "table.items() = ",table.items()

print "\nDeleting an Entry"
print "table = ", table
print "del table['Jack']" 
del table['Jack']
print "table = ", table

print "\nAdding an Entry"
print "table = ", table
table['John'] = 33
print "table['John'] = 33"
print "table = ", table

print "\nChanging an entry"
print "table = ", table
print "table['John'] = 44"
table['John'] = 44
print "table = ", table

print "\nOthers Dictionnary methods"
print "table = ", table
print "table.get('coco') =" , table.get('coco')
print "table.get('coco',50) =" , table.get('coco',50)
print "table.get('John') =" , table.get('John')

print "table = ", table
wline = {'Roger':99, 'Albert':88} 
print "wline = ", wline 
wline = {'Roger':99, 'Albert':88} 
print "table.update(wline)"
table.update(wline)
print "table = ", table
wline = {'Roger':100, 'John':188} 
print "wline = ", wline
print "table.update(wline)"
table.update(wline)
print "table = ", table

print "\nLooping thru Dictionnary with for loop"
print "table = ", table
print "for wline in table.keys():"
print "    print wline, '\t', table[wline]"
for wline in table.keys():
    print wline, '\t', table[wline]
    lineno = 0
for k, v in table.iteritems():
    print ("[%2d] %-25s ...%s..." % (lineno, k, v))
    lineno += 1

print "\n",'-'*80, "Working with file" 
print "myfile = open('datafile', 'w')"
myfile = open('datafile', 'w')
print "myfile.write('hello world !\\n')"
myfile.write('hello world !\n')
print "myfile.close()"
myfile.close()

print "\nmyfile = open('datafile', 'r')"
myfile = open('datafile', 'r')
print "myfile.readline()"
myfile.readline()
print "myfile.readline()"
myfile.readline()
print "myfile.close()"
myfile.close()


print "\n",'-'*80, "Working with Number" 
print "x = 1" 
x = 1

print "x = x + 1"
x = x + 1
print "x =", x

print "x += 1"
x += 1
print "x =", x


