#!/bin/bash

echo "Generating..."
ruby json.rb $1 $2 $3 $4 $5
echo "CUDA Results:"
time ./jsonCuda /tmp/test.in -q
echo "CPU Results:"
time ../json-parser/bench /tmp/test.in
