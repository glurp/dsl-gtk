#!/usr/bin/ruby
# encoding: utf-8
require_relative '../lib/ruiby'

class Win < Gtk::Window
	include Ruiby
    def initialize(t,w,h)
        super()
		add(@vb=VBox.new(false, 2)) 
		show_all
		add_a_ruiby_button()
    end	
	def add_a_ruiby_button() 
		ruiby_component do
			append_to(@vb) do 
				slot(button("Hello Word #{@vb.children.size}") {
					add_a_ruiby_button() 
				})
			end
		end
	end
end

Message.alert("CouCou")
Gtk.init
Win.new("application title",350,10)
Gtk.main
