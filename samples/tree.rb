#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative '../lib/ruiby'

class RubyApp < Ruiby_gtk
    def initialize() 
		super("Testing Ruiby Table / cell span",300,400) 
		threader(10)
	end	
	def component()        
		stack {
			@tg=tree_grid(%w{name 0age prename ok #image})
			buttoni("dailog...") {
				rep=dialog("modal window...") {
					label("eee")  
					list("aa",100,100)
				}
				alert("Response was "+rep.to_s)
			}
			buttoni("dailog async...") {
				dialog_async("modal window...",{response: proc {|a| alert(a);true}}) {
					label("eee") 
					list("aa",100,100)
				}
			}
		}
		@tg.set_data({
			b1: {
				a1: [11,"eee",true,"media/face_crying.png"],
				a2: [33,"Dee",false,"media/draw.png"],
				#a3: [33,"Dee",false,"open"],
			},
		})
	end  
end

Ruiby.start { window = RubyApp.new }
