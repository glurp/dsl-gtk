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
.title  {font: 35px arial,sans-serif; background: black ; color: white; text-align: center;padding: 30px;}
.atitle {font: 25px arial,sans-serif; background: #A0A0A0; color: white;padding: 10px;}
.api    {font: 18px courier; background: #F0F0A0; color: black;}
.descr  {font: 15px arial,sans-serif; background: #F0F0F0; color: black;margin: 10px 0 30px 30px}
.a { width: 100px;display: inline;}
	</style>
</head>

<body>

<div class='title'>Ruiby DSL Documentation</div>
Ruiby Version: %s<br>
Generated at : %s<br>
<hr>
<br>
%s <!-- table des matieres -->
<br>
<br>
%s  <!-- documentation -->
<hr>
<center>made by samples/make_doc.rb</center>
</body>
</html>
EEND

htable='<div class="a"><a href="#%s">%s</a></div>'

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
		if a=/^def[\s\t]+([^_].*)/.match(line)
			name=a[1].split('(')[0]
			api=a[1].split(')')[0]+")"
			descr=comment.gsub('#\s*',"")
			comment=""
			h[name]=[name,name,api,descr]
		elsif a=/^\s*#\s*(.*)/.match(line)
			comment+=a[1].gsub("#","")+"<br>"
		elsif a=/^def[\s\t]+(_.*)/.match(line)
			comment=""
		end
		h
	}
	hdoc
end

########################## M A I N ###############################

hdoc=extract_doc_dsl()
table=hdoc.keys.sort.select {|a| (a !~ /\./) }.map { |name| htable % [name,name]}.join(" ")
apis=hdoc.keys.sort.select {|a| (a !~ /\./) }.map {  |k|  hitem % hdoc[k] }.join("\n")

content=html % [
	File.read("#{File.dirname(__FILE__)}/../VERSION"),
	Time.now.to_s,
	table,
	apis
]

output="#{File.dirname(__FILE__)}/../doc.html"
File.open(output,"wb") { |f| f.write( content ) }
system("start",Dir.pwd+"/"+output)
