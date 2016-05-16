#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

#####################################################################
#  icones.rb : Stock icones list
#
#    echo @start /B @rubyw d:/dsl-gtk/samples/icones.rb  > c:/bin/ico.bat
#####################################################################
# encoding: utf-8
require_relative '../lib/Ruiby.rb'

Ruiby.app width: 300, height: 120, title: "Predefined icones (Stock GTK)" do
  def ent(name)    
     flow { 
        spacei ; labeli "#"+name.to_s ; spacei ;
        labeli(name.to_s)  
     } rescue nil
  end
  def do_dialog() 
    l=@licones_name.grep(/#{@e.text}/) 
    if l.size==0
      alert("no found *#{@e.text}*")
      return
    end
    dialog {
      stack {
        scrolled(300,200) do
          l.sort.map { |name|  
            (flow { labeli "#"+name ; entry(name)  } rescue nil) 
          } 
        end
      }
    }
  end
  stack do
    flowi { 
      space(2)
      labeli("\n  This icones can be use with '#' prefixe in label,button... commandes:\n Exemple: label('#close')  \n",font: "Arial bold 12")
      space(2) 
    }
    separator
    @licones_name=[]
    flowi do
      spacei(2); labeli("#famfamfam/find") 
      @st=Time.now.to_s
      @e=entry(ARGV.first||"",40) { |t|  do_dialog if t==@st; @st=t} 
      buttoni("#famfamfam/bullet_go") { do_dialog() }
      (after(10) { do_dialog() } )  if ARGV.size>0 
    end
    limg=Dir.glob("#{Ruiby::MEDIA}/famfamfam/**/*.png").map {|f| f.gsub("#{Ruiby::MEDIA}/","").split(".").first }
    @licones_name = (Gtk::IconTheme.default.icons + limg).sort
    limg= limg.each_slice(limg.size/2).to_a
    scrolled(400,500) do
      flow { 
        stacki { limg[0].each { |name| ent(name) } }
        stacki { limg[1].each { |name| ent(name) } }
        stack {Gtk::IconTheme.default.icons.sort.map { |name|  
          ent(name) if name.to_s !~ /symbolic/
        } } 
      }
    end if false
  end
end