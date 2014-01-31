# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
require_relative 'rspec_helper.rb'

describe Ruiby do
 before(:each) do
  @win= make_window
 end
 after(:each) do
  destroy_window(@win)
 end
 it "draw vectors in a canvas" do
    w=nil
    @win.create { stack {   w=canvas(150,250) do
          on_canvas_draw { |w,cr|  
            w.init_ctx
            w.draw_text(10,10  ,"Test Text write 1")
            w.draw_text(10,30  ,"Test Text write 2",2)
            w.draw_text(10,60  ,"Test Text write 3",3,"#000000")
            w.draw_text(10,130 ,"Test Text write 4",5,"#AA0000")
            w.draw_text(10,200 ,"Test Text write 5",7,"#0000AA")
          }
    end    } }
    w.redraw
    @win.sleeping(100,"Verify canvas : text")
    
 end
 it "draw vectors in a canvas" do
    w=nil
    @win.create { stack {   w=canvas(150,250) do
          on_canvas_draw { |w,cr|  
            w.init_ctx
            w.draw_text(10,10,"Test points :")
            w.draw_point(70,10)
            w.draw_point(90,10,"#AA4444",10)
            w.rotation(0,0,0.1) { w.draw_text(70,70,"eeee") }
            l=w.rotate([1,1,2,3,3,3,4,4],10,10,0.1)
            l=w.translate([1,1,2,3,3,3,4,4],70,10)
          }
    end    } }
    w.redraw
    @win.sleeping(100,"Verify canvas : points")
 end
 it "draw vectors in a canvas" do
    w=nil
    @win.create { stack {   w=canvas(150,250) do
          on_canvas_draw { |w,cr|  
            w.init_ctx
            w.draw_text(10,40,"Test rectangles :")
            w.draw_rectangle(70,50,40,10)
            w.draw_rectangle(120,50, 40,10,0,"#FF0000","#00FFFF",2)
          }
    end    } }
    @win.sleeping(100,"Verify canvas : rectangle")
 end
 it "draw vectors in a canvas" do
    pl=nil
    @win.create { 
      pl=plot(400,200,{
        "curve1" => {
          data:[[0,1],[110,1],[20,1],[30,1],[10,1],[22,1],[55,1],[77,1]],
          color: '#FF0000', 
          xminmax:[0,100], 
          yminmax:[0,100], 
          style: :linear
        }
      })
    }
    pl.get_data("curve1").size.should eq(8)
    pl.delete_curve("curve1")
 end
 
 it "draw vectors in a canvasOld" do
    w=nil
    @win.create { stack {   w=canvasOld(150,250,
          :expose => proc { |w,cr|  
             cr.set_source_rgba(0,0,0,1)
             cr.rectangle(0,0,12,33)
          })
    } }
    @win.sleeping(100,"Verify canvas : rectangle")
 end
 it "draw vectors in a canvas" do
    w=nil
    @win.create { stack {   w=canvas(150,250) do
          on_canvas_draw { |w,cr|  
            w.init_ctx
            w.draw_text(10,70,"Test lines :")
            w.draw_line([70,70, 80,90, 90,70])
            w.draw_line(w.translate([70,70, 80,90, 90,70],25,0),"#AA0000",2)
            w.draw_text(10,105,"Test polygons :")
            w.draw_polygon([70,100, 80,110, 90,100, 100,90, 70,110, 70,100])
            w.draw_polygon(w.translate([70,100, 80,110, 90,100, 100,90, 70,110, 70,100],35,0),"#AA0000","#00FFFF",2)
          }
    end    } }
    @win.sleeping(100,"Verify canvas line & polygons")
 end
 it "draw vectors in a canvas" do
    w=nil
    @win.create { stack {   w=canvas(150,250) do
          on_canvas_draw { |w,cr|  
            w.init_ctx
            w.draw_text(10,120,"Test circle :")
            w.draw_circle(70,130,20)
            w.draw_circle(90,150,20,"#AA0000")
            w.draw_circle(60,170,20,"#AA0000","#00FFFF",2)
          }
    end    } }
    @win.sleeping(100,"Verify canvas : circle")
 end
 it "draw vectors in a canvas" do
    w=nil
    @win.create { stack {   w=canvas(150,250) do
          on_canvas_draw { |w,cr|  
            w.init_ctx
            w.draw_text(10,200,"Test raster image :")
            raster_dir = Dir.exists?('samples') ? "samples/media/" : "../samples/media/"
            wp,hp=w.draw_image(70,210,raster_dir+"netprog.png",sx=1,sy=1)
            wp1,hp1=w.draw_image(70,210+hp+10,raster_dir+"netprog.png",sx=1,sy=1)
            w.draw_rectangle(70,210+hp+10,wp1,hp1,0,"#AA0000",nil,2)
            w.draw_image(70,210+hp+10+hp1+10,raster_dir+"netprog.png",2)
          }
    end    } }
    @win.sleeping(100,"Verify canvas : images")
 end
 it "draw vectors in a canvas" do
    w=nil
    @win.create { stack {   w=canvas(150,250) do
          on_canvas_draw { |w,cr|  
            w.init_ctx
            w.draw_text(10,10,"Test points :")
            w.draw_point(70,10)
            w.draw_point(90,10,"#AA4444",10)
            w.draw_text(10,40,"Test rectangles :")
            w.draw_rectangle(70,50,40,10)
            w.draw_rectangle(120,50, 40,10,0,"#FF0000","#00FFFF",2)
            w.draw_text(10,70,"Test lines :")
            w.draw_line([70,70, 80,90, 90,70])
            w.draw_line(w.translate([70,70, 80,90, 90,70],25,0),"#AA0000",2)
            w.draw_text(10,105,"Test polygons :")
            w.draw_polygon([70,100, 80,110, 90,100, 100,90, 70,110, 70,100])
            w.draw_polygon(w.translate([70,100, 80,110, 90,100, 100,90, 70,110, 70,100],35,0),"#AA0000","#00FFFF",2)
            w.draw_text(10,120,"Test circle :")
            w.draw_circle(70,130,20)
            w.draw_circle(90,150,20,"#AA0000")
            w.draw_circle(60,170,20,"#AA0000","#00FFFF",2)
            w.draw_text(10,200,"Test raster image :")
            raster_dir = Dir.exists?('samples') ? "samples/media/" : "../samples/media/"
            wp,hp=w.draw_image(70,210,raster_dir+"netprog.png",sx=1,sy=1)
            wp1,hp1=w.draw_image(70,210+hp+10,raster_dir+"netprog.png",sx=1,sy=1)
            w.draw_rectangle(70,210+hp+10,wp1,hp1,0,"#AA0000",nil,2)
            w.draw_image(70,210+hp+10+hp1+10,raster_dir+"netprog.png",2)
          }
    end    } }
    @win.sleeping(1000,"Verify canvas")
 end
 it "create a canvas with handlers" do
    w=nil
    @win.create { stack {   w=canvas(300,400) do
          on_canvas_draw { |w,cr|  
            w.init_ctx
            w.draw_text(10,100,"Please do some click & drag ",3)
          }
          on_canvas_button_press{ |w,e|   
            puts "button press !"
            [e.x,e.y]
          }
          on_canvas_button_motion { |w,e,o| 
            puts "motion #{e.x} #{e.y}  with memo=#{o.inspect}\n"
            [e.x,e.y]
          }
          on_canvas_button_release  { |w,e,o| 
            puts "button release ! with memo=#{o.inspect}"
          }
    end    } }
    @win.sleeping(2000,"Verify canvas, please click & drag...")
 end
end