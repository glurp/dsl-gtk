#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

$time_start=Time.now.to_f*1000
$mlog=[]
def mlog(text)
 delta=(Time.now.to_f*1000-$time_start).to_i
 $mlog << [delta,text]
 puts "%8d | %s" % [delta,text.to_s]
end

mlog 'require gtk3...'     ; require 'gtk3' 
mlog 'require ruiby....'   ; require_relative '../lib/Ruiby' ; mlog 'require ruiby done.'

module Gtk
 VERSION=%w{3 0 3}
end

class RubyApp < Ruiby_gtk
    def initialize
      mlog "befor init"
          super("Testing Ruiby",600,0)
      mlog 'after init'
      after(1) { mlog("first update") }
    end

def component()   
  (puts "\n\n####define style...####\n\n" ; def_style "* { background-image:  -gtk-gradient(linear, left top, left bottom, from(#AAA), to(@888));border-width: 3;}") if ARGV.size>0 && ARGV[0]=~/css/i
  after(1000) {puts "\n\n\n"  ; Gem.loaded_specs.each {|name,gem| puts "  #{gem.name}-#{gem.version}"} }
  mlog 'before Component'
  stack do
    htoolbar_with_icon_text do
      button_icon_text("document-open","Open...") { edit(__FILE__) }
      button_icon_text("document-save","Save.."){ alert("Save what ?")}
      button_icon_text("sep")
      button_icon_text("edit-undo","Undo") { alert( "undo")} 
      button_icon_text("edit-redo","Redo") { alert("redo") }
    end
    flowi do
    end
    separator
    flow do
       @left=stack {
        test_table
        test_canvas
      }
      separator
      stack do
        test_notebook
        flowi { 
          button("Test dialogs...") { do_special_actions() }
          button("Exit") { ruiby_exit }
        }
      end
    end # end flow
    mlog 'after Component'
  end # end global stack
