# -*- encoding: utf-8 -*-
$:.push('lib')

Gem::Specification.new do |s|
  s.name     = "Ruiby"
  s.version  = File.read("VERSION").strip
  s.date     = Time.now.to_s.split(/\s+/)[0]
  s.email    = "regis.aubarede@gmail.com"
  s.homepage = "http://github.com/raubarede/Ruiby"
  s.authors  = ["Regis d'Aubarede"]
  s.summary  = "A  DSL for building simple GUI ruby/gtk application"
  s.description = <<EEND
A DSL for building simple GUI ruby application rapidly.
EEND
  
  dependencies = [
    [:runtime,     "gtk2"],
    [:runtime, "gtksourceview2"],
    [:runtime,     "gtk3"],
    [:runtime, "gtksourceview3"]
	]

  s.files         = Dir['**/*'].reject { |a| a =~ /^\.git/ || a =~ /\._$/}
  s.test_files    = Dir['samples/**'] 
  s.require_paths = ["lib"]
  s.bindir		  = "bin"
  s.executables   = `ls bin/*`.split("\n").map{ |f| File.basename(f) }

  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.8.15"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version
  
  dependencies.each do |type, name, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, version)
    else
      s.add_dependency(name, version)
    end
  end
  s.post_install_message = <<TTEXT

      -------------------------------------------------------------------------------

      Hello, welcome to Ruiby univers....

        $ ruiby_demo    # test with gtk2
        $ ruiby_demo3   # test with gtk3 , experimental !
        
        $ ruiby -width 200 -height 100 "chrome(false); button 'Welcome' do exit!(0) end "
        
        $ ruiby_sketchi  # write and test ruiby gui

      -------------------------------------------------------------------------------
TTEXT
end

