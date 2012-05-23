#!/bin/bash

ruby generate.rb -n $1
./jsonCuda /tmp/test.in $1 > /tmp/test.out
diff /tmp/test.in /tmp/test.out
