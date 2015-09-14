# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl

  ############################## Popup
  # create a dynamic popup.
  # popup block can be composed by pp_item and pp_separator
  # Exemple :
  # popup { pp_item("text") { } ; pp_seperator ; pp_item('Exit") { exit!(0)} ; ....}
  # popup can be rebuild by popup_clear_append(w)
  def popup(w=nil)
    w ||= @lcur.last() 
    ppmenu = Gtk::Menu.new
    _set_accepter(ppmenu,:popupitem)
    @lcur << ppmenu 
    yield
    @lcur.pop
    ppmenu.show_all   
    w.add_events(Gdk::EventMask::BUTTON_PRESS_MASK)
    w.signal_connect("button_press_event") do |widget, event|
      ( after(300) {ppmenu.popup(nil, nil, event.button, event.time) { |menu, x, y, push_in| 
        [x,y] }} 
      ) if (event.button != 3)
    end
    ppmenu
  end

  # a button in a popup
  def pp_item(text,&blk)
    _accept?(:popupitem)
    item = Gtk::MenuItem.new(text)
    item.signal_connect('activate') { |w| blk.call() rescue error($!) }
    @lcur.last.append(item)
  end

  # a bar separator in a popup
  def pp_separator()
    _accept?(:popupitem)
    item = Gtk::SeparatorMenuItem.new()
    @lcur.last.append(item)
  end

  # clear a existant popup, rebuild it by bloc eval
  # popup_clear_append(@pp) { pp_item(..) ; pp_separator() ....}
  def popup_clear_append(pp)
    pp.children.each { |c| delete c}
    _set_accepter(pp,:popupitem)
    @lcur << pp
    yield rescue error($!)
    @lcur.pop
    pp.show_all   
  end  
  
  ############################## Menu  
  # create a application menu. must contain menu() {} :
  # menu_bar {menu("F") {menu_button("a") { } ; menu_separator; menu_checkbutton("b") { |w|} ...}}
  def menu_bar()
    menuBar= MenuBar.new
    _set_accepter(menuBar,:menu)
    @lcur << menuBar
    yield
    @lcur.pop
    slot(menuBar)
    menuBar
  end

  # a vertial drop-down menu, only for menu_bar container
  def menu(text)
    _accept?(:menu)
    filem = MenuItem.new(text.to_s)
    @lcur.last.append(filem)
    mmenu = Menu.new()
    _set_accepter(mmenu,:menuitem)
    @lcur << mmenu
    yield
    @lcur.pop
    filem.submenu=mmenu
    show_all_children(mmenu)
    mmenu
  end

  # create an text entry in a menu
  def menu_button(text="?",&blk)
    _accept?(:menuitem)
    item = MenuItem.new(text.to_s)
    @lcur.last.append(item)
    item.signal_connect("activate") { blk.call(text)  rescue error($!) }
  end

  # create an checkbox  entry in a menu
  def menu_checkbutton(text="?",state=false,&blk)
    _accept?(:menuitem)
    item = CheckMenuItem.new(label: text,use_underline: false)
    item.active=state
    @lcur.last.append(item)
    item.signal_connect("activate") {
      blk.call(item,text) rescue error($!.to_s)
    } 
  end
  def menu_separator() 
    _accept?(:menuitem)
    @lcur.last.append( SeparatorMenuItem.new ) 
  end

end
