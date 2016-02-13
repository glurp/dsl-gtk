require '../lib/Ruiby.rb'

########################## Exemple

module Ruiby_dsl
  def comp(*args)
    c=install_composant(self,Comp.new(*args))
  end
end
class Comp < AbstractComposant
   attr_reader :name
   def initialize(name)
      @name= name
   end
   def component() 
    framei("Component Comp:#{@name}") do
      label_clickable("B#{@name}...") { ppp(@name) }
      entry(@name,4)
    end
   end
   def ppp(n)
     log("cc")
     alert("from #{self.inspect} #{n}")
     prompt("ok?") {|a| alert(a) }
   end
end

#################### Test


Ruiby.app width: 800, height: 400, title: "Composant test" do
 stack do
   comp "eeeeeeeee"
   wa=flowi {}
   flowi {5.times {|a|  comp a.to_s } ;  }
   button("add one composant") { 
      append_to(wa) { 
          a=(wa.children.size+1).to_s
          comp(a) { alert(a) }
      } 
   }
 end
end
