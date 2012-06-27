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
				:mouse_down => proc { |w,e|   self.send(@mode.to_s+"_mdown",e) },
				:mouse_move => proc { |w,e,o| self.send(@mode.to_s+"_mmove",e)  },
				:mouse_up   => proc { |w,e,o| self.send(@mode.to_s+"_mup",e)  }
			})
		end
		def widget() @cv end
		def clear
			@layers=[[],[]]
			@mode=:nil
			redraw
		end
		def expose(w,ctx)
			@layers.each { |l| l.each {|v| v.draw(w,ctx) } }
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
		
		def nil_mdown(e) end
		def nil_mmove(e) redraw(e) end
		def nil_mup(e)   redraw(e) end
		
	end
	class VElem
		def initialize() @lpoints=[];@style={} end
		def lpoints() @lpoints end
		def lpoints=(l) @lpoints=l end
		def set_style(s) @style=s.clone	end
		def draw(w,ctx)
			return if @lpoints.size==0
			define_style(ctx)
			render(ctx)
		end
		def render() raise('abstract') end
		def define_style(ctx)
			ctx.set_line_width(@style[:stroke_width]) if @style[:stroke_width]
			ctx.set_source_rgba(@style[:stroke_color][0], @style[:stroke_color][1], @style[:stroke_color][2], 1) if @style[:stroke_color]
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
	end
	class Polyline 	< VElem
		def render(ctx)
			ctx.move_to(*@lpoints[0])
			@lpoints[1..-1].each {|px|  ctx.line_to(*px) } 
			ctx.stroke  
		end
	end
	class Polygone	< VElem
		def render(ctx)
			ctx.move_to(*@lpoints[0])
			@lpoints[1..-1].each {|px|  ctx.line_to(*px) } 
			if @lpoints.size>2
				ctx.fill
			else
				ctx.stroke
			end
		end
	end
	class Oval		< VElem	; end
	class Image		< VElem ; end
end


#####################################################################
#                        Vector canvas editable                     #
#####################################################################
module Vector
	class VCanvas_editable < VCanvas
		def initialize(win,w,h,options)
			super
			@current=nil
			@cstyle={:stoke_width=>1,:stroke_color=>[0.8,0.4,0.4],:fill_color=>[0.8,0.4,0.4]}
		end
		def clear
			@current=nil
			super
		end
		def define_style(options)
			@cstyle={
				:stoke_width=>options[:width],
				:stroke_color=>conv_color(options[:fg]),
				:fill_color=>conv_color(options[:bg])
			}
			@current.set_style(@cstyle) if @current
		end
		def conv_color(color)
			p color
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
		def mode_modify()
			complete_edition()
		end
		def cpoly_mdown(e) @current.lpoints << [e.x,e.y]    end
		def cpoly_mmove(e) 
			if @current.lpoints.size==1
			 @current.lpoints << [e.x,e.y]
			else
			 @current.lpoints.last[0]=e.x;@current.lpoints.last[1]=e.y 
			end
			redraw(e) 
		end
		def cpoly_mup(e)   @current.lpoints.last[0]=e.x;@current.lpoints.last[1]=e.y ; redraw(e) end

		def crect_mdown(e) 
			if @lpoints.size==0
				@lpoints << [e.x,e.y]  
			end
		end
		def crect_mmove(e) 
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
		def crect_mup(e) 
			mode_create_rect() 
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
			menu_bar do
				menu("File") {menu_button("Open") { } ; menu_button("Close") { } ;menu_button("New") { @win.clear} }
				menu("Edit") {menu_button("Cut") { } ; menu_button("Copy") { } ;menu_button("Past") { } ;menu_button("Copy style") { } }
			end
			flow do
				stack { stacki do
				  button("end"){ @win.end_create_current()}
				  separator
				  button("pl") { @win.mode_create_polyline() ; @labl.text="Create Polyline"}
				  button("po") { @win.mode_create_polygone() ; @labl.text="Create Polygone"}
				  button("rec") { @win.mode_create_rect()    ; @labl.text="Create rectangle"}
				  button("ov") { @win.mode_create_oval() 	 ; @labl.text="Create oval"}
				  button("im") { @win.mode_create_image() 	 ; @labl.text="Create image"}
				end}
				 
				@win=editable_vector(700,700)
				
				stack {space;stacki do
					button("cut");button("copy");button("past");button("c.style")
				end}
			end
			flow do
			  @labl=label("left...")
			  space  
			  flow {
				color_choice("bg") { |c| @bgcolor=c ; define_style}
				color_choice("fg") { |c| @fgcolor=c ; define_style}
				@epaisseur=islider(1,{:min=>1,:max=>30,:by=>1}) { |v| 
					@stroke_width=v.to_i
					define_style
				}
				islider(0,{:min=>0,:max=>180,:by=>1}) { |v| 
					@win.rotate(400,400,v.to_i)
				}
				islider(0,{:min=>-10,:max=>10,:by=>1}) { |v| 
					@win.scale(400,400,(v.to_i+10)/5.0,(v.to_i+10)/5.0)
				}
				@t=toggle_button("anim","stopped",false)
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