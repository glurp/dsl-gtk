# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl
  
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
  def box(sens=:vertical) 
    box=Gtk::Box.new(sens,2)
    _set_accepter(box,:layout,:widget)
    @lcur << box
    yield
    autoslot()
    @lcur.pop
  end
  

  #  mock class which can be push to layout stack : they accept some
  #  specific type of commands
  class HandlerContainer
    def accept?(t) 
      raise("no widget accepted here : #{self.class}") unless t==:handler 
    end 
  end
  
  # add a accept?() method to a layout (box). so children
  # will check if they can be added to current layout by invoke
  #    current_layout=@lcur.last
  #    current_layout.accept?( <type-children> )
  def _set_accepter(layout,*types)
    if types.size==1
      layout.define_singleton_method(:accept?) do |type|  
         raise("No command   #{type} accepted here, accept=#{types}/") unless types.first==type 
      end
    elsif types.size==2
      layout.define_singleton_method(:accept?) do |type|  
        raise("No command #{type} accepted here, accept=#{types}/") unless types.first==type || types.last==type 
      end
    else
      layout.define_singleton_method(:accept?) do |type| 
        raise("No command  #{type}  accepted here, accept=#{types}/") unless types.any? { |a| a==type }
      end
    end
  end
  def _accept?(type)
    w=@lcur.last
    w.respond_to?(:accept?) ? w.accept?(type) : true
  end  
  
  ################################ Some other layouts
  
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
    _set_accepter(vbox,:layout,:widget)
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
    _set_accepter(box,:layout,:widget)
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
  def sloti(w) @current_widget=nil; @lcur.last.pack_start(w, :expand => false, :fill => false, :padding => 0) ; w end

  # slot() precedently created widget if not sloted.
  # this is done by attribs(w) which is call after construction of almost all widget
  def autoslot(w=nil)
    (slot(@current_widget)) if @current_widget!=nil
    @current_widget=w 
  end
  # forget precedent widget oconstructed
  def razslot() @current_widget=nil; end
  
  # set a background color to current container
  # Usage : stack {  background("#FF0000")  { flow { ...} } }
  def background(color,options={},&b)
    _accept?(:layout)
    eventbox = Gtk::EventBox.new
    ret=_cbox(true,eventbox,{},true,&b)
    apply_options(eventbox,{bg: color}.merge(options))
    ret
  end
  def backgroundi(color,options={},&b)
    _accept?(:layout)
    eventbox = Gtk::EventBox.new
    ret=_cbox(false,eventbox,{},true,&b)
    apply_options(eventbox,{bg: color}.merge(options))
    ret
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



  ###################################### notebooks

  # create a notebook widget. it must contain page() widgets
  # notebook { page("first") { ... } ; ... }
  #  nb.page=<no page>  => active no page
  def notebook() 
    nb = Notebook.new()
    slot(nb)
    _set_accepter(nb,:tab)
    @lcur << nb
    yield
    @lcur.pop
    nb
  end
  # a page widget. only for notebook container.
  # button can be text or icone (if startin by '#', as label)
  def page(title,icon=nil)
    _accept?(:tab)
    l=Image.new(bixbuf: get_pixmap(icon[1..-1])) if icon
    l=Image.new(bixbuf: get_pixmap(title[1..-1])) if title && title[0,1]=="#"
    l=Label.new(title) if  title.size>1 && title[0,1]!="#"
    @lcur.last.append_page( box { yield }, l )
  end

  ############################## Accordion

  # create a accordion menu.  
  # must contain aitem() which must containe alabel() :
  # accordion { aitem(txt) { alabel(lib) { code }; ...} ... }
  def accordion() 
    _accept?(:layout)
    @slot_accordion_active=nil #only one accordion active by window!
    w=stack { stacki {
      _set_accepter(@lcur.last,:aitem,:layout,:widget)
      yield
    }}
    separator
    w
  end
  # create a horizontral accordion menu.  
  # must contain aitem() which must containe alabel() :
  # accordion { aitem(txt) { alabel(lib) { code }; ...} ... }
  def haccordion() 
    _accept?(:layout)
    @slot_accordion_active=nil #only one accordion active by window!
    w=flow { flowi {
      _set_accepter(@lcur.last,:aitem,:layout,:widget)
      yield
    }}
    separator
    w
  end
  #  a button menu in accordion
  #  bloc is evaluate for create/view a list of alabel :
  #  aitem(txt) { alabel(lib) { code }; ...}
  def aitem(txt,&blk) 
    _accept?(:aitem)
    b2=Gtk::Box.new(:vertical,2)
    _set_accepter(b2,:alabel,:layout,:widget)
    b=button(txt) {
          clear_append_to(@slot_accordion_active) {} if @slot_accordion_active
          @slot_accordion_active=b2
          clear_append_to(b2) {  blk.call() }
          slot_append_after(b2,b)
    }
  end

  # create a button-entry  in a  accordion menu
  # bloc is evaluate on user click. must be in aitem() bloc :
  # accordion { aitem(txt) { alabel(lib) { code }; ...} ... }
  def alabel(txt,&blk)
    _accept?(:alabel)
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
      title:   title,
      parent:  self,
      buttons: [[Gtk::Stock::OK, :accept],
                [Gtk::Stock::CANCEL, :reject]]
    )
            

    dialog.set_window_position(:center) if ! config[:position]
    
    @lcur << dialog.child
    hbox=stack { yield }
    @lcur.pop
    Ruiby.apply_provider(dialog.child)
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
    Ruiby.apply_provider(dialog.child)
    dialog.show_all 
    rep=dialog.run  #  blocked
    dialog.destroy
    rep==-3
  end
  
  # a dialog without default buttons
  # can be synchrone (block the caller until wndow destroyed)
  def window(title="",sync=false) 
    dialog = Dialog.new(
      title: title,
      parent: self,
      buttons: []
    )
      
    @lcur << dialog.child
    hbox=stack { yield }
    @lcur.pop
    
    dialog.set_window_position(:center)
    Ruiby.apply_provider(dialog.child)
    dialog.show_all 
    if sync
      rep=dialog.run  #  blocked
      dialog.destroy
    end
  end
  
end
