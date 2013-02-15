# LGPL
# Show dependencies af current Ruiby config
require 'tsort'

class Gims
  include TSort
   
  Gim = Struct.new(:name, :dependencies)
  def initialize()                   @gims = Hash.new{|h,k| h[k] = []}  end   
  def add(name, dependencies)        @gims[name] = dependencies         end
   
  def tsort_each_node(&block)        @gims.each_key(&block)             end   
  def tsort_each_child(node, &block) @gims[node].each(&block) if @gims.has_key?(node)          end
end
	 
def gem_loaded()
    lg=Gem::Specification.all.select { |s| s.activated? }
    gims=Gims.new
    h={}
    lg.each { |g|  h[g.name]=g  ; gims.add(g.name, g.dependencies.map {|d| d.name}) }
    lgs=gims.tsort.inject([]) { |a,n| a<< h[n] if h[n]; a }
    lgs.map  { |s|  [s.name,s.version,s.dependencies.map {|d|  "#{d.name}:#{d.requirement}" }]  }
end
class String ; def lcenter(size) "%-#{size}s" % [self] end  ; end

require 'gtksourceview2'
#puts gem_loaded.map { |(a,b,c)| "#{a.lcenter(20)} ==> #{c.join(' / ')}"}  
puts gem_loaded.map { |(a,b,c)| "gem uninstall #{a.lcenter(20)} && gem install #{a.lcenter(15)} -v #{b}"}.join("\n")
