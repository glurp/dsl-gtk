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
	# must be created by application, active the tread engine for caller window.
	# last caller is the winner!
	def threader(per)
		@queue=Queue.new
		$__queue__=@queue
		ici=self
		GLib::Timeout.add(per) {
			if @queue.size>0 
				( ici.instance_eval( &@queue.pop ) rescue log("#{$!} :\n  #{$!.backtrace[0..3].join("\n   ")}") ) while @queue.size>0 
			end
         true
        }
	end
	
	# shot peridicly a  bloc parameter
	# not threading: the bloc is evauated by gtk mainloop iin main thread context
	# return handle of animation. can be stoped by delete(hanim)
  	def anim(n,&blk) 
		GLib::Timeout.add(n) { 
			blk.call rescue log("#{$!} :\n  #{$!.backtrace[0..3].join("\n   ")}") 
			true 
		}
	end
	# as anim, but one shot, after some millisecs
  	def after(n,&blk) 
		GLib::Timeout.add(n) { 
			blk.call rescue log("#{$!} :\n  #{$!.backtrace[0..3].join("\n   ")}") 
			false
		}
	end
end

############################ Invoke HMI from anywhere ####################

# ift hreader() is done by almost one window,  
# evaluate (instance_eval) the bloc closure in the context of this window
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

# ift hreader() is done by almost one window,  
# evaluate (instance_eval) the bloc closure in the context of this window
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
