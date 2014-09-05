require_relative '../lib/Ruiby' 
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

Ruiby.app width: 60,height: 40 do
  @t=terminal("ee")
  stack do
    button("ReLoad...",size: [300,100]) { 
      load("../lib/ruiby_gtk/ruiby_terminal.rb",false)
      @t.close rescue nil
      @t=terminal("ee")
    }
    button("exit") { exit! }
  end
end
