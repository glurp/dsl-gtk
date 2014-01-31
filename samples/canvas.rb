#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#####################################################################
#  canvas.rb : edit/test drawing code
#####################################################################
# encoding: utf-8
require 'timeout'
require_relative '../lib/Ruiby'

# Usage
# CanvasBinding.eval_in(cv) {}

module DrawPrimitive end
class CanvasBinding
  include DrawPrimitive
  def self.eval_in(canvas,ctx=nil,blk)
     @dde_animation= 0
     @cv=canvas
     $ctx=ctx if ctx
     (p=new).instance_eval(blk,"<script>",1)
     p.dde_animation
  end
  def dde_animation() @dde_animation end
end

class RubyApp < Ruiby_gtk
    include Math 

    def initialize
      @blk=nil
      @redraw_error=false
      @dde_animation= 0
      super("Canvas",800,900)
      @filedef=Dir.tmpdir+"/canvas_default.rb"
      if  File.exists?(@filedef)
        fload(@filedef,nil)
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
      htoolbar {
        toolbar_button("open","Open file...") {
          fload(ask_file_to_read(".","*.rb"),nil)
        }
        toolbar_button("Save","Save buffer to file...") {
          @file=ask_file_to_write(".","*.rb") unless File.exists?(@file)
          @title.text=@file
          content=@edit.buffer.text
          File.open(@file,"wb") { |f| f.write(content) } if @file && content && content.size>2
        }
      }
      stack_paned(800,0.7) {
        flow_paned(900,0.4) do 
          stack {
            @title=sloti(label("Edit"))
            @edit=source_editor(:lang=> "ruby", :font=> "Courier new 12").editor
            sloti(button("Test...") { execute() })
          }
          stack { 
              @canvas= canvas(400,400) { 
                on_canvas_draw { |w,cr| redraw(w,cr) }
              } 
           }           
        end
        notebook do 
          page("Error") { @error_log=slot(text_area(600,100,{:font=>"Courier new 10"})) }
          page("Canvas Help") { make_help(slot(text_area(600,100,{:font=>"Courier new 10"}))) }
        end
      }
      buttoni("reload canvas.rb...") do 
        begin
          load (__FILE__)
        rescue StandardError => e
          error(e)
        end
      end
    end
  end
  def redraw(w,ctx)
    return if @redraw_error
    return unless  @blk
    begin
        @redraw_error=false
        @error_log.text=""
        begin
         dde_animation=CanvasBinding.eval_in(@cv,ctx,@blk)  
         GLib::Timeout.add([dde_animation,50].max) { @canvas.redraw ; false } if dde_animation && dde_animation>0
        rescue Exception => e
          @redraw_error=true
          error("Error in evaluate script :\n",e)
        end
    rescue Exception => e
      @redraw_error=true
      trace(e)
    end
  end
  def execute()
    content=@edit.buffer.text    
    @blk= content
    File.open(@filedef,"w") {|f| f.write(content)} if content.size>30
    @redraw_error=false
    @canvas.redraw
  rescue Exception => e
    trace(e)
  end
  
  def log(*e)
    @error_log.text+=e.join("    ")+"\n"
  end
  def trace(e)
    @error_log.text=e.to_s + " : \n   "+ e.backtrace[0..3].join("\n   ")
  end
  def make_help(ta)
    ta.text=DrawPrimitive.help_text
  end
  def make_example(ta)
    src=File.dirname(__FILE__)+"/test.rb"
    content=File.read(src)
    ta.text=content.split(/(def component)|(end # endcomponent)/)[2]
  end
  def fload(file,content)
    if File.exists?(file) && content==nil
      content=File.read(file)
    end
    return unless content!=nil 
    @file=file
    @mtime=File.exists?(file) ? File.mtime(@file) : 0
    @content=content
    @edit.buffer.text=content
  end
end

#=====================================================================================
#     Draw Primitives
#=====================================================================================

module DrawPrimitive
  def error(*t) Message.error(*t) end
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
  def fill(li,color="#000000",ep=2)
    color=::Gdk::Color.parse(color)
    $ctx.set_line_width(ep)
    $ctx.set_source_rgba(color.red/65000.0, color.green/65000.0, color.blue/65000.0, 1)
    pt0,*poly=*li
    $ctx.move_to(*pt0)
    poly.each {|px| $ctx.line_to(*px) } 
    $ctx.fill
  end
  def update(ms=20) @canvas.redraw ; sleep(ms*0.001) end
  def tradu(l) l.each_slice(2).to_a end
  def scale(l,sx,sy=nil) l.map {|(x,y)| [x*sx,y*(sy||sx)]}                                        end
  def trans(l,dx,dy) l.map {|(x,y)| [x+dx,y+dy]}                                                  end
  def rotat(l,angle) sa,ca=Math.sin(angle),Math.cos(angle); l.map {|(x,y)| [x*ca-y*sa,x*sa+y*ca]} end
  def crotat(l,x,y,angle) trans(rotat(trans(l,-x,-y),angle),x,y)                                  end
  def cscale(l,x,y,cx,cy=nil) trans(scale(trans(l,-x,-y),cx,cy),x,y)                              end
  def rotation(cx,cy,a,&blk) grotation(cx,cy,a,&blk) end
  def grotation(cx,cy,a,&blk) 
     if a==0
      yield
      return
     end
     $ctx.translate(cx,cy)
     $ctx.rotate(a)
     yield rescue error $!
     $ctx.rotate(-a)
     $ctx.translate(-cx,-cy)
  end
  def gscale(cx,cy,a,&blk) 
     if a==0
      yield
      return
     end
     $ctx.translate(cx,cy)
     $ctx.scale(a,a)
     yield rescue error $!
     $ctx.scale(1.0/a,1.0/a)
     $ctx.translate(-cx,-cy)
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
  def text(x,y,text,scale=1)
    $ctx.set_line_width(1)
    $ctx.set_source_rgba(0, 0 ,0, 1)
    if scale==1
      $ctx.move_to(x,y)
      $ctx.show_text(text)
    else
      gscale(x,y,scale) { $ctx.move_to(0,0); $ctx.show_text(text) }
    end
  end
  def def_animate(ms)
   @dde_animation= ms
  end
  
  def self.help_text()
    h=<<EEND

pt(x,y,color,width) 
  draw a point at x,y. color and stroke width optional

line([ [x,y],....],color,width)
  draw a polyline. color and stroke width optional
fill([ [x,y],....],color,width)
  draw a polygone. color and stroke width optional

tradu(l)          [0,1,2,..] ===> [[0,1],[2,3],...]
scale(l,sx,sy=nil) scale by (sx,sy), form 0,0
trans(l,dx,dy)     transmate by dx, dy
rotat(l,angle)     rotation by angle from 0,0
crotat(l,x,y,angle)  rotation by angle from cener x,y  
cscale(l,x,y,cx,xy=nil)  scake by cx,cy from center c,y
grotation(cx,cy,a) { instr } execute instr in rotated context (for text/image)
gscale(cx,cy,a) { instr } execute instr in scaled context (for text/image)

def_animate( n ) ask to reexecute this script n millisencondes forward
axes((xy0,maxx,maxy,stepx,stepy)
  draw plotter"s axes (to be well done...)
  
plot_yfx(x0,step) { |x| f(x) }
  draw a funtion y=f(x)

plot_xyft(t0,step) { |t| t=Math::PI/(t/700) ; [fx(x),fy(t)] }
  draw a parametric curve 
  
text(x,y,"Hello")
  draw a text
text(x,y,"Hello",coef)
  draw a text scaled by coef

def_animation( ms ) 
  ask to rexecute this script aech ms millisecondes
Examples

0.step(100,10) { |x| pt( rand*x, rand*x ,"#000",4)
line([ [0,0],[100,0],[100,100],[0,1000],[50,50],[0,0]],"#FF0000",4)

axes(20,800,800,20,10)
plot_yfx(10,3) { |x| 20+100+100*Math.sin(Math::PI*x/40)}
  
  
EEND
  end
end

Ruiby.start_secure { RubyApp.new }


