# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

=begin
DynVar is a Value object (as TkVariable) : 
* a DynVar represent a ruby variable, which recover read/write access.
* observer patern is use for to subscribe to a variable : each vriting will be submmitted to each
  subscriber
DynVar.stock(name,value) can be used for ensure that value will be persist to file by Ruiby-stock mecanisme.

Usage :
    var=DynVar.new(22)
    var.observ {|v| puts v} 
    .....
    Thread.new { sleep 1 ; var.value=var.value+1 }
    ....
    sleep 

v=DynVar.stock("VV",33)
p v.value
v.value=44
exit(0)

>first execution: 
 33
>seconde execution :
 44

Ruiby Usage:
===========
In widgets <entry,ientry,label,islider,check_button> the initial value (generaly a Number or a String) can be replaced by a DynVar 

>exemple :
v=DynVar("aa")
entry(v)
label(v)

>> each input in entry will change the string qshowed by label

see samples/dyn.rb

=end

################## Variable binding for widget : (shower/editor widget) <==> (int/float/string/bool variable) ###########

class DynVar
  class << self
    def stock(name,defv) 
      v= Ruiby.stock_get(name,defv)
      var=DynVar.new(v,name)
      if ! @ldyn
         @ldyn=[]    
         at_exit { DynVar.save_stock }
      end
      @ldyn << var
      var
    end
    def save_stock 
      (@ldyn||[]).each { |v| Ruiby.stock_put(v.name, v.value.to_s) if v.name }
    end
  end
  def initialize(v,name="") @value=v ; @abo={} ; @name=name end
  def set_name(name) @name=name                            end
  def name() @name                                         end
  def observ(&blk)  @abo[caller] = blk  ; blk.call(@value) end
  def do_notification()
    abo=@abo
     value=@value
     gui_invoke_wait { abo.each { |a,b|  b.call(value) } } if @abo.size>0  
  end
  def value=(v)     @value=v ; do_notification()           end
  def value()       @value                                 end
  def set_as_bool(v) 
    @value=case  @value
         when Numeric then v ? 1 : 0 
         when String then v ? "1" : ""
         else !!v
    end
    do_notification()
  end
  def get_as_bool() 
    case @value
    when Numeric then @value!=0 
    when String then @value && @value.length>0
    else 
      !! @value
    end
  end
end

################################# Object binding
# As Struct, but data member are all DynVar
# see samples/dyn.rb
def make_DynClass(h={"dummy"=>"?"})
  Class.new() do
    def initialize(x={})
      @values=self.def_init().merge(x).each_with_object({}){ |(name,v),h|  h[name]=DynVar.new(v) }
    end
    define_method(:def_init) { h.dup } 
    define_method(:keys) {  h.keys }
    define_method(:to_h) {  @values.each_with_object({}) { |(k,v),h1| h1[k]=v.value} }
    h.each do |key,value|
      define_method(key) { @values[key] }
    end
  end
end  

# make_DynClass, but data are saved at exit time.
# see samples/dyn.rb
def make_StockDynClass(h={"dummy"=>"?"})
  Class.new() do
    def initialize(oname="",x={})
      @values=self.def_init().merge(x).each_with_object({}){ |(name,v),h| h[name]=DynVar.stock(oname+"/"+name,v)}
    end
    define_method(:def_init) { h.dup } 
    define_method(:keys) {  h.keys }
    define_method(:to_h) {  @values.each_with_object({}) { |(k,v),h1| h1[k]=v.value} }
    h.each do |key,value|
      define_method(key) { @values[key] }
    end
  end
end  
def make_StockDynObject(oname,h) make_StockDynClass(h).new(oname) end


