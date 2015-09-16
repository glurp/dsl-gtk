#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
require 'Ruiby'

DEG_TO_RAD = Math::PI / 180.0
C=%w{AA0 EE0 FF0 EE0 EE8 EF8 8F8 7F7 0F0 5BB 0FF FAA} 

def draw_tree(cr,x1, y1, angle, depth)
	return if depth <= rand(2)
	s=rand(2.0..8.0)
	x2 = x1 + (Math.cos(angle * DEG_TO_RAD) * depth * s).to_i
	y2 = y1 + (Math.sin(angle * DEG_TO_RAD) * depth * s).to_i

	cr.set_line_width([1,5,depth/3].sort[1])
	color=Ruiby_dsl.cv_color_html(a="##{C[(C.size-depth)%C.size]}")
  p [a,color]
	cr.set_source_rgba(*color)
	cr.move_to(x1,y1)
	cr.line_to(x2,y2) 
	cr.stroke
	draw_tree(cr,x2, y2, angle + rand(-20..-10), depth - 1)
	draw_tree(cr,x2, y2, angle + rand(10..20), depth - 1)      
end
def draw_bg(cr,w,h,c1,c2)
	pattern = Cairo::LinearPattern.new(0.0, 0.0, 0.0, h)
	pattern.add_color_stop_rgba(0.0,Ruiby_dsl.cv_color_html(c1))
	pattern.add_color_stop_rgba(1.0,Ruiby_dsl.cv_color_html(c2))
	cr.rectangle(0,0,w,h)
	cr.set_source(pattern)
	cr.fill		
end

Ruiby.app title: "Fractal Tree", width: 600, height: 600 do
  
  stack   { 
    @cv=canvas(600,600) do 
		on_canvas_button_press { |w,cr| @on=true }
		on_canvas_button_motion {|w,e,o| true }
		on_canvas_button_release { |w,cr,o|  p false ;@on=false }
		on_canvas_draw { |w,cr| 
		    draw_bg(cr,600,600,"#60A0A0","#306060")
			draw_tree(cr,300,550,-90,12) 
		}
    end
  }
  @on=false
  #anim(100) { @cv.redraw if @on}
end