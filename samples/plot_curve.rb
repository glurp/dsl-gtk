# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
require_relative '../lib/Ruiby.rb'

def make_data(xmin,xmax,vmin,vmax)
 last=(vmax+vmin)/2
 p=(vmax-vmin)/50.0
 xmin.step(xmax,2).map {|x| 
  y=[vmin,vmax,last+p*rand(-1..1)].sort[1]
  last=y
  [y,x]
 }
end

$curves={
 a: {
     data: make_data(200  ,1300 ,100,1000), name:"Regis", 
     color: "#FAA",xminmax: [0,1300],yminmax: [100,1000]
 },
 b: {
     data: make_data(0  ,1000 ,10,100), name:"Alonso", 
     color: "#AAF",xminmax: [0,1300],yminmax: [10,100]
 } 
}

Ruiby.app width: 800,height: 300, title: "Plot curves" do
  flow do
    stacki do
      $curves.values.each {|d| labeli d[:name],bg: d[:color]}
      label("",bg:"#333")
    end
    c=plot(800,300,$curves,{
       bg: "#333", 
       tracker: [proc {|x| "Date: #{Time.at(Time.now.to_i+x)}"},proc  {|name,y| "#{name}: #{y} $"}]
    })
    lb1=([[0,0]]+$curves[:a][:data]).each_cons(2).each_with_object([]) {|((y0,x0),(y1,x1)),l| 
      c1=y0<300 ? "#F00" : y0>500 ? "#0F0": "#444"
      c2=y1<300 ? "#F00" : y1>500 ? "#0F0": "#444"
      (l << [x0,c1]) if c1!=c2
      (l << [x1,c2]) if c1!=c2
    }
    c.add_bar("rules a",[[0,"#00F"]]+lb1+[[1300,"#FFF"]])
  end
end