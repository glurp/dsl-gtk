# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
# Show dependencies of current Ruiby config

require 'tsort'

def  prequire(n)
  puts "require #{n} ..."
  begin
    require  n.to_s
  rescue Exception => e
    puts "   Error : #{e}"
  end
end
prequire ARGV.shift while ARGV.size>0

class Gims 
  include TSort
  def initialize()                   @gims = Hash.new{|h,k| h[k] = []}  end   
  def add(name, dependencies)        @gims[name] = dependencies         end
   
  def tsort_each_node(&block)        @gims.each_key(&block)             end   
  def tsort_each_child(node, &block) @gims[node].each(&block) if @gims.has_key?(node) end
  alias :tsort_old :tsort
  def tsort()
     tsort_old()
   rescue TSort::Cyclic => e
      puts " Cycles : #{e}"
     @gims
   else
     @gims
  end
end

def echo_gem_loaded()
    h={}
    gims=Gem.loaded_specs.map {|n,g| h[n]=g;g}.inject(Gims.new){ |gims,gem|
            gims.add( gem.name,gem.dependencies.map {|dep| dep.name} )
            gims
          }.tsort.map {|k,_| h[k]}.compact.
          map  { |s|  [s.name,s.version,s.dependencies.map {|d|  "#{d.name}#{d.requirement}" }]  }
end


puts echo_gem_loaded.map { |(a,b,c)| "#{a.ljust(20)} #{b.to_s.ljust(7)} => #{c.join('/')}"}  
