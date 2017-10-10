#!/usr/bin/env python3

# ---
print ("my_notes_string.py")
print ('-'*80) ; print ("STRING EXAMPLES") ; print ('-'*80) 
print ("knigtt's" , 'knight"s')                     # use ' inside "  and " inside ' quote

# ---
print ('s = "Jacques"')
s = "Jacques" 
print ('print "Length of s is " + str(len(s))')	# Get len of string and convert it to string
print ("Length of s is " + str(len(s)))	# Get len of string and convert it to string

# ---
print (" ")
print ('-'*80) ; print ("Raw String Suppress") ; print ('-'*80) 
print ("path = 'c:\new\text.dat'") 	#without raw string suppress
path = 'c:\new\text.dat' 	#without raw string suppress
print ("print path")
print (path)
print ("path = r'c:\new\text.dat'") 	#with raw string suppress \n not equal newline & \t not equal tab
path = r'c:\new\text.dat' 	#with raw string suppress \n not equal newline & \t not equal tab
print ("print path")
print (path)

# ---
print (" ")
print ('-'*80) ; print ("In string Test") ; print ('-'*80) 
print ("'k' in 'Jacques'") 
print ('k' in 'Jacques') 
print ("'a' in 'Jacques'")
print ('a' in 'Jacques') 

# ---
print (" ")
print ('-'*80) ; print ("String Indexing and Slicing") ; print ('-'*80) 
s = "Jacques" 
print ("s = " + s)
print ("print s[0] , s[-2]") 
print (s[0] , s[-2]) 
print ("print s[1:3], s[1:], s[:-1]")
print (s[1:3], s[1:], s[:-1])

# ---
print (" ")
print ('-'*80) ; print ("Convert String to Integer and Integer to String") ; print ('-'*80) 
print ('int("42"), str(42)')	# COnvert string to iny and integer to strint
print (int("42"), str(42))	# COnvert string to iny and integer to strint
print ('int("42") + 1')
print (int("42") + 1)
 

# ---
print (" ")
print ('-'*80) ; print ("String Formatting") ; print ('-'*80) 
print ('That is test number %d by %s' % (5, 'Jacques'))
x = 1234
res = "integers: ...%d...%-6d...%06d" % (x,x,x)
print (res)



# ---
print (" ")
print ('-'*80) ; print ("String Method") ; print ('-'*80) 
s = 'Jacques'  ; print ('s = Jacques')
print ("s = s[:3] + 'xx' + s[5:]") 
s = s[:3] + 'xx' + s[5:]
print (s)
print (" ")
s = 'Jacques Duplessis'  ; print ('s = ', s)
print ("s = s.replace('ques','k')") 
s = s.replace('ques','k')
print (s)
print (" ")
s = 'Jacques Duplessis'  ; print ('s = ', s)
print ("wpos = s.find('a')")
wpos = s.find('a')
print (wpos)
print (" ")
s = 'Jacques Duplessis'  ; print ('s = ', s)
print ("s = s[:wpos] + 'coco' + s[(wpos+3):]")
s = s[:wpos] + 'coco' + s[(wpos+3):]
print (s)
print (" ")
s = 'Jacques Joseph Duplessis'  ; print ('s = ', s) 
col1 = s[0:3]
print ("col1 = s[0:3] ") 
print (col1)
print ("col3 = s[8:]") 
col3 = s[8:]
print (col3) 

print (" ")
print ('-'*80) ; print ("String to List") ; print ('-'*80) 
s = 'Jacques'  ; print ('s = ', s) 
print ('l = list(s)')
l = list(s)
print ('l = ', l )

# ---
print (" ")
print ('-'*80) ; print ("String Line Split") ; print ('-'*80) 
line = 'Bob,Jack,Gille'
print ("line =",line)
print ("split_line = line.split(',')")
split_line = line.split(',')
print ("split_line =", split_line)
