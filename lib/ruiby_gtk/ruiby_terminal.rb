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
	puts "append_and_prompt #{text.inspect} // #{text.size}"
	buf_start, end_iter = @tb.bounds
    @tb.insert(end_iter,"\n#{text}\n> ")
	buf_start, end_iter = @tb.bounds
	eend=@tb.create_mark("eend", end_iter, false)
	@tv.scroll_to_mark(eend,0.0,true,1.0,1.0)
  end
  def replace_current(text)
	puts "replace_current by #{text}"
	buf_start, end_iter = @tb.bounds
    @tb.insert(end_iter,"\n#{text}")
	eend=@tb.create_mark("eend", end_iter, false)
	@tv.scroll_to_mark(eend,0.0,true,1.0,1.0)
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
	  when "show"
		@win.show_methods( eval(args.first) )
	  when "echo"
	    append_and_prompt(eval(args.join(" ")))
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
    sw.add_with_viewport(tv)
    tv.signal_connect('key-press-event') do |w,ev|
      _process_terminal_key(w,ev,termBuffer)
    end
    Terminal.new(tv,self) 
    
    wdlog.child.add(sw)
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
    end
    if ev.keyval==down
	   w.terminal.set_history(1)
    end
    if ev.keyval==enter
	   w.terminal.execute()
	   return true
    end      
      #show_methods termBuffer
      #after(1) { termBuffer.insert "Enter" }
    false
  rescue Exception => e
    w.terminal.append_and_prompt(e.to_s+"\n  "+e.backtrace.join("\n  "))
	false
  end
end

