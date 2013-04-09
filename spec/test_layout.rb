# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
require_relative 'rspec_helper.rb'

describe Ruiby do
 before(:each) do
	@win= make_window
	Ruiby.update
 end
 after(:each) do
	destroy_window(@win)
 end
 it "check rspec work :)" do
	Hash.new.size.should eq(0)
	expect { 1/0 }.to raise_error
	(0..10).should cover(3)
	[1,2,3].should include(1, 2)
	"this string".should start_with("this")
	{:a => 'b'}.should include(:a => 'b')
 end
 
 context "in a window" do
	 it "create a stack and check its presence" do
		ici=nil
		@win.create { ici=stack {  } }
		ici.should be_a_kind_of(Gtk::Box)
		ici.should be_a_kind_of(Gtk::Box)
		ici.should be_a_kind_of(Gtk::Widget)
	 end
	 it "create a flow and check its presence" do
		ici=nil
		@win.create { ici=flow {  } }
		ici.should be_a_kind_of(Gtk::Box)
	 end
	 it "create a flow in a stack and check its presence" do
		ici=nil
		@win.create { stack {  ici=flow { } } }
		ici.should be_a_kind_of(Gtk::Box)
	 end
	 it "create a  button" do
		ici=nil
		@win.create {  ici=button("button") }
		ici.should be_a_kind_of(Gtk::Button)
	 end
	 it "stack of button" do
		ici=nil
		@win.create { stack {  100.times { |i| ici=button(i.to_s)} } }
		ici.should be_a_kind_of(Gtk::Button)
	 end
	 it "flow of button" do
		ici=nil
		@win.create { flow {  100.times { |i| ici=button(i.to_s)} } }
		ici.should be_a_kind_of(Gtk::Button)
	 end
	 it "frame of button" do
		ici=nil
		@win.create { 
		   frame("a title for frame") {  10.times { |i| ici=button(i.to_s)} } 
		}
		ici.should be_a_kind_of(Gtk::Button)
	 end
	 it "stack of flow of button" do
		ici=nil
		@win.create { stack {  10.times { |i| flow { 10.times { |j| ici=button(j.to_s)} } } } }
		ici.should be_a_kind_of(Gtk::Button)
	 end
	 it "append some widget" do
		ici=nil; ici2=nil
		@win.create { ici=stack {} }
		@win.append_to(ici) { @win.button("e") }
		@win.append_to(ici) { @win.button("e") }
		@win.append_to(ici) { @win.button("e") }
		@win.append_to(ici) { @win.button("e") }
		@win.append_to(ici) { ici2=@win.button("e") }
		ici2.should be_a_kind_of(Gtk::Button)
	 end
	 it "clear some widget" do
		ici=nil; ici2=[]
		@win.create { ici=stack {} }
		@win.append_to(ici) { ici2 << @win.button("e") }
		@win.append_to(ici) { ici2 << @win.button("e") }
		ici2.size.should eq(2)
		frame=ici2[0].parent
		frame.children.size.should eq(2)
		@win.clear(ici) 
		frame.children.size.should eq(0)
		@win.append_to(ici) { @win.button("eeeeeeeeee") }
		frame.children.size.should eq(1)
	 end
	 it "clear_and_append_to some widget" do
		ici=nil; ici2=nil
		@win.create { ici=stack {} }
		@win.append_to(ici) { @win.button("e") }
		@win.append_to(ici) { @win.button("e") }
		@win.clear_append_to(ici) { ici2=@win.button("eeeeeeeeee") }  
		ici.children.size.should eq(1)
		ici.children[0].should be_a_kind_of(Gtk::Button)
	 end
	 it "slot_append_before" do
		ici=nil; ici2=nil
		@win.create { ici=stack {} }
		@win.append_to(ici) { @win.button("e") }
		@win.append_to(ici) { ici2=@win.button("e") }
		@win.slot_append_before(@win.flow { },ici2)
		ici.children[1].should be_a_kind_of(Gtk::Box)
	 end
	 it "slot_append_after" do
		ici=nil; ici2=nil
		@win.create { ici=stack {} }
		@win.append_to(ici) { ici2=@win.button("e") }
		@win.append_to(ici) { @win.button("e") }
		@win.slot_append_after(@win.flow { },ici2)
		ici.children[1].should be_a_kind_of(Gtk::Box)
	 end
	 it "delete a widget" do
		ici=nil; ici2=nil;ici3=nil;
		@win.create { ici=stack {} }
		@win.append_to(ici) { ici2=@win.button("e") }
		@win.append_to(ici) { ici3=@win.button("e") }
		@win.delete(ici2)
		ici.children.size.should eq(1)
		@win.delete(ici3)
		ici.children.size.should eq(0)
	 end
	 it "get_config" do
		ici=nil; ici2=nil;ici3=nil;
		@win.create { ici=stack {} }
		@win.append_to(ici) { ici2=@win.button("e") }
		@win.get_config(ici).should be_a_kind_of(Hash)
		@win.get_config(ici).size.should > 1
	 end
 end
 
end