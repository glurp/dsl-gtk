#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
##############################################################
#    bourse.rb
##############################################################
require 'json'
require 'httpclient'
require 'yahoo-finance'
require 'Ruiby'                       unless Dir.exists?("../lib/ruiby_dsl")
require_relative '../lib/Ruiby.rb' if Dir.exists?("../lib/ruiby_dsl")

require 'thread'
require 'date'
require 'pp'

$rfirst=! defined?($rfirst)

$cotes={
  "360114899" => {name: "Airbus"  , param1: 56.5  ,param2: 58.6, api: :lecho},
  "AIR.PA"    => {name: "YAirbus"  , param1: 56.5  ,param2: 58.6, api: :yahoo},
  "360194025" => {name: "EDF"     , param1: 17.7  ,param2: 17.8, api: :lecho},
  "360017060" => {name: "L'Oreal" , param1: 145.1 ,param2: 145.2, api: :lecho},
  "360114910" => {name: "Sanofi"  , param1: 87.7  ,param2: 87.8, api: :lecho},
  "360115975" => {name: "Vinci"   , param1: 55.5  ,param2: 56.6, api: :lecho},
  "360015511" => {name: "CAC40"   , param1: 80.7  ,param2: 90.8, api: :lecho},
  "GOOG"      => {name: "Google"  , param1: 630.0  ,param2: 635.0, api: :yahoo},
  "MSFT"      => {name: "Mi$"     , param1: 43.0  ,param2: 45.0, api: :yahoo},
  "GM"        => {name: "GM"      , param1:  29.0  ,param2: 32.0, api: :yahoo},
  "ATML"      => {name: "Atmel"   , param1: 7.0  ,param2: 9.0, api: :yahoo},
  "VLKPY"      => {name: "VolksW"   , param1: 20.0  ,param2: 30.0, api: :yahoo},
} if $rfirst
$file_config="bourse_config.rb"
$cotes=eval(File.read($file_config)) if File.exist?($file_config) && $rfirst

def calc_alarme(cote,values)
 return [false,false] unless values["last"]
 value=values["last"].to_f
 p1=cote[:param1]
 p2=cote[:param2]
 c1=(value < p1) ? "#FF4050" :  (value > p2) ? "#7F7" : $BGNOALARME
 c2=(value < p1*0.99) ? "#FF4050" :  (value > p2*1.01) ? "#7F7" : $BGNOALARME
 [c1,c2]
end

$nb_colonnes=ARGV.first || 2
$fr_ouverture=9..18 # heure ouverture cotations cac40
$us_ouverture=15..23 # heure ouverture cotations Nyse
$periode=60_000  # acquisition periode, ms
$BG="#383838"    # background color window
$PLOT0,$PLOT1="#111","#101010" # background plots zones (stroke/fill)
$TXTPLOT="#FFF"                # color text min/value/max un plot
$CVPLOT="#AAA"                 # shadow color of each  curve
$BGNOALARME=$BG                # alarme color non-active 


$url_lecho="http://1.ajax.lecho.be/rtq/?reqtype=simple&quotes=360015511&lightquotes=&group=g30_q_p"
$query_lecho={reqtype: "simple", quotes: 360015511, lightquotes: "", group: "g30_q_p"}

$url_yahoo="http://finance.yahoo.com"

$bgcolor=Ruiby_dsl.html_color($BG)
$hcotes={} if $rfirst
$COTES=$cotes.keys

#require 'nokogiri'


=begin
Data acquired with ajax.lecho.be :
try { _parseRtq(
  {"delay":60,"serverTime":1441820894526,
    "stocks":{       "360017060":{"volume":684414,"pct":"1.1573","high":"150.9500",   
      "last":"148.6000","low":"148.5500","prev":"146.9000","ask":"148.6000", "time":"17:35:00","bid":"148.5500","open":"150.1000"},
    ....
  }
  })
} catch(err) { if (console) console.error(err); }
=end

######################### sauvegardes courbes/restitution au demarrage

DATA_CURVES="curves2.data"
def save_curve(data)  
  File.open(DATA_CURVES,"wb") { |f| Marshal.dump(data,f) }
