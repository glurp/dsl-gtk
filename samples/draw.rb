# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

puts "Not terminted !!!!!"

require_relative '../lib/ruiby'

############################### Complete ruiby dsl for vector widget
module  Ruiby_dsl
	def vector(w,h,options={})	
		win=nil
		stack {
			win=Vector::VCanvas.new(self,w,h,options)
			slot(win.widget)
		}
		win
	end	
	def editable_vector(w,h,options={})	
		win=nil
		stack {
			win=Vector::VCanvas_editable.new(self,w,h,options)
			slot(win.widget)
		}
		win
	end
end

############################## define basic vector widget (not editable)
#                              end each vector type
module Vector
	class Bbox
		def initialize(*l)
			@x0,@y0,@x1,@y1=999999,999999,-999999,-999999
			if l.size==2 && Numeric===l[0]
				@x0=@x1=l[0]
				@y0=@y1=l[1]
			elsif l.size==4 && Numeric===l[0]
				add_point(l[0],l[1])
				add_point(l[2],l[3])
			end
		end 
		def values() [@x0,@y0,@x1,@y1] end
		def pvalues() [[@x0,@y0],[@x1,@y0],[@x1,@y1],[@x0,@y1]] end
		def add_lpoints(l) l.each { |(x,y)| add_point(x,y) } ; self end
		def <<(a,b=nil,c=nil,d=nil)
			if b==nil
			  Bbox === a ? add_bbox(a) : Array===a ? add_point(*a) : raise("error param bbox << ...")
			elsif c==nil
			  add_point(a,b)
			else
			  add_point(a,b)
			  add_point(c,d)
			end
			self
		end
		def add_point(x,y)
			@x0=x if x<@x0
			@y0=x if y<@y0
			@x1=x if x>@x1
			@y1=y if y>@y1
			self
		end
		def add_bbox(box)
			a,b,a1,b1=*box.values
			@x0=a  if a<@x0
			@y0=b  if b<@y0
			@x1=a1 if a1>@x1
			@y1=b1 if b1>@y1
			self
		end
	end
	
	class VCanvas
		def initialize(win,w,h,options)
			@layers=[[],[]]
			@mode=:nil
			@cv=win.canvas(w,h,{ 
				:expose     => proc { |w,ctx| self.expose(w,ctx) },
				:mouse_down => proc { |w,e|   self.send(@mode.to_s+"_mouse_down",e) },
				:mouse_move => proc { |w,e,o| self.send(@mode.to_s+"_mouse_move",e)  },
				:mouse_up   => proc { |w,e,o| self.send(@mode.to_s+"_mouse_up",e)  }
			})
		end
		
		def prt(*txt) puts "%-80s | %s" % [txt.map { |o| String===o ? o : o.inspect}.join(", ")[0..79],caller[0].to_s.split(/\//)[-1]] end
		def prt2(*txt) puts "%-80s | %s" % [txt.map { |o| String===o ? o : o.inspect}.join(", ")[0..79],caller[1].to_s.split(/\//)[-1]] end
		def to_svg(out)
			str=<<EEND
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20010904//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg
   xmlns:svg="http://www.w3.org/2000/svg"
       xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   x-width="%W%"
   x-height="%H%"
   viewport="0 0 %W% %H%"
   version="1.1"
   sodipodi:docname="%NAME%">
EEND
			x0,y0,x1,y1=bbox().values
			out << str.gsub(/%[^%]+%/,{ 
				"%W%" => x1.to_s,
				"%H%" => y1.to_s,
				"%NAME%" => "draw.svg"
			})
			@layers[1].each{ |v| v.to_svg(out)  }
			out << "\n</svg>"
		end
		def save_to_rdr(name)
			File.open(name,"wb") { |f| Marshal.dump(@layers[1],f) } 
		end
		def load_from_rdr(name)
			File.open(name,"rb") { |f| @layers[1]=Marshal.load(f) }	
		end
		def bbox() 
			@layers[1].inject(Bbox.new) {  |bb,v| v.append_to_bbox(bb) } 
		end
		def widget() @cv end

		def clear
			@layers=[[],[]]
			@mode=:nil
			redraw
		end
		def expose(w,ctx)
			@layers.reverse.each { |l| l.each {|v| v.draw(w,ctx) } }
		end
		def rotate(x,y,r) 
			@layers.each { |l| l.each {|v| v.rotate(x,y,r) } }
			redraw
		end
		def scale(x,y,rx,ry) 
			@layers.each { |l| l.each {|v| v.scale(x,y,rx,ry) } }
			redraw
		end
		def redraw(e=nil) 
			if defined?($app) && e
				$app.rstatus("#{e.x}, #{e.y}")
			end
			@cv.redraw()
		end
		
		#------------------ Query
		
		def find_cover_bbox(x0,y0,x1,y1,nolayer=1)
			@layers[nolayer].select { |v| v.cover_bbox?(x0,y0,x1,y1) }
		end
		def find_into_bbox(x0,y0,x1,y1,nolayer=1)
			@layers[nolayer].select { |v| v.into_bbox?(x0,y0,x1,y1) }
		end
		def find_nearest(x0,y0,nolayer=1)
			return nil if @layers[1].size==0
			l=@layers[nolayer].map { |v| [v,v.distance(x0,y0)] }.sort { |a,b| 
				a[1] <=> b[1] 
			}
			l[0][0]
		end
		def find_hoover(x0,y0,nolayer=1)
			@layers[nolayer].select { |v| v.hoover_point?(x0,y0) }[0]
		end
		def nil_mouse_down(e) end
		def nil_mouse_move(e) redraw(e) end
		def nil_mouse_up(e)   redraw(e) end
		
	end
	class VElem
		def initialize() @lpoints=[];@style={} end
		def bbox()
			@lpoints.inject(Bbox.new){ |bb,p| bb << [p[0],p[1]] }
		end
		def append_to_bbox(box)
			@lpoints.each { |p| box << [p[0],p[1]] }
			box
		end
		def vclone()
			n=self.clone
			n.lpoints=lpoints.clone
			n.set_style(@style.clone)
			n
		end
		def to_svg(out)
			out << "  <#{self.svg_tag()} dr='#{self.class}' d='#{self.svg_path()}' style='#{self.svg_style}'/>\n"
		end
		def svg_tag() "path" end
		def svg_path() "M"+lpoints.map {|p| "#{p[0]},#{p[1]}" }.join(" L") end
		def svg_style() "fill:##{svgc(:fill_color)};fill-opacity:#{1};stroke:##{svgc(:stroke_color)};stroke-width:#{@style[:stroke_width]||"0"};" end
		def svgc(name)  @style[name] ? "%02X%02X%02X" % @style[name].map { |v| (v*255).round } : "000000" end
	
		def lpoints() @lpoints end
		def lpoints=(l) @lpoints=l end
		def set_style(s) @style=s.clone	end
		def get_style(s) @style.clone	end
		def draw(w,ctx)
			return if @lpoints.size==0
			define_style_before(ctx)
			render(ctx)
			define_style_after(ctx)
		end
		
		def define_style_before(ctx)
			ctx.set_line_width(@style[:stroke_width]) if @style[:stroke_width]
			ctx.set_source_rgba(@style[:stroke_color][0], @style[:stroke_color][1], @style[:stroke_color][2], 1) if @style[:stroke_color]
		end
		def render() raise('abstract') end
		def define_style_after(ctx)
		end
		
		def clone_empty() self.class.new() end
		def rotate(x0,y0,r) 
			a=Math::PI*(r/180.0)
			@lpoints.map! { |(x,y)| [x0+(x-x0)*Math.cos(a)+(y-y0)*Math.sin(a),y0-(x-x0)*Math.sin(a)+(y-y0)*Math.cos(a)] }
			self
		end
		def deplace(dx,dy)
			@lpoints.map! { |(x,y)| [x+dx,y+dy] }
			self
		end
		def scale(x0,y0,rx,ry=nil) 
			ry=rx unless ry
			@lpoints.map! { |(x,y)| [x0+(x-x0)*rx,y0+(y-y0)*ry] }
			self
		end
		def distance(x0,y0)
			return(2_999_999_999) if @lpoints.size==0
			@lpoints.map { |(x1,y1)| Math.hypot(x1-x0,y1-y0)}.sort()[0]
		end 
		def cover_bbox?(x0,y0,x1,y1)
			@lpoints.select { |(x,y)| pt_in_bbox?(x,y, x0,y0,x1,y1)}.size>0
		end
		def into_bbox?(x0,y0,x1,y1)
			return(false) if @lpoints.size==0
			@lpoints.select { |(x,y)| pt_in_bbox?(x,y, x0,y0,x1,y1)}.size==@lpoints.size
		end
		def pt_in_bbox?(x,y, x0,y0,x1,y1)
			(x>=x0 && x<= x1 && y>=y0 && y<=y1)
		end
		def hoover_point?(x,y)
			distance(x,y)<10
		end
	end
	
	class VElem_surface < VElem
		def define_style_before(ctx)
			ctx.set_line_width(@style[:stroke_width]) if @style[:stroke_width]
		end
		def svg_path() super()+" Z" end
		def render() raise('abstract') end
		def define_style_after(ctx)
			if @style[:stroke_width]&&@style[:stroke_width]>0
				ctx.set_source_rgba(@style[:fill_color][0], @style[:fill_color][1], @style[:stroke_color][2], 1) if @style[:fill_color]
				ctx.fill_preserve
			end
			ctx.set_source_rgba(@style[:stroke_color][0], @style[:stroke_color][1], @style[:stroke_color][2], 1) if @style[:stroke_color]
			ctx.stroke
		end
	end
	class Group < VElem
		def initialize(l) @lvector=l.dup end
		def set_lvector(l)  @lvector=l.dup end
		def get_lvector()   @lvector.dup end
		def bbox()
			@lvector.inject(Bbox.new){ |bb,p| p.append_to_bbox(bb) }
		end
		def append_to_bbox(box)
			@lvector.inject(bbox) { |bb,p| p.append_to_bbox(bb) };
		end
		def vclone()
			Group.new(@lvector.map { |v| v.vclone })
		end
		def to_svg(out)
			out << "  <g>\n"
			@lvector.each{|v| v.to_svg(out)}
			out << "  </g>\n"
		end
	
		def lpoints() bbox().pvalues end
		def lpoints=(l) end
		def set_style(s) 	end
		def get_style(s) {}	end
		def draw(w,ctx)
			return if @lvector.size==0
			@lvector.each{|v| v.draw(w,ctx)} 
		end
		
		def render(ctx)  end		
		def rotate(x0,y0,r) @lvector.each{|v| v.rotate(ctx)} ; self end
		def deplace(dx,dy) @lvector.each{|v| v.deplace(dx,dy)} ; self end
		def scale(x0,y0,rx,ry=nil) @lvector.each{|v| v.scale(x0,y0,rx,ry)} ; self end
		def distance(x0,y0) 
			return(2_999_999_999) if @lvector.size==0
			@lvector.map{|v| v.distance(x0,y0)}.sort[0] 
		end 
		def cover_bbox?(x0,y0,x1,y1)
			return(false) if @lvector.size==0
			@lvector.any?{|v| v.cover_bbox?(x0,y0,x1,y1) }
		end
		def into_bbox?(x0,y0,x1,y1)
			return(false) if @lvector.size==0
			@lvector.any?{|v| v.into_bbox?(x0,y0,x1,y1) }
		end
		def hoover_point?(x,y)
			distance(x,y)<10
		end
	end
	
	class Polyline 	< VElem
		def render(ctx)
			ctx.move_to(*@lpoints[0])
			@lpoints[1..-1].each {|px|  ctx.line_to(*px) } 
			ctx.stroke  
		end
	end
	class Polygone	< VElem_surface
		def render(ctx)
			ctx.move_to(*@lpoints[0])
			@lpoints[1..-1].each {|px|  ctx.line_to(*px) } 
			ctx.close_path
		end
	end
	class SelRectangle < VElem
		def define_style_before(ctx)
			ctx.set_line_width(2) 
			ctx.set_source_rgba(0.3,0.3,0.7,0.8)
		end
		def define_style_after(ctx)
			ctx.set_source_rgba(0.3,0.3,0.7,0.3)
			ctx.fill_preserve
			ctx.set_source_rgba(0.3,0.3,0.7,0.8)
			ctx.stroke
		end
		def render(ctx)
			return if @lpoints.size!=2
			x0,y0,x1,y1=*(@lpoints.flatten)
			ctx.move_to(x0,y0)
			ctx.line_to(x1,y0);ctx.line_to(x1,y1);ctx.line_to(x0,y1);ctx.line_to(x0,y0);
		end
		def order
			return if @lpoints.size!=2
			x0,y0,x1,y1=@lpoints.flatten
			@lpoints=[
				[[x0,x1].min,[y0,y1].min],
				[[x0,x1].max,[y0,y1].max]
			]
		end
	end
	class SelMark < VElem
		def initialize(sel_vector=nil,index=nil)
			@sel_vector,@index=sel_vector,index
		end
		def deplace(dx,dy)
			return(self) if @lpoints.size!=1
			super
			@sel_vector.lpoints[@index]=@lpoints[0] if @sel_vector && @index
			self
		end
		def define_style_before(ctx)
			ctx.set_line_width(1) 
			ctx.set_source_rgba(0.3,0.3,1,0.8)
		end
		def render(ctx)
			return if @lpoints.size!=1
			t=4
			xc,yc=@lpoints[0]
			x0,y0,x1,y1=*[xc-t,yc-t,xc+t,yc+t]
			ctx.move_to(x0,y0)
			ctx.line_to(x1,y0);ctx.line_to(x1,y1);ctx.line_to(x0,y1);ctx.line_to(x0,y0);
			ctx.fill
		end
	end
	class Oval		< VElem_surface
		def render(ctx)
			return if @lpoints.size<4
			x= (@lpoints[0][0]+@lpoints[2][0])/2.0
			y= (@lpoints[0][1]+@lpoints[2][1])/2.0
			r= ((@lpoints[2][0]-@lpoints[0][0])/2.0).abs
			ctx.arc(x,y, r, 0, Math::PI*2)
		end
	end
	class Text		< VElem
		def set_text(text)
			@text=text
		end
		def to_svg(out)
			out << "  <text dr='#{self.class}' x='#{@lpoints[0][0]}' y='#{@lpoints[0][1]}' style='#{self.svg_style}'>#{@text}</text>\n"
		end
		def render(ctx)
			return if @lpoints.size!=1
			ctx.select_font_face(@style[:font] ,Cairo::FONT_SLANT_NORMAL,Cairo::FONT_WEIGHT_BOLD)
			ctx.set_font_size(@style[:font_size])
			ctx.move_to(@lpoints[0][0],@lpoints[0][1])
			ctx.show_text(@text|| "unknown" )
			ctx.fill
			ctx.stroke
		end
	end
	class Image		< VElem
		def set_image(filename)
			@filename=filename
			@pixbuf = $app.get_image_from(@filename).pixbuf
		end
		def render(ctx)
			return if @lpoints.size!=1 || ! defined?(@pixbuf) || ! @pixbuf
			ctx.set_source_pixbuf(@pixbuf, @lpoints[0][0],@lpoints[0][1])
			ctx.paint
		end
	end
end


#####################################################################
#                        Vector canvas editable                     #
#####################################################################
module Vector
	class VCanvas_editable < VCanvas
		def initialize(win,w,h,options)
			super
			@current=nil
			@select={}
			@corbeill=[]
			define_style({})
			#------------------------ create one vector for easy test
			@current=Polyline.new
			@current.lpoints=[[100,200],[100,10],[200,300],[400,300],[200,200]]
			define_style({})
			complete_edition()
			#------------------------
			mode_selection()
		end
		def clear
			@current=nil
			super
		end
		def define_style(options)
			if @current 
				@current.set_style(@cstyle) 
				redraw
			end
			if @select.size>0 && @select[:list] && @select[:list].size>0
				@select[:list].each { |v| v.set_style(options) }
			else
				@cstyle={
					:stroke_width=>options[:width] || 1,
					:stroke_color=>conv_color(options[:fg] || [0,0,0,0]),
					:fill_color=>conv_color(options[:bg] || [1,1,1]) ,
					:font=>options[:font]|| "Sans",
					:font_size=>options[:font_size]|| 10
				}
			end
		end
		def conv_color(color)
			return color if Array === color
		    [color.red/65535.0,color.green/65535.0,color.blue/65535.0]
		end
		def expose(w,ctx)
			super
			@current.draw(w,ctx) if @current
		end
		def complete_edition()
			if @current && @current.lpoints.size>0
				@layers[1] << @current  
				@current=@current.clone_empty
			end
		end
		def end_create_current()
			complete_edition()
		end
		def mode_create_polyline()
			complete_edition()
			@current=Polyline.new
			@current.set_style(@cstyle)
			@mode=:cpoly
		end
		def mode_create_polygone()
			complete_edition()
			@current=Polygone.new
			@current.set_style(@cstyle)
			@mode=:cpoly
		end
		def mode_create_rect()
			complete_edition()
			@current=Polygone.new
			@lpoints=[]
			@current.set_style(@cstyle)
			@mode=:crect
		end
		def mode_create_oval()
			complete_edition()
			@current=Oval.new
			@lpoints=[]
			@current.set_style(@cstyle)
			@mode=:crect
		end
		def mode_create_text()
			complete_edition()
			@current=Text.new
			@lpoints=[]
			@current.set_style(@cstyle)
			@mode=:cpoint
		end
		def mode_create_image()
			complete_edition()
			@current=Image.new
			@lpoints=[]
			@current.set_style(@cstyle)
			@mode=:cpoint
		end
		def mode_modify()
			complete_edition()
		end
		
		########################## Mouse Interaction for Poly___
		
		def cpoly_mouse_down(e) @current.lpoints << [e.x,e.y]    end
		def cpoly_mouse_move(e) 
			if @current.lpoints.size==1
			 @current.lpoints << [e.x,e.y]
			else
			 @current.lpoints.last[0]=e.x;@current.lpoints.last[1]=e.y 
			end
			redraw(e) 
		end
		def cpoly_mouse_up(e)   @current.lpoints.last[0]=e.x;@current.lpoints.last[1]=e.y ; redraw(e) end

		########################## Mouse Interaction for Rectangle/Oval
		def crect_mouse_down(e) 
			if @lpoints.size==0
				@lpoints << [e.x,e.y]  
			end
		end
		def crect_mouse_move(e) 
			if @lpoints.size==1
				@lpoints << [e.x,e.y]  
			else
				@lpoints.last[0]=e.x;@lpoints.last[1]=e.y 
			end
			@current.lpoints=[
					@lpoints[0],
					[@lpoints[1][0],@lpoints[0][1]],
					@lpoints[1],
					[@lpoints[0][0],@lpoints[1][1]]
			]
			redraw(e) 
		end
		def crect_mouse_up(e) 
			case @current 
			 when Polygone then mode_create_rect() 
			 when Oval     then mode_create_oval() 
			end
			redraw(e) 
		end
		########################## Mouse Interaction for Text/Image
		def cpoint_mouse_down(e) p(e) end
		def cpoint_mouse_move(e) p(e) end
		def cpoint_mouse_up(e)   
			@current.lpoints=[[e.x,e.y]]
			case @current 
			  when Text
			    $app.prompt("Text ?") {|t| 
					@current.set_text(t)
					mode_create_rect() 
					redraw(e) 
				}
			  when Image 
				f=$app.ask_file_to_read(".","*.png")
				return unless f
				$app.prompt("Detail sur #{f} ? ([Col,Row]xSize}",f) { |fi|
					@current.set_image(fi)
					mode_create_image() 
					redraw(e) 
				}
			end
		end
		
		################################################################
		#    Selection : mode, select voctor(s), interact with them
		################################################################		
		def has_selection?() (@select && @select[:list] && @select[:list].size>0)	end
		def mode_selection()
			complete_edition()
			@current=nil
			@select={}
			@layers[0]=[]
			@lasso=nil
			@mode=:select
			redraw
		end
		def selection_vector(lv)
			@layers[0]=[]
			@lasso=nil
			@select[:list]= []
			lv.each { |v|
				if v.lpoints.size>0
					v.lpoints.each_with_index { |(x,y),i| make_mark(v,i,x,y) } 
				else
				end
				@select[:list] << v
			}
			mode=:select
		end
		def make_mark(v,i,x,y)
			m=SelMark.new(v,i)
			m.lpoints=[[x,y]]
			@layers[0]<<m
			m
		end
		def make_lasso(x0,y0,x1,y1)
			r=SelRectangle.new
			r.lpoints=[[x0,y0],[x1,y1]]
			@layers[0]<<r
			@lasso=r
			r
		end
		def cut()
			return unless  has_selection?()
			@corbeill=[]
			l=@select[:list]
			mode_selection()
			l.each { |sel| 
				a,b=@layers[1].partition { |v| v!=sel }
				@corbeill += b
				@layers[1]=a
			}			
			prt "corbeill=",@corbeill 
			redraw
		end
		def copy()
			return unless  has_selection?()
			@corbeill=[]
			@select[:list].each { |sel| 
				@corbeill += @layers[1].select { |v| v==sel }
			}
			mode_selection()
			prt "corbeill=",@corbeill 
		end
		def past()
			return if @corbeill.size==0
			prt " << ",@corbeill 
			@layers[1] += @corbeill.map { |v| v.vclone.deplace(3,3) }
			redraw
		end
		def copystyle() 
			return  unless has_selection?()
			copy()
			@cstyle=@select[:list][0].get_style()
		end
		def edit() 
			str=to_svg("")
			$app.edit(str)
		end
		def sel_top()      
			return  unless has_selection?()
			@select[:list].each { |v| @layers[1].delete(v) }
			@layers[1].push(*@select[:list]) 
			selection_vector(@select[:list])
			redraw
		end
		def sel_bottom()   
			return  unless has_selection?()
			@select[:list].each { |v| @layers[1].delete(v) }
			@layers[1]= @select[:list] + @layers[1] 
			selection_vector(@select[:list].dup)
			redraw
		end
		def sel_group()
			return  unless has_selection?()
			@select[:list].each { |v| 
				@layers[1].delete(v) 
			}
			g=Group.new(@select[:list])
			@layers[1].push(g)
			selection_vector([g])
			redraw
		end
		def sel_ungroup()  
			return  unless has_selection?()
			return unless @select[:list].size==1 &&  @select[:list][0].is_a?(Group)
			v=@select[:list][0]
			lv=v.get_lvector
			@layers[1].delete(v) 
			lv.reverse.each { |v| @layers[1].unshift(v)}
			selection_vector(lv)
			redraw
		end
		def sel_align(direction,sens)
			return  unless has_selection?()
			lv=@select[:list]
			bx0,by0,bx1,by1=Group.new(lv).bbox.values
			lv.each { |v| 
				x0,y0,x1,y1=v.bbox().values				
				v.deplace(direction==0? (sens==0 ? (bx0-x0):(bx1-x1)):0,
						  direction==1? (sens==1 ? (by0-y0):(by1-y1)):0
				)
			}
			selection_vector(lv)
			redraw
		end
		
		################################## Mouse Interaction for Selection
		def select_mouse_down(e) 
			if r=find_hoover(e.x,e.y,0)
				@select[:vector]=[r,r.lpoints[0].clone]
				@mode=:mselect
			else
				@select[:pt0]=[e.x,e.y]
			end
		end
		def select_mouse_move(e) 
			@select[:pt1]=[e.x,e.y]
			if !@lasso
				make_lasso(*@select[:pt0],*@select[:pt1])
			else
			   @lasso.lpoints[1]=[e.x,e.y]
			end
			redraw(e) 
		end
		def select_mouse_up(e)   
			if @lasso
				@lasso.order
				l=find_into_bbox(*@lasso.lpoints.flatten)
				l=find_cover_bbox(*@lasso.lpoints.flatten) if l.size==0
				l.size>0 ? selection_vector(l) : mode_selection()
			else
				v=find_nearest(*@select[:pt0])				
				v ? selection_vector([v]) : mode_selection()
			end
			redraw(e) 
		end
		
		def mselect_mouse_move(e) 
			x0,y0=*@select[:vector][1]
			@select[:vector][0].deplace(e.x-x0,e.y-y0)
			@select[:vector][1]=[e.x,e.y]
			redraw(e) 
		end
		def mselect_mouse_up(e)   
			mode_selection()
		end
	end  # fin class
end  # fin module

################################### Drawer application #############################

class Application < Ruiby_gtk
    def initialize() 
		@win=nil
		@stroke_width=1
		@fgcolor=Gdk::Color.new(0,0,0)
		@bgcolor=Gdk::Color.new(1,1,1)
		@filename=nil
		@t=nil
		super("Vector Draw",800,800)  
	end

	def component()  		
		stack do
			################## Menu
			menu_bar do
				menu("File") {
					menu_button("Open") { fopen() }
					menu_button("Save") { fsave() }
					menu_button("Save as...") { fsave_as() }
					menu_button("Rename as...") { frename() } 
					menu_separator
					menu_button("Export...") { fexport() }
					menu_button("New") {  fclear()  }
					menu_separator
					menu_button("Exit") {  ruiby_exit }
				}
				menu("Edit") {
					menu_button("Cut") { cut() } ; menu_button("Copy") { copy() } ;menu_button("Past") { past() } ;menu_button("Copy style") { copystyle()} 
				}
			end
			############### Central zone
			flow do
				#------------------ Left menu
				stack { stacki do
				  button("#apply"){ @win.end_create_current()}
				  separator
				  button("#media/draw.png[0,0]x22") { @win.mode_create_polyline() ; @labl.text="Create Polyline"}
				  button("#media/draw.png[1,0]x22") { @win.mode_create_polygone() ; @labl.text="Create Polygone"}
				  button("#media/draw.png[2,0]x22") { @win.mode_create_rect()     ; @labl.text="Create rectangle"}
				  button("#media/draw.png[3,0]x22") { @win.mode_create_oval() 	  ; @labl.text="Create oval"}
				  button("#italic")					{ @win.mode_create_text() 	  ; @labl.text="Create text"}
				  button("#media/draw.png[4,0]x22") { @win.mode_create_image() 	  ; @labl.text="Create image"}
				end}
				#------------------ Canvas

				@win=editable_vector(700,700)
				
				#------------------ Right menu
				stack {space;stacki do
					button("Sel.") { @win.mode_selection() }
					button("#cut") { @win.cut() };button("#copy") { @win.copy() };button("#paste") { @win.past() }; space ; button("#edit") { @win.edit() }
				end}
			end
			
			####################### Bottom zone : styles interaction
			flow do
			  @labl=label("Left label...")
			  flow {
				button("#media/draw.png[0,1]x22") { @win.sel_top()      }
				button("#media/draw.png[1,1]x22") { @win.sel_bottom()   }
				button("#media/draw.png[2,1]x22") { @win.sel_group()    }
				button("#media/draw.png[3,1]x22") { @win.sel_ungroup()  }
				button("#media/draw.png[4,1]x22") { @win.sel_align(0,0) }
				button("#media/draw.png[5,1]x22") { @win.sel_align(0,1) }
				button("#media/draw.png[6,1]x22") { @win.sel_align(1,1) }
				button("#media/draw.png[7,1]x22") { @win.sel_align(1,1) }
				color_choice("bg") { |c| @bgcolor=c ; define_style}
				color_choice("fg") { |c| @fgcolor=c ; define_style}
				label("Width :")
				ientry(1,{:min=>1,:max=>100,:by=>1}) { |v| 
					@stroke_width=v.to_i
					define_style
				}
				label("Rotate :")
				ientry(0,{:min=>0,:max=>180,:by=>1}) { |v| 
					@win.rotate(400,400,v.to_i)
				}
				label("Scale :")
				ientry(0,{:min=>-10,:max=>10,:by=>1}) { |v| 
					@win.scale(400,400,(v.to_i+10)/5.0,(v.to_i+10)/5.0)
				}
				label("Animation :")
				@t=toggle_button("#play","#stop",false)
			  }
			  @labr=label("rigtht label...")
			end
			button("reload") { 
				puts "----------------------------------"
				begin
					load(__FILE__) 
				rescue Exception => e
					error($!) 
				end
				puts "----------------------------------"
			}
		end
		$app=self
		define_style
		anim(10) {
			@win.rotate(400,400,0.1) if @t && @t.active?
			x= Time.now.to_i%2==0 ? 1 : -1
			@win.scale(400,400,1.0+x*0.001,1.0+x*0.001) if @t && @t.active?
		}
	end # end component()
	def define_style
		@win.define_style({:fg=>@fgcolor,:bg=>@bgcolor,:width=>@stroke_width,:font=>"Arial",:font_size=>33})
	end
	def lstatus(text) @labl.text=text.to_s end
	def rstatus(text) @labr.text=text.to_s end
	
	def fopen() 
		fn=ask_file_to_read(".","*.rdr")
		if fn
			fclear()
			(@win.load_from_rdr(fn);@filename=fn)  rescue error($!)
		end
	end
	def fsave() 
		@filename=ask_file_to_write(".","*.rdr") unless  @filename
		if @filename
			(@win.save_to_rdr(@filename);alert("#{@filename} saved !")) rescue error($!)
		end
	end
	def fsave_as() 
		fn=ask_file_to_write(".","*.rdr")
		if fn
			@filename=fn
			fsave()
		end
	end
	def fexport() 
		fn=ask_file_to_write(".","*.svg")   
		if fn
			(File.open(fn,"w") { |f| @win.to_svg(f) };alert("#{fn} saved !")) rescue error($!)
		end
	end
	def frename() 
		return unless @filename
		fn=ask_file_to_write(".","*.svg")
		if fn && File.exists?(@filename)
			@filename,fn=fn,@filename
			fsave()
			File.delete(fn) if File.exists?(fn) && File.exists?(@filename)
		end
	end
	
	def fclear() @win.clear ; @filename=nil end

end

Ruiby.start { Application.new }