#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative '../lib/Ruiby'

Thread.abort_on_exception=true
class RubyApp < Ruiby_gtk
    def initialize() 
		super("Testing Ruiby Table / cell span",300,400) 
		threader(10)
	end	
	def component()        
		stack {
			frame("") { table(2,10,{set_column_spacings: 3}) do
			  row { cell_left label  "c1" ; cell_left label  "c2" ;  cell label  "c3" ;  cell label  "c4" ;}
			  row { cell_right label  "c1" ; cell_left label  "c2" ;  cell label  "c3" ;  cell label  "c4" ;}
			  row { cell_right label  "c1" ; cell_hspan(3,button("hspan 3"))   }
			  row { cell_vspan_top(2,button("vspan 2")) ; cell label  "c2" ;  cell label  "c3" ;  cell label  "c4" ;}
			  row { cell_pass; cell label  "c2" ;  cell_hspan_right(2,pan("hspan 2")) }
			end }
			flow {
				frame("List") {
					stack {
						@list=list("Demo",0,200)
						flow {
							button("s.content") { alert("Selected= #{@list.selection()}") }
							button("s.index") { alert("iSelected= #{@list.index()}") }
						}
					}
				}
				frame("Grid") {
					stack {
						@grid=grid(%w{nom prenom age},100,200)
						flow {
							button("s.content") { alert("Selected= #{@grid.selection()}") }
							button("s.index") { alert("iSelected= #{@grid.index()}") }
						}
					}
				}
			}
			button("Exit") { exit! }
		}
		######### Populate list & grid
		10.times { |i| @list.add_item("Hello #{i}") }
		@grid.set_data([["a",1,1.0],["b",1,111111.0],["c",2222222222,1.0],["c",2222222222,1.0],["c",2222222222,1.0]])
		Thread.new() do 5.times {
			sleep(1)
			gui_invoke { @grid.add_row([Time.now.to_s,Time.now.to_i,Time.now.to_f]) }
		} end
	end 
  def pan(t)
	stack(false) { button(t) ; button("2 lines") } 
  end
 
end

Ruiby.start do
    window = RubyApp.new
end
