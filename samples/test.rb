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
 VERSION=%w{3 0 2}
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
      sloti(label( <<-EEND ,:font=>"Tahoma bold 12"))
       This window is test & demo of Ruiby capacity. Ruby is #{RUBY_VERSION}, Ruiby is #{Ruiby::VERSION}, 
       Gtk is  #{Gtk::VERSION.join(".")} HMI code take #{File.read(__FILE__).split("comp"+"onent"+"()")[1].split(/\r?\n/).select {|l| l !~ /\s*#/ && l.strip.size>3}.size} LOC (without blanc lines,comment line,'end' alone)
      EEND
    end
    separator
    flow {
       @left=stack {
        test_table
        test_canvas
      }
      separator
      stack do
        notebook do
          page("","#go-home") { 
             stack(margins: 40){
                image(Ruiby::DIR+"/../media/ruiby.png")
                label("A Notebook Page with icon as button-title",{font: "Arial 18"}) 
				buttoni("Test css defininition...") {
					ici=self
					dialog_async("Edit Css style...",:response => proc {def_style(@css_editor.editor.buffer.text);false}) {
					   @css_editor=source_editor(:width=>300,:height=>200,:lang=> "css", :font=> "Courier new 12")
					   @css_editor.editor.buffer.text="* { background-image:  -gtk-gradient(linear, left top, left bottom, \nfrom(#AAA), to(@888));\nborder-width: 3;}"
					}
				}
             }
          }
          page("List & grids") { test_list_grid }		
          page("Explorer") { test_treeview }
          page("ex&dia") { test_dialog }
          page("Properties") { test_properties(0) }
          page("Source Ed") {
            if ed=source_editor(:width=>200,:height=>300,:lang=> "ruby", :font=> "Courier new 8",:on_change=> proc { edit_change })
              @editor=ed.editor
              @editor.buffer.text='def comp'+'onent'+File.read(__FILE__).split(/comp[o]nent/)[1]
            end
          }
          page("Menu") { test_menu }
          page("Accordion") { test_accordion }
          page("Pan & Scrolled") { test_pan_scroll}
        end # end notebook
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
      end
    } # end flow
    flowi { 
      button("Test dialogs...") { do_special_actions() }
      button("Exit") { ruiby_exit }
    }
    mlog 'after Component'
  end
end

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
  def test_treeview()
  stack do
    tr=tree_grid(%w{month name prename 0age ?male},200,300)
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
  end
  end
  def test_dialog()
  stack do
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
    buttoni("  Crud in memory ") { test_crud() }        
  end
  end
  def test_list_grid()
      flow {
        stack {
          frame("CB on List") {
            stacki{
              @list0=list("callback on selection",100,200) { |li| alert("Selections are : #{li.join(',')}") } 
              @list0.set_data((0..1000).to_a.map(&:to_s))
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
        frame("List with getter") {
          stack {
            @list=list("Demo",0,100)
            flowi {
              button("s.content") { alert("Selected= #{@list.selection()}") }
              button("s.index") { alert("iSelected= #{@list.index()}") }
            }
          }
        }
      }
      10.times { |i| @list.add_item("Hello #{i}") }
      @grid.set_data((1..30).map { |n| ["e#{n}",n,1.0*n]})
  end
  def test_properties(no)  
      flowi {
        sloti(button("#harddisk") { alert("image button!")})
        tt={int: 1,float: 1.0, array: [1,2,3], hash: {a:1, b:2}}
        properties("props editable",tt,{edit: true}) { |a| log(a.inspect);log(tt.inspect) }
        properties("props show",tt)
      }
      h={};70.times { |i| h[i]= "aaa#{i+100}" }
      properties("very big propertys editable",h,{edit: true,scroll: [100,200]}) { |a| log(a.inspect);log(h.inspect) }
  end
  def test_crud()
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
        @f=stacki {  regular ; space ; space ; calendar()  }
      }
  end
  def test_accordion()
      flow {
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

 
  def edit_change()
    alert("please, do not change my code..")
  end

  def do_special_actions()
    100.times { |i| log("#{i} "+ ("*"*(i+1))) }
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
# end component()
end
# test autoload plugins
Exemple.new

Ruiby.start do
    RubyApp.new
end
