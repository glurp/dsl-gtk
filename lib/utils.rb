################################################################################
#   utils.rb : utilitaires divers pour dev ruby
################################################################################
# module Enumerable : def oinject(obj)
# class Array
#   def superjoin(*ldescr) 					join n dimensions array
#   def join_html_table(css_class="nil")	join 2 dim array in a html table
#   def to_cols_by_nbline(number_of_line)
#   def to_cols_by_nbcols(number_of_cols)
#   def partitionning(part_size)
# class Hash def join_html_table(css="nil")
# class Object def join_html_table(css="nil")
# class File
#   def self.write(fn,text=nil)				write a string to a textfile
#   def self.my_find(root,filter,&blk)		recursive find file
#   def self.my_find_depht(root,filter,&blk)recursive find file files first
# class Kernel def chrono(text="",div=1)	eval bloc with time mesure
# module H									module Html builder
# class Html_builder						class Html builder
#  def self.do(&b) Html_builder.new.instance_eval(&b).to_html_code end
#  def css 
# class Reloader
#  def run
#  def refresh
#  def declare(filename)
#  def checkReloading(filename,last_mtime)
# def server_init()
################################################################################
require 'socket'
require 'thread'

module Enumerable
 def oinject(obj)
   inject(obj) { |obj,el| yield(obj,*el) ; obj }
 end
end

class Array

 # make en string from a multidimensioned array
 # 1 dim: ["pre-array","bettweencell","post-array"]
 # 2 dim: (html tab) ["<table><tr>", "</tr><tr>", "</tr></table>"], ["<td>", "</td><td>", "</td>"]
 #  ...
 def superjoin(*ldescr)
  raise("descriptor not ok : len=0") if ldescr.length==0
  raise("descriptor not ok :" + ldescr[0].length) if ldescr[0].length!=3
  d=ldescr[0]
  rest=ldescr[1..-1]
  d[0]+ self.map { |a| (a.respond_to?(:superjoin) && rest.length>0)? a.superjoin(*rest) : a.to_s }.join(d[1]) + d[2]
 end
 def join_html_table(css_class="nil")
   ret=superjoin(["<table class='#{css_class}'><tr>", "</tr><tr>", "</tr></table>"], ["<td>", "</td><td>", "</td>"])
   aret=ret.split(/<\/tr><tr>/)
   aret.size>1 ? (aret[0].gsub(/td>/,"th>")+"</tr><tr>"+aret[1..-1].join("</tr><tr>")) : ret
 end
 def to_cols_by_nbline(number_of_line)
    chunks = (1..number_of_line).collect { [] }
    0.upto(size-1) { |i| chunks[i % number_of_line] << self[i]  }
    chunks
 end
 def to_cols_by_nbcols(number_of_cols)
	to_cols_by_nbline( (size+number_of_cols-1) / number_of_cols )
  end
 def partitionning(part_size)
    nc=(size+part_size-1)/part_size
    chunks = (1..nc).collect { [] }
    0.upto(size-1) { |i| chunks[i / part_size] << self[i]  }
    chunks
 end
 def test_sttp(m,n)
   s=(10..m).to_a.partitionning(n).superjoin(["","\n",""],["< "," : "," >"])
   puts s
   s=(10..m).to_a.to_cols_by_nbcols(n).superjoin(["","\n",""],["< "," : "," >"])
   puts s
end
end

class File
  def self.write(fn,text=nil)
	File.open(fn,"wb") { |f| f.write(text || yield().join("\n")) }
  end
  def self.my_find(root,filter,&blk)
    Dir.glob("#{root}/*").each do |en|
      bn=File.basename(en)
      next if bn =~ /^\.\.?$/
      if File.directory?(en)
        my_find(en,filter,&blk)
      else
        blk.call(en) if File.fnmatch( filter, bn)
      end
    end
  end
  def self.my_find_depht(root,filter,&blk)
	l=[]
    Dir.glob("#{root}/*").each do |en|
      bn=File.basename(en)
      next if bn =~ /^\.\.?$/
      if File.directory?(en)
        l << en
      else
        blk.call(en) if File.fnmatch( filter, bn)
      end
    end
	l.each { |en| my_find_depht(en,filter,&blk) }
  end
