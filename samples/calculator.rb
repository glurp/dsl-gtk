# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative '../lib/Ruiby'
#require 'Ruiby'

DIV="\u00f7" # symbole division en utf-8

class RubyApp < Ruiby_gtk
    def initialize()
      super("Calculator",40,70)  
      @stack=[]
      @history=[]
      @tbc =false
    end
    def push(a) @stack << a end
    def pop() ret=@stack.last ; @stack=@stack[0..-2] ; ret end
    def add_number(n) 
       sn=n.to_s
       button(sn) {  
           if @tbc
             @number.value="" 
             @tbc=false
           end
           @number.value="#{@number.value}#{sn}" 
       } 
    end
    def add_ope(op) 
      b=case op
        when /\+|\-|x|#{DIV}/ then button(op) { push(@number.value) if @number.value.size>0 ; @tbc=true; push(op) }
        when "."              then button(op) { @number.value=(@number.value||"")+"." if @number.value !~ /\./ }
        when "="              then button(op) { calc(pop(),pop(),@number.value) if @stack.size >= 2 }
        when "Clear"          then button(op) { @number.value="" }
      end
    end
    def calc(op,a,b)
        res= case op
          when "x" then a.to_f * b.to_f
          when DIV then a.to_f / b.to_f
          when "+/-" then -1*a.to_f 
          else
           a.to_f.send(op.strip,b.to_f) rescue "Error"
        end
        res=res.to_i if (res-res.to_i).abs < 0.000000009
        @history<< "#{a}#{op}#{b} => #{res}"
        @number.value=res.to_s
        @tbc =true
        push res.to_f
    end
    def show_history()
       return if @history.size==0
       dialog { stack { @history.each {|a| label a}  ; label ""; separator} }
    end
    def component()  
      @ed=[]
      @change=false
      @number=DynVar.new("")
      stack {
        flow {
          button("^") { show_history }
          entry(@number,20)
          add_ope("Clear") 
        }
        flow { add_number(7);add_number(8);add_number(9) ; add_ope(DIV) }
        flow { add_number(4);add_number(5);add_number(6) ; add_ope("x") }
        flow { add_number(1);add_number(2);add_number(3) ; add_ope("-") }
        flow { add_ope("+/-")  ; add_number(0);add_ope(".")  ; add_ope("  +  ") }
        flow { add_ope("=") }
      }
  def_style <<EEND
button {
  border: none;
  color: #003333 ;
}
EEND
  end
end

window = RubyApp.new
Gtk.main
