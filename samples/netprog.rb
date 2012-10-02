################################################################################
# select * from netstat join tasklist where *.to_s like '%1%'    ;)
################################################################################
raise("not windows!") unless RUBY_PLATFORM =~ /in.*32/
require_relative '../lib/ruiby'

$fi=ARGV[0] || "LISTENING"
$filtre=Regexp.new($fi)

def make_list_process()
	hpid={}
	%x{tasklist}.split(/\r?\n/).each { |line| 
	  ll=line.chomp.split(/\s+/) 
	  next if ll.length<5
	  prog,pid,x,y,*l=ll
	  hpid[pid]= [prog,l.join(" ")]
	}
	hpid
end
def net_to_table(filtre)
    hpid=make_list_process()
    ret=[]
	%x{netstat -ano}.split(/^/).each { |line|
	 proto,src,dst,flag,pid=line.chomp.strip.split(/\s+/)  
	 prog,s = hpid[pid]||["?","?"]
	 ret << [flag,src,dst,prog,pid.to_i,s] if [flag,src,dst,prog,pid,s].inspect =~  filtre	 
	}
	ret.sort { |a,b| a[4]<=>b[4]}
end

Ruiby.app(:width => 0, :height => 0, :title => "NetProg #{$fi}") do
	@periode=2000
	stack do
		@grid=grid(%w{flag source destination proc pid proc-size},500,100)
		@grid.set_data(net_to_table($filtre))	
		buttoni("Refresh") { @grid.set_data(net_to_table($filtre)) }
		flowi do
			button("Filter") { prompt("Filter ?",$fi) { |value| $fi=value;$filtre=Regexp.new($fi) } }
			button("Periode") { 
				prompt("periode (ms) ?",@periode.to_s) { |value| 
					delete(@a)
					@periode=[1000,20000,value.to_i].sort[1]
					@a=anim(@periode) { @grid.set_data(net_to_table($filtre)) unless @active.active? }
				}
			}
			@active=check_button("Freese",false) 
		end
	end
	@a=anim(@periode) { @grid.set_data(net_to_table($filtre)) unless @active.active? }
end
