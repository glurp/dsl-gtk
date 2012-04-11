NAME="Ruiby"
Rake.application.options.trace = false

def push_changelog(line)
  b=File.read('CHANGELOG.txt').split(/\r?\n/) 
  b.unshift(line)
  File.open('CHANGELOG.txt','w') {|f| f.write(b.join("\n")) }
end
def change_version()
  a=File.read('VERSION').strip.split('.')[0..2]
  yield(a)
  version=a.join('.') 
  File.open('VERSION','w') {|f| f.write(version) }
  version
end


######################## Comment each file modified ######################
SRC = FileList['**/*.rb']

rule '._' => '.rb' do |src|
  puts "\n\ncomment for #{src.source} : "
  comment=$stdin.gets.chomp
  if comment && comment.size>0
	  puts "Abort!" 	if comment=~/^a(b(o(r(t)?)?)?)?$/
	  exit! 			if comment=~/^a(b(o(r(t)?)?)?)?$/
	  unless File.exists?(src.name)
		sh "git add #{src.source}"
	  end
	  sh "git commit #{src.source} -m \"#{comment.strip}\"" rescue 1
	  push_changelog("    #{src.source} : #{comment}")
	  $changed=true
  end
  touch src.name
end

COM=SRC.map do |src| 
  base=src.split('.').tap {|o| o.pop}.join('.')
  file "#{base}._" =>  src ; "#{base}._" 
end

desc "general dependency"
file "commit._" =>  COM

desc "job before xommitement"
task :pre_commit do
puts RUBY_PLATFORM
	sh "cls" if RUBY_PLATFORM =~ /(win32)|(mingw)/i 
	puts <<EEND


--------------------------------------------------------------------
                 Commmit & push #{NAME}
--------------------------------------------------------------------
EEND
	
	sh "giti"
	$changed=false
end

desc "job after local commit done: push to git repo"
task :post_commit do
  if $changed
	  $version=change_version { |a| a[-1]=(a.last.to_i+1) }  
	  sh "git commit VERSION -m update"
	  sh "git commit CHANGELOG.txt -m update"
	  sh "git push"
	  puts "\n\nNew version is #{$version}\n"
	  Rake::Task["test"].execute
  else
	puts "no change!"
  end
end
desc "commit local and then distant repo"
task :commit => [:pre_commit,"commit._",:post_commit]


desc "make a gem and push it to gemcutter"
task :gem => :commit do
	$version=change_version { |a| 
			a[-2]=(a[-2].to_i+1) 
			a[-1]=0 
	}  
	puts "New version ==>> #{$version}"
	l=FileList['*.gem']
	l.each { |fn| rm fn }
	gem_name="#{NAME}-#{$version}.gem"
	push_changelog  "#{$version} : #{Time.now}"
	sh "gem build #{NAME}.gemspec"
	Rake::Task["test"].execute
	sh "gem push #{gem_name}"
	l.each { |fn|
      ov=fn.split('-')[1].gsub('.gem',"")
	  sh "gem yank -v #{ov} #{NAME}"
	}
end

task :test do
 cd ".."
 mkdir "#{NAME}Test"
 nname="#{NAME}Test/test.rb"
 content=File.read("#{NAME}/samples/test.rb").gsub(/^\s*require_relative/,"require")
 File.open(nname,"w") { |f| f.write(content) }
 sh "gem install #{FileList['#{NAME}/#{NAME}*.gem'][-1]}"
 ruby  nname
end