end

class Hash
  def join_html_table(css="nil")
    self.sort {|a,b| a.to_s<=>b.to_s}.join_html_table(css)
  end
end
class Object
  def join_html_table(css="nil")
    instance_variables.sort.map { |n| [n,instance_variable_get(n)] }.join_html_table(css)
  end
end
module Kernel
  def chrono(text=nil,div=1)
    date_start=Time.now.to_f
    yield
    date_end=Time.now.to_f
    duree= (date_end - date_start)*1000
    duree/=div if div>1
    sduree= case duree
    when 0..3000 then duree.to_s + " ms"
    when 3000..10000 then (duree/1000).to_s + " sec"
    when 10000..180000 then (duree/1000).to_i.to_s + " sec"
    else
      (duree/60000).to_i.to_s + " mn"
    end
    puts "#{text} Duration: #{div>1? ' by iteration ': ''}" + sduree if text
	duree
  end
end


########################## Html builer #####################################
module H
 def escape(string)
    string.gsub(/([^ \/a-zA-Z0-9_.-]+)/n) { '%' + $1.unpack('H2' * $1.size).join('%').upcase }.tr(' ', '+')
  end

  def initHtml()
    @outerr=false
    @level=0
    @out=[]
    @in_insert=false
    @hMark={}
  end
  ###-- simple use :  this=self; H.do { html { body { t "hello "+ this.name } } } 
  def self.do(&b) H.new.instance_eval(&b).to_html_code end
  
  
  def t *txt ; @out << txt.join(" ") ; self ; end  
  def comment *txt; @out << "\n<!-- " + txt.join(" ") + " -->\n" ; self ; end  
  def mark(tag)
    @hMark[tag]=@out.size
  end
  def echo(txt)
    @out << txt
    @out << "\n"
  end
  def insert(tag) 
    return if @in_insert
    return if ! @hMark[tag]
    pos=@hMark[tag]
    @in_insert=true
    out_save=@out
    @out=[]
    begin
      yield
    rescue Exception => e
      @out << "<br>"+e.to_s+"<br>"
    end
    out_save.insert(pos,*@out)
    @out=out_save
  end
  def html(*args,&bloc) 
    @outerr=false
    @out << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
    do_tag("html",args,&bloc)
  end
  def tty *txt; @out << "<pre><code>#{txt.map {|c| c.to_s}.join(" ")}</code></pre>" ; self ;end
  def atohtml(l,with_header=false)
    if l[0].class != Array then t(l.inspect) ; return(self) ; end
    table("class='grid'") { 
      tr {l[0].each { |c| th { t c }} } if with_header
      l=l[1..-1] if with_header
      l.each {|l1| tr { l1.each { |c| td { t c }} }  }
    }
    self
  end   
  %w{A ABBR ACRONYM B BODY BR BUTTON CODE DD DIV DL DT FONT FORM FRAME FRAMESET H1 H2 H3 H4 H5 H6 HEAD HR I IFRAME IMG INPUT LABEL LI LINK MAP META OBJECT OL OPTION P PRE Q S SCRIPT SELECT SPAN STYLE TABLE TBODY TD TFOOT TH THEAD TR U UL ADDRESS APPLET AREA BLOCKQUOTE CAPTION CENTER COL COLGROUP FIELDSET LEGEND NOFRAMES NOSCRIPT SMALL STRIKE STRONG TEXTAREA TITLE BASE BASEFONT BDO BIG CITE DEL DIR DFN EM INS ISINDEX KBD MENU OPTGROUP PARAM SAMP SUB SUP TT VAR}.each { |tag|
    class_eval( "def #{tag.downcase}(*args,&bl) do_tag('#{tag.downcase}',args,&bl) end" )
  }
  def do_tag(name,args,&bl)
    return if @outerr
    @out << "<"   
    @out << name.to_s
    args.each { |a| @out << " " ; @out << a ; }
    if block_given?
      @out << ">"
      @level+=1
      begin
        str=yield   
	@out << str if String === str
      rescue Exception => e
        @out << "<br>Error: <br>" + e.to_s + "<ul>"  + e.backtrace[0..10].join("<br>")
        @outerr=true
      end
      @level-=1
      #@out << " " * @level
      @out << "</#{name}>\n"
    else
      @out << "/>"    
    end   
    self    
  end
  def to_html_code
    s=@out.join("")
    @out=[]
    s
  end


 def make(&blk)
   initHtml
   instance_eval(&blk)
   to_html_code
 end
 def self.add_tag(tag,str_bloc)
   module_eval %Q{def #{tag}(*args) ; #{str_bloc} ; end }
 end
end
class Html_builder
  def initialize
    initHtml()
  end
  ###-- simple use :  this=self; H.do { html { body { t "hello "+ this.name } } } 
  def self.do(&b) Html_builder.new.instance_eval(&b).to_html_code end
  def css 
      t(<<-EEND)
<style>
body { backgound: #F0F0F0 ; 
      margin:0px;padding:0px;
}
h1 { background-color:#505050; color:#FFF; 
     padding:20px 0 20px 0;margin:0px;
     margin:0px;padding:0px;height:40px;
     border-bottom: 2px solid black;
     font-size:20px;
}
h2 { background-color:#707070; color:#FFF; 
     padding:1px 0 1px 0;margin:0px;
     font-size:14px;
}
h3 { background-color:#505050; color:#FFF;
     width:100% ; height:5px; 
     padding:10px 0 10px 0;margin:0px;
     border-bottom: 2px solid black;
     font-size:10px;
}

div.decale { margin-left:50px ;}     

a { color: #303030 ;  text-decoration:none ;}     
a:link { }     
a:visited {}
a:hover {text-decoration: underline ;}
a:active {color: #0000FF}
td { border: 0px solid black; padding: 0px 0px 0px 20px;}
td img { border:0px; width:20px; height:20px; }
.home { border:0px; width:32px; height:32px; float:left ;}
.space { margin-left: 20px;}
.grid {border-collapse:collapse;border:2px solid black}
.grid th {border-collapse:collapse;border:1px solid black;background:#C0C0C0}
.grid td {border-collapse:collapse;border:1px solid black}
.mashcenter { margin-left:3px; border:1px solid #A0A0A0;}
.mashup { float:left ; height:100px; margin-left:3px; border:0px solid #A0A0A0;}
.window2 { border:1px solid #C0C0C0; background-color: #F0F9F0;}
.window { border:1px solid #A0A0A0; background-color: #F0FAF0;height:60px}
.border { border:0px solid #A0A0A0 }
.asfloat { width:100%; }
.shad { 
  text-shadow:1px 1px 3px #303040;-moz-text-shadow:1px 1px 3px #303040; ;
  height: 1em;
  filter: Shadow(Color=#C0C0C0,Direction=135,Strength=2);
  }
table.data {
  border-collapse:collapse;
  border: 2px solid black; padding: 0px 0px 0px 0px;
}
table.data th { background:#3090A0;color:#004040; border: 1px solid black; padding: 0px 3px 0px 3px;}
table.data td { border: 1px solid black; padding: 0px 3px 0px 3px;}
</style>
    EEND
  end
 include H
end

class Reloader
 class << self 
   @instance=false
   def run
     if ! @instance
       @files={}
       Thread.new { loop { refresh ; sleep(10)} }
	     @instance=true
     end
   end
   def refresh
     return if ! @instance
     lf=@files.to_a
	   lf.each {|file,time| checkReloading(file,time) } 
   end
   def declare(filename)
     @files[filename]=File.mtime(filename)
   end
 
   def checkReloading(filename,last_mtime)
	  mtime=File.mtime(filename)
	  if  mtime != last_mtime
	     @files[filename] =  mtime 
	     begin
		   puts "\n\n================ Reloading #{filename} ..."
		   load(filename) 
	       puts "================ end Reloading #{filename}"
		 rescue Exception => e
		   puts "Error loading source : #{$!}"
		 end 
	  end 
   end
  end
end

def server_init()
 return if defined?($__MARKER_IS_SERVER_SERVING)

 $__MARKER_IS_SERVER_SERVING = true
 $stdout.sync=true 
 $stderr.sync=true 
 Thread.abort_on_exception = true  
 BasicSocket.do_not_reverse_lookup = true
 trap("INT") { exit!(0) }
 yield
end

