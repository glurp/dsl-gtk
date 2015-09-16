#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
##############################################################
#    bourse.rb
##############################################################
require_relative 'Ruiby/lib/Ruiby.rb'

$cotes={
  "360114899" => {name: "Airbus"  , param1: 56.5  ,param2: 58.6},
  "360194025" => {name: "EDF"     , param1: 17.7  ,param2: 17.8},
  "360017060" => {name: "L'Oreal" , param1: 145.1 ,param2: 145.2},
  "360114910" => {name: "Sanofi"  , param1: 87.7  ,param2: 87.8},
  "360115975" => {name: "Vinci"   , param1: 55.5  ,param2: 56.6},
  "360015511" => {name: "CAC40"   , param1: 80.7  ,param2: 90.8},
}

def calc_alarme(cote,values)
 value=values["last"].to_f
 p1=cote[:param1]
 p2=cote[:param2]
 c1=(value < p1) ? "#FF4050" :  (value > p2) ? "#7F7" : $BGNOALARME
 c2=(value < p1*0.99) ? "#FF4050" :  (value > p2*1.01) ? "#7F7" : $BGNOALARME
 [c1,c2]
end

$ouverture=9..18 # heure ouverture cotations cac40
$periode=60_000  # acquisition periode, ms
$BG="#383838"    # background color window
$PLOT0,$PLOT1="#111","#101010" # background plots zones (stroke/fill)
$TXTPLOT="#FFF"                # color text min/value/max un plot
$CVPLOT="#AAA"                 # shadow color of each  curve
$BGNOALARME=$BG                # alarme color non-active 


$url="http://1.ajax.lecho.be/rtq/?reqtype=simple&quotes=360015511&lightquotes=&group=g30_q_p"
$query={reqtype: "simple", quotes: 360015511, lightquotes: "", group: "g30_q_p"}

$bgcolor=Ruiby_dsl.html_color($BG)
$hcotes={}
$COTES=$cotes.keys

require 'json'
require 'thread'
require 'httpclient'
require 'pp'
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

DATA_CURVES="curves.data"
def save_curve(data)  
  File.open(DATA_CURVES,"wb") { |f| Marshal.dump(data,f) }
end
def load_curve()
  a=(0..20).map { [100]*150 }
  if File.exists?(DATA_CURVES)
     File.open(DATA_CURVES,"rb") { |f| a=Marshal.load(f) }
  end
  p "data loaded size=#{a.size}"
  a
end
  
###################### Acqisition CAC40 aupres de lecho.be : javascript=>json=>data  
def get_data()
  h = HTTPClient.new()
  json=h.get($url,$query).body
  if json =~ /_parseRtq\(([^)]*?)\)\s*}\s*catch/
    JSON.parse($1)["stocks"] rescue (p $! ; {})
  else
    puts "no data"
    {}
  end
end

$first=true

def get_update(app)
  return unless  $first || $ouverture.member?(Time.now.hour)
  Thread.new {
    h=(get_data rescue nil)
    next if !h || h.size==0 || !(Hash === h)
    hh=$COTES.each_with_object({})  {|cote,r| r[cote]=h[cote] if h[cote]}
    $hcotes=hh
    #puts "====="
    #$hcotes.each {|(k,d)| puts "#{k} #{$cotes[k].ljust(9)}: time=#{d["time"]} vol=#{d["volume"]} pct=#{d["pct"]} value=#{d["last"]}"}
    #puts ""
    $first=false
    gui_invoke { push_data ; @cv.redraw()  rescue p $!}
  }
end
###############################################################
#    M A I N : fenetre et moteur d'acquisition
###############################################################

Ruiby.app width: 150,height: 600, title: "Boursiconton" do
  def cv_redraw() @cv.redraw() end
  chrome(false)
  @chrome=false
  set_resizable(true)
  move(1,800)
  @lv=[]
  @s={}
  @lv_last=[]
  @bddtr={}
  @marche_ok=false
  @lcurve=load_curve()
  stack do 
    @cv=canvas(150,600) do
      on_canvas_draw { |w,ctx| expose(w,ctx) } 
      on_canvas_button_press { |w,e| 
        @chrome=!@chrome
        chrome(@chrome)
        false # event is not consume; di the popup...
      } 
    end		
    flowi { 
      button("C.") {  }
      button("R.") { after(1) { get_update(self) } }
      buttoni("Exit")   { exit!(0) }
    }
  end

  ###################################################
  ## expose() : redessine l'ihm : courbes...
  ###################################################
  def expose(cv,ctx)
    return if $hcotes.size<1
    top=Time.now
    @sx,@sy=size()
    @hcurve=(@sy-12-2-12-15-24-3)/($hcotes.size*2) - 14
    @cv.draw_rectangle(0,0,@sx,@sy,1,"#AAA",$BG,3)
    y=10
    x=2
    $hcotes.each_with_index do |(k,v),i| 
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
    $hcotes.each_with_index do |(k,v),i| 
      x=5
      calc_alarme($cotes[k],v).each_with_index {|color,ii|
            @cv.draw_rectangle(x=2+11*(ii),y-10,10,10,4,$BGNOALARME, color,2) 
      }
      @cv.draw_text(x+16,y+2,"#{$cotes[k][:name]}",1.7,"#FFE")       
      @cv.draw_text_left(
             @sx-2,y+2,
             "€#{v["last"].to_f.round(2)} #{v["pct"].to_f.round(0)}%",
             1.5,
             "#FFE",$BG
      )  
      y+=10
      icurve=i*2
      y=draw_curve1(icurve   ,y, "€"   ,:brute , v["prev"].to_f)+3
      y=draw_curve1(icurve+1 ,y, "vol" , :delta, 0)
      y+=13
    end
    y+=10
    @cv.draw_text(@sx/2-30,y-8,$hcotes.values.first["time"],1.0,"#FFE") if $hcotes.size>0 
    y+=3
    if false && y>sy
      @cv.set_size_request(@sx-2,y) 
      move(1,1000-y)
    end
    save_curve(@lcurve)
  rescue Exception => e
    log(e)
  end
  def push_data()
    $hcotes.each_with_index {|(k,v),i| 
      curve=@lcurve[i*2]   ; curve.push(v["last"].to_f) ; curve.shift while curve.size>150
      curve=@lcurve[i*2+1] ; curve.push(v["volume"])    ; curve.shift while curve.size>150
    }
  end
  def draw_curve1(i,y0,unit, type, vy)
    w=@sx-4
    h=@hcurve
    curve=@lcurve[i]
    @cv.draw_rectangle(2,y0,w,h,1,$PLOT0,$PLOT1,2)
    coul="##{%w{FF4 4F4 6060FF FF6060 44F 4FF}[(i/2)%6]}"
    
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
    else
      #min,max=0,30000
    end
    min,max=min-50,min+50 if min==max
    dx=1.0*w/data.size
    lxy=data.each_with_index.map {|v,t| [dx*t,y0+h-1.0*(v-min)*h/(max-min)]}.flatten
    
    @cv.draw_line(lxy,$CVPLOT,3)
    @cv.draw_line(lxy,coul,1)
    if unit=="€" 
      y=y0+h-1.0*(vy-min)*h/(max-min)
      @cv.draw_line([2,y,@sx-2,y],"#F00",1)
    end
    @cv.draw_text(5,y0+(1)*8,"#{unit} #{min} .. #{max}",0.8,$TXTPLOT)  
    (y0+h)
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
  anim(2000) { set_keep_above(true) } # maintin en avant plan de la fenetre
end


