#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
require_relative '../lib/Ruiby.rb'

Ruiby.app width: 600, height: 200, title: "Sentences container" do
  stack do
    labeli "Sentence",font: "Arial bold 20",bg: "#066",fg: "#FFF"
    sentence {  
      14.times {|i| 
         case i%3
           when 0 then label("label #{i}")
           when 1 then button("b#{i}")
           when 2 then entry("e#{i}",10)
         end       
      }
      label("END")
    }
    separator
    labeli "Sentenci",font: "Arial bold 20",bg: "#067",fg: "#FFF"
    sentenci {  
       10.times {|i| i%3==0 ? label("label #{i*100}") : button("button #{i*100}")}
       label("END")
    }
    show_source
    buttoni("Exit") { exit! }
  end
end