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
end

require_relative 'dsl/layouts.rb'
require_relative 'dsl/commands.rb'
require_relative 'dsl/pixmap.rb'
require_relative 'dsl/label_button_image.rb'
require_relative 'dsl/form_fields.rb'
require_relative 'dsl/script.rb'

require_relative 'dsl/canvas.rb'
require_relative 'dsl/editors.rb'
require_relative 'dsl/list_grid.rb'
require_relative 'dsl/menus_popup.rb'
require_relative 'dsl/table.rb'
module Kernel
  def __(filter=//)
     $__mainwindow__.show_methods(self,filter)
  end
end

module Ruiby_dsl

  
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
  #    Containers organyze children widget, but show (almost) nothing.
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
  #       aitem alabel box button  calendar canvas cell* center check_button  combo  dialog
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
  #    space() can be used for slot a empty space.
  #
  # Attachement to a side of a container is not supported. You must put empty sloted widget
  # in free space:
  # <li> scoth xxxx in top of frame    : >stack { stacki { xxx } ; stack { } }
  # <li> scoth xxxx in bottom of frame : >stack {  stack { } ; stacki { xxx } }
  # <li> scoth xxxx in left of frame   : >flow { flowi { xxx } ; stack { } }
  #
  # Dynamique variables bindings
  # The class  <code>::DynVar</code> support a single value and the observer pattern.
  # So widgets can be associate with an dynamique value :
  # * if the value change, the widget change the view accordingly to the new value, 
  # * if the view change by operator action, the value change accordingly.
  # * Threading is care : widget updates will be done in maint thread context
  #
  # Widgets which supports DynVar are : 
  # * entry,ientry,
  # * label,
  # * islider,
  # * check_button
  #
  # This list will be extende to combo_button, toggle_button, list, grid ...
  #
  # 'make_DynClass' and 'make_StockDynClass' can be use for creation of Class/object
  # which contain DynVar : as OStruct, but data members are DynVar.
  #
  # <li>@calc=make_DynObject({"resultat"=> 0,"value" => "0" , "stack" => [] })
  # @calc.resultat => @calc.resultat.value="X" ; x= @calc.resultat.value
  #
  # <li>@calc=make_StockDynObject("name",{"resultat"=> 0,"value" => "0" , "stack" => [] })
  # create a object, name him for Stock, give default values if object does not exists
  # in current stock.
  #
  
  def aaa_generalities()
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
    if @current_widget && @current_widget.respond_to?(:set_tooltip_markup)
      @current_widget.set_tooltip_markup(value) 
      @current_widget.has_tooltip=true
    else
      error("tooltip : '#{value[0..30]}' : there are no current widget or it cannot contain ToolTip !") 
    end
  end


  ############### Commands

  # common widget property  applied for (almost) all widget. 
  # options are last argument of every dsl command, see apply_options
  def attribs(w,options)
      _accept?(:widget) 
      #p options if options && options.size>0
      apply_options(w,options)
      autoslot(w)  # slot() precedent widget if exist and not already sloted, and declare this one as the precedent
      def w.options(config) $__mainwindow__.apply_options(self,config) end
      w
  end
  # apply some styles  property  to an existing widget. 
  # options are :size, :width; :height, :margins, :bg, :fg, :font
  # apply_options(w,
  #   :size=> [10,10], 
  #   :width=>100, :heigh=>200,
  #   :margins=> 10
  #   :bg=>'#FF00AA",
  #   :fg=> Gdk::Color:RED,
  #   :tooltip=> "Hello...",
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
	  w.set_name(options[:id]) if options[:id]
      if options[:tooltip]
        w.set_tooltip_markup(options[:tooltip])
        w.has_tooltip=true
      end
      w
  end
  def _() @current_widget end
  def color_conversion(color)
    case color 
      when ::Gdk::RGBA then color
      when String then color_conversion(::Gdk::Color.parse(color))
      when Array then color_conversion(color[1])
      when ::Gdk::Color then ::Gdk::RGBA.new(color.red/65535.0,color.green/65535.0,color.blue/65535.0,1)
      else
        raise "unknown color : #{color.inspect}"
    end
  end
  # parse html color ( "#FF00AA" ) to rgba array, useful
  # for canvas vectors styles
  def self.cv_color_html(html_color,opacity=1)
    c=::Gdk::Color.parse(html_color)
    #::Gdk::RGBA.new(c.red/65000.0,c.green/65000.0,c.blue/65000.0,1)
    [c.red/65535.0,c.green/65535.0,c.blue/65535.0,opacity>1 ? 1 : opacity<0 ? 0 : opacity]
  end
  # parse color from #RRggBB html format Ruiby_dsl.html_color
  def html_color(str) color_conversion(str) end
  def self.html_color(str) ::Gdk::Color.parse(str) end
   
  def widget_properties(title=nil,w=nil) 
    widg=w||@current_widget||@lcur.last
    p get_config(widg)
    properties(title||widg.to_s,{},get_config(widg)) 
  end

  # horizontal toolbar of icon button and/or separator
  # if icon name contain a '/', second last is  tooltip text
  # Usage: 
  #   htoolbar { toolbat_button("text/tooltip" { } ; toolbar_separator ; ... } 
  def htoolbar(options={})
    b=Toolbar.new
    b.set_toolbar_style(Gtk::ToolbarStyle::ICONS)
    _set_accepter(b,:toolb)
    @toolbarIndex=0
    @lcur << b
    yield
    @lcur.pop
    i=0    
    attribs(b,options)
    sloti(b)
  end 
  
  def toolbar_button(name,tooltip=nil,&blk)
      _accept?(:toolb)
      iname=get_icon(name)
      
      w=Gtk::ToolButton.new(icon_widget: get_image(name) )
      w.signal_connect("clicked") { blk.call rescue error($!) } if blk
      w.set_tooltip_text(tooltip) if tooltip
      
      @lcur.last.insert(w,@toolbarIndex)
      @toolbarIndex+=1
  end
  def toolbar_separator()
      _accept?(:toolb)
      w=Gtk::SeparatorToolItem.new        
      @lcur.last.insert(w,@toolbarIndex)
      @toolbarIndex+=1
  end
 
  
  # horizontal toolbar of (icone+text)
  #
  # htoolbar_with_icon_text do
  #  button_icon_text "dialog_info","text info" do alert(1) end
  #  button_icon_text "sep"
  # end
  #
  # if icone name start with 'sep' : a vertical separator is drawn in place of touch
  # see sketchi
  #
  def htoolbar_with_icon_text(conf={})
    flowi {
      yield
    }
  end
  # a button with icon+text verticaly aligned,
  # can be call anywhere, and in htool_bar_with_icon_text
  # option is label options and  isize ( option for icon size, see label())
  def button_icon_text(icon,text="",options={},&b)
       if icon !~ /^sep/
          spacei
          pclickablie(proc { b.call  }) { stacki { 
              label("#"+icon,{isize: (options[:isize] || :dialog) }) 
              label(text[0,15],options)
         } }
       else
          separator
       end
  end
  def button_left_icon_text(icon,text="",options={},&b)
       if icon !~ /^sep/
          spacei
          pclickablie(proc { b.call  }) { flowi { 
              label("#"+icon,{isize: (options[:isize] || :dialog) }) 
              label(text,options)
         } }
       else
          separator
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
  # * w.uri= "file:///foo.avi"
  # * w.uri= "rtsp:///host:port/video"
  # *.progress=n    force current position in video (0..1)
  # see samples/video.rb and samples/quadvideo.rb
  
  def video(url=nil,w=300,h=200) 
    begin 
    require "gst"
    require "clutter-gtk"  # gem install clutter-gtk
    require "clutter-gst"  # gem install clutter-gstreamer
    rescue
      error("Please install gstreamer, clutter-gtk, clutter-gstreamer")
      return button("no video")
    end
    p 1
    clutter = ClutterGtk::Embed.new
    p 2
    video=ClutterGst::VideoTexture.new
    p 3
    p video
    clutter.stage.add_child(video)
    p 4
    video.width=w
    video.height=h
    video.uri = url if url
    video.playing = false
    isNotify=false
    #show_methods(video, /=$/)
    clutter.define_singleton_method(:view) { video }
    clutter.define_singleton_method(:url=) { |u| video.uri= u }
    clutter.define_singleton_method(:play) { video.playing= true }
    clutter.define_singleton_method(:stop) { video.playing= false }
    clutter.define_singleton_method(:progress=) { |pp| video.progress=(pp) unless isNotify }
    if block_given?
      video.signal_connect("notify") do |o,v,param|
            isNotify=true ;
            yield(video.progress()) rescue p $! ;
            isNotify=false
      end
    end
    $video=video
    attribs(clutter,{})
  end
end


=begin
dsl/canvas.rb:   
    canvas(width,height,option={})
    canvasOld(width,height,option={})
dsl/form_fields.rb:   
    combo(choices,default=nil,option={},&blk)
    toggle_button(text1,text2=nil,value=false,option={},&blk)
    check_button(text="",value=false,option={},&blk)
    entry(value,size=10,option={},&blk)
    ientry(value,option={},&blk)
    fentry(value,option={},&blk)
    field(tlabel,lwidth,value,option={},&blk)
    fields(alabel=[["nothing",""]],option={},&blk)   
    islider(value=0,option={},&b)
    color_choice(text=nil,options={},&cb)
dsl/label_button_image.rb:   
    label(text,options={})
    labeli(text,options={})
    image(file,options={}) 
    button(text,option={},&blk)
    buttoni(text,option={},&blk)
    slider(start=0.0,min=0.0,max=1.0,options={})
    progress_bar(start=0,options)
    levelbar(start=0,options)
    pclickable(aproc=nil,options={},&b) 
    pclickablie(aproc=nil,options={},&b) 
dsl/layouts.rb:   
   background(color,options={},&b)
   backgroundi(color,options={},&b)
   button_expand(text,initiale_state=false,options={},&b) 
dsl/list_grid.rb:   
   list(title,w=0,h=0,options={})
   grid(names,w=0,h=0,options={})
   tree_grid(names,w=0,h=0,options={})
dyn_var.rb:
   stock(name,defv) 
   save_stock 
   make_DynClass(h={"dummy"=>"?"})
   make_StockDynClass(h={"dummy"=>"?"})
   initialize(oname="",x={})
   make_StockDynObject(oname,h)   
ruiby_default_dialog3.rb:  
   alert(*txt) message(:info,*txt) end
   error(*txt) 
   prompt(txt,value="") 
   ask(*txt) 
   trace(*txt) message(:warning,*txt) end
   message(style,*txt)
   ask_color()
   edit(filename)
   ask_file_to_read(dir,filter)
   ask_file_to_write(dir,filter)
   ask_dir_to_read(initial_dir=nil)
   ask_dir_to_write(initial_dir=nil)
   dialog_chooser(title, action, button)
   
ruiby_dsl3.rb:
   get_current_container() @lcur.last end
   get_config(w)
   css_name(name)
   tooltip(value="?") 
   attribs(w,options)
   apply_options(w,options)
   _() @current_widget end
   color_conversion(color)
   self.cv_color_html(html_color,opacity=1)
   html_color(str) color_conversion(str) end
   self.html_color(str) ::Gdk::Color.parse(str) end
   widget_properties(title=nil,w=nil) 
   htoolbar(options={})
   toolbar_button(name,tooltip=nil,&blk)
   toolbar_separator()
   htoolbar_with_icon_text(conf={})
   button_icon_text(icon,text="",options={},&b)
   show_methods(obj=nil,filter=nil)
   propertys(title,hash,options={:edit=>false, :scroll=>[0,0]},&b)
   properties(title,hash,options={:edit=>false, :scroll=>[0,0]})
   calendar(time=Time.now,options={})
   video(url=nil,w=300,h=200) 
ruiby_terminal.rb:  
   terminal(title="Terminal")
ruiby_threader.rb:  
   anim(n,&blk)
   after(n,&blk) 
  gui_invoke(&blk) 
  gui_invoke_in_window(w,&blk) 
  gui_invoke_wait(&blk) 
systray.rb:
   systray(x=nil,y=nil,systray_config={})
windows.rb:
   on_resize(&blk)
   on_destroy(&blk) 
   ruiby_exit()
   component
   rposition(x,y)
   chrome(on=false)
   ruiby_component()
   initialize()
dsl/layouts.rb
  stack(config={},add1=true,&b)
  flow(config={},add1=true,&b)
  var_box(sens,config={},add1=true,&b)
  stacki(config={},add1=true,&b)
  flowi(config={},add1=true,&b)
  var_boxi(sens,config={},add1=true,&b)
  box(sens=:vertical) 
  accept?(t) 
  _set_accepter(layout,*types)
  _accept?(type)
  regular(on=true)
  spacing(npixels=0)
  center() 
  left(&blk) 
  right(&blk) 
  update() Ruiby.update() end
  frame(t="",config={},add1=true,&b)    
  framei(t="",config={},add1=true,&b)
  slot(w)
  sloti(w)
  autoslot(w=nil)
  razslot()
  background(color,options={},&b)
  backgroundi(color,options={},&b)
  scrolled(width,height,&b)
  vbox_scrolled(width,height,&b)
  notebook() 
  page(title,icon=nil)
  accordion() 
  haccordion() 
  aitem(txt,&blk) 
  alabel(txt,&blk)
  stack_paned(size,fragment,&blk)
  flow_paned(size,fragment,&blk)
  button_expand(text,initiale_state=false,options={},&b) 
  dialog_async(title,config={},&b) 
  dialog(title="") 
  window(title="") 
=end
