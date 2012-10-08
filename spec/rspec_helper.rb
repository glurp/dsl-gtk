
$:.unshift File.join(File.dirname(__FILE__),'..','lib')
require 'ruiby'
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
		nb=ms/50
		while nb>0
			Ruiby.update
			sleep(0.050)
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
	Ruiby.update
    Ruiby.destroy_log	
	win.destroy 
	Ruiby.update
end