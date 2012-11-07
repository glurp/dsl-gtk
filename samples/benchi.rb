# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

####################################################################################################
#
#   Benchi.rb : Mesure duration of a (short) traitment
#
####################################################################################################
#
# Author : Regis d'Aubarede, @ Actemium
#
require_relative '../lib/ruiby'
require 'timeout'

$global=binding
class Test ; def self.test() 1 end ; end
Test.test()
date=Time.now
10_000.times {
Test.test()
Test.test()
Test.test()
Test.test()
Test.test()
Test.test()
Test.test()
Test.test()
Test.test()
Test.test()
}
$etalon=(Time.now-date).to_f*1_000_000/(10_000*10)

##################################################################################
############################# Ruiby App ##########################################
##################################################################################

class Appli < Ruiby_gtk
  def initialize() 
		super("Benchi",300,400) 
		rposition(90,100)
  end	
  def component()
	stack do
	#------------ title + entrys: search, commands
    stacki do
      flow do
			label "Global init : "
			@wi=entry "$data=(1..100).to_a" 
			button "Go" do 
				rep=eval(@wi.text.chomp) 
				alert(rep) if rep
			end
      end
    end	

	#------------ central  part
    stack do
	  @a=slot(text_area(300,150,:text=> Ruiby.stock_get("test1")  ) ) 
	  flowi do
	    button " Test " do
			code=@a.text
			Ruiby.stock_put("test1",code)
		    clear_append_to(@demo) do
				begin
					eval( "class Test ; def self.test()  #{code} ; end ; end ",$global)
					mlabel "Result=#{Test.test()}"
				rescue
					mlabel"Error: " + $!.to_s  
				end
		    end
	    end 
	    button " Go " do
		  Ruiby.stock_put("test1",@a.text)
		  clear_append_to(@demo) {  bench(@a.text) }
        end			
	  end
	  @b=slot(text_area(300,150,:text=> Ruiby.stock_get("test2") ) )
	  flowi do
	    button " Test " ,:width => 0.5 do
			code=@b.text
			Ruiby.stock_put("test2",code)
		    clear_append_to(@demo) do
				begin
					eval( "class Test ; def self.test()  #{code} ; end ; end ",$global)
					mlabel  "Result=#{Test.test()}"
				rescue
					mlabel "Error: " + $!.to_s  
				end
		    end
	    end 
	    button " Go " ,:width => 0.5 do
		  Ruiby.stock_put("test2",@b.text)
		  clear_append_to(@demo) {  bench(@b.text) }
        end			
	  end
	  sloti(button("Compare") do
		clear_append_to(@demo)do 
		  Ruiby.stock_put("test1",@a.text)
		  Ruiby.stock_put("test2",@b.text)
		  label "Starting..."
		  timeout(10.1) do 
		    v1=bench(@a.text)
		    v2=bench(@b.text)
			mlabel "#{(100.0*(v2-v1)/((v1+v2)/2.0)).round}% best for v2"
		  end
		end
	  end)
	  @demo=stack do 
	    # eval(code) rescue nil
	  end
    end
	end
  end
  def mlabel(arg)
	label(arg.to_s[0..100])
  end
  def bench(code)
	 begin
		eval( "class Test ; def self.test()  #{code} ; end ; end ",$global)
		__i=0
		pas=100 # number of Test.test() in the while()
		Test.test # raise error if bg
		begin
		 timeout(1.1) { Test.test }
		rescue
		  raise "Duration too long for code"
		end
		date=Time.now
		cible=date+2.0
		while (Time.now < cible)
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   Test.test() ; 
		   __i+=1
		end
		now=Time.now
		durn=((((now-date).to_f*1000_000_000.0)/(__i*pas)) - $etalon).round
		dur=((((now-date).to_f*1000_000.0)/(__i*pas)) - $etalon).round
		if dur<1
		  mlabel "Duration : #{durn} nanos / #{__i*pas} iterations"
		elsif dur<5000
		  mlabel "Duration : #{dur} micros / #{__i*pas} iterations"
		elsif dur<10_000_000
		  mlabel "Duration : #{(dur/1000.0).round} millis / #{__i*pas} iterations" 
		else
		  mlabel "Duration : #{(dur/1000_000.0).round} sec / #{__i*pas} iterations" if dur >=10_000_000 					
		end
		__i
	rescue Exception => e
		mlabel "Error: #{$!}" rescue p $!
	end
  end  
end
Ruiby.start_secure { Appli.new }

