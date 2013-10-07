require_relative '../lib/Ruiby' 
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

Ruiby.app width: 600,height: 400 do
  video_file= ARGV[0] || "d:/usr/XT.avi"
  unless File.exists?(video_file)
      error("File video does not exists : '#{video_file}'")
      exit!(0)
  end
  title=video_file
  video_url="file:///#{video_file}"
  x=stack do
    @v=video(video_url,600,400-40)  {|progress| @prog && @prog.progress=progress*100 }
    flowi {
      buttoni("  Start  ") {  @v.play }
      buttoni("  Stop  ") {  @v.stop }
      @prog=slider(0,0,100.0) { |pos| @v.progress= pos/100.0}
      buttoni("  Exit  ") { exit!(0) }
    }
  end
  autoslot()
  show_all_children(x)
  Gem.loaded_specs.map {|n,g| puts "  | %20s %6s " % [g.name,g.version] }
end
