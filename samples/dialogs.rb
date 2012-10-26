require_relative '../lib/ruiby'

def test_dialogues()
	$gheader=%w{id first-name last-name age str}
	$gdata= (0..10000).to_a.map {|i| ("%d regis%d aubarede%d %d %s" % [i,i,i,i%99,("*"*(i%30))]).split(/\s+/) }
	a=PopupTable.new("title of dialog",400,200,
		$gheader,
		$gdata,
		{
		  "Create" => proc {|line| 
				nline=line.clone.map {|v| ""}
				nline[0]=$gdata.size
				$gdata << nline
				a.update($gdata)
		  },
		  "Duplicate" => proc {|line| 
				nline=line.clone
		        nline[0]=$gdata.size
				$gdata << nline
				a.update($gdata)
		  },
		  "Edit" => proc {|line| 
			data={} ;line.zip($gheader) { |v,k| data[k]=v }
			PopupForm.new("Edit #{line[1]}",0,0,data,{				
				"Rename" => proc {|w,cdata|  cdata['first-name']+="+" ; w.set_data(cdata)},
				"button-direction" => "h"
			}) do |h|
			    vh=h.values
				$gdata.map! { |l| l[0] ==vh[0] ?  vh : l} 
				a.update($gdata)
			end
		  },
		  "Delete" => proc {|line| 
				$gdata.select! { |l| l[0] !=line[0] || l[1] !=line[1]} 
				a.update($gdata)
		  },
		}
	) { |data| alert data.map { |k| k.join ', '}.join("\n")  }
end

Ruiby.app(:title => "Crud...", :width=> 0, :height=>150) do
	stack { 
		button "exit" do exit! end 
		button "view" do test_dialogues()end
	}
	after 1 do test_dialogues() end
	rposition(100,100)
end
