require_relative '../lib/Ruiby' 
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require "gst"
require "clutter-gtk" 
require "clutter-gst" 
Gem.loaded_specs.each {|name,gem| puts "  #{gem.name}-#{gem.version}"} 

p ClutterGst
p ClutterGst.constants
p ClutterGst.included_modules
p ClutterGst.methods.sort
exit(0)

Ruiby.app width: 600,height: 400 do
  video_file= ARGV[0] || "d:/usr/XT.avi"
  set_title(video_file)
  video_url=File.exists?(video_file) ?  "file:///#{video_file}" : video_file

  stack do
    (@v=video(video_url,600,400-40)  {|progress| @prog && @prog.progress=progress*100 })  rescue p $!
    Gem.loaded_specs.each {|name,gem| puts "  #{gem.name}-#{gem.version}"} 
    flowi {
      buttoni("  Start  ") {  @v.play }
      buttoni("  Stop  ") {  @v.stop }
      #@prog=slider(0,0,100.0) { |pos| @v.progress= pos/100.0}
      buttoni("  Exit  ") { exit!(0) }
    }
  end
  @v.play rescue p $!
  after(10000) { 
    @v.view.rotation_center_x=Clutter::Vertex.new(300,200,0)
    anim(50) {
      @v.view.rotation_angle_x+=0.1
      @v.view.rotation_angle_y+=0.1
    }
  }
  @luri=Dir.glob('d:/usr/local/video/avi/*.avi').map {|a|"file:///#{a}"}
  anim(40000) {
     if @luri.size>1
       @v.stop
       uri=@luri[rand(@luri.size-1).round]
       #log "switch to #{uri}"
       @v.url= uri
       @v.progress=rand
       @v.play     
     end
  }
end
