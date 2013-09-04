#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

### make_doc : extract api from soure DSL code file and
### make html documentation
require 'base64'


html=<<EEND
<?DOCTYPE html>
<html>
<head>
<title>Ruiby DSL doc</title>
<style>
  body { margin: 0px;}
  .title {font-size:33;color:white; padding:10px 100px 10px 100px;margin-bottom:20px;
  background: #5e8077;background: linear-gradient(to bottom, #606060 0%%,#808080 100%%);   
  box-shadow: 0px 2px 11px 2px #000; }
  .title2 {font-size:16;color:white; padding:10px 100px 10px 100px;margin-bottom:20px;
  background: #5e8077;background: linear-gradient(to bottom, #606060 0%%,#808080 100%%);   
  box-shadow: 0px 2px 11px 2px #000; }
  .atitle {
    font: 17px arial,sans-serif;         
    background: #5e8077;
    color:white; padding:5px 10px 4px 5px;margin-bottom:20px;
    background: linear-gradient(to right, #606060 0%%,#808080 100%%);   
    border-radius: 10px 10px ;
    box-shadow: 2px 2px 6px 1px #000; 
    margin-left:3px;margin-right:70px;
    padding-left: 30px
  }
  .api    {font: 18px courier; background: #F0F0A0; color: black;margin-left:3px;margin-right:50px;padding:4px}
  .code    {font: 18px courier; background: #FFFFFF; color: black;margin-left:3px;margin-right:50px;padding:4px}
  .descr  {
    font: 15px arial,sans-serif; background: #FFF; color: black;margin: 10px 0 30px 3px;
    padding: 5px;
  }
  a.l { color: #303030 ;  text-decoration:none ;}
  a:link { }     
  a:visited {}
  a:hover {text-decoration: underline ;}
  a:active {color: #0000FF}
  .a {float: left;	width: 150px;}
  #popup-div {
    border-radius: 20px 20px ;
    position: absolute;
    visibility:hidden;
    border : 2px solid black;
    background: #FFFFF0;
  }
</style>

<script>
function doSearch(text) {
    if (window.find && window.getSelection) {
        document.designMode = "on";
        var sel = window.getSelection();
        sel.collapse(document.body, 0);

        while (window.find(text)) {
            document.execCommand("HiliteColor", false, "pink");
            //sel.collapseToEnd();
        }
        document.designMode = "off";
    } else if (document.body.createTextRange) {
        var textRange = document.body.createTextRange();
        while (textRange.findText(text)) {
            textRange.execCommand("BackColor", false, "pink");
            textRange.collapse(false);
        }
    }
}
//================== popup data
var hdoc={};

%s

//================ popup code

function popup(word) {
 if (! hdoc[word]) return;
   
 var node=document.getElementById('popup-txt');
 node.innerHTML= hdoc[word];
 node=document.getElementById('popup-div');
 node.style.position ='fixed';
 node.style.visibility ='visible';
 node.style.left='25%%';
 node.style.bottom='25%%';
 node.style.width='50%%';
 node.style.height='50%%';
}

</script>
 </head>
<body>
<div class='title'>Ruiby DSL Documentation</div>
Ruiby Version: %s<br>
Generated at : %s<br>
<a href="#code">See code example</a>
<hr>
<center>Search : <input type='input' value="" size='80' onchange='doSearch(this.value);'></center>
<hr>
<br>
<ul>
%s <!-- table des matieres -->
<div style='clear: both;'> </div>
</ul>
<br>
<br>
<div style='-moz-column-count:2;-webkit-column-count:2;column-count:2;'>
%s
</div>
<a name="code"></a>
%s
</div>

<hr>
<center>made by samples/make_doc.rb</center>

<div id='popup-div'>
 <div class='atitle'>
    <input type='button' onclick="document.getElementById('popup-div').style.visibility='hidden';" value='X'>
 </div>
 <div id='popup-txt'></div>
</div 

</body>
</html>
EEND

htable='<span class="a"><a class="l" href="#%s">%s</a></span>'

hitem=<<EEND
<div class='atitle'><a name='%s'>%s</a></div>
<div class='api'>%s</div>
<div class='descr'>%s <a href='#ex_%s'>ex</a></div>
EEND


def extract_doc_dsl() 
	glob=File.dirname(__FILE__)+"/../lib/ruiby_gtk/*.rb"
  hdoc={}
  Dir[glob].each do |src| next if src =~ /dsl.rb/
    content=File.read(src)
    comment=""
    hdoc=content.split(/\r?\n\s*/).inject(hdoc) {|h,line|
      ret=nil
      if a=/^\s*def\s+([^_][a-z0-9_]*)/.match(line)
        name=a[1].split('(')[0]
        api=line.split(')')[0]+")"
        descr=comment.gsub('#\s*',"")
        comment=""
        h[name]=[name,name,api,descr]
      elsif a=/^\s*#\s*(.*)/.match(line)
        comment+=a[1].gsub("#","").gsub(/^\s*\*/,"<li>")+"<br>"
      elsif /^\s*end\b/.match(line) || /^\s*def\s+(_.*)/.match(line) || /^\s*$/.match(line) || line.size==0
        comment=""
      end
      h
    }
  end
  # make hyperlink cross reference to word definition in each description text
  hdoc.keys.sort.each {|k|
    name1,name2,api,descr= hdoc[k]
    if name1 =~/^aaa/
        api="" 
    end
    d=descr.gsub(/\w+/) { |word| (word!=k && hdoc[word]) ? make_anchor(word) : word}
    hdoc[k]=[name1,name2,api,d] 
  }
  hdoc
end

def make_anchor(word)
   ret="<a href='##{word}'>#{word}</a>"
   ret
end

$hexample={}
def make_popup(word)
   ret="<a href='javascript:popup(\"#{word}\");'>#{word}</a>"
   unless $hexample[word]
     ret="<a name='ex_#{word}'></a>"+ret
   end
   $hexample[word]=1
   ret
end


def make_example(hdoc,filename)
  count= $hexample.size
  src=File.dirname(__FILE__)+"/"+filename
	system('ruby',src,"take-a-snapshot")
  content=File.read(src).gsub('<','&lt;')
	code= if content =~ /component\(\)/
		'def component()' + content.split('component()')[1]
	else
	  content
	end
  code=code.gsub(/\w+/) { |word| (hdoc[word]) ? make_popup(word) : word}
	count-=$hexample.size
	puts " #{filename} : #{-count}"
	ifn="media/snapshot_#{filename}.png"
	img=if File.exists?(ifn)
			icontent=open(ifn,"rb") do |f|
				Base64.encode64(f.read(File.size(ifn)))
			end
			File.delete(ifn)
			'<br/><center><img src="data:image/gif;base64,'+icontent+'"></center><br/>'
	else
	  puts "no snapshot"
	  ""
	end
  '<div class="title2">Code of <a href="https://github.com/raubarede/Ruiby/blob/master/samples/%s">samples/%s</a></div>%s<div class="code"><pre><code>%s</code></pre><br></div><br>' % [filename,filename,img,code]
end





def make_hdoc(hdoc)
 hdoc.map {|w,v|  "hdoc['%s']= '<div class=\"api\"><br>%s</div><div>%s</div>';"  % [w,v[2],v[3].gsub("'","")]}.join("\n")
end

########################## M A I N ###############################

hdoc=extract_doc_dsl()
table=hdoc.keys.sort.select {|a| (a !~ /\./) }.map { |name| htable % [name,name]}.join(" ")
lapis=hdoc.keys.sort.select {|a| (a !~ /\./) }.map {  |k|  
  n1,n2,a,d= *hdoc[k]
  hitem % [n1,n2.gsub(/^aaa/,'').gsub('_',' '),a,d,n1]
}
dico_hdoc=make_hdoc(hdoc)

lscript=%w{canvas.rb table2.rb testth.rb animtext.rb  test_systray.rb  multi_window_threading.rb test_include.rb netprog.rb test.rb }
test=lscript.map { |file| make_example(hdoc,file) }.join("<hr>")
puts "\n\n no exemples for : #{hdoc.size - $hexample.size} words\n"
eend="<hr><br><p><b>No example for</b> : %s" % [(hdoc.keys - $hexample.keys- %w{initialize component}).join(', ')]

api1=lapis.join("\n")
content=html % [
  dico_hdoc,
	File.read("#{File.dirname(__FILE__)}/../VERSION"),
	Time.now.to_s,
	table,
	api1,
  test+eend
]

output="#{File.dirname(__FILE__)}/../doc.html"
File.open(output,"wb") { |f| f.write( content ) }
system("start",Dir.pwd+"/"+output)
