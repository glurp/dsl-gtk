# LGPL and Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
#################################################################
#  pingpongplot.rb : measure (tcp) ping on somme url
#
# can be use with pipeplot Ruiby gem
# Usage :
#   > ruby pingpongplot.rb  | ruby pipeplot.rb 0 0 300 pingpong auto
#   > ruby pingpongplot.rb  10.1.1.1 10.1.1.2 | pipeplot 0 0 300 pingpong auto -- 1 0 300 ping2 auto
#   > ruby pingpongplot.rb  -t 1000  10.1.1.2 | pipeplot 0 0 300 pingpong auto -- 1 0 300 ping2 auto
#################################################################
require 'minitcp'


$stdout.sync=true
if ARGV[0] && ARGV[0]=="-t" && ARGV.size>=2
  $periode=ARGV[1].to_i
  ARGV.shift;ARGV.shift;
else 
  $periode=2000  
end
if ARGV[0] && ARGV[0]=="-a" 
  $prevalue=true
  ARGV.shift
else 
  $prevalue=false 
end
if ARGV[0] && ARGV[0]=="-debug" 
  $debug=true
  ARGV.shift
else 
  $debug=false 
end

l=ARGV.size>0 ? ARGV : ["google.com"]

$data=(1..l.size).map {|| "0"}
l.each_with_index do |url,index|
  url,port=url.split(':')
  MClient.run_continious(url,(port||"80").to_i,$periode-100) do |socket|
    s=Time.now.to_f
    socket.on_any_receive() do |data| 
      p data if $debug
      $data[index]="#{((Time.now.to_f-s)*1000).round}"
      socket.close rescue nil
    end
    s=Time.now.to_f
    socket.print "GET /nodata-pingpong-test HTTP/1.0\r\nHost: ici\r\n\r\n"
    socket.wait_end
  end
end

1000.times {|i| l.size.times { print "#{rand(100..200)} " } ; puts } if $prevalue

Thread.new {|| loop {
  sleep 0.100
  data=$data.clone
  $stdout.puts data.join(" ")
  $stdout.flush
  sleep $periode/1000.0
} rescue nil  }.join
