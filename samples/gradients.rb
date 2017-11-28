# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative '../lib/Ruiby.rb'

Ruiby.app width: 400, height: 300, title: "Drawing Ruiby/canvas test" do
  pt=[0,0]
  stack do
	  canvas(0,0) do
      on_canvas_draw do |w,ctx|
        w.draw_rectangle(0,0,200-1,100-1,0    ,nil,%w{g tb #F00 #FF0 #00F},2)
        w.draw_rectangle(200,0,200-1,100-1,0  ,nil,%w{g bu #F00 #FF0 #00F},2)
        w.draw_rectangle(0,100,200-1,100-1,0  ,nil,%w{g lr #F00 #FF0 #00F},2)
        w.draw_rectangle(200,100,200,100,0    ,nil,%w{g tlb #F00 #FF0 #00F},2)
        w.draw_rounded_rectangle(0,200,200,100,30      ,nil,%w{g tb #AAA #AAA #AAA #FFF #AAA #AAA #AAA},2)
        w.draw_rounded_rectangle(200,200,200,100,30    ,nil,%w{g trb #FFF #AAA #555},2)
        
        w.draw_rectangle(pt.first-2,pt.last-2,3,3,0,"#000","#000",0) if pt!=[0,0]
      end
      on_canvas_button_press {|w,e| pt=[e.x,e.y] }
	  end
  end
end