# Ruiby [![Build Status](https://secure.travis-ci.org/raubarede/Ruiby.png?branch=master)](http://travis-ci.org/raubarede/Ruiby) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/raubarede/Ruiby) [![Dependency Status](http://www.versioneye.com/package/Ruiby/badge.png)](http://www.versioneye.com/package/Ruiby)

A DSL for building simple GUI (gtk) ruby application rapidly.
Based on gtk.

If your application become bigger and bigger: 

* use gtk directly by Ruiby extensions: write your gtk code, call it by define a new Ruiby word
* switch to glade/visualruby

Riuby is very cool for application which dynamicly build HMI from  data structure.


Resources
==========
blog: http://raubarede.tumblr.com/post/19640720031/currents-work

Code: http://github.com/raubarede/Ruiby

Gem : https://rubygems.org/gems/Ruiby


Status
======

NEW : 0.83.0 !!  (16-05-2013)
- RSPEC and TRAVIS CI : Passing 70% DSL 
- Treeview (not finished)
- Migration to gtk3 :almost finish
- EventMachine integration (main loop)

TODO
- resolve 100% gtk3 deprecated warning
- finish treeview   tree_grid,
- corrections in ruiby_require
- complete rspec => 99% ?
- Easy Form : variables binding for entry/list/check-radio button...

Installation
============
1) system

Install Ruby 1.9 or 2.0.x

Install GTK2/GTK3 :

*	linux: should be in the box... or install gtk2 and gtksourceview2 (dev version) :

(debian example)
```
> sudo apt-get install build-essential
> sudo apt-get install libgtk2.0-dev 
> sudo apt-get install gtksourceview2.0
> sudo apt-get install  libgtk-3-dev
> sudo apt-get install gtksourceview3
```

*	windows:
> http://downloads.sourceforge.net/project/gtk-win/   
>        ==>> gtk2-runtime-2.24.10-*-ash.exe
> 

2) install Ruiby

```
> gem update --system    # gem 2.0.3
> gem install Ruiby
> ruiby_demo             # check good installation with gtk2 (default)
> ruiby_demo3            # check good installation with gtk3 (experimental)
> ruiby_sketchi          # write and test ruiby code
```

NOTA
We must correct the capitalization of Ruiby...
GTK3 give some instability.


Usage
======
DSL is usable via inherit, include, Ruiby.app block, or one-liner command.

By inherit:

```ruby
class Application < Ruiby_gtk
    def initialize(t,w,h)
        super(t,w,h)
    end	
	def component()        
	  stack do
		...
	  end
	end
	.....your code....
end
Ruiby.start { Win.new("application title",350,10) }

```

By include, calling ruiby_component() :

```ruby
class Win < Gtk::Window
	include Ruiby
    def initialize(t,w,h)
        super()
		add(@vb=VBox.new(false, 2)) 
		....
    end	
	def add_a_ruiby_button() 
		ruiby_component do
			append_to(@vb) do 
				button("Hello Word #{@vb.children.size}") {
					add_a_ruiby_button() 
				}
			end
		end
	end
end
Ruiby.start { Win.new("application title",350,10) }
```

Autonomous DSL, for very little application :

```ruby 
require  'Ruiby'
Ruiby.app do
	stack do
		. . . 
	end
end
```
And, for very very little application ('~' are replaced by guillemet):

```ruby 

> ruiby   button(~Continue ? ~) "{  exit!(0) }"
> ruiby   fields([%w{a b},%w{b c},%w{c d}]) { "|a,b,c|" p [a,b,c] if a; exit!(a ?0:1) }
> ruiby -width 100  -height 300 -title "Please, select a file" \
             l=list(~Files :~);l.set_data Dir.glob(~*~) ;  \
             buttoni(~Selected~) { puts l.selection ; exit!(0) } ;\
			 buttoni(~Annul~) { exit!(1) }

```

Require
=======
Simple usage with gtk2 :

```ruby 
require 'Ruiby'
```
Simple usage with gtk3 : preloag gtk3 before Ruiby :

```ruby 
require 'gtk3'
require 'Ruiby'
```

Usage with Event Machine: preloag event-machine before Ruiby :

```ruby 
require 'em-proxy'
require 'Ruiby'
```

Warning : EM.run is done when starting mainloop, after creation of window(s)
so, if yu need initlization of event-machine callback, do it in componon() in a after(0):

```ruby 
Ruiby.app
  ....
  after(0) { EventMachine::start_server().. { ... } }
end
```

Threading
=========
Ruiby do not confidence qith gtk multi threading, so all Ruiby commands must be done in
main thread context. A Ruiby delegate is provided in Kenel module for supporte multi-threading

A Queue is polled by main-window thread :
* main window poll Queue , messagers are proc to be instance_eval() in the main window context
* everywere, a thread can invoke ```invoke_gui {ruiby code}```. this send to the main queue the proc,
 which will be evaluated asynchroniously 

instance_eval is avoided in ruiby. He is used only for thread invoker : gui_invoke().

```ruby
require_relative '../lib/ruiby'
class App < Ruiby_gtk
    def initialize
        super("Testing Ruiby for Threading",150,0)
		threader(10)
		Thread.new { A.new.run }
    end
	def component()        
	  stack do
		sloti(label("Hello, this is Thread test !"))
		stack { @lab=stacki { } }
	  end
	end # endcomponent
	
end
class A
	def run
 		loop do
		 	sleep(1) # thread...
			there=self 
			gui_invoke { append_to(@lab) { sloti( 
					label( there.aaa )  # ! instance_eval on main window
			)  } }
		end
	end 
	def aaa() Time.now.to_s  end
end

Ruiby.start { App.new }

```


License
=======
LGPL, CC BY-SA

Exemple 
=======
see samples in "./samples" directory

Complete API usage here (screen copy at http://raubarede.tumblr.com/gtk3 ) :
```ruby
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
	   ~ 180 Lines of code,
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
			  row { cell_right label  "speedy"                ; cell(toggle_button("on","off",false) {|w| w.label=w.active?() ? "Off": "On" })  }
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
			calendar()
		when 1
			h={};70.times { |i| h[i]= "aaa#{i+100}" }
			properties("very big propertys editable",h,{edit: true,scroll: [100,400]}) { |a| log(a.inspect);log(h.inspect) }
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
	
```


