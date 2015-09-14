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
      stack do
         menu_bar {
           menu("File Example") {
               menu_button("Open") { alert("o") }
               menu_button("Close") { alert("i") }
            }
        }
        flow_paned(800,0.5) do
          stack_paned(800,0.6) do
            stack_paned(400,0.5) do
              frame { 
                label("Label1 ",:size=> [100,100]) 
              }
              frame { label("Label2 ",:size=> [0,0]) } 
            end
            stack {
              frame { label("Label3 ",:size=> [200,200]) }
            }
          end
          frame { label("second flow", bg: "#FF0000") }
        end
      end
	end
end

RubyApp.new
Gtk.main
