#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
###############################################################################################
#   show some feeds 
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
 p url
  filename="#{Dir.tmpdir}/#{(Time.now.to_f*1000).to_i.to_s+"." + url.split('.').last}"
  File.open(filename,"wb") { |wf| open(url,"rb") { |rf| wf.write(rf.read) }  }
  filename
end
def extract_img(txt)
  return(nil) unless txt
  t=txt.to_s.scan(/src=([^\s]*)/)[0]
  t ? t.gsub("&quot;","").gsub("'","").gsub('"',"") : nil
end
def feed_update(win,st,url) 
  return unless url && url.size>0
  #win.set_title(url.gsub(/https?:\/\//,""))
  gui_invoke { gui_invoke { win.clear(st) } }
  rss = SimpleRSS.parse open(url)
  rss.items.each do |feed| 
      title=feed.title
      #feed.each { |k,v|  puts "%10s %s" % ["'"+k.to_s+"'",v.to_s[0..100]]}
      uimg= extract_img(feed.descrition) || extract_img(feed.link.inspect)
      fimg= (uimg && uimg=~/^https?:\/\//) ? load_img(uimg) : nil
      
      corp=(feed.description||feed.content||"").gsub("&amp;","").gsub("&nbsp;"," ").gsub(/&lt;.*&gt;/," ").gsub(/<[^>]*>/," ").gsub(/\s\s+/," ").strip
      date=(feed.pubDate||feed.updated||"").to_s.split(' ')[0]
      gui_invoke { 
        win.append_to(st) { evb=pclickable(proc {alert(corp)}) { flowi { 
            left { image(fimg,width:  70, height: 50 )  } if fimg 
            stacki { 
                left { label(date+ " : "+feed.title,  font: "Arial bold 10")  }
                left { text_area(500,50,font: "Arial  8").tap { |at| at.text=corp[0..300] }}  if corp.size>10  rescue nil
            } 
        } } ;separator }
        update
      }
  end
end

Ruiby.app width:400,height:700,title: "Feeds" do
  choices=[
    '',
    'http://www.marianne.net/index.php?preaction=rss',
    'http://feeds.feedburner.com/KorbensBlog-UpgradeYourMind',
    'http://www.lemonde.fr/rss/sequence/0,2-3208,1-0,0.xml',
    'http://feeds.feedburner.com/LeJournalDuGeek',
    'http://www.techno-science.net/include/news.xml',
    'http://planet.mozilla.org/atom.xml',
  ].each_with_index.inject({}) { |h,(k,i)| h[k]=i ; h}  
  stack {
    scrolled(500,700)  do backgroundi("#FFFFFF") do @st=stacki do label("wait...",font: "Arial bold 33") end end end
    this=self
    space
    sloti(combo(choices,0) { |url,no| Thread.new { feed_update(this,@st,url) } })
    space
  }
  after(1) { Thread.new { feed_update(self,@st, choices.keys.first)  } }
end