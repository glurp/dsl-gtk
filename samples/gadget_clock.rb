# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#################################################################
##  gadget_clock.rb
#################################################################
require 'gems' # gem install gems !!!

require 'Ruiby'

$BG="#383848"

Ruiby.app width: 120,height: 120, title: "Clock" do
  chrome(false)
  @chrome=false
  set_resizable(true)
  stack do 
    @cv=canvas(120,120) do
      on_canvas_draw { |w,ctx| expose(w,ctx) } 
      on_canvas_button_press { |w,e| 
        @chrome=!@chrome
        chrome(@chrome)
        false # event is not consume; do the popup...
      } 
    end		
  end
  def draw_aig(cv,x,y,r,pos,width,color) 
    a=(pos+0.75)*(Math::PI*2.0)
    @cv.draw_line([x,y,x+r*Math.cos(a),y+r*Math.sin(a)],color,width) 
  end  
  #show_methods(self,/iz/)
  def expose(cv,ctx)
    ssize= size()
    @cv.set_size_request(ssize.first,ssize.last)
    cx,cy=ssize.first/2,ssize.last/2
    ray=cx*0.8
    @cv.draw_rectangle(0,0,cx*2,cy*2,0,$BG,$BG,0)
    @cv.draw_circle(cx,cy,ray,"#A0A0A0","#FFF",3)
    12.times { |i| 
      @cv.draw_line([
          cx+(ray)*Math.cos(i*(Math::PI*2.0)/12.0),
          cy+(ray)*Math.sin(i*(Math::PI*2.0)/12.0),
          cx+(ray-6)*Math.cos(i*(Math::PI*2.0)/12.0),
          cy+(ray-6)*Math.sin(i*(Math::PI*2.0)/12.0)],
          "#FFF",3)
    }
    
    now=Time.now
    hour,min,sec=now.hour,now.min,now.sec
    @cv.draw_text(cx-40,cy*2-3,"%02d:%02d:%02d" % [hour,min,sec],1.8,"#FFF")
    draw_aig(cv,cx,cy,ray/2,hour/12.0,4,"#FF0000")
    draw_aig(cv,cx,cy,ray*2/3,min/60.0,2,"#FFFF00")
    draw_aig(cv,cx,cy,ray*0.9,sec/60.0,1,"#808080")
  rescue 
    puts "#{$!}\n  #{$!.backtrace.join("\n  ")}\n\n\n"
  end
  
  anim(1000) { @cv.redraw  }
  after(1) { @cv.redraw  }
end

