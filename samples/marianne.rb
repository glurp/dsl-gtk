#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
###############################################################################################
#   show a feed (french news 'Marianne')
###############################################################################################

#require 'Ruiby'
require_relative '../lib/Ruiby'
begin
 require 'simple-rss' 
rescue Exception => e
  Message.alert("please installe gem 'simple-rss'")
  exit!(1)
end
require 'open-uri'

def load_img(url)
  filename="#{Dir.tmpdir}/#{(Time.now.to_f*1000).to_i.to_s+"." + url.split('.').last}"
  File.open(filename,"wb") { |wf| open(url,"rb") { |rf| wf.write(rf.read) }  }
  filename
end

def feed_update(win,st) 
  c='http://www.marianne.net/index.php?preaction=rss'
  rss = SimpleRSS.parse open(c)
  gui_invoke { gui_invoke { win.clear(st) } }
  rss.items.each do |feed| 
      title=feed.title
      uimg=(feed.description.scan(/&lt;img src=&quot;([^;]+)&quot;/)[0][0] rescue nil)
      if ! uimg
        uimg=feed.description.scan(/<img src="([^"]+)"/)[0][0] rescue nil
      end
      corp=feed.description.gsub("&amp;","").gsub("&nbsp;"," ").gsub(/&lt;.*&gt;/," ").gsub(/\s\s+/," ")
      corp=corp.gsub("&amp;","").gsub(/<[^>]*>/," ").gsub(/\s\s+/," ")
      if uimg=~/^https?:\/\//
        fimg=load_img(uimg)
        gui_invoke { 
          win.append_to(st) { evb=pclickable(proc {alert(corp)}) { flowi { 
              left { image(fimg,width:  70, height: 50 )  }
              stacki { 
                  date=feed.pubDate.to_s.split(' ')[0]
                  left { label(date+ " : "+feed.title,  font: "Arial bold 10")  }
                  left { text_area(500,50,font: "Arial  8").tap { |at| at.text=corp[0..300] }} 
              } 
          } } ;separator }
          update
        }
      end
  end
end

 Ruiby.app width:400,height:700,title: "Marianne" do
  scrolled(500,700)  do backgroundi("#FFFFFF") do @st=stacki do label("wait...",font: "Arial bold 33") end end end
  Thread.new { feed_update(self,@st)  }
 end