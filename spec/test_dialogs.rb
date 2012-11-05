require_relative 'rspec_helper.rb'

describe Ruiby do
 before(:each) do
	@win= make_window
 end
 after(:each) do
	destroy_window(@win)
 end
 it "create a editor window" do
		if Gem.available?('gtksourceview2')
			s=nil;@win.create { stack { s=source_editor() } }
			content=File.read(__FILE__)
			s.editor.buffer.text=content
			s.editor.buffer.text.size().should eq(content.size)
		end
 end
 it "create a popup grid" do
		p=PopupTable.new("Test",800,500,
			%w{first-name last-name age},
			[%w{regis aubarede 12},%w{siger ederabu 21},%w{baraque aubama 12},%w{ruiby ruby 1}],
			{
			  "Detail" => proc {|line| $app.alert(line) },
			}
		)
		l= p.mgrid.get_data() 
		l.size.should ==4
		p.update([%w{nelson mandela 99}]);
		l= p.mgrid.get_data() 
		l.size.should ==1
		p.destroy
 end
 it "create a form dialog" do
	p=PopupForm.new("Test",0,0,{
			"name" => "regis",
			"last-name" => "aubarede",
			"int" => 22,
			"float" => 22.333
		},{
		}
	) 
	p.destroy
 end 
 it "create a log window" do
	@win.log "Test"
 end 
 it "test messageBox" do
    # impossible to test : 
	#    alert(), ask(), prompt(),ask_file_to_read(), 
	#    ask_file_to_write,ask_dir
 end 
 
end