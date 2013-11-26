# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require  'Ruiby'

samples=File.dirname(__FILE__)
media="#{samples}/media"
ldemo= Dir.glob("#{samples}/*.rb").select { |fn| fn !~ /make_/ }.map { |fn| f=File.basename(fn); ["#{media}/#{f.gsub(/\.rb$/,".png")}",fn]}

Ruiby.app width: 400, height: 600, title: "Ruiby Demos, see 'make_raster.rb' ..." do
  def lbutton(txt,&blk)
    box do  pclickable(blk) { label(txt) } end
  end
  stack do
  vbox_scrolled(400,600) do
     table(0,0) do
       ldemo.each do |(raster,rb)|
          if File.exists?(raster)
             row {  cell(image(raster)); cell_left(lbutton("run #{File.basename(rb)}") { run(rb) }) ; cell_left(lbutton("Source...") { edit(rb) }) } 
          else
             puts "#{raster} do not exist !!!"
          end
       end
     end
   end
  end
  def run(script)
    Thread.new { system("ruby",script) } 
    sleep 1
  end
end