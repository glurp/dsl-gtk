# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

=begin
general definition of Ruiby DSL, for GTK2. 

Most of this ressource are not thread-safe : use ruiby in the context
of main thread (thread which invoke Ruiby.start).

Exception : in thread, theses methods are frequently used. so they are thread-protected,
if they detect a invocation out of main thread, they auto-recall in a gui_invoke block :
    append_to(cont,&blk)       clear_append_to(cont,&blk)
    slot_append_before(w,wref) slot_append_after(w,wref)
    delete(w) 
    log(txt)

=end
module Ruiby_dsl
  include ::Gtk
  include ::Ruiby_default_dialog

  ############################ Slot : H/V Box or Frame

  def _nocodeeeeeeeeeee() end

  # container : vertical box, take all space available, sloted in parent ny default
  def stack(add1=true,&b)    		_cbox(true,VBox.new(false, 2),add1,&b) end
  # container : horizontal box, take all space available, sloted in parent
  def flow(add1=true,&b)	   		_cbox(true,HBox.new(false, 2),add1,&b) end
  # container : vertical box, take only necessary space , sloted in parent
  def stacki(add1=true,&b)    	_cbox(false,VBox.new(false, 2),add1,&b) end
  # container : horizontal box, take only necessary space , sloted in parent
  def flowi(add1=true,&b)	   		_cbox(false,HBox.new(false, 2),add1,&b) end

  # box { } used for container which manage the widget (as stack(false) {} ) 
  # use it for cell in table : table { row { cell(box { });... };... }
  def box() 
    box=VBox.new(false, 2)
    @lcur << box
    yield
    autoslot()
    @lcur.pop
  end
  # center { }  container which center his content (auto-sloted)
  def center() 
    autoslot()
    valign = Gtk::Alignment.new(0,0,0,0)
    @lcur.last.pack_start(valign,false,false,0)
    vbox=VBox.new(true, 0)
    valign.add(vbox)
    @lcur << vbox
    yield
    autoslot()
    @lcur.pop
  end

  # a box with border and texte title, take all space
  def frame(t="",add1=true,&b)  	
    _cbox(true,Frame.new(t),add1) { stack { b.call } } 
  end
  # a box with border and texte title, take only necessary space
  def framei(t="",add1=true,&b)
    _cbox(false,Frame.new(t),add1) { stack { b.call } }
  end

  # private: generic packer
  def _cbox(expand,box,add1)
    autoslot()
    if add1
      expand ? @lcur.last.add(box) : @lcur.last.pack_start(box,false,false,3)
    end
    @lcur << box
    yield
    autoslot()
    @lcur.pop
  end

  # pack widget in parameter, share space with prother widget
  # this is the default: all widget will be sloted if they are not slotied
  # this is done by attribs(w) which is call after construction of almost all widget
  def slot(w)  @current_widget=nil; @lcur.last.add(w) ; w end
  
  # pack widet in parameter, take only necessary space
  def sloti(w) @current_widget=nil; @lcur.last.pack_start(w,false,false,3) ; w end

  # slot() precedently created widget if not sloted.
  # this is done by attribs(w) which is call after construction of almost all widget
  def autoslot(w=nil)
    (slot(@current_widget)) if @current_widget!=nil
    @current_widget=w 
  end
  # forget precedent wdget oconstructed
  def raz() @current_widget=nil; end

  # append the result of bloc parameter to a contener (stack or flow)
  # thread protected
  # Usage : 
  #	 @stack= stack {}
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


  def get_current_container() @lcur.last end

  # get a Hash aff all properties of a gtk widget
  def get_config(w)
    return({"nil"=>""}) unless w && w.class.respond_to?("properties")
    w.class.properties().inject({"class"=>w.class.to_s}) { |h,meth| 
      data=(w.send(meth) rescue nil)
      h[meth]=data.inspect.gsub(/^#/,'')[0..32]  if data 
      h
    }
  end

  ########################### raster images access #############################

  def get_icon(name)
    return name if name.index('.') && File.exists?(name)
    iname=eval("Gtk::Stock::"+name.upcase) rescue nil
  end
  def get_stockicon_pixbuf(name)
    Image.new(eval("Gtk::Stock::"+name.upcase),IconSize::BUTTON).pixbuf
  end

  # get a Image widget from a file or from a Gtk::Stock
  # image can be a filename or a predefined icon in GTK::Stock
  # for file image, whe can specify a sub image (sqared) :
  #     filename.png[NoCol , NoRow]xSize
  #     filename.png[3,2]x32 : extract a icon of 32x32 pixel size from third column/second line
  #    see samples/draw.rb
  def get_image_from(name)
    if name.index('.') 
      return Image.new(name) if File.exists?(name)
      return _sub_image(name) if name.index("[")
      alert("unknown icone #{name}")
    end
    iname=get_icon(name)
    if iname
      Image.new(iname,IconSize::BUTTON)
    else
      nil
    end
  end
  def _sub_image(name)
    Image.new(get_pixbuf(name))
  end
  def get_pixbuf(name)
    @cach_pix={} unless defined?(@cach_pix)
    filename,px,py,bidon,dim=name.split(/\[|,|(\]x)/)
    if filename && px && py && bidon && dim && File.exist?(filename)
      dim=dim.to_i
      @cach_pix[filename]=Gdk::Pixbuf.new(filename) unless @cach_pix[filename]
      x0= dim*px.to_i
      y0= dim*py.to_i
      #p [x0,y0,"/",@cach_pix[filename].width,@cach_pix[filename].height]
      Gdk::Pixbuf.new(@cach_pix[filename],x0,y0,dim,dim)
    elsif File.exists?(name)
      @cach_pix[name]=Gdk::Pixbuf.new(name) unless @cach_pix[name]
      @cach_pix[name]
    elsif ! name.index(".")
      get_stockicon_pixbuf(name)
    else
      raise("file #{name} not exist");
    end
  end

  ############### Commands

  # general property automaticly applied for (almost) all widget (eval last argument a creation)
  def attribs(w,options)
      w.set_size_request(*options[:size]) if options[:size]	
      w.width_request=(options[:width]) if options[:width]
      w.height_request=(options[:height]) if options[:height]
      w.modify_bg(Gtk::STATE_NORMAL,options[:bg]) if options[:bg] # not work on window
      w.modify_fg(Gtk::STATE_NORMAL,options[:fg]) if options[:fg] # not work on window
      w.modify_font(Pango::FontDescription.new(options[:font])) if options[:font]
      autoslot(w)  # slot() precedent widget if existe and not already sloted, and declare this one as the precedent
      w
  end

  # create a bar (vertical or horizontal according to stack/flow current container) 
  def separator(width=1.0)  
    autoslot()
    sloti(HBox === @lcur.last ? VSeparator.new : HSeparator.new)  
  end

  # create  label, with text (or image if txt start with a '#')
  def label(text,options={})
    l=_label(text,options)
    attribs(l,options)
  end
  def labeli(text,options={}) sloti(label(text,options)) end 
  def _label(text,options={})
    l=if text && text[0,1]=="#"
      get_image_from(text[1..-1]);
    else
      Label.new(text);
    end
  end

  # create a icon with a raster file 
  # option can specify a new size : :width and :height, or :size  (square image)
  def image(file,options={})
    im=if File.exists?(file)
      pix=Gdk::Pixbuf.new(file) 
      pix=pix.scale(options[:width],options[:height],Gdk::Pixbuf::INTERP_BILINEAR) if options[:width] && options[:height]
      pix=pix.scale(options[:size],options[:size],Gdk::Pixbuf::INTERP_BILINEAR)  if options[:size] 
      Image.new(pix)
    else
      label("? "+file)
    end
    options.delete(:size)
    attribs(im,options)
  end
  # create a one-character size space, (or n character x n line space)
  def space(n=1) label(([" "*n]*n).join("\n"))  end

  # create  button, with text (or image if txt start with a '#')
  # block argument is evaluate at button click
  def button(text,option={},&blk)
    if text && text[0,1]=="#"
      b=Button.new()
      b.set_image(get_image_from(text[1..-1]))
    else
      b=Button.new(text);
    end
    b.signal_connect("clicked") { |e| blk.call(e) rescue error($!) } if blk
    attribs(b,option)
  end 
  
  # create  button, with text (or image if txt start with a '#')
  # block argument is evaluate at button click, slotied :
  #  packed without expand for share free place
  def buttoni(text,option={},&blk) sloti(button(text,option,&blk)) end 

  # horizontal toolbar of icon button and/or separator
  # if icon name contain a '/', second last is  tooltip text
  # Usage: 
  #   htoolbar(["text/tooltip", proc { },"separator" => "", ....]
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
          but.signal_connect("clicked") { v.call rescue error($!) } if v
          but.set_tooltip_text(tooltip) if tooltip
        }
      elsif name=~/^sep/i
        Gtk::SeparatorToolItem.new				
      elsif name=~/^right-(.*)/i
        Gtk::ToolButton.new(get_icon($1)).tap { |but|
          but.signal_connect("clicked") { v.call rescue error($!) } if v
          but.set_tooltip_text(tooltip) if tooltip
        }
      else
        puts "=======================\nUnknown icone : #{name}\n====================="
          puts "Icones dispo: #{Stock.constants.map { |ii| ii.downcase }.join(", ")}"
        Gtk::ToolButton.new(Stock::MISSING_IMAGE)
      end
      if w
        Ruiby.gtk_version(2) ? b.insert(i,w) : b.insert(w,i)
      end
      i+=1
     }
    attribs(b,options)
  end 

  ############### Inputs widgets

  #combo box, decribe  with a Hash choice-text => value-of-choice
  def combo(choices,default=-1,option={})
    if   Ruiby.gtk_version(2)
      w=ComboBox.new()
      choices.each do |text,indice|  
        w.append_text(text) 
      end
      w.set_active(default) if default>=0
      attribs(w,option)		
      w
    else
      w=ComboBoxText.new()
      choices.each do |text,indice|  
        w.append_text(text) 
      end
      w.set_active(default) if default>=0
      attribs(w,option)		
      w
    end
  end

  # to state button, with text for each state and a initiale value
  # value can be read by w.active?
  # callback on state change with new value as argument
  def toggle_button(text1,text2=nil,value=false,option={},&blk)
    text2 = "- "+text1 unless text2
    b=ToggleButton.new(text1);
    b.signal_connect("toggled") do |w,e| 
      w.label= w.active?() ? text2.to_s : text1.to_s 
      ( blk.call(w.active?()) rescue error($!) ) if blk
    end
    b.set_active(value)
    b.label= value ? text2.to_s : text1.to_s 
    attribs(b,option)		
    b
  end
  # create a checked button
  # no callback
  # state can be read by cb.active?
  def check_button(text="",value=false,option={})
    b=CheckButton.new(text)
          .set_active(value)
    attribs(b,option)
    b
  end
  # create a liste of radio button, horiznataly disposed
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

  # create a liste of radio button, vrtically disposed
  def vradio_buttons(ltext=["empty!"],value=-1)
    stack(false) {
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
  # create a text entry for keyboed input
  # if block defined, it while be trigger on ech of (character) change of the entry
  def entry(value,size=10,option={},&blk)
    w=Entry.new().tap {|e| e.set_text(value ? value.to_s : "") }
    after(1) do
      w.signal_connect("key-press-event") do |en,e|
        after(1) { blk.call(w.text) rescue error($!) }
        false
      end 
    end if block_given?
    attribs(w,option)
  end
  # create a integer text entry for keyboed input
  # option must define :min :max :by for spin button
  def ientry(value,option={},&blk)
    w=SpinButton.new(option[:min].to_i,option[:max].to_i,option[:by])
    w.set_numeric(true)
    w.set_value(value ? value.to_i : 0)
    
    w.signal_connect("value-changed") do |en|
      after(1) { blk.call(w.value) }
      false
    end if block_given?
    attribs(w,option)		
    w
  end

  # create a integer text entry for keyboed input
  # option must define :min :max :by for spin button
  def fentry(value,option={},&blk)
    w=SpinButton.new(option[:min].to_f,option[:max].to_f,option[:by].to_f)
    w.set_numeric(true)
    w.set_value(value ? value.to_f : 0.0)
    w.signal_connect("value-changed") do |en|
      after(1) { blk.call(w.value) rescue error($!)  }
      false
    end if block_given?
    attribs(w,option)		
    w
  end
  def field(tlabel,width,value,option={},&blk)
    e=nil
    flow {
      l=label(tlabel+ " : ")
      l.width_chars=width+3
      e=entry(value,option,&blk)
    }
    e
  end
  def fields(alabel,option={},&blk)   
    size=alabel.map {|t| t[0].size}.max
    stack {
      le=alabel.map { |(label,value)| field(label,size,value) }
      if block_given?
          button("Validation") { blk.call(*le.map {|t| t.text}) }
          button("Annulation") { blk.call(*le.map {|t| nil}) }
      end
    }
  end
  # create a slider
  # option must define :min :max :by for spin button
  # current value can be read by w.value
  # if bloc is given, it with be call on each change, with new value as parameter
  def islider(value,option={},&b)
    w=HScale.new(option[:min].to_i,option[:max].to_i,option[:by])
      .set_value(value ? value.to_i : 0)
    attribs(w,option)		
    w.signal_connect(:value_changed) { || b.call(w.value)  rescue error($!) } if block_given?
    w
  end

  # create a button wich will show a dialog for color choice
  # if bloc is given, it with be call on each change, with new color value as parameter
  def color_choice(text=nil,options={},&cb)
    b,d=nil,nil
    hb=flow(false) { b = slot(button(text.to_s||"Color?...")) ; d=slot(DrawingArea.new) }					
    b.signal_connect("clicked") {
      c=ask_color
      if c
      d.modify_bg(Gtk::STATE_NORMAL,c)
      b.modify_bg(Gtk::STATE_NORMAL,c)
      cb.call(c) if block_given?
      end
    }
    attribs(hb,options)		
    hb
  end
  # create a drawing area, for pixel draw
  # option can define closure :mouse_down :mouse_up :mouse_move
  # for interactive actions
  # see tst.rb fo little example
  # see samples/draw.rb for a little vector editor...
  def canvas(width,height,option={})
    autoslot()
    w=DrawingArea.new()
    w.set_size_request(width,height)
    w.events |= ( ::Gdk::Event::BUTTON_PRESS_MASK | ::Gdk::Event::POINTER_MOTION_MASK | ::Gdk::Event::BUTTON_RELEASE_MASK)
    w.signal_connect( 'expose-event'  ) { |w1,e| 
      cr = w1.window.create_cairo_context
      cr.save {
        cr.set_line_join(Cairo::LINE_JOIN_ROUND)
        cr.set_line_cap(Cairo::LINE_CAP_ROUND)
            cr.set_line_width(2)
            cr.set_source_rgba(1,1,1,1)
            cr.paint
        if option[:expose]
          begin
            option[:expose].call(w1,cr) 
          rescue Exception => e
           bloc=option[:expose]
           option.delete(:expose)
           after(1) { error(e) }
           after(3000) {  puts "reset expose bloc" ;option[:expose] = bloc }
          end  
        end
      }
    }
    @do=nil
    w.signal_connect('button_press_event')   { |wi,e| @do = option[:mouse_down].call(wi,e)  rescue error($!)              ; force_update(wi) }  if option[:mouse_down]
    w.signal_connect('button_release_event') { |wi,e| (option[:mouse_up].call(wi,e,@do)  rescue error($!)) if @do ; @do=nil ; force_update(wi) if @do }  if option[:mouse_up]
    w.signal_connect('motion_notify_event')  { |wi,e| (@do = option[:mouse_move].call(wi,e,@do) rescue error($!)) if @do     ; force_update(wi) if @do }  if option[:mouse_move]
    w.signal_connect('key_press_event')  { |wi,e| (option[:key_press].call(wi,e) rescue error($!)) ; force_update(wi) }  if option[:key_press]
    attribs(w,option)	
    def	w.redraw() 
      self.queue_draw_area(0,0,1000,1000)
    end
    w
  end
  # update a canvas
  def force_update(canvas) canvas.queue_draw unless  canvas.destroyed?  end

  ############################ table
  # create a container for table-disposed widgets. this is not a grid!
  # table(r,c) { row { cell(w) ; .. } ; ... }
  def table(nb_col,nb_row,config={})
    table = Gtk::Table.new(nb_row,nb_col,false)
    table.set_column_spacings(config[:set_column_spacings]) if config[:set_column_spacings]
    #sloti(table)
    @lcur << table
    @ltable << { :row => 0, :col => 0}
    yield
    @ltable.pop
    @lcur.pop
    attribs(table,config)
  end
    # create a row. must be defined in a table closure	
  # can only contain cell(s) call
  def row()
    autoslot()
    @ltable.last[:col]=0 # will be increment by cell..()
    yield
    @ltable.last[:row]+=1
  end	
  # a cell in a row/table. take all space, centered
  def  cell(w) 	cell_hspan(1,w)	  end
  # a cell in a row/table. take space of n cells, horizontaly
  def  cell_hspan(n,w) raz();@lcur.last.attach(w,@ltable.last[:col],@ltable.last[:col]+n,@ltable.last[:row],@ltable.last[:row]+1) ; @ltable.last[:col]+=n end 
  # a cell in a row/table. take space of n cells, vericaly
  def  cell_vspan(n,w) raz();@lcur.last.attach(w,@ltable.last[:col],@ltable.last[:col]+1,@ltable.last[:row],@ltable.last[:row]+n) ; @ltable.last[:col]+=1 end 
  # keep empty n cell consecutive on current row
  def  cell_pass(n=1)  @ltable.last[:col]+=n end
  # a cell in a row/table. take space of n cells, horizontaly
  def  cell_span(n=2,w) cell_hspan(n,w) end

  # create a cell in a row/table, left justified
  def cell_left(w)     raz();w.set_alignment(0.0, 0.5) rescue nil; cell(w) end
  # create a cell in a row/table, right justified
  def cell_right(w)    raz();w.set_alignment(1.0, 0.5)rescue nil ; cell(w) end

  # create a hspan_cell in a row/table, left justified
  def cell_hspan_left(n,w)   raz();w.set_alignment(0.0, 0.5)rescue nil ; cell_hspan(n,w) end
  # create a hspan_cell in a row/table, right justified
  def cell_hspan_right(n,w)  raz();w.set_alignment(1.0, 0.5)rescue nil ; cell_hspan(n,w) end

  # create a cell in a row/table, top aligned
  def cell_top(w)      raz();w.set_alignment(0.5, 0.0)rescue nil ; cell(w) end
  # create a cell in a row/table, bottom aligned
  def cell_bottom(w)   raz();w.set_alignment(0.5, 1.0)rescue nil ; cell(w) end

  def cell_vspan_top(n,w)    raz();w.set_alignment(0.5, 0.0)rescue nil ; cell_vspan(n,w) end
  def cell_vspan_bottom(n,w) raz();w.set_alignment(0.5, 1.0)rescue nil ; cell_vspan(n,w) end

  # deprecated: see properties
  def propertys(title,hash,options={:edit=>false, :scroll=>[0,0]},&b)
    properties(title,hash,options,&b)
  end
  def _make_prop_line(prop_current,options,k,v)
    if k.to_s =~/^sep\d+$/
        cell_span(2,HSeparator.new)
    else
      cell_right(label(" "+k.to_s+" : "))
      cell_left(options[:edit] ? 
        (prop_current[k]=entry(v.to_s)) : 
        label(v.to_s))
    end
  end
  # show methods of a object/class in log window
  def show_methods(obj=nil,filter=nil)
    obj=self unless obj
    title="\n============ #{Class===obj.class ? obj : obj.class} ===========\n"
    data=(obj.methods-Object.methods).grep(filter || /.*/).sort.each_slice(3).map { |a,b,c| "%-30s| %-30s| %-30s" % [a,b,c]}.join("\n")
    footer="\n==================================================\n"
    log( title+data+footer)
  end
  
  # create a property shower/editor : vertical liste of label/entry representing the ruby Hash content
  # Edition: Option: use :edit => true for show value in text entry, and a validate button, 
  # on button action, yield of bloc parameter is done with modified Hash as argument
  # widget define set_data()methods for changing current value
  def properties(title,hash,options={:edit=>false, :scroll=>[0,0]})
    if ! defined?(@prop_index)
      @prop_index=0
      @prop_hash={}
    else
      @prop_index+=1
    end
    prop_current=(@prop_hash[@prop_index]={})
    value={}
    widget=stacki {
    framei(title.to_s) {
       stack {
        if options[:scroll] &&  options[:scroll][1]>0
         vbox_scrolled(options[:scroll][0],options[:scroll][1]) {
           table(2,hash.size) {
            hash.each { |k,v| row {
              _make_prop_line(prop_current,options,k,v)
            }}
            }
          }
        else
         table(2,hash.size) {
          hash.each { |k,v| row {
              _make_prop_line(prop_current,options,k,v)
          }}
          }
        end
          if options[:edit]
            sloti(button("Validation") { 
              nhash=widget.get_data()
              if block_given? 
                yield(nhash)
              else
                hash.clear
                nhash.each { |k,v| hash[k]=v }
              end
            }) 
          end
        }
     }
    }	
    widget.instance_variable_set(:@prop_current,prop_current)	  
    widget.instance_variable_set(:@hash_initial,hash)	  
    def widget.set_data(newh)
    newh.each { |k,v| @prop_current[k].text=v.to_s }
  end
  def widget.get_data()
  @prop_current.inject({}) {|nhash,(k,w)| 
    v_old=@hash_initial[k]
    v_new=w.text
    vbin=case v_old 
      when String then v_new
      when Fixnum then v_new.to_i
      when Float  then v_new.to_f
      when /^(\[.*\])|(\{.*\})$/ then eval( v_new ) rescue error($!)
      else v_new.to_s
    end
    nhash[k]=vbin
    nhash
  }
  end
  widget
  end

  ###################################### notebooks

  # create a notebook widget. it must contain page() wigget
  # notebook { page("first") { ... } ; ... }
  def notebook() 
  nb = Notebook.new()
  slot(nb)
  @lcur << nb
  yield
  @lcur.pop
  nb
  end
  # a page widget. only for notebook container.
  # button can be text or icone (if startin by '#', as label)
  def page(title,icon=nil)
  if icon && icon[0,1]=="#" 
    l = Image.new(get_icon(icon[1..-1]),IconSize::BUTTON); #flow(false) { label(icon) ; label(title) }
  else
    l=Label.new(title)
  end 
  @lcur.last.append_page( stack(false)  { yield }, l )
  end

  ############################## Popup
  # popup { pp_item("text") { } ; ... }
  def popup(w=nil)
  w ||= @lcur.last() 
  ppmenu = Gtk::Menu.new
  @lcur << ppmenu 
  yield
  @lcur.pop
  ppmenu.show_all		
  w.add_events(Gdk::Event::BUTTON_PRESS_MASK)
  w.signal_connect("button_press_event") do |widget, event|
    ppmenu.popup(nil, nil, event.button, event.time) if (event.button == 3)
  end
  ppmenu
  end
  def pp_item(text,&blk)
  item = Gtk::MenuItem.new(text)
  item.signal_connect('activate') { |w| blk.call() }
  @lcur.last.append(item)
  end
  def pp_separator()
  item = Gtk::SeparatorMenuItem.new()
  @lcur.last.append(item)
  end
  ############################## Menu
  # create a application menu. must contain menu() {} :
  # menu_bar {menu("F") {menu_button("a") { } ; menu_separator; menu_checkbutton("b") { |w|} ...}}
  def menu_bar()
  @menuBar= MenuBar.new
  ret=@menuBar
  yield
  sloti(@menuBar)
  @menuBar=nil
  ret
  end

  # a vertial drop-down menu, only for menu_bar container
  def menu(text)
  raise("menu(#{text}) without menu_bar {}") unless @menuBar
  @filem = MenuItem.new(text.to_s)
  @menuBar.append(@filem)
  @mmenu = Menu.new()
  yield
  @filem.submenu=@mmenu
  show_all_children(@mmenu)
  @filem=nil
  @mmenu=nil
  end

  # create an text entry in a menu
  def menu_button(text="?",&blk)
  raise("menu_button(#{text}) without menu('ee') {}") unless @mmenu
  item = MenuItem.new(text.to_s)
  @mmenu.append(item)
  item.signal_connect("activate") { blk.call(text)  rescue error($!) }
  end

  # create an checkbox  entry in a menu
  def menu_checkbutton(text="?",state=false,&blk)
  raise("menu_button(#{text}) without menu('ee') {}") unless @mmenu
  item = CheckMenuItem.new(text,false)
  item.active=state
  @mmenu.append(item)
  item.signal_connect("activate") {
    blk.call(item,text) rescue error($!.to_s)
  } 
  end
  def menu_separator() @mmenu.append( SeparatorMenuItem.new ) end

  ############################## Accordion

  # create a accordion menu. 	
  # must contain aitem() which must containe alabel() :
  # accordion { aitem(txt) { alabel(lib) { code }; ...} ... }
  def accordion() 
    @slot_accordion_active=nil #only one accordion active by window!
    w=stack { stacki {
      yield
    }}
    separator
    w
  end
  # create a hoizontral accordion menu. 	
  def haccordion() 
    @slot_accordion_active=nil #only one accordion active by window!
    w=flow { flowi {
      yield
    }}
    separator
    w
  end
  #  a button menu in accordion
  def aitem(txt,&blk) 
    b2=nil
    b=button(txt) {
          clear_append_to(@slot_accordion_active) {} if @slot_accordion_active
          @slot_accordion_active=b2
          clear_append_to(b2) { 
            blk.call()
          }
    }
    b2=stacki { }
  end

  # create e entry in button associate vue af a accordion menu
  def alabel(txt,&blk)
    l=nil
    pclickable(proc { blk.call(l) if blk} ) { l=label(txt) }
  end

  ############################## Panned : 
  # split current frame in 2 panes
  # create a container which can cntaine 2 widget, separated by movable bar
  # block invoked must return a array of 2 box wich will put in the 2 panes
  # vertivaly disposed
  def stack_paned(size,fragment,&blk) _paned(false,size,fragment,&blk) end

  # split current frame in 2 panes
  # create a container which can cntaine 2 widget, separated by movable bar
  # block invoked must return a array of 2 box wich will put in the 2 panes
  # horizonaly disposed
  def flow_paned(size,fragment,&blk) _paned(true,size,fragment,&blk) end

  def _paned(vertical,size,fragment)
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

  # a source_editor widget : text as showed in fixed font, colorized (default: ruby syntaxe)
  # from: green shoes plugin
  # options= :width  :height :on_change :lang :font
  # @edit=source_editor().editor
  # @edit.buffer.text=File.read(@filename)
  def source_editor(args={}) # from green_shoes plugin
  return
    begin
      require 'gtksourceview2'
    rescue Exception => e
      log('gtksourceview2 not installed!, please use text_area')
      return
    end
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
    cb.define_singleton_method(:text=) { |t| sv.buffer.text=t }
    cb.define_singleton_method(:text) {  sv.buffer.text }

    cb.set_size_request(args[:width], args[:height])
    cb.set_policy(POLICY_AUTOMATIC, POLICY_AUTOMATIC)
    cb.set_shadow_type(SHADOW_IN)
    cb.add(sv)
    cb.show_all
    attribs(cb,{})	
  end

  # multiline entry
  # @edit=text_area(300,100).text_area
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
      class << eb
      def text=(a)  self.children[0].buffer.text=a.to_s end
      def text()    self.children[0].buffer.text end
      def append(a) self.children[0].buffer.text+=a.to_s.encode("UTF-8") end
      end
      eb.children[0].buffer.text=(args[:text]||"")
      eb.show_all
      eb	
  end	

  ############################# calendar

    # Month Calendar with callback on month/year move and day selection :
  # calendar(Time.now-24*3600, :selection => proc {|day| } , :changed => proc {|widget| }
  # calendar respond to
  # *	set_time(time)  : toto and select the day of tume object
  # *	get_time()		: return time of selected day
  def calendar(time=Time.now,options={})
    c = Calendar.new
    #c.display_options(Calendar::SHOW_HEADING | Calendar::SHOW_DAY_NAMES |  
    #        Calendar::SHOW_WEEK_NUMBERS )
    after(1) { c.signal_connect("day-selected") { |w,e| options[:selection].call(w.day)  rescue error($!) } } if options[:selection]
    after(1) { c.signal_connect("month-changed") { |w,e| options[:changed].call(w)  rescue error($!) } }if options[:changed]
    calendar_set_time(c,time)
    class << c
      def set_time(time)
        select_month(time.month,time.year)
        select_day(time.day)
      end
      def get_time()
        year, month, day= *date() 
        Time.local(year, month, day) 
      end
    end
    attribs(c,options)

  end

  # deprecated : change the current selection of a calendar, by Time object
  def calendar_set_time(cal,time=Time.now)
    cal.select_month(time.month,time.year)
    cal.select_day(time.day)
  end

  ############################# Video
  # from: green shoes plugin
  # **  not tested!	**
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

  ######### Scrollable stack container

  # create a Scrolled widget with a autobuild stack in it
  # stack can be populated 
  # respond to : scrooo_to_top; scroll_to_bottom,
  def scrolled(width,height,&b)  vbox_scrolled(width,height,&b) end
  def vbox_scrolled(width,height,&b)
    sw=slot(ScrolledWindow.new())
    sw.set_width_request(width)		if width>0 
    sw.set_height_request(height)	if height>0
    sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
    ret= stack(false,&b) if  block_given? 
    sw.add_with_viewport(ret)
    class << sw
      def scroll_to_top()    vadjustment.set_value( 0 ) 					; vadjustment.value_changed ; end
      def scroll_to_bottom() vadjustment.set_value( vadjustment.upper - 100); vadjustment.value_changed ; end
      #def scroll_to_left()   hadjustment.set_value( 0 ) end
      #def scroll_to_right()  hadjustment.set_value( hadjustment.upper-1 ) end
    end
    attribs(sw,{})
  end	

  # specific to gtk : some widget like label can't support click event, so they must
  # be contained in a clockable parent (EventBox)
  #  clickable(:callback_click_name) { label(" click me! ") }
  #  def callback_click_name(widget) ... end
  # clickable with methone callback by name
  def clickable(methode_name,&b) 
    eventbox = Gtk::EventBox.new
    eventbox.events = Gdk::Event::BUTTON_PRESS_MASK
    ret=_cbox(true,eventbox,true,&b) 
    eventbox.realize
    eventbox.signal_connect('button_press_event') { |w, e| self.send(methode_name,ret)  rescue error($!) }
    ret
  end

  # clickable with callback by closure :
  # pclicakble(proc { alert("e") }) { alabel("click me!") }
  def pclickable(aproc,&b) 
    eventbox = Gtk::EventBox.new
    eventbox.events = Gdk::Event::BUTTON_PRESS_MASK
    ret=_cbox(true,eventbox,true,&b) 
    eventbox.realize
    eventbox.signal_connect('button_press_event') { |w, e| aproc.call(w,e)  rescue error($!)  }
    ret
  end

  ##################################### List

  # create a verticale liste of data, with scrollbar if necessary
  # define methods: 
  #   list() : get (gtk)list widget embeded
  #   model() : get (gtk) model of the list widget
  #   clear()  clear content of the list
  #   set_data(array) : clear and put new data in the list
  #   selected() : get the selected item (or nil)
  #   index() : get the index  of selected item (or nil)
  def list(title,w=0,h=0)
    scrolled_win = Gtk::ScrolledWindow.new
    scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    scrolled_win.set_width_request(w)	if w>0
    scrolled_win.set_height_request(h)	if h>0
    model = Gtk::ListStore.new(String)
    column = Gtk::TreeViewColumn.new(title.to_s,Gtk::CellRendererText.new, {:text => 0})
    treeview = Gtk::TreeView.new(model)
    if block_given?
      treeview.signal_connect("row-activated") do |view, path, column|
        iter = view.model.get_iter(path)
        yield iter[0]
      end		
    end
    treeview.append_column(column)
    treeview.selection.set_mode(Gtk::SELECTION_SINGLE)
    scrolled_win.add_with_viewport(treeview)
    def scrolled_win.list() children[0].children[0] end
    def scrolled_win.model() list().model end
    def scrolled_win.clear() list().model.clear end
    def scrolled_win.add_item(word)
      raise("list.add_item() out of main thread!") if $__mainthread__ != Thread.current
      list().model.append[0]=word  
    end
    def scrolled_win.set_data(words)
      raise("list.set_data() out of main thread!") if $__mainthread__ != Thread.current
      list().model.clear
      words.each { |w| list().model.append[0]=w }
    end
    def scrolled_win.selection() a=list().selection.selected ; a ? a[0] : nil ; end
    def scrolled_win.index() list().selection.selected end
    autoslot(scrolled_win)
    scrolled_win
  end

  # create a grid of data (as list, but multicolumn)
  # use set_data() to put a 2 dimensions array of text
  # same methods as list widget
  # all columnes are String type
  def grid(names,w=0,h=0)
    scrolled_win = Gtk::ScrolledWindow.new
    scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    scrolled_win.set_width_request(w)	if w>0
    scrolled_win.set_height_request(h)	if h>0
    
    model = Gtk::ListStore.new(*([String]*names.size))
    treeview = Gtk::TreeView.new(model)
    treeview.selection.set_mode(Gtk::SELECTION_SINGLE)
    names.each_with_index do  |name,i|
      treeview.append_column(
        Gtk::TreeViewColumn.new( name,Gtk::CellRendererText.new,{:text => i} )
      )
    end
    if block_given?
      treeview.signal_connect("row-activated") do |view, path, column|
        iter = view.model.get_iter(path)
        yield(names.size.times.map { |i| iter[i] })
      end		
    end
    
    def scrolled_win.grid() children[0].children[0] end
    def scrolled_win.model() grid().model end
    def scrolled_win.add_row(words)
      l=grid().model.append()
      words.each_with_index { |w,i| l[i] = w.to_s }
    end
    $ici=self
    def scrolled_win.get_data()	
      raise("grid.get_data() out of main thread!")if $__mainthread__ != Thread.current
      @ruiby_data
    end
    def scrolled_win.set_data(data)	
      @ruiby_data=data
      raise("grid.set_data() out of main thread!")if $__mainthread__ != Thread.current
      grid().model.clear() ; data.each { |words| add_row(words) }
    end
    def scrolled_win.selection() a=grid().selection.selected ; a ? a[0] : nil ; end
    def scrolled_win.index() grid().selection.selected end
    
    scrolled_win.add_with_viewport(treeview)
    autoslot(nil)
    slot(scrolled_win)
  end

  # create a tree view of data (as grid, but first column is a tree)
  # use set_data() to put a  Hash of data
  # same methods as grid widget
  # a columns Class are distinges by column name :
  # <li>  raster image if name start with  a '#'
  # <li>  checkbutton  if name start with  a '?'
  # <li>  Integer      if name start with  a '0'
  # <li>  String 		else
  def tree_grid(names,w=0,h=0,options={})
    scrolled_win = Gtk::ScrolledWindow.new
    scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    scrolled_win.set_width_request(w)	if w>0
    scrolled_win.set_height_request(h)	if h>0
    scrolled_win.shadow_type = Gtk::SHADOW_ETCHED_IN
    
    types=names.map do |name|
     case name[0,1]
      when "#" then Gdk::Pixbuf
      when "?" then TrueClass
      when "0".."9" then Integer
      else String
     end
    end
    model = Gtk::TreeStore.new(*types)
    
    treeview = Gtk::TreeView.new(model)
    treeview.selection.set_mode(Gtk::SELECTION_SINGLE)
    names.each_with_index do  |name,i|
      renderer,symb= *(
        if    types[i]==TrueClass then	 [Gtk::CellRendererToggle.new().tap { |r| r.signal_connect('toggled') { } },:win]
        elsif types[i]==Gdk::Pixbuf then [Gtk::CellRendererPixbuf.new,:active]
        elsif types[i]==Numeric then	 [Gtk::CellRendererText.new,:text]
        else 							 [Gtk::CellRendererText.new,:text]
        end
      )
      treeview.append_column(
        Gtk::TreeViewColumn.new( name.gsub(/^[#?0-9]/,""),renderer,{symb => i} )
      )
    end
    
    #------------- Build singleton
    
    def scrolled_win.init(types) @types=types end
    scrolled_win.init(types)
    def scrolled_win.tree() children[0].children[0] end
    def scrolled_win.model() tree().model end
    $ici=self
    def scrolled_win.get_data()	
      raise("tree.get_data() out of main thread!")if $__mainthread__ != Thread.current
      @ruiby_data
    end
    def scrolled_win.set_data(hdata,parent=nil,first=true)	
      raise("tree.set_data() out of main thread!")if $__mainthread__ != Thread.current
      if parent==nil && first
        @ruiby_data=hdata
        model.clear()
      end
      hdata.each do |k,v|
        case v
          when Array 
            set_row([k.to_s]+v,parent)
          when Hash 
            p=model.append(parent)
            p[0] =k.to_s
            set_data(v,p,false)
        end
      end
    end
    def scrolled_win.set_row(data,parent=nil)
      puts "treeview: raw data size nok : #{data.size}/#{data.inspect}" if data.size!=@types.size
      i=0
      c=self.model.append(parent)
      data.zip(@types) do |item,clazz|
        c[i]=if clazz==TrueClass then (item ? true : false)
          elsif clazz==Gdk::Pixbuf then $ici.get_pixbuf(item.to_s).tap {|a| p [item,clazz,a]}
          elsif clazz==Integer then item.to_i
          else item.to_s
        end
        i+=1
      end
    end
    def scrolled_win.selection() a=tree().selection.selected ; a ? a[0] : nil ; end
    def scrolled_win.index() tree().selection.selected end
    
    scrolled_win.add_with_viewport(treeview)
    autoslot(nil)
    slot(scrolled_win)
  end

  # TODO: test!
  def button_expand(text,initiale_state=false,options={},&b) 
    expander = Gtk::Expander.new(text)
    expander.expanded = initiale_state
    frame=box(&b)
    expander.add(frame)
    attribs(expander,options)
  end
  ######################## Dialog ##################

  # dialog_async("title",:response=> bloc {|dia,e| }) {
  #   flow { button("dd") ... }
  # }
  # Dialog content is build with bloc parameter.
  # Action on Ok/Nok/delete button make a call to :response bloc.
  # dialog is destoy if return value of :response is true
  #
  def dialog_async(title,config,&b) 
    dialog = Dialog.new("Message",
      self,
      Dialog::DESTROY_WITH_PARENT,
      [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
            [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])

    dialog.set_window_position(Window::POS_CENTER)
    
    @lcur << dialog.vbox
    hbox=stack { yield }
    @lcur.pop

    dialog.signal_connect('response') do |w,e|
      rep=config[:response].call(dialog,e)
      dialog.destroy if rep
    end
    dialog.show_all	
  end
  # dialog_sync("title") {
  #   flow { button("dd") ... }
  # }
  # Dialog contents is build with bloc parameter.
  # call is bloced until action on Ok/Nok/delete button 
  # return true if dialog quit is done by action on OK button

  def dialog(title="") 
    dialog = Dialog.new(title,
      self,
      Dialog::DESTROY_WITH_PARENT,
      [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
            [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])
      
    @lcur << dialog.vbox
    hbox=stack { yield }
    @lcur.pop
    
    dialog.set_window_position(Window::POS_CENTER)
    dialog.show_all	
    rep=dialog.run
    dialog.destroy
    rep
  end

  ###################################### Logs

  # put a line of message text in log dialog (create and show the log dialog if not exist)
  def log(*txt)
    if $__mainthread__ && $__mainthread__ != Thread.current
      gui_invoke { log(*txt) }
      return
    end
    loglabel=_create_log_window()
    loglabel.buffer.text +=  Time.now.to_s+" | " + (txt.join(" ").encode("UTF-8"))+"\n" 
    if ( loglabel.buffer.text.size>1000*1000)
      loglabel.buffer.text=loglabel.buffer.text[-7000..-1].gsub(/^.*\n/m,"......\n\n")
    end
  end
  def _create_log_window() 
    return(@loglabel) if defined?(@loglabel) && @loglabel && ! @loglabel.destroyed?
    wdlog = Dialog.new("Logs : #{$0}",
      nil,
      0,
      [ Stock::OK, Dialog::RESPONSE_NONE ])
    Ruiby.set_last_log_window(wdlog)
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

  ############################ define style !! Warning: specific to gtk
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

end

