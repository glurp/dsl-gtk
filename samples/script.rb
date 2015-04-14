# LGPL and Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
require_relative '../lib/Ruiby.rb'

class Object ; 
  #def puts(*t) $app.instance_eval { log("  >",*t) } end 
end


Ruiby.app width: 800, height: 400, title: "Demo script layout" do
  stack do
    labeli(<<-EEND,font: "Arial bold 12")
      This is demo of script layout. With this command, you can quickly create
      a HMI for a typical script.
    EEND
    script("Parameters",3,"package_name" => "green_shoes" , "version" => "3.0") do
        button("install",bg: "#FFAABB") { exe("gem install #{@ctx.package_name.value}") }
        button("remove",bg: "#AABBFF")  { exe("gem remove #{@ctx.package_name.value}")  }
        button("cleanup",bg: "#AA88AA") { exe("gem cleanup #{@ctx.package_name.value}") }
        button("yank")                  { 
          if ask("yank version '#{@ctx.version.value}' ?")
            exe("gem yank #{@ctx.package_name.value} -v #{@ctx.version.value} ")   
          end
        }
        button("find")                  { exe("gfind / ",2) }
        button("ls")                    { exe("ls -lt -aF") }
        button("ping")                  { exe("ping -t localhost",2) }
    end
  end
  def exe(cmd,to=nil)
    log cmd+" ..."
    if Dir.exist?("C:/")
      require 'open3'
      exe_windows(cmd,to)
    else
      require 'pty'
      exe_posix(cmd,to)
    end
  end

  def exe_windows(cmd,to)
    Thread.new(cmd,to) do |cmd,to|
    begin
      STDOUT.sync = true
      process=nil
      Open3.popen3(cmd) do |sin,sout,serr,process0|
        process=process0
        sin.close_write
        loop do
          r,w,e=IO.select([sout,serr],nil,nil,to || 10)
          r.each { |a| log a.read.chomp} if r
          break unless r && !sout.eof? && !serr.eof?
        end
      end
      gui_invoke { log("done: status=#{process.value}") }
    rescue Exception => e
		  Process.kill(9,process.pid) if process
      log "Exception #{e} #{"  "+e.backtrace.join("\n  ")}"
    end ; end
  end
  
  def exe_posix(cmd,to)
    PTY.spawn(cmd) do |read,write,pid|
      begin
        #read.expect(/user/) { log "set user..."    ; write.puts "a" }
        #read.expect(/pass/) { log "set passwd..."  ; write.puts "b" }
        read.each { |output| log output.chomp }
      rescue Exception => e
        Process.kill(9,pid)
        log "Exception #{e} #{"  "+e.backtrace.join("\n  ")}"
      ensure
      end
    end
	end
end
