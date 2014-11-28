# LGPL
###############################################################
# plot.rb plot data(s) of stdin to Gui display
# Usage:
#  > data-generator | \n
#          ruby  plot.rb -2 value-0 value-100% cpu --  10  0 5000 io auto
#                        ^input-column         ^label  ^in-column .. ^auto-scale
#      
#  > vmstat 1 | ruby plot.rb  10  0 500  io auto -- -3 100 0 cpu 
#                             ^columne 10
#                                                   ^columne end-3 (cpu idle)
#                                                      ^ min..max=100..0 (inverse)
# testing:
#  > ruby -e '$stdout.sync=true;a=50;loop {a+=rand(-1..+1);puts a.to_s;sleep 0.05}' \n
#      | ruby plot.rb --pos 0x200 --dim 400x100 0 0 100 alea auto
###############################################################

require_relative '../lib/Ruiby'
#require 'Ruiby'

$bgcolor=Ruiby_dsl.html_color("#023")
$axecolor=Ruiby_dsl.html_color("#AA8888")
$axeopacity=1
$fgcolor=[
	Ruiby_dsl.html_color("#99DDFF"),
	Ruiby_dsl.html_color("#FFAA00"),
	Ruiby_dsl.html_color("#00FF00"),
	Ruiby_dsl.html_color("#0000FF"),
	Ruiby_dsl.html_color("#FFFF00"),
	Ruiby_dsl.html_color("#00FFFF"),
	Ruiby_dsl.html_color("#FF00FF"),
	Ruiby_dsl.html_color("#999"),
]
class Measure
	class << self
		def create(argv)
			noc=argv.shift.to_i
			y0=(argv.shift||"0.0").to_f
			y1=(argv.shift||"100.0").to_f
			label=argv.shift||"?"
			autoscale=argv.size>0
			@lcurve||=[]
			@lcurve << Measure.new(noc,y0,y1,label,autoscale)
			@lcurve.size-1
		end
    def resize()
			@lcurve.each { |m| m.resize }
    end
		def add(noc,y0,y1,label,autoscale)
			@lcurve << Measure.new(noc,y0,y1,label,autoscale)
			@lcurve.size-1
		end
		def scan_line(line)
			nums=line.scan(/[\d+.]+/)
			@lcurve.each { |m| m.register_value(nums) }
		end
		def add_value(index,value)
			@lcurve[index].register_value(value)
		end
		def draw_measures(ctx)
			@lcurve.each_with_index { |m,index| m.plot_curve(index,ctx) }
			@lcurve.each_with_index { |m,index| m.plot_label(index,ctx) }
		end
    def getValuesAtX(x)
			@lcurve.map{ |m| "#{m.name} : #{m.get_value_at(x)}" }
    end
	end
  attr_reader :label,:name
	def initialize(noc,min,max,label,auto_scale)
	  @noc=noc
    @min,@max=min,max
	  @div,@offset=calc_coef(@min,0.0,@max,1.0)
	  @name=label
	  @value= 0
	  @curve=[]
	  @label=@name
	  @autoscale=auto_scale
	end
	def register_value(data)
		if data.is_a? Array
			svalue=data[@noc]
			return if !svalue || svalue !~ /[\d.]+/
			@value=svalue.to_f
		else
			@value=data
		end
		@label = "%s %5.2f" % [@name,@value]
		v= @value * @div + @offset
		py=[0.0,($H-HHEAD)*1.0,($H-HHEAD)*(1.0-v)].sort[1]+HHEAD
		@curve << [$W+PAS,py,v,@value]
		@curve.select! {|pt| pt[0]-=PAS; pt[0]>=0}
	  p [@value,v,py] if $DEBUG
	  auto_scale if @autoscale && @curve.size>5
	end
  def resize()
		   @div,@offset=calc_coef(@min,0.0,@max,1.0)
       nbPt=$W/PAS
       if nbPt<@curve.size
         @curve=@curve[(@curve.size-nbPt)..-1]
       end
       p0=$W-@curve.size*PAS
		   @curve.each_with_index {|a,i| 
         y=a[3]*@div+@offset
         a[0] = p0+i*PAS
         a[1] = ($H-HHEAD)*(1.0-y)+HHEAD
         a[2] = y
       }
  end
	def auto_scale()
		min,max=@curve.minmax_by {|pt| pt[2]}
		if min!=max && (min[2]<-0.01 || max[2]>1.01)
		   #p "correction1 #{@name} #{min} // #{max}"
       @min,@max=min[3],max[3]
       resize
		elsif (d=(max[2]-min[2]).abs)< 0.3 && (@curve.size-1) >= $W/PAS && d>0.0001
		   #p "correction2 #{@name} #{min} // #{max}"
		   @div,@offset=calc_coef(min[3],min[2]-3*d,max[3],max[2]+3*d)
		   @curve.each {|a| 
         a[2]=a[3]*@div+@offset 
         a[1] = ($H-HHEAD)*(1.0-a[2])+HHEAD
       }			
		end
	end
	def calc_coef(x0,y0,x1,y1)
    return [1,0] if  (x1-x0).abs< 0.00001
		y0=[0.0,1.0,y0].sort[1]
		y1=[0.0,1.0,y1].sort[1]
		a=1.0*(y0-y1)/(x0-x1)
    b= (y0+y1-(x0+x1)*a)/2
    [a,b]
	end
  def get_value_at(x)
    @curve.each { |pt| if pt[0]>=x then  return(pt.last) end }
    return(-1)
  end
	def plot_curve(index,ctx)
		return if @curve.size<2
		a,*l=@curve
		style(ctx,3,$fgcolor.last)   ; draw(ctx,a,l)
		style(ctx,1,$fgcolor[index]) ; draw(ctx,a,l)
	end
	def style(ctx,width,color)
		ctx.set_line_width(width)
		ctx.set_source_rgba(color.red/65000.0,color.green/65000.0,color.blue/65000.0, 1.0)
	end
	def draw(ctx,h,t)
		ctx.move_to(h.first,h[1])
		t.each {|x,y,*q| ctx.line_to(x,y) }
		ctx.stroke   
	end		
	def plot_label(index,ctx)
		style(ctx,3,$fgcolor[index]) 
		ctx.move_to(5+60*index,HHEAD-5)
		ctx.show_text(@label)
	end
