# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

# show all raster file which names are in  ARGV
# First example of a Ruiby.app
require_relative '../lib/Ruiby'

if ARGV.size==0
	Message.alert("Usage\n>ruby   images.rb    raster.png   raster.gif ....")
	exit
end

Ruiby.app(:width=> 800, :height=>800) do
	vbox_scrolled(800,800) do 
		table(3,ARGV.size) do
			ARGV.each { |fn| 
				row { 
					cell( w=image( fn ) )
					#cell(box { properties(fn,get_config(w.pixbuf))  if w.pixbuf })
					cell(box { properties(fn,get_config(w),{:scroll => [300,100]})})
				}
			}
		end
	end
end
