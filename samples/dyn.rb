require_relative '../lib/Ruiby.rb'



################################ App test ###################################

Ruiby.app do
  stacki {
     labeli( <<-EEND ,font: "Arial 16",bg: "#004455", fg: "#CCCCCC")
     Testing variables binding for entry/slider/CheckButton/label. 
     
     Observer patern : Variables are Value Object,
     widget can be observer of a variable,
     so variable modification whill be showing in all widger observer,
     and a edition by a observer widger will be  notified to value object
     (like TkVariable)
     EEND
     
     v1=DynVar.stock("v1",1)
     framei("Int value",margins: 20) {
       framei("Dyn widget") {
         flowi { labeli "dyn label: " ;  label v1,bg: "#FFCCCC" ; bourrage 10 }
         flowi { labeli "dyn entry : " ;  entry v1 }
         flowi { labeli "dyn show/edit slider: " ;  islider v1 }
         flowi { labeli "dyn show     slider: " ;  islider v1 do end}
         flowi { labeli "dyn checkButton: " ;  check_button "!= 0",v1 }
         
       }
       flowi { labeli "editor (not dyn) :" ; entry("")  { |v| v1.value=v.to_i }                    }
       flowi { labeli "+/- button :" ; button("v1++") { v1.value=v1.value+1};  button("v1--") { v1.value=v1.value-1}          }   
     }
     
     v2=DynVar.stock("v2","99")
     framei("String value",margins: 20) {
       framei("Dyn widget") {
        flowi { labeli "dyn entry : " ; entry v2 }
       }
       flowi { labeli "editor (not dyn) :" ; entry("")  { |v| v2.value=v }  }
       flowi { labeli "+/- button :" ; button("v2++") { v2.value=v2.value+"a"};  button("v2--") { v2.value=v2.value[0..-2] }  }
     }
     v3=DynVar.stock("v3",true)
     framei("Boolean value",margins: 20) {
       framei("Dyn widget") {
        flowi { labeli "dyn check button: " ; check_button "True", v3 }
        flowi { labeli "dyn check button: " ; check_button "True", v3 }
       }
       label(v3) 
       flowi {  button("set tot true ") { v3.value=true};  button("set to false") { v3.value=false }  }
     }
  }
end