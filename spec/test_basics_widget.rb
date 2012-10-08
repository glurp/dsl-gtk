require_relative 'rspec_helper.rb'

describe Ruiby do
 before(:each) do
	@win= make_window
 end
 after(:each) do
	destroy_window(@win)
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
		@win.sleeping(100,"Verify slot/sloty")
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
		@win.sleeping(100,"Verify slot/sloty")
		s.children.size.should eq(4)
 end
 it "create a label with file image" do
		w=[];
		@win.create { stack {  
			label("file reaster is :")
			w << label("##{$here}/draw.png")  
			label("sub part of the raster file :")
			w << label("##{$here}/draw.png[0,0]x22")  
			w << label("##{$here}/draw.png[1,0]x22")  
			w << label("##{$here}/draw.png[2,0]x22")  
			w << label("##{$here}/draw.png[1,1]x22")  
			w << label("##{$here}/draw.png[2,1]x22")  
		} } 
		@win.sleeping(100,"Verify images")
		w.each { |x| x.should be_a_kind_of(Gtk::Image) }
		w.each { |x| x.pixbuf.should be_a_kind_of Gdk::Pixbuf}
		w[1..-1].each { |x| x.pixbuf.width.should eq(22)}
		
 end
 it "create a entry" do
		w=nil
		@win.create { stack {   w=entry("CouCou") { alert("key pressed ok") } } }
		@win.sleeping(100,"Verify entry")
		 w.should be_a_kind_of(Gtk::Entry)
 end
 it "create a ientry" do
		w=nil
		@win.create { stack {   w=ientry(22,min: 0, max: 100,by: 1) { alert("value modify, ok") } } }
		@win.sleeping(100,"Verify fentry")
		 w.should be_a_kind_of(Gtk::SpinButton)
 end
 it "create a fentry" do
		w=nil
		@win.create { stack {   w=fentry(22,min: 0, max: 10,by: 0.1) { alert("value modify, ok") } } }
		@win.sleeping(100,"Verify fentry")
		w.should be_a_kind_of(Gtk::SpinButton)
 end
 it "create fields" do
		w=nil
		@win.create { stack {   w=fields("aa"=>0,"bb"=>1)  } }
		@win.sleeping(100,"Verify fields")
		w.should be_a_kind_of(Gtk::VBox)
		w.children.size.should eq(2)
 end
 it "create  fields with validation" do
		w=nil
		@win.create { stack {   w=fields("aa"=>0,"bb"=>1) { alert("value modify, ok") } } }
		@win.sleeping(100,"Verify fields")
		w.should be_a_kind_of(Gtk::VBox)
		w.children.size.should eq(4)
 end
 it "create a slider" do
		w=nil
		@win.create { stack {   w=islider(22,min: 0, max: 100,by: 1) { |v|p v} } }
		@win.sleeping(100,"Verify islider")
		 w.should be_a_kind_of(Gtk::HScale)
 end
  it "create a canvas" do
		w=nil
		@win.create { stack {   w=canvas(100,100) } }
		 w.should be_a_kind_of(Gtk::DrawingArea)
 end

end