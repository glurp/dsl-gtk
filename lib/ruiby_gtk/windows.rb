# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
###############################################################################################
#            windows.rb : main ruiby windows  
###############################################################################################

class Ruiby_gtk < Gtk::Window
	include ::Ruiby_dsl
	include ::Ruiby_threader
 	def initialize(title,w,h)
		super()
		init_threader()
		#threader(10) # must be call by user window, if necessary
        set_title(title)
        set_default_size(w,h)
        signal_connect "destroy" do 
			if @is_main_window
				@is_main_window=false
				Gtk.main_quit
			end
		end
        set_window_position Window::POS_CENTER  # default, can be modified by window_position(x,y)
		@lcur=[self]
		@ltable=[]
		@current_widget=nil
		@cur=nil
		begin
			component  
		rescue
			error("Error COMPONENT() : ",$!)
			exit!
		end
        begin
			show_all 
		rescue
			puts "Error in show_all : illegal state of some widget? "+ $!.to_s
		end
	end
	def on_destroy(&blk) 
        signal_connect("destroy") { blk.call }
	end
	def ruiby_exit()
		(self.at_exit() if self.respond_to?(:at_exit) ) rescue puts $!.to_s
		Gtk.main_quit 
	end
	def component
		raise("Abstract: 'def component()' must be overiden in a Ruiby class")
	end

	# change position of window in the desktop. relative position works only in *nix
	# system.
	def rposition(x,y)
		if x==0 && y==0
			set_window_position Window::POS_CENTER
			return
		elsif 		x>=0 && y>=0
			gravity= Gdk::Window::GRAVITY_NORTH_WEST
		elsif 	x<0 && y>=0
			gravity= Gdk::Window::GRAVITY_NORTH_EAST
		elsif 	x>=0 && y<0
			gravity= Gdk::Window::GRAVITY_SOUTH_WEST
		elsif 	x<0 && y<0
			gravity= Gdk::Window::GRAVITY_SOUTH_EAST
		end
		move(x.abs,y.abs)
	end
	# show or supress the window system decoration
	def chrome(on=false)
		set_decorated(on)
	end
end

# can be included by a gtk windows, for  use ruiby.
# do an include, and then call ruiby_component() with bloc for use ruiby dsl
module Ruiby  
	include ::Ruiby_dsl
	include ::Ruiby_threader
	include ::Ruiby_default_dialog
	
	# ruiby_component() must be call one shot for a window, 
	# it initialise ruiby.
	# then append_to(),append_before()...  can be use fore dsl usage
	def ruiby_component()
		init_threader()
		@lcur=[self]
		@ltable=[]
		@current_widget=nil
		@cur=nil
		begin
			yield
		rescue
			error("ruiby_component block : "+$!.to_s + " :\n     " +  $!.backtrace[0..10].join("\n     "))
			exit!
		end
        show_all
	end
end

class Ruiby_dialog < Gtk::Window 
	include ::Ruiby_dsl
	include ::Ruiby_default_dialog
	def intialize() end
end