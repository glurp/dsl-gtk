# -*- encoding: utf-8 -*-
$:.push('lib')

Gem::Specification.new do |s|
  s.name     = "Ruiby"
  s.licenses = ['LGPL', 'CC-BY-SA']
  s.version  = File.read("VERSION").strip
  s.date     = Time.now.to_s.split(/\s+/)[0]
  s.email    = "regis.aubarede@gmail.com"
  s.homepage = "http://github.com/glurp/Ruiby"
  s.authors  = ["Regis d'Aubarede"]
  s.summary  = "A  DSL for building GUI ruby/gtk application"
  s.description = <<EEND
A DSL for building GUI ruby application, based on Gtk.
EEND
  

  s.files         = Dir['**/*'].reject { |a| a =~ /^\.git/ || a =~ /\._$/}
  s.test_files    = Dir['samples/**'] 
  s.require_paths = ["lib"]
  s.bindir        = "bin"
  s.executables   = `ls bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_runtime_dependency  'gtk3', '~>2.2','>= 2.2.3'
  s.add_runtime_dependency  'gtksourceview3', '~>2.2','>= 2.2.3'
  #s.add_runtime_dependency  'gstreamer'
  #s.add_runtime_dependency  'clutter-gtk'
  #s.add_runtime_dependency  'clutter-gstreamer'
  

  
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  
  s.post_install_message = <<-TTEXT
        
  -------------------------------------------------------------------------------
        
      Hello, welcome to Ruiby....

        $ ruiby_demo
        $ ruiby "chrome(false); button ' Welcome ' do exit!(0) end "        
        $ ruiby_sketchi  # write and test ruiby gui
		
      for video, on windows, do >gem install  gstreamer clutter-gtk clutter-gstreamer
   -------------------------------------------------------------------------------
   TTEXT
end

