#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

#####################################################################
#  panned.rb : IDE ruiby :) test paned h/v
#####################################################################
# encoding: utf-8
require_relative '../lib/Ruiby'


class RubyApp < Ruiby_gtk
    def initialize
        super("Testing Ruiby paned & threading",900,0)
		load(__FILE__)
    end
	def component()
		stack do
			sloti(htoolbar(
				"open/ouvrir fichier"=> proc {load(ask_file_to_read(".","*.rb"))},
				"Save/sauvegarder le fichier"=> proc {content=@edit.buffer.text
					File.open(@file,"wb") { |f| f.write(content) } if @file && content && content.size>2
				}
			)) 
			stack_paned(600,0.7) {
				[stack_paned(900,0.2) do 
					[stack {
						sloti(label("Project"))
						separator
						vbox_scrolled(100,500) { 22.times  { |i| slot(button("eee #{i}")) } }
					},
					stack {
						sloti(label("Edit"))
						@edit=slot(source_editor(:lang=> "ruby", :font=> "Courier new 12")).editor
					}]
				end,
				notebook do 
					page("Task") { frame() { slot(button("ee")) } }
					page("Error") { frame() { slot(button("fffffffffffffffffffffff")) } }
					page("Console") { frame() { slot(button("fffffffffffffffffffffff")) } }
				end
				]
			}
		end
	end
	def change(*t)
		puts "changer #{t.inspect}"
	end    
	def load(file)
		return unless file
		return unless File.exists?(file)
		@file=file
		@mtime=File.mtime(@file)
		@edit.buffer.text=File.read(@file)
	end
end

Gtk.init
    window = RubyApp.new
Gtk.main
