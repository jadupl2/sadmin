#!/usr/bin/env python
# 
# Test Program to read and write json file
#
# 2017_08_03 JDuplessis
#   V1.1 Initial Version

import  json

data = {
   'name' : 'ACME',
   'shares' : 100,
   'price' : 542.23
}
print data

# Writing JSON data
with open("data.json", 'w') as f:
     json.dump(data, f)

# Reading data back
with open("data.json", 'r') as f:
     data = json.load(f)

print data
json_str = json.dumps(data)

# Here is how you turn a JSON-encoded string back into a Python data structure:
data = json.loads(json_str)
print data