end


def run(app)
	$str=$stdin.gets
	if $str
		p $str if $DEBUG
		Measure.scan_line($str)
		gui_invoke { redrawCv }
	else 
		exit!(0)
	end
end

def run_window()
	Ruiby.app width: $W, height: $H, title: "Curve" do
    set_resizable(true)
		chrome(false)
    @pos_markeur=[0,0]
    @comment=""
		stack do 
			@cv=canvas($W,$H) do
				on_canvas_draw { |w,ctx| expose(w,ctx) } 
        on_canvas_resize { |w,width,height| 
           w.width_request,w.height_request=0,0
           w.allocation.width,w.allocation.height=width,height
           $W,$H=width,height if width>0 && height>0
           Measure.resize
        }
        on_canvas_button_press { |w,e| 
          puts "button: #{ '%16X' % e.button} #{e.class}"
          puts "======================="
          e.methods.select {|m| m.to_s=~/=$/ }.each {|m| puts "e.#{m} => #{e.send(m.to_s[0..-2])}" rescue nil }
          @pos_markeur=[e.x,10]
          @comment=Measure.getValuesAtX(e.x).join("; ") 
        } 
	    end		
			popup(@cv) do
				pp_item(" Plot ")	{  }
				pp_separator
				pp_item("htop") { system("lxterminal", "-e", "htop") }
				pp_item("Gnome Monitor") { Process.spawn("gnome-system-monitor") }
				pp_item("Terminal") { system("lxterminal") }
				pp_separator
				pp_item("Exit")	{ ask("Exit ?") && exit!(0) }
			end
		end
		move($posxy[0],$posxy[1])
	    @ow,@oh=size
		def expose(cv,ctx)
      draw_background(ctx)
      draw_axes(ctx)
			Measure.draw_measures(ctx)
      draw_markeurs(ctx)
			(puts "source modified!!!";exit!(0)) if File.mtime(__FILE__)!=$mtime 
    rescue
     puts "#{$!}:\n  #{$!.backtrace().join("\n  ")}"
		end
    def redrawCv()
      if @pos_markeur[0] && @pos_markeur[0]>0
        @pos_markeur[0]-=PAS
      end
      @cv.redraw
    end
    def draw_background(ctx)
			ctx.set_source_rgba($bgcolor.red/65000.0, $bgcolor.green/65000.0, $bgcolor.blue/65000.0, 1)
			ctx.rectangle(0,0,$W,$H)
			ctx.fill()
			ctx.set_source_rgba($bgcolor.red/65000.0, $bgcolor.green/65000.0, 05+$bgcolor.blue/65000.0, 0.3)
			ctx.rectangle(0,0,$W,HHEAD)
			ctx.fill()		
    end
    def draw_axes(ctx)
			HHEAD.step($H,($H-HHEAD)/4)  { |h| line(ctx,0,h,    $W,h,$axecolor,$axeopacity,1) }
			0.step($W,$W/8)              { |w| line(ctx,w,HHEAD,w,$H,$axecolor,$axeopacity,1) }
			ctx.stroke()
    end
    def line(ctx,x0,y0,x1,y1,color,opacity,width)
			ctx.set_source_rgba(color.red/65000.0, color.green/65000.0, color.blue/65000.0, opacity)
		  ctx.set_line_width(width)
      ctx.move_to(x0,y0) ; ctx.line_to(x1,y1) ;ctx.stroke;
    end
    def draw_markeurs(ctx)
        if @pos_markeur.last>0
          ctx.set_line_width(3)
          ctx.set_source_rgba(1, 1, 1, 1)
          ctx.move_to(@pos_markeur.first+300,HHEAD-5);ctx.show_text("> "+@comment)
          ctx.set_source_rgba($axecolor.red/65000.0, $axecolor.green/65000.0, $axecolor.blue/65000.0, 1)
          ctx.move_to(@pos_markeur.first,$H) ; ctx.line_to(@pos_markeur.first,0) ;ctx.stroke;
          @pos_markeur[1]-=1
        end
    end
		$mtime=File.mtime(__FILE__)

		after(20) { Thread.new(self) { |app|  loop { run(app) } } }
	end
end

############################### Main #################################

#Thread.new { sleep 50 ; exit!(0) }

if $0==__FILE__
	trap("TERM") { exit!(0) }

	PAS=2
	HHEAD=20
	$posxy=[0,0]

	if  ARGV.size>=2 && ARGV[0]=="--pos"
	  _,posxy=ARGV.shift,ARGV.shift
	  $posxy=posxy.split(/[x,:]/).map(&:to_i)
	end  
	if  ARGV.size>=2 && ARGV[0]=="--dim"
	  _,geom=ARGV.shift,ARGV.shift
	  $W,$H=geom.split(/[x,:]/).map(&:to_i)
	else
		$W,$H=200,100
	end  

	while ARGV.size>0
	  argv=[]
	  argv << ARGV.shift  while ARGV.size>0 && ARGV.first!="--"
	  Measure.create(argv)
	  ARGV.shift if ARGV.size>0 && ARGV.first=="--"
	end
	run_window
end