end
def load_curve()
  a={}
  if File.exists?(DATA_CURVES)
     File.open(DATA_CURVES,"rb") { |f| a=Marshal.load(f) }
  else
    a=$COTES.each_with_object({}) {|name,h| h[name]=[[100]*150,[100]*150] }
  end
  a
end
  
###################### Acqisition CAC40 aupres de lecho.be : javascript=>json=>data  
def get_data_lecho()
  h = HTTPClient.new()
  json=h.get($url_lecho,$query_lecho).body
  if json =~ /_parseRtq\(([^)]*?)\)\s*}\s*catch/
    JSON.parse($1)["stocks"] rescue (p $! ; {})
  else
    puts "noecho: no data"
    {}
  end
end
###################### Acqisition Yahoo Finance

  
def get_data_yahoo(lcotes)
  fields=[
    :name,
    :last_trade_price,:last_trade_time,
    :volume,:previous_close,
    :change_in_percent,
    :ask,:open,:bid
  ]
  yahoo_client = YahooFinance::Client.new
  l=yahoo_client.quotes(lcotes,fields)
  ret= l.zip(lcotes).each_with_object({}) {|(data,n),h|
     if data
       h[n]={
         "bname"  => data[:name],
         "volume" => nai(data[:volume]), 
         "pct"    => naf(data[:change_in_percent].gsub(/%\s*$/,"")), 
         "last"   => naf(data[:last_trade_price]),  
         "time"   => ftime(data[:last_trade_time]),
         "ask"   => naf(data[:ask]),  
         "open"   => naf(data[:open]),  
         "bid"   => naf(data[:bid]),  
         "prev"   => naf(data[:previous_close]),
         "unit"   => '$',
       }
     end
     #gui_invoke {alert("#{n} => #{h[n].inspect}") } if $first
  }
  pp ret
  return ret
end

def nai(s) s.to_i rescue 0 end
def naf(s) s.to_f rescue 0.0 end

def ftime(h) # 10:35am => 10:35, 02:35pm => 14:35
  case h
    when /(\d+):(\d+)am$/ then "#{$1}:#{$2}:00"
    when /(\d+):(\d+)pm$/ then "#{$1.to_i+12}:#{$2}:00"
    else
       puts "unknown time : #{h}"
      "00:00:00"
  end
end

##################### Moteur d'aquisition
$first=true

def get_update(app)
  return if Thread.list.size>2
  Thread.new {
    now=Time.now
    if  $first || $fr_ouverture.member?(Time.now.hour)
        h=(get_data_lecho rescue nil)
        next if !h || h.size==0 || !(Hash === h)
        hh=$COTES.each_with_object({})  {|cote,r| r[cote]=h[cote].merge({"unit"=>'€'}) if h[cote]}
        $hcotes.merge!(hh)
    end
    names=$COTES.select {|k| $cotes[k][:api]==:yahoo}
    p names
    if ($first || $us_ouverture.member?(Time.now.hour)) && names.size>0
          h=(get_data_yahoo(names) rescue p $! )
          next if !h || h.size==0 || !(Hash === h)
          $hcotes.merge!(h)
    end
    $first=false
    gui_invoke { push_data($hcotes) ; @cv.redraw()  rescue p $!}
    Historique.memo(now,$hcotes)
  }
end

####################### Archivage

Dir.mkdir("tradingdata") unless Dir.exists?("tradingdata")

