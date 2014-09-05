# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#
class Terminal
  def initialize(tv,win)
    @tv=tv
    @tb=tv.buffer
    @win=win
    def tv.terminal(term=nil) @term ? @term : (@term=term) end
    tv.terminal(self)
    @@history||= ["nop"]
    @history=@@history
    @position=@history.size-1
    append_and_prompt ""
  end
  def append_and_prompt(text)
    text=text.to_s
    puts "append_and_prompt #{text.to_s[0..50]}... // #{text.size}"
    buf_start, end_iter = @tb.bounds
    @tb.insert(end_iter,"\n#{text}\n> ")
    insert=@tb.create_mark("insert", @tb.bounds.last, true)
    @win.after(100) {
      vscroll=@tv.parent.vadjustment
      vscroll.value = vscroll.upper+8
    }
  end
  def append(text)
    text=text.to_s
    buf_start, end_iter = @tb.bounds
    @tb.insert(end_iter,text)
    insert=@tb.create_mark("insert", @tb.bounds.last, true)
  end
  def replace_current(text)
    #delete current line
    #@tb.bounds.last
    append_and_prompt(text)
  end
  
  def get_history(n=-1)
    @position= [0,@history.size-1,@position+n].sort[1]
    @history[@position]
  end
  def set_history(n=-1)
    text=get_history(n)
    replace_current(text)
  end
  def get_line()
    (@tb.text||"").split(/\r?\n/).last.gsub(/^\s*>\s*/,"")
  end
  
  def execute(line=nil)
    line||=get_line
    puts "lastline: #{line}"
    line=line.strip
    return if line.size==0
    
    @history << line if line!= @history.last
    @position= @history.size-1
    cmd,*args=line.split(/\s+/)
    case cmd 
      when /^vim?$/
        system("vim",*args)
        append_and_prompt ""
      when "clear","clr","cls"
        @tb.text=""
        append_and_prompt ""        
      when "tree"
        @win.wtree(@win)
        append_and_prompt ""
      when "h","history"
        if args.size==0
          s=@history.size
          append_and_prompt @history.each_with_index.map {|l,i| 
             "   %3d >%s" % [s-i,l]
            }.last(40).join("\n")
        else
          cmd=@history[-args.first.to_i-1]
          append_and_prompt "<<#{cmd}>>"
          execute cmd
        end
      when "show"
        @win.show_methods( @win.instance_eval(args.first) )
        append_and_prompt ""
      when "echo"
        append_and_prompt( @win.instance_eval(args.join(" ")))
      when "techo"
        append_and_prompt( self.instance_eval(args.join(" ")))
      when "exit"
        @tv.parent.parent.parent.parent.close
      else
        begin
          res=@win.instance_eval(line)
          append_and_prompt(res.to_s)
        end
    end
  end
end

module Ruiby_default_dialog
  def terminal(title="Terminal")
    wdlog = Dialog.new(title: title,
      parent: nil,
      flags: 0 )
    sw=ScrolledWindow.new()
    sw.set_width_request(800)
    sw.set_height_request(300)
    sw.set_policy(:automatic,:always)
    
    termBuffer = TextBuffer.new
    tv=TextView.new(termBuffer)
    tv.override_font(  Pango::FontDescription.new("Courier new 10 bold")) 
    sw.add_with_viewport(tv)
    tv.signal_connect('key-press-event') do |w,ev|
      _process_terminal_key(w,ev,termBuffer)
    end
    Terminal.new(tv,self) 
    
    wdlog.child.pack_start(sw,true,true)
    wdlog.signal_connect('response') { wdlog.destroy }
    wdlog.show_all
    wdlog
  end
  def _process_terminal_key(w,ev,termBuffer)
    char=(ev.keyval.chr rescue nil)
    #puts ev.keyval if !char 
    up=65362
    down=65364
    enter=65293
    if ev.keyval==up
       w.terminal.set_history(-1)
       return true
    end
    if ev.keyval==down
       w.terminal.set_history(1)
       return true
    end
    if ev.keyval==enter
       w.terminal.execute()
       return true
    end      
    false
  rescue Exception => e
    w.terminal.append_and_prompt(e.to_s+"\n  "+e.backtrace.join("\n  "))
    true
  end
end

