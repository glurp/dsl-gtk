#!/usr/bin/ruby
# encoding: utf-8
###########################################################
#   multi_window_threading.rb : 
#             test threading :
#             gui_invoke() and gui_invoke_in_window()
###########################################################
require_relative '../lib/ruiby'

def run(lapp) 
	loop {
		app=lapp[rand(lapp.length)]
		
		gui_invoke_in_window(app) { @wdata.append "CouCou\n" }
		gui_invoke { @wdata.append "CouCou in first window\n" }
		p "appended to #{app.class}"
		sleep 1
	}
end

class RubyApp < Ruiby_gtk
	def component
		stack {
			stacki {
				label  "window #{self.class}"
				button "top" do
					@wdata.append  Time.now.to_s+"\n"
				end
			}
			@wdata= slot(text_area(400,100,:text=>"Hello\n"))
			buttoni("exit") { destroy(self) }
		}
		threader(10)
	end
end
class RubyApp1 < RubyApp ; end
class RubyApp2 < RubyApp ; end
class RubyApp3 < RubyApp ; end

Ruiby.start do
	l=[RubyApp1.new("1",400,100),RubyApp2.new("2",300,100),RubyApp3.new("3",200,100)]
	Ruiby.update
    Thread.new(l) { |lapp| run(lapp)  }
end