class Historique 
  class << self
    def to_dir(top)
      dir="tradingdata/#{top.gmtime.strftime("%Y_%m")}"
      Dir.mkdir(dir) unless Dir.exists?(dir)
      dir
    end
    def to_sec(top) (top.gmtime.to_i % (24*3600)) end
    def from_i(gm_timestamp)
      dt=DateTime.strptime(gm_timestamp.to_s,'%s')
    end
    def memo(time,data)
      dir=to_dir(time)
      top=to_sec(time)
      hdata=data.clone
      hdata['_time']=top
      hdata['_timestamp']=time.gmtime.to_i 
      filename="#{dir}/#{time.day}.data"
      File.open(filename,"a+") { |f| f.puts(hdata.inspect) }
    end
    def read(t0,t1,lcotes)
      date0,date1=t0.gmtime.strftime("%Y_%m"),t1.gmtime.strftime("%Y_%m")
      t0gmt,t1gmt=t0.gmtime.to_i,t1.gmtime.to_i
      lvalues=(0..lcotes.size-1).map {[]}
      (date0..date1).each do |date| 
        next unless Dir.exists?("tradingdata/#{date}")
        Dir.glob("tradingdata/#{date}/*.data").sort.map  do |filename|
          numday=File.basename(filename).gsub(".data","").gsub(/^0/,"").to_i
          lv=File.readlines(filename).map do |line| 
            h=eval(line)
            tm=h['_timestamp']
            next if tm<t0gmt 
            return(lvalues) if tm>t1gmt
            lcotes.each_with_index {|cote,i| ( lvalues[i] << [h[cote]["last"].to_f,tm ] ) if h[cote] }
          end # end read each line
        end #end glob*.each
      end # end d0..d1
      return(lvalues) 
    end # end read
    
    def show(app)
      app.instance_eval do
        #======================== dialog choix cotes et periode
        profondeur=DynVar.new(1)
        ok=dialog("Cotes") do
          stack do
            labeli "  Choisir les cotes a extraire  "
            separator
            $cotes.values.each {|d| 
              d[:ok]=false
              check_button(d[:name],false) { |ok| d[:ok]=ok }
            }
            separator
            stacki {
              labeli "Profondeur d'extration (nb jour):"
              islider(profondeur,:min=>0,:max=>180,:by => 1) 
              wnbj=labeli "1 jour" 
              profondeur.observ {|v| wnbj.label= "#{v} Jours"}
            }
          end
        end
        return unless ok 
        #======================= extration datas et mise en formes
        lcotes=$cotes.each_with_object([]) {|(k,v),a| a<<k if v[:ok]}
        return unless lcotes.size>0
        delta= profondeur.value>0 ? (profondeur.value*24*3600) : (6*3600)
        datas=Historique.read(Time.now-delta,Time.now,lcotes)
        xminmax=datas[0].minmax_by {|(y,x)| x}.map {|(y,x)| x}
        hc=lcotes.each_with_object({}) { |cote,h|
          s={
           name: $cotes[cote][:bname] || $cotes[cote][:name],
           data: datas[h.size],
           color: %w{#F00 #FF0 #F0F #0FF #A0A #BBB}[h.size%6],
           xminmax: xminmax,
           yminmax: datas[h.size].minmax_by {|(y,x)| y}.map {|(y,x)| y}
          }
          h[cote]=s
        }
        #======================= Affichage courbes
        dialog_async("Archives Ploter",response: proc {true}) {
          stack {
             flow { 
               cc=canvas(70,300) {  # labels des cotes
                  on_canvas_draw { |w,ctx| 
                    cc.draw_rectangle(0,0,70,300,0,$BG,$BG,0)
                    hc.each_with_index { |(k,d),i| 
                      cc.draw_text(3,(i+1)*16,d[:name],1.2,d[:color])
                    }
                  }
               }
               c=plot(600,300,{},{bg: $BG, tracker: [proc {|x| Time.at(x).to_s},proc  {|name,y| "#{name}: #{y} $"}]})
               hc.each {|k,d| c.add_curve(k,d) }
             }
             flowi {
              button("<<")
              button(">>")
             }
          }
        }        
      end
    end
    
  end #class self
end
################################################################
#                  C o n f i g u r a t i o n 
################################################################

module Ruiby_dsl
  def dialog_minmax(wbutton,h,value)
    f1=DynVar.new(h[:param1])
    f2=DynVar.new(h[:param2])
    ok=dialog_async("Saisie Seuils #{h['name']}", response: proc {
      if f1.value<f2.value
        wbutton.label="#{f1.value}..#{f2.value}"
        h[:param1]=f1.value
        h[:param2]=f2.value
        File.write($file_config,$cotes.inspect)
        true
      else
        false
      end}
    ) do
      stack do
        label("#{h[:name]} : #{value}",font: "Arial bold 33px")
        separator
        flowi {  entry(f1) ; entry(f2) }
        a=label('',font: "Arial 33")
        f1.observ {|v| a.text= v<f2.value ? "Ok":"Nok: p1>p2 !"}
        f2.observ {|v| a.text= v>f1.value ? "Ok":"Nok: p2<p1 !"}
        stacki {
          fslider(f1,:min=>(f1.value*0.8),:max=>(f2.value*1.1),:by => 0.1,:decimal=>2) 
          fslider(f2,:min=>(f1.value*0.8),:max=>(f2.value*1.1),:by => 0.1,:decimal=>2) 
        }
      end
    end
    if ok
      
    end
   end
   def configuration_trading()
    dialog_async("Configuration",{response: proc {
        #alert($cotes)
        true
    }}) do
      stack do table(0,0) do
          row {
            cell(label('clef'));cell(label('name'));
            cell(label('param 1&2'));cell(label('api'))
          }            
          $cotes.each do |k,v|
            row do
              cell(label(k));cell(label(v[:name])) 
              x=nil
              x=cell(button("#{v[:param1]}..#{v[:param2]}") { |w| 
                dialog_minmax(w,v,$hcotes[k]["last"]) 
              })
              cell(label(v[:api].to_s))
            end # end row       
          end # end each
        end end # end stack
      end # end dialog
  end
end

###################################################
##         D e s s i n   f e n e t r e
###################################################
module Ruiby_dsl
  def expose_trading(cv,ctx)
    return if $hcotes.size<1
    top=Time.now
    @sx,@sy=size()
    @wcurve=@sx/@nb_col
    @hcurve=((@sy-12-2-12-15-24-3)/($hcotes.size*2) - 14)*@nb_col
    @cv.draw_rectangle(0,0,@sx,@sy,1,"#AAA",$BG,3)
    y=10
    x=2
    
    ############# Rappel des alertes
    
    $cotes.keys.each_with_index do |k,i| 
      v=$hcotes[k]
      car=$cotes[k][:name][0,1]
      calc_alarme($cotes[k],v).each_with_index {|color,col|
            x,y=2,y+12 if x>=@sx-20
            if col==0
              @cv.draw_text(x,y,car,0.8,"#FFF") 
              x+=7
            end
            @cv.draw_rectangle(x,y-5,6,3,0,$BGNOALARME, color,0) 
            x+=7
      }
      x+=5
    end    
    y+=2
    x+=3
    @cv.draw_line([7,y,@sx-7,y],"#FFF",2)
    y+=16
    y00=y
    ############# Zone detailles cotations: alerte+nom+valeur+courbes
    
    x=5
    $cotes.keys.each do |k|  v=$hcotes[k]
      if y>@sy-30-@hcurve*2
        y=y00
        x+=@wcurve+2
        @cv.draw_line([x-1,y,x-1,@sy],"#FFF",1)
        #alert(" changement colonne: #{x} #{y}")
      end
      calc_alarme($cotes[k],v).each_with_index {|color,ii|
            @cv.draw_rectangle(x+2+11*(ii),y-10,10,10,4,$BGNOALARME, color,2) 
      }
      @cv.draw_text(x+24,y+2,"#{$cotes[k][:name]}",1.7,"#FFE")       
      @cv.draw_text_left(
             x+@wcurve-2,y+2,
             "#{v["unit"]}#{v["last"].to_f.round(2)} #{v["pct"].to_f.round(0)}%",
             1.5,
             "#FFE",$BG
      )  
      y+=10
      y=draw_curve1(@lcurve[k][0] ,0 ,x,y, "€"   , :brute , v["prev"].to_f)+3
      y=draw_curve1(@lcurve[k][1] ,1 ,x,y, "vol" , :delta, 0)
      y+=13
    end
    
    ######################  bs de page: heure derniere cotation
    
    y+=10
    @cv.draw_text(@sx/2-30,y-8,$hcotes.values.first["time"],1.0,"#FFE") if $hcotes.size>0 
    y+=3
    if false
      @cv.set_size_request(@sx-2,y) 
      move(1,1)
    end
    save_curve(@lcurve)
  rescue Exception => e
    log(e)
  end
  def push_data(h)
    h.each_with_index {|(k,v),i| 
      next unless Hash === v
      begin
        @lcurve[k]=[[100]*150,[100]*150] unless @lcurve[k] && @lcurve[k].size==2
        curve=@lcurve[k][0]   ; curve.push(v["last"].to_f) ; curve.shift while curve.size>150
        curve=@lcurve[k][1]   ; curve.push(v["volume"])    ; curve.shift while curve.size>150
      rescue Exception => e
        p e
        p k,v,i
      end
    }
  end
  def draw_curve1(curve,i,x0,y0,unit, type, vy)
    w=@sx-4
    h=@hcurve
    @cv.draw_rectangle(x0,y0,@wcurve,h,1,$PLOT0,$PLOT1,2)
    coul="##{%w{FF4 4F4 6060FF FF6060 44F 4FF}[i]}"
    
    data= if type==:brute
      curve
    else 
      a=curve.each_cons(2).map { |a,b| b-a}
      min,max=a.minmax
      i=2
      a.each_cons(5) {|l| 
        m=l[2]
        mm=(l[0]+l[1]+l[3]+l[4])/4.0
        a[i]=mm if (m==min || m==max) && (m-mm).abs> (max-min)/5.0
        i+=1
      }
      a
    end
    min,max=data.minmax
    if unit=="€" 
      min,p,max=[min,vy,max].sort
    end
    if unit=="€" && (max-min).abs<1
      min,max=min-1,max+1
    end
    min,max=min-50,min+50 if min==max
    dx=1.0*@wcurve/data.size
    lxy=data.each_with_index.map {|v,t| [x0+dx*t,y0+h-1.0*(v-min)*h/(max-min)]}.flatten
    
    @cv.draw_line(lxy,$CVPLOT,3)
    @cv.draw_line(lxy,coul,1)
    if unit=="€" 
      y=y0+h-1.0*(vy-min)*h/(max-min)
      @cv.draw_line([x0+2,y,x0+@wcurve-2,y],"#F00",1)
    end
    @cv.draw_text(x0+5,y0+(1)*8,"#{unit} #{min} .. #{max}",0.8,$TXTPLOT)  
    (y0+h)
  end

end


###############################################################
#    M A I N : fenetre et moteur d'acquisition
###############################################################
Ruiby.app width: 150*$nb_colonnes,height: 600, title: "Boursicotons" do
  def cv_redraw() @cv.redraw() end
  chrome(false)
  @chrome=false
  set_resizable(true)
  move(10,30)
  @lv=[]
  @s={}
  @lv_last=[]
  @bddtr={}
  @marche_ok=false
  @lcurve=load_curve()
  @nb_col=$nb_colonnes
  stack do 
    @cv=canvas(150,600) do
      on_canvas_draw { |w,ctx| expose_trading(w,ctx) } 
      on_canvas_button_press { |w,e| 
        @chrome=!@chrome
        chrome(@chrome)
        false # event is not consume; di the popup...
      } 
    end		
    flowi { 
      button("Load") { load(__FILE__); }
      button("Arch") { Historique.show(self)  }
      button("Conf.") { configuration_trading() }
      button("Ref.") { after(1) { get_update(self) } }
      buttoni("Exit")   { exit!(0) }
    }
  end
  
  def_style <<EEND
* {background: #{$BG}} 
.button { 
  background: #444 ;
  background-image: none;
  font: Sans bold 8px;
  color: #CCC;
  border-radius: 5px;
  padding: 3px 7px 2px 5px;
  border-top-left-radius: 12px;
  border-width: 1px;
  -GtkButton-shadow-type:none;
  -GtkWidget-focus-line-width: 0;
}
GtkLabel { background:transparent; color: #FFC ; font: Sans  10px;}
GtkEntry { background:transparent; color: #FFC ; font: Sans bold 10px;}

EEND
  after(100) { get_update(self) ; anim($periode) { get_update(self) } } # update periodique
  anim(2000) { set_keep_above(true) if $nb_colonne==1} # maintin en avant plan de la fenetre
end if $rfirst
$rfirst=false


