#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

#####################################################################
#  paned.rb :  test paned h/v
#####################################################################
# encoding: utf-8
require_relative '../lib/Ruiby'


class RubyApp < Ruiby_gtk
    def initialize
        super("Testing Ruiby paned",900,800)
    end
	def component()
			flow_paned(800,0.5) do
        stack_paned(800,0.6) do
          stack_paned(400,0.5) do
            frame { label("Label1 ",:size=> [0,0]) }
            frame { label("Label2 ",:size=> [0,0]) } 
          end
          stack {
            frame { label("Label3 ",:size=> [200,200]) }
          }
        end
        frame { label("second flow") }
      end
	end
end

Gtk.init
    window = RubyApp.new
Gtk.main
