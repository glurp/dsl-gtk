# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl
  ######################## script ##################
  # define a hmi corresponding to a script command.
  # see samples/script.rb
  # the layout created contains three zones: 
  # * parameters : a set of entry, created with a DynObject which descriptor is hctx
  # * button zone : a table of widgets. widget are created with bloc traitment,
  # * a log zone : scolling area on text, appended with log() commande
  # * bottom fixed buttons : clear log and exit.
  def script(caption="Parameters",nb_column=2,hctx=nil) 
    $script_pid=nil
    @ctx=make_StockDynObject("ctx",hctx) if hctx
    stack do
      stacki do
        button_expand(caption+"...") do
          table(0,0) do
            row {
              @ctx.keys.each {|key|
                value=@ctx.send(key)
                cell_right(label "#{key.gsub('_',' ')} : ")
                cell_hspan(2,entry(value,{font: 'Courier 10'}))
                next_row
              }
            }
          end
        end if hctx
        @st=stack do yield end
        table(0,0) do
          row {
            @st.children.each_slice(nb_column) { |lb|
              lb.each {|w| w.parent.remove(w) ; cell(w) }
              next_row
            }
          }
        end
        delete(@st)
      end
      @log=text_area(100,100,{font: 'Courier 8', bg: "#004444", fg: "#FFF"})
      flowi do
        button("Clear log") { @log.text=""}
        buttoni("abort") { after(0) {
          Process.kill(9,$ruiby_script_pid) if $ruiby_script_pid; $ruiby_script_pid=nil
          } 
        } 
        buttoni("Exit") { after(0) {exit()} } 
      end 
    end
    self.class.instance_eval { define_method("log") do |*args|  @log.append(args.join(" ")+"\n") end }
  end  
  
  # execute a asynchonous system command, as done in a shell.
  # output goes to log, pid of process is in $ruiby_script_pid
  # on linux/unix host, exe() use PTY gem , on Windows it use popen3
  # to parameter is timeout of IO.select which wait for stdout output.
  def exe(cmd,to=nil)
    log cmd+" ..."
    if Dir.exist?("C:/")
      require 'open3'
      _exe_windows(cmd,to)
    else
      require 'pty'
      _exe_posix(cmd,to)
    end
  end

  def _exe_windows(cmd,to)
    Thread.new(cmd,to) do |cmd,to|
    begin
      STDOUT.sync = true
      process=nil
      Open3.popen3(cmd) do |sin,sout,serr,process0|
        process=process0
        $ruiby_script_pid= process.pid
        sin.close_write
        loop do
          r,w,e=IO.select([sout,serr],nil,nil,to || 10)
          r.each { |a| log a.read.chomp} if r
          break unless r && !sout.eof? && !serr.eof?
        end
      end
      gui_invoke { log("done: status=#{process.value}") }
      $ruiby_script_pid=nil
    rescue Exception => e
		  Process.kill(9,process.pid) if process
      log "Exception #{e} #{"  "+e.backtrace.join("\n  ")}"
      $ruiby_script_pid= nil
    end ; end
  end
  
  def _exe_posix(cmd,to)
    Thread.new(cmd,to) do |cmd,to|
      begin
        PTY.spawn(cmd) do |read,write,pid|
          $ruiby_script_pid= pid
          ( read.each { |output| (log output.chomp) } if read ) rescue log $!.to_s
        end
        rescue Exception => e
          log "Exception #{e} #{"  "+e.backtrace.join("\n  ")}"
          Process.kill(9,$ruiby_script_pid) if $ruiby_script_pid
          $ruiby_script_pid= nil
        ensure
      end
      gui_invoke { log("done") }
    end
	end
end

