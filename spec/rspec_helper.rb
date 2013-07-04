# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#
# do a rcov if test is rennung from gem base directory
#
( require 'simplecov' ; SimpleCov.start ) if File.exists?("spec")

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'gtk3'
require 'Ruiby'
require 'timeout'
$here=File.dirname(__FILE__)

class TestRuibyWindows < Ruiby_gtk
	def initialize(t,w,h)
		super(t,w,h)
		threader(10)
	end
	def top() @top end
	def component()
		@top=stack do end
	end
	def sleeping(ms,text=nil)
		log("Sleep #{ms} millisecondes for : " +text) if text && ms>1999
		nb=ms/20
		while nb>0
			Ruiby.update
			sleep(0.02)
			nb-=1
		end
		Ruiby.update
	end
	def create(&blk) 
		self.instance_eval { clear_append_to(top()) { instance_eval(&blk) } } 
	end
end

def make_window
	w=TestRuibyWindows.new("RSpec",300,400)
	Ruiby.update
	w
end
def destroy_window(win,sleep=0)
	win.sleeping(sleep) if sleep>0
	win.sleeping(15)
    Ruiby.destroy_log	
	win.destroy 
	Ruiby.update
end