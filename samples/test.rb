﻿#!/usr/bin/ruby
# encoding: utf-8
require_relative '../lib/ruiby'


class RubyApp < Ruiby_gtk
    def initialize
        super("Testing Ruiby",900,0)
    end
def component()        
  stack do
    htoolbar(
		"open/tooltip text on button"=>proc { edit(__FILE__) },
		"close/fermer le fichier"=>nil,
		"undo/defaire"=>nil,
		"redo/refaire"=>proc { alert("e") },"ee"=>nil
	)
    label( <<-EEND ,:font=>"Arial 12")
     This window is test & demo of Ruiby capacity,
	 ~ 120 Line of code,
     (Ruiby version is #{Ruiby::VERSION})
	EEND
	
    
    separator
    flow {
      @left=stack {
        frame("") { table(2,10,{set_column_spacings: 3}) do
          row { cell_right(label  "mode de fontionnement"); cell(button("set") { alert("?") }) }
          row { cell_right label  "vitesse"               ; cell(entry("aa"))  }
          row { cell_right label  "size"                  ; cell ientry(11,{:min=>0,:max=>100,:by=>1})  }
          row { cell_right label  "feeling"               ; cell islider(10,{:min=>0,:max=>100,:by=>1})  }
          row { cell_right label  "speedy"                ; cell(toggle_button("on","off",false) {|w| w.label=w.active?() ? "Off": "On" })  }
          row { cell       label  "acceleration type"     ; cell hradio_buttons(%w{aa bb cc},1)  }
          row { cell      label  "mode on"               ; cell check_button("",false)  }
          row { cell      label  "mode off"              ; cell check_button("",true)  }
          row { cell_left label  "Variable"              ; cell combo({"aaa"=>1,"bbb"=>2,"ccc"=>3},1) }
          row { p 4;cell_left label  "Couleur"               ; cell color_choice()  }
        end }
        frame("Buttons in frame") {
          flow { sloti(button("packed with sloti()") {alert("button packed with sloti()")}) 
		         @bref=sloti(button("bb")) ;  button("packed with slot()") ; 
		  }
        }
        flow do
          stack {
            button("Couleur") {
              #alert("alert !") ; error("error !") ; ask("ask !") ;trace("trace !") ;
              @color=ask_color()
            }
            sloti(label('Epaisseur'))
            @epaisseur=sloti(islider(1,{:min=>1,:max=>30,:by=>1}))
          }
          @ldraw=[] ; @color=  ::Gdk::Color.parse("#33EEFF");
          canvas(100,100,{ 
            :expose     => proc { |w,cr|  
              @ldraw.each do |line|
                next if line.size<3
                color,ep,pt0,*poly=*line
                cr.set_line_width(ep)
                cr.set_source_rgba(color.red/65000.0, color.green/65000.0, color.blue/65000.0, 1)
                cr.move_to(*pt0)
                poly.each {|px|    cr.line_to(*px) } 
                cr.stroke  
            end
            },          
            :mouse_down => proc { |w,e|   no= [e.x,e.y] ;  @ldraw << [@color,@epaisseur.value,no] ;  no    },
            :mouse_move => proc { |w,e,o| no= [e.x,e.y] ; (@ldraw.last << no) if no[0]!=o[0] || no[1]!=o[1] ; no },
            :mouse_up   => proc { |w,e,o| no= [e.x,e.y] ; (@ldraw.last << no) ; no}
            })
        end 
      }
      separator
      notebook do
        page("List & grid") {
			flow {
				frame("List") {
					stack {
						@list=list("Demo",0,100)
						flow {
							button("s.content") { alert("Selected= #{@list.selection()}") }
							button("s.index") { alert("iSelected= #{@list.index()}") }
						}
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
			10.times { |i| @list.add_item("Hello #{i}") }
			@grid.set_data((1..30).map { |n| ["e#{n}",n,1.0*n]})
        }
        page("Calendar","#about") {
          flowi {
			sloti(button("#harddisk") { alert("image button!")})
			sloti(label('#cdrom'))
		  }
		  calendar()
	    }
        page("Edit","#home") {
		  @editor=source_editor(:width=>200,:height=>300,:lang=> "ruby", :font=> "Courier new 6",:on_change=> proc { edit_change }).editor
		  @editor.buffer.text='def comp'+'onent'+File.read(__FILE__).split(/comp[o]nent/)[1]
        }
      end
      frame("") do
		stack {
			sloti(label("Test scrolled zone"))
			separator
			stack_paned 300,0.5 do [
			  vbox_scrolled(-1,100) { 
				100.times { |i| 
				  flow { sloti(button("eeee#{i}"));sloti(button("eeee")) }
				}
			  },
			  vbox_scrolled(100,100) { 
				100.times { |i| 
				  flow { sloti(button("eeee#{i}"));sloti(button("eeee"));sloti(button("aaa"*100)) }
				}
			  }] end
		  }
      end      
    }
    sloti(button("Test Specials Actions...") { p @bref ; do_special_actions() })
    sloti( button("Exit") { exit! })
  end
end # endcomponent
  def edit_change()
	alert("please, do not change my code..")
  end

  def do_special_actions()
    log("Coucou")
    prompt("test prompt()!\nveuillezz saisir un text de lonqueur \n plus grande que trois") { |reponse| reponse && reponse.size>3 }
    log("append before :",slot_append_before( button("new before") ,@bref) )
    log("append after :",slot_append_after(  button("new after"),@bref)   )
    log("file : " , ask_file_to_read(".","*.rb")  )
    log("file : ", ask_file_to_write(".","*.rb") )
    log("dir : " , ask_dir() )
    100.times { |i| log("#{i} "+ ("*"*(i+1))) }
  end
end
# test autoload plugins
Exemple.new

Ruiby.start do
    window = RubyApp.new
end
