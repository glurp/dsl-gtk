# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
require_relative 'rspec_helper.rb'
 
describe Ruiby do
 before(:each) do
	@win= make_window
 end
 after(:each) do
	destroy_window(@win)
 end
 it "create a thread invoked text_area write" do
		w=nil
		@win.create { stack {    
			w=slot(text_area(100,200, {text: "a"} ) )
		} }
		@win.sleeping(30,"Verify button")
		w.text.should == "a"
		Thread.new {  gui_invoke { w.append("b") } }.join
		@win.sleeping(30,"Verify button")
		w.text.should == "ab"
 end
 it "create a thread appending som widget" do
		w,t=nil,nil
		@win.create { w=stack {    
			t=slot(text_area(100,200) )
		} }
		t.text.should == ""
		Thread.new {  gui_invoke { append_to(w) { button("1") } } }.join
		@win.sleeping(30,"Verify button")
		w.children.size.should == 2
		Thread.new {  gui_invoke { append_to(w) { button("1") } } }.join
		@win.sleeping(30,"Verify button")
		w.children.size.should == 3
 end
 it "create a thread which cleared " do
		w,t=nil,nil
		@win.create { w=stack { button("1") ;  button("2") }  }

		@win.sleeping(30,"")
		w.children.size.should == 2
		Thread.new {  gui_invoke { clear(w) } }.join
		@win.sleeping(30,"")
		w.children.size.should == 0
 end
 it "create a thread which cleared and append" do
		w,t=nil,nil
		@win.create { w=stack { button("1") ;  button("2") }  }

		@win.sleeping(30,"")
		w.children.size.should == 2
		Thread.new {  gui_invoke { clear_append_to(w) { button("e") } } }.join
		@win.sleeping(30,"")
		w.children.size.should == 1
 end

 it "create a thread which slot_append_before" do
		w,t=nil,nil
		@win.create { t=stack { button("1") ;  w=button("2") }  }

		@win.sleeping(30,"")
		t.children.size.should == 2
		Thread.new {  gui_invoke { slot_append_before(text_area(20,20), w) } }.join
		@win.sleeping(30,"")
		t.children.size.should == 3
 end
 it "create a thread which slot_append_after" do
		w,t=nil,nil
		@win.create { t=stack { button("1") ;  w=button("2") }  }

		@win.sleeping(30,"")
		t.children.size.should == 2
		Thread.new {  gui_invoke { slot_append_after(text_area(20,20), w) } }.join
		@win.sleeping(30,"")
		t.children.size.should == 3
 end

end