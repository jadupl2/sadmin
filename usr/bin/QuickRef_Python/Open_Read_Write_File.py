#!/usr/bin/env python3
# Python Files Related Examples - Oct 2017 - J.D.
#---------------------------------------------------------------------------------------------------
import os

print ("\n",'-'*80, "Working with file")
print ("myfile = open('datafile', 'w')")
myfile = open('datafile', 'w')
print ("myfile.write('hello world !\\n')")
myfile.write('hello world !\n')
print ("myfile.close()")
myfile.close()


print ("\nmyfile = open('datafile', 'r')")
myfile = open('datafile', 'r')
print ("myfile.readline()")
myfile.readline()
print ("myfile.readline()")
myfile.readline()
print ("myfile.close()")
myfile.close()

os.remove('datafile')

