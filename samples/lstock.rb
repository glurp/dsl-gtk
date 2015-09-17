#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
require 'Ruiby'
Ruiby.app width: 500, height: 400, title: "Gtk Stock icon" do
  stack do
    scrolled(400,500) { 
      li=Gtk::IconTheme.default.icons.sort
      li2=li.partition {|a| a.to_s=~/-symbolic$/} 
      (li2[1]+li2[0]).map { |name|  
      flow { labeli "##{name}" ; entry("  "+name.to_s,20,font: "courier 14") } 
      }
    }
    buttoni("Exit") { exit! }
  end
end