end # end def Component
  def test_table
    frame("Forms",margins: 10,bg: "#FEE") { table(2,10,{set_column_spacings: 3}) do
        row { cell_right(label  "state")             ; cell(button("set") { alert("?") }) }
        row { cell_right label  "speed"              ; cell(entry("aa"))  }
        row { cell_right label  "size"               ; cell ientry(11,{:min=>0,:max=>100,:by=>1})  }
        row { cell_right label  "feeling"            ; cell islider(10,{:min=>0,:max=>100,:by=>1})  }
        row { cell_right label  "speedy"             ; cell(toggle_button("on","off",false) {|ok| alert ok ? "Off": "On" })  }
        row { cell       label  "acceleration type"  ; cell hradio_buttons(%w{aa bb cc},1)  }
        row { cell      label  "mode on"             ; cell check_button("",false)  }
        row { cell      label  "mode off"            ; cell check_button("",true)  }
        row { cell_left label  "Attribute"           ; cell combo({"aaa"=>1,"bbb"=>2,"ccc"=>3},1) }
        row { cell_left label  "Color"               ; cell box { color_choice() {|c| alert(c.to_s)}  } }
      end 
    }
  end
  def test_canvas()
     flow do
        stack do
          button("Color") {
            @color=ask_color()
          }
          tooltip("Please choose the <b>drawing</b> <i>color</i>...")
          @epaisseur=islider(1,{:min=>1,:max=>30,:by=>1})
          tooltip("Please choose the <b>drawing</b> pen <i>width</i>...")
        end
        @ldraw=[] ; @color= html_color("#FF4422");
        canvas(200,100) do
          on_canvas_draw { |w,cr|  
              @ldraw.each do |line|
                next if line.size<3
                color,ep,pt0,*poly=*line
                cr.set_line_width(ep)
                cr.set_source_rgba(color.red/65000.0, color.green/65000.0, color.blue/65000.0, 1)
                cr.move_to(*pt0)
                poly.each {|px|    cr.line_to(*px) } 
                cr.stroke  
              end
          }
          on_canvas_button_press{ |w,e|   
              pt= [e.x,e.y] ;  @ldraw << [@color,@epaisseur.value,pt] ;  pt
          }
          on_canvas_button_motion { |w,e,o| 
              if  o
                pt= [e.x,e.y] ; (@ldraw.last << pt) if pt[0]!=o[0] || pt[1]!=o[1] ; pt 
              end
          }
          on_canvas_button_release  { |w,e,o| 
              pt= [e.x,e.y] ; (@ldraw.last << pt)
          }
        end
        stacki {
          label("Popup test...")
          popup(canvas(50,200) { }) {
              pp_item("copy")     { alert "copy.." }
              pp_item("cut") 	    { alert "cut..." }
              pp_item("past")	    { alert "pasting.." }
              pp_separator
              pp_item("Save")	    { alert "Saving.." }            
          }
        }
      end 
  end
  ##############################################################
  #                   N o t e b o o k
  ##############################################################
  def test_notebook
        notebook do
          page("","#go-home") {  test_page }
          page("Source") {
            if ed=source_editor(:width=>200,:height=>300,:lang=> "ruby", :font=> "Courier new 8",:on_change=> proc { edit_change })
              @editor=ed.editor
              @editor.buffer.text='def comp'+'onent'+File.read(__FILE__).split(/comp[o]nent/)[1]
            end
          }
          page("Cv") { test_canvas_draw }
          page("Grids") { test_list_grid }		
          page("Divers") { test_dialog }
          page("Prop.") { test_properties(0) }
          page("Menu") { test_menu }
          page("Scrol.") { test_pan_scroll}
        end # end notebook
  end
  def test_page
     stack(margins: 40) {
        image(Ruiby::DIR+"/../media/ruiby.png")
        label("A Notebook Page with icon as button-title",{font: "Arial 18"}) 
        buttoni("Test css defininition...") {
          ici=self
          dialog_async("Edit Css style...",:response => proc {def_style(@css_editor.editor.buffer.text);false}) {
             @css_editor=source_editor(:width=>500,:height=>300,:lang=> "css", :font=> "Courier new 12")
             @css_editor.editor.buffer.text="* { background-image:   \n      -gtk-gradient(linear, left top, left bottom, \n        from(#AAA), to(@888));\n   border-width: 3;\n}"
          }
        }
        buttoni("Test Crud...") { test_crud }
     }
  end
  def test_canvas_draw()
    stack do
      canvas(400,300) do
        on_canvas_draw do |cv,cr|
          cv.draw_pie(
             200,300,70,
             [
               [1,"#F00","P1e"],[2,"#00F","P2"],[3,"#0F0","P3"],
               [1,"#F00","P1"],[2,"#00F","P2"],[3,"#0F0","P3"],
               [4,"#F00","P1"],[5,"#00F","P2"],[6,"#0F0","P3"]
             ],
             true)
          cv.draw_pie(100,70,15,[1,8,3,2])            
          
          cv.draw_image(400,10,"#{Ruiby::DIR}/../samples/media/angel.png")
          cv.scale(400,200,0.5) {
            w=80
            cv.draw_rectangle(w+10,0,w+20,2*w+20,20,"#000","#0E0",1)
            cv.draw_image(0,0,"#{Ruiby::DIR}/../samples/media/angel.png")
            cv.draw_rectangle(0,0,w,2*w,0,"#000",nil,4)
          }
          
          # polyline and polygone...
          cv.draw_line([1,10,100,10,100,10,100,110],"#0A0",1)
          cv.draw_polygon([1,110,100,110,100,110,100,210,1,110],"#0AA","#A00",1)
          
          # horizontal text
          cv.draw_line([200,0,200,120],"#000",1)            
          cv.draw_text(200,70,"Hello !",6,"#000")    
          cv.draw_text(200,90,"Hello, with bg",2,"#000","#EEE")    
          cv.draw_text_left(200,100,"Right aligned",0.8,"#000")    
          cv.draw_text_center(200,130,"centered aligned ✈",2,"#000","#CAA")    
          
          # not horizontal text
          cv.rotation(290,100,1.0/16) { 
            cv.draw_point(0,0,"#066",3)
            cv.draw_text(0,0,"1234567890",1,"#000")     
          }
          
          # gant chart
          x0,y0,x1,y1=600,130,800,130
          vmin,vmax=0,10
          cv.draw_rectangle(x0,y0-5,x1-x0,55,0,"#000","#050",1)
          cv.draw_varbarr(x0,y0,x1,y1            ,vmin,vmax,[[0,0],[2,0]],10)  {|value| "#F00"}
          cv.draw_varbarr(x0,y0+10,x1,y1+10      ,vmin,vmax,[[2,0],[3,0]],10)  {|value| "#0FF"}
          cv.draw_varbarr(x0,y0+20,x1,y1+20      ,vmin,vmax,[[3,0],[4,0]],10)  {|value| "#F0F"}
          cv.draw_varbarr(x0,y0+30,x1,y1+30      ,vmin,vmax,[[5.5,0],[7.5,0]],10) {|value| "#FF0"}
          cv.draw_varbarr(x0,y0+40,x1,y1+40      ,vmin,vmax,[
            [0,2],[1,2],[1,0],[2,0],[3,1],[4,1],[5,2],[6,2],[8,3],[10,3]
          ],10)  {|value| blue='%01X' % (value*5) ; "#A090#{blue}0" }
          
          15.times { |c| 15.times { |l| cv.draw_point(600+c*10,200+l*10,"#000",2)} }
          cv.draw_arc( 500,200,30,0.1,0.3,0,"#F00","#0F0")
          cv.draw_arc2(520,210,30,0.1,0.3,0,"#F0F","#00F")
          4.times { |f|  
            cv.draw_arc2(530,290,20,
              0.1+0.25*f,0.1+0.25*(f+1),
              0,"#F0F","#0AA" ) 
         }
        end            
      end
      pl=plot(200,100,{
            "a"=> { data: aleacurve(2) , color: "#A0A0FF" , maxlendata: 100},
            "b"=> { data: aleacurve(3) , color: "#FFA0A0"}
            },{
            bg: "#383"
            }
      )
    end
  end
  def test_list_grid()
      flow {
        stack {
          frame("CB on List") {
            stacki{
              @list0=list("callback on selection",100,200) { |li| alert("Selections are : #{li.join(',')}") } 
              @list0.set_data((0..100).to_a.map(&:to_s))
              buttoni("set selection no2") { @list0.set_selection(1) }
            }
          }
          frame("Grid") {
            stack { stacki {
              @grid=grid(%w{nom prenom age},100,150)
              flow {
                button("s.content") { alert("Selected= #{@grid.selection()}") }
                button("s.index") { alert("iSelected= #{@grid.index()}") }
              }
            } }
          }
        }
        stack {
            frame("List with getter") {
              @list=list("Demo",0,100)
              flowi {
                button("s.content") { alert("Selected= #{@list.selection()}") }
                button("s.index") { alert("iSelected= #{@list.index()}") }
              }
            }
            frame("TreeView") {
              tr=tree_grid(%w{month name prename 0age ?male},100,200)
              tr.set_data({
                janvier: {
                  s1:["aaa","bbb",22,true],
                  s2:["aaa","bbb",33,false],
                  s3:["aaa","bbb",111,true],
                  s4:["aaa","bbb",0xFFFF,true],
                },
                fevrier: {
                  s1:["aaa","bbb",22,true],
                  s2:["aaa","bbb",33,false],
                },
              })
            }
        }
      }
      10.times { |i| @list.add_item("Hello #{i}") }
      @grid.set_data((1..30).map { |n| ["e#{n}",n,1.0*n]})
  end
  def test_dialog()
  stack do
    stacki {
      frame("Buttons in frame") {
        flow { sloti(button("packed with sloti()") {alert("button packed with sloti()")}) 
          @bref=sloti(button("bb")) ;  button("packed with slot()") ; 
        }
      }
      frame("regular size sub-widget (homogeneous)") {
        flow { 
          regular
          5.times { |i| button("**"*(1+i)) ; tooltip("button <b>#{i+1}</b>") }
        }
      }
    }
    sloti(button_expand("Test button_expand()") {
     flow {  2.times { |c| stack { 5.times { |a| label("#{c}x#{a}",{font: "arial 33"}) } } } }
    })
    buttoni("dailog...") do
      rep=dialog("modal window...") {
        label("eee")  
        list("aa",100,100)
      }
      alert("Response was "+rep.to_s)
    end
    space
    buttoni("dailog async...") do
      dialog_async("modal window...",{response: proc {|a| alert(a);true}}) {
        label("eee") 
        list("aa",100,100)
      }
    end
  end
  end
  def test_properties(no)  
      flowi {
        sloti(button("#weather-severe-alert") { alert("image button!")})
        tt={int: 1,float: 1.0, array: [1,2,3], hash: {a:1, b:2}}
        properties("props editable",tt,{edit: true}) { |a| log(a.inspect);log(tt.inspect) }
        properties("props show",tt)
      }
      h={};70.times { |i| h[i]= "aaa#{i+100}" }
      properties("very big propertys editable",h,{edit: true,scroll: [100,200]}) { |a| log(a.inspect);log(h.inspect) }
  end
  def test_crud()
    stack do
      $gheader=%w{id first-name last-name age}
      $gdata=[%w{regis aubarede 12},%w{siger ederabu 21},%w{baraque aubama 12},%w{ruiby ruby 1}]
      i=-1; $gdata.map! { |l| i+=1; [i]+l }
      a=PopupTable.new("title of dialog",400,200,
        $gheader,
        $gdata,
        {
          "Delete" => proc {|line| 
            $gdata.select! { |l| l[0] !=line[0] || l[1] !=line[1]} 
            a.update($gdata)
          },
          "Duplicate" => proc {|line| 
            nline=line.clone
            nline[0]=$gdata.size
            $gdata << nline
            a.update($gdata)
          },
          "Create" => proc {|line| 
            nline=line.clone.map {|v| ""}
            nline[0]=$gdata.size
            $gdata << nline
            a.update($gdata)
          },
          "Edit" => proc {|line| 
          data={} ;line.zip($gheader) { |v,k| data[k]=v }
          PopupForm.new("Edit #{line[1]}",0,0,data,{				
            "Rename" => proc {|w,cdata|  cdata['first-name']+="+" ; w.set_data(cdata)},
            "button-orrient" => "h"
          }) do |h|
            $gdata.map! { |l| l[0] ==h.values[0] ?  h.values : l} 
            a.update($gdata)
          end
          },
        }
      ) { |data| alert data.map { |k| k.join ', '}.join("\n")  }
    end
  end
  def test_menu
      stack {
        menu_bar {
          menu("File Example") {
            menu_button("Open") { alert("o") }
            menu_button("Close") { alert("i") }
            menu_separator
            menu_checkbutton("Lock...") { |w| 
              w.toggle
              append_to(@f) { button("ee #{}") }
            }
          }
          menu("Edit Example") {
            menu_button("Copy") { alert("a") }
          }
        } 
        frame("Accordeon") {
          accordion do
            ("A".."G").each do |cc| 
              aitem("#{cc} Flip...") do
                  5.times { |i| 
                    alabel("#{cc}e#{i}") { alert("#{cc} x#{i}") }
                  }
              end
            end
          end
          label "x"
        }
        calendar()
      }
  end
  def test_pan_scroll()
      stack do
        sloti(label("Test scrolled zone"))
        stack_paned 300,0.5 do 
          vbox_scrolled(-1,20) { 
            30.times { |i| 
              flow { sloti(button("eeee#{i}"));sloti(button("eeee")) }
            }
          }
          vbox_scrolled(-1,20) { 
            30.times { |i| 
              flow { sloti(button("eeee#{i}"));sloti(button("eeee"));sloti(button("aaa"*100)) }
            }
          }
        end
      end
  end
  def aleacurve(pas=1) 
     l=[[50,0]]
     200.times { l << [[0,300,l.last[0]+rand(-pas..pas)].sort[1],l.last[1]+1] }
     l
  end
 
  def edit_change()
    alert("please, do not change my code..")
  end

  def do_special_actions()
    10.times { |i| log("#{i} "+ ("*"*(i+1))) }
    dialog("Dialog tests") do
      stack do
        labeli "  alert, prompt, file chosser and log  "
        c={width: 200,height: 40,font: "Arial old 12"}
        button("Dialog",c) {
          @std=nil
          @std=dialog_async "test dialog" do
            stack {
              a=text_area(300,200)
              a.text="ddd dd ddd ddd dd\n ddd"*200
              separator
              flowi{ button("ddd") {@std.destroy}; button("aaa") {@std.destroy}}
            }
          end
        }

        button("alert", c)         { alert("alert is ok?") }
        button("ask", c)           { log ask("alert is ok?") }
        button("prompt", c)        { log prompt("test prompt()!\nveuillezz saisir un text de lonqueur \n plus grande que trois") { |reponse| reponse && reponse.size>3 }}
        button("file Exist",c)     { log ask_file_to_read(".","*.rb") }
        button("file new/Exist",c) { log ask_file_to_write(".","*.rb") }
        button("Dir existant",c)   { log ask_dir_to_read(".") }
        button("Dir new/Exist",c)  { log ask_dir_to_write(".") }
        button("dialog...") do
          dialog("title") {
            stack  { 
              fields([["prop1","1"],["prop1","2"],["properties1","3"]]) {|*avalues| alert(avalues.join(", "))}
              separator
            }
          }
        end
        button("dialog async...") do
          dialog_async("title",:response=> proc { ask("ok") }) {
            stack  { 
              label "without validations.."
              fields([["prop1","1"],["prop1","2"],["properties1","3"]]) 
              separator
            }
          }
        end        
        button("Timeline",c)  { do_timeline() }
      end
    end
  end
  def do_timeline()
    dialog("ruiby/gtk startup timestamps") do
      lline=[[10  ,180]]
      ltext=[]
      xmin, xmax= $mlog.first[0], $mlog.last[0]
      a,b,ot = (400.0-20)/(xmax-xmin) , 10.0 , 0
      $mlog.each_with_index {|(time,text),i|
        pos=a*time+b
        h=50+i*15
        lline << [pos,180] ;lline << [pos,h] ;lline << [pos,180]
        ltext << [[pos+5,h],text+ "(#{time-ot} ms)"]
        ot=time
      }
      labeli("Total time : #{xmax} milliseconds")
      canvas(500,200) {
          on_canvas_draw { |w,cr|  
            w.init_ctx("#774433","#FFFFFF",2)
            w.draw_line(lline.flatten)
            ltext.each { |(pos,text)|  w.draw_text(*pos,text) }
          }
      }
    end
  end
 #end component()
end
# test autoload plugins
Exemple.new

Ruiby.start do
    RubyApp.new
end
