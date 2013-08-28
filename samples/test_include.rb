#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative '../lib/Ruiby'

class Win < Gtk::Window
	include Ruiby
    def initialize(t,w,h)
        super()
		add(@vb=VBox.new(false, 2)) 
		show_all
		add_a_ruiby_button()
    signal_connect "destroy" do  Gtk.main_quit ; end
	end
	def add_a_ruiby_button() 
		ruiby_component do
			append_to(@vb) do 
				button("Hello Word #{@vb.children.size}") {
					add_a_ruiby_button() 
				}
				if ARGV.any? { |a| a=~/take-a-snapshot/} 
					after(1000) { snapshot("snapshot_test_include.rb.png") ; exit!(0) }
				end
			end
		end
	end
end


Ruiby.start do	Win.new("application title",350,10) end
