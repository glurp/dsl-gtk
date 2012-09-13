require_relative '../lib/ruiby'

def test_dialogues()
	$gheader=%w{id first-name last-name age}
	$gdata=[%w{regis aubarede 12},%w{siger ederabu 21},%w{baraque aubama 12},%w{ruiby ruby 1}]
	i=-1; $gdata.map! { |l| i+=1; [i]+l }
	a=PopupTable.new("title of dialog",400,200,
		$gheader,
		$gdata,
		{
		  "Delete" => proc {|line| 
				$gdata.select! { |l| l[0] !=line[0] || l[1] !=line[1]} 
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
				"button-orrient" => "h"
			}) do |h|
				$gdata.map! { |l| l[0] ==h.values[0] ?  h.values : l} 
				a.update($gdata)
			end
		  },
		}
	) { |data| alert data.map { |k| k.join ', '}.join("\n")  }
end

Ruiby.app(:title => "Crud...", :width=> 8, :height=>150) do
	stack { 
		button "exit" do exit! end 
		button "view" do test_dialogues()end
	}
	after 1 do test_dialogues() end
	rposition(100,100)
end
