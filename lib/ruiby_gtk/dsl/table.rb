# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl

  ############################ table
  # create a container for table-disposed widgets. this is not a grid!
  # table(r,c) { row { cell(w) ; .. } ; ... }
  # or this form :
  # table { cell(w) ; cell(w2) ; next_row ; cell(w3), cell(w4) }
  def table(nb_col=0,nb_row=0,config={})
    autoslot
    table = Gtk::Table.new(nb_row,nb_col,false)
    table.set_column_spacings(config[:set_column_spacings]) if config[:set_column_spacings]
    _set_accepter(table,:row,:cell,:widget)
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
    _accept?(:row)
    @ltable.last[:col]=0 # will be increment by cell..()
    yield
    @ltable.last[:row]+=1
  end 
  def next_row()
    @ltable.last[:col]=0 # will be increment by cell..()
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
    _accept?(:cell)
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

end