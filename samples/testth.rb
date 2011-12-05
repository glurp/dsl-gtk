#!/usr/bin/ruby
# encoding: utf-8

require_relative 'ruiby'
require 'open3'

class RubyApp < Ruiby_gtk
    def initialize
        super("Testing Ruiby for Threading",150,0)
		threader(10)
		Thread.new { run1 }
		Thread.new { run2 }
    end
	
	def component()        
	  stack do
		sloti(htoolbar({"open/ourir fichier"=>nil,"close/fermer le fichier"=>nil,
			"undo/defaire"=>nil,"redo/refaire"=>proc { alert("e") },"ee"=>nil }))
		sloti(label( <<-EEND
		 Hello, this is Thread test !         
		EEND
		))
		separator
		flow {
		  stack { @lab=stacki { } }
		  separator
		  stack { @fr=stacki { } }
		}
		sloti( button("Exit") { exit! })
	  end
	end # endcomponent
	
	def run1
		@ss=0
 		loop {
		 	sleep(0.05)
			gtk_invoke_wait { @ss=@lab.children.size }
			if @ss<20
			  gtk_invoke { append_to(@lab) { sloti(label(Time.now.to_f.to_s))  } }
			else
			  gtk_invoke { @lab.children[0..3].each { |w| delete(w) } }
			end
		}
	end 
	def run2
		ii=0
 		loop {
			Open3.popen3("ping 10.177.235.1") { |si,so,se| 
				while str=(so.gets || se.gets)
					if ii>10
						gtk_invoke_wait { @fr.children[0..-3].each { |w| delete(w) } }   
						ii=3
					end
					log str
					gtk_invoke { append_to(@fr) { sloti(label(str.chomp)) } }
					ii+=1
				end
			}
		}
	end
end

Gtk.init
window = RubyApp.new
Gtk.main
