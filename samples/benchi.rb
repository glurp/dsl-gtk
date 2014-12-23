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
require_relative '../lib/Ruiby'
require 'timeout'

$global=binding
class Test ; def self.test() 1  end ; end
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
$etalon_mis=(((Time.now-date).to_f)*1_000_000)/(10_000*100)
p "call cost : #{$etalon_mis*1000} ns"
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
	#------------ title + entry
    stacki do
      flow do
      buttoni("ed") do
        @commontext=Ruiby.stock_get("precode")
        dialog_async("Edit common...",
           :response => proc {
              @commontext=@editor.editor.buffer.text
              begin
                Ruiby.stock_put("precode",@commontext)
                rep=eval(@commontext,$global,"<script>",0) 
                alert(rep) if rep
                true
              rescue Exception => e
                error(e)
                false
              end
            }) {
					   @editor=source_editor(:width=>500,:height=>400,:lang=> "ruby", :font=> "Courier new 12")
					   @editor.editor.buffer.text=@commontext
					}
      end
			label "Global init : "
			@wi=entry "$data=(1..100).to_a" 
			buttoni "Go" do 
        begin
          rep=eval(@wi.text.chomp,$global,"<script>",0) 
          alert(rep) if rep
        rescue Exception => e
          error(e)
        end
			end
      end
    end	

	#------------ central  part
    stack do
	  @a=text_area(300,150,:font => "Courier new 12", :text=> Ruiby.stock_get("test1")  ) 
	  flowi do
	    button " Test " do
			code=@a.text
			Ruiby.stock_put("test1",code)
		    clear_append_to(@demo) do
				begin
					eval( "class Test ; def self.test()  #{code} ; end ; end ",$global,"<text>",1)
					mlabel "Result=#{Test.test()}"
				rescue Exception => e
					mlabel"Error: " + e.to_s  
				end
		    end
	    end 
	    button " Go " do
		  Ruiby.stock_put("test1",@a.text)
		  clear_append_to(@demo) {  bench(@a.text) }
        end			
	  end
	  @b=text_area(300,150,:font => "Courier new 12",:text=> Ruiby.stock_get("test2") ) 
	  flowi do
	    button " Test " ,:width => 0.5 do
			code=@b.text
			Ruiby.stock_put("test2",code)
		    clear_append_to(@demo) do
				begin
					eval( "class Test ; def self.test()  #{code} ; end ; end ",$global)
					mlabel  "Result=#{Test.test()}"
				rescue Exception => e
					mlabel "Error: " + e.to_s  
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
		  timeout(100.1) do 
		    v1=bench(@a.text)
		    v2=bench(@b.text)
			  mlabel "#{(100.0*(v2-v1)/((v1+v2)/2.0)).round}% best for v2" rescue nil
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
		eval( "class Test ; def self.test()  #{([code]*100).join(" ; ")} ;  end ; end ",$global)
		__i=0
		istep=100 # number of Test.test() in the while()
    cstep=100 # number of code duplication in Test.test
		#Test.test # raise error if bg
		begin
		 timeout(0.1) { Test.test }
		rescue Exception => e
		  raise "Duration too long for code"
		end
		date=Time.now
		cible=date+2.0
		while (Time.now < cible)
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
		   __i+=1
		end
		now=Time.now
		durn=(((((now-date).to_f*1000_000_000.0)/(__i*istep)) - $etalon_mis*1000)/cstep).round
		 dur=((((now-date).to_f*1000_000.0)/(__i*istep)) - $etalon_mis).round/cstep
		if dur<1
		  mlabel "Duration : #{durn} nanos / #{__i*istep} iterations"
		elsif dur<5000
		  mlabel "Duration : #{dur} micros / #{__i*istep} iterations"
		elsif dur<10_000_000
		  mlabel "Duration : #{(dur/1000.0).round} millis / #{__i*istep} iterations" 
		else
		  mlabel "Duration : #{(dur/1000_000.0).round} sec / #{__i*istep} iterations" if dur >=10_000_000 					
		end
		__i
	rescue Exception => e
		mlabel "Error: #{$!}" rescue p $!
	end
  end  
end
Ruiby.start_secure { Appli.new }

