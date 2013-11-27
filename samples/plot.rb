# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative  '../lib/Ruiby'


Ruiby.app width: 400, height: 300, title: "Ploter test" do
  def aleac(pas=1) 
     l=[[50,0]]
     100.times { l << [l.last[0]+rand(-pas..pas),l.last[1]+1] }
     l
  end
  def alear() 
     l=[[50,50]]
     100.times { l << [l.last[0]+rand(-4..4),l.last[1]+rand(-4..4)] }
     l
  end
  a=b=c=nil
  stack do
     label("Test Ruiby 'plot' ",font: "Arial bold 22")
     separator
     a=plot(400,100,{"a"=> { data: aleac(), color: "#004050" , maxlendata: 100},
                   "b"=> { data: aleac(), color: "#FFA0A0"}})
     b=plot(400,100,{"b"=> { data: aleac(20)}})
     c=plot(400,100,{"c"=> { data: alear(),xminmax: [0,100],yminmax: [0,100]}})
  end
  t=3
  i=0
  anim(t) do 
    i+=1
    puts Time.now.to_f*1000  if i%(1000/t)==0
    a.scroll_data("a", [0,100,a.get_data("a").last[0]+rand(-5..5)].sort[1])
    a.scroll_data("b", [0,100,a.get_data("b").last[0]+rand(-10..10)].sort[1]) if Time.now.to_i%10<5
    b.get_data("b").each_cons(3) {|p0,p1,p2| p1[0]=(2*p1[0]+p0[0]+p2[0])/4 if p0 && p1 && p2}
    b.get_data("b")[0][0]=(b.get_data("b")[1][0]+b.get_data("b")[0][0])/2
    b.get_data("b")[-1][0]=(b.get_data("b")[-2][0]+b.get_data("b")[-1][0])/2
    c.get_data("c").each {|p| p[0]=p[0]+rand(-1..+1); p[1]=p[1]+rand(-1..+1) }
    b.redraw
    c.redraw
  end
end