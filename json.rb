out = "[1,2.3,4,5,6.7]"

for x in ARGV
   out = "[#{(out + ",") * (x.to_i - 1) + out}]"
   end

#puts out.inspect
f = File.open("/tmp/test.in", "w")
f.write(out)
f.close
