# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

=begin
general definition of Ruiby DSL, for GTK3. 

Most of this ressource are not thread-safe : use ruiby in the context
of main thread (thread which invoke Ruiby.start).

Exception : in thread, theses methods are frequently used. so they are thread-protected,
if they detect a invocation out of main thread, they auto-recall in a gui_invoke block :
    append_to(cont,&blk)       clear_append_to(cont,&blk)
    slot_append_before(w,wref) slot_append_after(w,wref)
    delete(w) 
    log(txt)

=end
require_relative 'ruiby_default_dialog3'

module Ruiby_dsl
  include ::Gtk
  include ::Ruiby_default_dialog


  def _nocodeeeeeeeeeee() end


  # All Ruiby commands correspond of
  #   * a object creation (container, widget), see later,
  #   * complement set propertie to current/alst widget created : css_name(), space(), tooltip()
  #   * a immediate dialog (modal) command : 
  #   <ul>
  #       alert  ask ask_color ask_dir_to_read ask_dir_to_write ask_file_to_read  
  #       ask_file_to_write color_choice dialog dialog_async edit 
  #    </ul>
  #   * a immediate command, the can be used in callback code: gui manipulation... : 
  #   <ul>
  #       after  anim append_to apply_options  attribs autoslot chrome clear clear_append_to  
  #       color_conversion def_style def_style3 delete  force_update get_config  
  #       get_current_container get_icon get_image_from get_pixbuf get_stockicon_pixbuf 
  #       gui_invoke gui_invoke_in_window gui_invoke_wait  hide_app  log  on_destroy  
  #       rposition ruiby_component ruiby_exit  show_methods 
  #       slot_append_after slot_append_before sloti style threader  update 
  #    </ul>
  # 
  #
  # 2 kinds of objects :
  # * container
  #   <ul>
  #       accordion box  center flow flow_paned flowi frame framei  grid haccordion notebook  
  #       pclickable popup stack stack_paned stacki systray table var_box var_boxi vbox_scrolled 
  #    </ul>
  #    Containers organize children widget, but show (almost) nothing.
  #    Children must be created in container bloc, container can contains widget and container :
  #       <code><pre> 
  #       | stack do
  #       |   button("Hello")
  #       |   label(" word")
  #       |   flow { button("x") ; label("y") }
  #       | end
  #       </pre></code>
  # * widgets
  #   <ul>
  #       accordion aitem alabel box button  calendar canvas cell* center check_button  combo  dialog
  #       dialog_async  edit entry fentry field fields grid  haccordion  hradio_buttons htoolbar ientry image  
  #       islider label labeli list menu menu_bar menu_button menu_checkbutton menu_separator   page  
  #       pp_item pp_separator  properties   row   scrolled separator  show_methods  source_editor space 
  #       syst_add_button syst_add_check syst_add_sepratator syst_icon syst_quit_button 
  #       systray table text_area  toggle_button  tree_grid  vradio_buttons wtree
  #    </ul>
  #    Widget must be placed in a container.
  #    2 kinds of placement :
  #    <li>sloted  : widget take all disponible space ( gtk: pack(expand,fill) ), share
  #                 space with other sloted widget in same container
  #    <li>slotied : widget take only necessary place ( gtk: pack(no-expand , no-fill) ) 
  #
  #<pre><code>
  #   |------------------------|
  #   |<buttoni               >|
  #   |<labeli                >|
  #   |<--------------------- >|
  #   |<                      >|
  #   |<    button            >|
  #   |<                      >|
  #   |<--------------------- >|
  #   |<                      >|
  #   |<    label             >|
  #   |<                      >|
  #   |<--------------------- >|
  #   |<buttoni               >|
  #   |------------------------|
  #
  #</code></pre> 
  #    by default, all widgetcontainer are sloted !
  #    widget name ended by 'i' ( buttoni, labeli, stacki , flowi ...) are slotied
  #
  #    slot()  command is deprecated. sloti() command must be use if *i command 
  #    do not exist  :  w=sloti( widgetname() {...} )
  #    space() can be used for slot a ampty space
  #
  # Attachement :
  # <li> scoth xxxx in top of frame    : >stack { stacki { xxx } ; stack { } }
  # <li> scoth xxxx in bottom of frame : >stack {  stack { } ; stacki { xxx } }
  # <li> scoth xxxx in left of frame   : >flow { flowi { xxx } ; stack { } }
  #
  def aaa_generalities()
  end
  
  ############################ Slot : H/V Box or Frame

  # container : vertical box, take all space available, sloted in parent by default
  def stack(config={},add1=true,&b)       _cbox(true,Box.new(:vertical, 2),config,add1,&b) end
  # container : horizontal box, take all space available, sloted in parent by default
  def flow(config={},add1=true,&b)        _cbox(true,Box.new(:horizontal, 2),config,add1,&b) end
  # container : vertical or horizontal box (stack/flow, choice by first argument), 
  # sloted in parent by default
  def var_box(sens,config={},add1=true,&b) _cbox(true,Box.new(sens, 2),config,add1,&b) end
  # container : vertical box, take only necessary space , sloted in parent
  def stacki(config={},add1=true,&b)      _cbox(false,Box.new(:vertical, 2),config,add1,&b) end
  # container : horizontal box, take only necessary space , sloted in parent
  def flowi(config={},add1=true,&b)       _cbox(false,Box.new(:horizontal, 2),config,add1,&b) end
  # container : vertical or horizontal box (stacki/flowi, choice by first argument), 
  # sloted in parent by default
  def var_boxi(sens,config={},add1=true,&b) _cbox(false,Box.new(sens, 2),config,add1,&b) end

  # box { } container which manage children widget without slot (pack()) 
  # in parent container.
  # Use it for cell in table, notebook  : table { row { cell(box { });... }; ... }
  def box() 
    box=Gtk::Box.new(:vertical,2)
    @lcur << box
    yield
    autoslot()
    @lcur.pop
  end
  
  # set homogeneous contrainte on current container :
  # all chidren whill have same size
  # * stack : children will have same height
  # * flow :   children will have same width
  def regular(on=true) @lcur.last.homogeneous=on end
 
  # set space between each chidren of current box
  def spacing(npixels=0) @lcur.last.spacing=npixels end
    
  # center { }  container which center his content (auto-sloted)
  # TODO : tested!
  def center() 
    autoslot()
    valign = Gtk::Alignment.new(0,0,0,0)
    @lcur.last.pack_start(valign, :expand => true, :fill => false, :padding => 0)
    vbox=Box.new(:vertical, 0)
    valign.add(vbox)
    @lcur << vbox
    yield
    autoslot()
    @lcur.pop
  end
  # TODO : not tested!
  def left(&blk) 
    autoslot()
    w=yield
    halign = Gtk::Alignment.new(0,0,0,0)
    halign.add(w)
    @lcur.last.pack_start(halign, :expand => false, :fill => false, :padding => 3)
    razslot()
  end
  # TODO : not tested!
  def right(&blk) 
    autoslot()
    w=yield
    halign = Gtk::Alignment.new(1,0,0,0)
    halign.add(w)
    @lcur.last.pack_start(halign, :expand => false, :fill => false, :padding => 3)
    razslot()
  end
  def update() Ruiby.update() end
  
  # a box with border and texte title, take all space
  def frame(t="",config={},add1=true,&b)    
    w=_cbox(true,Frame.new(t),config,add1) { s=stack { b.call } ; s.set_border_width(5) } 
  end
  # a box with border and texte title, take only necessary space
  def framei(t="",config={},add1=true,&b)
    _cbox(false,Frame.new(t),config,add1) { s=stack { b.call } ; s.set_border_width(5) }
  end

  # private: generic packer
  def _cbox(expand,box,config,add1)
    autoslot() # pack last widget before append new bow
    parent=@lcur.last
    if add1
     _pack(parent,box,expand)
    end
    @lcur << box
    yield
    autoslot() # pack last widget before closing box
    @lcur.pop 
    apply_options(box,config) 
  end
  def _pack(parent,box,expand)
     parent.respond_to?(:pack_start) ? 
          parent.pack_start(box, :expand => expand, :fill => true): 
          parent.add(box) 
  end
  # pack widget in parameter, share space with prother widget
  # this is the default: all widget will be sloted if they are not slotied
  # this is done by attribs(w) which is call after construction of almost all widget
  def slot(w)  @current_widget=nil; _pack(@lcur.last,w,true) ; w end
  
  # pack widget in parameter, take only necessary space
  def sloti(w) @current_widget=nil; @lcur.last.pack_start(w, :expand => false, :fill => false, :padding => 3) ; w end

  # slot() precedently created widget if not sloted.
  # this is done by attribs(w) which is call after construction of almost all widget
  def autoslot(w=nil)
    (slot(@current_widget)) if @current_widget!=nil
    @current_widget=w 
  end
  # forget precedent wdget oconstructed
  def razslot() @current_widget=nil; end

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
  
  # give a name to last widget created. Useful for css style declaration
  def css_name(name)  @current_widget ? @current_widget.set_name(name) : error("cssname #{name}: there are no current widget!") end 

  # give a tooltip to last widget created. 
  def tooltip(value="?") 
    if @current_widget && value && value.size>0
      @current_widget.set_tooltip_markup(value) 
      @current_widget.has_tooltip=true
    else
      error("tooltip #{value}: there are no current widget!") 
    end
  end

  ########################### raster images access #############################

  def get_icon(name)
    return name if name.index('.') && File.exists?(name)
    iname=eval("Gtk::Stock::"+name.upcase) rescue nil
  end
  # Image#initialize(:label => nil, :mnemonic => nil, :stock => nil, :size => nil)'
  def get_stockicon_pixbuf(name)
    Image.new(:label => nil, :mnemonic => nil, :stock => eval("Gtk::Stock::"+name.upcase), :size => :button).pixbuf
  end

  # get a Image widget from a file or from a Gtk::Stock
  # image can be a filename or a predefined icon in GTK::Stock
  # for file image, whe can specify a sub image (sqared) :
  #     filename.png[NoCol , NoRow]xSize
  #     filename.png[3,2]x32 : extract a icon of 32x32 pixel size from third column/second line
  #    see samples/draw.rb
  def get_image_from(name,size=:button)
    if name.index('.') 
      return Image.new(name) if File.exists?(name)
      return _sub_image(name) if name.index("[")
      alert("unknown icone #{name}")
    end
    iname=get_icon(name)
    if iname
      Image.new(:stock => iname,:size=> size)
    else
      nil
    end
  end
  def _sub_image(name)
    Image.new(get_pixbuf(name))
  end
  def get_pixbuf(name)
    @cach_pix={} unless defined?(@cach_pix)
    if @cach_pix.size>100
      puts "purge cach pixbuf"
      @cach_pix={}
    end
    filename,px,py,bidon,dim=name.split(/\[|,|(\]x)/)
    if filename && px && py && bidon && dim && File.exist?(filename)
      dim=dim.to_i
      @cach_pix[filename]=Gdk::Pixbuf.new(filename) unless @cach_pix[filename]
      x0= dim*px.to_i
      y0= dim*py.to_i
      #p [x0,y0,"/",@cach_pix[filename].width,@cach_pix[filename].height]
      Gdk::Pixbuf.new(@cach_pix[filename],x0,y0,dim,dim)
    elsif File.exists?(name)
      unless @cach_pix[name]
        px=Gdk::Pixbuf.new(name) rescue error($!)
        @cach_pix[name]=px if px
      end
      @cach_pix[name]
    elsif ! name.index(".")
      get_stockicon_pixbuf(name)
    else
      raise("file #{name} not exist");
    end
  end

  ############### Commands

  # common widget property  applied for (almost) all widget. 
  # options are last argument of every dsl command, see apply_options
  def attribs(w,options)
      #p options if options && options.size>0
      apply_options(w,options)
      autoslot(w)  # slot() precedent widget if exist and not already sloted, and declare this one as the precedent
      w
  end
  # apply some styles  property  to an existing widget. 
  # options are :size, :width; :height, :margins, :bg, :fg, :font
  # apply_options(w,
  #   :size=> [10,10], 
  #   :width=>100, :heigh=>200,
  #   :margins=> 10
  #   :bg=>'#FF00AA",:fg=> Gdk::Color:RED,
  #   :font=> "Tahoma bold 32"
  # )
  def apply_options(w,options)
      w.set_size_request(*options[:size])                                 if options[:size] 
      w.set_border_width(options[:margins])                               if options[:margins]  
      w.width_request=(options[:width].to_i)                              if options[:width]
      w.height_request=(options[:height].to_i)                            if options[:height]
      w.override_background_color(:normal,color_conversion(options[:bg])) if options[:bg] 
      w.override_color(:normal,color_conversion(options[:fg]))            if options[:fg] 
      w.override_font(Pango::FontDescription.new(options[:font]))         if options[:font]
      w
  end
  def color_conversion(color)
    case color 
      when ::Gdk::RGBA then color
      when String then color_conversion(::Gdk::Color.parse(color))
      when ::Gdk::Color then ::Gdk::RGBA.new(color.red/65000.0,color.green/65000.0,color.blue/65000.0,1)
      else
        raise "unknown color : #{color.inspect}"
    end
  end
  # parse color from #RRggBB html format
  def html_color(str) ::Gdk::Color.parse(str) end
   
  def widget_properties(title=nil,w=nil) 
    widg=w||@current_widget||@lcur.last
    p get_config(widg)
    properties(title||widg.to_s,{},get_config(widg)) 
  end
  
  # create a bar (vertical or horizontal according to stack/flow current container) 
  def separator(width=1.0)  
    autoslot()
    sloti( Separator.new(
      @lcur.last.orientation==Gtk::Orientation::VERTICAL ? 
        Gtk::Orientation::HORIZONTAL : Gtk::Orientation::VERTICAL))  
  end

  # create  label, with text (or image if txt start with a '#')
  # spatial option : isize : icon size if image (menu,small_toolbar,large_toolbar,button,dnd,dialog)
  def label(text,options={})
    l=_label(text,options)
    attribs(l,options)
  end
  def labeli(text,options={}) sloti(label(text,options)) end 
  
  def _label(text,options={})
    l=if text && text[0,1]=="#"
      get_image_from(text[1..-1],options[:isize]||:button);
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
  def spacei(n=1) labeli(([" "*n]*n).join("\n"))  end
  def bourrage(n=1) n.times { sloti(labeli("    ")) }  end

  # create  button, with text (or image if txt start with a '#')
  # block argument is evaluate at button click
  def button(text,option={},&blk)
    if text && text[0,1]=="#"
      b=Button.new(:label => "", :mnemonic => nil, :stock_id => nil)
      b.set_image(get_image_from(text[1..-1]))
    else
      b=Button.new(:label => text, :mnemonic => nil, :stock_id => nil);
    end
    b.signal_connect("clicked") { |e| blk.call(e) rescue error($!) } if blk
    apply_options(b.child,option)
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
        Gtk::ToolButton.new(:stock_id => iname).tap { |but|
          but.signal_connect("clicked") { v.call rescue error($!) } if v
          but.set_tooltip_text(tooltip) if tooltip
        }
      elsif name=~/^sep/i
        Gtk::SeparatorToolItem.new        
      elsif name=~/^right-(.*)/i
        Gtk::ToolButton.new(:stock_id => get_icon($1)).tap { |but|
          but.signal_connect("clicked") { v.call rescue error($!) } if v
          but.set_tooltip_text(tooltip) if tooltip
        }
      else
        puts "=======================\nUnknown icone : #{name}\n====================="
          puts "Icones dispo: #{Stock.constants.map { |ii| ii.downcase }.join(", ")}"
        Gtk::ToolButton.new(:stock_id => Stock::MISSING_IMAGE)
      end
      if w
        b.insert(w,i)
      end
      i+=1
     }
    attribs(b,options)
  end 
  
  # horizontal toolbar of (icone+text)
  # Usage 1:
  # htoolbar_with_icontext("dialog_info/text info" => proc {alert(1)},"dialog_error/text error" => proc {alert(2)} )
  # Usage 2 :
  # htoolbar_with_icon_text do
  #  button_icon_text "dialog_info","text info" do alert(1) end
  #  button_icon_text "dialog_error","text error" do alert(2) end
  # end
  # if icone name start with 'sep' : a vertical separator is drawn in place of touch
  # see sketchi
  def htoolbar_with_icon_text(conf={})
    if  block_given?
      flowi {
        yield
      }
    else
      flowi {
        conf.each do |k,v|
           icon,text=k.split('/',2)
           if icon !~ /^sep/
              spacie
              pclickablie(proc { v.call  }) { stacki { 
                  label("#"+icon,isize: :dialog) do v.call end 
                  label text[0,12] 
             } }
           else
              separator
           end
        end
      }
    end
  end
  # a button with icon+text vertivcaly aligned,
  # can be call anywhere, and in htool_bar_with_icon_text
  # option is label options and  isize ( option for icon size, see label())
  def button_icon_text(icon,text="",options={},&b)
       if icon !~ /^sep/
          spacie
          pclickablie(proc { b.call  }) { stacki { 
              label("#"+icon,{isize: (options[:isize] || :dialog) }) 
              label(text[0,15],options)
         } }
       else
          separator
       end
  end
  ############### Inputs widgets

  #combo box, decribe  with a Hash choice-text => value-of-choice
  # choices: array of text choices
  # dfault : text activate or index of text in array
  # bloc ! called when a choice is selected
  #
  # Usage :  combo(%w{aa bb cc},"bb") { |text;index| alert("the choice is #{text} at #{index}") }
  #
  def combo(choices,default=nil,option={},&blk)
    w=ComboBoxText.new()
    choices=choices.inject({}) { |h,k| h[k]=h.size ; h} if Array===choices
    choices.each do |text,indice|  
      w.append_text(text) 
    end
    if default
        if String==default
          w.set_active(choice[default]) 
        else
          w.set_active(default) 
        end
    end
    w.signal_connect(:changed) { |w,evt|
      blk.call(w.active_text,choices[w.active_text])
    } if blk    
    attribs(w,option)   
    class << w
      def choices()
          []
      end
      def choices=(h)
         clear
         h.keys.each { |k| append_text(k) }
      end
    end
    w
  end

  # to state button, with text for each state and a initiale value
  # value can be read by w.active?
  # calue can be changed by w.set_active(true/false)
  # callback on state change with new value as argument
  def toggle_button(text1,text2=nil,value=false,option={},&blk)
    text2 = "- "+text1 unless text2
    b=ToggleButton.new(text1);
    b.signal_connect("clicked") do |w,e| 
      w.label= w.active?() ? text2.to_s : text1.to_s 
      ( blk.call(w.active?()) rescue error($!) ) if blk
    end
    b.set_active(value)
    b.label= value ? text2.to_s : text1.to_s 
    attribs(b,option)   
    b
  end
  # create a checked button
  # state can be read by cb.active?
  def check_button(text="",value=false,option={},&blk)
    b=CheckButton.new(text)
    b.set_active(value)
    b.signal_connect("clicked") do |w,e| 
      ( blk.call(w.active?()) rescue error($!) ) if blk
    end
    attribs(b,option)
    b
  end
  # create a liste of radio button, horizontaly disposed
  # value is the indice of active item (0..(n-1)) at creation time
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

  # create a liste of radio button, vertically disposed
  # value is the indice of active item (0..(n-1)) at creation time
  # define 2 methods:
  # * get_selected         # get indice of active radio-button
  # * set_selected(indice) # set indice of active radio-button
  def vradio_buttons(ltext=["empty!"],value=-1) _radio_buttons(:vertical,ltext,value) end
  # as vradio_buttons , but horizontaly disposed
  def hradio_buttons(ltext=["empty!"],value=-1) _radio_buttons(:horizontal,ltext,value) end
  
  def _radio_buttons(sens,ltext=["empty!"],value=-1)
    b0=nil
    s=var_box(sens,{},false) {
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
    # TODO: test!
    class << s
      ;  def get_selected()
        b0.group.each_with_index.map { |w,index| return(index) if w.active? }
      end
     ;  def set_selected(indice)
        b0.group.each_with_index.map { |w,index| w.active=true if indice==index }
      end
    end
    s
  end
  # create a text entry for keyboard input
  # if block defined, it while be trigger on eech of (character) change of the entry
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
    w=SpinButton.new(option[:min].to_i,option[:max].to_i,option[:by]||1)
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
  
  # show a label and a entry in a  flow. entrey widget is returned
  # see fields()
  def field(tlabel,width,value,option={},&blk)
    e=nil
    flow {
      l=label(tlabel+ " : ")
      l.width_chars=width+3
      e=entry(value,option,&blk)
    }
    e
  end
  
  # show a stack of label/entry and buttons validation/annulation
  # on button, bloc is invoked with the list of values of entrys
  def fields(alabel=[["nothing",""]],option={},&blk)   
    size=alabel.map {|t| t[0].size}.max
    stack do
      le=alabel.map { |(label,value)| field(label,size,value) }
      if block_given?
          flowi {
            button("Validation") { blk.call(*le.map {|t| t.text}) }
            button("Annulation") { blk.call(*le.map {|t| nil}) }
          }
      end
    end
  end
  
  # create a slider
  # option must define :min :max :by for spin button
  # current value can be read by w.value
  # if bloc is given, it with be call on each change, with new value as parameter
  def islider(value=0,option={},&b)
    w=Scale.new(:horizontal,(option[:min]||0).to_i,(option[:max]||100).to_i,option[:by]||1)
    w.set_value(value ? value.to_i : 0)
    w.signal_connect(:value_changed) { || b.call(w.value)  rescue error($!) } if block_given?
    attribs(w,option)   
  end

  # create a button wich will show a dialog for color choice
  # if bloc is given, it with be call on each change, with new color value as parameter
  # current color is w.get_color()
  def color_choice(text=nil,options={},&cb)
    but,lab=nil,nil
    out=flow { 
      but = button((text||"Color?...").to_s) do
        c=ask_color    
        apply_options(lab,{bg: c}) if c
        cb.call(c) if block_given? 
      end
      lab=label("  c    ")
    }
    attribs(but,options)    
    def out.get_color()
       chilldren[1].get_color()
    end
    out
  end

  # Create a drawing area, for pixel draw
  # option can define closure :mouse_down :mouse_up :mouse_move
  # for interactive actions
  # See test.rb fo little example.
  # See samples/draw.rb for a little vector editor...
  def canvas(width,height,option={})
    autoslot()
    w=DrawingArea.new()
    w.width_request=width
    w.height_request=height
    w.events |=  ( ::Gdk::Event::Mask::BUTTON_PRESS_MASK | ::Gdk::Event::Mask::POINTER_MOTION_MASK | ::Gdk::Event::Mask::BUTTON_RELEASE_MASK)

    w.signal_connect(  'draw' ) { |w1,cr| 
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
           after(3000) {  puts "reset expose bloc" ;option[:expose] = nil }
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
    def w.redraw() 
      self.queue_draw_area(0,0,self.width_request,self.height_request)
    end
    w
  end
  # update a canvas
  def force_update(canvas) canvas.queue_draw unless  canvas.destroyed?  end

  #  define a plot zone, with several curves :
  #  pl=plot(400,200,{
  #      "curve1" => {
  #         data:[[0,1],[110,1],[20,1],[30,1],[10,1],[22,1],[55,1],[77,1]],
  #         color: '#FF0000', xminmax:[0,100], yminmax:[0,100], style: :linear,},...})
  #  }
  #
  # this methods are added :
  # * pl.set_data(name,data) : replace current values par a new list of point [ [y,x],....] for curve named 'name'
  # * pl.get_data(name) 
  # * pl.add_data(name,pt)  : add a point at the end of the curve
  # * pl.scroll_data(name,value)  : add a point at last and scroll if necessary (act as oscilloscope)
  # see samples/plot.rb
  def plot(width,height,curves,config={})
     cv=canvas(width,height,
          :mouse_down => proc do |w,e|   
          end,
          :expose => proc do |w,ctx|  cv.expose(ctx) end
     )
     def cv.add_curve(name,config) 
        c=config.dup
        c[:data] ||= [[0,0],[100,100]]
        c[:maxlendata] ||= 100
        c[:color] ||= "#003030"
        c[:xminmax] ||= [c[:data].first[1],c[:data].last[1]]
        c[:yminmax] ||= [0,100]
        c[:style] ||= :linear
        c[:xa] = 1.0*width_request/(c[:xminmax][1]-c[:xminmax][0])
        c[:xb] = 0.0    -c[:xminmax][0]*c[:xa]
        c[:ya] = 1.0*height_request/(c[:yminmax][0]-c[:yminmax][1])
        c[:yb] = 1.0*height_request+c[:yminmax][0]*c[:xa]
        @curves||={}
        @curves[name]=c
     end
     def cv.expose(ctx) 
        @curves.values.each do |c|
              next if c[:data].size<2
              l=c[:data].map { |(y,x)|  [x*c[:xa]+c[:xb] , y*c[:ya]+c[:yb] ]  }
              coul=c[:rgba]
              ctx.set_source_rgba(coul.red,coul.green,coul.blue)
              ctx.move_to(*l[0])
              l[1..-1].each { |pt| ctx.line_to(*pt) }
              ctx.stroke
        end
     end
     
     def cv.set_data(name,data) 
       @curves[name][:data]=data
       maxlen(name,@curves[name][:maxlendata])
       redraw
     end
     def cv.get_data(name) 
       @curves[name][:data]
     end
     def cv.add_data(name,pt) 
       @curves[name][:data] << pt
       maxlen(name,@curves[name][:maxlendata])
       redraw
     end
     def cv.scroll_data(name,value) 
        l=@curves[name][:data]
        pas=width_request/l.size
        l.each { |pt| pt[1]-=pas } 
        l << [ value , @curves[name][:xminmax].last ]
        maxlen(name,@curves[name][:maxlendata])
        redraw
     end
     def cv.maxlen(name,len)
       @curves[name][:data]=@curves[name][:data][-len..-1] if @curves[name][:data].size>len
     end
     curves.each { |name,descr| descr[:rgba]=color_conversion(descr[:color]||'#303030') ; cv.add_curve(name,descr) }
     cv
  end
  ############################ table
  # create a container for table-disposed widgets. this is not a grid!
  # table(r,c) { row { cell(w) ; .. } ; ... }
  def table(nb_col,nb_row,config={})
    table = Gtk::Table.new(nb_row,nb_col,false)
    table.set_column_spacings(config[:set_column_spacings]) if config[:set_column_spacings]
    @lcur << table
    @ltable << { :row => 0, :col => 0}
    yield
    @ltable.pop
    @lcur.pop
    attribs(table,config)
  end
  # create a row. must be defined in a table closure  
  # Closure argment should only contain cell(s) call.
  # many cell type are disponibles : cell cell_bottom cell_hspan cell_hspan_left 
  # cell_hspan_right cell_left cell_pass cell_right cell_span cell_top cell_vspan 
  # cell_vspan_bottom cell_vspan_top
  # row do
  #    cell( label("ee")) ; cell_hspan(3, button("rr") ) }
  # end
  def row()
    autoslot()
    @ltable.last[:col]=0 # will be increment by cell..()
    yield
    @ltable.last[:row]+=1
  end 
  # a cell in a row/table. take all space, centered
  def  cell(w)  cell_hspan(1,w)   end
  # a cell in a row/table. take space of n cells, horizontaly
  def  cell_hspan(n,w) cell_hvspan(n,0,w) end 
  # a cell in a row/table. take space of n cells, verticaly
  def  cell_vspan(n,w) cell_hvspan(0,n,w) end 
  # a cell in a row/table. take space of n x m cells, horizontaly x verticaly 
  def  cell_hvspan(n,m,w) 
    razslot();
    @lcur.last.attach(w,
       @ltable.last[:col],@ltable.last[:col]+n,
       @ltable.last[:row],@ltable.last[:row]+m+1
    )  
    @ltable.last[:col]+=n
    @ltable.last[:row]+=m
  end 
  # keep empty n cell consecutive on current row
  def  cell_pass(n=1)  @ltable.last[:col]+=n end
  # a cell in a row/table. take space of n cells, horizontaly
  def  cell_span(n=2,w) cell_hspan(n,w) end

  # create a cell in a row/table, left justified
  def cell_left(w)     razslot();w.set_alignment(0.0, 0.5) rescue nil; cell(w) end
  # create a cell in a row/table, right justified
  def cell_right(w)    razslot();w.set_alignment(1.0, 0.5)rescue nil ; cell(w) end

  # create a hspan_cell in a row/table, left justified
  def cell_hspan_left(n,w)   razslot();w.set_alignment(0.0, 0.5)rescue nil ; cell_hspan(n,w) end
  # create a hspan_cell in a row/table, right justified
  def cell_hspan_right(n,w)  razslot();w.set_alignment(1.0, 0.5)rescue nil ; cell_hspan(n,w) end

  # create a cell in a row/table, top aligned
  def cell_top(w)      razslot();w.set_alignment(0.5, 0.0)rescue nil ; cell(w) end
  # create a cell in a row/table, bottom aligned
  def cell_bottom(w)   razslot();w.set_alignment(0.5, 1.0)rescue nil ; cell(w) end
  # a cell_vspan aligned on top
  def cell_vspan_top(n,w)    razslot();w.set_alignment(0.5, 0.0)rescue nil ; cell_vspan(n,w) end
  # a cell_vspan aligned on bottom
  def cell_vspan_bottom(n,w) razslot();w.set_alignment(0.5, 1.0)rescue nil ; cell_vspan(n,w) end

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
      l = Image.new(:stock => get_icon(icon[1..-1]),:size => :button); 
    else
      l=Label.new(title)
    end 
    @lcur.last.append_page( box { yield }, l )
  end

  ############################## Popup
  # create a dynamic popup. (shoud by calling in a closure)
  # popup block can be composed by pp_item and pp_separator
  # Exemple :
  # popup { pp_item("text") { } ; pp_seperator ; pp_item('Exit") { exit!(0)} ; ....}
  def popup(w=nil)
    w ||= @lcur.last() 
    ppmenu = Gtk::Menu.new
    @lcur << ppmenu 
    yield
    @lcur.pop
    ppmenu.show_all   
    w.add_events(Gdk::Event::Mask::BUTTON_PRESS_MASK)
    w.signal_connect("button_press_event") do |widget, event|
      ( ppmenu.popup(nil, nil, event.button, event.time) { |menu, x, y, push_in| [event.x_root,event.y_root] } ) if (event.button == 3)
    end
    ppmenu
  end
  # a button in a popup
  def pp_item(text,&blk)
    item = Gtk::MenuItem.new(text)
    item.signal_connect('activate') { |w| blk.call() }
    @lcur.last.append(item)
  end
  # a bar separator in a popup
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
  # create a horizontral accordion menu.  
  # must contain aitem() which must containe alabel() :
  # accordion { aitem(txt) { alabel(lib) { code }; ...} ... }
  def haccordion() 
    @slot_accordion_active=nil #only one accordion active by window!
    w=flow { flowi {
      yield
    }}
    separator
    w
  end
  #  a button menu in accordion
  #  bloc is evaluate for create/view a list of alabel :
  #  aitem(txt) { alabel(lib) { code }; ...}
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

  # create a button-entry  in a  accordion menu
  # bloc is evaluate on user click. must be in aitem() bloc :
  # accordion { aitem(txt) { alabel(lib) { code }; ...} ... }
  def alabel(txt,&blk)
    l=nil
    pclickable(proc { blk.call(l) if blk} ) { l=label(txt) }
  end

  ############################## Panned : 
  
  # create a container which can containe 2 widgets, separated by movable bar
  # block invoked must create 2 widgets, vertivaly disposed
  def stack_paned(size,fragment,&blk) _paned(false,size,fragment,&blk) end

  # create a container which can containe 2 widgets, separated by movable bar
  # block invoked must create 2 widgets,horizonaly disposed
  def flow_paned(size,fragment,&blk) _paned(true,size,fragment,&blk) end

  def _paned(horizontal,size,fragment)    
    s=stack {} # create a temporary container for inner widgets
    @lcur << s
    yield()
    autoslot
    @lcur.pop
    
    raise("panned : must contain only 2  children") if s.children.size!=2
    
    frame1,frame2=*s.children

    (frame1.shadow_type = :in)  rescue nil
    (frame2.shadow_type = :in)  rescue nil
    
    paned = Paned.new(horizontal ? :horizontal : :vertical)
    paned.position=size*fragment
    horizontal ? paned.set_size_request(size, -1) : paned.set_size_request(-1,size)
    
    s.remove(frame1)
    s.remove(frame2)
    s.parent.remove(s)
    paned.pack1(frame1, :resize => true, :shrink => false)
    paned.pack2(frame2, :resize => true, :shrink => false)
    slot(paned)
  end

  ##################### source editor

  # a source_editor widget : text as showed in fixed font, colorized (default: ruby syntaxe)
  # from: green shoes plugin
  # options= :width  :height :on_change :lang :font
  # @edit=source_editor().editor
  # @edit.buffer.text=File.read(@filename)
  def source_editor(args={}) 
    #return(nil) # loading gtksourceview3 scratch application...
    begin
      require 'gtksourceview3'
    rescue Exception => e
      log('gtksourceview3 not installed!, please use text_area')
      puts '******** gtksourceview3 not installed!, please use text_area ************' 
      return
    end
    args[:width]  = 400 unless args[:width]
    args[:height] = 300 unless args[:height]
    change_proc = proc { }
    (change_proc = args[:on_change]; args.delete :on_change) if args[:on_change]
    sv = GtkSource::View.new
    sv.show_line_numbers = true
    sv.insert_spaces_instead_of_tabs = false
    sv.smart_home_end = :always
    sv.tab_width = 4
    sv.buffer.text = (args[:text]||"").to_s
    sv.buffer.language = GtkSource::LanguageManager.new.get_language(args[:lang]||'ruby')
    sv.buffer.highlight_syntax = true
    sv.override_font(  Pango::FontDescription.new(args[:font] || "Courier new 10")) 
    cb = ScrolledWindow.new
    cb.define_singleton_method(:editor) { sv }
    cb.define_singleton_method(:text=) { |t| sv.buffer.text=t }
    cb.define_singleton_method(:text) {  sv.buffer.text }

    cb.set_size_request(args[:width], args[:height])
    cb.set_policy(:automatic, :automatic)
    cb.set_shadow_type(:in)
    cb.add(sv)
    cb.show_all
    attribs(cb,{})  
  end

  # multiline entry
  # w=text_area(min_width,min_height,options) 
  #
  # Some binding are defined :
  # * w.text_area          ; get text area widdget (w is a ScrolledWindow)
  # * w.text=""            ; set content
  # * puts w.text()        ; get content
  # * w.append("data \n")  ; append conent to the end of current content
  # * w.text_area.wrap_mode = :none/:word
  def text_area(w=200,h=100,args={}) # from green_shoes app
      tv = Gtk::TextView.new
      tv.wrap_mode = :word
      tv.buffer.text = args[:text].to_s if args[:text]
      tv.override_font(Pango::FontDescription.new(args[:font])) if args[:font]
      tv.accepts_tab = true

      eb = Gtk::ScrolledWindow.new
      eb.set_size_request(w,h) 
      eb.add(tv)
      eb.define_singleton_method(:text_area) { tv }
      class << eb
      ; def text=(a)  self.children[0].buffer.text=a.to_s.encode("UTF-8") end
      ; def text()    self.children[0].buffer.text end
      ; def append(a) self.children[0].buffer.text+=a.to_s.encode("UTF-8") end
      ; def buffer()  self.children[0].buffer end
      ; def tv()      self.children[0] end
      end
      eb.show_all
      args.delete(:text)
      args.delete(:font)
      attribs(tv,args)  
      attribs(eb,args)  
  end 

  ############################# calendar

  # Month Calendar with callback on month/year move and day selection :
  # calendar(Time.now-24*3600, :selection => proc {|day| } , :changed => proc {|widget| }
  # calendar respond to
  # * set_time(time)  ; set a selected date from a Time object
  # * get_time()      ; return Time of selected day
  def calendar(time=Time.now,options={})
    c = Calendar.new
    #c.display_options(Calendar::SHOW_HEADING | Calendar::SHOW_DAY_NAMES |  
    #        Calendar::SHOW_WEEK_NUMBERS )
    after(1) { c.signal_connect("day-selected") { |w,e| options[:selection].call(w.day)  rescue error($!) } } if options[:selection]
    after(1) { c.signal_connect("month-changed") { |w,e| options[:changed].call(w)  rescue error($!) } }if options[:changed]
    class << c
    ;  def set_time(time)
        select_month(time.month,time.year)
        select_day(time.day)
      end
    ;  def get_time()
        year, month, day= *date() 
        Time.local(year, month, day) 
      end
    end
    c.set_time(time)
    attribs(c,options)

  end
  
  # Show a video in a gtk widget.
  # * if block is defined, it is invoked on each video progression (from 0 to 1.0)
  # * w.play
  # * w.stop
  # * w.uri= "foo.avi"
  # *.progress=n    force current position in video (0..1)
  #
  #  video() need the gems clutter, GStreamer, and glues Clutter<=>Gtk : "clutter-gtk" and "clutter-gst" 
  #  * gem install clutter-gtk 
  #  * gem install clutter-gstreamer
  #
  def video(uri=nil,w=300,h=200,&blk)
    require "clutter-gtk"  
    require "clutter-gst"  # gem install clutter-gstreamer
    clutter = ClutterGtk::Embed.new
    video=ClutterGst::VideoTexture.new
    clutter.stage.add_child(video)
    video.width=w
    video.height=h
    video.uri = uri if uri
    video.playing = false
    isNotify=false
    clutter.define_singleton_method(:uri=) { |uri| video.uri = uri }
    clutter.define_singleton_method(:play) { video.playing = true }
    clutter.define_singleton_method(:stop) { video.playing = false }
    clutter.define_singleton_method(:progress=) { |pp|  video.progress=(pp) unless isNotify }
    if block_given?
      video.signal_connect("notify") { |o,v,param|  isNotify=true ; yield(video.progress()) rescue p $! ; isNotify=false }
    end
    attribs(clutter,{})
  end

  ######### Scrollable stack container

  # create a Scrolled widget with a autobuild stack in it
  # stack can be populated 
  # respond to : scroll_to_top; scroll_to_bottom,
  def scrolled(width,height,&b)  vbox_scrolled(width,height,&b) end
  def vbox_scrolled(width,height,&b)
    sw=ScrolledWindow.new()
    slot(sw)
    sw.set_width_request(width)   if width>0 
    sw.set_height_request(height) if height>0
    sw.set_policy(:automatic, :always)
    ret= box(&b) if  block_given? 
    sw.add_with_viewport(ret)
    class << sw
    ;  def scroll_to_top()    vadjustment.set_value( 0 )          ; vadjustment.value_changed ; end
    ;  def scroll_to_bottom() vadjustment.set_value( vadjustment.upper - 100); vadjustment.value_changed ; end
      #def scroll_to_left()   hadjustment.set_value( 0 ) end
      #def scroll_to_right()  hadjustment.set_value( hadjustment.upper-1 ) end
    end
    attribs(sw,{})
  end 
  
  # Create a horizontal bar with a stick which can be moved.
  # block (if defined) is invoked on each value changed
  # w.proess=n can force current position at n
  #
  def slider(start=0.0,min=0.0,max=1.0,options={})
   w=Gtk::Scale.new(:horizontal)
   w.set_range min,max
   w.set_size_request 160, 35
   w.set_value start
   w.signal_connect("value-changed") { |w| yield(w.value) } if block_given?
   w.define_singleton_method(:progress=) { |value| w.set_value(value) }
   attribs(w,{})
  end
  
  # Show the evolution if a numeric value. Evolution is a number between 0 and 1.0
  # w.progress=n  force current evolution 
  def progress_bar(start=0,options)
   w=Gtk::ProgressBar.new
   w.define_singleton_method(:progress=) { |fract| w.fraction=fract }
   w.fraction=start
   attribs(w,{})
  end
  
  # specific to gtk : some widget like label can't support click event, so they must
  # be contained in a clickable parent (EventBox)
  #  
  # Exemple: clickable(:callback_click_name) { label(" click me! ") }
  #
  # click callback  is definied by a method name.
  # see pclickable for callback by closure.
  def clickable(method_name,&b) 
    eventbox = Gtk::EventBox.new
    eventbox.events =Gdk::Event::Mask::BUTTON_PRESS_MASK
    ret=_cbox(true,eventbox,{},true,&b) 
    eventbox.realize
    eventbox.signal_connect('button_press_event') { |w, e| self.send(method_name,ret)  rescue error($!) }
    ret
  end

  # specific to gtk : some widget like label can't support click event, so they must
  # be contained in a clickable parent (EventBox)
  #
  # Exemple: pclickable(proc { alert true}) { label(" click me! ") }
  #
  # bloc is evaluated in a stack container
  def pclickable(aproc=nil,options={},&b) 
    eventbox = Gtk::EventBox.new
    eventbox.events = Gdk::Event::Mask::BUTTON_PRESS_MASK
    ret=_cbox(true,eventbox,{},true,&b) 
    eventbox.realize
    eventbox.signal_connect('button_press_event') { |w, e| aproc.call(w,e)  rescue error($!)  } if aproc
    apply_options(eventbox,options)
    ret
  end
  # set a background to contaned container
  # Usage : stack {  background("#FF0000")  { flow { ...} } }
  def background(color,options={},&b) 
    eventbox = Gtk::EventBox.new
    ret=_cbox(true,eventbox,{},true,&b) 
    apply_options(eventbox,{bg: color}.merge(options))
    ret
  end
  def backgroundi(color,options={},&b) 
    eventbox = Gtk::EventBox.new
    ret=_cbox(false,eventbox,{},true,&b) 
    apply_options(eventbox,{bg: color}.merge(options))
    ret
  end
  # as pclickable, but container is a stacki
  # pclickablei(proc { alert("e") }) { label("click me!") }
  def pclickablie(aproc=nil,options={},&b) 
    eventbox = Gtk::EventBox.new
    eventbox.events = Gdk::Event::BUTTON_PRESS_MASK
    ret=_cbox(false,eventbox,{},true,&b) 
    eventbox.realize
    eventbox.signal_connect('button_press_event') { |w, e| aproc.call(w,e)  rescue error($!)  } if aproc
    apply_options(eventbox,options)
    ret
  end

  ##################################### List

  # create a verticale liste of data, with scrollbar if necessary
  # define methods: 
  # *  list() : get (gtk)list widget embeded
  # *  model() : get (gtk) model of the list widget
  # *  clear()  clear content of the list
  # *  set_data(array) : clear and put new data in the list
  # *  selected() : get the selected items (or [])
  # *  index() : get the index  of selected item (or [])
  # * set_selection(index) : force current selection do no item in data
  # * set_selctions(i0,i1) : force multiple consecutives selection from i1 to i2
  #
  # if bloc is given, it is called on each  selection, with array 
  # of index of item selectioned
  # 
  # Usage :  list("title",100,200) { |li| alert("Selections is : #{i.join(',')}") }.set_data(%w{a b c d})
  #
  def list(title,w=0,h=0,options={})
    scrolled_win = Gtk::ScrolledWindow.new
    scrolled_win.set_policy(:automatic ,:automatic )
    scrolled_win.set_width_request(w) if w>0
    scrolled_win.set_height_request(h)  if h>0
    model = Gtk::ListStore.new(String)
    column = Gtk::TreeViewColumn.new(title.to_s,Gtk::CellRendererText.new, {:text => 0})
    treeview = Gtk::TreeView.new(model)
    if block_given?
      treeview.selection.signal_connect("changed") do |selection, path, column|
        li=[];i=0;selection.selected_each {|model, path, iter|  li << path.to_s.to_i; i+=1 }
        yield(li) 
      end   
    end
    treeview.append_column(column)
    treeview.selection.set_mode(:multiple)
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
    def scrolled_win.selection() 
      li=[];i=0;list().selection.selected_each {|model, path, iter|  li << path.to_s.to_i; i+=1 }
      li 
    end
    def scrolled_win.index() 
      li=[];i=0;list().selection.selected_each {|model, path, iter|  li << path.to_s.to_i; i+=1 }
      li 
    end
    def scrolled_win.set_selections(istart,istop) 
      spath,epath=nil,nil
      i=0;model().each {|model, path, iter| 
          if i==istart
            spath=path  
          elsif i==istop
            epath=path  
          end
          list().selection.unselect_path(path)
          i+=1
      } 
      list().selection.select_range(spath,epath) if spath && epath
    end
    def scrolled_win.set_selection(index) 
      model().each {|model, path, iter|  list().selection.unselect_path(path) } 
      i=0;model().each {|model, path, iter| 
          if i==index 
            list().selection.select_path(path)  
          end
          i+=1
      } 
    end
    apply_options(treeview,options)
    autoslot(scrolled_win)
    scrolled_win
  end

  # create a grid of data (as list, but multicolumn)
  # use set_data() to put a 2 dimensions array of text
  # same methods as list widget
  # all columnes are String type
  def grid(names,w=0,h=0,options={})
    scrolled_win = Gtk::ScrolledWindow.new
    scrolled_win.set_policy(:automatic,:automatic)
    scrolled_win.set_width_request(w) if w>0
    scrolled_win.set_height_request(h)  if h>0
    
    model = Gtk::ListStore.new(*([String]*names.size))
    treeview = Gtk::TreeView.new(model)
    treeview.selection.set_mode(:single)
    names.each_with_index do  |name,i|
      treeview.append_column(
        Gtk::TreeViewColumn.new( name,Gtk::CellRendererText.new,{:text => i} )
      )
    end
    if block_given?
      treeview.signal_connect("changed") do |view, path, column|
        # TODO
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
  # <li>  String    else
  def tree_grid(names,w=0,h=0,options={})
    scrolled_win = Gtk::ScrolledWindow.new
    scrolled_win.set_policy(:automatic,:automatic)
    scrolled_win.set_width_request(w) if w>0
    scrolled_win.set_height_request(h)  if h>0
    scrolled_win.shadow_type = :etched_in
    
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
    treeview.selection.set_mode(:single)
    names.each_with_index do  |name,i|
      renderer,symb= *(
        if    types[i]==TrueClass then   [Gtk::CellRendererToggle.new().tap { |r| r.signal_connect('toggled') { } },:window]
        elsif types[i]==Gdk::Pixbuf then [Gtk::CellRendererPixbuf.new,:active]
        elsif types[i]==Numeric then   [Gtk::CellRendererText.new,:text]
        else               [Gtk::CellRendererText.new,:text]
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
    apply_options(treeview,options)
    autoslot(nil)
    slot(scrolled_win)
  end

  #a button which show a sub-frame on action
  def button_expand(text,initiale_state=false,options={},&b) 
    expander = Gtk::Expander.new(text)
    expander.expanded = initiale_state
    frame=box(&b)
    expander.add(frame)
    attribs(expander,options)
  end
  ######################## Dialog ##################

  # Dialog content is build with bloc parameter.
  # Action on Ok/Nok/delete button make a call to :response bloc.
  # dialog is destoy if return value of :response is true
  #
  # dialog_async("title",:response=> bloc {|dia,e| }) {
  #   flow { button("dd") ... }
  # }
  def dialog_async(title,config={},&b) 
    dialog = Dialog.new(
      title:   "Message",
      parent:  self,
      buttons: [[Gtk::Stock::OK, :accept],
                [Gtk::Stock::CANCEL, :reject]]
    )
            

    dialog.set_window_position(:center) if ! config[:position]
    
    @lcur << dialog.child
    hbox=stack { yield }
    @lcur.pop
    if config[:response]
      dialog.signal_connect('response') do |w,e|
        rep=config[:response].call(dialog,e) 
        dialog.destroy if rep
      end
    end
    dialog.show_all 
  end
  
  # Dialog contents is build with bloc parameter.
  # call is bloced until action on Ok/Nok/delete button 
  # return true if dialog quit is done by action on OK button
  #
  # dialog("title") {
  #   flow { button("dd") ... }
  # }
  def dialog(title="") 
    dialog = Dialog.new(
      title: title,
      parent: self,
      buttons: [[Gtk::Stock::OK, :accept],
                [Gtk::Stock::CANCEL, :reject]]
    )
      
    @lcur << dialog.child
    hbox=stack { yield }
    @lcur.pop
    
    dialog.set_window_position(:center)
    dialog.show_all 
    rep=dialog.run  #  blocked
    dialog.destroy
    dialog
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

  ############################ define style !! Warning: specific to gtk
  #
  # not ready!!!
  def def_style(string_style=nil)
    unless string_style
       fn=caller[0].gsub(/.rb$/,".rc")
       raise "Style: no ressource (#{fn} not-exist)" if !File.exists?(fn)
       string_style=File.read(fn)
    end
    begin
      css=Gtk::CssProvider.new
      css.load(data: string_style)
      self.style_context.add_provider(css, 600)      
      @style_loaded=true
    rescue Exception => e
      error "Error loading style : #{e}\n#{string_style}"
    end
  end
  def snapshot(filename=nil)
     return unless  RUBY_PLATFORM =~ /in.*32/
     require 'win32/screenshot'
     require 'win32ole'
     
     filename=Time.now.strftime("%D-%H%m%s.png").gsub('/','-') unless filename

     if ! self.title || self.title.size<3
        self.title=Time.now.to_f.to_s.gsub('.','')
     end
    File.delete(filename) if File.exists?(filename)
    puts "generated  for title '#{self.title}' ==> #{filename} ..."
    Win32::Screenshot::Take.of(:window,:title => /#{self.title}/, :context => :window).write(filename)
    puts "done #{File.size(filename)} B"
  end
end

