require_relative 'rspec_helper.rb'

describe Ruiby do
 before(:each) do
	@win= make_window
	Ruiby.update
 end
 after(:each) do
	Ruiby.update
	sleep(0.05)
	Ruiby.update
	@win.destroy 
	Ruiby.update
 end
 it "create a button" do
		s=nil;@win.create { s=stack {  } }
		@win.append_to(s) { @win.button("CouCou") { puts "coucou" } }
		s.children.size.should eq(1)
 end
 it "create a label" do
		s=nil;@win.create { s=stack {  } }
		@win.append_to(s) { @win.label("CouCou")  }
		s.children.size.should eq(1)
 end
 it "create a label with icon" do
		s=nil;@win.create { s=stack {  } }
		@win.append_to(s) { @win.label("#open")  }
		s.children.size.should eq(1)
 end
 it "create a labeli and buttoni, checking min/auto size" do
		s=nil;@win.create { 
			label "without slotti"
			s=flow {  
				button("i")
				label("i")
				button("openssssssssssssssss")		
				button("#open")		
			}
			label "with slotti on 'i' widget"
			s=flow {  
				buttoni("i")
				labeli("i")
				button("openssssssssssssssss")		
				buttoni("#open")		
			}
		}
		@win.sleeping(300,"Verify slot/sloty")
		s.children.size.should eq(4)
 end
end