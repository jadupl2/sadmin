#!/usr/bin/env sh

NAME="Jacques"
LNAME=`expr length $NAME`
echo "Before $NAME and len $LNAME"

for (( c=${#NAME}  ; c<30; c++ ))
do
   NAME="${NAME}."
done
LNAME=`expr length $NAME`
echo "After $NAME and len $LNAME"
