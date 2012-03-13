module Ruiby_threader
	def init_threader
		unless defined?($__mainthread__)
			$__mainthread__= Thread.current
			$__mainwindow__=self
			@is_main_window=true
		else
			@is_main_window=false
		end
	end
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
	# shot peridicly ; return handle of animation. can be stoped by delete(hanim)
  	def anim(n,&blk) 
		GLib::Timeout.add(n) { 
			blk.call rescue log("#{$!} :\n  #{$!.backtrace[0..3].join("\n   ")}") 
			true 
		}
	end
	# one shot after some millisecs
  	def after(n,&blk) 
		GLib::Timeout.add(n) { 
			blk.call rescue log("#{$!} :\n  #{$!.backtrace[0..3].join("\n   ")}") 
			false
		}
	end
end

############################ Invoke HMI from anywhere ####################

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
