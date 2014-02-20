# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl

  ##################### source editor

  # a source_editor widget : text as showed in fixed font, colorized (default: ruby syntaxe)
  # from: green shoes plugin
  # options= :width  :height :on_change :lang :font
  # @edit=source_editor().editor
  # @edit.buffer.text=File.read(@filename)
  def source_editor(args={},&blk) 
    #return(nil) # loading gtksourceview3 scratch application...
    begin
      require 'gtksourceview3'
    rescue Exception => e
      log('gtksourceview3 not installed!, please use text_area')
      puts '******** gtksourceview3 not installed!, please use text_area ************' 
      return
    end
    _accept?(:widget)    
    args[:width]  = 400 unless args[:width]
    args[:height] = 300 unless args[:height]
    change_proc = proc { }
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
    
    if block_given?
      sv.signal_connect('key_press_event') { |w,evt|
          blk.call(w,w.buffer.text) rescue error($!)
          false
      }
    end
    
    cb.set_size_request(args[:width], args[:height])
    cb.set_policy(:automatic, :automatic)
    cb.set_shadow_type(:in)
    cb.add(sv)
    cb.show_all
    attribs(cb,{})  
  end

end