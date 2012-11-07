# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

#!/usr/bin/ruby
# encoding: utf-8
require_relative '../lib/ruiby'

Thread.abort_on_exception=true

class RubyAppV < Ruiby_gtk
    def initialize() 
		super("Testing Ruiby accordion",300,400) 
		rposition(90,100)
	end	

	def component()        
		flow {
			accordion {
				aitem("entry 1") {
						alabel("xeee1") { alert("x1") }
						alabel("xeee2") { alert("x2") }
						alabel("xeee3") { alert("x3") }
				}
				aitem("entry 2") {
						alabel "aeee1"
						alabel "aeee2"
						alabel "aeee3"
				}
				aitem("entry 3") {
						alabel "beee1"
						alabel "beee2"
						alabel("beee3") { alert("bee3") }
				}
			}
			stack {
				label "x"
				stacki {haccordion {
				aitem("entry 1") {
						alabel("xeee1") { alert("x1") }
						alabel("xeee2") { alert("x2") }
						alabel("xeee3") { alert("x3") }
				}
				aitem("entry 2") {
						alabel "aeee1"
						alabel "aeee2"
						alabel "aeee3"
				}
				aitem("entry 3") {
						alabel "beee1"
						alabel "beee2"
						alabel("beee3") { alert("bee3") }
				}
			}}
			}				
		}
	end 
end

Ruiby.start do
    window = RubyAppV.new
end
