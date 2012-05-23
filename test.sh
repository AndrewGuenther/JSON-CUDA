#!/bin/bash

ruby generate.rb -n $1
./jsonCuda /tmp/test.in $1
diff /tmp/test.in /tmp/test.out
