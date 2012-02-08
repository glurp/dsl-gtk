#####################################################
# make a ruby source with icons in base64, 
# load source and show icons in a Window
#######################################################
FILE_SRC_CONS="icons64.rb"

########################## Make a source 
## code in base64 each png file in args, result to ruby source

require 'base64'
require 'tmpdir'

str=<<EEND
require 'base64'
require 'tmpdir'
$icons={}
EEND

lvar=[]
ARGV.each { |fn|
 varname=File.basename(fn).split('.')[0].gsub(/[^a-zA-Z0-9]+/,"_").downcase
 File.open(fn,"rb") { |f|   str+= "\n$icons['#{varname}']=<<EEND\n"+Base64.encode64(f.read)+"EEND\n" }
 lvar << varname
}
str+=<<'EEND'
def get_icon_filename(name)
  raise("icon '#{name}' unknown in #{$icons.keys}") unless $icons[name]
  fname=File.join(Dir.tmpdir,name+".png")
  puts "#{name} ==> #{fname} / #{$icons[name].size}" if $DEBUG
  File.open(fname,"wb") { |f| f.write($icons[name].unpack('m')) } unless File.exists?(fname)
  fname
end
EEND

File.open(FILE_SRC_CONS,"w") { |f| f.write(str) }
STDERR.puts "#{lvar.join(", ")} done size=#{str.size}."


####################################################### test source generated

require_relative '../lib/ruiby.rb'
load FILE_SRC_CONS

class X < Ruiby_gtk
   def initialize(a,b,c)
        super(a,b,c)
    end	
	def component()
	  stack do
		$icons.keys.each do |n| 
			flow { slot(label(n)) ; slot(label("#"+get_icon_filename(n) )) }
		end
	  end
	end
end
Ruiby.start { X.new("eee",100,100) }