# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com> LGPL
#require 'Ruiby'
require_relative '../lib/Ruiby'

Ruiby.app width: 300,height: 200,title:"UpCase" do
  chrome(false)
  # create a class from a hash, instanciate on object which will save/restor at each stop/start of the script
  # structure of class and initale values are in the hash
  ctx=make_StockDynObject("simpl1",{"value" => "0" , "len" => 10, "res"=> ""})
  stack do
    flowi {
      sloti(toggle_button("D","ND",false,tooltip: "Window Frame border..." ) {|v| chrome(v)})
      frame("Convertissor",margins: 20) do
       flowi { 
         labeli "Value: " ,width: 200 
         entry(ctx.value,30,tooltip: "String to convert ro Upcase...")  
         button("reset") { ctx.value.value="" }}
       separator
       flowi { labeli "len: " ,width: 200    ;    entry(ctx.len,10,tooltip: "String length value")  }
       flowi { labeli " " ,width: 200        ;    islider(ctx.len)  }
       flowi { labeli "Resultat: " ,width: 200 ;  entry(ctx.res)  }
      end
    }
    flowi {  regular  # tool bar of buttons, each must have same size (regular on flow => same width)
      button("Validation") {  validation(ctx) }    
      button("Exit") { ruiby_exit } 
    }
  end
  def validation(ctx)  # a method appended to current class (private)
    Thread.new do
      sleep 1                               # long time traitment...
      ctx.res.value= ctx.value.value.upcase # DynObject automaticly notify in main thread context 
      ctx.len.value= ctx.res.value.size   
    end
  end
end