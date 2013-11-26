#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

# generade little snapshot of each demo script

samples=File.dirname(__FILE__)
media="#{samples}/media"

ls= Dir.glob("#{samples}/*.rb").select { |fn| fn !~ /make_/ }.map do |fn| 
  f=File.basename(fn); 
  ["#{media}/#{f.gsub(/\.rb$/,".png")}",fn]
end
ls.each do |(raster,rb)| 
  unless File.exists?(raster) && File.mtime(raster) > File.mtime(rb)
    p [raster,rb]
    system("ruby",rb,"take-a-snapshot")
    ifn="media/snapshot_#{File.basename(rb)}.png"
    system("convert",ifn,"-resize","120x300",raster)
    File.delete(ifn) rescue nil
  end
end