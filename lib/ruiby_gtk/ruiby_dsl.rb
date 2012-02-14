module Ruiby_dsl
	include ::Gtk
	include ::Ruiby_default_dialog
 
	############################ define style !! WArining: speific to gtk
	# see http://ruby-gnome2.sourceforge.jp/hiki.cgi?Gtk%3A%3ARC
	# %GTK_BASEPATH%/share/themes/Metal/gtk-2.0/gtkrc
	#
	# style "mstyle"
	# {
	# 	GtkWidget::interior_focus = 1
	# 	GtkButton::default_spacing = { 1, 1, 1, 1 }
	# 	GtkButton::default_outside_spacing = { 0, 0, 0, 0 }
	# 	font_name = "lucida"
	#   bg_pixmap[NORMAL] = 'pixmap.png'
	# 	bg[NORMAL]      = { 0.80, 0.80, 0.80 }
	# 	bg[PRELIGHT]    = { 0.80, 0.80, 1.00 }
	# 	bg[ACTIVE]      = { 0.80, 0.80, 0.80 }
	# 	bg[SELECTED]    = { 0.60, 0.60, 0.80 }
	# 	text[SELECTED]  = { 0.00, 0.00, 0.00 }
	# 	text[ACTIVE]    = { 0.00, 0.00, 0.00 }
	# }	
	# class "GtkLabel" style "mstyle"
	#
	def def_style(string_style=nil)
		unless string_style
			 fn=caller[0].gsub(/.rb$/,".rc")
			 raise "Style: no ressource (#{fn} not-exist)" if !File.exists?(fn)
			 string_style=File.read(fn)
		end
		begin
			Gtk::RC.parse_string(string_style)
			@style_loaded=true
		rescue Exception => e
			error "Error loading style : #{e}\n#{string_style}"
		end
	end
	############################ Slot : H/V Box or Frame
	def vbox_scrolled(width,height,&b)
		sw=slot(ScrolledWindow.new())
		sw.set_width_request(width)		if width>0 
		sw.set_height_request(height)	if height>0
		sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
		ret=stack(false,&b)
		sw.add_with_viewport(ret)
		class << sw
			def scroll_to_top()    vadjustment.set_value( 0 ) end
			def scroll_to_bottom() vadjustment.set_value( vadjustment.upper - 1) end
			def scroll_to_left()   hadjustment.set_value( 0 ) end
			def scroll_to_right()  hadjustment.set_value( hajustement.upper-1 ) end
		end
		sw
	end	


	def clickable(methode_name,&b) 
		eventbox = Gtk::EventBox.new
		eventbox.events = Gdk::Event::BUTTON_PRESS_MASK
		ret=cbox(true,eventbox,true,&b) 
		eventbox.realize
		eventbox.signal_connect('button_press_event') { |w, e| self.send(methode_name,ret) }
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
 		raise("#{name}(w,r) : Widget ref not created!") unless wref
 		raise("#{name}(w,r) : new Widget not created!") unless w
 		parent=wref.parent
 		raise("#{name}(w,r): r=#{parent.inspect} is not a XBox or Frame !") unless !parent || parent.kind_of?(Container)
 		raise("#{name}(w,r): r=#{parent.inspect} is not a XBox or Frame !") unless parent.respond_to?(:reorder_child)
 		parent
 	end
	

	def get_current_container() @lcur.last end
	

	########################### widgets #############################
	def get_icon(name)
		return name if name.index('.') && File.exists?(name)
		iname=eval("Stock::"+name.upcase) rescue nil
	end
	def get_image_from(name)
		puts("#{name}...") if name.index('.') && File.exists?(name)
		return Image.new(name) if name.index('.') && File.exists?(name)
		iname=eval("Stock::"+name.upcase) rescue nil
		if iname
			Image.new(iname,IconSize::BUTTON)
		else
			nil
		end
	end

	############### Commands
	def attribs(w,options)
		  w.modify_bg(Gtk::STATE_NORMAL,options[:bg]) if options[:bg]
		  w.modify_fg(Gtk::STATE_NORMAL,options[:fg]) if options[:fg]
		  w.modify_font(Pango::FontDescription.new(options[:font])) if options[:font]
		  w
	end
	def separator(width=1.0)  sloti(HBox === @lcur.last ? VSeparator.new : HSeparator.new)  end
	def label(text,options={})
		l=if text && text[0,1]=="#"
			get_image_from(text[1..-1]);
		else
			Label.new(text);
		end
		attribs(l,options)
	end
	def button(text,option={},&blk)
		if text && text[0,1]=="#"
			b=Button.new()
			b.set_image(get_image_from(text[1..-1]))
		else
			b=Button.new(text);
		end
		b.signal_connect("clicked",&blk) if blk
		attribs(b,option)
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
				Gtk::ToolButton.new(iname).tap { |but|
				  but.signal_connect("clicked") { v.call } if v
			 	  but.set_tooltip_text(tooltip) if tooltip
			 	}
			elsif name=~/^sep/i
				Gtk::SeparatorToolItem.new
			else
				puts "=======================\nUnknown icone : #{name}\n====================="
	   			puts "Icones dispo: #{Stock.constants.map { |ii| ii.downcase }.join(", ")}"
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
	def entry(value,size=10,option={},&blk)
		w=Entry.new().tap {|e| e.set_text(value ? value.to_s : "") }
		attribs(w,option)	
		after(1) do
			w.signal_connect("key-press-event") do |en,e|
				after(1) { blk.call(w.text) }
				false
			end 
		end if block_given?
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
		w.signal_connect('button_press_event')   { |wi,e| @do = option[:mouse_down].call(wi,e)                ; force_update(wi) }  if option[:mouse_down]
		w.signal_connect('button_release_event') { |wi,e| option[:mouse_up].call(wi,e,@do)   if @do ; @do=nil ; force_update(wi) if @do }  if option[:mouse_up]
		w.signal_connect('motion_notify_event')  { |wi,e| @do = option[:mouse_move].call(wi,e,@do) if @do     ; force_update(wi) if @do }  if option[:mouse_move]
		w.signal_connect('key_press_event')  { |wi,e| option[:key_press].call(wi,e) ; force_update(wi) }  if option[:key_press]
		attribs(w,option)				
		w
	end
	def force_update(canvas) canvas.queue_draw unless  canvas.destroyed?  end

	############################ table
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
	
	def row()
		@col=0 # will be increment by cell..()
		yield
		@row+=1
	end	
	
	def  cell(w) 		 @lcur.last.attach(w,@col,@col+1,@row,@row+1) ; @col+=1 end
	def  cell_hspan(n,w) @lcur.last.attach(w,@col,@col+n,@row,@row+1) ; @col+=n end # :notested!
	def  cell_vspan(n,w) @lcur.last.attach(w,@col,@col+1,@row,@row+n) ; @col+=1 end # :notested!
	def  cell_pass(n=1)  @col+=n end # :notested!
	def  cell_span(n=2,w)
		@lcur.last.attach(w,@col,@col+n,@row,@row+1)
		@col+=n
	end
	
	# set_alignment is not defined for all widget, so rescue..
	def cell_left(w)     w.set_alignment(0.0, 0.5) rescue nil; cell(w) end
	def cell_right(w)    w.set_alignment(1.0, 0.5)rescue nil ; cell(w) end
	
	def cell_hspan_left(n,w)   w.set_alignment(0.0, 0.5)rescue nil ; cell_hspan(n,w) end
	def cell_hspan_right(n,w)  w.set_alignment(1.0, 0.5)rescue nil ; cell_hspan(n,w) end
	
	def cell_top(w)      w.set_alignment(0.5, 0.0)rescue nil ; cell(w) end
	def cell_bottom(w)   w.set_alignment(0.5, 1.0)rescue nil ; cell(w) end

	def cell_vspan_top(n,w)    w.set_alignment(0.5, 0.0)rescue nil ; cell_vspan(n,w) end
	def cell_vspan_bottom(n,w) w.set_alignment(0.5, 1.0)rescue nil ; cell_vspan(n,w) end
	

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
		wdlog = Dialog.new("Logs : #{$0}",
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

	
end
