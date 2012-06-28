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
		def find_cover_bbox(x0,y0,x1,y1)
			@layers[1].select { |v| v.cover_bbox?(x0,y0,x1,y1) }
		end
		def find_into_bbox(x0,y0,x1,y1)
			@layers[1].select { |v| v.into_bbox?(x0,y0,x1,y1) }
		end
		def find_nerest(x0,y0)
			return nil if @layers[1].size==0
			l=@layers[1].map { |v| [v,v.distance(x0,y0)] }.sort { |a,b| 
				a[1] <=> b[1] 
			}
			l[0][0]
		end
		def nil_mouse_down(e) end
		def nil_mouse_move(e) redraw(e) end
		def nil_mouse_up(e)   redraw(e) end
		
	end
	class VElem
		def initialize() @lpoints=[];@style={} end
		def lpoints() @lpoints end
		def lpoints=(l) @lpoints=l end
		def set_style(s) @style=s.clone	end
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
		end
		def scale(x0,y0,rx,ry=nil) 
			ry=rx unless ry
			@lpoints.map! { |(x,y)| [x0+(x-x0)*rx,y0+(y-y0)*ry] }
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
	end
	
	class VElem_surface < VElem
		def define_style_before(ctx)
			ctx.set_line_width(@style[:stroke_width]) if @style[:stroke_width]
		end
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
			y= (@lpoints[0][1]+@lpoints[1][1])/2.0
			r= ((@lpoints[2][0]-@lpoints[0][0])/2.0).abs
			ctx.arc(x,y, r, 0, Math::PI*2)
		end
	end
	class Text		< VElem
		def set_text(text)
			@text=text
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
			define_style({})
		end
		def clear
			@current=nil
			super
		end
		def define_style(options)
			@cstyle={
				:stroke_width=>options[:width] || 1,
				:stroke_color=>conv_color(options[:fg] || [0,0,0,0]),
				:fill_color=>conv_color(options[:bg] || [1,1,1]) ,
				:font=>options[:font]|| "Sans",
				:font_size=>options[:font_size]|| 10
			}
			@current.set_style(@cstyle) if @current
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
			if @current
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
		def mode_selection()
			complete_edition()
			@select={}
			@layers[0]=[]
			@lasso=nil
			@mode=:select
		end
		def make_mark(x,y)
			m=SelMark.new
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
		def selection_vector(lv)
			@layers[0]=[]
			@lasso=nil
			p lv
			lv.each { |v| v.lpoints.each { |(x,y)| make_mark(x,y) } }
		end
		
		################################## Mouse Interaction for Selection
		def select_mouse_down(e) 
			@select[:pt0]=[e.x,e.y]
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
				v=find_nerest(*@select[:pt0])				
				v ? selection_vector([v]) : mode_selection()
			end
			redraw(e) 
		end
	end
end

################################### Drawer application #############################

class Application < Ruiby_gtk
    def initialize() 
		@win=nil
		@stroke_width=1
		@fgcolor=Gdk::Color.new(0,0,0)
		@bgcolor=Gdk::Color.new(1,1,1)
		@t=nil
		super("Vector Draw",800,800)  
	end
	def component()  		
		stack do
			################## Menu
			menu_bar do
				menu("File") {menu_button("Open") { } ; menu_button("Close") { } ;menu_button("New") { @win.clear} }
				menu("Edit") {menu_button("Cut") { } ; menu_button("Copy") { } ;menu_button("Past") { } ;menu_button("Copy style") { } }
			end
			############### Central zone
			flow do
				#------------------ Left menu
				stack { stacki do
				  button("#apply"){ @win.end_create_current()}
				  separator
				  button("#media/draw.png[0,0]x32") { @win.mode_create_polyline() ; @labl.text="Create Polyline"}
				  button("#media/draw.png[1,0]x32") { @win.mode_create_polygone() ; @labl.text="Create Polygone"}
				  button("#media/draw.png[2,0]x32") { @win.mode_create_rect()     ; @labl.text="Create rectangle"}
				  button("#media/draw.png[3,0]x32") { @win.mode_create_oval() 	  ; @labl.text="Create oval"}
				  button("#italic")					{ @win.mode_create_text() 	  ; @labl.text="Create text"}
				  button("#media/draw.png[4,0]x32") { @win.mode_create_image() 	  ; @labl.text="Create image"}
				end}
				#------------------ Canvas

				@win=editable_vector(700,700)
				
				#------------------ Right menu
				stack {space;stacki do
					button("Sel.") { @win.mode_selection() }
					button("#cut");button("#copy");button("#paste");button("#delete");button("#edit")
				end}
			end
			
			####################### Bottom zone : styles interaction
			flow do
			  @labl=label("left...")
			  space  
			  flow {
				color_choice("bg") { |c| @bgcolor=c ; define_style}
				color_choice("fg") { |c| @fgcolor=c ; define_style}
				islider(1,{:min=>1,:max=>30,:by=>1}) { |v| 
					@stroke_width=v.to_i
					define_style
				}
				islider(0,{:min=>0,:max=>180,:by=>1}) { |v| 
					@win.rotate(400,400,v.to_i)
				}
				islider(0,{:min=>-10,:max=>10,:by=>1}) { |v| 
					@win.scale(400,400,(v.to_i+10)/5.0,(v.to_i+10)/5.0)
				}
				@t=toggle_button("#play","#stop",false)
			  }
			  space
			  @labr=label("rigtht...")
			end
			button("reload") { load(__FILE__,0) rescue p $! }
		end
		$app=self
		define_style
		anim(10) {
			@win.rotate(400,400,0.1) if @t && @t.active?
			x= Time.now.to_i%2==0 ? 1 : -1
			@win.scale(400,400,1.0+x*0.001,1.0+x*0.001) if @t && @t.active?
		}
	end
	def define_style
		@win.define_style({:fg=>@fgcolor,:bg=>@bgcolor,:width=>@stroke_width})
	end
	def lstatus(text) @labl.text=text.to_s end
	def rstatus(text) @labr.text=text.to_s end
end
Ruiby.start { Application.new }