# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_threader
  # implictly called by Ruiby window creator
  # initialize multi thread engine
  def init_threader
    unless defined?($__mainthread__)
      $__mainthread__= Thread.current
      $__mainwindow__=self
      @is_main_window=true
    else
      @is_main_window=false
    end
  end
  # must be created by application (in initialize, after super), active the tread engine for 
  # caller window.
  # if several windows, last created is the winner : gtk_invoke will throw to last treaded() window!
  def threader(per)
    return unless $__mainwindow__==self
    @queue=Queue.new
    $__queue__=@queue
    ici=self
    GLib::Timeout.add(per) {
      while @queue.size>0 
           mess= @queue.pop
         if Array===mess
            win,mess=*mess
         else
          win=ici
         end
         win.instance_eval(&mess) rescue log("#{$!} :\n  #{$!.backtrace[0..3].join("\n   ")}") 
      end
         true
        }
  end
  
  # shot peridicly a  bloc parameter
  # no threading: the bloc is evaluated by gtk mainloop in main thread context
  # return handle of animation. can be stoped by delete(anim) // NOT WORK!, return a Numeric...
  def anim(n,&blk)
    @hTimer||={}
    $on=false
    px=0
    px=GLib::Timeout.add(n) do
      unless $on
        $on=true
        blk.call rescue log("#{$!} :\n  #{$!.backtrace.join("\n   ")}")
        $on=false
      else
        p "pass"
      end
      ret=@hTimer[px] 
      @hTimer.delete(px) unless ret
      ret
    end
    @hTimer[px]=true
    px
  end
  # as anim, but one shot, after some millisecs
  # no threading: the bloc is evaluated by gtk mainloop in main thread context
    def after(n,&blk) 
    GLib::Timeout.add(n) { 
      blk.call rescue log("#{$!} :\n  #{$!.backtrace[0..3].join("\n   ")}") 
      false
    }
  end
end

############################ Invoke HMI from anywhere ####################

# if threader() is done by almost one window,  
# evaluate (instance_eval) the bloc  in the context of this window
# async: bloc will be evaluate after the return!
def gui_invoke(&blk) 
  if ! defined?($__mainwindow__)
    puts("\n\ngui_invoke() : initialize() of main windows not done!\n\n") 
    return
  end
  if $__mainthread__ != Thread.current
    if defined?($__queue__)
      $__queue__.push( blk ) 
    else
      puts("\n\nThreaded invoker not initilized! : please call threader(ms) on window constructor!\n\n") 
    end
  else
    $__mainwindow__.instance_eval( &blk )
  end
end
def gui_invoke_in_window(w,&blk) 
  if ! defined?($__mainwindow__)
    puts("\n\ngui_invoke() : initialize() of main windows not done!\n\n") 
    return
  end
  if $__mainthread__ != Thread.current
    if defined?($__queue__)
      $__queue__.push( [w,blk] ) 
    else
      puts("\n\nThreaded invoker not initilized! : please call threader(ms) on window constructor!\n\n") 
    end
  else
    w.instance_eval( &blk )
  end
end

# if threader() is done by almost one window,  
# evaluate (instance_eval) the bloc  in the context of this window
# sync: bloc will be evaluate before  the return. Warining! : imlementation is stupid
def gui_invoke_wait(&blk) 
  if ! defined?($__mainwindow__)
    puts("\n\ngui_invoke_wait() : initialize() of main windows not done!\n\n") 
    return
  end
  if $__mainthread__ != Thread.current
    if defined?($__queue__)
      $__queue__.push( blk ) 
      n=0
      (sleep(0.05);n+=1) while $__queue__.size>0 && n<5000 # 25 secondes max!
    else
      puts("\n\nThreaded invoker not initilized! : please call threader(ms) on window constructor!\n\n") 
    end
  else
    $__mainwindow__.instance_eval( &blk )
  end
end
