#!/bin/bash

ruby generate.rb -n $1
./jsonCuda test.in $1 > test.out
diff test.in test.out
