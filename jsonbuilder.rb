out = [1, 2.3, 4, 5, 6.7]

for x in ARGV
   out = [out] * x.to_i
   end

#puts out.inspect
f = File.open("/tmp/test.in", "w")
f.write(out.to_s.gsub(/\s+/, ""))
f.close

alpha = 65
f = File.open("dims.h", "w")
for x in ARGV
   f.write("#define #{alpha.chr} #{x.to_i}\n")
   alpha += 1
end
f.close()
