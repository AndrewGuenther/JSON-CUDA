require 'trollop'

opts = Trollop::options do
   banner <<-EOS
Generates a type header and test values.

Usage:
   generate [options]

where [options] are:
   EOS

   opt :spec, "A comma separate spec string. Currently 'int' and 'float32' are supported.", :type => :string, :default => "int, float32, int, int, float32"
   opt :dim, "Number of dimensions in the randomly generated array", :type => :int
   opt :num_elements, "Number of elements in each dimension", :type => :int, :default => 0
   opt :header, "Generate a new header file for the given spec", :default => false
end

spec = Array.new
for elem in opts[:spec].split(',')
   if elem.lstrip == 'int'
      spec << Integer
   elsif elem.lstrip == 'float32'
      spec << Float
   else
      puts "Invalid type"
      exit
   end
end

if opts[:header]
   header = "typedef struct {\n"

   char = 97 
   for x in spec
      if x == Integer
         header << "int #{char.chr};\n"
         char += 1
      elsif x == Float
         header << "float #{char.chr};\n"
         char += 1
      else
         puts "Invalid type: #{x.lstrip}"
         exit
      end
   end

   header << "} GenType;\n"

   File.open('genType.h', 'w').write(header)
end

r = Random.new
test = '['
for i in 1..opts[:num_elements]
   test << '['
   for elem in spec
      if elem == Integer
         test << r.rand(-50..50).to_s
      elsif
         test << "%.2f" % r.rand(-50.00..50.00).round(2).to_s
      end
      test << ' '
   end
   test << "]\n"
end
test << ']'

File.open('/tmp/test.in', 'w').write(test)
