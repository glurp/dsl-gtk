# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Gtk
=begin
  class Win < Ruiby_gtk
	def component()
	  . . . . . 
	  systray(nil,50) do
		syst_icon  		"icon.png"
		syst_add_button "Reload"				do |state| load(__FILE__) rescue log $! ; end
		syst_add_button "Configuration"			do |state| show_config end
		syst_quit_button true
	  end
  end
=end
class SysTray < StatusIcon 
  def initialize(window,title="title?",config,x0,y0)
	$statusIcon=self
	@popup_tray=Menu.new
	@checkMenu={}
	file= (config[:icon] && File.exist?(config[:icon])) ? config[:icon] : nil
	alert("No icon defined for systray (or unknown file)") if ! file 
	config.each do |label,proc|
		if Proc === proc 
		  case label
		  when  /^\+/
			bshow = CheckMenuItem.new(label[1..-1])
			@checkMenu[bshow]=bshow
			bshow.signal_connect("toggled") { |w|	
			   proc.call(! w.active?) 
			}  
			#TODO : get checkButton state to application closure, set state with closure return value
		  when  /^-+/
			bshow = SeparatorMenuItem.new
		  else
			bshow = MenuItem.new(label)
			bshow.signal_connect("activate") { proc.call(window.visible?) }  
			#TODO : icon in face of button
		  end
		  @popup_tray.append(bshow) 
		end
	end
	if config[:quit]
		@bquit_tray=ImageMenuItem.new(Stock::QUIT)
		@bquit_tray.signal_connect("activate"){window.main_quit}
		#@popup_tray.append(SeparatorMenuItem.new)
		@popup_tray.append(@bquit_tray)
	end
	@popup_tray.show_all
	super()
	
	self.pixbuf= file ?  Gdk::Pixbuf.new(file) :  nil 
	self.tooltip=title
	self.signal_connect('activate'){ 
		if window.visible? 
			$wposition=window.position
			window.hide
		else
			window.move(*$wposition)
			window.show 
		end
	}
	self.signal_connect('popup-menu'){|tray, button, time|
	  @popup_tray.popup(nil, nil, button, time) {|menu, x, y, push_in| [(x0||x),(y0||y)] }
	}
  end
end
end # Gtk


module Ruiby_dsl
	def systray(x=nil,y=nil)
		@title=File.basename($0).gsub(/\.rb/,'') unless defined?(@title)
		@systray_config={}
		yield
		@systray=::Gtk::SysTray.new(self,@title,@systray_config,x,y)
	end
	def syst_icon(file)		         @systray_config[:icon]=file     ; end
	def syst_add_button(label,&prc)  @systray_config[label]=prc     ; end
	def syst_add_sepratator()        @systray_config["--#{@systray_config.size}"]= proc {} ; end
	def syst_add_check(label,&prc)   @systray_config["+"+label]=prc ; end
	def syst_quit_button(yes)       @systray_config[:quit]=yes       ; end
	def systray_setup(config)
		@systray=::Gtk::SysTray.new(self,@title,config)
	end 
	def show_app()
		deiconify	
		show 
	end
	def hide_app
		iconify
		hide
	end

	def close_dialog
		destroy
	end 
end
