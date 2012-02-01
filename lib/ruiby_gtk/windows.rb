###############################################################################################
#            windows.rb : main ruiby windows  
###############################################################################################

=begin
basic usage :
class Application < Ruiby_gtk
	def component
		stack do
			...
		end
	end
end

Container
---------
 auto-slot mean widget is automaticly pack to its parrent,
 if widget is not auto-sloting : call slot(x) or sloti(w) or cell(w) for pack it
 generaly, containers are auto-sloted 

 flow{ slot(w1) ; slot(w2) }    				# AUTO slot()
 stack { slot(w) ; flow { slot(w) }}			# AUTO slot()
 table(col,row) { 
	row { cell(w) ; cell(w) }
	row { cell(flow(false) { ... } } 
 }  # !AUTO slot()
 notebook { page("ee") { } ; page("aa") { } }	# AUTO slot()
 separator                                      # AUTO slot()
 flow(false)   { ... }                          # not sloted
 stack(false)  { ... }                          # not sloted
 paned { [frame,frame] }

For append a widget to a container : 
 slot(w)		# pack in container, fill+expand
 sloti(w)       # pack no fill/no expand
 cell(w)        # pack in : table { row { cell() } } 
Post-component ressources, threaded protected :
   append_to(w) { }
   clear_append_to { }
   append_to_before(w) { }
   slot_append_before(w) { }
   
Widgets
-------
   button(text/'#'icon,&action) entry(value) ientry(ivalue) fentry(fvalue) islider(ivalue) 
   label(text/'#'icon) combo({name=>value,...},initiale_value)
   toggle_button(l1,l2,state)  check_button(name,state)  hradio_buttons(lname,value) 
   htoolbar({name=> proc {},... })
   color_choice()
   canvas(w,h,{:event => proc {},...})
   source_editor()
   text_area()
   
dialogs
--------
 alert() info() error() prompt() ask_color()
 ask() (boolean)
 ask_file_to_read(dir,filter)
 ask_file_to_write(dir,filter)
 ask_dir()
 
Background
----------
   @a=anim(milliseconds) { instructions }
   delete(@a)
   threader(periode-pooling-queue) # at initialize(), declare multithread engine
   Thread.new {
	 gui_invoke { instructions }	# block will be evaluate (instance_eval on main windows object) 
									#in the main thread
	 gui_invoke_wait { instructions } # block will be evaluate, retrune when it is done
   }
   some basic commands are automaticly gui_invoked if called from non-main-thread
      log() append_to() clear_appand_to() ...
	  

TODO
---
 Root window/Graphics environnement :
		get_root_size
		set_window_chrome(w,bool)  ( )
		systray(icon,{label=>proc {},...})
 grid()
 list() 
 progress_bar() 
 menu()
 variable binding for : entry/ientry/fentry/islider/combo/togle_button/check_button hradio_button
 for all : options={} ==> color/font/pading/halign/valign/fg/bg
 SWT,Qt...

=end
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
				self.gtk_exit
			end
		end
        set_window_position Window::POS_CENTER  # default, can be modified by window_position(x,y)
		@lcur=[self]
		@cur=nil
		begin
			component  
		rescue
			error("COMPONENT() : "+$!.to_s + " :\n     " +  $!.backtrace[0..10].join("\n     "))
			exit!
		end
        show_all
	end
	def gtk_exit
		(self.at_exit() if self.respond_to?(:at_exit) ) rescue puts $!.to_s
		Gtk.main_quit 
	end
	def component
		raise("Abstract: 'def component()' must be overiden in a Ruiby class")
	end
	def window_position(x,y)
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
end

module Ruiby # must be included by a Gtk::Window :notested!
	include ::Ruiby_dsl
	include ::Ruiby_threader
	include ::Ruiby_default_dialog
	def ruiby_component()
		init_threader()
		@lcur=[self]
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

class Ruiby_dialog < Gtk::Window # :notested!
	include ::Ruiby_dsl
	include ::Ruiby_default_dialog
end