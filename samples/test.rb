#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

$time_start=Time.now.to_f*1000
def mlog(text)
 puts "%8f | %s" % [(Time.now.to_f*1000-$time_start).to_i,text.to_s]
end
mlog 'before require gtk2'
require 'gtk2'
mlog 'before require ruiby'
require_relative '../lib/ruiby'
mlog 'after require ruiby'


class RubyApp < Ruiby_gtk
    def initialize
		mlog "befor init"
        super("Testing Ruiby",900,0)
		mlog 'after init'
		after(1) { mlog("first update") }
    end
	
	
def component()        
  mlog 'before Component'
  stack do
    sloti(htoolbar(
		"open/tooltip text on button"=>proc { edit(__FILE__) },
		"close/fermer le fichier"=>nil,
		"undo/defaire"=>nil,
		"redo/refaire"=>proc { alert("e") }
	   ))
    sloti(label( <<-EEND ,:font=>"Arial 12"))
     This window is test & demo of Ruiby capacity,
     Ruiby version is #{Ruiby::VERSION}, Gtk version is #{Gtk::VERSION.join(".")}
	EEND
    separator
    flow {
      @left=stack {
		test_table
		test_canvas
     }
	separator
      notebook do
        page("","#home") { label("A Notebook Page with icon as button-title",{font: "Arial 18"}) }
        page("List & grid") { test_list_grid }
        page("Explorer") { test_treeview }
        page("Property Edit.") { test_properties(0) }
        page("Big PropEditor") { test_properties(1) }
        page("Source Editor") {
		  @editor=source_editor(:width=>200,:height=>300,:lang=> "ruby", :font=> "Courier new 8",:on_change=> proc { edit_change }).editor
		  @editor.buffer.text='def comp'+'onent'+File.read(__FILE__).split(/comp[o]nent/)[1]
        }
		page("Menu") { test_menu }
        page("Accordion") { test_accordion }
		page("Pan & Scrolled") { test_pan_scroll}
	  end # end notebook
    } # end flow
    sloti(button("Test Specials Actions...") { p @bref ; do_special_actions() })
    sloti( button("Exit") { exit! })
	mlog 'after Component'
  end
end

	def test_table	
		frame("") { table(2,10,{set_column_spacings: 3}) do
			  row { cell_right(label  "mode de fontionnement"); cell(button("set") { alert("?") }) }
			  row { cell_right label  "vitesse"               ; cell(entry("aa"))  }
			  row { cell_right label  "size"                  ; cell ientry(11,{:min=>0,:max=>100,:by=>1})  }
			  row { cell_right label  "feeling"               ; cell islider(10,{:min=>0,:max=>100,:by=>1})  }
			  row { cell_right label  "speedy"                ; cell(toggle_button("on","off",false) {|ok| alert ok ? "Off": "On" })  }
			  row { cell       label  "acceleration type"     ; cell hradio_buttons(%w{aa bb cc},1)  }
			  row { cell      label  "mode on"               ; cell check_button("",false)  }
			  row { cell      label  "mode off"              ; cell check_button("",true)  }
			  row { cell_left label  "Variable"              ; cell combo({"aaa"=>1,"bbb"=>2,"ccc"=>3},1) }
			  row { p 4;cell_left label  "Couleur"               ; cell color_choice()  }
			end 
		}
        frame("Buttons in frame") {
          flow { sloti(button("packed with sloti()") {alert("button packed with sloti()")}) 
		         @bref=sloti(button("bb")) ;  button("packed with slot()") ; 
		  }
        }
	end
	def test_canvas()
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
			  cv=canvas(100,100,{ 
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
				popup {
					pp_item("copy") 	{ alert 1 }
					pp_item("cut") 		{ alert 2 }
					pp_item("past")		{ alert 3 }
					pp_item("duplicate"){ alert 4 }
				}

			end 
	 end
	 def test_treeview()
		stack do
			tr=tree_grid(%w{month name prename 0age ?male})
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
	 def test_list_grid()
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
	end
	def test_properties(no)  
		case no 
	     when 0
			flowi {
				sloti(button("#harddisk") { alert("image button!")})
				tt={int: 1,float: 1.0, array: [1,2,3], hash: {a:1, b:2}}
				properties("props editable",tt,{edit: true}) { |a| log(a.inspect);log(tt.inspect) }
				properties("props show",tt)
		    }
			flow {
				fn=File.join(Ruiby::DIR,"../samples/media/face_smile_big.png")
				w=label( "#"+fn ) 
				properties("pixbuf",get_config(w.pixbuf))  
				properties("widget",get_config(w),{:scroll => [300,100]})			
			}
			calendar()
		when 1
			h={};70.times { |i| h[i]= "aaa#{i+100}" }
			properties("very big propertys editable",h,{edit: true,scroll: [100,400]}) { |a| log(a.inspect);log(h.inspect) }
			button("dialog grid & form") {
				test_crud()
			}
		end
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
				@f=stacki { }				
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
			stack {
				sloti(label("Test scrolled zone"))
				separator
				stack_paned 300,0.5 do [
				  vbox_scrolled(-1,100) { 
					30.times { |i| 
					  flow { sloti(button("eeee#{i}"));sloti(button("eeee")) }
					}
				  },
				  vbox_scrolled(100,100) { 
					30.times { |i| 
					  flow { sloti(button("eeee#{i}"));sloti(button("eeee"));sloti(button("aaa"*100)) }
					}
				  }] end
			  }
	end
	
# endcomponent
 
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
