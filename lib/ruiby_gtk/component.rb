# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

# class father of all component
# is 'like' a Window class : it delagate DSL words to  @win member
class AbstractComposant
 include Ruiby_dsl
 def install(cur) 
    @lcur=cur
    p @lcur.last.methods.sort.grep /win/
    @win=$app
    @ltable=[]
    @current_widget=nil
    @cur=nil
    begin
      component
    rescue Exception => e
      error("Composant error  : "+$!.to_s + " :\n     " +  $!.backtrace[0..10].join("\n     "))
    end
 end
 
 ########## Delegate window dsl words
 
 def alert(*t) @win.alert(*t) end
 def error(*t) @win.alert(*t) end
 def prompt(*t,&b) @win.prompt(*t) { |v| b.call(v) } end
 def ask(*t) @win.ask(*t) end
 def log(*t) @win.log(*t) end
end

# helper for install a component.
# when use a component, define in Ruiby_dsl word:
#  def component_name(*args)
#    c=install_composant(self,ClassCompenent.new(*args))
#  end
# ClassCompenent must inherit from AbstractComposant and define 
# component method (as a window)
# class XX < AbstractComposant
#    def component
#      stack { .... }
#    end
# end
module Ruiby_dsl
  def install_composant(window,componant)
     componant.install( window.instance_eval { @lcur } )
  end
end
