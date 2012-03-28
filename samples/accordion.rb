#!/usr/bin/ruby
# encoding: utf-8
require_relative '../lib/ruiby'

Thread.abort_on_exception=true

class RubyAppV < Ruiby_gtk
    def initialize() 
		super("Testing Ruiby accordion",300,400) 
		rposition(90,90)
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
			label "x"
		}
	end 
end
class RubyAppH < Ruiby_gtk
    def initialize() 
		super("Testing Ruiby accordion",300,400) 
		rposition(390,100)
	end	

	def component()        
		stack {
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
			label "x"
		}
	end 
end

Ruiby.start do
    window = RubyAppV.new
    window = RubyAppH.new
end
