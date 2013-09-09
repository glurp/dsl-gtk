# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#####################################################################################
#          test_systray.rb : tst systray & style
#####################################################################################
require_relative  '../lib/Ruiby' 

HAPPY_ICON   ="media/face_smile_big.png"
Thread.abort_on_exception=true

unless defined?($statusIcon)
$statusIcon=nil
$win=nil 
$p={}
class Application < Ruiby_gtk
  def update()
    clear_append_to(@st) do 
      label "Time is.."
      label Time.now.to_s
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
      chrome(true)
      update()
      # component()
      systray(1000,850) do
        syst_icon  HAPPY_ICON
        syst_add_button "Reload"        do |state| load(__FILE__) rescue log $! ; end
        syst_add_button "Execute Test"  do |state|  move(100,100);show; update() end
        syst_quit_button true
      end # end component()
    end
    def selection() update()  end
    def component()
    clickable(:selection) { @st= stack { slot(label("...")) } }
    end
  end
  Ruiby.start { Application.new }
end # unless defined?
