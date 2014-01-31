# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl
  ############### Inputs widgets

  # combo box, decribe  with a Hash choice-text => value-of-choice
  # choices: array of text choices
  # dfault : text activate or index of text in array
  # bloc ! called when a choice is selected
  #
  # Usage :  combo(%w{aa bb cc},"bb") { |text;index| alert("the choice is #{text} at #{index}") }
  #
  def combo(choices,default=nil,option={},&blk)
    # TODO Dyn
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
    # TODO Dyn
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
  
  def _dyn_check_button(text,var,option={}) 
    w= block_given? ?  check_button(text,!! var.value,option) : check_button(text,!! var.value,option) { |v|  var.set_as_bool(v) }
    var.observ { |v|  w.set_active(var.get_as_bool())  }
    w
  end
  
  # create a checked button
  # state can be read by cb.active?
  def check_button(text="",value=false,option={},&blk)
    if DynVar === value
      return _dyn_check_button(text,value,option)
    end
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
    # TODO Dyn
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
    # TODO Dyn
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
  
 
  def _dyn_entry(var,size,options,slotied) 
    size= var.value.to_s.size*2 unless size
    w= unless slotied
      (block_given? ? entry(var.value,size,options)  : entry(var.value,size,options) { |v| var.value=v })
    else
      (block_given? ? entry(var.value,size,options)  : entry(var.value,size,options) { |v| var.value=v })
    end
    var.observ { |v| w.text = v.to_s }
    w
  end
   
  # create a text entry for keyboard input
  # if block defined, it while be trigger on eech of (character) change of the entry
  def entry(value,size=10,option={},&blk)
    if DynVar === value
       return _dyn_entry(value,size,option,false,&blk)       
    end
    w=Entry.new().tap {|e| e.set_text(value ? value.to_s : "") }
    after(1) do
      w.signal_connect("key-press-event") do |en,e|
        after(1) { blk.call(w.text) rescue error($!) }
        false
      end 
    end if block_given?
    attribs(w,option)
  end
  
  def _dyn_ientry(var,options,slotied) 
    w= unless slotied
      (block_given? ? ientry(var.value,options)  : ientry(var.value,options) { |v| var.value=v })
    else
      (block_given? ? ientry(var.value,options)  : ientry(var.value,options) { |v| var.value=v })
    end
    var.observ { |v| w.text = v.to_s }
    w
  end
  
  # create a integer text entry for keyboed input
  # option must define :min :max :by for spin button
  def ientry(value,option={},&blk)
    if DynVar === value
       return _dyn_entry(value,value.value.to_s.size*4,option,true,&blk)       
    end
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
    # TODO Dyn
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
  
  # show a label and a entry in a  flow. entry widget is returned
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
  
  def _dyn_islider(var,option,&blk) 
    w=  block_given? ?  islider(var.value.to_i,option,&blk) : islider(var.value.to_i,option) { |v| var.value=v }
    var.observ { |v| w.set_value(v.to_i) }
    attribs(w,option)   
    w
  end
  
  # create a slider
  # option must define :min :max :by for spin button
  # current value can be read by w.value
  # if bloc is given, it with be call on each change, with new value as parameter
  # if value is a DynVar, slider will be binded to the DynVar : each change of the var value will update the slider,
  # of no block given,each change of the slider is notifies to the DynVar, else change will
  # only call the block.
  def islider(value=0,option={},&b)
    if DynVar === value
      return _dyn_islider(value,option,&b)
    end
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
  # multiline entry on dynvar
  #
  def text_area_dyn(dynvar,w=200,h=100,args={}) # from green_shoes app
    # TDODO : test !
    w=text_area_dyn(w,h,args) 
    dynvar.observ { |o,n| w.text=n }
    w.text_area.signal_connect(:changed) { |t,e| dynvar.value(w.text) }
    w
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
  
end