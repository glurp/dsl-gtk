#!/usr/bin/ruby
# encoding: utf-8
require_relative '../lib/ruiby'

# NOT READY!

class RubyApp < Ruiby_gtk
    def initialize
        super("Testing Ruiby video",300,0)
    end
	def component()
		stack do
			sloti(htoolbar({"open/ouvrir fichier"=>nil,"close/fermer le fichier"=>nil,
				"undo/defaire"=>nil,"redo/refaire"=>proc { alert("e") } }))
			separator
			@video=slot(video("file://h.avi")).video
			sloti( button("Exit") { exit! })			
		end
	end
end

Gtk.init
window = RubyApp.new
Gtk.main
