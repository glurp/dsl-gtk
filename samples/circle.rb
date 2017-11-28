# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative '../lib/Ruiby.rb'

Ruiby.app width: 400, height:200, title: "Drawing Ruiby/canvas test" do
  pt=[0,0]
  stack do
    @lab=labeli("@")
	  canvas(0,0) do
      on_canvas_draw do |w,ctx|
        w.draw_rectangle(0,0,400,200,0,nil,%w{g tb #AAA #555 - - - - - - - #AAA},2)
        w.draw_rectangle(30,30,70,70,[0,0,20,20],"#F00","#00A",1)
        w.draw_rectangle(60,110,50,50,[10,10,0,0],"#F00","#A0A",1)
        w.draw_rectangle(110,15,50,50,[0,10,10,0],"#F00","#AAA",1)
        w.draw_rectangle(3,3,150,170,20,"#F00",nil,3)
        w.draw_arc(300,100,80, 0.25,0.60,3, nil   ,"#AA0")
        w.draw_arc(320,40, 40, 0.0 ,0.1 ,3, "#0AA")
        
        w.draw_rectangle(pt.first-2,pt.last-2,3,3,0,"#000","#000",0) if pt!=[0,0]
      end
      on_canvas_button_press {|w,e| pt=[e.x,e.y] ; @lab.text=pt.to_s ; pt}
      on_canvas_button_motion {|w,e,o| pt=[e.x,e.y] ; @lab.text=pt.to_s ; pt}
	  end
  end
end