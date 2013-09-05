#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#####################################################################
#  canvas.rb : edit/test drawing code
#####################################################################
# encoding: utf-8
require 'timeout'
require_relative '../lib/Ruiby'

class RubyApp < Ruiby_gtk
    include Math 

    def initialize
      @blk=nil
      @redraw_error=false
      super("Canvas",800,900)
      @filedef=Dir.tmpdir+"/canvas_default.rb"
      if  File.exists?(@filedef)
        load(@filedef,nil)
      else
        @edit.buffer.text=<<-EEND
def exp(z,d,a)
  p=(a-0.5)*(a-0.5)*(a-0.5)
  x=z*p
  d+x
end

z,d=1000,[200,400] ; 10000.times do
    a,dist=rand*360, exp(z,0,rand)
	pt(d[0]+dist*Math.cos(a),d[1]+dist*Math.sin(a) ,"#000",1)
end if true

if true 
	axes(20,800,800,20,10)
	plot_yfx(10,3) { |x| 20+100+100*Math.sin(Math::PI*x/40)}
end

          EEND
      end
    end
	def component()
		stack do
			sloti(htoolbar(
				"open/Open file..."=> proc {
					load(ask_file_to_read(".","*.rb"),nil)
				},
				"Save/Save buffer to file..."=> proc {
					@file=ask_file_to_write(".","*.rb") unless File.exists?(@file)
					@title.text=@file
					content=@edit.buffer.text
					File.open(@file,"wb") { |f| f.write(content) } if @file && content && content.size>2
				}
			)) 
			stack_paned(800,0.7) {
				flow_paned(900,0.4) do 
				  stack {
						@title=sloti(label("Edit"))
						@edit=source_editor(:lang=> "ruby", :font=> "Courier new 12").editor
						sloti(button("Test...") { execute() })
					}
          stack { 
              @canvas= canvas(400,400,{ 
                :expose     => proc { |w,cr|   redraw(w,cr) }
              }) 
           }           
				end
				notebook do 
					page("Error") { @error_log=slot(text_area(600,100,{:font=>"Courier new 10"})) }
					page("Canvas Help") { make_help(slot(text_area(600,100,{:font=>"Courier new 10"}))) }
				end
			}
		end
	end
  def redraw(w,ctx)
    return if @redraw_error
    $ctx=ctx
    begin
      timeout(10) { @blk.call(w,ctx) if @blk }
    rescue Exception => e
      @redraw_error=true
      trace(e)
    end
  end
	def execute()
		@error_log.text=""
		@content=@edit.buffer.text
    cv=@canvas
    cv.redraw
    @redraw_error=false
	  @blk=proc { |x,ctx| eval(@content,binding() ,"<script>",1) } 
		File.open(@filedef,"w") {|f| f.write(@content)} if @content.size>30
	rescue Exception => e
		trace(e)
	end
  
  
	def log(*e)
		@error_log.text+=e.join("    ")+"\n"
	end
	def trace(e)
		@error_log.text=e.to_s + " : \n   "+ e.backtrace[0..3].join("\n   ")
	end
	def make_api(ta)
		src=File.dirname(__FILE__)+"/../lib/ruiby_gtk/ruiby_dsl.rb"
		content=File.read(src)
		ta.text=content.split(/\r?\n\s*/).grep(/^def[\s\t]+[^_]/).map {|line| (line.split(/\)/)[0]+")").gsub(/\s*def\s/,"")}.sort.join("\n")
	end
	def make_help(ta)
		ta.text=<<EEND

pt([x,y],color,width) 
  draw a point at x,y. color and stroke width optional

line([ [x,y],....],color,width)
  draw a polyline. color and stroke width optional

axes((xy0,maxx,maxy,stepx,stepy)
  draw plotter"s axes
  
plot_yfx(x0,step) { |x| f(x) }
  draw a funtion y=f(x)

plot_xyft(t0,step) { |t| t=Math::PI/(t/700) ; [fx(x),fy(t)] }
  draw a parametric curve 
text(x,y,"Hello")
  draw a text

Examples

0.step(100,10) { |x| pt( rand*x, rand*x ,"#000",4)
line([ [0,0],[100,0],[100,100],[0,1000],[50,50],[0,0]],"#FF0000",4)

axes(20,800,800,20,10)
plot_yfx(10,3) { |x| 20+100+100*Math.sin(Math::PI*x/40)}
  
  
EEND
	end
	def make_example(ta)
		src=File.dirname(__FILE__)+"/test.rb"
		content=File.read(src)
		ta.text=content.split(/(def component)|(end # endcomponent)/)[2]
	end
	def load(file,content)
		if File.exists?(file) && content==nil
			content=File.read(file)
		end
		return unless content!=nil 
		@file=file
		@mtime=File.exists?(file) ? File.mtime(@file) : 0
		@content=content
		@edit.buffer.text=content
	end
  ####################################### Simple drawing  
  
  def line(li,color="#000000",ep=2)
    color=::Gdk::Color.parse(color)
    $ctx.set_line_width(ep)
    $ctx.set_source_rgba(color.red/65000.0, color.green/65000.0, color.blue/65000.0, 1)
    pt0,*poly=*li
    $ctx.move_to(*pt0)
    poly.each {|px| $ctx.line_to(*px) } 
    $ctx.stroke  
  end

  def pt(x,y,color="#000000",ep=2)
    line([[x,y-ep/4],[x,y+ep/4]],color,ep)
  end
  def  axe(min,max,pas,sens)
    x0=20
    x1=15
    l=[]; l << [x0,x0]
    (min+2*x0).step(max,pas) { |v|
    l << [sens==0 ? v:x0, sens==1 ? v: x0 ]
    l << [sens==0 ? v:x1, sens==1 ? v: x1 ]
    l << [sens==0 ? v:x0, sens==1 ? v: x0 ]
    }
    line(l)
  end
  def axes(x0,maxx,maxy,pasx,pasy)
    axe(x0,maxx,pasx,0)
    axe(x0,maxy,pasy,1)
  end
  def plot_yfx(x0,pas,&b)
    l=[]
    x0.step(700,pas) { |x| y= b.call(x) ; l << [20+x,20+y] }
    line(l)
  end
  def plot_xyft(t0,tmax,pas,xy,color="#000000",ep=2,&b)
    l=[]
    t0.step(tmax,pas) { |t| 
      t1= b.call(t)
      l << [xy[0].call(t1)+20,xy[1].call(t1)+20] 
    }
    line(l,color,ep)
    pt(*l.first,"#AAAAFF",4)
    pt(*l.last,"#FFAAAA",4)
  end
  def text(x,y,text)
    $ctx.set_line_width(1)
    $ctx.set_source_rgba(0, 0 ,0, 1)
    $ctx.move_to(x,y)
    $ctx.show_text(text)
  end
end

Ruiby.start_secure { RubyApp.new }


