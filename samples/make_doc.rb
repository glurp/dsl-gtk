#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

### make_doc : extract api from soure DSL code file and
### make html documentation

html=<<EEND
<?DOCTYPE html>
<html>
<head>
<title>Ruiby DSL doc</title>
<style>
body { margin: 0px;}
.title{font-size:33;color:white; padding:10px 100px 10px 100px;margin-bottom:20px;
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
.descr  {font: 15px arial,sans-serif; background: #FFF; color: black;margin: 10px 0 30px 3px;
padding: 5px;}
a.l { color: #303030 ;  text-decoration:none ;}
a:link { }     
a:visited {}
a:hover {text-decoration: underline ;}
a:active {color: #0000FF}
.a {float: left;	width: 150px;}
	</style>
</head>

<body>

<div class='title'>Ruiby DSL Documentation</div>
Ruiby Version: %s<br>
Generated at : %s<br>
<hr>
<br>
<ul>
%s <!-- table des matieres -->
<div style='clear: both;'> </div>
</ul>
<br>
<br>
<table style="width:90%%;">
<tr><td>%s</td><td>%s</td></tr>  <!-- documentation -->
</table>
<hr>
<center>made by samples/make_doc.rb</center>
</body>
</html>
EEND

htable='<span class="a"><a class="l" href="#%s">%s</a></span>'

hitem=<<EEND
<div class='atitle'><a name='%s'>%s</a></div>
<div class='api'>%s</div>
<div class='descr'>%s</div>
EEND


def extract_doc_dsl() 
	src=File.dirname(__FILE__)+"/../lib/ruiby_gtk/ruiby_dsl3.rb"
	content=File.read(src)
	comment=""
	hdoc=content.split(/\r?\n\s*/).inject({}) {|h,line|
		ret=nil
		if a=/^def\s+([^_].*)/.match(line)
			name=a[1].split('(')[0]
			api=a[1].split(')')[0]+")"
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
  # make hyperlink cross reference to word definition in each description text
	hdoc.keys.sort.each {|k|
    name1,name2,api,descr= hdoc[k]
    d=descr.gsub(/\w+/) { |word| (word!=k && hdoc[word]) ? make_anchor(word) : word}
    hdoc[k]=[name1,name2,api,d] if d !=descr
  }
  hdoc
end
def make_anchor(word)
   ret="<a href='##{word}'>#{word}</a>"
   ret
end
########################## M A I N ###############################

hdoc=extract_doc_dsl()
table=hdoc.keys.sort.select {|a| (a !~ /\./) }.map { |name| htable % [name,name]}.join(" ")
lapis=hdoc.keys.sort.select {|a| (a !~ /\./) }.map {  |k|  hitem % hdoc[k] }
s=lapis.size
api1=lapis[0..(s/2)].join("\n")
api2=lapis[((s/2)+1)..-1].join("\n")
content=html % [
	File.read("#{File.dirname(__FILE__)}/../VERSION"),
	Time.now.to_s,
	table,
	api1,
  api2
]

output="#{File.dirname(__FILE__)}/../doc.html"
File.open(output,"wb") { |f| f.write( content ) }
system("start",Dir.pwd+"/"+output)
