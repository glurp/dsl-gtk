# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
require_relative 'rspec_helper.rb'

describe Ruiby do
 before(:each) do
	@win= make_window
	Ruiby.update
 end
 after(:each) do
	destroy_window(@win) if @win
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
	 it "create a center box" do
		ici=nil
		@win.create { stack {  ici=center { } } }
		ici.should be_a_kind_of(Gtk::Box)
	 end
	 it "create a left box" do
		ici=nil
		@win.create { stack {  left { ici=button("ee") } } }
    ici.should be_a_kind_of(Gtk::Button)
	 end
	 it "create a right box" do
		ici=nil
		@win.create { stack {  right { ici=button("ee") } } }
    ici.should be_a_kind_of(Gtk::Button)
	 end
	 it "create a  box with a background" do
		ici=nil
		@win.create { ici=stack {  background("#FF0000") { button("eee") } } }
		ici.should be_a_kind_of(Gtk::Box)
	 end
	 it "create a  box with a backgroundi" do
		ici=nil
		@win.create { ici=stack {  backgroundi("#FF0000") { button("eee") } } }
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
	 it "ruiby api" do
      l=Ruiby.make_doc_api
      l.size.should > 40
	 end
	 it "stock get set" do
      snow=Time.now.to_s
      Ruiby.stock_put("toto",snow)
      s=Ruiby.stock_get("toto","?")
      snow.should eq(s)
      Ruiby.stock_reset()
      s=Ruiby.stock_get("toto","?")
      s.should eq("?")
	 end
	 it "Dyn var" do
      v=DynVar.new("22")
      v.value.should eq("22")
      aa=""
      v.observ { |value| aa= value}
      v.value="33"
      t=Time.now
      @win.update while Time.now< t+1 
      aa.should eq("33")
   end
	 it "Dyn Stock var" do
      v1=DynVar.stock("ee","44")
      v2=DynVar.stock("ff","55")
      DynVar.save_stock
      v1.value.should eq("44")
      v2.value.should eq("55")
   end
	 it "Dyn object" do 
      C=make_DynClass(h={"dummy"=>"?"})
      c=C.new
      c.dummy.value.should eq("?")
      c=C.new("dummy"=>"2")
      c.dummy.value.should eq("2")
   end
	 it "Dyn Stock object" do 
      o=make_StockDynObject("eee",h={"dummy"=>"?"})
      o.dummy.value.should eq("?")
      o.dummy.value="2"
      o.dummy.value.should eq("2")
   end
	 it "list" do
		tr=nil
		@win.create { 
      tr=list(%w{month},200,300)
      tr.set_data(%w{a b c d})
      tr.add_item("e")
      tr.set_selections(0,3)
    }
		tr.should be_a_kind_of(Gtk::ScrolledWindow)
	 end
	 it "tree grid" do
		tr=nil
    data=nil
		@win.create { 
      tr=tree_grid(%w{month name prename 0age ?male},200,300)
      tr.set_data({
        janvier: {
          s1:["aaa","bbb",22,true],
          s2:["aaa","bbb",33,false],
          s3:["aaa","bbb",111,true],
          s4:["aaa","bbb",0xFFFF,true],
        },
        fevrier: {
          s1:["aaa","bbb",22,true],
          s2:["aaa","bbb",33,false],
        },
      })
      data=tr.get_data
    }
		data.size.should eq(2)
		tr.should be_a_kind_of(Gtk::ScrolledWindow)
	 end
   it "notebook" do
		@win.create { 
     notebook { 
        page("first") { button("e") ; button("r") }
        page("second") { button("e") ; button("r") }
     }
    }
   end
   it "accordeon" do
		@win.create { 
      accordion { aitem("ee") { alabel("ee") {alert("ee")} ; alabel("ee") {alert("ee")}  } }
      stack { }
    }
   end
   it "style css" do
		@win.create { 
      def_style( <<EEND )
@define-color bg_color #cece00;
@define-color fg_color #ff0000;
* {
  engine: none;
  border-width: 9px;
  background: @bg_color ;
  color: @fg_color;
}
EEND
     stack { }
    }
   end
=begin
   if RUBY_PLATFORM =~ /in.*32/
     it "make a snapshot" do
      File.delete("/tmp/ici.png") if File.exists?("/tmp/ici.png")
      @win.create { 
        button("eee")
        label("eeeeeeeeeeeee")
        snapshot("/tmp/ici.png")
      }
      File.exists?("/tmp/ici.png").should eq(true)
      File.delete("/tmp/ici.png")
    end
   end
=end 
 end
end
