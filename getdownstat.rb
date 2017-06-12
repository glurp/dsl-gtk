# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
###########################################################################
#  get statistiques of download of a gem
#    builded to see curve download for a new version
#    must run during 24 hours, after a upload of a new version
###########################################################################

framework="Ruiby"

require 'open-uri'
require 'nokogiri'

def getCount(name)
  url="https://rubygems.org/gems/#{name}"
  Nokogiri::HTML(open(url)).css("span.gem__downloads").last.content.gsub(/[\D]+/,'').to_i
end


v=getCount(framework)-1
puts "Currant #{v}"
start=Time.now.to_i
loop {
  v1=getCount(framework)
  if v1!=v
    puts "#{Time.now} | #{Time.now.to_i-start} | #{v} ==> #{v1}"
    v=v1
    sleep 10
  else
    sleep 60
  end
}