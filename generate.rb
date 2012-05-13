require 'trollop'

opts = Trollop::options do
   banner <<-EOS
Generates a type header and test values.

Usage:
   generate [options]

where [options] are:
   EOS

   opt :spec, "A comma separate spec string. Currently 'int' and 'float32' are supported.", :type => :string
   opt :dim, "Number of dimensions in the randomly generated array", :type => :int
   opt :num_elements, "Number of elements in each dimension", :type => :int
end


f = "typedef struct {\n"

spec = opts[:spec].split(',')
char = 97 
for x in spec
   if x.lstrip == 'int'
      f << "int #{char.chr};\n"
      char += 1
   elsif x.lstrip == 'float32'
      f << "float #{char.chr};\n"
      char += 1
   else
      puts "Invalid type: #{x.lstrip}"
      exit
   end
end

f << "} GenType;\n"

File.open('genType.h', 'w').write(f)
