# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require '../lib/Ruiby'
require 'thread'
require 'timeout'

Ruiby.app width: 300,height: 400,title: "All" do
  def exec(l)
    @stop=false
    l.each_with_index do |s,index| 
      gui_invoke {  @list.set_selection(index) }
      timeout(10) {
        puts "="*50 ; puts "                     #{s} " ; puts "^"*50
        @snapshot ? system("ruby",s,"take-a-snapshot") : system("ruby",s)
        puts "V"*50+"\n\n\n" 
      } rescue puts "timeout"
      break if @stop
    end
    gui_invoke { alert("all.rb : end of executions !") }
  end

  stack {
    @lscript=Dir.glob("*.rb").sort.select { |a|  a !~ /all|make_/ }
    @list=list("List of Scripts to be tested",300,300)
    @list.set_data(@lscript) 
    @snamshot=false
    @cb=sloti(check_button(" Snapshot ",false))
    buttoni(" Go ") { @snapshot=@cb.active?  ; Thread.new { exec(@lscript)} }
    buttoni(" Stop! ") { @stop=true }
  }
end