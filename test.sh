#!/bin/bash

echo "Generating JSON..."
ruby json.rb $1 $2 $3 $4 $5
echo "Parsing..."
time ./jsonCuda /tmp/test.in $1 $2 $3 $4 $5
echo "Diffing..."
diff /tmp/test.in /tmp/test.out -q
