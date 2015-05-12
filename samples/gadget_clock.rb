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
    if width<2
      @cv.draw_line([x,y,x+r*Math.cos(a),y+r*Math.sin(a)],color,width) 
    else
      a1=(pos+0.75-width/60.0)*(Math::PI*2.0)
      a2=(pos+0.75+width/60.0)*(Math::PI*2.0)
			 r1=x/15.0
      x1,y1=x+r1*Math.cos(a1),y+r1*Math.sin(a1)
      x2,y2=x+r1*Math.cos(a2),y+r1*Math.sin(a2)
      x3,y3=x+r*Math.cos(a),y+r*Math.sin(a)
      @cv.draw_polygon([x,y,x1,y1,x3,y3,x2,y2,x,y],color,color,1) 
      @cv.draw_circle(x,y,2,color,color,1) 
    end
  end  

  #show_methods(self,/iz/)
  def expose(cv,ctx)
    ssize= size()
    @cv.set_size_request(ssize.first-2,ssize.last-2)
    cx,cy=ssize.first/2,ssize.last/2
    cy=cx if cy>cx
    ray=cx*0.8
    cy*=0.87
    @cv.draw_rectangle(0,0,ssize.first,ssize.last,0,$BG,$BG,0)
    @cv.draw_circle(cx,cy,ray,"#A0A0A0","#FFF",3)
    c=[[3,1],[5,3],[8,5]]
    60.times { |i| 
      type= if (i%15)==0 then 2 elsif (i%5)==0 then 1 else 0 end 
      @cv.draw_line([
          cx+(ray-2)*Math.cos(i*(Math::PI*2.0)/60.0),
          cy+(ray-2)*Math.sin(i*(Math::PI*2.0)/60.0),
          cx+(ray-c[type][0])*Math.cos(i*(Math::PI*2.0)/60.0),
          cy+(ray-c[type][0])*Math.sin(i*(Math::PI*2.0)/60.0)],
          "#FFF",c[type][1])
    }
    
    now=Time.now
    hour,min,sec=now.hour,now.min,now.sec
    min,sec=(now.to_i%3600)/60.0,now.to_f%60
    hour+=min/60.0
    
    @cv.draw_text(cx-35,[ssize.last-4,cy*2+16].min,"%02d:%02d:%02d" % [hour,min,sec],1.6,"#FFF")
    draw_aig(cv,cx,cy,ray/2,hour/12.0,4,"#FFF")
    draw_aig(cv,cx,cy,ray*2/3,min/60.0,2,"#FFF")
    draw_aig(cv,cx,cy,ray*0.9,sec/60.0,1,"#888")
  rescue 
    puts "#{$!}\n  #{$!.backtrace.join("\n  ")}\n\n\n"
  end
  
  anim(1000) { @cv.redraw  }
  after(1) { @cv.redraw  }
  anim(3000) { set_keep_above(true) } 
end

