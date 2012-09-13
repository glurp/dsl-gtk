####################################################################################
#   tilesviewer.rb : show Map type OSM raster tiles 
####################################################################################
# Usage : 
#    > ruby tilesviewer.rb dir_tiles_path zoom_exam zoom_show
# Example :
#  ruby tilesviewer.rb d:\tbf_2012\saiaEclairagePublic\www\webapps\default\tiles 18 15
#    this show zomm level 18, with utilization of tiles raster of zoom level 15
#
####################################################################################
require_relative '../lib/ruiby'

if ARGV.size<3
	Message.alert("Usage\n>ruby #{$0}.rb  pathToTiles zoomLevel-examine  zommLevel-show")
	exit(0)
end

module Ruiby_dsl
	def radians(degrees) (Math::PI * degrees) / 180.0 end
	def degrees(radians) (radians * 180.0) / Math::PI end
	def tile_nums_2_lonlat(xtile, ytile, zoom)
	  factor = 2.0 ** (zoom)
	  lon = ((xtile * 360) / factor) - 180.0
	  lat = Math.atan(Math.sinh(Math::PI * (1 - 2 * ytile / factor)))
	  return  [lon,degrees(lat),zoom]
	end

	def img(filename,size)
	  onclick=proc {|w,e| 
		z,x,y=filename.split(/[\/.]/)[-4..-2].map(&:to_i)
		lon,lat,z=tile_nums_2_lonlat(x,y,z)
		lon1,lat1,z=tile_nums_2_lonlat(x+1,y+1,z)
		w.children[0].hide
		alert("#{filename.split("/")[-4..-1].join("/")}\n #{lon} / #{lat}\n #{lon1} / #{lat1}") 
		w.children[0].show
	  }
	  box  { pclickable(onclick) { image( filename,{:size=>size}) } }
	end
end

Ruiby.app(:width=> 800, :height=>800, :title=> "Tiles on #{ARGV[0]}") do
	dir="#{ARGV[0]}/#{ARGV[1]}".gsub('\\','/')
	
	z=ARGV[1].to_i
	za=ARGV[2].to_i
	sa=z-1 			if za<= z	
	diz="#{ARGV[0]}/#{za}".gsub('\\','/').gsub('\\','/')
	
	diff=2**(z-za) # nb tiles in level z for one tile in za level; by axe
	
	raise ("tiles dir not exist !") unless File.exists?(dir);
	raise ("tiles dir not exist !") unless File.exists?(diz);
	
	puts "scan dir X..."
	ld=Dir.entries(dir+"/").select {|n| n =~ /^\d+$/}.map {|d| d.to_i}.sort
	tab=Hash.new { |h,k| h[k]=Hash.new  }
	thy={}
	puts "scan dir Y..."
	ld.each { |y|
		ydir="#{dir}/#{y}"
		xld=Dir.entries(ydir).select {|n| n =~ /^\d+.png$/}.map {|d| d.split('.').first.to_i}.sort
		xld.each.each { |x|  
		  tab[x][y]="#{dir}/#{y}/#{x}.png" 
		  thy[y]=1
		}
	}
	
	minx,maxx= tab.keys.minmax
	miny,maxy= thy.keys.minmax
	nbtx,nbty=[maxx-minx,maxy-miny]
	$SZ= [800/[nbtx,nbty].max, 2].max
	#alert "nbx=%d nby=%d SZ=%d h=%d w=%d" % [nbtx,nbty,$SZ,nbtx*$SZ,nbty*$SZ]
	puts "go tiles draw, size=#{$SZ} ..."
	sx=(nbty+1)*$SZ
	sy=(nbtx+1)*$SZ
	
	set_default_size(sx,sy)	
	vbox_scrolled(sx,sy) do 
		frame { table((maxy-miny),(maxx-minx)) do
			(minx..maxx).each { |x|
				next if (x % diff)!=0
				p x
				row { 
					if tab[x].size>0
				      (miny..maxy).each { |y|  
						next if (y % diff)!=0
						filename="#{diz}/#{y/diff}/#{x/diff}.png"
					    cell( File.exists?(filename) ? img(filename,$SZ*diff)  : label("?") ) 
				      }
					else
					 label("?")
					end
				}
			 }
		end } 
	end
end
