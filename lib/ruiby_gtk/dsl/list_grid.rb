# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl
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
      treeview.selection.signal_connect("changed") do |selection, path, column1|
        li=[];i=0;selection.selected_each {|model1, path1, iter|  li << path1.to_s.to_i; i+=1 }
        ldata=[];model.each {|model, path, iter|  ldata << iter.get_value(0) }
        ld=li.map { |idx| ldata[idx] }
        yield(li,ld) rescue error($!)
      end
    end
    treeview.append_column(column)
    treeview.selection.set_mode(:multiple)
    scrolled_win.add_with_viewport(treeview)

    def scrolled_win.options(c) $__mainwindow__.apply_options(children[0].children[0],c) end
    def scrolled_win.list() children[0].children[0] end
    def scrolled_win.model() list().model end
    def scrolled_win.clear() list().model.clear end
    def scrolled_win.add_item(word)
      raise("list.add_item() out of main thread!") if $__mainthread__ != Thread.current
      list().model.append[0]=word
    end
    def scrolled_win.get_data()
      raise("list.get_data() out of main thread!") if $__mainthread__ != Thread.current
      puts
      l=[];list().model.each {|model, path, iter|
          l << iter.get_value(0)
      }
      l
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
      treeview.signal_connect("row-activated") do |tview, path, column|
          sl=names.size.times.map {|i| tview.selection.selected[i].to_s.clone}
          yield(sl)
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
      grid().selection.unselect_all
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

end
