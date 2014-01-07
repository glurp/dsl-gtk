# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative '../lib/Ruiby.rb'


Ruiby.app width: 300,height: 200,title:"Calc" do
  chrome(false)
  @calc=make_StockDynObject("calc",{"res"=> 0,"value" => "0" , "stack" => [] })
  @calc.stack.value=eval @calc.stack.value
  stack do
    flowi {
      sloti(toggle_button("D",false) {|v| chrome(v)})
      frame("Calculator",margins: 20) do
       flowi { labeli "Resultat: " ,width: 200 ;  entry(@calc.res)  ; button("reset") { @calc.res.value="" ; @calc.stack.value=["0","reset"]}}
       flowi { labeli "Value: " ,width: 200    ;  entry(@calc.value) ; button("reset") { @calc.value.value="" }}
       flowi do
         regular
         '+ - * / syn cos'.split(' ').each { |op| button(op) { ope(op,@calc.res,@calc.value) } }
       end
      end
    }
    flowi { 
      regular
      button("Reset") {  @calc.stack.value=["0","reset"] ; @calc.res.value="0" ; @calc.value.value=""} 
      button("Trace") { alert((@calc.stack.value.slice(-20..-1)||@calc.stack.value).each_slice(2).map {|b,a| "%s %10.5f" % [a,b]}.reverse.join("\n")) } 
      button("Exit") { ruiby_exit } 
    }
  end
  
  def ope(ope,dvRes,dvVal)
     return if dvVal.value==""
     expr=ope.size==1 ? "#{dvRes.value.to_f.to_s} #{ope} #{dvVal.value.to_f.to_s}" : "Math.#{ope}(#{dvRes.value.to_f.to_s})" 
     res= eval(expr).to_f
    
     @calc.stack.value.push(dvVal.value)
     @calc.stack.value.push(ope)
     
     (ope.size==1 ? dvRes : dvVal).value=res.to_s 
     #dvVal.value=""
  rescue Exception => e
    alert("Expretion exotique : #{expr}")
  end
end