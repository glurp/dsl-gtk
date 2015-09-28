# -*- encoding: utf-8 -*-
$:.push('lib')

Gem::Specification.new do |s|
  s.name     = "Ruiby"
  s.authors  = ["Regis d'Aubarede"]
  s.licenses = ['LGPL', 'CC-BY-SA']
  s.homepage = "http://github.com/glurp/Ruiby"
  s.email    = "regis.aubarede@gmail.com"
  
  s.version  = File.read("VERSION").strip
  s.date     = Time.now.to_s.split(/\s+/)[0]
  s.summary  = "A  DSL for building GUI ruby/gtk application"
  s.description = <<EEND
A DSL for building GUI ruby application, based on Gtk.
EEND
  

  s.files         = Dir['**/*'].reject { |a| a =~ /^\.git/ || a =~ /\._$/ }
  s.test_files    = Dir['samples/**'] 
  s.require_paths = ["lib"]
  s.bindir        = "bin"
  s.executables   = `ls bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_runtime_dependency  'gtk3',          '>= 3.0.5'
  s.add_runtime_dependency  'gtksourceview3','>= 3.0.5'
  

  
#  s.add_development_dependency  'gstreamer'
#  s.add_development_dependency  'clutter-gtk'
#  s.add_development_dependency  'clutter-gstreamer'
   s.add_development_dependency 'rake'
   s.add_development_dependency 'rspec'
   s.add_development_dependency 'simplecov'
  
  s.post_install_message = <<-TTEXT
        
  -------------------------------------------------------------------------------
        
      Hello, Welcome to Ruiby....

        $ ruiby_demo
        $ ruiby_sketchi  # write and test ruiby gui code

    Reference doc of the DSL :  https://rawgit.com/glurp/Ruiby/master/doc.html
   -------------------------------------------------------------------------------
   TTEXT
end

