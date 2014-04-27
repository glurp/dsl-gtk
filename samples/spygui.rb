#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#########################################################################################################
#  spygui.rb :  TCP proxy  for spy data exhange between an TCP client and a TCP Server
#
# based onem-proxy, which use Event Machine
# Ruiby as been adapted for ability to mixe event loop EM / Gtk
#
#########################################################################################################
require 'gtk3'
require 'em-proxy'
require_relative '../lib/Ruiby'
#require 'Ruiby'
require 'logger'

$glob=false
$ascii=false
$short=false
$proxy=nil
SLINE=90

# patching  em-proxy (Proxy.start do a EM.run; whichis done by Ruiby)
class Proxy
  def self.starting(options, &blk)
        @proxy=EventMachine::start_server(options[:host], options[:port],EventMachine::ProxyServer::Connection, options) { |c|
          c.instance_eval(&blk)
        }
  end

  def self.stop
    puts "Terminating ProxyServer.."
    if @proxy
      EventMachine.stop_server(@proxy)  rescue puts "Issue stoping proxy : #{$!}"
      @proxy=nil
    end
  end
end

Log = Logger.new('spylog.txt','daily')
Log.level = Logger::DEBUG

def datelog()  
  n=Time.now
  milli=((n.to_f - n.to_f.floor)*1000).round # %L not defined somewhere
  "@"+n.strftime("%H:%M:%S.")+"%03d"%[milli]
end
def sout(obj) ($ascii ? obj.to_s : obj.inspect).to_s end
def sdata(prefix,str0)
  str=if $short
    str0&&(str0.length>800 ?  str0.slice(0..800) + " ..." : str0)
  else
    str0||""
  end
  ($glob ? prefix+sout(str.gsub(/\r?\n/," <//> ")) : str.split(/\r?\n/).map {|l| prefix+sout(l)}.join("\n")).chomp
end

def area(t)  
  $ta.text=$ta.text+t+"\n" 
rescue Exception => e
$ta.text=$ta.text + "???\n"
end

def stop()    Proxy.stop              end
def taclear() $ta.text="cleared!"     end

def run(wspy,wtarget,stempo,str_size) 
  tempo= (stempo.size>0) ? (stempo.to_f)/1000.0 : nil
  tr_size=(str_size.size>0) ? str_size.to_i : nil
  tempo=22 if tr_size && ! tempo
  raise("missing proxy port number") if wspy[:port].text.size==0 || wspy[:port].text.to_i<=0
  raise("missing target host") if wtarget[:host].text.size==0 
  raise("missong target port") if wtarget[:port].text.size==0 || wtarget[:port].text.to_i<=0
  taclear()
  puts "log to spylog.txt"
  Proxy.starting(:host => "0.0.0.0", :port => wspy[:port].text.to_i, :debug => false) do |conn|
        conn.server :srv, :host => wtarget[:host].text, :port => wtarget[:port].text.to_i
        area "Starting..."
        # modify / process request stream
        conn.on_data do |data|
          area "#{"="*(SLINE/2)} #{data.split("\r\n")[0]} #{("="*(SLINE/2))}" if data=~/GET|PUT|POST|HEAD.*HTTP.1/
          #area "#{datelog()}|__data__: " +  sdata(">>:",data)
          Log.debug "#{datelog()}|__data__: " +  sdata(">>:",data)
          if tr_size
            it=1
            data.chars.each_slice(tr_size/2) { |ld| 
              s=ld.join("")
              tt=(tempo*it).to_i
              EM.add_timer( tt ) { 
                 p [tt,s]
                 @servers.values.first.send_data(s)  if @servers.values.size>0
              }
              it+=1
             }
             nil
          else
            data
          end
        end

        # modify / process response stream
        conn.on_response do |backend, data|
          #area "#{datelog()}|response: "  + sdata("<<:",data)
          Log.debug "#{datelog()}|response: "  + sdata("<<:",data)
          if tr_size
            it=1
            data.chars.each_slice(tr_size) { |ld| 
              s=ld.join("")
              EM.add_timer( (tempo*it).to_i) { send_data(s) ; area "  #{it} #{s.gsub(/\r?\n/," ")[0..100]}..."}
              it+=1
           }
           nil
          else
           data
          end
        end

        # termination logic
        conn.on_finish do |backend, name|
          area  "#{datelog()}|close? " +  backend.inspect
          Log.debug "#{datelog()}|close? " +  backend.inspect

          # terminate connection (in duplex mode, you can terminate when prod is done)
          if backend == :srv
            area "#{datelog()}|realy close " +  backend.inspect + "..."
            Log.debug "#{datelog()}|realy close " +  backend.inspect + "..."
            unbind rescue nil
          end
        end
  end
  area "EM started done"
end


Ruiby.app width: 800,height: 400,title: "Proxy" do
  wspy={}
  wtarget={}
  style={:font=>"Arial bold 12"}
  stack do
    stacki do
      table(0,0) do
        row {cell(button("Client",style)) ;cell_hspan(3,button(" Spy ",style)) ;cell(button("Target Server",style)) ;}        
        row { cell(label(""))}
        row { 
          cell(label("<clients>")) ; cell(label(" ==> "))  
          cell(box {flow{label("localhost:");wspy[:port]=entry("8181");}}) 
          cell(label(" ==> "))
          cell(box {
              label("target: host port")
              wtarget[:host]=entry("localhost")
              wtarget[:port]=entry("7070")
          }) 
        }
        row {cell(label("")) ;cell(label("")) ;cell(label("")) ;cell(label("  |  ")) ;}        
        row {cell(label("")) ;cell(label("")) ;cell(label("")) ;cell(label("  |  ")) ;}        
        row {cell(label("")) ;cell(label("")) ;cell(label("")) ;cell(label("  V  ")) ;}        
        row {
          cell_hspan_right(2,label("tempo tronconnage : ")) 
          cell(@et=entry("55",5,width: 40)) 
          cell(label("  Screen ")) ;
        }        
        row {
          cell_hspan_right(2,label("taille Tronconnage: ")) 
          cell(@st=entry("200",5,width: 40)) 
        }        
      end
      flowi { button("Run") {run(wspy,wtarget,@et.text,@st.text)} 
      button("Stop") {stop()}; 
      button("Clear") {taclear()}
      button("Logs..") {consult_log()}}
    end
    $ta=text_area(0,0,{font: "Courier bold 10"})
    buttoni("Exit") { exit!(0)}
    area("ok")
  end
  def consult_log()
    f=ask_file_to_read(".","*.txt")
    edit(f) if f && File.exists?(f)
  end
end


