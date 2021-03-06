# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl

  # append the result of bloc parameter to a contener (stack or flow)
  # thread protected
  # Usage : 
  #  @stack= stack {}
  #    . . . . 
  #    append_to(@stack) { button("Hello") }
  def append_to(cont,&blk)
    if $__mainthread__ != Thread.current
      gui_invoke { append_to(cont,&blk) }
      return
    end
    @lcur << cont
    yield 
    autoslot()
    @lcur.pop
    show_all_children(cont)
  end

  # clear a containet (stack or flow)
  # thread protected
  def clear(cont) 
    if $__mainthread__ != Thread.current
      p "not in main thread"
      gui_invoke { clear(cont) }
      return
    end
    cont.children.each { |w| cont.remove(w) } 
  end
  
  # clear a container (stack or flow) and append the result of bloc parameter to this
  # container
  # thread protected
  def clear_append_to(cont,&blk) 
    if $__mainthread__ != Thread.current
      p "not in main thread"
      gui_invoke { clear_append_to(cont,&blk) }
      return
    end
    cont.children.each { |w| cont.remove(w) } 
    @lcur << cont
    yield 
    autoslot()
    @lcur.pop
    show_all_children(cont)
  end
  def show_all_children(c)
    return unless c
    c.each { |f|   show_all_children(f) if  f.respond_to?(:children) ; f.show() } ; c.show
  end
  # append the widget w before another one wref
  # thread protected
  def slot_append_before(w,wref)
    if $__mainthread__ != Thread.current
      gui_invoke { slot_append_before(w,wref) }
      return
    end
    parent=_check_append("slot_append_before",w,wref)
    parent.add(w)
    parent.children.each_with_index { |child,i| 
      next if child!=wref
      parent.reorder_child(w,i)
      break
    }
    w
  end
  # append the widget w after anotherone wref)
  # thread protected
  def slot_append_after(w,wref)
    if $__mainthread__ != Thread.current
      gui_invoke { slot_append_after(w,wref) }
      return
    end
    parent=_check_append("slot_append_after",w,wref)
    parent.add(w)
    parent.children.each_with_index { |child,i| 
      next if child!=wref
      parent.reorder_child(w,i+1)
      break
    }
    w
  end
  # delete a widget or a timer
  # thread protected
  def delete(w)
    if $__mainthread__ != Thread.current
      gui_invoke { delete(w) }
      return
    end
    if  Numeric === w && @hTimer[w]
      @hTimer[w]=false
    elsif  GLib::Timeout === w
      w.destroy
    else
      w.parent.remove(w) rescue error($!)
    end
  end
  def _check_append(name,w,wref)
    raise("#{name}(w,r) : Widget ref not created!") unless wref
    raise("#{name}(w,r) : new Widget not created!") unless w
    parent=wref.parent
    raise("#{name}(w,r): r=#{parent.inspect} is not a XBox or Frame !") unless !parent || parent.kind_of?(Container)
    raise("#{name}(w,r): r=#{parent.inspect} is not a XBox or Frame !") unless parent.respond_to?(:reorder_child)
    parent
  end
  

	# define a set of css style, to be apply to every widget of main window
	# if noparameter, load a file <caller>.rc
	def def_style(string_style=nil)
		unless string_style
		   fn=caller[0].gsub(/.rb$/,".rc")
		   raise "Style: no ressource (#{fn} not-exist)" if !File.exists?(fn)
		   string_style=File.read(fn)
		end
		begin
		  css=Gtk::CssProvider.new
		  css.load(data: string_style)
		  Ruiby.set_style_provider(css)
		  Ruiby.apply_provider(self)
		rescue Exception => e
		  error "Error loading style : #{e}\n#{string_style}"
		end
	end

	 
  # make a snapshot raster file of current window
  # can be called by user. 
  # Is called by mainloop if string 'take-a-snapshot' is present in ARGV
  # only for Windows !!!
  def snapshot(filename=nil)
     return unless  RUBY_PLATFORM =~ /in.*32/
     require 'win32/screenshot'
     require 'win32ole'
     
     filename=Time.now.strftime("%D-%H%m%s.png").gsub('/','-') unless filename
     
     # window must have a title...
     if ! self.title || self.title.size<3
        self.title=Time.now.to_f.to_s.gsub('.','')
     end
    File.delete(filename) if File.exists?(filename)
    puts "generated  for title '#{self.title}' ==> #{filename} ..."
    Win32::Screenshot::Take.of(:window,:title => /#{self.title}/, :context => :window).write(filename)
    puts "snapshot done, size= #{File.size(filename)/1024} KB, name=#{filename}"
  end  

  ###################################### Logs

  # put a line of message text in log dialog (create and show the log dialog if not exist)
  def log(*txt)
    if $__mainthread__ && $__mainthread__ != Thread.current
      gui_invoke { log(*txt) }
      return
    end
    loglabel=_create_log_window()
    buffer=loglabel.buffer
    tc=txt.map {|t| 
      t.kind_of?(Exception) ?  "#{t.to_s}\n  #{(t.backtrace||[]).join("\n  ")}\n" :  t 
    }.join(" ")
    txt_utf8= tc.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '?')
    t="#{Time.now} | #{txt_utf8}\n"
    buffer.insert(buffer.end_iter,t)
    if ( loglabel.buffer.text.size>1000*1000)
      loglabel.buffer.text=loglabel.buffer.text[-7000..-1]
    end
    #----------  scroll to bottom, not perfect
    Ruiby.update
    vscroll=loglabel.parent.vadjustment
    vscroll.value = vscroll.upper+8
  end
  def trace(*txt)
    if $__mainthread__ && $__mainthread__ != Thread.current
      gui_invoke { log(*txt) }
      return
    end
    loglabel=_create_log_window()
    buffer=loglabel.buffer
    tc=txt.map {|t| 
      t.kind_of?(Exception) ?  "#{t.to_s}\n  #{(t.backtrace||[]).join("\n  ")}\n" :  t 
    }.join(" ")
    txt_utf8= tc.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '?')
    t=" #{txt_utf8}\n"
    buffer.insert(buffer.end_iter,t)
    if ( loglabel.buffer.text.size>1000*1000)
      loglabel.buffer.text=loglabel.buffer.text[-7000..-1]
    end
    #----------  scroll to bottom, not perfect
    Ruiby.update
    vscroll=loglabel.parent.vadjustment
    vscroll.value = vscroll.upper+8
  end
  
  def _create_log_window() 
    return(@loglabel) if defined?(@loglabel) && @loglabel && ! @loglabel.destroyed?
    wdlog = Dialog.new(
            title: "Logs #{$0}",
            parent: nil,
            flags: 0,
            buttons:   [[ :Validation,1]]
    )
    Ruiby.set_last_log_window(wdlog)
    logBuffer = TextBuffer.new
    @loglabel=TextView.new(logBuffer)
    @loglabel.override_font(  Pango::FontDescription.new("Courier new 10")) 
    sw=ScrolledWindow.new()
    sw.set_width_request(800) 
    sw.set_height_request(200)  
    sw.set_policy(:automatic, :always)
    
    sw.add_with_viewport(@loglabel)
    wdlog.child.pack_start(sw, :expand => true, :fill => true, :padding => 3)
    wdlog.signal_connect('response') { wdlog.destroy }
    wdlog.show_all  
    @loglabel
  end
  def log_as_widget(width=nil,height=nil,opt={})
    logBuffer = TextBuffer.new
    loglabel=TextView.new(logBuffer)
    loglabel.override_font(  Pango::FontDescription.new( opt["font"] || "Courier new 10")) 
    sw=ScrolledWindow.new()
    sw.set_width_request(width) if width
    sw.set_height_request(height)  if height
    sw.set_policy(:automatic, :always)
    class << loglabel
      def add(s) 
        self.buffer.insert(self.buffer.end_iter,s)  
        self.scroll_mark_onscreen(self.buffer.create_mark("mend",self.buffer.start_iter.forward_to_end,false))
        self.parent.vadjustment.value=self.parent.vadjustment.upper - self.parent.vadjustment.page_size
      end
      def clear() self.buffer.text="" end
      def text=(s) self.buffer.text=s  end
    end
    sw.add_with_viewport(loglabel)
    apply_options(loglabel,opt)
    attribs(sw,{})
    @loglabel=loglabel
  end
end