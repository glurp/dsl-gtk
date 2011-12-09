###############################################################################################
#            ruiby.rb :   not a dsl for Ruby/Gui
#                         Gtk based. Future : Java/swt or Qt (?)
###############################################################################################
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

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
( auto-slot mean widget is automaticly pack to its parrent)

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
 containers are automaticly sloted to there parent
 threaded protexted :
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
	  
Root window/Graphics environnement
--------------------------------
td   window_position(x,y)
td   get_root_size
td   set_window_chrome(w,bool)  ( )
td   systray(icon,{label=>proc {},...})

TODO
---
 grid()
 list() 
 progress_bar() 
 menu()
 
 variable binding for : entry/ientry/fentry/islider/combo/togle_button/check_button hradio_button
 
 for all : options={} ==> color/font/pading/halign/valign/fg/bg


=end
###############################################################################################
require 'gtk2'

class Ruiby_gtk < Gtk::Window
	include Gtk
 	def initialize(title,w,h)
		super()
		unless defined?($__mainthread__)
			$__mainthread__= Thread.current
			$__mainwindow__=self
			@is_main_window=true
		else
			@is_main_window=false
		end
        set_title(title)
        set_default_size(w,h)
        signal_connect "destroy" do 
			if @is_main_window
				self.gtk_exit
			end
		end
        set_window_position Window::POS_CENTER  # default
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
		(self.at_exit() if self.respond_to?(:at_exit) ) rescue puts $!
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
	############################ Slot : H/V Box or Frame
	def vbox_scrolled(width,height,&b)
		sw=slot(ScrolledWindow.new())
		sw.set_width_request(width)		if width>0 
		sw.set_height_request(height)	if height>0
		sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
		ret=stack(false,&b)
		sw.add_with_viewport(ret)
		ret
	end	
	def stack(add1=true,&b)    		cbox(true,VBox.new(false, 2),add1,&b) end
	def flow(add1=true,&b)	   		cbox(true,HBox.new(false, 2),add1,&b) end
	def frame(t="",add1=true,&b)  	cbox(true,Frame.new(t),add1,&b)       end
	def stacki(add1=true,&b)    	cbox(false,VBox.new(false, 2),add1,&b) end
	def flowi(add1=true,&b)	   		cbox(false,HBox.new(false, 2),add1,&b) end
	def framei(t="",add1=true,&b)  	cbox(false,Frame.new(t),add1,&b)       end
	
	def cbox(expand,box,add1)
		if add1
			expand ? @lcur.last.add(box) : @lcur.last.pack_start(box,false,false,3)
		end
		@lcur << box
		yield
		@lcur.pop
	end
	def slot(w) @lcur.last.add(w) ; w end
	def sloti(w) @lcur.last.pack_start(w,false,false,3) ; w end
	
	def append_to(cont,&blk) 
		if $__mainthread__ != Thread.current
			gui_invoke { append_to(cont,&blk) }
			return
		end
		@lcur << cont
		yield rescue puts "#{$!} :\n#{$!.backtrace.join("\n  ")}"
		@lcur.pop
		show_all_children(cont)
	end
	def clear_append_to(cont,&blk) 
		if $__mainthread__ != Thread.current
			gui_invoke { clear_append_to(cont,&blk) }
			return
		end
		cont.children.each { |w| cont.remove(w) } 
		@lcur << cont
		yield rescue puts "#{$!} :\n#{$!.backtrace.join("\n  ")}"
		@lcur.pop
		show_all_children(cont)
	end
	def show_all_children(c)
		return unless c
		c.each { |f|   show_all_children(f) if  f.respond_to?(:children) ; f.show() } ; c.show
	end
 	def slot_append_before(w,wref)
		if $__mainthread__ != Thread.current
			gui_invoke { slot_append_before(w,wref) }
			return
		end
 		parent=check_append("slot_append_before",w,wref)
 		parent.add(w)
 		parent.children.each_with_index { |child,i| 
	 		next if child!=wref
 			parent.reorder_child(w,i)
 			break
 		}
 		w
 	end
 	def slot_append_after(w,wref)
		if $__mainthread__ != Thread.current
			gui_invoke { slot_append_after(w,wref) }
			return
		end
 		parent=check_append("slot_append_after",w,wref)
 		parent.add(w)
 		parent.children.each_with_index { |child,i| 
	 		next if child!=wref
 			parent.reorder_child(w,i+1)
 			break
 		}
 		w
 	end
	# delete a widget or a timer
	def delete(w)
		if $__mainthread__ != Thread.current
			gui_invoke { delete(w) }
			return
		end
		if  GLib::Timeout === w
			w.destroy
		else
			w.parent.remove(w) rescue nil
		end
	end
 	def check_append(name,w,wref)
 		raise ("#{name}(w,r) : Widget ref not created!") unless wref
 		raise ("#{name}(w,r) : new Widget not created!") unless w
 		parent=wref.parent
 		raise("#{name}(w,r): r=#{parent.inspect} is not a XBox or Frame !") unless !parent || parent.kind_of?(Container)
 		raise("#{name}(w,r): r=#{parent.inspect} is not a XBox or Frame !") unless parent.respond_to?(:reorder_child)
 		parent
 	end

	def get_current_container() @lcur.last end

	########################### widgets #############################
	def get_icon(name)
		iname=eval("Stock::"+name.upcase) rescue nil
	end

	############### Commands
	def attribs(w,options)
		  w.modify_font(Pango::FontDescription.new(options[:font])) if options[:font]
		  w
	end
	def separator(width=1.0)  sloti(HBox === @lcur.last ? VSeparator.new : HSeparator.new)  end
	def label(text,options={})
		l=if text && text[0,1]=="#"
			Image.new(get_icon(text[1..-1]),IconSize::BUTTON);
		else
			Label.new(text);
		end
		attribs(l,options)
		l
	end
	def button(text,option={},&blk)
		if text && text[0,1]=="#"
			b=Button.new()
			b.set_image(Image.new(get_icon(text[1..-1]),IconSize::BUTTON))
		else
			b=Button.new(text);
		end
		b.signal_connect("clicked",&blk) if blk
		attribs(b,option)
		b
	end 
	def htoolbar(items,options={})
		b=Toolbar.new
		b.set_toolbar_style(Toolbar::Style::ICONS)
		i=0
		items.each {|name_tooltip,v| 
			name,tooltip=name_tooltip,nil
			if ((ar=name_tooltip.split('/')).size>1)
				name,tooltip=*ar
				tooltip="  #{tooltip.capitalize}  "
			end
			iname=get_icon(name)
			w=if iname
				Gtk::ToolButton.new(iname).tap { |b|
				  b.signal_connect("clicked") { v.call } if v
			 	  b.set_tooltip_text(tooltip) if tooltip
			 	}
			elsif name=~/^sep/i
				Gtk::SeparatorToolItem.new
			else
				puts "=======================\nUnknown icone : #{name}\n====================="
	   			puts "Icones dispo: "+Stock.constants.map { |i| i.downcase }.join(", ")
				Gtk::ToolButton.new(Stock::MISSING_IMAGE)
			end
			b.insert(i,w)
			i+=1
	   }
	   b
	end 

	############### Inputs widgets

	def combo(choices,default=-1,option={})
		w=ComboBox.new()
		choices.each do |text,indice|  
			w.append_text(text) 
		end
		w.set_active(default) if default>=0
		attribs(w,option)		
		w
	end

	def toggle_button(text1,text2=nil,value=false,option={})
		text2 = "- "+text1 unless text2
		b=ToggleButton.new(text1);
		b.signal_connect("toggled") do |w,e| 
			w.label= w.active?() ? text2.to_s : text1.to_s 
		end
		b.set_active(value)
		b.label= value ? text2.to_s : text1.to_s 
		attribs(b,option)		
		b
	end
	def check_button(text="",value=false,option={})
		b=CheckButton.new(text)
        	.set_active(value)
		attribs(b,option)
		b
	end
	def hradio_buttons(ltext=["empty!"],value=-1)
		flow(false) {
			b0=nil
			ltext.each_with_index {|t,i|
			  b=if i==0
		      	b0=slot(RadioButton.new(t))
		      else
		      	slot(RadioButton.new(b0,t))
		      end
		      if i==value
				b.toggled 
				b.set_active(true) 
			  end
			}
		}
	end
	def entry(value,size=10,option={})
		w=Entry.new().tap {|e| e.set_text(value ? value.to_s : "") }
		attribs(w,option)		
		w
	end
	def ientry(value,option={})
		w=SpinButton.new(option[:min].to_i,option[:max].to_i,option[:by])
			.set_numeric(true)
			.set_value(value ? value.to_i : 0) 
		attribs(w,option)		
		w
	end
	def fentry(value,option={})
		w=SpinButton.new(option[:min].to_f,option[:max].to_f,option[:by].to_f)
			.set_numeric(true)
			.set_value(value ? value.to_f : 0.0)
		attribs(w,option)		
		w
	end
	def islider(value,option={})
		w=HScale.new(option[:min].to_i,option[:max].to_i,option[:by])
			.set_value(value ? value.to_i : 0)
		attribs(w,option)		
		w
	end
	def color_choice(color=0xff000000)
		b,d=nil,nil
		hb=flow(false) { b = slot(button("Color?...")) ; d=slot(DrawingArea.new) }					
		#b.modify_bg(Gtk::STATE_NORMAL,color)
		b.signal_connect("clicked") {
		  c=ask_color
		  if c
			d.modify_bg(Gtk::STATE_NORMAL,c)
			b.modify_bg(Gtk::STATE_NORMAL,c)
		  end
		}
		hb
	end
	def canvas(width,height,option={})
		w=DrawingArea.new()
		w.set_size_request(width,height)
		w.events |= ( ::Gdk::Event::BUTTON_PRESS_MASK | ::Gdk::Event::POINTER_MOTION_MASK | ::Gdk::Event::BUTTON_RELEASE_MASK)
		w.signal_connect('expose_event') { |w1,e| 
			cr = w1.window.create_cairo_context
			cr.save {
				cr.set_line_join(Cairo::LINE_JOIN_ROUND)
				cr.set_line_cap(Cairo::LINE_CAP_ROUND)
	        	cr.set_line_width(2)
	        	cr.set_source_rgba(1,1,1,1)
	        	cr.paint
				option[:expose].call(w1,cr) if option[:expose]
			}
		}  
		@do=nil
		w.signal_connect('button_press_event')   { |w,e| @do = option[:mouse_down].call(w,e)                ; force_update(w) }  if option[:mouse_down]
		w.signal_connect('button_release_event') { |w,e| option[:mouse_up].call(w,e,@do)   if @do ; @do=nil ; force_update(w) if @do }  if option[:mouse_up]
		w.signal_connect('motion_notify_event')  { |w,e| @do = option[:mouse_move].call(w,e,@do) if @do     ; force_update(w) if @do }  if option[:mouse_move]
		w.signal_connect('key_press_event')  { |w,e| option[:key_press].call(w,e) ; force_update(w) }  if option[:key_press]
		attribs(w,option)				
		w
	end
	def force_update(canvas) canvas.queue_draw unless  canvas.destroyed?  end

	############################ table
	def row()
		@col=0
		yield
		@row+=1
	end	
	def  cell(w) @lcur.last.attach(w,@col,@col+1,@row,@row+1) ; @col+=1 end
	def cell_span(n=2,w)
		@lcur.last.attach(w,@col,@col+n,@row,@row+1)
		@col+=n
	end
	def table(nb_col,nb_row,config={})
		table = Gtk::Table.new(nb_row,nb_col,false)
		table.set_column_spacings(config[:set_column_spacings]) if config[:set_column_spacings]
		slot(table)
		@lcur << table
		@row=0
		@col=0
		yield
		@lcur.pop
	end

	###################################### notebooks
	def notebook() 
		nb = Notebook.new()
		slot(nb)
		@lcur << nb
		yield
		@lcur.pop
	end
	def page(title,icon=nil)
		if icon && icon[0,1]=="#" 
			l = Image.new(get_icon(icon[1..-1]),IconSize::BUTTON); #flow(false) { label(icon) ; label(title) }
		else
		  l=Label.new(title)
		end 
		@lcur.last.append_page( stack(false)  { yield }, l )
	end
	############################## Panned : 
	def paned(vertical,size,fragment)
		paned = vertical ? HPaned.new : VPaned.new
		slot(paned)
		@lcur << paned
		frame1,frame2=*yield()
		@lcur.pop
		(frame1.shadow_type = Gtk::SHADOW_IN) rescue nil
		(frame2.shadow_type = Gtk::SHADOW_IN) rescue nil
		paned.position=size*fragment
		vertical ? paned.set_size_request(size, -1) : paned.set_size_request(-1,size)
		paned.pack1(frame1, true, false)
		paned.pack2(frame2, false, false)
		show_all_children(paned)
	end
	##################### source editor
	# from: green shoes plugin
	# options= :width  :height :on_change :lang :font
	# @edit=slot(source_editor()).editor
	# @edit.buffer.text=File.read(@filename)

    def source_editor(args={}) # from green_shoes plugin
      require 'gtksourceview2'

      args[:width]  = 400 unless args[:width]
      args[:height] = 300 unless args[:height]
  	  change_proc = proc { }
      (change_proc = args[:on_change]; args.delete :on_change) if args[:on_change]
      sv = ::Gtk::SourceView.new
      sv.show_line_numbers = true
      sv.insert_spaces_instead_of_tabs = false
      sv.smart_home_end = Gtk::SourceView::SMART_HOME_END_ALWAYS
      sv.tab_width = 4
      sv.buffer.text = (args[:text]||"").to_s
      sv.buffer.language = Gtk::SourceLanguageManager.new.get_language(args[:lang]||'ruby')
      sv.buffer.highlight_syntax = true
      sv.modify_font(  Pango::FontDescription.new(args[:font] || "Courier new 10")) 

      cb = ScrolledWindow.new
	  cb.define_singleton_method(:editor) { sv }

      cb.set_size_request(args[:width], args[:height])
      cb.set_policy(POLICY_AUTOMATIC, POLICY_AUTOMATIC)
      cb.set_shadow_type(SHADOW_IN)
      cb.add(sv)
      cb.show_all
	  cb
    end
	
	# @edit=slot(text_area(300,100)).text_area
	# @edit.buffer.text="Hello!"
	def text_area(w=200,h=100,args={}) # from green_shoes app
		  tv = Gtk::TextView.new
		  tv.wrap_mode = TextTag::WRAP_WORD
		  tv.buffer.text = args[:text].to_s if args[:text]
		  tv.modify_font(Pango::FontDescription.new(args[:font])) if args[:font]
		  tv.accepts_tab = true

		  eb = Gtk::ScrolledWindow.new
		  eb.set_size_request(w,h) 
		  eb.add(tv)
		  eb.define_singleton_method(:text_area) { tv }

		  eb.show_all
		  eb
    end	

	############################# calendar
	
	# calendar(Time.now-24*3600, :selection => proc {|c| } , :changed => proc {|c| }
	def calendar(time=Time.now,options={})
		c = Calendar.new
		c.display_options(Calendar::SHOW_HEADING | Calendar::SHOW_DAY_NAMES |  
						Calendar::SHOW_WEEK_NUMBERS | Gtk::Calendar::WEEK_START_MONDAY)
		after(1) { c.signal_connect("day-selected") { |w,e| options[:selection].call(w.day) } } if options[:selection]
		after(1) { c.signal_connect("month-changed") { |w,e| options[:changed].call(w) } }if options[:changed]
		calendar_set_time(c,time)
		c
	end
	def calendar_set_time(cal,time=Time.now)
		cal.select_month(time.month,time.year)
		cal.select_day(time.day)
	end
	
	############################# Video
	# from: green shoes plugin
	# not ready!
	
	def video(uri,w=300,h=200)
		wid=DrawingArea.new()
		wid.set_size_request(w,h)
		uri = File.join('file://', uri.gsub("\\", '/').sub(':', '')) unless uri =~ /^(\w\w+):\/\//
		require('gst')
		require('win32api') rescue nil
		v = Gst::ElementFactory.make('playbin2')
		v.video_sink = Gst::ElementFactory.make('dshowvideosink')
		v.uri = uri
		args[:real], args[:app] = v, self
        handle = wid.window.class.method_defined?(:xid) ? @app.win.window.xid : 
          Win32API.new('user32', 'GetForegroundWindow', [], 'N').call
        v.video_sink.xwindow_id = handle
		
		wid.events |= ( ::Gdk::Event::BUTTON_PRESS_MASK | ::Gdk::Event::POINTER_MOTION_MASK | ::Gdk::Event::BUTTON_RELEASE_MASK)
		wid.signal_connect('expose_event') do |w1,e| 		
		end
		def wid.video() v end
		wid.video.play
     end
	 
	###################################### Logs

	def log(*txt)
		if $__mainthread__ != Thread.current
			gui_invoke { log(*txt) }
			return
		end
		loglabel=create_log_window()
		loglabel.buffer.text +=  Time.now.to_s+" | " + (txt.join(" "))+"\n" 
		p loglabel.buffer.text.size
		if ( loglabel.buffer.text.size>10000)
		  loglabel.buffer.text=loglabel.buffer.text[-7000..-1].gsub(/^.*\n/m,"......\n\n")
		end
    end
	def create_log_window() 
		return(@loglabel) if defined?(@loglabel) && @loglabel && ! @loglabel.destroyed?
		wdlog = Dialog.new("Logs : #{title}",
			nil,
			0,
			[ Stock::OK, Dialog::RESPONSE_NONE ])

		logBuffer = TextBuffer.new
		@loglabel=TextView.new(logBuffer)
		sw=ScrolledWindow.new()
		sw.set_width_request(800)	
		sw.set_height_request(200)	
		sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
		
		sw.add_with_viewport(@loglabel)
		
		wdlog.vbox.add(sw)
		wdlog.signal_connect('response') { wdlog.destroy }
		wdlog.show_all	
		@loglabel
	end

	###################################### Alerts

	def alert(*txt) message(MessageDialog::INFO,*txt) end
	def error(*txt) message(MessageDialog::ERROR,*txt) end
	def prompt(txt,value="") 
		 dialog = Dialog.new("Message",
			self,
			Dialog::DESTROY_WITH_PARENT,
			[ Stock::OK, Dialog::RESPONSE_NONE ])

		label=label(txt)
		entry=entry(value.to_s)
		dialog.vbox.add(label)
		dialog.vbox.add(entry)

		dialog.signal_connect('response') do |w,e|
			rep=true
			rep=yield(entry.text) if block_given?
			dialog.destroy if rep
		end
		dialog.show_all	
	end


	def ask(*txt) 
		text=txt.join(" ")
        md = MessageDialog.new(self,
            Dialog::DESTROY_WITH_PARENT,  Gtk::MessageDialog::QUESTION, 
            MessageDialog::BUTTONS_YES_NO, text)
		rep=md.run
		md.destroy
		return( rep==-8 )
	end
	def trace(*txt) message(MessageDialog::WARNING,*txt) end

	def message(style,*txt)
		text=txt.join(" ")
        md = MessageDialog.new(self,
            Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::QUESTION, 
            MessageDialog::BUTTONS_CLOSE, text)
        md.run
        md.destroy
    end
	def ask_color
		cdia = ColorSelectionDialog.new("Select color")
		response=cdia.run
		color=nil
        if response == Gtk::Dialog::RESPONSE_OK
            colorsel = cdia.colorsel
            color = colorsel.current_color
        end 		
		cdia.destroy
		color
	end

	########## File Edit
	def edit(filename)
		if File.exists?("/usr/bin/gedit")
			Thread.new { system("gedit",filename) }
		else
			Editor.new(self,filename)
			#Thread.new { system("write.exe",filename) }
		end
	end
	########## File dialog <<== Green Shoes!

	def ask_file_to_read(dir,filter)
		dialog_chooser("Open File (#{filter}) ...", Gtk::FileChooser::ACTION_OPEN, Gtk::Stock::OPEN)
	end
	def ask_file_to_write(dir,filter)
	 dialog_chooser("Save File (#{filter}) ...", Gtk::FileChooser::ACTION_SAVE, Gtk::Stock::SAVE)
	end
	def ask_dir()
		dialog_chooser("Save Folder...", Gtk::FileChooser::ACTION_CREATE_FOLDER, Gtk::Stock::SAVE)
	end
	def dialog_chooser(title, action, button)
	    dialog = Gtk::FileChooserDialog.new(
	      title,
	      self,
	      action,
	      nil,
	      [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
	      [button, Gtk::Dialog::RESPONSE_ACCEPT]
	    )
	    ret = ( dialog.run == Gtk::Dialog::RESPONSE_ACCEPT ? dialog.filename : nil rescue false)
	    dialog.destroy
	    ret
	end
	
	def threader(per)
		@queue=Queue.new
		$__queue__=@queue
		ici=self
		GLib::Timeout.add(per) {
			if @queue.size>0 
				( ici.instance_eval( &@queue.pop ) rescue log("#{$!} :\n  #{$!.backtrace[0..3].join("\n   ")}") ) while @queue.size>0 
				show_all
			end
         true
        }
	end
	# shot peridicly ; return handle of animation. can be stoped by delete(hanim)
  	def anim(n,&blk) 
		GLib::Timeout.add(n) { 
			blk.call rescue log("#{$!} :\n  #{$!.backtrace[0..3].join("\n   ")}") 
			true 
		}
	end
	# one shot after some millisecs
  	def after(n,&blk) 
		GLib::Timeout.add(n) { 
			blk.call rescue log("#{$!} :\n  #{$!.backtrace[0..3].join("\n   ")}") 
			false
		}
	end
end

class Editor < Ruiby_gtk
    def initialize(w,filename)
		@filename=filename
        super("Edit #{filename[0..40]}",350,0)
		transient_for=w
    end	
	def component()        
	  stack do
		@edit=slot(source_editor()).editor
		@edit.buffer.text=File.exists?(@filename) ? File.read(@filename) : @filename
		sloti( button("Exit") { destroy() })
	  end
	end # endcomponent

end
# end #end module :Gtk

############################ Invoke HMI from anywhere ####################
#		$__queue__= 
#		$__mainthread__= Thread.current
#		$___mainwindow__=self

def gui_invoke(&blk) 
    if ! defined?($__mainwindow__)
		puts("\n\ngui_invoke() : initialize() of main windows not done!\n\n") 
		return
	end
	if $__mainthread__ != Thread.current
		if defined?($__queue__)
			$__queue__.push( blk ) 
		else
			puts("\n\nThreaded invoker not initilized! : please call threader(ms) on window constructor!\n\n") 
		end
	else
		$___mainwindow__.instance_eval( &blk )
	end
end

def gui_invoke_wait(&blk) 
    if ! defined?($__mainwindow__)
		puts("\n\ngui_invoke_wait() : initialize() of main windows not done!\n\n") 
		return
	end
	if $__mainthread__ != Thread.current
		if defined?($__queue__)
			$__queue__.push( blk ) 
			n=0
			(sleep(0.05);n+=1) while $__queue__.size>0 && n<5000 # 25 secondes max!
		else
			puts("\n\nThreaded invoker not initilized! : please call threader(ms) on window constructor!\n\n") 
		end
	else
		$___mainwindow__.instance_eval( &blk )
	end
end
