#!/usr/bin/ruby
# encoding: utf-8
require_relative '../lib/ruiby'


class RubyApp < Ruiby_gtk
    def initialize() super("Testing Ruiby Table / cell span",300,0) end	
	def component()        
		stack {
			frame("") { table(2,10,{set_column_spacings: 3}) do
			  row { cell_left label  "c1" ; cell_left label  "c2" ;  cell label  "c3" ;  cell label  "c4" ;}
			  row { cell_right label  "c1" ; cell_left label  "c2" ;  cell label  "c3" ;  cell label  "c4" ;}
			  row { cell_right label  "c1" ; cell_hspan(3,button("hspan 3"))   }
			  row { cell_vspan_top(2,button("vspan 2")) ; cell label  "c2" ;  cell label  "c3" ;  cell label  "c4" ;}
			  row { cell_pass; cell label  "c2" ;  cell_hspan_right(2,pan("hspan 2")) }
			end }
			slot( button("Exit") { exit! })
		}
	end 
  def pan(t)
	stack(false) { slot(button(t)) ; slot(button("2 lines")) } 
  end
 
end

Ruiby.start do
    window = RubyApp.new
end
