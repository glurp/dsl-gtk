# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative 'Ruiby'


Ruiby.app width: 300,height: 200,title:"UpCase" do
  chrome(false)
  ctx=make_StockDynObject("simpl1",{"value" => "0" , "len" => 10, "res"=> ""})
  stack do
    flowi {
      sloti(toggle_button("D",false) {|v| chrome(v)})
      frame("Convertissor",margins: 20) do
       flowi { labeli "Value: " ,width: 200    ;  entry(ctx.value) ; button("reset") { ctx.value.value="" }}
       separator
       flowi { labeli "len: " ,width: 200    ;    entry(ctx.len)  }
       flowi { labeli "Resultat: " ,width: 200 ;  entry(ctx.res)  }
      end
    }
    flowi { 
      regular
      button("Validation") {  validation(ctx) }      
      button("Exit") { ruiby_exit } 
    }
  end
  def validation(ctx)
    Thread.new {
      sleep 3  # log time traitment...
      ctx.len.value= ctx.res.value.size
      ctx.res.value= ctx.value.value.upcase ; 
    }
  end
end