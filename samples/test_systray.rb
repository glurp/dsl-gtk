# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#####################################################################################
#          test_systray.rb : tst systray & style
#####################################################################################
require_relative  '../lib/ruiby' 

HAPPY_ICON   ="media/face_smile_big.png"
Thread.abort_on_exception=true

unless defined?($statusIcon)
$statusIcon=nil
$win=nil 
$p={}
class Application < Ruiby_gtk
	def update()
		clear_append_to(@st) do 
			slot(label "Time is..")
			slot(label Time.now.to_s)
		end
		after(3000) do
			hide
		end
	end
	  def initialize()
		  super("test systray",100,0)
		  default_height=0
		  height=0
		  
		  threader(20)
		  move(100,100)
		  chrome(false)
		  update()
		  systray(nil,850) do
			syst_icon  HAPPY_ICON
		    syst_add_button "Reload"				do |state| load(__FILE__) rescue log $! ; end
			syst_add_button "Execute Test"			do |state|  move(100,100);show; update() end
			syst_quit_button true
		  end
	  end
	  def selection() update()  end
	  def component()
	    # 17 pixel h
	    def_style(<<-EEND)
		  pixmap_path 'media'
		  style "dark" {  bg[NORMAL] = { 0.5, 0.5, 0.5 }  }	
		  style "box"  {  bg_pixmap[NORMAL] = 'fond.png'  }	
		  style "mstyle" { 
		    font_name   = "Arial"
		    fg[NORMAL] = { 0.9, 0.9, 0.9 } 
		  }	
		  class  "*"   style "dark"
		  class  "*Box*"   style "box"
		  class  "*Label*" style "mstyle"
	    EEND
		clickable(:selection) { @st= stack { slot(label("...")) } }
	  end
	end
	Ruiby.start { Application.new }
end # unless defined?
