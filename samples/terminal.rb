require_relative '../lib/Ruiby' 
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

Ruiby.app width: 60,height: 40 do
  terminal("ee")
  stack do
    button("load") { 
      load("../lib/ruiby_gtk/ruiby_terminal.rb",false)
    }
  end
end
