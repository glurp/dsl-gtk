# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
##################################################################################
# quadvideo.rb : show multiple video stream in one window                         
# Usage: 
#   > ruby  quadvideo.rb  video-width/4 nb-colomn nb-lines rtsp://ip:port/video
#
# for emulate some rtsp stream camera, see vlm.rb, with VIDEOLAN/Vlc installed !
#
######################################################################

require_relative '../lib/Ruiby.rb'

Gem.loaded_specs.map {|n,g| puts "  | %10s %6s " % [g.name,g.version] }

w,nbcol,nblign,url=*ARGV
w,nbcol,nblign=w.to_i,nbcol.to_i,nblign.to_i
Ruiby.app width: (w*4*nbcol),height: (w*3*nblign),title: "Quad" do
  video_file= url || "d:/usr/XT.avi"
  stack { table(0,0) do
    nblign.times do
      row {  nbcol.times { cell( box {  video=video(video_file,w*4,w*3);  video.play  } ) } }
    end
  end }
end
