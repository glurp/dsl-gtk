#!/usr/bin/ruby
# encoding: utf-8
require_relative 'ruiby'


class RubyApp < Ruiby_gtk
    def initialize
        super("Testing Ruiby editor",900,0)
    end
	def component()
		stack do
			sloti(htoolbar({"open/ouvrir fichier"=>nil,"close/fermer le fichier"=>nil,
				"undo/defaire"=>nil,"redo/refaire"=>proc { alert("e") } }))
			separator
			@edit=slot(source_editor()).editor
			@edit.text=File.read(__FILE__)
			sloti( button("Exit") { exit! })			
		end
	end
end

Gtk.init
    window = RubyApp.new
Gtk.main
