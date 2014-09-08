# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative '../lib/Ruiby'


class RubyApp < Ruiby_gtk
    def initialize() super("Calendar",400,10)  end
    def component()  
		@ed=[]
		@change=false
		stack {
			flow {
				@ed << calendar(Time.now,:changed=> proc {|c| change(0)} ) 
				@ed << calendar(Time.now,:changed=> proc {|c| change(1)} ) 
				@ed << calendar(Time.now,:changed=> proc {|c| change(2)} ) 
			}
			@time=sloti( label(Time.now.to_s,:font=>"Arial 24") )
		}
		change(1)
		anim(100) { @time.text=Time.now.to_s}
    end
	def change(no)
		unless @change
			@change=true
			c=@ed[no]
			dref=Time.new(c.year,c.month+1,c.day)-(30*24*3600)*no
			@ed.each_with_index { |c,i| c.set_time(dref+i*(30*24*3600)) }
			@change=false
		end
	end
end

Gtk.init
window = RubyApp.new
Gtk.main
